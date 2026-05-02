---
chapter: 5
section: 3
title: Clustering
language: EN
workflow_status: reviewing
tags:
  - book/section
  - book/chapter-5
  - lang/EN
---

# 5.3 Clustering

The Ch 5 classical pipeline is `preprocess → ground → cluster → fit → track`. [[5_1_pointcloud_preprocessing_EN|§5.1]] publishes a deskewed, filtered `PointCloud2` in `base_link`; [[5_2_ground_segmentation_EN|§5.2]] leaves a residual non-ground cloud. This section turns that residual point cloud into candidate objects. The output contract is simple: a cluster is point indices plus a cluster-bbox approximation, and [[5_4_object_shape_fitting_EN|Ch 5 §5.4]] fits L-shapes, PCA-OBBs, min-area rectangles, convex hulls, and class-prior box dimensions to those clusters.

A few inherited concepts before the algorithms. The `PointCloud2` schema from [[1_3_lidar_calibration_EN|Ch 1 §1.3]] / [[1_4_sensor_time_sync_EN|Ch 1 §1.4]] carries `x, y, z, intensity, ring, time` per point — clustering uses `x, y, z`, and range-image and scan-line variants additionally need `ring` and per-point `time`. The `lidar → base_link` extrinsic from [[1_1_coordinate_frames_EN|Ch 1 §1.1]] places points in a vehicle-fixed frame, so the cluster-bbox approximation this section publishes is in `base_link` unless the operator chose otherwise. Clustering quality also inherits §5.1 deskew quality: residual points produced from a stale `/tf` or missing per-point `time` carry sweep-direction smear, and the smear becomes split or merged clusters in this section before §5.4 ever sees a box.

The prerequisite concept to restate explicitly is density. A spinning LiDAR samples angles, not meters; at twice the range, the same angular step covers roughly twice the lateral distance in both image axes, so point density falls approximately quadratically with range. The residual cloud is uniformly preprocessed, but it is not uniformly dense.

> [!info]
> Clustering in this section is proposal generation, not classification. A cluster says "these non-ground points may belong to one object"; shape fitting, Tracking-by-detection in [[5_5_classical_tracking_EN|Ch 5 §5.5]], map/ROI checks in [[5_7_occupancy_freespace_map_roi_EN|Ch 5 §5.7]], and validation in [[5_10_safety_and_validation_EN|Ch 5 §5.10]] decide whether that proposal is usable.

## Euclidean clustering

Euclidean clustering is the standard entry point because it matches the raw point-cloud representation from §5.1. PCL exposes it as `pcl::EuclideanClusterExtraction`: build a KD-tree over the residual non-ground cloud, flood-fill neighbors within a fixed cluster tolerance, and repeat until every point is assigned or rejected by size gates. It is fast enough for a CPU hot path when the residual cloud is already downsampled.

In C++ terms, the core knobs are familiar:

```cpp
pcl::EuclideanClusterExtraction<pcl::PointXYZI> ec;
ec.setClusterTolerance(0.45);       // meters
ec.setMinClusterSize(10);
ec.setMaxClusterSize(25000);
ec.setSearchMethod(kdtree);
ec.setInputCloud(non_ground_cloud);
ec.extract(cluster_indices);
```

The fixed tolerance is both the strength and the weakness. On small uniform-density patches, Euclidean clustering gives stable proposals with little parameter ceremony. On a range-biased road scene, one value must serve pedestrians at 30 m, a truck at 12 m, and two adjacent cars at 8 m. If the tolerance separates close near-field vehicles, the far pedestrian fragments into two or three clusters. If it keeps far sparse pedestrians intact, large vehicles at 10 m merge with poles, parked cars, or clutter.

> [!warning]
> The range-bias failure is not a rare corner case. A single Euclidean tolerance over-segments sparse far objects and under-segments dense near objects in the same frame. Tuning it on one radial band usually moves the error to another band.

Practical systems soften the problem with near/mid/far branches, different tolerances and minimum sizes, ROI gates for static façades, or downstream association in [[5_5_classical_tracking_EN|Ch 5 §5.5]]. These are engineering patches, not mathematical fixes.

## DBSCAN

DBSCAN, introduced by Ester et al. in 1996, frames clustering as density reachability. Its main parameters are `eps`, the neighborhood radius, and `minPts`, the number of points needed to make a core point. Points reachable through chains of core points join the same cluster; points not density-reachable from any core point are noise.

Compared with Euclidean clustering, DBSCAN gives a cleaner noise model. Rain returns, tire spray, glass reflections, or isolated high returns do not need to become singleton clusters if they fail the density test. DBSCAN also handles non-convex shapes because density reachability can follow a curved surface or partial vehicle outline.

The hard part is that `eps` and `minPts` inherit the same range-density problem. Near the sensor, `minPts=6` inside `eps=0.4 m` may be permissive; at 40 m, the same object may not contain enough returns to create a core point. Increasing `eps` recovers far objects but bridges near objects. Lowering `minPts` admits rain, fence clutter, and ground-segmentation leftovers.

HDBSCAN is the usual brief escape hatch: it estimates clusters over a hierarchy of density levels and can reduce manual `eps` tuning. It is useful offline and in some CPU-rich pipelines, but it is not the classical baseline for a small embedded Ch 5 detector.

## Range-image connected components

Range-image connected components use the spherical projection introduced in §5.1. A range image stores each LiDAR firing in a 2-D grid indexed by ring/elevation and azimuth, with range as the main value. For a spinning LiDAR, adjacent pixels usually correspond to adjacent beams or azimuth samples, so image connectivity preserves sensor topology that a KD-tree discards.

Bogoslavskyi & Stachniss proposed a fast 3-D LiDAR segmentation method in 2016 that labels connected components directly on this projection. The key test asks whether neighboring pixels lie on the same surface or on a different surface separated by a depth jump. Let `d1` and `d2` be the shorter and longer ranges of two adjacent pixels, and let `α` be the angular step between those beams (a fixed sensor parameter). The local surface angle `β` between the two returns and the line of sight to the closer one is

```
β = atan2( d2 · sin α ,  d1 − d2 · cos α )
```

When `β` is close to 90° the two returns sit on a steep, nearly perpendicular surface (a vehicle side, a wall) and the neighbor connects to the same component; when `β` is small the depth gap is too large to be one local surface and a new component starts. The crucial property of this test is that it is **range-adaptive by construction**: at far range, the same physical separation produces a smaller `α · d` baseline, and a fixed-metric-radius neighbor query (Euclidean clustering's `pcl::EuclideanClusterExtraction` tolerance, or DBSCAN's `eps`) would either bridge unrelated returns near the sensor or fail to bridge legitimate ones in the distance. Bogoslavskyi's angle-test reasons in angular adjacency rather than metric radius, so the same threshold works across the range bands that destroy a single Euclidean tolerance.

In words: if two adjacent beams hit the same slanted car side, their ranges differ smoothly and `β` is plausible. If one beam hits a pedestrian at 12 m and the next goes to a wall at 30 m, the range discontinuity is too large for one local surface and `β` collapses toward zero.

Range-image clustering is attractive before voxelization or after preserving ring/azimuth metadata. It is `O(N)` over occupied pixels, cache-friendly, and deterministic. It also keeps scan-line evidence that Euclidean clustering loses.

It has its own failure modes. Missing pixels, non-repetitive scan patterns, motion distortion from bad deskew, and multi-LiDAR fused clouds can create artificial adjacency or holes in the range image. A rooftop spinning LiDAR is the friendly case; a fused surround cloud should keep per-sensor projections when possible.

## Scan-line variants and heuristics

Scan-line and row-wise variants apply the same idea with less machinery. A row pass splits each ring whenever consecutive points show a depth jump, lateral gap, or height discontinuity; a second pass links compatible segments across neighboring rings. This is common in embedded stacks because it avoids a general KD-tree search and exposes interpretable thresholds.

The danger is threshold drift. A depth-jump threshold that works for a 64-beam sensor at 10 Hz can be wrong for a 32-beam sensor, a different beam pattern, or a firmware timing change. Row-wise methods should log ring index, azimuth gap, and range-discontinuity statistics as diagnostics.

> [!tip]
> Preserve `ring` and per-point `time` through §5.1 when a later branch wants range image or scan-line clustering. A voxel-only cloud can still be clustered in 3-D, but it cannot recover the original row adjacency reliably.

## Cluster post-processing

All three clustering families need post-processing before §5.4 consumes them. Minimum size gates remove isolated noise and ground leftovers; maximum size gates prevent a façade, guardrail strip, or embankment from becoming one giant object. Height and aspect-ratio sanity checks catch obvious non-objects: a 0.05 m tall "vehicle" is likely residual ground, and a 40 m long cluster is likely static structure unless the ODD includes unusual trailers.

The cluster-bbox approximation at this stage is not the final box. It is a cheap axis-aligned or coarse oriented bound used for diagnostics, gating, and handoff. [[5_4_object_shape_fitting_EN|Ch 5 §5.4]] owns the geometric fit: L-shape via Zhang 2017 search, PCA-OBB, min-area rectangle, convex hull, and class-prior dimensions. §5.3 should preserve point indices so §5.4 can re-read the original residual points rather than fit to a lossy summary.

Deduplication is necessary when multiple branches run in parallel. A near-field Euclidean branch and a far-field range-image branch can report the same vehicle; a map-subtraction branch can overlap a raw residual branch. Cluster-level deduplication compares point-index overlap, 3-D bbox IoU, centroid distance, and timestamp before publishing one candidate set.

Where classical clustering still ships is best understood by deployment bucket rather than as a single claim. In **restricted, low-speed ODDs** (campus shuttles, factory yards, airport tugs) classical clustering can remain primary, because the ODD bounds the variety of objects and false-positive cost is lower. In **DL-primary L4 robotaxi and consumer NOA stacks**, learned semantic / instance segmentation owns the primary proposal path; classical clustering survives in narrower roles — embedded fallback, Generic Obstacle Detection over occupancy, a pre-filter that cheaply rejects ground-segmentation leftovers before a learned head, and a regression / diagnostic baseline when learned perception is degraded. In **research and academic** contexts classical clustering remains the canonical baseline against which DL detectors are measured. [[5_9_deployment_runtime_EN|Ch 5 §5.9]] picks up the production-survival argument; this section's claim is bounded to "classical clustering retains specific bounded roles," not "classical clustering is still a viable primary path on the open road."

> [!warning] Failure modes for §5.10 catalog
> | id | cause | observable_symptom | downstream_hazard | mitigation | validation_test |
> |---|---|---|---|---|---|
> | `5_3.fm.range_bias_oversegmentation` | Fixed Euclidean clustering tolerance is too small for sparse far returns; point density falls quadratically with range. | A pedestrian or cyclist at 30 m appears as 2-3 clusters, often split by torso/leg or front/back returns. | §5.4 fits multiple small boxes; Tracking-by-detection in §5.5 creates duplicate tracks or drops the object as unstable. | Use radial bands with range-aware tolerances; preserve a range image branch; tune minimum size by range, not globally. | Replay far-pedestrian and far-cyclist bags at 20-50 m; assert cluster count per actor remains one or is merged before tracking. |
> | `5_3.fm.merged_close_vehicles` | Tolerance or DBSCAN `eps` is too large in dense near-field regions, or a ground/guardrail residual bridges objects. | Two adjacent parked cars, a car and pole, or a truck and roadside clutter become one elongated cluster. | §5.4 fits an oversized box that blocks free space or biases planner clearance. | Apply near-field tighter tolerances, remove bridge-like low-height residuals, split clusters by range-image depth jumps, and gate maximum aspect ratio. | Use close-parked-vehicle and curbside-clutter scenarios; require fitted boxes not to exceed actor ground-truth length by the §5.10 threshold. |
> | `5_3.fm.dbscan_eps_too_small` | DBSCAN `eps`/`minPts` tuned on near dense objects rejects sparse far objects as noise. | Valid non-ground returns exist visually, but no cluster is published for a distant pedestrian, cone, or small obstacle. | Missed detection propagates directly to shape fitting and tracking; planner receives no obstacle. | Tune `eps` and `minPts` per radial band or sensor ring density; monitor rejected-noise rates by range bin. | Sweep `eps`/`minPts` on labeled far-small-object logs and require recall above the deployment threshold by range bin. |
> | `5_3.fm.range_image_projection_holes` | Missing rings, bad deskew, non-repetitive scan pattern, or fused multi-LiDAR projection creates artificial holes or adjacency in the range image. | Components flicker frame to frame, thin objects disappear, or two surfaces connect through a projection artifact. | §5.4 receives unstable point sets; §5.5 track management alternates between initiation and deletion. | Keep per-sensor projections, validate ring/time fields, fall back to 3-D clustering when projection quality diagnostics fail. | Replay high-yaw-rate and multi-LiDAR fusion bags; compare component stability with projection diagnostics enabled. |
> | `5_cross.fm.deskew_then_cluster_doubling` | Stale `/tf`, missing per-point `time`, or interpolation gaps in §5.1 deskew leave residual smear that survives ground segmentation. | A single moving vehicle or guardrail appears as two parallel clusters, or one elongated cluster is split into front and rear halves along the scan direction. | §5.4 fits two undersized boxes per actor or one box with the wrong yaw; §5.5 produces ID switches at every turn or hard brake. | Surface this catalog entry from §5.3 because the symptom appears here, but the fix is at §5.1: enforce per-point timestamp presence, monitor `/tf` age, and reject frames outside the ego-pose interpolation window. | Replay turning, braking, and high-yaw-rate logs with deskew-on/off comparisons; require stable cluster count per actor across the deskew toggle. (Owned by §5.10 per the cross-section convention; named here because §5.3 is where the symptom first becomes visible.) |

| stage | compute | frame_rate_assumption | point_count_assumption | latency_p50_ms | latency_p99_ms | memory_mb | cadence | tf_freshness_assumption | assumptions_and_caveats |
|---|---|---|---|---:|---:|---:|---|---|---|
| `5_3_clustering` | cpu | 10 Hz mechanical-spinning | residual non-ground cloud ~30k points after §5.2 | 8 | 24 | 96 | every-frame | ≤ 50 ms | **Illustrative** CPU-only budget for Euclidean clustering on a Jetson-class CPU using a KD-tree over the residual cloud, radial clipping already applied, no learned segmentation, no GPU, cluster post-processing included but shape fitting excluded; latency varies with voxel size, cluster tolerance, number of branches, and scene clutter. |
