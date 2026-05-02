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

The Ch 5 classical pipeline is `preprocess → ground → cluster → fit → track`. Ground segmentation is the first stage that makes an object/background decision: it removes or masks road-surface points so [[5_3_clustering_EN|Ch 5 §5.3]] does not spend most of its budget clustering asphalt. A good segmenter is not the one that deletes the most points. It is the one that leaves a residual non-ground cloud where curbs, legs, cones, pedestrians, vehicle underbodies, and road debris remain visible.

[[5_1_pointcloud_preprocessing_EN|Ch 5 §5.1]] establishes the four canonical representations: raw point cloud, voxel grid, range image, and BEV. This section consumes the §5.1 output: a deskewed cloud in `base_link`, voxel-downsampled by `pcl::VoxelGrid`, and de-noised by SOR/ROR. Intensity is not a stable material classifier, so ground segmentation here is geometric; intensity may be passed through for diagnostics, but it does not define asphalt, concrete, water, or vegetation. The optional branches are representation choices: Himmelsbach-style scan-line segmentation uses a range image or ring ordering, while Patchwork and Patchwork++ use a radial-grid view of the same preprocessed cloud.

The frame contract from [[5_8_ros2_integration_EN|Ch 5 §5.8]] also matters. `PointCloud2.header.stamp` is the end-of-scan time, per-point `time` is a non-negative `Δt` such that absolute time is `header.stamp − time`, and the cloud is usually in `base_link` after deskew. If a ground segmenter silently mixes `lidar` and `base_link`, or consumes stale `/tf`, it will confuse vehicle pitch with a sloped road. That failure then propagates into the residual cloud, not just into a local label map.

## Output contract

§5.2 produces a residual non-ground cloud: ground points are removed, or a mask is published beside the original cloud when consumers need original point indices. The residual inherits the §5.1 preprocessing decisions. It is uniformly filtered, but it is not uniformly dense; LiDAR point density still falls roughly quadratically with range.

[[5_3_clustering_EN|Ch 5 §5.3]] consumes this residual cloud for object proposals and must tune clustering thresholds with range-bias in mind. [[5_7_occupancy_freespace_map_roi_EN|Ch 5 §5.7]] may also consume ground labels or the residual cloud, but its cadence differs: occupancy can tolerate a slower or accumulated ground model for stable freespace, while clustering usually needs every-frame residuals.

## RANSAC plane fitting

RANSAC is the simplest honest starting point and a useful teaching algorithm; the operational default for this chapter is Patchwork++, introduced in the Patchwork section below. The algorithm samples minimal point sets, fits a plane, counts inliers within a distance threshold, and keeps the plane with the largest consensus set. As a toy sanity check, in a flat empty parking lot the dominant plane is the road; removing its inliers leaves cars, poles, cones, and walls. RANSAC works on a raw point cloud, needs no ring layout, and has a small number of parameters.

The plane model is usually written as:

```text
n_x x + n_y y + n_z z + d = 0
```

with a constraint that the normal `n` is near the gravity direction in `base_link`. Without that prior, the side of a truck, a wall, or a building façade can win when the visible road patch is small. With it, RANSAC becomes a fast ground hypothesis rather than a generic plane detector.

RANSAC is a useful teaching algorithm and a reasonable fallback for near-flat sites, but it is not the recommended primary segmenter for urban driving. Roads are not one plane: they include crowns, ramps, banked curves, speed humps, curbs, and driveway aprons. A global plane either under-removes ground or over-removes object points that happen to sit near it.

> [!warning] RANSAC failure modes
> RANSAC eats curbs when the distance threshold is larger than curb height, and it can eat flat-bed trucks because the bed is a large horizontal plane. Ramps, banked roads, raised sidewalks, and driveway crossings violate the single-plane assumption. Large vehicles close to the sensor can dominate the consensus and cause the road plane to lose.

## Himmelsbach scan-line segmentation

Himmelsbach proposed a scan-line ground segmentation method in 2010 for mechanical-spinning LiDAR. A spinning sensor already orders points into radial scan lines: as azimuth changes, each ring traces a line over the scene. Along a scan line, ground usually changes smoothly in height and slope, while obstacles create sharper jumps. This makes the method fast and physically intuitive.

The common implementation projects the cloud into a range image or preserves `(ring, azimuth)` ordering before voxel operations destroy adjacency. Each scan line is split into segments or bins, local slope is estimated between neighboring points or fitted line pieces, and points are labeled ground when height and slope remain consistent with the current profile. Because it works radially, it partly adapts to dense near points and sparse far points.

Himmelsbach-style methods remain valuable for explaining the link between LiDAR topology and classical perception. They also avoid expensive global neighbor search. Their limitation is that they assume a repeatable ring structure and usable adjacency; non-repetitive LiDAR, heavily downsampled clouds, or fused multi-LiDAR clouds can create holes and artificial neighbors.

> [!warning] Himmelsbach failure modes
> Scan-line methods can label curb faces as ground when slope thresholds are permissive, or steep ramps as obstacle when thresholds are strict. Overpasses and underpasses create two valid surfaces along similar azimuths but different heights. Standing water can vanish, shift, or appear as sparse low points, so the scan line sees missing evidence.

## Radial bins and grid heightmaps

Radial-bin methods generalize the scan-line idea into sectors and distance bins. Instead of following one ring, the node groups points by azimuth sector and radial distance, then estimates a local ground height or plane in each bin. This is a bridge from Himmelsbach to Patchwork: the representation is still polar, but the local model can use all points in a small region.

Grid-based heightmaps are the simpler rectangular alternative. Project points into BEV cells, store height and count statistics, then classify cells by height difference relative to neighbors. A 2.5D heightmap is easy to debug, deterministic, and useful as a production fallback when the ODD is controlled — port, mine, warehouse, and mapped-campus deployments are typical examples.

The heightmap approach also gives [[5_7_occupancy_freespace_map_roi_EN|Ch 5 §5.7]] a convenient interface: ground-like cells support freespace reasoning, and non-ground cells seed obstacle occupancy. The cost is resolution coupling. A cell size that is stable for freespace may erase curb geometry, while a curb-preserving cell can be too noisy or expensive for a wide ROI.

> [!warning] Radial-grid and heightmap failure modes
> Grid methods smear vertical structure inside a cell. A curb, tire, trailer leg, or low obstacle can disappear when the cell stores only minimum height. Rolling terrain makes continuous road look like obstacle steps. Overpasses require multi-layer handling; one 2.5D surface cannot represent road below and bridge deck above.

## GP-INSAC as historical context

GP-INSAC belongs in the lineage because it tries to solve a real weakness of single-plane fitting: the road is a smooth surface, not necessarily a plane. The method combines sampling ideas with a Gaussian-process model so the ground estimate can bend across the scene. In principle, this is what ramps, crowns, and rolling terrain need.

This family lost production favor because Gaussian-process inference and kernel tuning are hard to keep inside a predictable every-frame CPU budget as point count and ROI grow. It also asks more from calibration, ego-pose consistency, and hyperparameter maintenance than local-plane methods. As learned segmentation became common in Ch 6 systems, GP-based classical modeling lost the middle ground.

> [!warning] GP-INSAC failure modes
> A smooth prior can oversmooth curbs, median edges, and loading-dock lips. Kernel length scale becomes ODD-specific: too short follows noise, too long erases terrain changes. Runtime jitter is itself a safety problem because the ground stage sits before clustering.

## Patchwork and Patchwork++

Patchwork, introduced by Lim et al. in 2021, is the modern classical baseline for ground segmentation in this chapter. Patchwork++ by Lee et al. in 2022 keeps the same classical spirit and adds several practical improvements, including: **Reflected Noise Removal (RNR)**, which rejects below-ground returns from wet asphalt and specular surfaces; **Adaptive Ground Likelihood Estimation (A-GLE)**, which adapts parts of the likelihood / threshold setting from observed scene statistics so the operator does not need to pre-set everything per ODD (some parameter tuning still remains, see below); **Temporal Ground Revert (TGR)**, which uses the previous frame's ground estimate to recover patches that the current-frame likelihood test rejected too aggressively; plus refinements such as region-wise vertical-plane handling that catch curbs and walls the original Patchwork could mis-classify. Both algorithms are fully classical. They do not use learned class labels, neural features, or a hybrid semantic prior; their strength is careful geometric decomposition. TGR introduces frame-to-frame state into the ground stage — that is the only sense in which Patchwork++ is not strictly stateless, and it does not change the classical-vs-learned line.

The core representation is the concentric zone model. Space around the vehicle is divided into rings, sectors, and local regions. Near the sensor, regions are small because point density is high and curbs or low obstacles matter. Farther away, regions become larger because fewer points are available and the ground estimate needs more support.

Within each region, Patchwork fits a local plane and evaluates whether it is a plausible ground patch. Region-wise plane fitting is the key difference from global RANSAC: a road crown, ramp, or banked curve can be represented as many small planes. Ground likelihood estimation uses geometric cues such as uprightness, elevation, flatness, and local consistency to accept, reject, or refine candidate patches.

The behavior envelope is what earns Patchwork++ its baseline status: it handles non-flat roads better than global RANSAC, preserves more obstacle evidence than aggressive heightmaps, and remains cheap enough for C++ CPU deployment on a single-roof 32-beam spinning sensor. Region-wise PCA / plane fitting does scale with point count, so denser configurations (HDL-64 or 128-beam, multi-LiDAR fusion) usually need extra voxel downsampling at the §5.1 boundary to keep the per-frame budget. That is why this section recommends Patchwork / Patchwork++ as the default classical baseline when Ch 6 learned segmentation is not primary.

Parameter tuning still matters. Zone boundaries should match sensor beam density and near-field requirements. Plane thresholds should keep curbs and flat-bed trucks out of the ground class, but not make ramps into obstacles. A practical node exposes sensor height, ground normal, region sizes, seed selection, elevation threshold, and diagnostics.

> [!tip]
> Treat Patchwork++ as the baseline to beat, not as a proof that ground segmentation is solved. If a learned Ch 6 model is primary, Patchwork++ still makes sense as a monitor, fallback, or dataset label sanity check because it is fully classical and failure modes are interpretable.

> [!warning] Patchwork / Patchwork++ failure modes
> Patchwork / Patchwork++ can still eat curbs when a region mixes road top and curb face into one plausible plane. A flat-bed truck or bus floor can look like an elevated ground patch if elevation rejection is loose. Rolling terrain stresses seed selection, overpasses create multi-layer surfaces, and standing water reduces local-plane evidence even with RNR active.

## Shippable interface

A shippable C++ ground node should keep the full-cloud hot path simple. It subscribes to the §5.1 `PointCloud2`, verifies frame and field layout per [[5_8_ros2_integration_EN|Ch 5 §5.8]], runs the chosen model, and publishes either a residual cloud or an index mask plus diagnostics. Diagnostics should include input point count, ground ratio (overall and **by range band**, since range-dependent failure is a recurring theme), residual point count, processing time, TF age, and method-specific health signals such as rejected patch count or empty-region ratio.

The residual cloud is the main contract. It should preserve `x, y, z, intensity, ring, time` when those fields exist, because [[5_3_clustering_EN|Ch 5 §5.3]] may still use ring or range information to handle density bias. If §5.2 deletes too much, clustering never sees the object; if it deletes too little, clustering merges road texture and obstacle points.

Classical ground segmentation remains useful, but be specific about where it wins and where it loses. Patchwork++ wins on interpretability, CPU predictability, sensor and domain portability under limited labels, and fitness as a monitor or fallback in DL-primary stacks. Learned ground and semantic segmentation tend to win on semantic separation of drivable from non-drivable surfaces, unusual terrain (construction zones, gravel, debris), stacked scenes, and wet or specular surfaces where geometry alone is unreliable. Ch 5 provides the geometric baseline, fallback, monitor, and vocabulary needed to understand what the learned system replaced.

Ground segmentation is a **lossy early decision** in the pipeline. A wrongly-deleted point cannot be recovered by clustering, shape fitting, or tracking; a wrongly-kept point becomes a candidate object that downstream stages must spend budget filtering. The failures named below all share that mechanism — different scene types stress different geometric assumptions, but in every case the consequence is residual-cloud distortion that downstream sections inherit.

> [!warning] Failure modes for §5.10 catalog
> | id | cause | observable_symptom | downstream_hazard | mitigation | validation_test |
> |---|---|---|---|---|---|
> | `5_2.fm.curb_eaten_as_ground` | Thresholds are loose enough that curb faces and tops join the ground class. | Curbs disappear from the residual cloud; boundary clusters flicker or vanish. | [[5_3_clustering_EN\|Ch 5 §5.3]] misses low road-edge obstacles; [[5_7_occupancy_freespace_map_roi_EN\|Ch 5 §5.7]] may over-clear across a curb. | Use curb-focused validation, range-aware thresholds, smaller near-field Patchwork++ regions, and conservative residual preservation near height discontinuities. | Replay curb approaches, driveway entries, and parking-lot islands; require curb points above the catalog height threshold to remain residual. |
> | `5_2.fm.ramp_misclassified` | Ground model assumes near-horizontal local planes or uses seed selection that does not adapt to steep grades, ramps, and banked roads. | Uphill road patches appear as obstacle bands, or the ramp surface remains in the residual as a wide false cluster. | Clustering creates planner-blocking phantom obstacles; tracking may stabilize them as static objects. | Use gravity-aware but slope-tolerant local planes, tune region-wise thresholds on grade scenarios, and gate global plane fallbacks by road-pitch diagnostics. | Run garage ramps, freeway ramps, crowned roads, and banked turns; measure false residual area per frame and downstream false-track persistence. |
> | `5_2.fm.flatbed_truck_as_ground` | Large horizontal vehicle surfaces satisfy flatness and uprightness tests, especially when elevation rejection is weak or sensor height is misconfigured. | Truck beds, bus floors, or trailer decks are removed from the residual cloud while vertical sides remain. | Shape fitting underestimates object extent; the planner sees an incomplete obstacle or free space under a real vehicle. | Enforce elevation bands relative to expected ground, preserve elevated flat surfaces for clustering, and add object-size consistency checks after segmentation. | Replay flat-bed trucks, low trailers, and buses at multiple ranges; assert elevated horizontal surfaces above the road remain non-ground. |
> | `5_2.fm.overpass_single_layer` | A 2.5D or single-ground-surface model cannot represent road below and bridge or overpass deck above at the same BEV location. | Points on the overpass underside or deck are alternately removed as ground or left as broad residual sheets. | Occupancy and clustering report large false structures, or incorrectly clear space underneath an elevated surface. | Add height-layer checks, ROI context, and conservative handling for stacked surfaces; avoid using a single heightmap as the sole ground authority in multi-level scenes. | Replay underpasses, elevated ramps, and parking structures; inspect residual layers and require no free-space clearing through elevated surfaces. |
> | `5_2.fm.standing_water_sparse_returns` | Wet or standing-water surfaces produce missing, specular, or unstable low returns that break local plane evidence. | Ground ratio drops abruptly in puddle regions; residual contains shimmering low clusters or holes in freespace. | False obstacles trigger braking, or occupancy fails to clear genuinely drivable wet road. | Monitor ground-evidence confidence, use temporal consistency, keep intensity only as an auxiliary diagnostic, and validate wet-road behavior separately from dry asphalt. | Replay wet asphalt, puddles, and tire-spray scenes; measure false residual clusters and free-space clearing stability across repeated passes. |

| stage | compute | frame_rate_assumption | point_count_assumption | latency_p50_ms | latency_p99_ms | memory_mb | cadence | tf_freshness_assumption | assumptions_and_caveats |
|---|---|---|---|---:|---:|---:|---|---|---|
| `5_2_ground_segmentation` | cpu | 10 Hz Velodyne HDL-32E or VLP-32C-class single-roof mechanical-spinning sensor | after §5.1 preprocessing, ~35k-70k points/frame depending on return mode, voxel leaf size, clipping, and SOR/ROR | 8 | 22 | 80 | every-frame for [[5_3_clustering_EN\|Ch 5 §5.3]] residuals; optional lower-rate branch for [[5_7_occupancy_freespace_map_roi_EN\|Ch 5 §5.7]] | ≤ 50 ms | **Illustrative** Patchwork++ C++ CPU budget on a Jetson-class CPU after §5.1 preprocessing; assumes single-roof 32-beam spinning LiDAR, concentric zones, region-wise plane fitting, no learned model, no GPU, and no map lookup. GPU is not required for this stage. Production numbers vary with sensor / CPU class and should be measured for [[5_9_deployment_runtime_EN\|Ch 5 §5.9]]. |
