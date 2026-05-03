---
chapter: 5
section: 2
title: Ground segmentation
language: EN
workflow_status: reviewing
tags:
  - book/section
  - book/chapter-5
  - lang/EN
---

# 5.2 Ground segmentation

The Ch 5 classical pipeline is `preprocess → ground → cluster → fit → track`. Ground segmentation is the first stage that makes an object/background decision: it removes or masks road-surface points so [[5_3_clustering_EN|§5.3]] does not spend most of its budget clustering asphalt. A good segmenter is not the one that deletes the most points. It is the one that leaves a residual non-ground cloud where curbs, legs, cones, pedestrians, vehicle underbodies, and road debris remain visible.

The default sensor assumption in this section is a single mechanical-spinning LiDAR in the HDL-32E / HDL-64E / VLP-32C class. Himmelsbach scan-line methods and Patchwork++ both benefit from rough ring repeatability and a stable radial sampling pattern. Non-repetitive scanners such as Livox Mid-360, Avia, or Horizon, and fused multi-LiDAR clouds, need either per-sensor processing before fusion or an explicit re-projection step with diagnostics for artificial holes and neighbors. The algorithms below can still be used outside the default sensor class, but the representation contract must be made explicit instead of assumed from the driver.

[[5_1_pointcloud_preprocessing_EN|§5.1]] establishes five canonical representations (raw point cloud, voxel grid, OctoMap, range image, BEV); §5.2 uses four of them — raw point cloud, voxel grid, range image, and BEV. OctoMap is §5.7-specific and not part of the ground-segmentation pipeline. This section consumes the §5.1 output: a deskewed cloud in `base_link`, voxel-downsampled by `pcl::VoxelGrid`, and de-noised by SOR/ROR. Intensity is not a stable material classifier, so ground segmentation here is geometric; intensity may be passed through for diagnostics, but it does not define asphalt, concrete, water, or vegetation. The optional branches are representation choices: Himmelsbach-style scan-line segmentation uses a range image or ring ordering, while Patchwork and Patchwork++ use a radial-grid view of the same preprocessed cloud.

The frame contract from [[5_8_ros2_integration_EN|§5.8]] also matters. `PointCloud2.header.stamp` is the end-of-scan time, per-point `time` is a non-negative `Δt` such that absolute time is `header.stamp − time`, and the cloud is usually in `base_link` after deskew. If a ground segmenter silently mixes `lidar` and `base_link`, or consumes stale `/tf`, it will confuse vehicle pitch with a sloped road. That failure then propagates into the residual cloud, not just into a local label map.

## Output contract

§5.2 produces a residual non-ground cloud: ground points are removed, or a mask is published beside the original cloud when consumers need original point indices. The residual inherits the §5.1 preprocessing decisions. It is uniformly filtered, but it is not uniformly dense; LiDAR point density still falls roughly quadratically with range.

[[5_3_clustering_EN|§5.3]] consumes this residual cloud for object proposals and must tune clustering thresholds with range-bias in mind. [[5_7_occupancy_freespace_map_roi_EN|§5.7]] may also consume ground labels or the residual cloud, but its cadence differs: occupancy can tolerate a slower or accumulated ground model for stable free-space, while clustering usually needs every-frame residuals.

Ground segmentation is a lossy early decision. A wrongly-deleted point cannot be recovered by clustering, shape fitting, or tracking; a wrongly-kept point becomes a candidate object that downstream stages must spend budget filtering. Some production DL stacks run classical ground segmentation in front of learned detectors when cutting the input cloud reduces the learned head's compute meaningfully. Other PointPillars / CenterPoint-style deployments run on the full preprocessed cloud and let the voxel encoder absorb the ground problem implicitly. Both patterns ship. The bounded claim for Ch 5 is that classical ground segmentation survives as one of several integration patterns inside DL-primary stacks, not that it is the production default.

## Geometry to keep in mind

The central ambiguity is the difference between a continuous road surface and a height discontinuity that matters to the planner. A curb is low enough to be eaten by loose thresholds, but it is not ground in the object-proposal contract when the stack needs road-edge evidence.

```text
side view, vehicle driving left → right

z
^
|                         truck bed: horizontal, but non-ground
|                         +---------------------------+
|                         |                           |
|             curb face   |                           |
| road crown      _       |                           |
|          ______/ \______|___________________________|____
|         /       ^       ^                           ^
| ramp --/        |       |                           |
|                 |       curb top should remain       |
|                 standing water may produce sparse    |
|                 low or missing returns               |
+------------------------------------------------------------> x

ground-like: smooth road / ramp when locally supported
non-ground-like: curb face, curb top, truck bed, vertical object faces
```

This picture is why a single scalar "remove all points near the road" rule is dangerous. The road, ramp, and water are not all equally observable; the curb and flat-bed truck are geometrically close to ground under different metrics; and every downstream module sees only the residual that survives this section.

## RANSAC plane fitting

RANSAC is the simplest honest starting point and a useful teaching algorithm; the operational default for this chapter is Patchwork++, introduced in the Patchwork section below. The algorithm samples minimal point sets, fits a plane, counts inliers within a distance threshold, and keeps the plane with the largest consensus set. As a toy sanity check, in a flat empty parking lot the dominant plane is the road; removing its inliers leaves cars, poles, cones, and walls. RANSAC works on a raw point cloud, needs no ring layout, and has a small number of parameters.

The plane model is usually written as:

```text
n_x x + n_y y + n_z z + d = 0
```

with a constraint that the normal `n` is near the gravity direction in `base_link`. Without that prior, the side of a truck, a wall, or a building facade can win when the visible road patch is small. With it, RANSAC becomes a fast ground hypothesis rather than a generic plane detector.

Mechanically, the loop is sample, fit, count, keep, and refine. A plane needs three non-collinear points, so the sample size is `s = 3`. Each iteration draws three candidate points, fits `n` and `d`, rejects the model if `n` points too far away from the expected gravity-aligned ground normal, computes each point's perpendicular distance `|n·p + d| / ||n||`, and counts inliers whose distance is below `τ_dist`. The best model is the one with the largest inlier count or, in MSAC-style variants, the smallest clipped residual cost. After the best consensus set is found, a production implementation usually refits the plane with all inliers by least squares instead of keeping the noisy three-point model.

The iteration count comes from the probability of drawing at least one all-inlier sample:

```text
N >= log(1 - p_success) / log(1 - w^s)
```

where `w` is the expected inlier ratio, `s = 3`, and `p_success` is the desired success probability. If the road is expected to be 60 % of the cloud and `p_success = 0.99`, then `N >= log(0.01) / log(1 - 0.6^3) ≈ 19`. If the road is only 30 % because nearby vehicles dominate, the same formula gives about `169` iterations. That jump is the operational lesson: RANSAC cost and stability depend on the scene composition, not just point count.

Worked example. A toy scene contains a road at `z = 0`, a curb top at `z = 0.12 m`, and a truck bed at `z = 0.9 m`. Suppose the node uses `τ_dist = 0.15 m` because the validation set includes rough asphalt and driveway aprons. The road plane fit is correct, but the inlier test now accepts the curb top because `0.12 < 0.15`. The residual cloud loses the curb. If `τ_dist` is tightened to `0.05 m`, the curb survives, but crowned or warped road patches may remain as false residual. The truck bed is not eaten by this particular threshold, but if a nearby flat-bed truck provides more visible horizontal points than the road and the normal prior is loose, the truck bed can become the consensus plane and the road loses.

Usage starts with three gates: keep the candidate normal close to gravity, restrict the sample pool to plausible road-height points when the mount height is known, and cap the plane's elevation relative to `base_link`. Tune `τ_dist` on curb and ramp bags, not only on flat road. A typical implementation also logs inlier ratio, fitted normal, fitted plane height at the ego origin, iteration count, and the percentage of points deleted by range band. If a RANSAC branch is used in production, it is usually a fallback for near-flat sites, a bootstrap model for another method, or a diagnostic baseline that proves the rest of the pipeline can consume a residual cloud.

RANSAC is a useful teaching algorithm and a reasonable fallback for near-flat sites, but it is not the recommended primary segmenter for urban driving. Roads are not one plane: they include crowns, ramps, banked curves, speed humps, curbs, and driveway aprons. A global plane either under-removes ground or over-removes object points that happen to sit near it.

> [!warning] RANSAC failure modes
> RANSAC eats curbs when the distance threshold is larger than curb height, and it can eat flat-bed trucks because the bed is a large horizontal plane. Ramps, banked roads, raised sidewalks, and driveway crossings violate the single-plane assumption. Large vehicles close to the sensor can dominate the consensus and cause the road plane to lose.

## Himmelsbach scan-line segmentation

Himmelsbach proposed a scan-line ground segmentation method in 2010 for mechanical-spinning LiDAR. A spinning sensor already orders points into radial scan lines: as azimuth changes, each ring traces a line over the scene. Along a scan line, ground usually changes smoothly in height and slope, while obstacles create sharper jumps. This makes the method fast and physically intuitive.

The common implementation projects the cloud into a range image or preserves `(ring, azimuth)` ordering before voxel operations destroy adjacency. Each scan line is split into segments or bins, local slope is estimated between neighboring points or fitted line pieces, and points are labeled ground when height and slope remain consistent with the current profile. Because it works radially, it partly adapts to dense near points and sparse far points.

Mechanically, read a scan-line implementation as a cut-and-merge pipeline. First, sort points by ring and azimuth, or consume the driver's native order if it is reliable. Second, break each ring into radial segments using range gaps, height jumps, or a fixed radial bin width. Third, summarize each segment with a line in `(range, z)`, a slope, an intercept, a point count, and height residuals. Fourth, classify a segment as ground when its slope is within the local road-slope limit, its height is continuous with the previous accepted ground segment, and its residuals are small enough. Fifth, merge compatible neighboring segments and optionally smooth labels across adjacent rings.

Worked example. On one ring, assume four consecutive radial pieces:

| segment | range span | fitted `z(r)` behavior | decision |
|---|---:|---|---|
| `s0` | `2-8 m` | gentle rise from `0.00` to `0.05 m` | ground seed |
| `s1` | `8-12 m` | jump to `0.18 m`, then flat | curb top or obstacle |
| `s2` | `12-20 m` | smooth ramp from `0.20` to `0.55 m` | ground only if connected as ramp |
| `s3` | `20-24 m` | vertical-ish jump and sparse points | non-ground |

If the local slope threshold is permissive and only looks at `s1`'s flatness, the curb top can be merged into ground. If the height-continuity threshold is strict, `s2` is rejected even though it is a ramp. The code-review question is therefore not "does it compute slope?" but "which previous segment is the reference, and how are height jumps distinguished from ramps?"

Usage starts with preserving `ring`, `azimuth`, and per-point `time` through §5.1. Reasonable first knobs are small radial bins in the near field, larger bins farther out, a maximum local slope tied to ODD grade, a separate maximum height jump for curb-like discontinuities, and a minimum point count before a segment is trusted. The exact numbers are sensor and ODD dependent; diagnostics should report rejected segments by ring, range, slope, and height jump. Himmelsbach-style methods remain attractive when the stack owns a mechanical-spinning sensor and needs a cheap, inspectable branch.

Himmelsbach-style methods remain valuable for explaining the link between LiDAR topology and classical perception. They also avoid expensive global neighbor search. Their limitation is that they assume a repeatable ring structure and usable adjacency; non-repetitive LiDAR, heavily downsampled clouds, or fused multi-LiDAR clouds can create holes and artificial neighbors.

> [!warning] Himmelsbach failure modes
> Scan-line methods can label curb faces as ground when slope thresholds are permissive, or steep ramps as obstacle when thresholds are strict. Overpasses and underpasses create two valid surfaces along similar azimuths but different heights. Standing water can vanish, shift, or appear as sparse low points, so the scan line sees missing evidence.

## Radial bins and grid heightmaps

Radial-bin methods generalize the scan-line idea into sectors and distance bins. Instead of following one ring, the node groups points by azimuth sector and radial distance, then estimates a local ground height or plane in each bin. This is a bridge from Himmelsbach to Patchwork: the representation is still polar, but the local model can use all points in a small region.

Grid-based heightmaps are the simpler rectangular alternative. Project points into BEV cells, store height and count statistics, then classify cells by height difference relative to neighbors. A 2.5D heightmap is easy to debug, deterministic, and useful as a production fallback when the ODD is controlled -- port, mine, warehouse, and mapped-campus deployments are typical examples.

The mechanics are mostly data-structure mechanics. A radial-bin branch computes `sector = floor(atan2(y, x) / Δφ)` and `bin = floor(range / Δr)` for each point, then stores local statistics: minimum height, low-percentile height, median height, point count, and sometimes a small plane fit. A cell is ground if its low-height statistic is close to the previous radial ground estimate, its slope from the previous bin is plausible, and the height spread does not look like a vertical object. A rectangular heightmap computes `ix, iy` from BEV coordinates and stores similar statistics per cell; it then runs neighbor comparisons or connected components over cells.

Worked example. A `0.25 m` BEV heightmap cell straddles the edge of a curb. The cell contains road points at `z = 0.00`, curb-face points from `z = 0.02` to `0.12`, and curb-top points at `z = 0.12`. If the cell stores only minimum height, it becomes `0.00` and the curb disappears. If it stores maximum height, it may flag the entire cell as obstacle and leave too much road residual. If it stores height spread, `0.12 m` becomes visible, but the next stage must decide whether that spread is a curb, tire, rough asphalt, or a bad return. That is why heightmaps are production-friendly only when the ODD and resolution match the hazard being preserved.

Usage starts with cell size. Smaller cells preserve curbs and trailer legs but increase noise and memory; larger cells stabilize free-space but smear vertical structure. A radial representation should use finer angular and radial bins near the vehicle and coarser bins far away, because the sensor's angular sampling already changes metric spacing with range. A heightmap branch should publish both the ground mask and statistics such as point count, min height, max height, and age when it feeds §5.7. If it feeds §5.3 directly, it should be conservative about deleting low objects: the clusterer can reject nuisance residuals, but it cannot recover deleted curb points.

The heightmap approach also gives [[5_7_occupancy_freespace_map_roi_EN|§5.7]] a convenient interface: ground-like cells support free-space reasoning, and non-ground cells seed obstacle occupancy. The cost is resolution coupling. A cell size that is stable for free-space may erase curb geometry, while a curb-preserving cell can be too noisy or expensive for a wide ROI.

> [!warning] Radial-grid and heightmap failure modes
> Grid methods smear vertical structure inside a cell. A curb, tire, trailer leg, or low obstacle can disappear when the cell stores only minimum height. Rolling terrain makes continuous road look like obstacle steps. Overpasses require multi-layer handling; one 2.5D surface cannot represent road below and bridge deck above.

## GP-INSAC as historical context

GP-INSAC belongs in the lineage because it tries to solve a real weakness of single-plane fitting: the road is a smooth surface, not necessarily a plane. The method combines sampling ideas with a Gaussian-process model so the ground estimate can bend across the scene. In principle, this is what ramps, crowns, and rolling terrain need.

This family lost production favor because Gaussian-process inference and kernel tuning are hard to keep inside a predictable every-frame CPU budget as point count and ROI grow. It also asks more from calibration, ego-pose consistency, and hyperparameter maintenance than local-plane methods. As learned segmentation became common in Ch 6 systems, GP-based classical modeling lost the middle ground. Treat GP-INSAC as historical context: it explains the desire for a continuous ground surface, while Patchwork++ takes the production-friendly route of many local patches.

> [!warning] GP-INSAC failure modes
> A smooth prior can oversmooth curbs, median edges, and loading-dock lips. Kernel length scale becomes ODD-specific: too short follows noise, too long erases terrain changes. Runtime jitter is itself a safety problem because the ground stage sits before clustering.

## Patchwork and Patchwork++

Patchwork (Lim 2021) and Patchwork++ (Lee 2022) are the modern classical baseline this chapter recommends when learned ground segmentation is not the primary path. Patchwork introduced the concentric-zone, region-wise local-plane framing; Patchwork++ subsumes it with additional engineering for reflected noise, adaptive likelihood, temporal recovery, and vertical-plane handling. Patchwork++ is a strong open-source classical baseline: it is the method many active 2024-2026 open-source pipelines reach for when they want a deterministic ground segmenter. That is not a claim that it is benchmark-SOTA on a specific dataset.

Both algorithms are fully classical. They do not use learned class labels, neural features, or a semantic prior; their strength is careful geometric decomposition. TGR introduces frame-to-frame state into the ground stage, but temporal state does not change the classical-vs-learned line.

The core representation is the Concentric Zone Model (CZM). Space around the vehicle is divided into rings, sectors, and local patches. Near the sensor, patches are small because point density is high and curbs or low obstacles matter. Farther away, patches become larger because fewer points are available and the ground estimate needs more support.

```text
top view of CZM around ego vehicle

             far zone: larger patches
        +-------------------------------+
        | \      \      |      /      / |
        |  \      \     |     /      /  |
        |   +------+----+----+------+   |
        |   | \    |    |    |    / |   |
        |   |  +---+----+----+---+  |   |
        |---+--| ego vehicle |--+---+---|
        |   |  +---+----+----+---+  |   |
        |   | /    |    |    |    \ |   |
        |   +------+----+----+------+   |
        |  /      /     |     \      \  |
        | /      /      |      \      \ |
        +-------------------------------+
             near zone: smaller patches
```

Within one patch, Patchwork++ runs a concrete decision flow rather than a single magic threshold. The input is all points assigned to the CZM patch after §5.1 preprocessing and any reflected-noise prefilter. The output is three sets: accepted ground points, residual non-ground points, and patch diagnostics. The local plane is estimated only from selected low seeds, and the final label is decided from geometric features plus temporal recovery.

**CZM: partition and route the points.** For each point, compute radius and azimuth in `base_link`, assign it to a zone, ring, and sector, and append it to that patch's point list. The decision rule is not ground / non-ground yet; it is "which local neighborhood owns this evidence?" CZM adapts patch size to range: small near patches avoid mixing a curb face with a road top, while larger far patches gather enough returns to fit a stable plane. Empty or under-populated patches are marked low-confidence rather than forced into a plane.

**R-GPF: Region-wise Ground Plane Fitting.** For a populated patch, sort points by height or select the lowest quantile as seed candidates. Remove obvious below-ground reflected noise first when the sensor-height model says the return is physically implausible. Estimate an initial plane from the seeds, commonly by PCA / least-squares: the smallest-eigenvalue direction is the normal, and the seed centroid anchors `d`. Then classify every point in the patch by signed distance to that local plane and update the plane with the accepted near-plane points for a small fixed number of refinements. The R-GPF decision is: if the fitted normal is plausibly upright, the elevation is plausible for that zone, the flatness residual is small, and enough points support the plane, the patch becomes a ground candidate; otherwise it becomes a rejected patch whose points remain residual unless later recovered.

**GLE: Ground Likelihood Estimation.** Patchwork++ then scores the candidate patch using features such as uprightness of the normal, elevation relative to the expected ground band, flatness / residual spread, and local consistency with neighboring patches. In Patchwork++ this likelihood is adaptive rather than a single global cutoff: the node estimates scene statistics and adjusts acceptance thresholds by zone, so far sparse ground is not judged by the same evidence budget as near dense ground. The GLE decision is: accept the patch as ground when the likelihood exceeds the zone threshold; reject it when low elevation support, poor uprightness, or high residual spread makes it more likely to contain an obstacle, curb, wall, or mixed surface.

**TGR: Temporal Ground Revert.** Temporal Ground Revert handles the asymmetric cost of over-rejection. If GLE rejects a patch in the current frame but the same spatial patch was stable ground in recent frames, TGR compares the current plane, elevation, and support against the previous ground estimate. If the mismatch is small and the rejection looks like sparse evidence rather than a true discontinuity, TGR reverts the patch to ground. If the patch contains a new obstacle-like height jump, large elevation change, or vertical structure, it stays residual. The TGR decision is therefore "recover likely ground that current-frame evidence undersupported, but do not recover new objects."

**R-VPF and RNR: Region-wise Vertical Plane Fitting and Reflected Noise Removal.** Patchwork++ also includes vertical-plane checks and reflected-noise logic. In practice, this means the patch diagnostics look for vertical or near-vertical structure, curb-like discontinuity, and returns below physically plausible ground caused by wet asphalt or specular reflection. The R-VPF decision is: if the patch's best explanation is a vertical plane or curb/wall face, keep those points non-ground even when part of the patch is flat; if points are below the plausible ground band and match RNR criteria, remove or quarantine them before they distort the ground seeds. This step is why the per-patch output may contain both accepted ground and preserved residual points.

Walk one patch through the flow. A near-field sector contains 80 road points around `z = 0`, 15 curb-face points rising to `z = 0.12`, and 10 curb-top points at `z = 0.12`. CZM places them in a small near patch. R-GPF chooses the lowest road points as seeds and fits a plane close to the road. GLE sees good uprightness and flatness for the road support but also a height spread that suggests mixed structure. R-VPF / vertical-plane diagnostics keep the curb face and top as residual instead of letting the plane absorb them. In the next frame, suppose rain removes half the road returns and GLE rejects the patch because support is thin. TGR checks the previous stable plane; if the curb evidence has not changed and the current plane remains close, it recovers the road points as ground while preserving the curb residual. That is the behavior RANSAC cannot express.

Usage still requires tuning. Zone boundaries should match beam density, mount height, and near-field hazards. Seed selection should be conservative enough that low obstacles do not become seeds, but permissive enough that rough road still initializes a plane. Elevation thresholds should preserve elevated horizontal surfaces such as truck beds. Diagnostics should include rejected patch count, reverted patch count, reflected-noise count, ground ratio by range band, per-zone empty-patch ratio, and processing time. Region-wise PCA / plane fitting scales with point count, so denser sensors, 128-beam sensors, or multi-LiDAR fusion usually need explicit downsampling or per-sensor patching at the §5.1 boundary.

> [!tip]
> Treat Patchwork++ as the baseline to beat, not as a proof that ground segmentation is solved. If a learned Ch 6 model is primary, Patchwork++ still makes sense as a monitor, fallback, or dataset label sanity check because it is fully classical and failure modes are interpretable.

> [!warning] Patchwork / Patchwork++ failure modes
> Patchwork / Patchwork++ can still eat curbs when a region mixes road top and curb face into one plausible plane. A flat-bed truck or bus floor can look like an elevated ground patch if elevation rejection is loose. Rolling terrain stresses seed selection, overpasses create multi-layer surfaces, and standing water reduces local-plane evidence even with RNR active.

## Method comparison

The four practical families differ less by "accuracy" in the abstract than by the assumption they make about the road surface.

| family | assumptions | strengths | failure signatures |
|---|---|---|---|
| global plane (RANSAC) | One dominant plane explains most visible road points; gravity prior is valid. | Simple, sensor-topology agnostic, useful fallback and teaching baseline. | Curbs eaten by distance threshold, ramps left as obstacle bands, truck beds or walls win consensus. |
| scan-line (Himmelsbach) | Mechanical-spinning rings preserve radial adjacency; ground is smooth along each line. | Fast, interpretable, range-aware through sensor topology. | Curb faces merge into ground, steep ramps rejected, overpasses create two surfaces in one azimuth direction. |
| radial bins / heightmap | Local polar or BEV cells summarize ground height well enough for the ODD. | Deterministic, easy to debug, convenient for occupancy and controlled sites. | Vertical structure smeared inside cells, 2.5D overpass ambiguity, resolution trades curb preservation against noise. |
| local patches (Patchwork / Patchwork++) | Many local planes plus likelihood / temporal checks explain the road better than one global model. | Strong open-source classical baseline, handles non-flat roads, preserves diagnostics, CPU-friendly relative to learned segmentation. | Mixed patches still eat curbs, elevated flat objects can look ground-like, temporal revert can recover stale ground when scene change is subtle. |

## Shippable interface

A shippable C++ ground node should keep the full-cloud hot path simple. It subscribes to the §5.1 `PointCloud2`, verifies frame and field layout per [[5_8_ros2_integration_EN|§5.8]], runs the chosen model, and publishes either a residual cloud or an index mask plus diagnostics. Diagnostics should include input point count, ground ratio (overall and **by range band**, since range-dependent failure is a recurring theme), residual point count, processing time, TF age, and method-specific health signals such as rejected patch count or empty-region ratio.

The residual cloud is the main contract. It should preserve `x, y, z, intensity, ring, time` when those fields exist, because [[5_3_clustering_EN|§5.3]] may still use ring or range information to handle density bias. If §5.2 deletes too much, clustering never sees the object; if it deletes too little, clustering merges road texture and obstacle points.

Classical ground segmentation remains useful, but be specific about where it wins and where it loses. Patchwork++ wins on interpretability, CPU predictability, sensor and domain portability under limited labels, and fitness as a monitor or fallback in DL-primary stacks. Learned ground and semantic segmentation tend to win on semantic separation of drivable from non-drivable surfaces, unusual terrain (construction zones, gravel, debris), stacked scenes, and wet or specular surfaces where geometry alone is unreliable. Ch 5 provides the geometric baseline, fallback, monitor, and vocabulary needed to understand what the learned system replaced.

The failures named below all share the same mechanism: residual-cloud distortion. Different scene types stress different geometric assumptions, but every failure changes what downstream sections inherit.

> [!warning] Failure modes for §5.10 catalog
> | id | cause | observable_symptom | downstream_hazard | mitigation | validation_test |
> |---|---|---|---|---|---|
> | `5_2.fm.curb_eaten_as_ground` | Thresholds are loose enough that curb faces and tops join the ground class. | Curbs disappear from the residual cloud; boundary clusters flicker or vanish. | [[5_3_clustering_EN\|Ch 5 §5.3]] misses low road-edge obstacles; [[5_7_occupancy_freespace_map_roi_EN\|Ch 5 §5.7]] may over-clear across a curb. | Use curb-focused validation, range-aware thresholds, smaller near-field Patchwork++ regions, and conservative residual preservation near height discontinuities. | Replay curb approaches, driveway entries, and parking-lot islands; require curb points above the catalog height threshold to remain residual. |
> | `5_2.fm.ramp_misclassified` | Ground model assumes near-horizontal local planes or uses seed selection that does not adapt to steep grades, ramps, and banked roads. | Uphill road patches appear as obstacle bands, or the ramp surface remains in the residual as a wide false cluster. | Clustering creates planner-blocking phantom obstacles; tracking may stabilize them as static objects. | Use gravity-aware but slope-tolerant local planes, tune region-wise thresholds on grade scenarios, and gate global plane fallbacks by road-pitch diagnostics. | Run garage ramps, freeway ramps, crowned roads, and banked turns; measure false residual area per frame and downstream false-track persistence. |
> | `5_2.fm.flatbed_truck_as_ground` | Large horizontal vehicle surfaces satisfy flatness and uprightness tests, especially when elevation rejection is weak or sensor height is misconfigured. | Truck beds, bus floors, or trailer decks are removed from the residual cloud while vertical sides remain. | Shape fitting underestimates object extent; the planner sees an incomplete obstacle or free space under a real vehicle. | Enforce elevation bands relative to expected ground, preserve elevated flat surfaces for clustering, and add object-size consistency checks after segmentation. | Replay flat-bed trucks, low trailers, and buses at multiple ranges; assert elevated horizontal surfaces above the road remain non-ground. |
> | `5_2.fm.overpass_single_layer` | A 2.5D or single-ground-surface model cannot represent road below and bridge or overpass deck above at the same BEV location. | Points on the overpass underside or deck are alternately removed as ground or left as broad residual sheets. | Occupancy and clustering report large false structures, or incorrectly clear space underneath an elevated surface. | Add height-layer checks, ROI context, and conservative handling for stacked surfaces; avoid using a single heightmap as the sole ground authority in multi-level scenes. | Replay underpasses, elevated ramps, and parking structures; inspect residual layers and require no free-space clearing through elevated surfaces. |
> | `5_2.fm.standing_water_sparse_returns` | Wet or standing-water surfaces produce missing, specular, or unstable low returns that break local plane evidence. | Ground ratio drops abruptly in puddle regions; residual contains shimmering low clusters or holes in free-space. | False obstacles trigger braking, or occupancy fails to clear genuinely drivable wet road. | Monitor ground-evidence confidence, use temporal consistency, keep intensity only as an auxiliary diagnostic, and validate wet-road behavior separately from dry asphalt. | Replay wet asphalt, puddles, and tire-spray scenes; measure false residual clusters and free-space clearing stability across repeated passes. |

| stage | compute | frame_rate_assumption | point_count_assumption | latency_p50_ms | latency_p99_ms | memory_mb | cadence | tf_freshness_assumption | assumptions_and_caveats |
|---|---|---|---|---:|---:|---:|---|---|---|
| `5_2_ground_segmentation` | cpu | 10 Hz Velodyne HDL-32E or VLP-32C-class single-roof mechanical-spinning sensor | after §5.1 preprocessing, ~35k-70k points/frame depending on return mode, voxel leaf size, clipping, and SOR/ROR | 8 | 22 | 80 | every-frame for [[5_3_clustering_EN\|§5.3]] residuals; optional lower-rate branch for [[5_7_occupancy_freespace_map_roi_EN\|§5.7]] | ≤ 50 ms | **Illustrative** Patchwork++ C++ CPU budget on a Jetson-class CPU after §5.1 preprocessing; assumes single-roof 32-beam spinning LiDAR, concentric zones, region-wise plane fitting, no learned model, no GPU, and no map lookup. GPU is not required for this stage. Production numbers vary with sensor / CPU class and should be measured for [[5_9_deployment_runtime_EN\|§5.9]]. |
