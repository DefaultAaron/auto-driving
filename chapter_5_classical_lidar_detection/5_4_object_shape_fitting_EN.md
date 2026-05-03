---
chapter: 5
section: 4
title: Object-shape fitting — L-shape, OBB, class priors
language: EN
workflow_status: complete
tags:
  - book/section
  - book/chapter-5
  - lang/EN
---

# 5.4 Object-shape fitting — L-shape, OBB, class priors

## Why this section exists

A cluster is not yet an object. [[5_3_clustering_EN|§5.3]] hands you point indices plus a coarse cluster-bbox approximation; the planner, [[5_5_classical_tracking_EN|§5.5]] tracking, and Ch 7 fusion all consume `(x, y, z, l, w, h, yaw, optional class)`. Object-shape fitting is the geometric step that produces that tuple — and it is where most classical-pipeline failures become visible: a cluster with the right points can still be fit to a box that points the wrong way, swells past the actor's true extent, or flips yaw between frames. **Cluster quality and box quality are not the same metric.** A pipeline tuned only on cluster recall will publish boxes that look right on a logged frame and break planning when the yaw inverts a hundred milliseconds later. Treat shape fitting as a first-class layer with its own failure modes, not as a one-line `getOrientedBoundingBox()` call. Classical shape fitting has been largely displaced in production primary-detection paths by learned 3D box regressors (PointPillars, SECOND, CenterPoint — see [[6_3_pointpillars_EN|Ch 6 §6.3]] and Ch 6); classical fits survive as a generic-obstacle fallback, a safety-redundant secondary path, and the box layer behind occupancy-derived clusters. The role-choice context is a §5.9 / §5.10 question; this section teaches the geometry.

This section covers L-shape fitting (Zhang 2017) for vehicles, PCA / OBB as the cheap fallback, min-area rectangle as the convex-hull optimum, convex hull as an *optional footprint payload*, and class-prior dimensions for partial views. The pedagogical center is the failure-mode catalog: classical fits routinely produce *planner-hostile boxes* even when the underlying cluster looks fine.

## Prerequisites, restated inline

Shape fitting consumes a cluster of non-ground points in `base_link` after [[5_2_ground_segmentation_EN|§5.2]] / [[5_3_clustering_EN|§5.3]], gravity-aligned per the §5.1 frame contract ([[1_1_coordinate_frames_EN|Ch 1 §1.1]], [[1_3_lidar_calibration_EN|Ch 1 §1.3]]). Yaw is rotation about z; `l` is along the box's local x-axis (heading), `w` along local y, `h` along z. The geometric primitives this section uses are 2D convex hull (`O(N log N)`), 2×2 eigendecomposition, and rotating-calipers traversal of a convex polygon.

## L-shape fitting (Zhang 2017) — the workhorse for vehicles

### Concept

A LiDAR sweep almost never sees a full vehicle. From any pose other than directly behind or directly in front, the cloud captures *two adjacent faces* of the box — typically the rear and one side, or the front and one side — meeting at a near-90° corner. Projected to BEV, the cluster outlines an "L" rather than a closed rectangle. Naive PCA on this L will mis-estimate yaw because the dominant eigenvector splits the difference between the two arms.

Xiao Zhang, Wenda Xu, Chiyu Dong, and John M. Dolan (IV 2017) proposed a **search-based fit**: rotate a candidate yaw `θ` from 0 to π/2 (90° covers all rectangle orientations by symmetry), project the cluster onto the rotated axes, and score how well the projected points form an L. The yaw with the best score wins; the box dimensions fall out of the projection extents.

```text
typical vehicle observation in BEV

                   candidate yaw θ
                        →
visible side      p7  p8  p9  p10
                 *   *   *   *
                 |
                 |      good θ: two arms lie near two box edges
                 |
visible rear  *--*--*--*--*      bad θ: projections smear across all edges
             p0 p1 p2 p3 p4

The L corner is the shared physical corner. The search asks which θ makes
the points closest to two perpendicular rectangle faces, not which θ merely
encloses all points with the smallest area.
```

### Mechanics

The objective is a function over `θ ∈ [0, π/2)`. For each BEV point `p_i = (x_i, y_i)`, define the candidate unit axes:

```text
e_θ = (cos θ, sin θ)
f_θ = (-sin θ, cos θ)
u_i = p_i · e_θ
v_i = p_i · f_θ
```

The candidate rectangle in rotated coordinates is bounded by:

```text
u_min = min_i u_i,  u_max = max_i u_i
v_min = min_i v_i,  v_max = max_i v_i
l(θ) = u_max - u_min
w(θ) = v_max - v_min
```

The centroid in `base_link` is the inverse rotation of the midpoint:

```text
c_uv = ((u_min + u_max)/2, (v_min + v_max)/2)
c_xy = c_u e_θ + c_v f_θ
```

Zhang's paper gives three scoring criteria. The **area criterion** minimizes:

```text
J_area(θ) = l(θ) · w(θ)
```

This is compact but behaves like min-area rectangle on partial footprints. The **closeness criterion** asks points to sit near the closer of the two hypothesized L-shape edges:

```text
d_i(θ) = min(distance from point i to first L-edge,
             distance from point i to second L-edge)
C(θ) = Σ_i 1 / max(d_i(θ), d_0)   (maximize)
```

Here `d_0` prevents division by zero and caps near-perfect alignments. This is not equivalent to minimizing `Σ_i d_i`: the reciprocal is applied before summation, so the argmax rewards inliers and suppresses outliers, while an L1 sum stays outlier-sensitive. The **variance criterion** assigns each point to one of the same two L-shape edges and measures residual evenness:

```text
E1(θ) = { i : point i closer to first L-edge }
E2(θ) = { i : point i closer to second L-edge }
σ²_1(θ) = variance of d_i for i ∈ E1
σ²_2(θ) = variance of d_i for i ∈ E2
J_var(θ) = σ²_1(θ) + σ²_2(θ)   (minimize)
```

Closeness is the common pedagogical default for vehicles because it rewards the "visible L lies on the box's two faces" intuition. Area is a compactness tie-breaker; variance helps when one edge is noisy and another is clean. Production implementations tweak these for latency: `d_0` varies with sensor resolution, and some pipelines use only closeness because variance is heavier. Autoware's `autoware_shape_estimation` is a public implementation in this family.

The search is cheap enough to keep explicit. A production-readable version runs a coarse pass over `θ = 0°, 5°, 10° ... 85°`, keeps the best few candidates under `C(θ)` (or the configured criterion), and then refines each survivor in a narrow window at `0.5°` or `1°`. With `N` cluster points and `K` tested yaws, the fit is `O(N · K)`: no KD-tree, no iterative optimizer, and no sensitivity to initial yaw. Once `θ*` is chosen, `l` and `w` come from the projection extents; `z` and `h` come from vertical min/max over the original cluster; the optional class remains `unknown` unless an upstream cue or class-prior branch sets it.

This section uses the following local `yaw_confidence` mapping. Compute five normalized signals: `m`, the score margin between the best and second-best yaw after converting cost to a higher-is-better score; `a`, two-arm support, measured as `min(n_u_edge, n_v_edge) / max(n_u_edge, n_v_edge)` after assigning points to the two populated perpendicular edges; `q`, corner-angle quality, `1 - |angle_between_arms - 90°| / 45°` clamped to `[0, 1]`; `ρ`, point-density support, rising from `0` below the range-aware point floor to `1` at the expected point count; and `r`, a fallback PCA separation term `(λ₁ - λ₂) / (λ₁ + λ₂)` clamped to `[0, 1]`. For L-shape fits:

```text
yaw_confidence = clamp(0.35m + 0.25a + 0.20q + 0.15ρ + 0.05r, 0, 1)
```

The exact coefficients are a local implementation contract, not a universal standard. The monotonicity is the important handoff to [[5_5_classical_tracking_EN|§5.5]]: clearer score margin, balanced two-arm support, a near-right-angle corner, and enough points increase confidence. A single visible face drives `a` and `q` toward `0`; a no-corner cluster drives `m` toward `0` because many yaws score similarly; a sparse far cluster drives `ρ` toward `0`. In all three cases the tracker should treat the published yaw as a weak measurement and prefer velocity / history.

> [!tip] RANSAC L-fit, in one paragraph
> A second classical option fits two perpendicular lines via RANSAC. It is cheap when the cluster has clear corner geometry but is **not** a graceful fallback on single-face clusters — the perpendicular partner is unconstrained and the algorithm will hallucinate one. The right move for single-face clusters is the §5.5 velocity / lane prior plus low yaw confidence (see `5_4.fm.l_pointing_wrong_way`); RANSAC L-fit ships alongside Zhang for ablation and for crisp-corner / low-point-count clusters.

### Worked Example

Take a toy 12-point L-cluster in meters. The local `u` axis is heading, so `l` is longitudinal length; `v` is perpendicular to heading, so `w` is width. This rear-corner partial view shows `2.5 m` longitudinally and `1.5 m` laterally; class-prior back-fill will recover a sedan-like full box near `4.5 m × 1.8 m`.

| point | coordinate | point | coordinate |
|---|---:|---|---:|
| `p0` | `(0.0, 0.0)` | `p6` | `(0.0, 0.25)` |
| `p1` | `(0.5, 0.0)` | `p7` | `(0.0, 0.50)` |
| `p2` | `(1.0, 0.0)` | `p8` | `(0.0, 0.75)` |
| `p3` | `(1.5, 0.0)` | `p9` | `(0.0, 1.00)` |
| `p4` | `(2.0, 0.0)` | `p10` | `(0.0, 1.25)` |
| `p5` | `(2.5, 0.0)` | `p11` | `(0.0, 1.50)` |

At `θ = 0°`, `u=x`, `v=y`, so `u_min=0`, `u_max=2.5`, `v_min=0`, `v_max=1.5`. If the L-edges are `v_min` and `u_min`, every point lies on one of them. With `d_0=0.05 m`, each point contributes `20`, so `C(0°)=240`; the visible extents are `l_visible=2.5 m`, `w_visible=1.5 m`. Because the view undersamples both full length and full width, class-prior update can publish `l≈4.5 m`, `w≈1.8 m`.

At `θ = 5°`, use `cos θ≈0.996`, `sin θ≈0.087`. Point `p5=(2.5,0)` projects to `u≈2.490`, `v≈-0.218`; point `p11=(0,1.5)` projects to `u≈0.131`, `v≈1.494`. The extents become roughly `u_min=0`, `u_max=2.490`, `v_min=-0.218`, `v_max=1.494`. For L-edges `v_min` and `u_min`, `p2=(1.0,0)` has `(u,v)≈(0.996,-0.087)`, nearest `v_min`, distance `0.131`, contribution about `7.6`. `p8=(0,0.75)` has `(u,v)≈(0.065,0.747)`, nearest `u_min`, distance `0.065`, contribution about `15.3`. Reciprocal votes give smaller `C(5°)` than `C(0°)`, so the coarse pass prefers `0°`. In real clusters the same arithmetic makes `11.5°` beat `10.0°` or `12.0°`.

### Usage

Use L-shape fitting when the cluster is vehicle-like, has enough points for two arms, and sits in a range band where the corner can be sampled. A practical ladder is: run L-shape first on vehicle-like clusters; accept it when `yaw_confidence` is above the tracker gate; otherwise publish the tuple but mark low confidence and let §5.5 hold yaw from track history. Apply class-prior back-fill only after the fit identifies which visible edges are trustworthy. Learned regressors in Ch 6 absorb the partial-view problem through training data and direct box regression; the classical branch exposes the geometric uncertainty explicitly through `yaw_confidence`, `extent_source`, and `corner_visibility`.

### Failure Modes

The L-shape-specific hazards are `5_4.fm.yaw_flip`, `5_4.fm.partial_view_undersized_box`, `5_4.fm.l_pointing_wrong_way`, and `5_4.fm.spray_inflated_box`. Single-face clusters are the most important operational case: the closeness score can look sharp along one edge while the missing perpendicular edge leaves heading ambiguous. Sparse clusters should lower `yaw_confidence`; dense but contaminated clusters should downweight isolated tail points before fitting; and large disagreement against PCA / OBB or min-area rectangle should be logged as a diagnostic rather than silently averaged.

## PCA / OBB — the cheap fallback

### Concept

Principal Component Analysis on the 2D BEV cluster gives an oriented bounding box almost for free. PCA / OBB treats the point distribution as an ellipse: the larger eigenvector is the long axis, the smaller eigenvector is the short axis, and the box is the projection extent on those axes. It is a cheap fallback, not the vehicle anchor, because an L-shaped vehicle cluster is not a full ellipse.

### Mechanics

Demean the BEV points:

```text
μ = (1/N) Σ_i p_i
q_i = p_i - μ
C = (1/N) Σ_i q_i q_i^T
```

For a 2×2 covariance `C = [[a, b], [b, c]]`, eigendecompose it. The larger-eigenvalue vector `e₁` defines yaw:

```text
yaw = atan2(e₁_y, e₁_x)
e₂ = (-e₁_y, e₁_x)
s_i = q_i · e₁
t_i = q_i · e₂
l = max_i s_i - min_i s_i
w = max_i t_i - min_i t_i
centroid = μ + ((max s + min s)/2)e₁ + ((max t + min t)/2)e₂
```

Implementations then normalize the yaw so `l ≥ w` if the object class expects a longer heading axis; otherwise they keep the raw principal axis and let §5.5 stabilize it. The confidence term `r = (λ₁ - λ₂)/(λ₁ + λ₂)` is useful diagnostics: `r≈1` means a strongly elongated cluster, while `r≈0` means the yaw is poorly constrained.

### Worked Example

Use five BEV points on a broadside vehicle-like patch: `(0,0)`, `(1,0.1)`, `(2,-0.1)`, `(3,0.0)`, `(4,0.1)`. The mean is about `(2.0, 0.02)`. The covariance has large x variance, small y variance, and a small cross term, so the dominant eigenvector is nearly `(1,0)`. Projections on `e₁` run from about `-2` to `2`, so `l≈4 m`; projections on `e₂` run from about `-0.12` to `0.08`, so `w≈0.2 m` before class-prior back-fill. That yaw is stable because the cluster is elongated.

Now replace the points with a near-square rear face: `(0,0)`, `(0.2,0)`, `(0,0.2)`, `(0.2,0.2)`. The covariance has `λ₁≈λ₂`. Any small noise point can rotate the chosen eigenvector, and a 90° yaw flip between frames is not a surprise. The published tuple may still be geometrically enclosing, but `yaw_confidence` should be low and `corner_visibility` should not pretend an L exists.

### Usage

PCA / OBB is appropriate for elongated debris, broadside objects, and fallback boxes when L-shape fitting cannot find a corner. It is also a useful fast diagnostic: if PCA and L-shape produce similar yaw, the cluster is probably well constrained; if they disagree by nearly 90°, the side-channel should make the yaw weakness visible. In a DL-primary stack, learned box heads replace this covariance trick for primary detection, but PCA / OBB remains a cheap fallback for unknown clusters and a sanity check for occupancy-derived obstacles.

### Failure Modes

The catalog connection is `5_4.fm.yaw_flip`. PCA / OBB fails when `λ₁≈λ₂`, when an L-cluster's arm lengths bias the eigenvector away from true heading, or when spray / clutter adds high-leverage points. The mitigation is not to hide the instability: publish low `yaw_confidence`, keep `extent_source = visible_only` unless a prior is justified, and let §5.5 enforce yaw continuity.

## Min-area rectangle — the convex-hull optimum

### Concept

The min-area enclosing rectangle is the smallest-area rectangle that contains the BEV point set. It is the right answer when the desired primitive is "tight enclosing box," and it is the wrong instinct when the vehicle is only partly observed. L-shape fitting tries to place rectangle faces under observed vehicle faces; min-area rectangle only minimizes enclosure.

### Mechanics

The min-area enclosing rectangle of a 2D point set is, by a classical result (Toussaint 1983), one of the rectangles whose sides are *flush with an edge of the convex hull*. This reduces the search to `O(H)` where `H` is the number of hull edges, and the rotating-calipers traversal computes it in linear time after the hull is built.

```text
hull  = convex_hull(BEV_points)        # O(N log N)
for each edge e of hull:                # O(H)
    θ = orientation(e)
    project hull onto (θ, θ + π/2) axes
    track the rectangle with smallest area
```

```text
rotating calipers on a 7-point hull

          p3 *------* p4
            /        \
       p2 *           * p5       candidate caliper orientation θ
          |           |          bottom side flush with edge p0→p1
       p1 *-----------* p6
            \       /
              * p0

iteration:
1. choose hull edge p0→p1 as the support direction
2. find extreme projections left/right/top/bottom
3. compute area = (u_max-u_min)(v_max-v_min)
4. rotate to the next hull edge and update the four extremes
```

In production code, the hull is usually already ordered counterclockwise. For each hull edge `e_k = h_{k+1} - h_k`, compute `θ_k = atan2(e_y, e_x)`. Project all hull vertices onto `e_θ` and `f_θ`, compute extents and area, and keep the minimum. A true rotating-calipers implementation updates four support indices instead of re-projecting every vertex, but the code-review invariant is the same: candidate orientations come from hull edges, not from an arbitrary yaw grid.

### Worked Example

Take hull vertices `(0,0)`, `(3,0)`, `(3.2,1.0)`, `(2.0,1.4)`, `(0.2,1.0)`. For edge `(0,0)→(3,0)`, `θ=0°`: x extent is `3.2`, y extent is `1.4`, area is `4.48 m²`. For edge `(3,0)→(3.2,1.0)`, `θ≈78.7°`. Projecting the same vertices gives a long extent around `1.53 m` in the edge direction and a cross extent around `3.14 m`, area about `4.80 m²`. The first orientation wins so far. The calipers continue around the hull; if no edge gives an area below `4.48`, the rectangle flush with the bottom edge is the min-area rectangle.

The worked arithmetic shows the difference from L-shape. If the points are a partial vehicle corner, the bottom edge can dominate because it encloses tightly, even if that edge is a sampled visible face rather than the vehicle heading.

### Usage

Min-area rectangle is a strong default for approximately convex clusters: pedestrians, barrels, cones, small debris, and static obstacles whose footprint is better treated as an enclosing bound than a vehicle model. It is also useful as a cross-check against L-shape fitting. Large yaw or area disagreement means the cluster geometry is partial, contaminated, or non-vehicle-like; the shape fitter should expose that disagreement rather than let one method silently overwrite the other.

### Failure Modes

Operationally, min-area is outlier-sensitive: a single spray point changes the hull, and the hull changes the candidate orientations. It is enclosing-only: it will not place a side along the dominant L-arm if doing so increases area. Learned detectors handle the same partial-view case by regressing the hidden extent from training data; the classical min-area branch has no hidden-face model unless class-prior box dimensions are layered on top. Catalog connections are `5_4.fm.spray_inflated_box` and `5_4.fm.partial_view_undersized_box`.

## Convex hull — when the planner wants the actual shape

### Concept

Sometimes the right answer is not a rectangle. Pedestrians, cyclists with extended limbs, flatbeds carrying irregular cargo — these are poorly approximated by an OBB. Some planners can consume polygonal footprints directly; some consume the convex hull as a conservative bound that is tighter than a rectangle. The binding box tuple is still primary; the hull travels alongside as an *optional footprint payload*.

### Mechanics

The convex hull of the BEV-projected cluster is the ordered polygon containing all points with minimum convex area. Andrew's monotone chain is the easiest implementation to read: sort points by `(x,y)`, build the lower hull while right turns violate convexity, build the upper hull the same way, and concatenate. The cross product test is the only geometric primitive:

```text
cross(o, a, b) = (a_x-o_x)(b_y-o_y) - (a_y-o_y)(b_x-o_x)
```

For a counterclockwise hull, non-left turns are popped when building a strictly convex hull; collinear-point policy is implementation-specific and should be documented. Complexity is `O(N log N)` from sorting and `O(N)` for the scan. The hull vertices should stay in `base_link` BEV coordinates, with any simplification or inflation handled downstream by the planner branch that consumes polygons.

### Worked Example

Sort seven points: `(0,0)`, `(0.4,0.2)`, `(0.5,1.0)`, `(1.2,0.1)`, `(1.5,1.1)`, `(2.0,0.0)`, `(2.1,0.8)`. The lower-hull pass starts with `(0,0)`, `(0.4,0.2)`, then tests `(0.5,1.0)`: the cross product is positive, so keep it. When `(1.2,0.1)` arrives, the last turn bends inward, so `(0.5,1.0)` is popped from the lower hull. Continuing this rule yields the outer chain; the upper pass recovers the top vertices. The interior point `(0.4,0.2)` disappears if it does not support the boundary.

### Usage

Use the hull when downstream code benefits from footprint detail: occupancy inflation, polygon collision checks, or diagnosis of why a rectangle is too conservative. A pedestrian cluster can fit a `0.6 × 0.6 m` OBB while the hull retains an outstretched arm. Both views stay consistent because they come from the same cluster: the OBB carries the binding tuple, and the hull contributes optional shape detail.

### Failure Modes

Convex hull is conservative but not semantic. It fills concavities, wraps around separated limbs or cargo, and expands around spray unless preprocessing removes weak returns. It should not replace the binding tuple because §5.5, Ch 7, and Ch 8 need stable `(x, y, z, l, w, h, yaw, optional class)` fields. Learned systems may output masks or boxes directly; the classical hull remains useful as a transparent footprint payload and as a way to audit whether a rectangle has hidden too much geometry.

## Class-prior box dimensions — back-filling the hidden faces

### Concept

A LiDAR cluster of a vehicle 40 m away might contain 30 points on one corner with visible extent `~1.6 m × 0.8 m`, when the actor is almost certainly a `~4.5 m × 1.8 m` sedan. If the box is published at the visible extent, the tracker sees it grow as the vehicle approaches and the planner under-reserves clearance. Class-prior box dimensions are the classical fix: use a class-specific dimension table to back-fill axes whose visible extent is too small to be the actor's true extent.

### Mechanics

The mechanics are a guarded substitution, not a new fit. First, fit visible geometry with L-shape, PCA / OBB, or min-area rectangle. Second, choose a candidate prior from `upstream_class`, `tracker_history`, or a gross `dimension_lookup`. Third, compare observed dimensions against the prior. A typical rule shape is:

```text
if observed_l < τ_l · prior_l: use prior_l
if observed_w < τ_w · prior_w: use prior_w
if observed_h < τ_h · prior_h: use prior_h
```

with the thresholds validated per ODD rather than copied between stacks. The yaw stays from the shape fit. The centroid shift is the important part: back-fill should keep the visible face anchored to the cluster. If the rear face is visible and length is extended forward, the centroid moves forward by half the added length. If the left side is visible and width is extended to the right, the centroid moves right by half the added width. If the face identity is unknown, the section should either avoid back-fill or set low confidence and let §5.5 resolve the ambiguity over time.

### Worked Example

Suppose L-shape fitting returns a vehicle-like box with visible dimensions `l=1.6 m`, `w=0.8 m`, `h=1.4 m`, yaw aligned with the track lane. A sedan prior is `4.5 × 1.8 × 1.5 m`, and the implementation uses a `0.6` observed/prior threshold. Since `1.6 < 0.6·4.5 = 2.7`, length is back-filled to `4.5`. Since `0.8 < 0.6·1.8 = 1.08`, width is back-filled to `1.8`. Height is already close enough. The centroid shift is `(4.5-1.6)/2 = 1.45 m` along the hidden length direction plus `(1.8-0.8)/2 = 0.5 m` along the hidden width direction, with signs determined by the visible corner.

### Usage

Two pieces entangle. **Class assignment**: classical pipelines often do not have a class — fallbacks pick one by gross dimensions and otherwise publish `unknown` with the visible-extent box. **Which face is anchored**: the L-shape corner identifies the *corner*, not whether the visible face is the front or the rear; classical fitting alone cannot disambiguate "facing toward us" from "facing away," and §5.5 resolves this by accumulating a heading consistent with the velocity vector. The side-channel must say whether back-fill was used through `extent_source`, and how the prior was selected through `class_prior_source`.

Class-prior back-fill is a hack that pays for the fact that classical fitting can only see what the LiDAR saw. It works because vehicles have relatively tight dimensional priors, and it breaks on classes the table does not anticipate: forklifts, motorized wheelchairs, non-standard trailers, construction vehicles, and unusual cargo. Learned detectors won much of this role because they regress full boxes from partial observations directly; the classical branch remains valuable when the stack wants an auditable fallback and explicit uncertainty.

### Failure Modes

The `5_4.fm.partial_view_undersized_box` and `5_4.fm.wrong_prior_inflated_box` failure modes carry the operational risks. Under-fill makes far vehicles grow over time and under-reserves clearance. Wrong-prior over-fill shifts the centroid and blocks free space that the actor does not occupy. The mitigation is to require sufficient corner evidence before back-fill, prefer `tracker_history` over `dimension_lookup` when available, and expose the source so §5.5 can downweight class consistency when the prior is weak.

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
- `corner_visibility ∈ {two_corners, one_corner, no_corner}` — set by §5.4 from hull edge counts. In vehicle terms: `one_corner` is the **canonical L-shape** — two adjacent faces meeting at one shared near-90° corner; this is the typical case for a vehicle observed from any pose other than directly behind / directly in front. `two_corners` means a **broadside / near-full-side observation** where both the front and rear ends of the actor's long side are visible inside the cluster (i.e., the cluster has *two* physical corners terminating its longest face); this is rarer and requires the actor to be entirely within sensor range with no occlusion. `no_corner` is a **single visible face** (a vehicle directly ahead, ego following) where no perpendicular partner is in the cluster.

The enum values above are the §5.4-§5.5 binding interface, not a complete taxonomy of every possible shape-origin source. A downstream consumer should treat any value outside the documented enum as `unknown` rather than assuming the list exhausts all implementations.

These side-channel fields are **diagnostics, not part of the binding tuple**, and [[5_5_classical_tracking_EN|§5.5]] must function correctly when they are absent (e.g., from a different shape-fitting implementation) by treating them as `unknown / unset`. Convex hull travels alongside as an *optional footprint payload* (see above) for planners that consume polygons. §5.5 owns the consumption story (Kalman / IMM / Hungarian / lifecycle); this section's contract ends at the per-frame box.

## Failure-mode pedagogy

This is where most of the section's value lives. Classical shape fitting can produce boxes that satisfy a per-frame IoU metric and still break the planner. The canonical patterns below — yaw flip, partial-view extent error, single-face mis-heading, spray-inflated box, sub-cluster halves — span the four geometric primitives this section taught and the §5.3 boundary that feeds them.

> [!warning] Failure modes for §5.10 catalog
> | id | cause | observable_symptom | downstream_hazard | mitigation | validation_test |
> |---|---|---|---|---|---|
> | `5_4.fm.yaw_flip` | PCA on a near-square cluster (rear of a sedan seen head-on, a small symmetric obstacle), or L-shape search picking a degenerate corner when only one face is visible. `λ₁ ≈ λ₂` makes the chosen eigenvector unstable across frames; for L-shape, the closeness score is nearly flat across two yaw candidates 90° apart. | Box yaw inverts by 90° (or 180°) between consecutive frames despite the cluster moving smoothly. Tracker reports rotation rates of tens of rad/s; predicted trajectory swings sideways. | Planner receives an actor "rotating in place" and either over-brakes for a phantom yaw rate or refuses to commit to a lane-change because the predicted heading is incoherent. | Prefer L-shape over PCA when corner-strength score exceeds threshold; otherwise fall back to PCA with a yaw-stickiness penalty seeded from the previous frame's box; let §5.5 enforce yaw continuity through the tracker's heading state. | Replay logs of slow-moving and stationary vehicles seen at varying aspect angles; assert per-track yaw-rate p99 stays below a physical bound (e.g. 1.5 rad/s for cars). |
> | `5_4.fm.partial_view_undersized_box` | A sparse far cluster of, say, 25 points covering one rear corner of a vehicle is fit at *visible* extent without class-prior back-fill (point count is too low to trigger the back-fill threshold). | Box dimensions are smaller than the actor and shrink-and-grow as the vehicle approaches and more points become visible. | Tracker's process noise has to absorb spurious extent change as motion; planner under-reserves clearance for "small" far vehicles. | Set the side-channel `extent_source = visible_only` and a low `yaw_confidence` when point count is below a per-range floor; let §5.5 accumulate extent over several frames (e.g. ≥ 5) before promoting class confidence. | Ground-truth-overlay validation on far-range (>30 m) vehicle logs: assert per-track extent variance settles within the prior's range after 5 confirmed frames. |
> | `5_4.fm.wrong_prior_inflated_box` | The L-shape corner is misidentified or class assignment by gross-dimension lookup picks the wrong class (e.g. a long sedan tagged "truck"); back-fill then inflates the box along the wrong axis. | Box swells well beyond the actor's prior — a sedan reported with truck-class `(l, w, h)`, often with the centroid shifted along the wrong axis. | Planner over-reserves clearance for inflated near vehicles; lane-change decisions become conservative incorrectly; fusion in Ch 7 disagrees with camera class and degrades the joint estimate. | Tighten gross-dimension class gating; require corner-strength score above threshold before applying class-prior back-fill; expose `class_prior_source = dimension_lookup` in the side-channel so §5.5 can downweight class-consistency lifecycle gates when the prior was a gross-dimension guess (rather than a tracker-confirmed history). | Replay logs of mixed-class traffic at close range; assert that per-class box dimensions stay within the class prior's range, and that misclassifications above the §5.10 threshold are flagged in diagnostics. |
> | `5_4.fm.l_pointing_wrong_way` | Only the rear face of a vehicle is visible (vehicle directly ahead, ego following). The L-shape search has no second arm to lock onto, and chooses a yaw that minimizes closeness over a single line — often parallel to the visible face, which is *perpendicular* to the actor's true heading. | Vehicle in front of ego is published with yaw rotated 90°: heading reported as crossing left-to-right when the actor is in fact moving forward in the same lane. Across frames the yaw stays wrong but stable, so the symptom is not yaw flip but sustained mis-heading. | Planner classifies a leading vehicle as a crossing actor; ACC misbehaves; lane-change decisions read a co-moving car as a side hazard. | Detect single-face-only clusters by counting hull edges and corner strength; for those, set the side-channel `corner_visibility = no_corner` and `yaw_confidence` low so §5.5 holds yaw from the tracker's velocity-derived heading prior until a corner re-appears. The published tuple's `yaw` itself is still set; the consumer is told via side-channel that it is low-confidence. | Replay car-following logs; assert that yaw error against ground truth is <10° for clusters with at least one corner visible, and that the side-channel `yaw_confidence` falls below threshold when no corner is seen. |
> | `5_4.fm.spray_inflated_box` | Tire spray, exhaust plume, or rain returns survive [[5_1_pointcloud_preprocessing_EN\|§5.1]]'s SOR/ROR and get attached to a vehicle's cluster by [[5_3_clustering_EN\|§5.3]]. The min-area rectangle or L-shape fit then encloses the actor *plus* the spray. | Box behind a truck on wet road extends 1–2 m past the actual rear bumper; the trailing edge oscillates with spray density. | Following distance estimation is confused; planner cannot resolve whether the trailing edge is rigid or stochastic, and the gap to the actor effectively shrinks. | Range-aware spray filters earlier in §5.1; cluster-side gating that strips low-density tail points before fitting; weight closeness scores toward dense corners and away from sparse trailing points; reject trailing extent contributions below a density threshold. | Wet-road and truck-following replay; compare published box length against reference (radar / ground truth) and assert that the rear-edge stability is within tolerance across a sliding window. |
> | `5_4.fm.subcluster_halves_one_box` | [[5_3_clustering_EN\|§5.3]] split one vehicle into two sub-clusters along a low-return seam (a dark side panel, a window, an occluding pole), and §5.4 fits one box per sub-cluster instead of one box per vehicle. | Two adjacent boxes appear where one vehicle exists; their combined footprint matches the true vehicle but each individual box is half-sized and mis-yawed. | Tracker maintains two separate tracks for one actor; planner sees a non-existent gap between the halves, or worse, treats one half as a small overtakeable obstacle. | Post-fit cluster-merge step: adjacent boxes whose combined extent matches a class prior and whose yaws agree within tolerance are candidates to merge before publishing. Diagnostic: the §5.10 catalog should treat this as a §5.3 / §5.4 boundary case, not just a clustering bug. | Replay logs through known dark-vehicle and partial-occlusion scenarios; assert that one-box-per-actor recall on §5.5's tracks stays above threshold. |

The IDs follow the chapter convention `5_4.fm.<short_slug>` consumed by the [[5_10_safety_and_validation_EN|§5.10]] catalog.

## Runtime-budget row

Per the [[5_9_deployment_runtime_EN|§5.9]] contract, §5.4 commits one row. Assumptions and trade-off detail are in the row's `assumptions_and_caveats` cell.

| stage | compute | frame_rate_assumption | point_count_assumption | latency_p50_ms | latency_p99_ms | memory_mb | cadence | tf_freshness_assumption | assumptions_and_caveats |
|---|---|---|---|---|---|---|---|---|---|
| `5_4_object_shape_fitting` | cpu | 10 Hz | ~50 clusters/frame from §5.3, median ~120 points/cluster after preprocessing | ~3 | ~9 | ~24 | every-frame | ≤ 50 ms | **Illustrative** budget for a C++ ROS2 node implementing L-shape (Zhang 1° search, coarse-to-fine), PCA / OBB, min-area rectangle (rotating calipers), convex hull, and class-prior back-fill on a single thread. Latency is dominated by L-shape search on the larger clusters; PCA-only or OBB-only paths run in ~1 ms. Memory is small because work is per-cluster. Per-deployment numbers vary with cluster count, point distribution, and search resolution and should be measured rather than assumed. Numbers exclude §5.5 tracker overhead.
