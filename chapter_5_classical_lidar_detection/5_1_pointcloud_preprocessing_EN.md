---
chapter: 5
section: 1
title: Point-cloud preprocessing
language: EN
workflow_status: reviewing
tags:
  - book/section
  - book/chapter-5
  - lang/EN
---

# 5.1 Point-cloud preprocessing

The Ch 5 classical pipeline is `preprocess → ground → cluster → fit → track`. Point-cloud preprocessing is the part that makes the rest of that pipeline physically meaningful: it puts points into a consistent frame, removes obvious non-object returns, controls point count, and chooses the representation that later algorithms consume. A ground segmenter, clusterer, or shape fitter can only be as trustworthy as the geometry it receives; a doubled car from bad deskew or a spray plume promoted into a cluster is already a detection failure before any RANSAC, Patchwork, Euclidean clustering, or Kalman filter appears.

The prerequisites are small but non-negotiable. TF2 supplies the transform chain from `lidar` through `base_link` into `odom`, `map`, or `world`, as introduced in [[1_1_coordinate_frames_EN|Ch 1 §1.1]]. LiDAR sensor basics — beam pattern, returns, and intensity caveats — come from [[1_3_lidar_calibration_EN|Ch 1 §1.3]]; sensor time-sync hygiene and rosbag clock semantics come from [[1_4_sensor_time_sync_EN|Ch 1 §1.4]]. A ROS2 `PointCloud2` carries `header.stamp`, `frame_id`, and fields such as `x, y, z, intensity, ring, time`; the per-point `time` field is what makes sweep-level deskew possible. Ch 2's ego-state estimator provides the IMU, wheel, and odometry source for interpolated ego-pose ([[2_1_ego_state_estimation_EN|Ch 2 §2.1]] / [[2_2_gnss_ins_imu_fusion_EN|Ch 2 §2.2]]); `odom` and `map`-relative semantics come from [[2_3_lidar_localization_EN|Ch 2 §2.3]] and [[2_5_map_relative_localization_EN|Ch 2 §2.5]].

## Deskew

Deskew is the anchor algorithm for §5.1. A mechanical spinning LiDAR does not capture a full sweep at one instant. At 10 Hz, one revolution spans roughly 100 ms; at 20 m/s, `base_link` moves about 2 m during that sweep. Above parking-lot speeds, treating all points as if they share `header.stamp` bends poles, doubles nearby vehicles, and makes rectangular objects look like arcs. Deskew corrects this by transforming each point from its acquisition time to a common reference time, usually the end of the sweep or the midpoint, before downstream geometry sees the cloud.

The concept is not "make the cloud prettier"; it is "make every point describe the scene at the same time." Without that common time, §5.2 fits ground to a warped surface, §5.3 clusters a single actor into two surfaces, §5.4 fits boxes to torn geometry, and §5.6 tries to register a moving shutter artifact. Production DL stacks generally consume motion-compensated sweeps too. VoxelNet, PointPillars, CenterPoint, and range-image learned detectors do not make per-point timestamps irrelevant; they usually inherit a deskewed point cloud or validate any learned / joint LiDAR-IMU compensation against an ego-pose-driven baseline before it enters the perception contract in [[6_0_overview_EN|Ch 6]].

> [!example] Sweep-direction smear before and after deskew
> ```
> ego moving left → right during one 100 ms sweep
>
> before deskew: one parked car appears twice / bent
> scan start points        scan end points
>     +------+                 +------+
>     | car  | . . . . . . . . | car  |
>     +------+                 +------+
>         pole becomes a leaning slash:     /
>
> after deskew to sweep-end `base_link`
>                   +------+
>                   | car  |
>                   +------+
>                   pole is vertical:       |
> ```
> The visual symptom is geometric, not semantic. Once the doubled car reaches clustering, later modules can only patch the damage; they cannot recover the missing per-point timing.

The implementation starts with the transform chain. Following the convention that `T_a_b` denotes the transform from frame `b` to frame `a` (so `T_a_b * v_b = v_a`), and writing `T_world_base(t)` for the time-varying base-pose-in-world from the Ch-2 ego-pose stream:

```text
p_common = T_base_world(t_common) * T_world_base(t_point) * T_base_lidar * p_lidar
```

where `T_base_world(t) = (T_world_base(t))^-1`. `T_base_lidar` is the calibrated extrinsic from [[1_1_coordinate_frames_EN|Ch 1 §1.1]] / [[1_3_lidar_calibration_EN|Ch 1 §1.3]]. `t_point = header.stamp + point.time` when the point field stores offset-from-sweep-start, or `t_point = point.time` when the driver stores absolute time; the driver contract must state which convention it uses. `t_common` is commonly the sweep-end time because it matches the latest ego pose available at publication, but midpoint deskew is also valid if every downstream consumer agrees. The persisted frame is usually `base_link` at `t_common`; `odom` or `map` may be used for registration and ROI branches, but the invariant is still one common time.

Ego-pose interpolation is the next layer. The preprocessor keeps a time-indexed buffer of ego poses, usually from fused wheel / IMU / odometry rather than raw GNSS alone. For each point, find the two bracketing ego poses `T_world_base(t0)` and `T_world_base(t1)` such that `t0 ≤ t_point ≤ t1`. Translation is normally linearly interpolated over the short sweep interval:

```text
u = (t_point - t0) / (t1 - t0)
p_world_base(t_point) = (1 - u) * p0 + u * p1
```

Rotation should be interpolated with quaternion slerp, not Euler-angle interpolation. Slerp follows the shortest arc on the unit quaternion sphere and avoids roll / pitch / yaw discontinuities at wraparound. Over a 100 ms sweep, linear translation plus quaternion slerp is usually accurate enough for perception preprocessing; if the ego source already publishes a continuous-time trajectory, the deskew node can sample that trajectory instead of maintaining its own interpolation rule. The important code-review question is whether rotation and translation are interpolated at the same timestamp, from the same ego-pose source, and with a clear extrapolation policy.

The ego-pose buffer must be indexed by the same clock domain as the point cloud. In live ROS2 operation, `header.stamp`, TF2 timestamps, and ego-pose messages are expected to be in ROS time. During rosbag replay with `use_sim_time`, nodes read time from `/clock`; wall-clock time is irrelevant. A common bug is to compare `header.stamp` from the bag against `now()` from wall time, which makes every transform look stale or futuristic. The deskew node should reject frames when the buffer does not cover `[t_first_point, t_last_point]`, not silently clamp to the nearest ego pose. The buffer also needs margin: if the cloud arrives late, the node still needs the ego poses that bracket the old point timestamps. Store sweep start, sweep end, per-point min/max time offsets, and buffer coverage in diagnostics; those four numbers explain most replay failures.

TF2 lookup discipline is equally concrete. Use `canTransform` or an equivalent preflight to test whether the static and dynamic chain exists for the requested time, then `lookupTransform` for the actual transform. Static transforms such as `T_base_lidar` can be cached after validation; dynamic transforms such as `T_world_base(t)` must be time-specific. Do not call `lookupTransform(..., TimePointZero)` inside deskew code unless the desired behavior is explicitly "latest available transform," because latest transform is often wrong for old points. Extrapolation should be a deliberate policy: fail fast for the primary obstacle path, optionally fall back for non-safety diagnostics, and log the delta between requested and available times. A frame that cannot be deskewed inside the interpolation window should be marked invalid before it reaches §5.2.

Worked example. Suppose a 10 Hz sweep is deskewed to sweep end `t_common = 100 ms`. One point is fired at azimuth 90°, `50 ms` into the sweep, with local coordinates `p_lidar = (10.0, 0.0, 0.0)` after applying the static LiDAR-to-base extrinsic for simplicity. Ego speed is `20 m/s`, yaw rate is `0.1 rad/s`, and the point is therefore `50 ms` earlier than the common time. Over that interval, the ego travels:

```text
Δx = 20 m/s * 0.050 s = 1.0 m
Δyaw = 0.1 rad/s * 0.050 s = 0.005 rad
```

To express the earlier point in sweep-end `base_link`, apply the relative motion from `t_point` to `t_common`. Ignoring vertical motion, the correction is approximately:

```text
x' = cos(0.005) * 10.0 - sin(0.005) * 0.0 - 1.0 ≈ 9.000 m
y' = sin(0.005) * 10.0 + cos(0.005) * 0.0       ≈ 0.050 m
```

The exact sign depends on the chosen frame convention, which is why the `T_a_b` expression above matters more than a memorized formula. The physical scale is the lesson: one mid-sweep point needs about a meter of translation correction and several centimeters of lateral yaw correction at normal road speed.

```python
u = (t_point - t0) / (t1 - t0)
q = slerp(q0, q1, u)
tr = (1 - u) * tr0 + u * tr1
T_w_b_point = make_transform(q, tr)
T_b_w_common = inverse(T_w_b_common)
p_common = T_b_w_common @ T_w_b_point @ T_b_lidar @ p_lidar
```

Usage starts with hard admission checks: `PointCloud2` must contain per-point time or a driver-specific firing-order table; `frame_id` must match the static extrinsic; the ego-pose buffer must cover the full sweep; TF2 age should be monitored with a freshness target such as `≤ 50 ms` for the hot path; and replay must run under `use_sim_time` when bags provide `/clock`. The tuning knobs are mostly policy knobs. Sweep-end vs midpoint changes latency and residual distortion distribution. A larger interpolation buffer improves replay robustness but can hide stale upstream timing. Fail-fast behavior reduces false geometry but increases dropped frames. Fallback-to-latest behavior keeps visualization alive but should not feed safety-relevant obstacle detection.

Failure modes are visible and testable. Missing per-point `time` produces sweep-direction smear. Wrong time origin produces a cloud that looks deskewed in static scenes and fails during turns. Stale TF2 transforms produce duplicated cars, bent poles, and curved lane boundaries. Wrong extrinsics mimic deskew failure but remain static across speed. The catalog row is `5_1.fm.deskew_failure_doubling`; §5.3 also sees the same symptom as `5_cross.fm.deskew_then_cluster_doubling`. The validation habit is to replay turning, braking, and highway-speed bags with deskew toggled on/off and require stable cluster count, object extent, and ground residuals.

> [!tip]
> Treat deskew as mandatory for road-speed evaluation logs. A pipeline that only works on static rosbag snippets can look correct while still failing the first hard brake, lane change, or urban turn.

## De-noising and preprocessing gates

De-noising removes points that are unlikely to be stable surfaces before they become clusters. The family is deliberately simple because it sits on the hot path: Statistical Outlier Removal, Radius Outlier Removal, return selection, near-far clipping, and height gates. The concept is to reduce obvious nuisance points while preserving every plausible obstacle; preprocessing is not allowed to become a hidden classifier.

**SOR.** Statistical Outlier Removal estimates each point's mean distance to its `k` nearest neighbors, computes the distribution of those mean distances over the cloud, and removes points whose mean distance is outside a standard-deviation threshold. A typical starting point is `k = 20` and `stddev = 1.0`, but the values are not portable defaults. SOR works best when point density is roughly homogeneous. A global threshold can preserve near rain and delete far pedestrians because LiDAR density falls with range and varies by ring. Tune by range bin: if far valid actors disappear, loosen SOR or branch it by range; if rain spray survives near wheels, tighten only the near band.

**ROR.** Radius Outlier Removal requires at least `min_neighbors` inside a radius. A common first setting is `radius = 0.4 m`, `min_neighbors = 2-5` on a downsampled obstacle branch. The rule is easy to read in code: query a spatial index, count neighbors, keep or drop. Its failure is the same density problem in a different form. A fixed radius is strict for sparse far objects and permissive for dense near clutter. Use ROR when isolated speckles are the nuisance; avoid treating it as a rain detector unless the validation set includes adverse-weather logs.

**Return selection.** Dual- and triple-return sensors may report first, strongest, and last returns for the same laser firing. First returns preserve thin foreground structures and spray; strongest returns emphasize retroreflectors and lane markings; last returns can recover surfaces behind partial occluders. There is no universally correct choice. An obstacle branch may keep strongest or last returns for stable surfaces, while a free-space branch may preserve first returns because any foreground hit should block a ray. The policy should be written into the branch name or metadata; otherwise two downstream consumers can think they are seeing the same physical evidence when they are not.

**Near-far clipping.** Near clipping removes returns from the sensor housing, hood, roof rack, and self-reflections. A typical lower bound is on the order of `0.5-1.0 m`, adjusted for the vehicle body and LiDAR mount. Far clipping enforces the ODD and compute budget: a detector that is validated to 80 m should not spend its hot-path cluster budget on 180 m speckle unless a map or free-space branch needs it. The tuning ladder is direct: raise near clip if ego-body ghosts pass through, lower it if close curbs or bumper-adjacent obstacles vanish; lower far clip if far speckle dominates, raise it only with labeled long-range recall tests.

**Height gates.** Height gates remove points outside physically plausible road-scene bounds, usually in `base_link` or a gravity-aligned frame. A starting band such as `-2.5 m ≤ z ≤ 3.0 m` can remove sky, bridge undersides, and hood returns for a passenger-vehicle roof LiDAR, but the correct band depends on calibration, road grade, vehicle height, and the ODD. The lower gate is safety-sensitive: too aggressive a threshold erases pothole edges, curbs, dropped cargo, trailer legs, or road debris that a Generic Obstacle Detection fallback should still see. The upper gate should not delete truck tops or overhanging obstacles if the planner must care about them.

Worked example. A branch receives eight residual points after deskew, with range `r`, height `z`, and local neighbor count inside `0.4 m`:

| point | `r` | `z` | neighbors | return | decision |
|---|---:|---:|---:|---|---|
| `a` | 0.3 | 0.2 | 5 | strongest | drop: near clip |
| `b` | 8.0 | 0.4 | 4 | strongest | keep |
| `c` | 8.2 | 0.5 | 3 | strongest | keep |
| `d` | 16.0 | 3.8 | 6 | last | drop: height |
| `e` | 28.0 | 0.6 | 1 | first | drop or temporal-check: sparse |
| `f` | 28.2 | 0.6 | 2 | strongest | keep if far branch loosens ROR |
| `g` | 90.0 | 0.7 | 2 | strongest | drop if ODD far clip is 80 m |
| `h` | 12.0 | -2.8 | 4 | last | drop unless ground/curb branch owns it |

```python
for p in points:
    if p.r < near or p.r > far: continue
    if p.z < z_min or p.z > z_max: continue
    if return_policy.rejects(p.return_type): continue
    if ror_enabled and count_neighbors(p, radius) < min_neighbors: continue
    keep.append(p)
```

Usage is branch-specific. A clustering branch should be conservative about deleting plausible obstacles, because §5.3 and §5.5 can reject unstable clusters later. A free-space branch should be even more conservative with first returns, because deleting a foreground hit can falsely clear space. A registration branch can be stricter: unstable spray and dynamic actors hurt ICP/NDT more than they help. Monitor kept/dropped point counts by range, ring, height, and return type; one scalar "filter ratio" hides the failure that matters.

The catalog row is `5_1.fm.rain_spray_ghosts`. Rain, tire spray, fog, exhaust, glass reflections, multi-path, and cross-LiDAR interference all create returns that are geometrically plausible for one frame. Downstream Euclidean clustering does not know that a 20-point blob is spray rather than a traffic cone. Learned detectors can suppress some weather patterns with training data, but production stacks still keep explicit preprocessing gates and adverse-weather monitors because DL confidence does not prove a return is physically stable.

## Intensity Caveats

Intensity is useful, but it is not a stable material classifier. The returned value depends on range, incidence angle, aperture, receiver gain, automatic exposure or thresholding, firmware, wavelength, weather, and vendor calibration. Two sensors looking at the same asphalt, sign, or car paint can report different intensity scales; even one sensor can shift across temperature, rain, and firmware revisions.

Classical pipelines still use intensity in narrow ways. Lane markings and retroreflectors often stand out enough to support map alignment, lane-boundary cues, or sign-post detection. BEV feature grids may include mean intensity or max intensity per cell because it adds information to density and height. These uses are reasonable when the operating domain and sensor calibration are fixed.

The failure mode is semantic overreach. If a rule says "high intensity means lane paint" or "low intensity means vegetation," the rule will break under wet asphalt, steep incidence angles, dark retroreflective materials, and sensor replacement. The safer wording is: intensity is an auxiliary channel whose distribution must be monitored per sensor family and ODD. It can help a detector separate markings and retroreflectors; it does not define object material in a portable way.

## Multi-frame Accumulation

Multi-frame accumulation stacks several sweeps before ground segmentation, clustering, occupancy, or map comparison. It recovers sparse far objects, fills in non-repetitive scan patterns, and gives low-beam sensors more evidence than one frame can provide. The concept is different from deskew: deskew puts points from one sweep into one time; accumulation intentionally keeps evidence from several sweeps, transformed into a common frame, because one sweep is too thin for the task.

The mechanics are a transform-and-append loop. Each incoming `PointCloud2` is first deskewed to its own sweep reference time. The accumulator then transforms that cloud into an accumulation frame such as `base_link(t_now)`, `odom`, or `map`, appends the points to a rolling buffer, and ages old points out. Store at least original point timestamp, source sweep id, range, and branch label. Aging can be time-window based (`keep last 300 ms`), distance-window based (`keep points until ego travels 2 m`), or both. Time windows are easier to reason about for planner freshness; distance windows are useful when the vehicle crawls and a fixed time window contains redundant geometry.

Static and dynamic layers should be separated. Static surfaces such as curbs, walls, poles, parked vehicles, lane boundaries, and map landmarks accumulate well when ego-pose is accurate. Moving actors do not: a crossing pedestrian becomes a streak, an oncoming car appears in several positions, and a turning ego vehicle can smear all dynamic objects if the transform chain is stale. For detection, accumulation before clustering should usually be short, track-aware, or avoided. For occupancy, ROI consistency, and map subtraction, a longer static layer can be valuable as long as each cell carries age.

Worked example. At 10 Hz, a 5-frame accumulation window contains sweeps at `t = -400, -300, -200, -100, 0 ms`; its age span is 400 ms between first and last sweep, often called a 500 ms five-frame window in operational shorthand because it contains five 100 ms frame intervals. If ego speed is `10 m/s`, the vehicle travels `4 m` between the oldest and newest sweep. A static pole at `x = 20 m` in `odom` should align after each cloud is transformed through ego pose. A moving cyclist crossing at `3 m/s` moves `1.2 m` during the same window, so the accumulated points form a stripe even with perfect ego pose.

```python
for cloud in incoming_sweeps:
    deskewed = deskew(cloud)
    T_acc_src = lookup_pose(accum_frame, deskewed.stamp)
    buffer.append(transform(deskewed, T_acc_src))
    buffer.drop_if(age_ms > max_age or ego_delta_m > max_dist)
publish(concat(buffer.points_with_time()))
```

Usage defaults should be modest on the primary obstacle path: one to three sweeps for sparse low-beam sensors, or no accumulation before clustering when moving actors dominate the risk. A static occupancy or map-comparison branch can use five or more sweeps if it publishes age-aware cells and does not clear or block drivable space from stale dynamic points. Increase the window when far cones or curbs flicker; decrease it when moving objects leave trails, when planner latency rises, or when track initiation sees repeated ghosts behind actors.

The failure mode is ghost occupancy. The observable symptom is a trail of points behind a moving vehicle, duplicated car surfaces during ego turns, or a false obstacle persisting after the actor has moved. Learned temporal fusion can handle motion cues better than a blind append buffer, but it still depends on the same timestamp and ego-pose discipline. Classical accumulation remains common because it is transparent and cheap; its outputs must carry age so §5.7 and the planner do not mistake memory for current occupancy.

## Voxel Downsampling

Voxel downsampling controls compute by replacing many points inside a small 3D cell with one representative point. `pcl::VoxelGrid` emits the **centroid** of the points falling in each occupied voxel — set the leaf size via `setLeafSize(...)`, insert points, and PCL emits one centroid per occupied voxel. `pcl::ApproximateVoxelGrid` is a faster variant that snaps each point to its voxel-center coordinate rather than computing per-voxel centroids — a small precision loss for a noticeable speedup on dense clouds. This preserves the large-scale geometry needed by ground segmentation, clustering, and registration while reducing neighbor-search cost.

Mechanically, the implementation computes an integer voxel key from each point:

```text
ix = floor((x - x_min) / leaf_x)
iy = floor((y - y_min) / leaf_y)
iz = floor((z - z_min) / leaf_z)
```

A hash map from `(ix, iy, iz)` to an accumulator is common for sparse clouds; a flat grid is faster only when the ROI is bounded tightly enough that empty cells do not dominate memory. `pcl::VoxelGrid` stores sums and counts, then emits `(sum_x/count, sum_y/count, sum_z/count)` plus whatever field policy the implementation chooses for intensity, ring, and time. That field policy matters. Averaging intensity may be useful for BEV statistics; averaging `ring` is meaningless; averaging per-point `time` can be misleading if a later range-image branch expects original firing order. If ring/time topology is needed, build the range image before voxelization or keep an index list per voxel.

> [!example] Voxel representative tradeoff
> ```
> leaf size = 0.20 m, one occupied voxel
>
> raw points inside voxel (top view)
> +----------------+
> | *              |
> |     *          |
> |          *     |
> |              * |
> +----------------+
>
> pcl::VoxelGrid centroid:          approximate voxel center:
> +----------------+                +----------------+
> |                |                |                |
> |       C        |                |       X        |
> |                |                |                |
> +----------------+                +----------------+
> C follows the local surface distribution; X is cheaper but can shift thin edges.
> ```

Worked example. Six points enter a voxel filter with `leaf = 0.20 m` and origin `(0,0,0)`:

| point | coordinate | voxel key |
|---|---|---|
| `p0` | `(0.01, 0.02, 0.00)` | `(0,0,0)` |
| `p1` | `(0.04, 0.03, 0.00)` | `(0,0,0)` |
| `p2` | `(0.18, 0.19, 0.01)` | `(0,0,0)` |
| `p3` | `(0.22, 0.03, 0.00)` | `(1,0,0)` |
| `p4` | `(0.27, 0.04, 0.00)` | `(1,0,0)` |
| `p5` | `(0.42, 0.02, 0.00)` | `(2,0,0)` |

`pcl::VoxelGrid` emits centroid `(0.077, 0.080, 0.003)` for key `(0,0,0)`, centroid `(0.245, 0.035, 0.000)` for key `(1,0,0)`, and `p5` unchanged for key `(2,0,0)`. `pcl::ApproximateVoxelGrid` would instead emit approximate cell-center representatives such as `(0.10, 0.10, 0.10)` and `(0.30, 0.10, 0.10)` depending on the coordinate convention. The point count drops from six to three, but the first surface edge also shifts.

```python
vox = {}
for p in points:
    key = floor(p.xyz / leaf)
    vox.setdefault(key, []).append(p)
out = []
for key, bucket in vox.items():
    out.append(mean_xyz(bucket))  # VoxelGrid; use center(key) for approximate
```

Leaf size is an ODD decision, not a library default. A `0.05 m` voxel may preserve curb and small-object detail but do little for CPU budget. A `0.10 m` voxel is a common starting point for near-field obstacle and ground work. A `0.20 m` voxel may make a VLP-32-class cloud cheap enough for real-time clustering but can erase cones, trailer legs, and pedestrian shape cues at range. Registration often uses a coarser branch than ground segmentation because ICP/NDT prefers stable structure over fine clutter. BEV occupancy usually matches the BEV cell resolution rather than the clustering leaf size.

The tuning ladder is visible in downstream symptoms. Increase leaf size when KD-tree clustering or registration exceeds budget; expect small objects and thin poles to weaken first. Decrease leaf size when curbs, cones, or L-shape corners disappear; expect memory and neighbor-search time to rise. Use anisotropic leaves only when the downstream method agrees: a tall `z` leaf can help BEV occupancy but damage height-based ground segmentation.

Downsampling must also respect ordering assumptions. Once a cloud is voxelized as an unordered point set, ring adjacency is gone unless `ring` and time metadata are preserved or the range image is built before filtering. That matters for scan-line ground segmentation and range-image connected components later in Ch 5. If a pipeline wants both range-image segmentation and voxel clustering, it should branch deliberately rather than hope one representation can serve every algorithm. In Ch 6, learned voxel-grid resolution inherits the same tradeoff: smaller voxels improve detail and cost more memory; larger voxels reduce compute and erase small geometry.

### 5.1.x Representation map

Representations are the substrate before the algorithms appear. Ch 5 uses five classical representations, and each one makes different assumptions about the sensor and the downstream method.

| representation | what it is | methods it enables | sensor topology assumptions | downstream Ch 5 use |
|---|---|---|---|---|
| raw point cloud | Unordered or lightly indexed `(x, y, z, intensity, ring, time)` points, usually queried by KD-tree or voxel hash. | SOR, ROR, PCL `VoxelGrid`, Euclidean clustering, RANSAC plane fitting, ICP-style registration. | Works for spinning, MEMS, flash-derived, and fused clouds if timestamps and frames are valid. | This section, [[5_2_ground_segmentation_EN|Ch 5 §5.2]], [[5_3_clustering_EN|Ch 5 §5.3]], [[5_6_registration_EN|Ch 5 §5.6]]. |
| voxel grid | 3D cells on a flat grid with representative points, counts, or statistics. | Downsampling (`pcl::VoxelGrid`), coarse clustering, registration acceleration via cell hashing. | Works across topologies after points are transformed into a common frame; resolution must match range and ODD. | This section, [[5_6_registration_EN|Ch 5 §5.6]]. |
| probabilistic octree (OctoMap) | Hierarchical octree of log-odds occupancy; coarse cells subdivide into eight children only where occupancy varies. Hornung 2013. | Probabilistic occupancy update, free-space ray carving, multi-resolution map memory. | Same frame requirements as voxel grid; the multi-resolution structure is the central benefit, not a flat-grid extension. | [[5_7_occupancy_freespace_map_roi_EN|Ch 5 §5.7]]. |
| range image | 2D spherical projection indexed by azimuth and elevation or ring. Pixel values store range, height, intensity, or labels. | Scan-line ground segmentation, depth-jump segmentation, range-image connected components, fast neighborhood tests. | Strongest for repeating-ring spinning LiDAR; non-repetitive sensors need re-projection and can create holes or artificial adjacency. | [[5_2_ground_segmentation_EN|Ch 5 §5.2]] and [[5_3_clustering_EN|Ch 5 §5.3]]. |
| BEV grid | Top-down raster over the ground plane with channels such as max height, mean height, density, occupancy, distance, angle, or intensity. | Occupancy grids, HD-map ROI gating, connected components in drivable area. (The *learned* PointPillars-class encoders that consume BEV grids are out of scope for Ch 5; see [[6_3_pointpillars_EN|Ch 6 §6.3]] for that handoff.) | Best when points are gravity-aligned and map or `odom` alignment is reliable; works for single or multi-LiDAR after extrinsics. | [[5_7_occupancy_freespace_map_roi_EN|Ch 5 §5.7]]. |

Read this table as a branching map rather than a ranking. Raw points carry maximum local geometry; voxel grids control compute; OctoMap stores probabilistic map memory; range images preserve firing topology; BEV grids express planner-facing occupancy. A production preprocessor usually publishes more than one branch because each representation buys a different downstream invariant.

The representation choice should happen before tuning algorithm thresholds. A DBSCAN threshold that looks wrong on raw points may be fine on a voxel grid; a range-image split that works on a Velodyne ring pattern may fail on a non-repetitive MEMS scan; a BEV occupancy cell that is useful for free-space can be too coarse for L-shape fitting. Most production systems keep more than one branch because no single representation is optimal for all of `preprocess → ground → cluster → fit → track`.

### 5.1.x Output contract for downstream sections

§5.1 publishes a deskewed, de-noised, voxel-downsampled `PointCloud2` in `base_link` at sweep-end time. Branch policy:

| consumer | input expected | preprocessing applied |
|---|---|---|
| [[5_2_ground_segmentation_EN\|§5.2]] ground segmentation | full preprocessed cloud (deskewed, SOR/ROR, height-gated, voxel-downsampled at the ground-seg leaf size) | optional projection to a range image when scan-line methods (Himmelsbach) or range-image connected components are used |
| [[5_3_clustering_EN\|§5.3]] clustering | residual non-ground cloud from §5.2 | inherits §5.2's preprocessing |
| [[5_6_registration_EN\|§5.6]] registration | same preprocessed cloud, voxel-downsampled at the **registration** leaf size (typically coarser than ground-seg) | source for ICP/NDT/GICP and for map-subtraction registration |
| [[5_7_occupancy_freespace_map_roi_EN\|§5.7]] occupancy + ROI gating | BEV projection of the preprocessed cloud at the BEV cell resolution | downsampling at the BEV cell resolution |

A pipeline may keep multiple branches active simultaneously (one for ground/clustering, one for registration, one for occupancy) because no single leaf size or representation is optimal for every downstream stage.

> [!warning] Failure modes for §5.10 catalog
> | id | cause | observable_symptom | downstream_hazard | mitigation | validation_test |
> |---|---|---|---|---|---|
> | `5_1.fm.rain_spray_ghosts` | Rain, tire spray, fog, or exhaust creates short-lived but geometrically plausible returns that pass simple SOR/ROR thresholds. | Small clusters appear near wheels, behind trucks, or in wet road spray, with unstable frame-to-frame positions. | Clustering and tracking promote the returns into false obstacles, causing braking, path blockage, or unnecessary lane-change suppression. | Range-aware outlier thresholds, return-selection policy, temporal consistency checks, weather-specific monitors, conservative separation between obstacle detections and free-space clearing. | Replay wet-road and truck-spray scenarios with ground-truth free-space review and measure false-obstacle persistence (not only per-frame mAP). |
> | `5_1.fm.deskew_failure_doubling` | Missing per-point `time`, stale TF2 transforms, or incorrect ego-pose interpolation transforms different parts of one sweep to inconsistent `base_link` poses. | Cars, poles, lane boundaries, or guardrails appear doubled, curved, or torn along the scan direction. | Ground segmentation, clustering, and shape fitting split one actor into multiple objects or fit planner-hostile boxes with incorrect yaw and extent. | Enforce per-point timestamp presence, monitor `/tf` age, reject frames outside the ego-pose interpolation window, validate deskew on high-yaw-rate logs. | Run turning, braking, and highway-speed rosbag scenarios with deskew-on/off comparisons; require stable cluster count and object extent. |
> | `5_1.fm.intensity_misclassification` | A rule treats intensity as material identity even though intensity shifts with range, incidence, aperture, firmware, weather, and sensor family. | Wet asphalt, retroreflective signs, dark vehicles, or replacement sensors change class-like decisions without a corresponding geometry change. | Lane-marking, reflector, ROI, or obstacle filters suppress real objects or create false semantic cues for downstream modules. | Use intensity only as an auxiliary feature; calibrate and monitor distributions per sensor and ODD; keep geometry-based fallbacks active. | Compare dry/wet, near/far, multi-incidence, and cross-sensor logs; check that decisions do not depend on an uncalibrated intensity threshold. |

| stage | compute | frame_rate_assumption | point_count_assumption | latency_p50_ms | latency_p99_ms | memory_mb | cadence | tf_freshness_assumption | assumptions_and_caveats |
|---|---|---|---|---|---|---|---|---|---|
| `5_1_pointcloud_preprocessing` | cpu | 10 Hz mechanical spinning LiDAR | VLP-32C in **single-return** mode at ~600k pts/s sustained, ~60k pts/frame before filtering (dual-return roughly doubles both) | ~6 | ~18 | ~96 | every-frame | ≤ 50 ms | **Illustrative** budget for a single-roof-LiDAR C++ ROS2 node on a Jetson-Orin-class CPU running deskew + SOR/ROR + clipping + optional 3-frame accumulation branch + PCL `VoxelGrid`; no learned voxelization; latency excludes driver packet parsing and downstream ground segmentation. Per-deployment numbers vary with sensor / CPU class / accumulation cadence and should be measured rather than assumed. |
