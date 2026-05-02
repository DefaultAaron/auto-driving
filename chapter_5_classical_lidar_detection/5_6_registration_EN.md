---
chapter: 5
section: 6
title: Registration — ICP / NDT / GICP
language: EN
workflow_status: draft
tags:
  - book/section
  - book/chapter-5
  - lang/EN
---

# 5.6 Registration — ICP / NDT / GICP

You saw these names in [[2_3_lidar_localization_EN|Ch 2 §2.3]]; here is how they work, plus four ways perception itself uses them. Ch 2 introduced ICP, NDT, and GICP as the workhorses behind LiDAR localization and forward-pointed to this section for algorithmic depth. That depth is owed here, but the section earns its place in a *detection* chapter by showing four perception roles registration plays beyond the localization use the reader has already met.

> [!abstract] What this section covers
> The three classical registration algorithms — ICP (Besl & McKay 1992), NDT (Magnusson 2009), and GICP (Segal, Haehnel, Thrun 2009) — at the level of objective, optimization sketch, convergence behavior, and failure modes. Then four perception roles registration plays in Ch 5: deskew refinement, map subtraction, multi-frame accumulation alignment, and map-aided ROI consistency. The fifth role is localization itself, which Ch 2 already named.

## Prerequisites, restated inline

Registration aligns one point cloud to another. To talk about that alignment cleanly we need three things from earlier chapters: the TF2 tree relating the `lidar` frame to `base_link` and `base_link` to `map` ([[1_1_coordinate_frames_and_tf2_EN|Ch 1 §1.1]]); a source of ego-pose at the timestamp of each sweep ([[2_1_ego_state_estimation_EN|Ch 2 §2.1]]); and the canonical representations introduced in [[5_1_pointcloud_preprocessing_EN|§5.1]] — raw point cloud, voxel grid, range image, BEV. ICP operates on raw point clouds; NDT operates on a voxel-grid representation of the target; GICP operates on raw points augmented with per-point covariances.

Throughout this section, "source" is the live cloud being aligned and "target" is the cloud (or map) it is being aligned to. The output is a rigid transform `T ∈ SE(3)` that maps source-frame points into the target frame.

## ICP — Iterative Closest Point

Besl & McKay proposed ICP in 1992 as a general method for registering 3-D shapes given a reasonable initial guess. The algorithm alternates between two cheap subproblems:

1. **Correspondence step.** For every source point `p_i`, find the closest target point `q_i` under the current transform estimate `T_k`. A KD-tree on the target cloud makes this `O(N log M)`.
2. **Alignment step.** Solve for the transform `T_{k+1}` that minimizes the sum of squared distances between corresponded pairs.

Iterate until the transform stops changing. The two variants differ only in the alignment objective:

- **Point-to-point ICP** minimizes
  ```
  E_pp(T) = Σ_i || T·p_i − q_i ||²
  ```
  This has a closed-form solution per iteration via the Kabsch / Horn SVD construction on the cross-covariance matrix.
- **Point-to-plane ICP** (Chen & Medioni 1991, popularized alongside ICP) minimizes the squared distance from each transformed source point to the *tangent plane* of its corresponding target point:
  ```
  E_pl(T) = Σ_i ( n_i · ( T·p_i − q_i ) )²
  ```
  where `n_i` is the surface normal at `q_i`. Each iteration linearizes the rotation about the current estimate and solves a small least-squares system. Point-to-plane converges faster than point-to-point on roughly planar scenes (roads, walls, building façades — most of urban LiDAR), because it lets points slide along the local surface instead of pinning them to a single nearest neighbor.

> [!info] What "convergence" means here
> Both ICP variants can be viewed as alternating projection on a non-convex energy. Each step decreases the cost, so the iterates converge to a *local* minimum. The basin of convergence is small: the initial transform must already place the source within a few degrees of rotation and a meter or so of translation of the true alignment for ICP to find it. ICP is a refiner, not a solver from scratch.

**Failure modes worth naming up front:**

- **Degenerate geometry.** A long featureless tunnel or open highway gives the optimizer no along-track signal; the cost surface is nearly flat in one direction, and the solution drifts.
- **Poor initial transform.** Without a decent prior from IMU, wheel odometry, or a previous registration, ICP latches onto the wrong local minimum. Doubled-up walls and rotated-by-one-pillar artifacts are the classic symptoms.
- **Partial overlap.** When the source sees regions the target does not (or vice versa), nearest-neighbor correspondences become spurious; rejection thresholds (max correspondence distance, reciprocal-correspondence checks) help but do not save a fundamentally non-overlapping pair.

## NDT — Normal Distributions Transform

Magnusson's 2009 thesis is the canonical reference for the 3-D NDT used in production AD. The idea is to throw away individual target points and replace each voxel by its **per-cell normal distribution** — a mean `μ_c` and covariance `Σ_c` fit to the points falling inside cell `c`. The target then becomes a sum of Gaussians defined over space.

Given a transform `T`, each transformed source point `T·p_i` lands in some target cell `c(i)`. NDT minimizes the negative log-likelihood of the source under the target's piecewise-Gaussian density:

```
E_ndt(T) = − Σ_i exp( − ½ (T·p_i − μ_{c(i)})ᵀ Σ_{c(i)}⁻¹ (T·p_i − μ_{c(i)}) )
```

(The exponential, rather than the raw quadratic, is the form Magnusson uses to keep the score bounded and to soften the influence of outliers. Modern implementations add small regularizers to `Σ_c` for stability when a cell sees few points.)

Two practical consequences flow from this:

- **Smoother loss landscape.** Because the target is now a continuous density rather than a point set, the cost surface is smoother and has a noticeably **larger basin of convergence** than ICP. NDT tolerates worse initial transforms.
- **Voxel size is the dominant hyperparameter.** Too small and each cell sees too few points to estimate a meaningful covariance; too large and the Gaussians blur over distinct surfaces and the alignment biases. A common production choice is 1 m for outdoor automotive LiDAR; Autoware exposes it as a tunable.

NDT is the default registration in Autoware's `ndt_localizer` / `ndt_scan_matcher` for vehicle pose against a prior point-cloud map. It does not need a target KD-tree, only the voxel hash, which is part of why it scales well to dense map clouds.

## GICP — Generalized ICP

Segal, Haehnel, and Thrun introduced GICP at RSS 2009 as a probabilistic generalization that subsumes both ICP variants and point-to-plane. The construction estimates a local covariance `C^A_i` at each source point and `C^B_i` at each target point (typically from the K nearest neighbors). GICP then minimizes

```
E_gicp(T) = Σ_i d_iᵀ ( C^B_i + T C^A_i Tᵀ )⁻¹ d_i ,    d_i = T·p_i − q_i
```

The information matrix `( C^B_i + T C^A_i Tᵀ )⁻¹` weights each correspondence by how confident the local geometry is along each direction. Pick the source and target covariances to be isotropic and you recover point-to-point ICP; pick them to be highly anisotropic along surface normals (i.e. "infinite" tangentially, "small" along the normal) and you recover point-to-plane. The probabilistic formulation is the common parent.

In practice this means GICP handles **partial-overlap and locally-planar regions** more gracefully than either parent, at the cost of estimating per-point covariances and inverting them every iteration. Production SLAM stacks (FAST-LIO and LIO-SAM use GICP-flavored sub-modules at the SLAM level — see [[2_6_slam_essentials_EN|Ch 2 §2.6]]) routinely choose GICP when compute allows.

> [!tip] Choosing between the three
> If you already have a good prior and a structured scene, point-to-plane ICP is the cheapest and fastest. If you need a larger basin of convergence (e.g., relocalizing into a prior map after a brief outage), prefer NDT. If you can afford the per-point covariance work and need robustness on partial overlap or anisotropic geometry, GICP is the production default.

## Four perception roles registration plays in Ch 5

This is the section's pedagogical center: the argument for why registration belongs in a *detection* chapter, not just a localization one.

### Role 1 — Inter-sweep deskew refinement

[[5_1_pointcloud_preprocessing_EN|§5.1]] explained that motion compensation ("deskew") rewrites every point in a sweep to a common timestamp using the ego-pose trajectory across the ~100 ms a 10 Hz spinning sensor takes to acquire one revolution. The classical pipeline gets that trajectory from IMU and wheel odometry. When that source is insufficient — high yaw rates that exceed a short-baseline IMU's effective bandwidth, accumulated bias drift, or a gap between IMU and wheel-odom updates — the deskewed cloud still shows curvature artifacts: a doubled lane edge, a smeared pole, a bent guardrail.

Scan-to-scan ICP or GICP between consecutive sweeps refines the **inter-sweep pose estimate** (or, in continuous-time formulations, the spline parameters of the trajectory) that the deskew transform consumes. The deskew operation itself does not change. **Registration refines poses, not timestamps.**

The downstream payoff is concrete: clustering ([[5_3_clustering_EN|§5.3]]) and shape fitting ([[5_4_object_shape_fitting_EN|§5.4]]) operate on the deskewed cloud. A 1° yaw error during a sweep at 30 m range translates into ~0.5 m of lateral displacement at the far edge of the cluster, which is enough to merge two parked cars or split a truck.

### Role 2 — Map subtraction for change detection

Autoware's `compare_map_segmentation` registers the live cloud to a prior point-cloud map of the static environment, then *subtracts* the matched portion. What remains — points the prior map does not explain — are the dynamic obstacles. This is **classical detection by elimination**: instead of identifying objects, identify everything that is *not* the map.

The registration step here is what makes the subtraction safe. A naive nearest-neighbor subtraction in a fixed frame fails the moment ego-pose drift accumulates more than a voxel; the apparent "residual" is dominated by the static scene shifted by drift. GICP or NDT scan-to-map alignment, run at a sub-frame cadence (every Nth frame, with the most recent transform held in between), keeps the residual confined to genuinely dynamic content. Map subtraction is one of the load-bearing classical pieces that survives inside DL-primary stacks ([[5_9_deployment_runtime_EN|§5.9]]).

### Role 3 — Multi-frame accumulation alignment

Sparse far-range objects benefit from accumulating several sweeps into a denser cloud before clustering or fitting. The naive accumulation — just transform each sweep by the recorded ego-pose and union the points — produces the **doubled-car artifact**: the moving car at frame `k−2` lands a meter or two away from the moving car at frame `k`, and the cluster you fit a box to is two cars long.

There are two failure sources here, and registration addresses one cleanly. Ego-motion drift (the world doesn't actually move; our pose did) is corrected by registering each sweep to the previous one (or to a short rolling reference) and using the registered transform to accumulate. Object motion (dynamic actors do move during the accumulation window) is *not* a registration problem — it requires track-aware compensation in [[5_5_classical_tracking_EN|§5.5]]. The classical division of labor is: registration handles the static scene; tracking handles the dynamic actors.

### Role 4 — Map-aided ROI gating consistency

[[5_7_occupancy_freespace_map_roi_EN|§5.7]] uses a BEV ROI lookup table — drivable-road and junction polygons rasterized into a grid — to gate clustering and fitting onto cells the HD-map says are interesting. The gating is correct only if the live cloud and the map are expressed in the same frame.

Frame consistency is owned primarily by TF and by map-relative localization ([[2_5_map_relative_localization_EN|Ch 2 §2.5]]), not by registration. Registration is **one mechanism** for obtaining or correcting that alignment when localization-only is insufficient — for example, in GNSS-denied zones (urban canyons, tunnels), in regions where the prior map is stale enough that GNSS-+-IMU alignment falls outside the gating tolerance, or when the localization pipeline itself has degraded and must be re-anchored. In a healthy stack, TF carries the alignment for free; registration is the recovery mechanism, not the routine path.

### The fifth role: localization itself

Localization, the use Ch 2 §2.3 already introduced, is the fifth role. The reader has met it; this section provides the algorithmic depth that pointer promised.

## Production references

- **PCL.** `pcl::IterativeClosestPoint` (point-to-point), `pcl::IterativeClosestPointWithNormals` (point-to-plane), and `pcl::GeneralizedIterativeClosestPoint` are the standard implementations. They share the same `setInputSource` / `setInputTarget` / `align` API, so swapping algorithms in a perception node is a matter of changing the typedef.
- **Autoware Universe.** `ndt_scan_matcher` and `ndt_localizer` provide NDT-based vehicle pose against a pre-built point-cloud map; `compare_map_segmentation` is the map-subtraction node from Role 2.
- **SLAM modules.** FAST-LIO and LIO-SAM use registration as a sub-module inside a tightly coupled LiDAR-inertial estimator — see [[2_6_slam_essentials_EN|Ch 2 §2.6]] for the SLAM-level treatment. From Ch 5's perspective those stacks are *consumers* of registration, not what this section teaches.

## Failure modes (catalog entries)

> [!warning] Failure modes for §5.10 catalog
> | id | cause | observable_symptom | downstream_hazard | mitigation | validation_test |
> |---|---|---|---|---|---|
> | `5_6.fm.icp_local_minimum` | ICP basin is small; a poor initial transform or near-symmetric geometry traps the optimizer in the wrong local minimum. | Aligned cloud appears rotated by a small angle or shifted by one structural period (one pillar, one parking-bay width); residual energy plateaus high. | Map subtraction (Role 2) flags large swaths of static scene as "dynamic," producing ghost obstacles and triggering false braking; accumulation (Role 3) doubles structural features. | Seed ICP with an IMU/wheel-odom prior; gate convergence on residual energy and on transform delta from the prior; fall back to NDT when the prior uncertainty is large. | Replay rosbags with synthetic IMU-bias injection across a tunnel / featureless-highway segment; assert ghost-obstacle rate stays below the §11.3 threshold. |
> | `5_6.fm.ndt_voxel_size_mismatch` | NDT voxel size chosen for one sensor and reused on another (e.g., HDL-32 tuning carried over to a sparser MEMS sensor): cells receive too few points to estimate a covariance, or so many that distinct surfaces are blurred together. | Per-cell covariances become rank-deficient or isotropic-by-default; alignment converges but with a small persistent bias; localization drifts slowly along walls and façades. | Map-aided ROI gating (Role 4) drifts off the drivable polygon; clusters near ROI edges flicker in and out of the gated set, producing intermittent obstacles. | Calibrate voxel size per sensor class; monitor median points-per-cell at runtime and flag when it falls outside `[10, 200]` for the chosen voxel size. | Spot-check against a held-out sequence per sensor class with known ground-truth pose; require alignment bias under 0.05 m / 0.2°. |
> | `5_6.fm.gicp_degenerate_covariance` | GICP's per-point covariance estimation collapses on degenerate local neighborhoods (a single returns-thin scan line, a flat highway with no curbs in view); the information matrix becomes ill-conditioned. | Per-iteration step blows up or stalls; runtime jitter spikes; alignment occasionally returns a transform far outside the IMU prior. | Deskew refinement (Role 1) injects a worse trajectory than the IMU-only baseline, *amplifying* the artifact it was supposed to remove. | Add an isotropic regularizer `λI` to each covariance; cap per-iteration step size; sanity-check the GICP output against the IMU prior and reject outliers. | In §11.3 scenario testing, add featureless-highway and single-line-thin-cloud sequences and assert that GICP rejection rate stays under threshold and the IMU fallback engages cleanly. |

The IDs follow the chapter convention `5_6.fm.<short_slug>` defined in the [[5_10_safety_and_validation_EN|§5.10]] catalog contract.

## Runtime-budget row

Per the [[5_9_deployment_runtime_EN|§5.9]] contract, the section commits one row to the chapter-wide runtime table. Values below assume GICP scan-to-map at 10 Hz against a Velodyne HDL-32E live cloud (~70k points/sweep after voxel downsampling), running on the host CPU of a Jetson-class edge module, with the prior point-cloud map already memory-resident.

| stage | compute | frame_rate_assumption | point_count_assumption | latency_p50_ms | latency_p99_ms | memory_mb | cadence | tf_freshness_assumption | assumptions_and_caveats |
|---|---|---|---|---|---|---|---|---|---|
| `5_6_registration` | cpu | 10 Hz spinning | ~70k voxel-downsampled (HDL-32E) | 20 | 45 | 200 | every-frame | ≤ 50 ms | GICP scan-to-map; prior point-cloud map memory-resident; voxel downsample at 0.2 m; 4 OMP threads; KD-tree rebuild amortized; point-to-plane ICP would be ~half the latency, NDT comparable to GICP at larger voxel; for map subtraction (Role 2) cadence drops to every-3-frames in production; for inter-sweep deskew refinement (Role 1) cadence is every-frame and uses point-to-plane ICP rather than GICP. |
