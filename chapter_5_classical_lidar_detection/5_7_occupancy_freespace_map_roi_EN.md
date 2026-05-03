---
chapter: 5
section: 7
title: Occupancy, free-space & map-aided ROI gating
language: EN
workflow_status: reviewing
tags:
  - book/section
  - book/chapter-5
  - lang/EN
---

# 5.7 Occupancy, free-space & map-aided ROI gating

This section unifies two classical machineries that Ch 5 has been pointing at since [[5_1_pointcloud_preprocessing_EN|§5.1]]: probabilistic **occupancy grids** (with their 3-D extension **OctoMap**, free-space ray carving, and the Generic Obstacle Detection fallback) and **map-aided filtering / gating** (Apollo's HDMap polygon ROI lookup table — the canonical "HD-map ROI gating" pattern — together with Autoware's `compare_map_segmentation`, which is a different shape of map-aided gating: point-cloud-map subtraction rather than drivable-polygon ROI).

The two halves share substrate and roles. Both consume the BEV grid from §5.1. Both depend on registration roles from [[5_6_registration_EN|§5.6]] — **Role 2 (map subtraction for change detection)** for `compare_map_segmentation`, **Role 4 (map-aided ROI consistency)** for HDMap ROI gating, with **Role 3 (multi-frame accumulation alignment)** entering only when occupancy is built from accumulated sweeps. Both are the load-bearing classical pieces that survive *inside* DL-primary stacks.

The failure modes are stories about how the two halves couple. A stale HD map suppresses a real actor that the class-agnostic occupancy fallback would have caught. Localization drift offsets the ROI cells relative to the live cloud, and the occupancy update writes evidence into the wrong row of the grid. The catalog at the end of the section is built around exactly these cross-half couplings, which is why occupancy and map-aided gating are taught together rather than in two shorter sections.

> [!abstract] What this section covers
> Recursive Bayesian occupancy in log-odds form on a 2-D BEV grid; OctoMap (Hornung 2013) as the same math lifted to a hierarchical 3-D octree; free-space carving via ray casting; **Generic Obstacle Detection** as the class-agnostic safety fallback that sits underneath the per-class detector; **Apollo HDMap ROI gating** as a precomputed BEV lookup; Autoware's `compare_map_segmentation` as the registration-dependent map-subtraction pattern (Role 2 from §5.6); failure modes that span both halves; one paragraph on why this combination survives inside DL-primary stacks. Out of scope: HD-map *building* ([[2_7_hd_map_management_EN|Ch 2 §2.7]]), learned occupancy networks (Tesla-style; [[6_0_overview_EN|Ch 6]]), and pure semantic free-space segmentation.

## Prerequisites, restated inline

The BEV grid substrate is the one introduced in [[5_1_pointcloud_preprocessing_EN|§5.1]]'s representation map: a top-down raster over the gravity-aligned ground plane, indexed by `(i, j)` cells of width `r` (typical `r = 0.1 m` to `0.4 m`), with channels for max height, density, occupancy, and so on. Frames follow [[1_1_coordinate_frames_EN|Ch 1 §1.1]]: the live cloud arrives in `lidar` and is transformed into `base_link` (sensor extrinsics) and then into `map` for any operation that touches a prior map. The "`map` frame" assumption is exactly what [[2_5_map_relative_localization_EN|Ch 2 §2.5]] provides — a globally consistent frame whose origin is fixed to a surveyed reference and in which HD-map polygons are authored. HD-map *freshness* and *change detection* (was this junction repainted last week?) is the responsibility of [[2_7_hd_map_management_EN|Ch 2 §2.7]]; this section consumes a map that may be stale and treats staleness as a failure mode. Registration roles from [[5_6_registration_EN|§5.6]] enter as follows: **Role 4 (map-aided ROI consistency)** keeps the ROI lookup aligned to the live cloud; **Role 2 (map subtraction for change detection)** is the registration that makes Autoware's `compare_map_segmentation` safe; and **Role 3 (multi-frame accumulation alignment)** is the role the occupancy update borrows when it accumulates static evidence across sweeps. The same `§5.6` roles thus serve different parts of this section.

The section's output contract is: **occupancy grid + ROI mask + free-space layer + GOD candidates**. The primary detector consumes the ROI mask as a gate; the planner consumes the free-space layer and obstacle candidates; Ch 7 fusion may consume the occupancy grid as a geometric prior or veto.

## 2-D occupancy grids in log-odds

An occupancy grid stores, for each BEV cell `c`, the posterior probability `p(c | z_{1:t})` that the cell is occupied given all sensor measurements up to time `t`. The classical recursive Bayes update is more convenient in **log-odds** form because the recursion becomes a sum:

```text
l(c | z_{1:t}) = l(c | z_{1:t-1}) + l(c | z_t) − l_0
```

where `l(p) = log( p / (1 − p) )` is the log-odds transform of a probability `p`, `l_0 = l(p_0)` is the log-odds of the prior occupancy (typically `p_0 = 0.5`, so `l_0 = 0`), and `l(c | z_t)` is the log-odds the **sensor model** assigns to cell `c` from the current measurement alone. Adding two log-odds values is equivalent to multiplying odds, which is what Bayes' rule does under the standard cell-independence assumption.

The sensor model is two numbers in the simplest form: `l_occ` (positive) for cells that received a hit and `l_free` (negative) for cells a ray passed through without hitting. A cell that the current sweep does not see at all gets no update — its log-odds carry forward unchanged, decaying only if an explicit forgetting term is applied. Probabilities are recovered by the inverse transform `p = 1 / (1 + exp(−l))` whenever a downstream consumer (planner, visualizer) needs them; the filter math itself stays in log-odds, though most implementations also expose a probability or threshold view at the output boundary.

Two practical details govern stability. **Clamping** caps `l(c)` to a fixed interval `[l_min, l_max]`; without it, a wall observed for a thousand sweeps accumulates a log-odds value so high that one bad measurement can never erase it, and a pedestrian who steps in front of that wall is denied because the grid "knows" the cell is permanent. OctoMap's defaults of `l_min ≈ −2` and `l_max ≈ 3.5` are a reasonable starting point and trade slow forgetting for stable maps. **Initialization** at `l_0 = 0` (probability `0.5`) means an unobserved cell is neither occupied nor free; treating unobserved as free is a classical bug that produces phantom drivable area beyond the sensor horizon.

> [!tip]
> A cell whose log-odds has saturated at `l_max` for hours is not the same as a cell whose log-odds just crossed the occupancy threshold. Downstream consumers that need this distinction (e.g., Generic Obstacle Detection wanting only *fresh* hits) should read the timestamp of last update alongside the log-odds value, not just the binary thresholded grid.

### Worked Example — three sweeps on a 5×5 grid

Use a toy BEV grid with the ego sensor at the bottom center, cell `(row=4, col=2)`. The row index increases downward in the sketch; physically, smaller row means farther forward. Let

```text
l_0 = 0.0
l_occ = +0.85     p ≈ 0.70
l_free = -0.40    p ≈ 0.40
l_min = -2.0
l_max = +3.5
occupied threshold: l > +0.7
free threshold:     l < -0.7
```

Sweep 1 sees a return at `(1,2)`. Bresenham traversal clears `(3,2)` and `(2,2)`, then marks `(1,2)` occupied. Sweep 2 sees the same obstacle again but from slight ego motion, clearing `(3,1)` and `(2,2)`, then marking `(1,2)`. Sweep 3 sees no hit along the center ray out to `(0,2)`, so it clears `(3,2)`, `(2,2)`, `(1,2)`, and `(0,2)` but marks no occupied endpoint. The log-odds after the three sweeps are:

```text
after sweep 0 (prior)             after sweep 1

 r\c  0    1    2    3    4        r\c  0    1    2    3    4
 0   .    .    .    .    .          0   .    .    .    .    .
 1   .    .    .    .    .          1   .    .   +.85 .    .
 2   .    .    .    .    .          2   .    .   -.40 .    .
 3   .    .    .    .    .          3   .    .   -.40 .    .
 4   .    .    S    .    .          4   .    .    S    .    .

legend: S=sensor cell, .=no update / l=0.0
```

```text
after sweep 2                     after sweep 3

 r\c  0    1    2    3    4        r\c  0    1    2    3    4
 0   .    .    .    .    .          0   .    .   -.40 .    .
 1   .    .  +1.70 .    .          1   .    .  +1.30 .    .
 2   .    .   -.80 .    .          2   .    .  -1.20 .    .
 3   .  -.40 -.40 .    .          3   .  -.40 -.80 .    .
 4   .    .    S    .    .          4   .    .    S    .    .
```

The example shows three invariants. First, repeated endpoint hits accumulate positive evidence: `(1,2)` crosses the occupied threshold after sweep 1 and becomes stronger after sweep 2. Second, repeated pass-through cells accumulate negative evidence: `(2,2)` crosses the free threshold after sweep 2. Third, contradictory evidence is arithmetic, not a special case: sweep 3 does not delete the obstacle at `(1,2)`; it subtracts `0.40`, lowering `+1.70` to `+1.30`. A fourth center-clear sweep would lower it to `+0.90`, a fifth to `+0.50`, below the occupied threshold. That lag is intentional. The grid should not erase a two-sweep obstacle because one ray missed it, but it also must not keep it forever once clearing evidence repeats.

## Free-space carving via ray casting

Free-space comes from ray casting, not from the absence of returns. For every laser ray, the cells along the segment from the sensor origin to the first hit are *cleared* (their log-odds receive `l_free`), and the cell containing the hit is *occupied* (it receives `l_occ`). Cells beyond the hit are not touched — the ray did not see through the surface. Bresenham-style line traversal in 2-D, or the 3-D variant for OctoMap, enumerates the cells a ray crosses in `O(L / r)` time per ray, where `L` is the ray length and `r` is the cell size.

The first-return policy is the default for carving. If the sensor reports multiple returns, the earliest physical surface should bound the free-space segment; later returns may still be useful for object evidence, but using a far return to clear every cell before it can carve through vegetation, glass, spray, or a thin pole. The magnitude of `l_free` should usually be smaller than `l_occ` because a miss is less informative than a hit: one beam passing through a cell only says that no surface blocked that beam inside that cell, while a hit says the beam ended there. A common starting ratio is `|l_free| ≈ 0.4-0.6 · l_occ`, then adjusted against replay logs for flicker and persistence.

Ray casting is what makes the grid learn drivable area in the classical sense. After a few sweeps along a clear road, the cells in front of the vehicle accumulate negative log-odds and cross the *free* threshold; obstacle cells stay positive; never-observed cells stay near zero. A planner can then read "drivable area" as cells with `l(c) < l_free_thresh` *and* a recent update timestamp.

The free-space carving operation is also where the classical occupancy framework gets its safety guarantee: a cell is declared free only because a specific ray passed through it without hitting anything. There is no inference from "I have not seen an obstacle here" — the absence of evidence is not evidence of absence. This is the load-bearing distinction between an honest occupancy grid and a map that quietly assumes the unseen world is empty.

```text
ray-casting-through-glass mechanism

true glass surface            far specular return
      |                              x
      |                             /
      |                            /
 lidar o----free----free----free--/       bad carve if far return is used
            cells weakened behind glass

correct policy: prefer the first physical surface for carving; cap l_free
so one specular ray cannot erase a previously occupied cell.
```

### Usage and failure modes

Use ray casting for cells whose beam geometry is known: a spinning LiDAR with ring and azimuth metadata, a range image from §5.1, or a point cloud whose per-point origin can be reconstructed. Do not apply "free" updates to all cells in front of the vehicle just because no point landed there. Ray casting also needs a maximum range policy. A no-return ray can clear up to the sensor's reliable range only if the sensor driver actually reports that ray as valid no-return evidence; many point-cloud messages contain only returns, not the missing beams.

The main failure modes are over-clearing and under-clearing. Over-clearing appears when specular returns, wrong return selection, or extrinsic error cause free-space carving through an object. Under-clearing appears when `l_free` is too weak, maximum range is too short, or the implementation refuses to update cells unless an endpoint exists. Both are visible in the log-odds time series: over-clearing drives obstacle cells below threshold too quickly; under-clearing leaves stale occupied cells in the planner's path long after the actor moved.

## OctoMap — the same math, lifted to 3-D

Hornung et al. introduced OctoMap in 2013 as a probabilistic 3-D occupancy mapping framework backed by an octree. The pedagogical claim is that OctoMap is **the recursive Bayes occupancy update of the previous subsection, lifted from a flat 2-D BEV grid to a hierarchical 3-D octree**. The log-odds update equation is identical; what changes is the spatial container and how cells subdivide.

An octree partitions space into cubic cells; each cell either stores a leaf log-odds value or has eight children. In OctoMap, leaf cells carry log-odds; inner-node values are derived from children (typically the maximum or a clamped accumulation) so that pruning can collapse a homogeneous subtree into a single coarse cell. Internal nodes are allocated along the rays and endpoints touched during sensor updates; homogeneous subtrees (all eight children at the same occupancy state) can be pruned later, leaving an adaptive tree that uses memory only where occupancy varies. The qualifier "homogeneous" matters — a wall observed by a few rays at sub-leaf incidence will not collapse, and dense urban scenes pay much closer to flat-grid memory than the highway-emptiness case suggests. For an ODD that includes long, mostly empty highway stretches, the multi-resolution benefit is substantial; for a dense city block it is modest. Memory should be measured on representative scenes rather than estimated from theoretical bounds.

OctoMap exposes the same operating knobs as a 2-D grid (`l_occ`, `l_free`, `l_min`, `l_max`, leaf resolution, occupancy threshold) plus the octree-specific ones (maximum depth, pruning policy). Free-space carving uses a 3-D ray-casting traversal that descends the tree and updates leaves along the ray. The reference C++ implementation `octomap::OcTree` is what most ROS2 stacks integrate.

> [!info] OctoMap vs flat voxel grid
> A flat 3-D voxel grid spends memory on empty air and on the interior of solid objects; an octree avoids both, *when pruning succeeds*. The cost is that neighbor lookup and ray traversal are `O(log N)` rather than `O(1)`. For automotive perception at 10 Hz, the multi-resolution memory benefit usually outweighs the per-access overhead on highway and suburban ODDs; dense urban scenes shift the trade and may not benefit. C++ implementations are fast enough on Jetson-class CPUs in the deployments the maintainers report, but per-stack latency must be measured rather than assumed.

## Generic Obstacle Detection — the class-agnostic safety fallback

The per-class detector (whether classical clustering + L-shape fitting from [[5_3_clustering_EN|§5.3]] / [[5_4_object_shape_fitting_EN|§5.4]], or the DL detector of [[6_0_overview_EN|Ch 6]]) is good at recognizing the classes it was built for: vehicles, pedestrians, cyclists. It is, by construction, blind to anything else. A mattress in the lane, a deer, a fallen tree, a piece of construction debris, a tipped traffic cone — none of these belong to the trained vocabulary. **Generic Obstacle Detection** is the classical occupancy-based detector that catches these.

The construction is simple. Take the occupancy grid (or the OctoMap volume), threshold cells at log-odds above `l_occ_thresh`, run connected components on the thresholded grid, filter components by minimum size and minimum height-above-ground, and emit each surviving component as a *generic obstacle* — a class-agnostic 3-D bounding volume with no class label, only an "occupied volume here, planner please avoid" semantic. The detector works because it asks a question the per-class detector does not: "is there any geometry in this cell that the ground plane does not explain?" The answer is independent of object identity.

Its output contract is deliberately narrower than a per-class detector's contract:

```text
(footprint_or_box, z_min, z_max, velocity_optional, class=generic, source=occupancy)
```

The planner should treat `class=generic` as "avoid this volume" rather than as a weak semantic label. If a later fusion layer associates the same volume with a vehicle track, the generic candidate can be suppressed or merged; if no semantic detector explains it, the generic candidate still carries obstacle authority.

Mechanically, Generic Obstacle Detection is the same connected-component shape as §5.3 clustering, but its input is a raster or voxel occupancy layer rather than raw residual points. The usual sequence is:

```text
1. select fresh occupied cells:
     l(c) > l_occ_thresh
     age(c) < max_age
     height_above_ground(c) > h_min

2. run connected components in BEV (4- or 8-neighbor)

3. reject tiny components:
     area_cells < min_component_cells
     or physical area < min_area_m2

4. lift the surviving BEV footprint to a 3-D volume:
     z_min / z_max from points or voxel evidence
     footprint from cell union, convex hull, or OBB

5. publish generic obstacle candidates to the planner / fusion layer
```

The freshness gate is important. A static wall that has been occupied for minutes is not a new generic obstacle; a fresh occupied blob on the shoulder or lane is. Conversely, a component with old occupied cells and new occupied cells should not be split by timestamp alone unless the planner contract wants "new obstacle" rather than "occupied volume." A practical implementation publishes both `occupied_volume` and `last_update_age` so the consumer can decide.

### Worked Example

Take a `0.2 m` BEV grid after ray casting and ground removal. The Generic Obstacle Detection branch uses:

```text
l_occ_thresh = +0.7
max_age = 0.3 s
min_component_cells = 4
min_height_above_ground = 0.20 m
```

After thresholding, the occupied cells are:

```text
component A: (10,20), (10,21), (11,20), (11,21), (12,21)
component B: (4,40), (4,41)
component C: (18,7), (19,7), (20,7), (21,7), but height=0.08 m
```

Connected components accepts A as one five-cell blob. Its footprint area is about `5 * 0.2 * 0.2 = 0.20 m²`; its height evidence is above `0.20 m`; it becomes a generic obstacle candidate, perhaps a small debris pile or a fallen box. B is rejected by `min_component_cells=4`; two occupied cells at this resolution are likely rain, spray, or a sparse reflection unless a special small-object mode is active. C has enough cells but fails the height-above-ground gate, so it is treated as curb paint, ground residual, or a shallow road artifact, not an obstacle. The worked example is intentionally identity-free: the output is not "box" or "deer"; it is "fresh occupied volume that the planner must not assume is drivable."

Generic Obstacle Detection is **a common classical safety pattern** rather than an industry-wide architectural guarantee. The pattern: a class-agnostic occupancy-derived detector runs in parallel with the primary per-class detector, and the planner consumes some defined arbitration of the two — most often the union with priority rules, sometimes a confidence-weighted merge. If the primary detector misses a fallen ladder because no training image contained one, the occupancy grid still reports a tall connected component above the road surface and the planner brakes or routes around it. Apollo's classical perception, Autoware's `obstacle_segmentation`-derived nodes, and several proprietary OEM stacks describe pipelines of this shape; the *exact* arbitration policy, the false-positive controls, and whether the occupancy fallback is wired as a hard interrupt or as a soft prior vary by stack. The pedagogically reliable claim is the weaker one: "the per-class detector is not class-complete, and a class-agnostic geometric path is the most common classical answer to that gap." The strong claim — *every* deployed stack must carry such a fallback or risk a safety-case rejection — is a design recommendation this section makes, not an industry observation it can certify. Section 5.10 picks up the validation requirements; Ch 11 owns the formal safety-case process.

## HD-map ROI gating — the Apollo HDMap pattern

The other half of the section is the dual question: where should the **primary per-class detector** spend its compute? The HD-map answers this. A road network's drivable polygons (lanes, junctions, shoulders, parking) and non-drivable polygons (sidewalks, building footprints, off-road areas) are authored once at map-construction time and stored as polygons in the `map` frame. ROI gating shapes the input to the *primary detection path*; the occupancy / Generic Obstacle Detection fallback runs on an *ungated* (or ROI-dilated) domain so ROI-boundary misses are still caught — the survival argument later in this section makes that division explicit.

Apollo's classical perception pipeline used the HDMap to produce, at startup or at map-tile load time, a **precomputed BEV ROI lookup table**: the drivable polygons are rasterized into a binary BEV grid at the same cell resolution as the occupancy grid, and each cell carries a single bit `is_in_ROI`. Cell-wise gating is then a constant-time lookup — no polygon-in-point geometry test on the hot path, no per-frame rasterization. The lookup table is parameterized by the ego's current map tile and is swapped as the vehicle drives between tiles.

The C++ pseudocode is small enough to write inline:

```cpp
// hd_map_roi_lookup.cpp (sketch)
// Precomputed at tile load:
//   roi_grid_(row_y, col_x) = 1 if the cell center lies inside any drivable
//   polygon, else 0. Row follows map y; column follows map x.
// On the hot path, called per **primary-detection** cluster only —
// the occupancy / Generic Obstacle Detection fallback runs on an ungated domain.
bool IsInROI(const Eigen::Vector3d& p_map) const {
  const int col_x =
      static_cast<int>(std::floor((p_map.x() - origin_x_) / cell_size_));
  const int row_y =
      static_cast<int>(std::floor((p_map.y() - origin_y_) / cell_size_));
  if (row_y < 0 || col_x < 0 || row_y >= rows_ || col_x >= cols_) {
    return false;
  }
  return roi_grid_(row_y, col_x) != 0;
}
```

ROI gating is then policy, and the policy choice has a real safety / performance trade. Four common granularities:

- **Centroid-only**: the single BEV cell containing the cluster centroid is queried. Cheapest. Drops large objects that straddle the ROI edge — a truck whose centroid lands on a sidewalk while its body extends into a lane is gated out.
- **Any-cell**: the cluster is gated in if *any* of its occupied cells falls inside the ROI. Most permissive on the safety side. Admits irrelevant structures whose footprint touches the ROI even slightly (a building corner, an overhead sign).
- **Footprint-overlap fraction**: gated in if the overlap between the cluster's BEV footprint and the ROI exceeds a fraction (e.g. 0.5). Tunable middle ground. Requires a cluster footprint (the §5.4 OBB or convex hull) rather than just a centroid.
- **Dilated-ROI**: the ROI grid is *dilated* (morphological inflation) by `k` cells before lookup, and any of the granularities above runs against the dilated grid. The buffer absorbs sub-cell localization drift and edge actors but admits more sidewalk content.

The right choice is ODD-dependent and policy-dependent. Apollo-style classical ROI gating uses footprint-overlap with a small buffer (e.g., `2 m`); Autoware's `compare_map_segmentation` exposes map-subtraction tolerances such as `distance_threshold`, while Autoware ROI gating uses separate lanelet / drivable-area filters not covered here in depth. Safety-critical deployments often pair "any-cell" with a strict size / class filter to keep performance manageable. The single-cell-per-cluster lookup itself is a constant-time operation; the cost difference between granularities is in how the cluster footprint is queried, not in the LUT.

After the gating policy is chosen, clusters that pass it are passed downstream; the rest are *gated out* of the primary detection path. The performance cost remains close to one BEV index lookup per queried cell.

### Worked Example — truck on an ROI edge

Suppose an HD-map tile contains a drivable lane polygon whose right edge is `y = 0.0 m` in the `map` frame. The raster has `cell_size = 0.5 m`, `origin_x = 0`, `origin_y = -5`, and the convention from the snippet: `row_y = floor((y - origin_y) / cell_size)`, `col_x = floor((x - origin_x) / cell_size)`. The rasterizer marks a cell as ROI if the **cell center** lies inside the drivable polygon. That convention matters at boundaries. A cell spanning `y ∈ [-0.5, 0.0)` has center `y=-0.25` and is inside; a cell spanning `y ∈ [0.0, 0.5)` has center `y=+0.25` and is outside. A point at `y=-0.01` and a point at `y=+0.01` may therefore land in adjacent cells with different ROI bits even though they are only `2 cm` apart.

Now a truck cluster is fitted by §5.4 as an OBB footprint:

```text
center = (x=12.0, y=0.15)
length = 8.0 m
width  = 2.6 m
yaw    = 0°
```

Its left half extends into the lane (`y < 0`) and its right half extends outside the lane (`y > 0`). With **centroid-only** gating, the center cell has `y=0.15`, which maps to the outside row, so the primary detector drops the truck even though a large part of its footprint occupies the lane. With **any-cell** gating, the rasterized footprint includes cells whose centers are `y=-0.25`; those cells are ROI, so the truck passes. With **overlap fraction**, if roughly `40%` of the truck footprint lies in the lane and the threshold is `0.5`, the cluster is rejected; if the threshold is `0.3`, it passes. With **dilated-ROI**, a one-cell dilation expands the drivable mask by `0.5 m`, so the centroid cell at `y=+0.25` becomes inside the buffered ROI and the truck passes under centroid gating.

```text
overhead ROI suppress visual

map y
 ^
 | outside ROI / sidewalk          rejected by primary ROI gate
 |      [actor B]                       x
 |---------------------------------------------- lane edge y=0
 | drivable ROI (cell centers inside)  [truck A straddles edge]
 |                         #######+++++
 |                         #######+++++     # in-lane footprint cells
 |                         #######+++++     + outside-but-buffered cells
 +----------------------------------------------------------> map x

Primary detector: sees A if policy is any-cell / overlap / dilated; may drop B.
GOD fallback: runs ungated or wider, so actor B can still become a generic obstacle.
```

The safety policy this book recommends is explicit: a cluster that straddles an ROI boundary should not be rejected by centroid-only lookup unless the occupancy / Generic Obstacle Detection path is independently guaranteed to catch it and the planner consumes that union. For primary detection, use any-cell or overlap-fraction against a dilated ROI when localization residual is near the cell scale. For the fallback branch, keep the evaluation domain ungated or at least wider than the primary ROI. This is exactly the `5_7.fm.map_suppresses_real_actor` catalog row in operational form.

The gating is a performance and a safety lever at once. On the performance side, it removes thousands of clusters from sidewalks, building shoulders, and irrelevant off-road areas every frame, which is the difference between a tractable tracker and one that drowns in static returns. On the safety side, it is *also* the failure mode: anything outside the rasterized polygon — a child standing one tile inside a parking lot, a debris pile on the shoulder — is, by gating policy, not seen. Section 5.10 carries the validation requirement that ROI gating must be paired with a class-agnostic occupancy fallback whose evaluation domain is wider than the rasterized ROI.

## Autoware `compare_map_segmentation` — map subtraction

Autoware's `compare_map_segmentation` is the second classical map-aided pattern. The node consumes a prior point-cloud map of the static environment (typically built via offline SLAM and persisted as PCD tiles), the live `PointCloud2`, and the map-frame transform supplied by upstream localization (`ndt_localizer`, pose estimator, or current `map → base_link` / `map → lidar` chain). It does **not** perform NDT or GICP registration internally. It places live points in the map frame, compares them against the prior map by distance / voxel / elevation tests, and emits every live point the prior map does not explain within a tolerance.

What survives the subtraction is, by construction, **unexplained by the prior map** — and is *only approximately* "dynamic." The unexplained set includes genuinely dynamic actors (vehicles, pedestrians, cyclists), but also localization residual error, map staleness (construction, vegetation growth, repainted lanes), sensor viewpoint differences from the build sweep, density mismatch, and tolerance-edge effects. The classical detection-by-elimination chain is then `map subtraction → clustering → fitting → tracking`, with a far smaller input cloud at the clustering stage than the unfiltered version would receive — and a downstream tracker / temporal filter that has to separate true dynamic actors from the residual's static-but-unexplained content. The mental model "subtraction yields dynamic" is a useful first cut; the operational truth is "subtraction yields *unexplained*, and the rest of the pipeline does the dynamic-vs-static call."

Two operating cadences matter. The localization / pose-estimation step that supplies the alignment may run at its own cadence — sometimes sub-rate, with the most recent accepted transform held in between — because scan-to-map localization such as GICP or NDT can be expensive at 10 Hz. `compare_map_segmentation` consumes that transform and runs residual extraction against the prior map on its input cloud cadence. The cadence split is one of the runtime patterns §5.9 inherits.

`compare_map_segmentation` is a different shape of map-aided gating from the Apollo HDMap pattern. The Apollo lookup gates **where to look** (drivable polygons); Autoware's subtraction gates **what the static prior fails to explain** (operationally "unexplained," which is only approximately "dynamic"). They are complementary and a stack may use both.

### Mechanics and Worked Example

The hot path is a nearest-prior test after receiving an already-registered pose:

```text
input:
  P_live       live points in lidar/base_link at sweep stamp
  M_static     prior point-cloud map tile in map frame
  T_map_live   transform from upstream localization / pose estimation
  d_thresh     distance tolerance, e.g. 0.25-0.50 m

for each live point p:
  q = T_map_live · p
  m = nearest_neighbor(q, M_static)
  if ||q - m|| > d_thresh:
      keep q as residual/unexplained
  else:
      suppress q as explained by static prior

cluster residual points → fit boxes or generic volumes → track / fuse
```

Most implementations use a voxel hash or KD-tree over the prior tile, often with a z-aware gate / elevation test and sometimes intensity or normal consistency. The tolerance is not just sensor noise. It must cover map point density, localization residual, seasonal vegetation changes, and viewpoint mismatch between the map-building sweep and the live sweep. A small `d_thresh` increases dynamic recall but floods the residual with static ghosts; a large `d_thresh` suppresses ghosts but hides actors close to mapped structures.

Worked example. Upstream localization has already accepted the pose that places the live scan in the prior PCD map frame:

```text
upstream pose accepted:
  T_map_live age                  = 35 ms
  localization health             = pass
  residual / covariance gate       = pass

d_thresh = 0.35 m
min residual cluster size = 8 points
```

In `map`, each point is tested against the prior tile's KD-tree:

| live structure | nearest-prior distance pattern | decision |
|---|---:|---|
| building facade | `0.03-0.18 m` from prior facade points | explained by prior; suppress |
| parked car present in the map | `0.05-0.22 m` from prior car points | explained by prior; suppress |
| pedestrian crossing the lane | `0.55-1.10 m` from nearest prior points | unexplained / residual; keep |
| new construction sign near curb | `0.40-0.75 m` from nearest prior points | unexplained / residual; keep, but not necessarily dynamic |

The residual extractor emits the pedestrian points and the construction-sign points. Clustering then creates two residual components. The tracker may classify the first as dynamic after temporal motion; the second may remain static but still unexplained by the prior map. This is the main conceptual point: `compare_map_segmentation` is a *residual extractor*, not a truth oracle for motion. If the upstream localization transform had failed its health gate or the transform freshness had expired, the correct behavior would be to bypass subtraction or mark the residual stream degraded; otherwise an alignment error would make the entire static facade look dynamic.

The Apollo-vs-Autoware distinction is therefore:

```text
Apollo HDMap ROI gating:        polygon prior gates where primary detection looks.
Autoware compare_map_segmentation: point-cloud prior gates what the static prior
                                   fails to explain.
```

The Apollo lookup gates **where to look** (drivable polygons); Autoware's subtraction gates **what the static prior fails to explain** (operationally 'unexplained,' which is only approximately 'dynamic'). They are complementary and a stack may use both.

## Why this classical substrate survives inside DL-primary stacks

The book's honest assessment is that learned 3-D detectors outperform classical clustering on accuracy *for the classes they know*. They do not, however, displace the substrate this section describes. The occupancy grid (and OctoMap, and Generic Obstacle Detection on top of them) provides the **class-agnostic safety fallback** that no per-class detector can provide on its own. The HD-map ROI gating and `compare_map_segmentation` provide the **prior** that lets a heavy DL stack run on a smaller, relevant subset of the cloud — Apollo's classical ROI filter still sits in front of learned modules, and Autoware's map-subtraction stages still narrow the input to dynamic content. In a deployed stack, the DL primary detector sits **on top** of this substrate, not under it: occupancy and ROI gating are early in the data flow, and a deployment that wants to ship without one or both must justify that choice in the safety case rather than treating the substrate as optional. The unification of the two halves of this section is what makes that argument readable: the gating prior tells you where to spend compute, and the occupancy fallback tells you what to fall back to when the per-class detector is wrong about what it sees. ROI gating is typically applied to the primary per-class detection path; the occupancy / Generic Obstacle Detection fallback should run on an *ungated* (or wider) domain so that ROI-boundary misses (the `5_7.fm.map_suppresses_real_actor` pattern below) are caught downstream.

## Failure modes (catalog entries)

The interesting failures here are the ones that span both halves of the section.

> [!warning] Failure modes for §5.10 catalog
> | id | cause | observable_symptom | downstream_hazard | mitigation | validation_test |
> |---|---|---|---|---|---|
> | `5_7.fm.map_suppresses_real_actor` | A real actor (child, debris pile, cyclist cutting a corner) is geometrically present but lies outside the rasterized drivable polygon, so HD-map ROI gating filters its cluster before the **primary per-class detector** sees it (the occupancy / Generic Obstacle Detection fallback runs ungated and should still see it, *if* it is wired). | Per-class detector emits no detection; occupancy grid shows a clear connected component above ground in the gated-out region. | Planner does not know the actor exists and may not brake or yield; safety-critical miss with no in-pipeline diagnostic unless the fallback is wired correctly. | Run Generic Obstacle Detection on the *ungated* occupancy grid in parallel with ROI-gated per-class detection; require the planner to consume the union; widen the ROI by a buffer (e.g., 2 m) around drivable polygons. | Replay scenarios with actors crossing the ROI boundary (children near parking lots, debris on shoulders); assert that Generic Obstacle Detection emits a detection even when the per-class path is gated. |
> | `5_7.fm.stale_map_after_construction` | HD map is older than the road state — junction repainted, lane added, construction barrier installed; the rasterized ROI no longer matches reality. | ROI polygons gate out a now-drivable cell or include a now-blocked cell; `compare_map_segmentation` flags large swaths of recently-changed static structure as "unexplained". | Phantom dynamic obstacles flood the tracker; or the gated ROI excludes a real lane and the per-class detector ignores actors there. | Carry HD-map version and build-timestamp in **explicit map-metadata fields** (e.g., a custom `hd_map_meta_msgs/MapTileInfo` message or a `MapVersion` field on the ROI message — *not* `header.frame_id`, which is reserved for coordinate-frame identity); refuse activation past a freshness budget; run a change-detection diff between the prior map and a recent average occupancy grid; surface the diff on a diagnostic topic per [[2_7_hd_map_management_EN|Ch 2 §2.7]]. | Inject a synthetically aged HD map (e.g., a tile from before a known repaint) into a replay log; assert the freshness monitor trips and the system either degrades gracefully to map-free Generic Obstacle Detection or refuses activation. |
> | `5_7.fm.localization_drift_offsets_roi` | Map-relative localization (Role 4 from §5.6) drifts by more than one BEV cell relative to the live cloud; the precomputed ROI lookup is now indexing the wrong row of the grid. | Clusters near ROI edges flicker in and out of the gated set frame-to-frame; occupancy log-odds for static walls smear across two cell columns; map-subtraction residual shows a static-structure ghost shifted by the drift offset. | Intermittent obstacles appear and disappear; tracker lifetimes thrash; planner sees a non-stationary world where reality is stationary. | Monitor registration residual on the Role-4 alignment and refuse ROI gating when residual exceeds half a cell; widen the ROI by one cell to absorb sub-cell drift; degrade to occupancy-only fallback above a drift threshold. | In §11.3 scenario testing, inject controlled localization drift (5 cm to 50 cm) and require that the ROI freshness monitor trips at the documented threshold and that no obstacle flickers in/out for more than two consecutive frames. |
> | `5_7.fm.ray_casting_through_glass` | Glass walls, bus shelters, or wet road reflections produce specular returns that the LiDAR registers as hits on the *far* side of the surface; the ray-casting carving step then clears cells along the spurious ray, weakening evidence at the actual glass surface and at cells behind it. | Occupancy grid shows a weakly-cleared corridor through what is visibly a glass-walled bus shelter; cells containing a pedestrian behind the glass have suppressed log-odds, depending on return pattern, occlusion, prior evidence, and clamping. | If carving fully clears the cells, Generic Obstacle Detection may miss the pedestrian and the planner may treat the corridor as drivable; even partial clearing depresses confidence below the obstacle threshold. | Use the §5.1 return-selection policy to prefer first returns for ray casting; flag returns whose intensity-vs-range profile is consistent with specular reflection; cap `l_free` magnitude per ray so a single ray cannot fully clear a previously-occupied cell. | Replay glass-wall and wet-road sequences; assert that occupancy log-odds at the glass surface remain above the free threshold even after extended carving exposure. |

The IDs follow the chapter convention `5_7.fm.<short_slug>` defined in the [[5_10_safety_and_validation_EN|§5.10]] catalog contract.

## Runtime-budget row

Per the [[5_9_deployment_runtime_EN|§5.9]] contract, the section commits one row to the chapter-wide runtime table. Values below assume a Velodyne VLP-32C / HDL-32E-class spinning LiDAR at 10 Hz on a Jetson-class edge module, with the HD-map ROI lookup table memory-resident and a 2-D BEV occupancy grid at `r = 0.2 m` over a `100 m × 100 m` window (250 000 cells).

| stage | compute | frame_rate_assumption | point_count_assumption | latency_p50_ms | latency_p99_ms | memory_mb | cadence | tf_freshness_assumption | assumptions_and_caveats |
|---|---|---|---|---|---|---|---|---|---|
| `5_7_occupancy_freespace_map_roi` | cpu (gpu-optional) | 10 Hz spinning | ~60k pts/frame after §5.1 voxel downsample (VLP-32C single-return) | 8 | 25 | 220 | every-frame for occupancy update + ROI gating; map-subtraction localization sub-rate (every 3rd frame as an illustrative cadence drawn from the §5.9 budget table, not a universal default) | ≤ 50 ms | **Illustrative** combined budget for a single-roof-LiDAR C++ ROS2 node running 2-D BEV occupancy update with ray casting + Apollo-style HDMap ROI lookup + `compare_map_segmentation`-style map subtraction gated on the §5.6 Role-2 localization / pose cadence. **OctoMap as a 3-D layer is *excluded* from these numbers** and adds ~50–200 MB per the §5.9 illustrative budget and several extra ms of latency depending on scene complexity. Within the included scope: ray casting dominates latency; ROI lookup is sub-millisecond because the LUT is precomputed; map subtraction adds a fraction of a millisecond per frame, illustrative on the §5.9 Jetson-class assumption, plus localization cost on sub-rate ticks. GPU acceleration of ray casting (CUDA Bresenham kernels) is available in some stacks and can roughly halve CPU latency when present, but this is implementation-dependent and illustrative; assumed *off* here. Memory: BEV grid (~ a few MB at the configured resolution) + one tile of the HD-map ROI LUT (~ tens of MB) + a short ring buffer of recent occupancy snapshots and the registered prior-map tile (~ 100–200 MB), summing to the ~220 MB illustrative figure. Numbers exclude downstream clustering and tracking and should be measured per deployment.
