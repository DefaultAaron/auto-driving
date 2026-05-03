---
chapter: 5
section: 1
title: Point-cloud preprocessing
language: EN
workflow_status: complete
tags:
  - book/section
  - book/chapter-5
  - lang/EN
---

# 5.1 Point-cloud preprocessing

The Ch 5 classical pipeline is `preprocess → ground → cluster → fit → track`. Point-cloud preprocessing is the part that makes the rest of that pipeline physically meaningful: it puts points into a consistent frame, removes obvious non-object returns, controls point count, and chooses the representation that later algorithms consume. A ground segmenter, clusterer, or shape fitter can only be as trustworthy as the geometry it receives; a doubled car from bad deskew or a spray plume promoted into a cluster is already a detection failure before any RANSAC, Patchwork, Euclidean clustering, or Kalman filter appears.

The prerequisites are small but non-negotiable. TF2 supplies the transform chain from `lidar` through `base_link` into `odom`, `map`, or `world`, as introduced in [[1_1_coordinate_frames_EN|Ch 1 §1.1]]. LiDAR sensor basics — beam pattern, returns, and intensity caveats — come from [[1_3_lidar_calibration_EN|Ch 1 §1.3]]; sensor time-sync hygiene and rosbag clock semantics come from [[1_4_sensor_time_sync_EN|Ch 1 §1.4]]. A ROS2 `PointCloud2` carries `header.stamp`, `frame_id`, and fields such as `x, y, z, intensity, ring, time`; the per-point `time` field is what makes sweep-level deskew possible. Ch 2's ego-state estimator provides the IMU, wheel, and odometry source for interpolated ego-pose ([[2_1_ego_state_estimation_EN|Ch 2 §2.1]] / [[2_2_gnss_ins_imu_fusion_EN|Ch 2 §2.2]]); `odom` and `map`-relative semantics come from [[2_3_lidar_localization_EN|Ch 2 §2.3]] and [[2_5_map_relative_localization_EN|Ch 2 §2.5]].

## Deskew

A mechanical spinning LiDAR does not capture a full sweep at one instant. At 10 Hz, one revolution spans roughly 100 ms; at 20 m/s, `base_link` moves about 2 m during that sweep. Above parking-lot speeds, treating all points as if they share `header.stamp` bends poles, doubles nearby vehicles, and makes rectangular objects look like arcs. Deskew corrects this by transforming each point from its acquisition time to a common reference time, usually the end of the sweep or the midpoint, before downstream geometry sees the cloud.

The pipeline uses the per-point timestamp, interpolates ego-pose from the Ch 2 source, and applies the relative transform. Following the convention that `T_a_b` denotes the transform from frame `b` to frame `a` (so `T_a_b * v_b = v_a`), and writing `T_world_base(t)` for the time-varying base-pose-in-world from the Ch-2 ego-pose stream:

```text
p_common = T_base_world(t_common) * T_world_base(t_point) * T_base_lidar * p_lidar
```

where `T_base_world(t) = (T_world_base(t))^-1`. The result places each point in `base_link` at the common reference time. The choice of `base_link` (most common), `odom`, or `map` for the persisted frame is downstream-driven and only matters for §5.6 registration and §5.7 ROI gating, where map-relative work happens; the invariant is the same regardless: every point must describe the scene at the same reference time. In C++ systems this usually lives beside the driver or point-cloud preprocessor, implemented with TF2, Eigen transforms, and a time-indexed ego-pose buffer. Quaternion interpolation handles orientation; translation is usually linearly interpolated over the short sweep interval unless the ego-pose source already provides a continuous-time trajectory.

Deskew is not SLAM. It consumes an ego-pose stream; it does not build a scan-to-map solution, which belongs to Ch 2 and to the registration depth in [[5_6_registration_EN|Ch 5 §5.6]]. The practical question here is latency and freshness. If `/tf` lags the point cloud by more than the interpolation buffer can cover, a perception node either blocks, falls back to an approximate transform, or marks the frame invalid. Each choice is visible later: stale deskew produces duplicated object surfaces, bad yaw interpolation produces curved lanes and guardrails, and missing per-point time silently converts a moving-vehicle problem into a static-sensor assumption.

> [!tip]
> Treat deskew as mandatory for road-speed evaluation logs. A pipeline that only works on static rosbag snippets can look correct while still failing the first hard brake, lane change, or urban turn.

## De-noising

De-noising removes points that are unlikely to be stable surfaces before they become clusters. The common filters are simple because they sit on the hot path. Statistical Outlier Removal estimates each point's mean neighbor distance and removes points outside a standard-deviation threshold. Radius Outlier Removal requires a minimum number of neighbors inside a fixed radius. Near-far clipping removes returns too close to the sensor housing or beyond the useful range for the ODD. Height gates remove points outside physically plausible road-scene bounds, usually expressed in `base_link` or a gravity-aligned frame.

These filters are easy to overtrust. SOR works better when point density is roughly homogeneous, but LiDAR density falls with range and varies by ring. A global neighbor-distance threshold can preserve near rain and delete far pedestrians. ROR has the same range problem in a different form: a fixed radius is strict near the vehicle and permissive at long range unless it is made range-aware. Height gates are useful for removing sky, bridge undersides, and hood returns, but an aggressive lower gate can erase pothole edges, curbs, trailer legs, or road debris that a Generic Obstacle Detection fallback should still see.

Return selection is a second de-noising lever. Dual- and triple-return sensors may report first, strongest, and last returns for the same laser firing. First returns help preserve thin foreground structures and spray; strongest returns emphasize retroreflectors and lane markings; last returns can recover surfaces behind partial occluders. There is no universally correct choice. A pipeline that clusters obstacles may prefer last or strongest returns for stability, while a free-space monitor may preserve first returns because any foreground hit should block a ray.

Weather and optics create the hardest cases. Rain, tire spray, fog, exhaust, glass reflections, multi-path, and cross-LiDAR interference all create returns that are geometrically plausible for one frame. Downstream Euclidean clustering does not know that a 20-point blob is spray rather than a traffic cone. Production preprocessors therefore combine local geometry filters with temporal checks, range-dependent thresholds, ring consistency, and sometimes vendor-specific invalid-return flags. The validation set must include adverse-weather bags; clear-day tuning usually sets thresholds too loose for spray and too tight for distant sparse objects.

## Intensity Caveats

Intensity is useful, but it is not a stable material classifier. The returned value depends on range, incidence angle, aperture, receiver gain, automatic exposure or thresholding, firmware, wavelength, weather, and vendor calibration. Two sensors looking at the same asphalt, sign, or car paint can report different intensity scales; even one sensor can shift across temperature, rain, and firmware revisions.

Classical pipelines still use intensity in narrow ways. Lane markings and retroreflectors often stand out enough to support map alignment, lane-boundary cues, or sign-post detection. BEV feature grids may include mean intensity or max intensity per cell because it adds information to density and height. These uses are reasonable when the operating domain and sensor calibration are fixed.

The failure mode is semantic overreach. If a rule says "high intensity means lane paint" or "low intensity means vegetation," the rule will break under wet asphalt, steep incidence angles, dark retroreflective materials, and sensor replacement. The safer wording is: intensity is an auxiliary channel whose distribution must be monitored per sensor family and ODD. It can help a detector separate markings and retroreflectors; it does not define object material in a portable way.

## Multi-frame Accumulation

Multi-frame accumulation stacks several sweeps before ground segmentation, clustering, occupancy, or map comparison. It recovers sparse far objects, fills in non-repetitive scan patterns, and gives low-beam sensors more evidence than one frame can provide. The simplest version transforms recent point clouds into a common `base_link` or `odom` reference using ego-pose, clips the history to a short time window, and appends the points.

The central tradeoff is sparse-far recovery versus ghost obstacles. Static surfaces such as curbs, walls, poles, and parked vehicles accumulate well when ego-pose is accurate. Moving actors do not: a crossing pedestrian becomes a streak, an oncoming car appears in several positions, and a turning ego vehicle can smear all dynamic objects if the transform chain is stale. For detection, accumulation should usually be split into static and dynamic layers. A static layer can support road boundaries, occupancy memory, and HD-map ROI consistency. A dynamic layer should be short, track-aware, or avoided before clustering unless the downstream tracker explicitly handles motion compensation.

Accumulation also changes latency semantics. A five-frame window at 10 Hz contains 500 ms of history even if the node publishes every frame. That may be acceptable for curb evidence and map subtraction; it is dangerous for a primary obstacle path if the planner interprets old points as current occupancy. A robust implementation stores point timestamps with the accumulated cloud and ages out points by both time and ego-motion distance.

## Voxel Downsampling

Voxel downsampling controls compute by replacing many points inside a small 3D cell with one representative point. `pcl::VoxelGrid` emits the **centroid** of the points falling in each occupied voxel — set the leaf size via `setLeafSize(...)`, insert points, and PCL emits one centroid per occupied voxel. `pcl::ApproximateVoxelGrid` is a faster variant that snaps each point to its voxel-center coordinate rather than computing per-voxel centroids — a small precision loss for a noticeable speedup on dense clouds. This preserves the large-scale geometry needed by ground segmentation, clustering, and registration while reducing neighbor-search cost.

Leaf size is an ODD decision, not a library default. A 0.05 m voxel may preserve curb and small-object detail but do little for CPU budget. A 0.20 m voxel may make a VLP-32 cloud cheap enough for real-time clustering but can erase cones, trailer legs, and pedestrian shape cues at range. Many systems use different leaf sizes for different branches: fine for near-field Generic Obstacle Detection and coarse for map subtraction or far-field occupancy.

Downsampling must also respect ordering assumptions. Once a cloud is voxelized as an unordered point set, ring adjacency is gone unless `ring` and time metadata are preserved or the range image is built before filtering. That matters for scan-line ground segmentation and range-image connected components later in Ch 5. If a pipeline wants both range-image segmentation and voxel clustering, it should branch deliberately rather than hope one representation can serve every algorithm.

### 5.1.x Representation map

Representations are the substrate before the algorithms appear. Ch 5 uses four classical representations, and each one makes different assumptions about the sensor and the downstream method.

| representation | what it is | methods it enables | sensor topology assumptions | downstream Ch 5 use |
|---|---|---|---|---|
| raw point cloud | Unordered or lightly indexed `(x, y, z, intensity, ring, time)` points, usually queried by KD-tree or voxel hash. | SOR, ROR, PCL `VoxelGrid`, Euclidean clustering, RANSAC plane fitting, ICP-style registration. | Works for spinning, MEMS, flash-derived, and fused clouds if timestamps and frames are valid. | This section, [[5_2_ground_segmentation_EN|Ch 5 §5.2]], [[5_3_clustering_EN|Ch 5 §5.3]], [[5_6_registration_EN|Ch 5 §5.6]]. |
| voxel grid | 3D cells on a flat grid with representative points, counts, or statistics. | Downsampling (`pcl::VoxelGrid`), coarse clustering, registration acceleration via cell hashing. | Works across topologies after points are transformed into a common frame; resolution must match range and ODD. | This section, [[5_6_registration_EN|Ch 5 §5.6]]. |
| probabilistic octree (OctoMap) | Hierarchical octree of log-odds occupancy; coarse cells subdivide into eight children only where occupancy varies. Hornung 2013. | Probabilistic occupancy update, free-space ray carving, multi-resolution map memory. | Same frame requirements as voxel grid; the multi-resolution structure is the central benefit, not a flat-grid extension. | [[5_7_occupancy_freespace_map_roi_EN|Ch 5 §5.7]]. |
| range image | 2D spherical projection indexed by azimuth and elevation or ring. Pixel values store range, height, intensity, or labels. | Scan-line ground segmentation, depth-jump segmentation, range-image connected components, fast neighborhood tests. | Strongest for repeating-ring spinning LiDAR; non-repetitive sensors need re-projection and can create holes or artificial adjacency. | [[5_2_ground_segmentation_EN|Ch 5 §5.2]] and [[5_3_clustering_EN|Ch 5 §5.3]]. |
| BEV grid | Top-down raster over the ground plane with channels such as max height, mean height, density, occupancy, distance, angle, or intensity. | Occupancy grids, HD-map ROI gating, connected components in drivable area. (The *learned* PointPillars-class encoders that consume BEV grids are out of scope for Ch 5; see [[6_3_pointpillars_EN|Ch 6 §6.3]] for that handoff.) | Best when points are gravity-aligned and map or `odom` alignment is reliable; works for single or multi-LiDAR after extrinsics. | [[5_7_occupancy_freespace_map_roi_EN|Ch 5 §5.7]]. |

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
