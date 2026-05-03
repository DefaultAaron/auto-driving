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

Euclidean clustering is the standard entry point because it matches the raw point-cloud representation from §5.1. PCL exposes it as `pcl::EuclideanClusterExtraction`: build a KD-tree over the residual non-ground cloud, flood-fill neighbors within a fixed cluster tolerance, and repeat until every point is assigned or rejected by size gates. It is fast enough for a CPU hot path when the residual cloud is already downsampled, and it is the baseline most readers meet first in Autoware-style or PCL-heavy code.

The mechanics are simple enough to read in production code once the flood-fill is explicit. First, insert every non-ground point into a KD-tree keyed by `x, y, z`. Second, keep a `processed` bitset. Third, scan points in input order; when an unprocessed seed appears, run a radius search with `cluster_tolerance`, push every unprocessed neighbor into the same work queue, mark each visited point, and continue until the queue is empty. Fourth, accept the collected point indices only if `min_cluster_size ≤ size ≤ max_cluster_size`. The KD-tree accelerates the neighbor query; the cluster itself is still just a connected component under a fixed metric radius.

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

Worked example. Suppose the residual cloud contains six 2-D points, using `z=0` here only to keep the arithmetic visible:

| point | coordinate |
|---|---|
| `p0` | `(0.00, 0.00)` |
| `p1` | `(0.22, 0.05)` |
| `p2` | `(0.46, 0.03)` |
| `p3` | `(1.25, 0.00)` |
| `p4` | `(1.55, 0.03)` |
| `p5` | `(3.00, 0.00)` |

With `cluster_tolerance = 0.35 m`, the seed `p0` reaches `p1` because their distance is about `0.23 m`; `p1` reaches `p2` because their distance is about `0.24 m`. The component is therefore `{p0, p1, p2}` even though `p0` and `p2` are `0.46 m` apart: connectivity is transitive through the flood-fill. The next unprocessed seed is `p3`, which reaches `p4`, so `{p3, p4}` becomes the second component. `p5` has no neighbor inside `0.35 m`, so it is rejected if `min_cluster_size=2` or accepted as a singleton if the minimum is lowered.

```python
pts = [(0,0), (.22,.05), (.46,.03), (1.25,0), (1.55,.03), (3,0)]
tol = 0.35
clusters = []
seen = set()
for i, p in enumerate(pts):
    if i in seen: continue
    q, c, seen = [i], [], seen | {i}
    while q:
        j = q.pop(); c.append(j)
        for k, r in enumerate(pts):
            if k not in seen and ((p:=pts[j])[0]-r[0])**2 + (p[1]-r[1])**2 <= tol**2:
                seen.add(k); q.append(k)
    clusters.append(c)
```

The fixed tolerance is both the strength and the weakness. On small uniform-density patches, Euclidean clustering gives stable proposals with little parameter ceremony. On a range-biased road scene, one value must serve pedestrians at 30 m, a truck at 12 m, and two adjacent cars at 8 m. If the tolerance separates close near-field vehicles, the far pedestrian fragments into two or three clusters. If it keeps far sparse pedestrians intact, large vehicles at 10 m merge with poles, parked cars, or clutter.

> [!example] Range bias from angular sampling
> ```
> adjacent beams separated by angular step α
>
> near range d = 10 m:      lateral spacing ≈ α·d
> lidar o----\----\         α = 0.2° = 0.00349 rad → 0.035 m
>             \    \        dense returns: parked car and pole may bridge
>
> far range d = 40 m:       lateral spacing ≈ α·d
> lidar o----------\----\   α = 0.2° = 0.00349 rad → 0.140 m
>                   \    \  sparse returns: pedestrian torso/legs may split
> ```
> A wall is forgiving because many beams land on one surface. A vehicle near the sensor is over-connected through dense side returns. A pedestrian far away can be under-connected because the same angular beam spacing covers a much larger metric gap.

Usage usually starts with `setClusterTolerance(0.45)` for an urban residual cloud after voxel filtering, `setMinClusterSize(10)` to reject isolated returns, and a large `setMaxClusterSize` such as `25000` to prevent façades from dominating the output. The first tuning knob is tolerance. Increasing it reduces far-object fragmentation but merges close vehicles, poles, and guardrail leftovers. Decreasing it separates near clutter but fragments far pedestrians and cyclists. Minimum size should be range-aware when possible: a global minimum that rejects rain near the sensor may also reject valid small actors at long range. Maximum size is a sanity gate, not an object model; if it fires often, the upstream ground segmentation or static-structure filtering is probably leaking.

The operational fit is best in bounded ODDs where the object catalog is simple and the background is known: yards, ports, campus routes, parking lots, and map-filtered curbside scenes. It is weaker in dense urban scenes where bicycles, poles, vegetation, and parked vehicles share tight spatial gaps. The runtime budget row at the end of the section assumes this style of KD-tree clustering over about `30k` residual points; if the stack runs three radial branches, the branch count becomes a first-order latency knob even when each branch is individually simple.

> [!warning]
> The range-bias failure is not a rare corner case. A single Euclidean tolerance over-segments sparse far objects and under-segments dense near objects in the same frame. Tuning it on one radial band usually moves the error to another band.

Practical systems soften the problem with near/mid/far branches, different tolerances and minimum sizes, ROI gates for static façades, or downstream association in [[5_5_classical_tracking_EN|Ch 5 §5.5]]. These are engineering patches, not mathematical fixes. In a DL-primary stack, PointNet / PointNet++-style point-set semantic segmentation or voxel networks normally own the primary proposal path; Euclidean clustering survives as a fallback, a regression baseline, or a cheap cleanup branch. Its catalog connections are `5_3.fm.range_bias_oversegmentation` and `5_3.fm.merged_close_vehicles`: the first is fragmentation from sparse far returns, the second is bridge formation in the dense near field.

## DBSCAN

DBSCAN, introduced by Ester et al. in 1996, frames clustering as density reachability. Its main parameters are `eps`, the neighborhood radius, and `minPts`, the number of points needed to make a core point. Points reachable through chains of core points join the same cluster; points not density-reachable from any core point are noise. Relative to Euclidean clustering, the key change is that a sparse connected chain is not enough. The seed must live in a locally dense neighborhood before it can grow a cluster.

The mechanics are a repeated region query. For each unvisited point, find all neighbors within `eps`. If the neighbor count is below `minPts`, label the point as noise for now. If the count meets `minPts`, create a new cluster, mark the point as core, and expand through its neighbors. Every neighbor that also has at least `minPts` neighbors contributes its neighborhood to the expansion queue. A non-core point reached by a core point becomes a border point; it belongs to the cluster but does not grow it further. Implementations commonly use a KD-tree or spatial hash for the region query, so the code shape still resembles Euclidean clustering, but the label semantics differ: `core`, `border`, and `noise` are first-class outcomes.

Compared with Euclidean clustering, DBSCAN gives a cleaner noise model. Rain returns, tire spray, glass reflections, or isolated high returns do not need to become singleton clusters if they fail the density test. DBSCAN also handles non-convex shapes because density reachability can follow a curved surface or partial vehicle outline.

Worked example. Use `eps = 0.35 m` and `minPts = 3`, counting the point itself in `minPts`, on this 2-D set:

| point | coordinate | neighborhood within `eps` | role |
|---|---:|---|---|
| `a` | `(0.00, 0.00)` | `a,b,c` | core |
| `b` | `(0.20, 0.02)` | `a,b,c,d` | core |
| `c` | `(0.05, 0.22)` | `a,b,c` | core |
| `d` | `(0.48, 0.02)` | `b,d` | border |
| `e` | `(1.40, 0.00)` | `e,f,g` | core |
| `f` | `(1.62, 0.04)` | `e,f,g` | core |
| `g` | `(1.45, 0.24)` | `e,f,g` | core |
| `h` | `(2.60, 0.00)` | `h` | noise |

Starting at `a`, DBSCAN creates cluster 1. `a`, `b`, and `c` are core points, so their neighborhoods are expanded. `d` is reached from `b`, so it becomes a border point in cluster 1, but it does not expand because it has only two neighbors. Starting later at `e`, DBSCAN creates cluster 2 with `e,f,g`. `h` remains noise. A Euclidean flood-fill with a similar radius would also connect `d`, but it would not tell the downstream system that `d` sits on the density fringe.

The hard part is that `eps` and `minPts` inherit the same range-density problem. Near the sensor, `minPts=6` inside `eps=0.4 m` may be permissive; at 40 m, the same object may not contain enough returns to create a core point. Increasing `eps` recovers far objects but bridges near objects. Lowering `minPts` admits rain, fence clutter, and ground-segmentation leftovers.

Usage in a classical detector often starts with `eps = 0.4 m` and `minPts = 6` on a downsampled residual cloud. Increase `eps` when far pedestrians or cones become noise; expect the observable symptom to move toward merged parked cars and curbside clutter. Decrease `eps` when adjacent near-field actors bridge; expect far sparse objects to disappear first. Increase `minPts` when rain or isolated ground leftovers create nuisance clusters; decrease it when valid small obstacles become noise. A useful diagnostic is rejected-noise rate by range bin. If the far bins have high rejected-noise counts while visual inspection shows valid objects, the parameter pair is tuned to near-field density.

DBSCAN is most useful when the scene has nuisance returns that Euclidean clustering would otherwise publish as tiny clusters. It is less useful when the dominant problem is range bias rather than noise, because the density test still uses a metric radius. On a robotaxi perception stack, learned instance segmentation usually displaces DBSCAN for primary proposals because semantic context separates a bicycle from a pole even when their point sets are close. DBSCAN remains a useful diagnostic baseline: if a learned detector misses an object that DBSCAN groups cleanly, the failure is probably semantic or training-data related; if DBSCAN also fails, the raw geometry may be too sparse or contaminated.

HDBSCAN is the usual brief escape hatch: it estimates clusters over a hierarchy of density levels and can reduce manual `eps` tuning. It is useful offline and in some CPU-rich pipelines, but it is not the classical baseline for a small embedded Ch 5 detector. It is ML-adjacent in the sense that it learns less from labels than a neural segmenter but tries to avoid one global density scale; it is not a DL replacement for semantic instance segmentation. DBSCAN's catalog connection is `5_3.fm.dbscan_eps_too_small`, and it also contributes to `5_3.fm.merged_close_vehicles` when `eps` is increased to rescue far actors.

## Range-image connected components

Range-image connected components use the spherical projection introduced in §5.1. A range image stores each LiDAR firing in a 2-D grid indexed by ring/elevation and azimuth, with range as the main value. For a spinning LiDAR, adjacent pixels usually correspond to adjacent beams or azimuth samples, so image connectivity preserves sensor topology that a KD-tree discards.

Bogoslavskyi & Stachniss proposed a fast 3-D LiDAR segmentation method in 2016 that labels connected components directly on this projection. The key test asks whether neighboring pixels lie on the same surface or on a different surface separated by a depth jump. This is the anchor algorithm for the section because it solves the range-bias problem at the representation level: the neighbor relation is angular and topological before it is metric.

Mechanics start with projection. For each residual point `(x, y, z)`, compute `range = sqrt(x² + y² + z²)`, `azimuth = atan2(y, x)`, and elevation `θ = atan2(z, sqrt(x² + y²))`. If the sensor provides a trustworthy `ring` field, use it as the row index. If not, approximate `ring = round((θ - θ_min) / Δθ)` for a uniform vertical pattern; this approximation is fragile for non-uniform beam layouts. The column is `col = round((azimuth - azimuth_min) / Δφ) mod W`, where `Δφ` is the horizontal angular step. Each occupied cell stores range and the original point index; when multiple points project to one cell, keep the closest return or a short per-cell list depending on the stack's return policy.

The connected-components pass then runs on the occupied range image. A BFS implementation is easiest to read: scan cells row-major; when an unlabeled occupied cell appears, create a label, push the cell into a queue, and test its 4-neighbors or 8-neighbors. A two-pass implementation is also common: first pass assigns provisional labels and records label equivalences; second pass resolves the union-find labels. In both versions, the only question for a neighbor pair is whether the range discontinuity is small enough to belong to one surface. Empty cells, invalid ranges, and azimuth wraparound require explicit handling; otherwise a component can leak across missing data or split at the image seam.

Compact pseudocode looks like this, with `connect()` standing for the β test below:

```python
for cell in occupied_cells(range_image):
    if label[cell]: continue
    q, label[cell] = [cell], next_label()
    while q:
        u = q.pop()
        for v in neighbors4(u):
            if occupied(v) and not label[v] and connect(u, v):
                label[v] = label[cell]
                q.append(v)
```

That short loop hides two production details. First, `neighbors4()` must choose the correct `α` for the neighbor direction: horizontal azimuth step for left/right, vertical ring spacing for up/down, and sensor-specific handling for non-uniform rings. Second, the label image is not the output object; it is an intermediate index that must be converted back to original point indices after component filtering.

Following the original paper's convention, let `d1 = max(r_a, r_b)` be the **longer** range of the two adjacent pixels and `d2 = min(r_a, r_b)` the **shorter** range; let `α` be the angular step between those beams (a fixed sensor parameter). The local surface angle `β` is the angle, measured at the closer return, between the line of sight to that return and the chord connecting the two returns:

```
β = atan2( d2 · sin α ,  d1 − d2 · cos α )
```

> [!example] β-angle geometry
> ```
> same surface: ranges nearly equal
>
>        far return d1≈10.05
>          *
>         /|
>        / | chord between adjacent returns
> lidar o  |
>        \ |
>         \|
>          * close return d2=10.00
>          β ≈ 90°  → connect
>
> depth jump: one beam passes to background
>
> background d1=30.0   *
>                     /
>                    / chord almost along line of sight
> lidar o-----------*
>             foreground d2=10.0
>             β small → split
> ```

For a same-surface case (`d1 ≈ d2`), the denominator `d1 − d2 cos α` is small (≈ `d · α²/2` for small `α`), the numerator is small but non-zero, and `β` is **close to 90°** — the chord is nearly perpendicular to the line of sight, which is what a steep / radially-oriented surface looks like (a vehicle side, a wall). For a depth-jump case (`d1 ≫ d2`), the denominator is large and positive, the numerator is bounded, and `β` is **small**. The classifier is then a single threshold: connect the neighbor when `β > β_thresh` (e.g. `β_thresh = 10°`); start a new component otherwise. The crucial property of this test is that it is **range-adaptive by construction**. The lateral spacing between neighboring beams *grows* with range (it is approximately `α · d`, as established earlier in this section), so a fixed-metric-radius neighbor query — Euclidean clustering's `pcl::EuclideanClusterExtraction` tolerance, or DBSCAN's `eps` — must trade off: bridge unrelated returns near the sensor (where actors are dense) or fail to bridge legitimate ones at long range (where actors are sparse). Bogoslavskyi's angle-test sidesteps that trade because it does not depend on the metric distance between two points at all; it depends only on the *ratio* `d1/d2` and on the fixed angular step `α`. The same threshold therefore works across range bands that destroy a single Euclidean tolerance.

The threshold rationale is geometric, not magical. `β_thresh = 10°` is permissive for smooth surfaces because same-surface pairs with small `α` produce angles near 90°. It is strict for foreground/background discontinuities because a large ratio `d1/d2` collapses the angle toward the line of sight. The sensor's `α` still matters: vertical adjacency for an HDL-32E or VLP-32C is much coarser than horizontal adjacency, while an HDL-64E has finer vertical sampling. Typical angular steps often cited for these sensors are roughly HDL-32E `1.33°` vertical and `0.16°` horizontal at 10 Hz, HDL-64E `0.43°` vertical and `0.16°` horizontal, and VLP-32C `1.33°` vertical and `0.2°` horizontal. A production implementation should use the sensor calibration table, not assume a uniform `Δθ`.

Worked example. Use `α = 0.2° = 0.00349 rad` and `β_thresh = 10°`. For two neighboring pixels on the same surface, set `d1 = 10.05` and `d2 = 10.0`:

```
numerator   = 10.0 · sin(0.00349)        ≈ 0.0349
denominator = 10.05 − 10.0 · cos(0.00349) ≈ 0.0501
β = atan2(0.0349, 0.0501) ≈ 34.8°
```

This still exceeds `10°`, so the pixels connect. With a smaller depth difference, the angle moves closer to 90°; for example `d1 = 10.005`, `d2 = 10.0` gives `β ≈ 81.7°`. For a depth jump, set `d1 = 30.0` and `d2 = 10.0`:

```
numerator   = 10.0 · sin(0.00349)        ≈ 0.0349
denominator = 30.0 − 10.0 · cos(0.00349) ≈ 20.0001
β = atan2(0.0349, 20.0001) ≈ 0.1°
```

This falls below `10°`, so the labeler starts a new component. If the implementation uses a larger vertical `α` for row-to-row tests, the same depth-jump example can land around the single-digit degrees; the classification remains the same. The important habit is to compute `β` with the actual neighbor direction's angular step.

After labeling, post-processing converts components back into the §5.4 handoff. Reject tiny components by point count, optionally using range-aware size gates so far small objects are not erased. Reject huge components that span walls, embankments, or projection artifacts. Then gather the stored original point indices for each surviving label, compute the cluster-bbox approximation in `base_link`, and publish the index list rather than only the image cells. That projection-back step is not bookkeeping trivia: §5.4 needs the original residual points for L-shape, PCA-OBB, min-area rectangle, convex hull, and class-prior fitting.

The usual implementation order is therefore: project residual points, fill the range image, label connected components with β, reject components by size and projection diagnostics, gather original point indices, compute the approximate bbox, and publish the cluster array. The order matters. If size gating happens before projection-back, it should still use original point counts, not just occupied cell counts, because a near vehicle can place multiple returns into the same angular bin while a far object may occupy only a few bins. If bbox computation happens in image space, it loses the `base_link` contract that §5.4 expects.

In words: if two adjacent beams hit the same slanted car side, their ranges differ smoothly and `β` stays high. If one beam hits a pedestrian at 12 m and the next goes to a wall at 30 m, the range discontinuity makes the chord nearly aligned with the line of sight, and `β` collapses toward zero.

Range-image clustering is attractive before voxelization or after preserving ring/azimuth metadata. It is `O(N)` over occupied pixels, cache-friendly, and deterministic. It also keeps scan-line evidence that Euclidean clustering loses. Usage usually starts with `β_thresh = 10°`, 4-neighbor connectivity for conservative separation, a small-component gate after labeling, and projection diagnostics that track empty-cell rate by ring. Raising `β_thresh` makes the algorithm stricter and can over-segment slanted or sparsely sampled surfaces. Lowering it connects more neighbors and can bridge true depth jumps. If components flicker at azimuth wraparound, inspect seam handling; if thin actors disappear, inspect missing rings and the size gate before changing the angle threshold.

It has its own failure modes. Missing pixels, non-repetitive scan patterns, motion distortion from bad deskew, and multi-LiDAR fused clouds can create artificial adjacency or holes in the range image. A rooftop spinning LiDAR is the friendly case; a fused surround cloud should keep per-sensor projections when possible. The catalog row is `5_3.fm.range_image_projection_holes`, and the cross-section deskew symptom is `5_cross.fm.deskew_then_cluster_doubling`. In DL-primary stacks, RangeNet / SqueezeSeg-style range-image semantic segmentation is the learned analogue: it keeps the projection but replaces the hand-built β test with learned per-pixel semantics and often learned instance grouping. Classical range-image connected components remains useful as a deterministic fallback and as a diagnostic for whether the learned range-image branch is respecting geometry.

## Scan-line variants and heuristics

Scan-line and row-wise variants apply the same idea with less machinery. A row pass splits each ring whenever consecutive points show a depth jump, lateral gap, or height discontinuity; a second pass links compatible segments across neighboring rings. This is common in embedded stacks because it avoids a general KD-tree search and exposes interpretable thresholds.

The mention-level mechanics are: preserve the original ordered ring stream, cut each ring into segments at discontinuities, summarize each segment by point count / min range / max range / height span, and merge adjacent-ring segments if their ranges and endpoints agree. The method is easier to inspect than a full range-image labeler but more sensitive to beam pattern assumptions. Its usage knobs are the per-ring depth-jump threshold and the cross-ring merge threshold; both should be logged by ring and range bin.

The danger is threshold drift. A depth-jump threshold that works for a 64-beam sensor at 10 Hz can be wrong for a 32-beam sensor, a different beam pattern, or a firmware timing change. Row-wise methods should log ring index, azimuth gap, and range-discontinuity statistics as diagnostics.

> [!tip]
> Preserve `ring` and per-point `time` through §5.1 when a later branch wants range image or scan-line clustering. A voxel-only cloud can still be clustered in 3-D, but it cannot recover the original row adjacency reliably.

## Cluster post-processing

All three clustering families need post-processing before §5.4 consumes them. Minimum size gates remove isolated noise and ground leftovers; maximum size gates prevent a façade, guardrail strip, or embankment from becoming one giant object. Height and aspect-ratio sanity checks catch obvious non-objects: a 0.05 m tall "vehicle" is likely residual ground, and a 40 m long cluster is likely static structure unless the ODD includes unusual trailers.

The cluster-bbox approximation at this stage is not the final box. It is a cheap axis-aligned or coarse oriented bound used for diagnostics, gating, and handoff. [[5_4_object_shape_fitting_EN|Ch 5 §5.4]] owns the geometric fit: L-shape via Zhang 2017 search, PCA-OBB, min-area rectangle, convex hull, and class-prior dimensions. §5.3 should preserve point indices so §5.4 can re-read the original residual points rather than fit to a lossy summary.

Deduplication is necessary when multiple branches run in parallel. A near-field Euclidean branch and a far-field range-image branch can report the same vehicle; a map-subtraction branch can overlap a raw residual branch. Cluster-level deduplication compares point-index overlap, 3-D bbox IoU, centroid distance, and timestamp before publishing one candidate set.

Where classical clustering still ships is best understood by deployment bucket rather than as a single claim. In **restricted, low-speed ODDs** (campus shuttles, factory yards, airport tugs) classical clustering can remain primary, because the ODD bounds the variety of objects and false-positive cost is lower. In **DL-primary L4 robotaxi and consumer NOA stacks**, learned semantic / instance segmentation owns the primary proposal path; classical clustering survives in narrower roles — embedded fallback, Generic Obstacle Detection over occupancy, a pre-filter that cheaply rejects ground-segmentation leftovers before a learned head, and a regression / diagnostic baseline when learned perception is degraded. In **research and academic** contexts classical clustering remains the canonical baseline against which DL detectors are measured. [[5_9_deployment_runtime_EN|Ch 5 §5.9]] picks up the production-survival argument; this section's claim is bounded to "classical clustering retains specific bounded roles," not "classical clustering is still a viable primary path on the open road."

PointNet++ and voxel/point transformer families mostly displace Euclidean and DBSCAN as primary proposal generators in open-road DL stacks; RangeNet and SqueezeSeg mostly displace the hand-built range-image label test when the stack already projects to a range image. The classical methods remain valuable because they are transparent, cheap, and easy to run under degraded learned perception, but the bounded claim above is the one this chapter carries forward into [[6_0_overview_EN|Ch 6]].

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
