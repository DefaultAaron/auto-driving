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

Registration aligns one point cloud to another. To talk about that alignment cleanly we need three things from earlier chapters: the TF2 tree relating the `lidar` frame to `base_link` and `base_link` to `map` ([[1_1_coordinate_frames_EN|Ch 1 §1.1]]); a source of ego-pose at the timestamp of each sweep ([[2_1_ego_state_estimation_EN|Ch 2 §2.1]]); and the canonical representations introduced in [[5_1_pointcloud_preprocessing_EN|§5.1]] — raw point cloud, voxel grid, range image, BEV. ICP operates on raw point clouds; NDT operates on a voxel-grid representation of the target; GICP operates on raw points augmented with per-point covariances.

Throughout this section, "source" is the live cloud being aligned and "target" is the cloud (or map) it is being aligned to. The output is a rigid transform `T ∈ SE(3)` that maps source-frame points into the target frame.

Registration is usually run after §5.1 voxel downsampling and often after §5.2 ground segmentation has split the cloud into ground and residual sets. The algorithm may align all points, ground-only points, edge / plane features, or a filtered static-scene subset; the contract is still the same: estimate one rigid `T`, then use that transform to make two representations comparable. The timestamp contract is inherited from §5.1 and §5.5: the source cloud carries a sweep-end stamp, and the ego-pose prior used as initialization must be evaluated at that same stamp.

## ICP — Iterative Closest Point

### Concept

Besl & McKay proposed ICP in 1992 as a general method for registering 3-D shapes given a reasonable initial guess. ICP is the foundational registration algorithm because it exposes the two operations every later variant has to answer: which source point corresponds to which target geometry, and which rigid transform best explains those correspondences? It alternates between those two subproblems until the transform update becomes small.

The simplest variant is point-to-point ICP:

```text
E_pp(T) = Σ_i || T·p_i − q_i ||²
```

where `p_i` is a source point and `q_i` is its matched target point. Point-to-plane ICP uses target normals:

```text
E_pl(T) = Σ_i ( n_i · ( T·p_i − q_i ) )²
```

where `n_i` is the surface normal at `q_i`. Chen & Medioni's range-image registration work (1991), "Object modelling by registration of multiple range images," introduced point-to-plane-style alignment; the common modern ICP presentation keeps Besl & McKay 1992 for the iterative nearest-neighbor framework and Chen & Medioni 1991 for the plane residual idea. Point-to-plane converges faster than point-to-point on roughly planar urban scenes because a source point is allowed to slide along a road, wall, or facade instead of being pinned to one sampled target point.

> [!info] What "convergence" means here
> Both ICP variants can be viewed as alternating projection on a non-convex energy. Each step decreases the cost, so the iterates converge to a *local* minimum. The basin of convergence is small: the initial transform must already place the source within a few degrees of rotation and a meter or so of translation of the true alignment for ICP to find it. ICP is a refiner, not a solver from scratch.

### Mechanics

The correspondence step transforms each source point by the current estimate `T_k`, then finds the nearest target point. A KD-tree built over the target cloud makes a query `O(log M)` on average, so one sweep of `N` source points is roughly `O(N log M)` after the target index exists. Production implementations usually downsample before this step: voxel leaf sizes around `0.2-0.5 m` for scan-to-scan, larger for coarse scan-to-map, and sometimes separate filters for ground and non-ground points. The nearest-neighbor search is also gated. A maximum correspondence distance rejects pairs whose Euclidean distance is implausible under the prior; reciprocal matching rejects `p_i -> q_j` unless `q_j` also prefers `p_i` under the reverse search; normal-angle checks reject pairs whose normals disagree by more than, say, `30°-45°`. These filters are not decoration. Without them, a parked car visible in the live cloud but absent from the map can drag the transform toward a false explanation.

```text
ICP correspondence + convergence sketch

target points q:        x----x----x----x       wall / curb sample
source at T0 p:       o----o----o----o         initial guess shifted
nearest pairs:        o --> x  o --> x

iteration k:
  1. transform source by T_k
  2. query target KD-tree for q_i
  3. reject pairs outside distance / normal / reciprocal gates
  4. solve ΔT_k from surviving pairs
  5. compose T_{k+1} = ΔT_k T_k

cost / transform update:

  residual
     ^
     |  * k=0
     |    \
     |     * k=1
     |       \
     |        * k=2
     |         * k=3  stop: small ΔT and small cost change
     +----------------------------> iteration
```

For point-to-point ICP, the alignment step has a closed form via Kabsch / Horn SVD. Let the surviving correspondences be `(p_i, q_i)`. Compute centroids `p_bar` and `q_bar`, demean the points, and form the cross-covariance:

```text
H = Σ_i (p_i − p_bar)(q_i − q_bar)^T
H = U S V^T
R = V diag(1, 1, det(V U^T)) U^T
t = q_bar − R p_bar
```

The determinant correction prevents a reflection when the point set is nearly planar or noisy. The resulting `R, t` minimize squared point-to-point residuals for the fixed correspondences. In an iterative ICP implementation this `R, t` is the incremental transform from the current source placement to the target placement; it is composed into the running `T`.

Point-to-plane ICP replaces that closed form with a small linear least-squares problem. At the current estimate, write a small incremental motion as `δ = [α, β, γ, tx, ty, tz]^T`, where `α, β, γ` are small rotations. For a transformed source point `x_i = T_k p_i`, the first-order approximation is:

```text
R(δ)x_i + t(δ) ≈ x_i + ω × x_i + v
r_i(δ) = n_i · (x_i + ω × x_i + v − q_i)
       = a_i δ + b_i
```

with

```text
a_i = [ (x_i × n_i)^T   n_i^T ]
b_i = n_i · (x_i − q_i)
```

Stacking all rows gives `A δ ≈ -b`, solved by QR, Cholesky on `A^T A`, or a damped Gauss-Newton / Levenberg step when conditioning is weak. After solving, convert `δ` back to an `SE(3)` increment, compose it with `T_k`, recompute correspondences, and repeat. The solve is small, but the correspondence set changes every iteration, so the overall behavior is still non-convex.

Convergence criteria should combine geometry and optimizer signals. Common gates are: maximum iterations (`20-50` for refinement), translation update below `1-2 cm`, rotation update below `0.05-0.1°`, relative residual improvement below `1e-4`, and a minimum inlier ratio. Robust kernels sit between correspondence rejection and least squares. A Huber or Cauchy weight downweights large residuals without throwing them away immediately:

```text
minimize Σ_i ρ(r_i),  with  w_i = ρ'(r_i) / r_i
solve weighted least squares on sqrt(w_i) a_i, sqrt(w_i) b_i
```

The operational rule is simple: hard gates remove physically impossible pairs; robust kernels reduce the leverage of suspicious but not impossible pairs. Both are needed in live traffic.

### Worked Example

Take three 2-D source points embedded in 3-D with `z=0`:

```text
p1=(0,0), p2=(1,0), p3=(0,1)
```

The target is the same triangle shifted by `(2,1)`:

```text
q1=(2,1), q2=(3,1), q3=(2,2)
```

Assume the initial guess is identity and the correspondence step already found the correct pairs. Point-to-point ICP computes:

```text
p_bar = (1/3, 1/3)
q_bar = (7/3, 4/3)
```

Demeaned source points are `(-1/3,-1/3)`, `(2/3,-1/3)`, `(-1/3,2/3)`. Demeaned target points are identical because the difference is pure translation. Therefore `H` has the same orientation on both sides, SVD yields `R = I`, and:

```text
t = q_bar − R p_bar = (7/3,4/3) − (1/3,1/3) = (2,1)
```

After one alignment step the source becomes exactly the target. A slightly more interesting one-iteration case rotates the target by `90°` and translates by `(2,1)`:

```text
q1=(2,1), q2=(2,2), q3=(1,1)
q_bar=(5/3,4/3)
```

The SVD of the cross-covariance returns a `90°` rotation,

```text
R = [ 0 -1
      1  0 ]
t = q_bar − R p_bar
  = (5/3,4/3) − (-1/3,1/3)
  = (2,1)
```

The arithmetic is why Kabsch / Horn SVD is attractive: once the pairs are fixed, the best rigid transform is not a tuning problem. ICP's difficulty lies in obtaining and preserving the right pairs as the transform evolves.

### Usage

Use point-to-plane ICP when the initial transform is already good and the scene has strong planar structure: road surface, building faces, barriers, parked vehicles, poles with estimated normals. Use point-to-point when normals are unavailable or too noisy, or when aligning compact object fragments where the nearest sampled points matter more than surface tangency. A practical parameter ladder is:

```text
coarse voxel: 0.5-1.0 m, max correspondence: 1.5-3.0 m, 10-20 iters
fine voxel:   0.2-0.3 m, max correspondence: 0.3-0.8 m, 20-50 iters
```

The coarse stage catches moderate ego-pose error; the fine stage removes residual centimeter-to-decimeter drift. If the result jumps far from the IMU / wheel-odom prior, reject it rather than publishing a prettier residual. The runtime cost is dominated by nearest-neighbor search; on a Jetson-class CPU, voxel-downsampled scan-to-scan point-to-plane ICP can run every frame, while dense scan-to-map ICP usually needs map tiling, cached KD-trees, or a lower cadence.

Classical registration remains the more common production choice in open-source AV stacks (Autoware, Apollo, MOLA) as of 2024–2026; learned registration (3DRegNet, DeepGMR, FCGF + RANSAC, Predator) leads on benchmark accuracy but production deployment data is partial and stack-dependent. For Ch 5, learned detectors in Ch 6 still often consume clouds that have been deskewed, accumulated, or map-aligned by classical registration.

### Failure Modes

ICP fails predictably. `5_6.fm.icp_local_minimum` appears when the initial guess is outside the basin or the target has repeated structure: parking pillars, tunnel walls, and lane-separated guardrails can produce a clean but wrong alignment. Degenerate geometry gives weak observability; a flat highway may constrain roll, pitch, and height but not along-track translation. Partial overlap corrupts the correspondence set; hard distance gates and robust kernels reduce the damage but cannot infer missing map structure. Moving actors are outliers from the static-scene perspective, so live traffic should be filtered, downweighted, or made harmless by robust loss.

The code-review smell is a low residual with a high transform delta from the prior. A registration module should publish residual, inlier count, inlier ratio, iteration count, final transform delta, and a pass / reject status. Downstream §5.7 map subtraction and Role 3 accumulation need that status because a wrong transform is worse than no refinement.

## NDT — Normal Distributions Transform

### Concept

Magnusson's 2009 thesis is the canonical reference for the 3-D NDT used in production AD. NDT changes the target representation. Instead of matching live source points to individual target points, it partitions the target map into voxels and fits a Gaussian to the points inside each occupied voxel. The target becomes a continuous density field over space; the source is moved until its transformed points fall into high-density regions.

This is why NDT tolerates weaker initialization than ICP. A target wall represented by many points gives ICP many discrete nearest-neighbor traps; NDT turns the same wall into a smoother local score. It is still non-convex, and it still needs an ego-pose prior, but the basin is often wider enough that scan-to-map localization and map subtraction prefer NDT for coarse alignment.

### Mechanics

Build a voxel grid over the target cloud. For each occupied cell `c`, compute:

```text
μ_c = (1/N_c) Σ_j q_j
Σ_c = (1/(N_c−1)) Σ_j (q_j−μ_c)(q_j−μ_c)^T + λI
```

The regularizer `λI` prevents singular covariances. Cells with too few points are dropped or inflated to a conservative covariance. The source point `p_i`, transformed by `T`, lands in a target cell `c(i)`. NDT scores it by the Gaussian response:

```text
S_ndt(T) = Σ_i exp( − 1/2 d_i^T Σ_{c(i)}^-1 d_i )
d_i = T·p_i − μ_{c(i)}
```

Implementations maximize `S_ndt` or minimize `E_ndt = -S_ndt`. The bounded exponential matters: a point far from any target Gaussian contributes nearly zero instead of dominating the objective. The optimizer is usually Newton or More-Thuente line-search Newton over the six transform parameters. Let `x` be the current 6-D pose increment. The update is:

```text
g = ∂E/∂x
H = ∂²E/∂x²
Δx = − H^-1 g
x_next = x + step_size · Δx
```

The Hessian combines the Gaussian curvature from each occupied cell with the derivatives of the transformed point coordinates with respect to pose. In code, the important diagnostic is not deriving every term by hand; it is ensuring that `H` stays well-conditioned, the line search decreases the objective, and empty / degenerate cells do not inject nonsense gradients.

```text
NDT voxel Gaussian sketch (BEV slice)

+---------+---------+---------+
|         |  ////   |         |
|         | / μ2 /  |         |   each occupied voxel stores
|         | ////    |         |   mean μ and covariance ellipse
+---------+---------+---------+
|  ----   |         |  ||||   |
| --μ1--  | source  |  |μ3|   |   transformed source points score
|  ----   |   o o   |  ||||   |   against the cell they land in
+---------+---------+---------+
|         |  o      |         |
| empty   |         | empty   |
|         |         |         |
+---------+---------+---------+
```

Voxel resolution is the dominant hyperparameter. Too small: cells contain too few points, `Σ_c` becomes rank-deficient, and the optimizer receives noisy gradients. Too large: distinct structures blur together, for example curb and wall points in one broad Gaussian, and the optimum becomes biased. Outdoor automotive defaults often start around `1.0 m`; sparse sensors may need larger cells, dense 64/128-beam sensors can support smaller cells, and map-subtraction use may choose a resolution that matches the subtraction voxel grid. Runtime diagnostics should track median points per occupied cell, fraction of dropped cells, covariance condition numbers, and the eigenvalue ratio distribution. `5_6.fm.ndt_voxel_size_mismatch` is visible before the vehicle drifts if these metrics are watched.

The NDT score shape explains its initialization tolerance. Near a broad wall, the Gaussian has a long tangential axis and a tight normal axis, so the score strongly pulls the source toward the wall while caring less about sliding along it. In a corner or facade-rich scene, overlapping Gaussians constrain more degrees of freedom. In a featureless tunnel, the same smoothness becomes ambiguity: the score is gentle along the tunnel direction, and the optimizer may converge while still biased.

### Worked Example

Use a tiny 2-D voxel map. Cell `A` is centered at `μ_A=(0,0)` with covariance:

```text
Σ_A = [0.25 0
       0    0.04]
```

Cell `B` is centered at `μ_B=(2,0)` with the same covariance. The narrow `y` variance says both cells represent a horizontal curb or wall segment. A live scan has two source points:

```text
p1=(0.3, 0.2)
p2=(2.3, 0.2)
```

At the initial transform `T0 = identity`, both points land in the right cells but sit `0.2 m` above the means. For either point:

```text
d = (0.3, 0.2)
d^T Σ^-1 d = 0.3²/0.25 + 0.2²/0.04 = 0.36 + 1.00 = 1.36
score contribution = exp(-0.68) ≈ 0.51
```

Total score is about `1.02`. Try a candidate translation `t=(−0.3,−0.2)`. The transformed points become `(0,0)` and `(2,0)`, so each quadratic form is `0` and total score becomes `2.0`, the maximum for these two points. Try a wrong translation `t=(−0.3,+0.2)`: the transformed points become `(0,0.4)` and `(2,0.4)`, each quadratic form is `4.0`, and total score falls to `2·exp(-2)≈0.27`. The optimizer's gradient points downward in `y` much more strongly than in `x` because `Σ_y` is tighter than `Σ_x`.

This toy example is the scan-to-map alignment used by §5.7 map subtraction in miniature. The live scan is not forced to choose a single nearest target point. It is pulled toward the local map distribution, and the covariance shape decides which directions are trusted.

### Usage

Prefer NDT when the target is a large static map, the initial pose may be off by more than point-to-plane ICP likes, or the downstream job is §5.7 map subtraction. Map subtraction needs a transform that keeps static map points and live static points in the same voxel neighborhood; NDT's smooth scan-to-map objective is a better coarse alignment tool than nearest-neighbor ICP in that role. ICP can still be run afterward for fine refinement if the residual budget needs it.

Production knobs are voxel resolution, minimum points per voxel, covariance regularization, maximum iterations, line-search step bounds, and convergence thresholds on translation / rotation / score improvement. Observable symptoms map cleanly: oscillation or singular Hessians suggest bad covariances; slow biased convergence along walls suggests too-large voxels or weak geometry; many empty-cell source points suggest initialization outside the map neighborhood or stale TF. On CPU, NDT avoids a target KD-tree but pays for voxel lookup and Newton derivatives; cadence is often every frame for localization, every Nth frame for map subtraction, with the last good transform held between updates.

### Failure Modes

NDT fails when its target density is wrong for the live scan. A stale map turns construction cones, parked trucks, and changed curbs into low-score regions; the optimizer may still align to the remaining static structure, but subtraction residuals grow. A bad voxel size creates `5_6.fm.ndt_voxel_size_mismatch`: too-small cells are noisy and rank-deficient, too-large cells blur structure and bias the pose. Degenerate corridors give a smooth but underconstrained score, so convergence must be checked against prior delta and Hessian conditioning, not just final score.

The DL displacement story is scoped. Learned registration methods can outperform NDT on curated benchmarks, but open-source AV stacks still commonly ship classical NDT / ICP / GICP because their diagnostics, failure modes, and runtime envelopes are easier to bound. Ch 6 detectors may replace the object detector; they do not remove the need for stable map alignment when the perception stack subtracts maps or accumulates sweeps.

## GICP — Generalized ICP

### Concept

Segal, Haehnel, and Thrun introduced GICP at RSS 2009 as a probabilistic generalization that places point-to-point and point-to-plane ICP under one objective. The key idea is to attach a local covariance to every source and target point. A point on a wall is uncertain along the wall but tight normal to the wall; a corner has tighter constraints in more directions; a sparse single scan line has weak or degenerate local geometry. GICP lets those anisotropic uncertainties weight the residual.

This makes GICP less sensitive to local surface noise and mixed surface types, and it provides a unified framework for point-to-point and point-to-plane via per-point covariances. It should not be described as solving partial overlap ambiguity by itself. It still uses correspondences, still needs overlap, and still benefits from rejection gates and robust kernels.

### Mechanics

For each point, estimate a covariance from its `K` nearest neighbors. Demean the neighborhood and compute:

```text
C_i = (1/K) Σ_j (p_j − p_bar)(p_j − p_bar)^T
```

Then regularize the eigenvalues. A common plane-like model keeps large tangential variances and a small normal variance, which encodes "the point may slide on the local plane, but movement through the plane is expensive." Given a correspondence `(p_i, q_i)`, GICP minimizes:

```text
d_i = T·p_i − q_i
M_i(T) = C^B_i + R C^A_i R^T
E_gicp(T) = Σ_i d_i^T M_i(T)^-1 d_i
```

where `C^A_i` is the source covariance, `C^B_i` is the target covariance, and `R` is the rotation part of `T`. The inverse covariance is the Mahalanobis information matrix. Isotropic covariances make all directions equally trusted, reproducing point-to-point behavior. Highly anisotropic plane covariances make normal error expensive and tangential sliding cheap, reproducing point-to-plane behavior. Mixed neighborhoods interpolate between those cases.

The optimizer is iterative because `M_i(T)` depends on rotation and because correspondences are recomputed. Implementations look like ICP on the outside: build target KD-tree, transform source, find nearest target, reject bad pairs, solve a nonlinear least-squares step, repeat. The extra work is covariance estimation, covariance rotation, and per-pair matrix inversion or decomposition. Regularization is mandatory; otherwise single-line neighborhoods and flat highways produce ill-conditioned information matrices.

### Worked Example

Suppose a source point after the current transform is `x=(0.10, 0.02, 0)` from a target point `q=(0,0,0)` on a vertical wall. The residual is `d=(0.10,0.02,0)`. If the combined covariance says tangential `x` uncertainty is `0.25` and wall-normal `y` uncertainty is `0.01`,

```text
M = diag(0.25, 0.01, 0.25)
d^T M^-1 d = 0.10²/0.25 + 0.02²/0.01 = 0.04 + 0.04 = 0.08
```

Move the same point `0.10 m` through the wall normal: `d=(0.02,0.10,0)`. The cost becomes `0.02²/0.25 + 0.10²/0.01 ≈ 1.00`. The same Euclidean magnitude is treated differently because the local surface covariance says which direction is physically meaningful.

### Usage

Use GICP when surfaces are mixed and normals / covariances are stable enough to justify the extra compute: scan-to-scan refinement in urban scenes, fine scan-to-map alignment after NDT, or deskew refinement where point-to-plane ICP is too brittle across curbs, poles, and road patches. Good starting parameters are `K=10-30` neighbors for covariance estimation, voxel downsample around `0.2-0.5 m`, max correspondence distance similar to ICP, covariance eigenvalue floors, and a hard sanity check against the ego-motion prior.

GICP is more expensive than point-to-plane ICP and harder to diagnose than NDT because bad local covariances can look like bad correspondences. Runtime diagnostics should include covariance condition numbers, rejected-pair ratio, final Mahalanobis residual, and transform delta from prior. Tightly coupled SLAM stacks integrate related residuals differently — FAST-LIO uses an iterated EKF with point-to-plane LiDAR residuals, LIO-SAM uses scan-to-map matching inside a factor-graph backend — see [[2_6_slam_essentials_EN|Ch 2 §2.6]].

### Failure Modes

The catalog row is `5_6.fm.gicp_degenerate_covariance`. GICP fails when the local covariance estimate lies. A single returns-thin scan line, sparse far-range points, or a featureless highway can produce covariances with misleading eigenvectors or tiny eigenvalues. The optimizer then stalls, jitters, or returns a transform outside the prior. Partial overlap remains a correspondence problem; GICP's covariance weighting reduces local surface-noise sensitivity but does not identify which half of the scan should be ignored. Learned registration can improve matching in partial-overlap benchmarks, but production use still depends on stack-specific validation and runtime explainability.

## Four perception roles registration plays in Ch 5

This is the section's pedagogical center: the argument for why registration belongs in a *detection* chapter, not just a localization one.

### Role 1 — Inter-sweep deskew refinement

[[5_1_pointcloud_preprocessing_EN|§5.1]] explained that motion compensation ("deskew") rewrites every point in a sweep to a common timestamp using the ego-pose trajectory across the ~100 ms a 10 Hz spinning sensor takes to acquire one revolution. The classical pipeline gets that trajectory from IMU and wheel odometry. When that source is insufficient — high yaw rates that exceed a short-baseline IMU's effective bandwidth, accumulated bias drift, or a gap between IMU and wheel-odom updates — the deskewed cloud still shows curvature artifacts: a doubled lane edge, a smeared pole, a bent guardrail.

Scan-to-scan ICP or GICP between consecutive sweeps refines the **inter-sweep pose estimate** (or, in continuous-time formulations, the spline parameters of the trajectory) that the deskew transform consumes. The deskew operation itself does not change. **Registration refines poses, not timestamps.**

The downstream payoff is concrete: clustering ([[5_3_clustering_EN|§5.3]]) and shape fitting ([[5_4_object_shape_fitting_EN|§5.4]]) operate on the deskewed cloud. A 1° yaw error during a sweep at 30 m range translates into ~0.5 m of lateral displacement at the far edge of the cluster, which is enough to merge two parked cars or split a truck.

### Role 2 — Map subtraction for change detection

Autoware's `compare_map_segmentation` registers the live cloud to a prior point-cloud map of the static environment, then *subtracts* the matched portion. What remains — points the prior map does not explain — are the dynamic obstacles. This is **classical detection by elimination**: instead of identifying objects, identify everything that is *not* the map.

The registration step here is what makes the subtraction safe. A naive nearest-neighbor subtraction in a fixed frame fails the moment ego-pose drift accumulates more than a voxel; the apparent "residual" is dominated by the static scene shifted by drift. GICP or NDT scan-to-map alignment, run at a sub-frame cadence (every Nth frame, with the most recent transform held in between), keeps the residual confined to genuinely dynamic content. Map subtraction is one of the load-bearing classical pieces that survives inside DL-primary stacks ([[5_9_deployment_runtime_EN|§5.9]]).

Role 2 is also the clearest ICP-vs-NDT decision in the section. If the live scan is already map-aligned and only needs a last few centimeters of refinement, point-to-plane ICP is attractive. If the map subtraction node must absorb moderate localization drift before deciding which points are dynamic, NDT is usually safer because the voxel Gaussian score gives a wider basin and direct diagnostics on map-cell support.

### Role 3 — Multi-frame accumulation alignment

Sparse far-range objects benefit from accumulating several sweeps into a denser cloud before clustering or fitting. The naive accumulation — just transform each sweep by the recorded ego-pose and union the points — produces the **doubled-car artifact**: the moving car at frame `k−2` lands a meter or two away from the moving car at frame `k`, and the cluster you fit a box to is two cars long.

There are two failure sources here, and registration addresses one cleanly. Ego-motion drift (the world doesn't actually move; our pose did) is corrected by registering each sweep to the previous one (or to a short rolling reference) and using the registered transform to accumulate. Object motion (dynamic actors do move during the accumulation window) is *not* a registration problem — it requires track-aware compensation in [[5_5_classical_tracking_EN|§5.5]]. The classical division of labor is: registration handles the static scene; tracking handles the dynamic actors.

The implementation should therefore accumulate only after removing or downweighting likely dynamic points when possible. A static-scene mask from §5.7 occupancy, a low-height ground / facade subset, or a track-aware dynamic-object exclusion makes registration solve the problem it is meant to solve. Registering on moving actors is an attractive but wrong shortcut.

### Role 4 — Map-aided ROI gating consistency

[[5_7_occupancy_freespace_map_roi_EN|§5.7]] uses a BEV ROI lookup table — drivable-road and junction polygons rasterized into a grid — to gate clustering and fitting onto cells the HD-map says are interesting. The gating is correct only if the live cloud and the map are expressed in the same frame.

Frame consistency is owned primarily by TF and by map-relative localization ([[2_5_map_relative_localization_EN|Ch 2 §2.5]]), not by registration. Registration is **one mechanism** for obtaining or correcting that alignment when localization-only is insufficient — for example, in GNSS-denied zones (urban canyons, tunnels), in regions where the prior map is stale enough that GNSS-+-IMU alignment falls outside the gating tolerance, or when the localization pipeline itself has degraded and must be re-anchored. In a healthy stack, TF carries the alignment for free; registration is the recovery mechanism, not the routine path.

The perception symptom is ROI flicker: clusters near road edges appear and disappear because the map raster is shifted relative to the live cloud. A registration diagnostic that says "map alignment rejected; ROI gate widened or bypassed" is preferable to silently applying a crisp but wrong ROI.

### The fifth role: localization itself

Localization, the use Ch 2 §2.3 already introduced, is the fifth role. The reader has met it; this section provides the algorithmic depth that pointer promised.

## Production references

- **PCL.** `pcl::IterativeClosestPoint` (point-to-point), `pcl::IterativeClosestPointWithNormals` (point-to-plane), and `pcl::GeneralizedIterativeClosestPoint` are the standard implementations. They share the same `setInputSource` / `setInputTarget` / `align` API, so swapping algorithms in a perception node is a matter of changing the typedef.
- **Autoware Universe.** `ndt_scan_matcher` and `ndt_localizer` provide NDT-based vehicle pose against a pre-built point-cloud map; `compare_map_segmentation` is the map-subtraction node from Role 2.
- **SLAM modules.** FAST-LIO and LIO-SAM use registration as a sub-module inside a tightly coupled LiDAR-inertial estimator — see [[2_6_slam_essentials_EN|Ch 2 §2.6]] for the SLAM-level treatment. From Ch 5's perspective those stacks are *consumers* of registration, not what this section teaches.
- **Open3D / MOLA / Apollo-style stacks.** Open3D is useful for readable ICP / colored ICP / robust-kernel experiments; MOLA exposes modern registration components in a robotics stack; Apollo and similar production-oriented stacks use registration inside localization and map-relative modules rather than as a standalone Ch 5 detector.

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
