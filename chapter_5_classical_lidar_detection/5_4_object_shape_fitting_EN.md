---
chapter: 5
section: 4
title: Object-shape fitting — L-shape, OBB, class priors
language: EN
workflow_status: reviewing
tags:
  - book/section
  - book/chapter-5
  - lang/EN
---

# 5.4 Object-shape fitting — L-shape, OBB, class priors

> [!abstract] What this section covers
> The geometric layer that turns a cluster into a planner-consumable 3D box. L-shape fitting (Zhang 2017) for vehicles, PCA / OBB for cheap fallbacks, min-area rectangle as the convex-hull optimum, and convex hull as an *optional footprint payload* travelling alongside the binding box tuple for non-rectangular actors. Class-prior dimensions for partial views. The section's pedagogical center is the failure-mode catalog: classical fits routinely produce *planner-hostile boxes* even when the underlying cluster looks fine.

## Why this section exists

A cluster is not yet an object. [[5_3_clustering_EN|§5.3]] hands you a list of point indices plus a coarse cluster-bbox approximation; the planner does not consume that. The planner — and [[5_5_classical_tracking_EN|§5.5]] tracking, and Ch 7 fusion — consume `(x, y, z, l, w, h, yaw, optional class)`. Object-shape fitting is the geometric step that produces that tuple. It is also where most classical-pipeline failures become visible to the rest of the stack: a cluster that contains the right points can still be fit to a box that points the wrong way, swells past the actor's true extent, or flips yaw between consecutive frames.

That last point is the section's load-bearing argument. **Cluster quality and box quality are not the same metric.** A pipeline tuned only on cluster recall and IoU-of-points will publish boxes that look correct on a logged frame and break planning a hundred milliseconds later when the yaw inverts. Treat shape fitting as a first-class layer with its own failure modes, not as a one-line `getOrientedBoundingBox()` call after clustering.

> [!info] Honest scoping
> Classical shape fitting has been largely displaced in production primary-detection paths by learned 3D box regressors (PointPillars, SECOND, CenterPoint — see [[6_3_pointpillars_EN|Ch 6 §6.3]] and the rest of Ch 6). Where classical fits survive in modern stacks is in three roles: (1) a generic-obstacle fallback for unknown classes the learned detector was not trained on, (2) a safety-redundant secondary path that is geometrically interpretable, and (3) the box layer behind classical map-subtraction or occupancy-derived clusters. This section teaches the geometry; the role choice is a §5.9 / §5.10 question.

## Prerequisites, restated inline

Shape fitting consumes a cluster of non-ground points in `base_link` after [[5_2_ground_segmentation_EN|§5.2]] / [[5_3_clustering_EN|§5.3]], gravity-aligned per the §5.1 frame contract ([[1_1_coordinate_frames_EN|Ch 1 §1.1]], [[1_3_lidar_calibration_EN|Ch 1 §1.3]]). Yaw is rotation about z; `l` is along the box's local x-axis (heading), `w` along local y, `h` along z. The geometric primitives this section uses are 2D convex hull (`O(N log N)`), 2×2 eigendecomposition, and rotating-calipers traversal of a convex polygon.

## L-shape fitting (Zhang 2017) — the workhorse for vehicles

A LiDAR sweep almost never sees a full vehicle. From any pose other than directly behind or directly in front, the cloud captures *two adjacent faces* of the box — typically the rear and one side, or the front and one side — meeting at a near-90° corner. Projected to BEV, the cluster outlines an "L" rather than a closed rectangle. Naive PCA on this L will mis-estimate yaw because the dominant eigenvector splits the difference between the two arms.

Zhang, Wang, Wei & Wang (IV 2017) proposed a **search-based fit**: rotate a candidate yaw `θ` from 0 to π/2 (90° covers all rectangle orientations by symmetry), project the cluster onto the rotated axes, and score how well the projected points form an L. The yaw with the best score wins; the box dimensions fall out of the projection extents.

The objective is a function over `θ ∈ [0, π/2)`. For each `θ`, project every BEV point onto rotated axes and score how the cluster sits relative to the four edges of the implied rectangle. Zhang's paper gives three scoring criteria — *area* (minimize the rectangle area), *closeness* (minimize sum of distances from each point to the nearest of the four edges), and *variance* (minimize per-edge distance variance). The **closeness** criterion is the common pedagogical default for vehicles because it directly rewards the "L lies on the box's two visible faces" intuition; production stacks vary, with Autoware's `autoware_shape_estimation` and many proprietary stacks tuning a closeness-style objective per ODD. Search resolution is typically 1° or 0.5°; coarse-to-fine (5° → 0.5°) is cheap. Once `θ*` is found, `l` and `w` come from the projected extents, the centroid is the rotated midpoint of the projection box, and `z` / `h` come from the cluster's vertical extent. The full sweep is `O(N · K)` and runs sub-millisecond per cluster on a modern CPU at automotive cluster sizes. The optional class is left as `unknown` unless an upstream cue assigns it.

> [!tip] RANSAC L-fit, in one paragraph
> A second classical option fits two perpendicular lines via RANSAC: sample a pair of points, hypothesize a line, count inliers, then fit a perpendicular partner from the remaining points. It is cheap when the cluster has clear corner geometry. It is **not** a graceful fallback on barely-L-shaped clusters: with only one face visible the perpendicular partner is unconstrained, and the algorithm will hallucinate a partner along whatever direction the residual points happen to support, producing a confident-looking but spurious yaw. For single-face-only clusters the right move is not RANSAC L-fit but a velocity / lane prior from the §5.5 tracker (see `5_4.fm.l_pointing_wrong_way` below) or low yaw confidence. Production code that ships Zhang as the default usually keeps a RANSAC L-fit available as a same-interface alternative for ablation and for clusters with crisp corners but few points.

## PCA / OBB — the cheap fallback

Principal Component Analysis on the 2D BEV cluster gives an oriented bounding box almost for free. Demean, form the 2×2 covariance, eigendecompose, align the box axes with the eigenvectors, and read `l` and `w` from the projected extents. PCA is `O(N)` plus a 2×2 eig, fast enough for a hot path, and works adequately for elongated, well-sampled clusters — a lone vehicle seen broadside at close range with a clean ring pattern.

It is also where the **yaw-instability failure mode lives**. PCA picks the eigenvector of *largest variance*, which assumes the longer side of the actor produced more points. For an L-shaped cluster the longer arm is not necessarily aligned with the actor's heading; for symmetric or near-cylindrical clusters (the rear of a sedan seen head-on, a person, a barrel), `λ₁ ≈ λ₂` and the returned yaw is essentially noise. Across two consecutive frames that noise can flip the chosen axis by 90°, the tracker sees a phantom rotation, and prediction goes sideways. PCA / OBB is therefore the cheap fallback for clusters whose shape is too sparse or too irregular for L-shape fitting to lock onto a corner — used consciously, not by default.

## Min-area rectangle — the convex-hull optimum

The min-area enclosing rectangle of a 2D point set is, by a classical result (Toussaint 1983), one of the rectangles whose sides are *flush with an edge of the convex hull*. This reduces the search to `O(H)` where `H` is the number of hull edges, and the rotating-calipers traversal computes it in linear time after the hull is built.

```text
hull  = convex_hull(BEV_points)        # O(N log N)
for each edge e of hull:                # O(H)
    θ = orientation(e)
    project hull onto (θ, θ + π/2) axes
    track the rectangle with smallest area
```

Min-area rectangle is the geometric optimum for "smallest enclosing rectangle." It is **not** the right answer for a partial vehicle cluster, and that distinction is the pedagogical point. L-shape fitting prefers the rectangle whose sides *lie under the visible points*; min-area rectangle prefers the rectangle whose sides *enclose every point with the least area*. The objectives differ in three ways that matter operationally: min-area is **outlier-sensitive** (a single spray point pulls the enclosing rectangle and the yaw with it; L-shape's closeness score weights inliers); min-area depends on the **partial-hull geometry** (when only two arms are visible the hull's longest edge is whatever happened to be sampled, not necessarily the actor's heading); and min-area is **enclosing-only** (it will not place a side along the dominant L-arm if doing so increases area). For a closed cluster (a fully observed object, or a convex actor like a pedestrian) the two objectives agree. The 90°-symmetric ambiguity for near-square clusters that *PCA* notoriously suffers from is a different failure mode and is treated under PCA / OBB above.

The practical role of min-area rectangle in a Ch 5 pipeline is therefore: a strong default for clusters known to be approximately convex (pedestrians, small obstacles, accumulated debris) and a sanity check against L-shape fitting on vehicles (large disagreement is a flag).

## Convex hull — when the planner wants the actual shape

Sometimes the right answer is not a rectangle. Pedestrians, cyclists with extended limbs, a person pushing a stroller, a tow strap connecting two vehicles, a flatbed carrying irregular cargo — all of these are poorly approximated by an OBB. Some planners can consume polygonal footprints directly; some consume the convex hull as a conservative bound that is tighter than a rectangle.

The convex hull of the BEV-projected cluster is `O(N log N)` and produces an ordered list of hull vertices that downstream code can rasterize, simplify, or inflate. The book-canonical box tuple `(x, y, z, l, w, h, yaw, optional class)` is still the primary perception interface — convex hull travels alongside it as an *optional* footprint payload, not as a replacement.

> [!example] When to keep the hull
> A pedestrian cluster fits a 0.6 × 0.6 m OBB cleanly, but the same cluster's convex hull retains the asymmetry of an outstretched arm or a bag at the side. If the §5.5 tracker uses the OBB and the planner uses the hull, both views stay consistent because they come from the same cluster — the OBB carries the heading-bearing tuple `(x, y, z, l, w, h, yaw, ...)`, and the hull is an unrotated polygon footprint travelling alongside it. The planner can consume the hull where it cares about footprint detail; the tracker keeps using the box.

## Class-prior box dimensions — back-filling the hidden faces

A LiDAR cluster of a vehicle 40 m away might contain 30 points covering one corner. The visible extent along the two axes is, say, 1.6 m × 0.8 m. The actor is almost certainly a 4.5 m × 1.8 m sedan. If the box is published at the *visible* extent, the tracker will see it grow as the vehicle approaches, and the planner will under-reserve clearance.

Class-prior dimensions are the classical fix. Given a candidate class (sedan, truck, pedestrian, cyclist), substitute the prior `l × w × h` for any axis where the cluster's observed extent is less than a threshold (say 60% of the prior). The yaw stays from the L-shape fit; the centroid is shifted along the heading axis so that the *visible* face (the rear or front of the vehicle, whichever the L-shape corner identifies) stays anchored to the cluster.

Two pieces entangle here:

1. **Class assignment.** Classical pipelines often do not have a class. The clusterer produces "candidate object," not "candidate sedan." Without a class, the prior table cannot be indexed. Production classical fallbacks usually pick a class by gross dimensions (anything in `[3, 6] m × [1.5, 2.2] m × [1.2, 2.0] m` is "vehicle-like") and otherwise publish `unknown` with the visible-extent box.
2. **Which face is anchored.** L-shape fitting tells you the corner. The corner tells you which two faces are visible — but not whether the *front* or the *rear* is one of them. Without a velocity prior or a tracker, classical fitting cannot disambiguate "vehicle facing toward us" from "vehicle facing away." The tracker fixes this in [[5_5_classical_tracking_EN|§5.5]] by accumulating a heading consistent with the velocity vector.

The honest framing: class-prior back-fill is a hack that pays for the fact that classical fitting can only see what the LiDAR saw. It works because vehicles really do have a tightly clustered dimension prior. It breaks on classes the prior table does not anticipate (a forklift, a motorized wheelchair, a truck with a non-standard trailer), which is one of the reasons learned detectors won this fight in production.

## Output contract — what §5.5 reads from this section

Per-frame, §5.4 publishes a list of fitted boxes. The **binding tuple** is the book-canonical:

```text
(x, y, z, l, w, h, yaw, optional class)
```

with semantics:

- **Frame.** `base_link` at sweep-end time, matching [[5_1_pointcloud_preprocessing_EN|§5.1]]'s output frame and timestamp.
- **(x, y, z).** Box centroid. `z` is the vertical center, not the ground contact.
- **(l, w, h).** Length along the box's local x-axis (heading), width along local y, height along z. Either the visible extent or the class-prior-back-filled extent (see *optional metadata* below for which).
- **yaw.** Rotation about z, in radians, in `[−π, π)`. **BEV plane only**: pitch and roll are not modeled by classical shape fitting in this chapter.
- **optional class.** `unknown` is a valid value. When set, it is consistent with the prior used for back-fill.

The binding tuple does not change between sections — §5.5 / Ch 7 / Ch 8 read exactly those eight fields. Mitigations in the failure-mode catalog below reference internal diagnostics and per-message side-channel metadata that ride **alongside** the tuple as ROS2 message fields or per-track diagnostics, not as additions to the tuple itself:

- `extent_source ∈ {visible_only, class_prior_backfill}` — set by §5.4; consumed by §5.5 to decide whether the tracker should accumulate extent before promoting class confidence.
- `class_prior_source ∈ {none, dimension_lookup, upstream_class, tracker_history}` — when `extent_source = class_prior_backfill`, this names *how* the prior was selected so §5.5 can downweight class confidence when the prior was a gross-dimension guess (`dimension_lookup`) versus a tracker-confirmed history.
- `yaw_confidence ∈ [0, 1]` — set by §5.4 from L-shape corner strength and PCA eigenvalue ratio; consumed by §5.5 to gate yaw-rate updates and switch to a tracker-supplied yaw prior when low.
- `corner_visibility ∈ {two_corners, one_corner, no_corner}` — set by §5.4 from hull edge counts. In vehicle terms: `two_corners` is the canonical L-shape, two adjacent faces meeting at one near-90° corner *and* clearly terminated at both far ends (rare in practice — needs a broadside view of a finite-length actor); `one_corner` is the typical L (two adjacent faces, one shared corner, one or both far ends extending past the visible cluster); `no_corner` is a single visible face (a vehicle directly ahead, ego following) where no perpendicular partner is in the cluster.

These side-channel fields are **diagnostics, not part of the binding tuple**, and §5.5 must function correctly when they are absent (e.g., from a different shape-fitting implementation) by treating them as `unknown / unset`. Convex hull travels alongside as an *optional footprint payload* (see above) for planners that consume polygons.

[[5_5_classical_tracking_EN|§5.5]] consumes these per-frame boxes and runs Kalman / CTRV / IMM filters with Hungarian / GNN / JPDA / MHT association, with AB3DMOT (Weng & Kitani 2020) as the canonical baseline. The detection input to §5.5 is per-frame fitted boxes, not raw clusters; track output flows downstream to Ch 7 fusion and Ch 8 prediction.

## Failure-mode pedagogy

This is where most of the section's value lives. Classical shape fitting can produce boxes that satisfy a per-frame IoU metric and still break the planner. The canonical patterns below — yaw flip, partial-view extent error, single-face mis-heading, spray-inflated box, sub-cluster halves — span the four geometric primitives this section taught and the §5.3 boundary that feeds them.

> [!warning] Failure modes for §5.10 catalog
> | id | cause | observable_symptom | downstream_hazard | mitigation | validation_test |
> |---|---|---|---|---|---|
> | `5_4.fm.yaw_flip` | PCA on a near-square cluster (rear of a sedan seen head-on, a small symmetric obstacle), or L-shape search picking a degenerate corner when only one face is visible. `λ₁ ≈ λ₂` makes the chosen eigenvector unstable across frames; for L-shape, the closeness score is nearly flat across two yaw candidates 90° apart. | Box yaw inverts by 90° (or 180°) between consecutive frames despite the cluster moving smoothly. Tracker reports rotation rates of tens of rad/s; predicted trajectory swings sideways. | Planner receives an actor "rotating in place" and either over-brakes for a phantom yaw rate or refuses to commit to a lane-change because the predicted heading is incoherent. | Prefer L-shape over PCA when corner-strength score exceeds threshold; otherwise fall back to PCA with a yaw-stickiness penalty seeded from the previous frame's box; let §5.5 enforce yaw continuity through the tracker's heading state. | Replay logs of slow-moving and stationary vehicles seen at varying aspect angles; assert per-track yaw-rate p99 stays below a physical bound (e.g. 1.5 rad/s for cars). |
> | `5_4.fm.partial_view_undersized_box` | A sparse far cluster of, say, 25 points covering one rear corner of a vehicle is fit at *visible* extent without class-prior back-fill (point count is too low to trigger the back-fill threshold). | Box dimensions are smaller than the actor and shrink-and-grow as the vehicle approaches and more points become visible. | Tracker's process noise has to absorb spurious extent change as motion; planner under-reserves clearance for "small" far vehicles. | Set the side-channel `extent_source = visible_only` and a low `yaw_confidence` when point count is below a per-range floor; let §5.5 accumulate extent over several frames (e.g. ≥ 5) before promoting class confidence. | Ground-truth-overlay validation on far-range (>30 m) vehicle logs: assert per-track extent variance settles within the prior's range after 5 confirmed frames. |
> | `5_4.fm.wrong_prior_inflated_box` | The L-shape corner is misidentified or class assignment by gross-dimension lookup picks the wrong class (e.g. a long sedan tagged "truck"); back-fill then inflates the box along the wrong axis. | Box swells well beyond the actor's prior — a sedan reported with truck-class `(l, w, h)`, often with the centroid shifted along the wrong axis. | Planner over-reserves clearance for inflated near vehicles; lane-change decisions become conservative incorrectly; fusion in Ch 7 disagrees with camera class and degrades the joint estimate. | Tighten gross-dimension class gating; require corner-strength score above threshold before applying class-prior back-fill; expose `extent_source` in the side-channel so §5.5 can downweight class confidence when the prior was a guess. | Replay logs of mixed-class traffic at close range; assert that per-class box dimensions stay within the class prior's range, and that misclassifications above the §5.10 threshold are flagged in diagnostics. |
> | `5_4.fm.l_pointing_wrong_way` | Only the rear face of a vehicle is visible (vehicle directly ahead, ego following). The L-shape search has no second arm to lock onto, and chooses a yaw that minimizes closeness over a single line — often parallel to the visible face, which is *perpendicular* to the actor's true heading. | Vehicle in front of ego is published with yaw rotated 90°: heading reported as crossing left-to-right when the actor is in fact moving forward in the same lane. Across frames the yaw stays wrong but stable, so the symptom is not yaw flip but sustained mis-heading. | Planner classifies a leading vehicle as a crossing actor; ACC misbehaves; lane-change decisions read a co-moving car as a side hazard. | Detect single-face-only clusters by counting hull edges and corner strength; for those, set the side-channel `corner_visibility = no_corner` and `yaw_confidence` low so §5.5 holds yaw from the tracker's velocity-derived heading prior until a corner re-appears. The published tuple's `yaw` itself is still set; the consumer is told via side-channel that it is low-confidence. | Replay car-following logs; assert that yaw error against ground truth is <10° for clusters with at least one corner visible, and that the side-channel `yaw_confidence` falls below threshold when no corner is seen. |
> | `5_4.fm.spray_inflated_box` | Tire spray, exhaust plume, or rain returns survive [[5_1_pointcloud_preprocessing_EN\|§5.1]]'s SOR/ROR and get attached to a vehicle's cluster by [[5_3_clustering_EN\|§5.3]]. The min-area rectangle or L-shape fit then encloses the actor *plus* the spray. | Box behind a truck on wet road extends 1–2 m past the actual rear bumper; the trailing edge oscillates with spray density. | Following distance estimation is confused; planner cannot resolve whether the trailing edge is rigid or stochastic, and the gap to the actor effectively shrinks. | Range-aware spray filters earlier in §5.1; cluster-side gating that strips low-density tail points before fitting; weight closeness scores toward dense corners and away from sparse trailing points; reject trailing extent contributions below a density threshold. | Wet-road and truck-following replay; compare published box length against reference (radar / ground truth) and assert that the rear-edge stability is within tolerance across a sliding window. |
> | `5_4.fm.subcluster_halves_one_box` | [[5_3_clustering_EN\|§5.3]] split one vehicle into two sub-clusters along a low-return seam (a dark side panel, a window, an occluding pole), and §5.4 fits one box per sub-cluster instead of one box per vehicle. | Two adjacent boxes appear where one vehicle exists; their combined footprint matches the true vehicle but each individual box is half-sized and mis-yawed. | Tracker maintains two separate tracks for one actor; planner sees a non-existent gap between the halves, or worse, treats one half as a small overtakeable obstacle. | Post-fit cluster-merge step: adjacent boxes whose combined extent matches a class prior and whose yaws agree within tolerance are candidates to merge before publishing. Diagnostic: the §5.10 catalog should treat this as a §5.3 / §5.4 boundary case, not just a clustering bug. | Replay logs through known dark-vehicle and partial-occlusion scenarios; assert that one-box-per-actor recall on §5.5's tracks stays above threshold. |

The IDs follow the chapter convention `5_4.fm.<short_slug>` consumed by the [[5_10_safety_and_validation_EN|§5.10]] catalog.

## Runtime-budget row

Per the [[5_9_deployment_runtime_EN|§5.9]] contract, §5.4 commits one row to the chapter-wide runtime table. The numbers below assume a §5.3 cluster set of roughly 50 candidate clusters per frame at 10 Hz, on the host CPU of a Jetson-class edge module. L-shape search is done at 1° resolution coarse-to-fine; PCA / min-area / convex hull are available on the same code path and selected per cluster.

| stage | compute | frame_rate_assumption | point_count_assumption | latency_p50_ms | latency_p99_ms | memory_mb | cadence | tf_freshness_assumption | assumptions_and_caveats |
|---|---|---|---|---|---|---|---|---|---|
| `5_4_object_shape_fitting` | cpu | 10 Hz | ~50 clusters/frame from §5.3, median ~120 points/cluster after preprocessing | ~3 | ~9 | ~24 | every-frame | ≤ 50 ms | **Illustrative** budget for a C++ ROS2 node implementing L-shape (Zhang 1° search, coarse-to-fine), PCA / OBB, min-area rectangle (rotating calipers), convex hull, and class-prior back-fill on a single thread. Latency is dominated by L-shape search on the larger clusters; PCA-only or OBB-only paths run in ~1 ms. Memory is small because work is per-cluster. Per-deployment numbers vary with cluster count, point distribution, and search resolution and should be measured rather than assumed. Numbers exclude §5.5 tracker overhead.
