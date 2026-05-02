---
title: Ch 5 research synthesis — Classical LiDAR detection
doc_type: research-synthesis
chapter: 5
phase: 1
status: draft
created: 2026-05-02
sources: [main-vault-scan, gemini-researcher, codex-collaborator-research]
tags: [research, chapter-5, classical-lidar]
---

# Chapter 5 research synthesis — Classical LiDAR detection

This document integrates three parallel research streams on Ch 5 (Classical LiDAR detection): main-session vault scan, `gemini-researcher`, and `codex-collaborator` (`MODE: RESEARCH`). It is the input artifact for Phase 2 (research deal-loop) and Phase 3 (chapter plan + allocation).

The chapter is **classical only** — no learned 3D detectors (PointNet / VoxelNet / SECOND / PointPillars / CenterPoint / transformer-based). Those land in Ch 6. In scope: geometric, hand-engineered, optimization-based, and shallow-ML methods, plus the production-grade preprocessing / tracking / map-gating layers that are still load-bearing classical even when the bbox predictor itself is DL.

---

## 0. Vault context (for grounding the synthesis)

The vault already declares a 10-section Ch 5 in `00_table_of_contents.md` and `chapter_5_classical_lidar_detection/5_0_overview_EN.md`:

```
5.0  Overview
5.1  Point-cloud preprocessing
5.2  Ground segmentation (RANSAC etc.)
5.3  Clustering — Euclidean, DBSCAN
5.4  Multi-object tracking — Kalman / IMM / JPDA
5.5  Registration — ICP / NDT / GICP        ← owns algorithmic depth forward-pointed from Ch 2 §2.3
5.6  Occupancy grids & free-space
5.7  ROS2 integration
5.8  Deployment & runtime constraints
5.9  Safety & validation (template instance)
```

Prerequisites (per the existing overview):
- **Ch 1 §1.3** LiDAR calibration & point-cloud basics, **§1.4** sensor sync, **§1.5** ROS2 essentials.
- **Ch 2** localization / ego-pose substrate — Ch 5 outputs feed into the tracker / planner via the ego-pose pipeline; Ch 5 §5.5 owns ICP / NDT / GICP depth that Ch 2 §2.3 forward-points to.

Downstream commitments:
- **Ch 6** (DL LiDAR detection) starts from this baseline; Ch 6 will displace the *bbox predictor* but inherits Ch 5's preprocessing, tracking, and map-gating in production stacks.
- **Ch 7** (camera+LiDAR fusion) consumes Ch 5's output representation (tracks + occupancy) and the L-shape / OBB convention.

This existing structure is the working baseline; the synthesis below flags two potential structural gaps for the Phase 2 deal-loop.

---

## 1. Integrated findings, by topic

### 1.1 LiDAR sensor families and what they imply for classical algorithms

The chapter must teach the four hardware axes that determine which classical algorithms apply, **not** a market survey of vendors. Product names appear only as one-line illustrations of an axis.

**Axis 1 — scan topology** (the most consequential for algorithm design):
- **Repeating ring (mechanical spinning).** Ordered horizontal scan lines at fixed elevation angles. Enables scan-line ground segmentation (Himmelsbach 2010), range-image connected components (Bogoslavskyi 2016), and ring-aware clustering. *Examples:* Velodyne HDL-64E (the KITTI sensor), VLP-16/32, Ouster OS-series, Hesai Pandar128, RoboSense Ruby Plus.
- **Non-repetitive (MEMS / solid-state).** No fixed vertical-ring table, no 360° single-sweep coverage. Forces algorithms onto per-point timestamps, accumulation windows, and spatial indexing rather than scan-line topology. *Example:* Livox Mid / Avia / HAP.
- **Flash / staring array.** Dense 2.5D-image-like output; processed more like a depth camera than a sparse cloud.

**Axis 2 — FoV pattern.** 360° roof-mount (robotaxi style) vs. 120° front-only (automotive ADAS / production). Front-only sensors push detection toward HD-map ROI gating rather than global 360° clustering.

**Axis 3 — ranging principle.** Time-of-flight (ToF, the dominant case — 905 nm) vs. FMCW coherent (per-point radial velocity is *measured*, not inferred — *example:* Aeva). FMCW simplifies dynamic-object filtering, track initialization, and motion compensation; a one-paragraph mention in the sensor primer suffices.

**Axis 4 — photodetector.** APD analog with waveform thresholding (traditional) vs. SPAD digital / single-photon (newer; image-like outputs; needs careful ambient-light and shot-noise handling). The teaching purpose is to motivate **de-noising defaults**, not to study detector physics.

**Spec-sheet caveat — call out once.** Public range numbers are quoted at varying reflectivity (10 %, 20 %, 80 %); "max range" ≠ useful detection range; point rate differs for single vs. dual/triple return; FoV may include ROI modes. Do not let the chapter become a vendor-comparison table.

**Industry-context bucket separation.** Consumer ADAS marketing, robotaxi L4 stacks, and academic benchmarks have different priors. The Tesla camera-only counter-narrative is real but separate from this chapter. China's LiDAR-heavy ADAS deployment vs. Western robotaxi-LiDAR vs. low-LiDAR-cost MEMS programs is one paragraph of context, not a tour. XPeng-Livox 2021 and Hesai AT128 in the Didi/GAC L4 robotaxi are illustrative reference points but should not anchor the section.

### 1.2 Point-cloud preprocessing (intended target: §5.1)

Both research agents and the vault's existing scope agree on the same sub-pipeline. Where they differ is in *emphasis* — codex foregrounds production failure modes; gemini foregrounds algorithmic identity.

**Sub-stages:**

1. **Motion compensation / deskew.** Mandatory above parking-lot speeds. A 10 Hz spinning sweep is acquired over ~100 ms; at 20 m/s the vehicle moves ~2 m during one sweep. Classical pipelines use high-frequency IMU/wheel/odometry to spherically interpolate ego pose and transform every point/packet to a common timestamp (typically the end of the sweep) in the vehicle or map frame *before* clustering or fitting. **This is the explicit handoff from Ch 2.**
2. **De-noising and outlier removal.** Statistical Outlier Removal (SOR), Radius Outlier Removal (ROR), return selection (single/dual/triple), near/far clipping, height gates. Rain, spray, fog, exhaust, glass reflections, retroreflectors, multi-path, and cross-LiDAR interference all create ghost points that downstream clustering happily promotes to obstacles. SPAD shot-noise statistics make this *not optional* (gemini emphasis).
3. **Intensity calibration — taught with caveats.** Intensity depends on range, incidence angle, aperture, receiver gain, firmware, wavelength, weather, and vendor calibration. Useful for lane markings / retroreflectors / channel features, but cross-sensor generalization is poor. **The chapter should not present intensity as a stable material classifier.** (Codex emphasis.)
4. **Multi-frame accumulation in vehicle frame.** Helps sparse far objects and Livox-style coverage; introduces ghost obstacles unless ego motion, object motion, and per-point timestamps are handled. Static-map accumulation helps curbs/road boundaries; dynamic-object accumulation needs track-aware compensation.
5. **Voxel downsampling.** PCL `VoxelGrid` filter; the workhorse cost-control step before clustering or registration.

**Production references:** Autoware `autoware_pointcloud_preprocessor` (crop boxes, outlier filters, distortion correction, accumulation/densification) and Apollo's preprocessing nodes are the canonical reads.

### 1.3 Ground segmentation (intended target: §5.2)

The most computationally critical classical step (40–60 % point-volume reduction). Both streams produced the same family tree, with codex giving more historical depth and gemini naming Patchwork as the current gold standard.

**Family tree, in pedagogical order:**

1. **Global RANSAC plane fit.** Easiest to teach, most brittle: fails on crests, banked roads, ramps, potholes, curbs, multi-level roads, and when large vehicles dominate the sample. Best as a *local / patch* method, not a global road plane. **Pedagogical entry point** — show the algorithm, then show its failure modes.
2. **Scan-line / radial-bin methods (Himmelsbach 2010).** Split the cloud into angular/radial bins, estimate local ground per bin, then run fast 2D connected components. The lasting lineage: "turn 3D into many small 1D/2D problems." Production-fast on spinning LiDAR.
3. **GP-INSAC / Gaussian-process terrain (Vasudevan / Douillard 2011).** Probabilistic continuous ground surface with outliers. Less production-friendly than radial / grid / patch methods because of cost and parameterization. Historical importance: the ground-as-surface idea, not the implementation.
4. **Patchwork / Patchwork++ (Lim 2021 / Lee 2022).** Concentric-zone region-wise plane fit + ground likelihood + adaptive thresholds + temporal ground revert + vertical-plane handling + reflected-noise removal. **Fully classical** — geometric / heuristic, no learned model. The mature endpoint of non-DL ground segmentation and the practical default to teach as the modern classical baseline. (An earlier draft of this synthesis incorrectly framed Patchwork++ as "hybrid / partly learned"; that framing was wrong and has been removed.)
5. **Grid-based elevation maps / 2.5D heightmaps.** Simple, cheap, good for mining/ports/warehouse ODDs and as a redundancy fallback.

**Failure-mode pedagogy (both streams stress this):** curbs removed as ground; ramps classified as obstacles; tall vehicles dominating the global plane; multi-level roads (overpasses).

### 1.4 Representations — unifying primer in §5.1, distributed treatment thereafter

Codex's Phase-2 critique pushed back on calling representations "tools, not topics" — a learner needs the conceptual map of representations early, because each algorithm choice down-stream is gated on which representation it consumes. Accepted.

Four classical representations the chapter must teach:

- **Raw point cloud** `(x, y, z, intensity)` indexed by KD-tree. The default; expensive when used directly for clustering.
- **Voxel grid / OctoMap (Hornung 2013).** Probabilistic occupancy, free-space, octree compression. Strong for free-space / mapping / static memory; too heavy/persistent for tight vehicle boxes.
- **Range image / spherical projection.** Maps 3D points to 2D `(azimuth, elevation)`. Enables fast 2D CV (connected components, depth-jump segmentation) at the cost of occlusion behind foreground. **Tightly tied to spinning-LiDAR scan order**; breaks on non-repetitive sensors without re-projection artifacts.
- **BEV grid (the bridge to Ch 6).** Hand-engineered channels — max height, mean height, intensity, density, occupancy, distance, angle per cell. Apollo's early LiDAR CNN consumed exactly these channels before learned segmentation. In Ch 5 the classical version is BEV occupancy + connected components, no CNN. This is the natural handoff to Ch 6's PointPillars.

**Pedagogical placement.** An **explicit named subsection §5.1.x "Representation map"** at the end of §5.1 (point-cloud preprocessing) lists the four representations, the methods they enable, and which sensor topologies they assume. It is a real subsection in the section's table of contents, not just trailing prose. Subsequent sections then introduce each representation where it is *used*: voxelization in §5.1; range image in §5.3 (clustering / segmentation); BEV grid in the renamed §5.7 (occupancy + map-aided ROI). No separate top-level "representations" section is created; §5.1.x is what gives the learner the substrate before the algorithms appear.

### 1.5 Clustering / segmentation (intended target: §5.3)

Both streams converge on four classical methods, and both flag the same failure mode (range-bias).

- **Euclidean clustering on the residual cloud.** PCL standard. Uses a KD-tree; `O(N log N)`. With one tolerance, over-segments near and merges far. Better classical systems use range-dependent tolerance, polar grids, voxel pre-clustering, or range-image adjacency.
- **DBSCAN-family on point clouds.** Density-based; robust to noise; hyperparameter-sensitive (`ε`, `minPts`) given LiDAR's varying density at range.
- **Connected components on range images (Bogoslavskyi & Stachniss 2016).** Operates on the 2D range image; computes the angle between adjacent pixels; depth-jump → split. Microseconds-per-frame; staple of early production AD stacks; tied to spinning-LiDAR ring structure.
- **Depth-jump / scan-line segmentation.** Pre-Bogoslavskyi lineage; conceptually similar.

**Failure-mode pedagogy (codex strong emphasis):** sparse far pedestrians; adjacent parked cars merged into one cluster; trucks split into pieces; guardrails mistaken for vehicles; rain clusters tracked as objects; deskew errors producing doubled cars.

### 1.6 Object-shape fitting — promote to first-class §5.4

**Both research streams independently flagged shape-fitting as a major classical topic; codex's Phase-2 critique then pushed back on the original "decimal §5.3.5" placement as structurally underweighted.** Accepted. Shape fitting is *where clusters become planner-consumable objects* — first-class status, not an afterthought. Recommended placement: **new §5.4 "Object-shape fitting — L-shape, OBB, class priors,"** with sections 5.4–5.9 in the existing overview shifting to 5.5–5.10 (chapter goes from 10 to 11 sections).

Topics this section must cover (classical detection cannot work without them):

- **L-shape fitting (Zhang 2017, Zhao 2021).** Vehicles present as L-shapes from corner viewpoints. Search-based criterion (rectangle orientation that maximizes points-near-edges); RANSAC L-fit. The canonical classical vehicle-box method.
- **PCA / oriented bounding boxes.** Fast but unstable for partial views — a visible car side can look like a line, corner, or rectangle depending on occlusion. Often produces boxes aligned to the L-shape diagonal rather than the true vehicle heading.
- **Min-area rectangle / convex hull.** Used in Autoware `autoware_shape_estimation` alongside L-shape and cylinder fits.
- **Class-prior box dimensions.** Cars / trucks / cyclists / pedestrians / cones / barriers each get different size gates, height ranges, min-points thresholds, and yaw priors from tracking or lane direction. **A detector with no priors produces visually plausible but planning-hostile boxes.**

**Pipeline placement reasoning.** The chapter pipeline becomes preprocess → ground → cluster → **fit** → track. Tracking (current §5.4) consumes fitted boxes, not raw clusters; placing fit *between* clustering and tracking is the correct dependency order.

### 1.7 Tracking-by-detection (intended target: §5.5 in the renumbered chapter)

Both streams emphasize: tracking is the part of "classical LiDAR" that **survives unchanged in DL-era production stacks**. This is the chapter's most durable content.

- **Filters.** Constant-velocity Kalman; Constant-Turn-Rate-and-Velocity (CTRV); Interacting Multiple Model (IMM) for stop/go/turning regime mixtures.
- **Association.** Nearest Neighbor (NN); Global Nearest Neighbor (GNN); Joint Probabilistic Data Association (JPDA); Multi-Hypothesis Tracking (MHT) for occlusion-heavy scenes.
- **AB3DMOT (Weng & Kitani 2019/2020).** The canonical baseline: 3D Kalman + Hungarian via 3D IoU. Reportedly 207.4 FPS on KITTI; competitive on KITTI/nuScenes. Pedagogically valuable because it shows how much "tracking performance" comes from simple geometry plus bookkeeping.
- **Track lifecycle.** Birth / confirmation / coast / deletion thresholds; sensitive to detection FP/FN rates; this is where production tuning lives.

**Cross-chapter handoff:** the camera-side counterpart (ByteTrack / OC-SORT / BoT-SORT) is in Ch 4 §4.6. Ch 5 §5.5 (renumbered) should explicitly call out which assumptions transfer (motion model, association via IoU) and which don't (3D vs 2D IoU; Mahalanobis vs Euclidean association).

### 1.8 Registration — ICP / NDT / GICP (intended target: §5.6 in the renumbered chapter)

This section is owed to Ch 2 §2.3 by forward-pointer — Ch 5 owns the *algorithmic depth*. Codex's Phase-2 critique noted (correctly) that without sharper framing, this section risks feeling like Ch 2 / SLAM material dumped into a detection chapter. The chapter must therefore frame registration as a **perception primitive**, not just a localization primitive.

**Why registration belongs in a classical-LiDAR-detection chapter — four perception roles:**

1. **Inter-sweep deskew refinement** — when IMU-only deskew is insufficient (high yaw rates, short-baseline IMU, IMU bias drift), scan-to-scan ICP/GICP refines the **inter-sweep pose estimate** (or, in continuous-time formulations, the trajectory) that the deskew transform consumes before clustering. Registration refines poses, not timestamps.
2. **Map subtraction for change detection** (Autoware `compare_map_segmentation`) — register the live cloud to a prior point-cloud map, then subtract; the residual is dynamic obstacles. Classical detection by elimination.
3. **Multi-frame accumulation alignment** — registering successive sweeps before accumulation prevents the "doubled-car" artifact from ego-motion / odometry drift.
4. **Map-aided ROI gating consistency** — the BEV ROI lookup table assumes the live cloud is in the map's frame. Frame consistency is owned primarily by TF / localization / map-relative pose (Ch 2 §2.5); registration is **one mechanism** for obtaining or correcting that alignment when localization-only is insufficient (e.g., GNSS-denied zones, map-stale regions).

The localization use (Ch 2 §2.3) is the fifth role and the one the reader has already met; this section provides the *algorithmic depth* the previous reference promised.

**Required content:**
- **ICP** (Besl & McKay 1992) — point-to-point and point-to-plane variants, convergence guarantees, local-minima failures.
- **NDT** (Magnusson 2007/2009) — voxelize the target into per-cell normal distributions, optimize the source fit. Smoother loss landscape than ICP, larger basin of convergence.
- **GICP** (Segal, Haehnel, Thrun 2009) — generalizes both via a probabilistic formulation; standard production choice in many SLAM stacks.
- **Production references:** PCL implementations; Autoware `ndt_localizer` / `ndt_scan_matcher` for vehicle pose; FAST-LIO / LIO-SAM use registration as a sub-module (covered at the SLAM level in Ch 2 §2.6).

**Framing line:** "You saw these names in Ch 2 §2.3. Here is how they actually work, and here are the four ways perception itself uses them."

### 1.9 Occupancy grids & free-space (intended target: §5.7 in the renumbered + renamed chapter)

- **2D occupancy grids** — log-odds update, beam-model vs. inverse-sensor-model.
- **3D OctoMap** (Hornung 2013) — probabilistic occupancy with octree compression; supports free-space ray carving.
- **Free-space carving / drivable-area estimation** — raycasting from sensor to point; clears dynamic obstacles from a static memory; **this is the safety-critical "is space occupied?" fallback in production stacks** even when the bbox predictor is DL (codex emphasis: load-bearing in Waymo and Apollo safety-fallback modules).
- **Generic Obstacle Detection (GOD).** Deep learning fails on unknown objects (overturned trucks, spilled cargo); classical voxel occupancy is the ultimate safety fallback for "something is there." **Both streams converge on this as a core pedagogical message.**

### 1.10 Map-aided detection / HD-map ROI gating (resolved: subsection of renamed §5.7)

**Codex foregrounded this; gemini included it briefly under "industry deployment."** Phase 2 deal-loop resolved this as a **subsection inside the renamed §5.7 "Occupancy, free-space & map-aided ROI gating."** This is a canonical-TOC rename and therefore a **structural change** that must be surfaced to the user alongside the §5.4 insertion (see §3).

Content the subsection must carry:

- **Apollo HDMap ROI filter.** Rasterizes drivable road / junction polygons into a BEV lookup table; removes buildings/trees/background outside ROI; runs obstacle segmentation only on the gated cloud. Even in Apollo's *CNN* LiDAR perception, the ROI LUT, MinBox builder, HM tracker, and map gating are classical.
- **Autoware `vector_map` / `compare_map_segmentation`.** Same idea; subtracts a previously-built point-cloud map from the live scan to isolate dynamic obstacles.
- **Free-space carving with map priors.** Drivable-area mask + LiDAR rays = high-confidence free-space.
- **Failure mode (must teach):** map gating can suppress real actors outside mapped polygons (construction detours, novel infrastructure) and couples perception correctness to map freshness. This connects to Ch 2 §2.7 (HD-map freshness & change detection).

### 1.11 ROS2 / Humble integration (intended target: §5.8 in the renumbered chapter)

Both streams agree on the same checklist:

- **Message conventions.** `sensor_msgs/msg/PointCloud2` with `header.stamp`, `frame_id`, `fields` such as `x, y, z, intensity, ring, time` (the per-point time field is what enables deskew).
- **TF2.** `lidar → base_link → odom/map`; conventions inherited from Ch 1 §1.1.
- **Lifecycle / managed nodes** for perception; composable nodes for zero-copy intra-process via loaned messages — large clouds without serialization overhead.
- **rosbag replay validity.** Only valid if `/tf`, `/tf_static`, clock, and per-point timing assumptions are preserved.
- **Reference stacks.** Autoware Universe / Core (`pointcloud_preprocessor`, `ground_segmentation`, `euclidean_cluster_object_detector`, `shape_estimation`, `compare_map_segmentation`); Apollo perception; MOLA.
- **C++ over Python** for the perception path per the book's deployment policy (rclpy only when concise).

### 1.12 Datasets, benchmarks, classical baselines (cross-cuts §5.5 and §5.9 / §5.10 in the renumbered chapter)

| Dataset | LiDAR | Region | Classical-baseline notes |
|---|---|---|---|
| KITTI (Geiger 2012) | Velodyne HDL-64E | Karlsruhe, daylight | Defines the classical baseline era. Strongly biased toward Velodyne-era methods. Small. |
| Waymo Open Dataset (Sun 2020) | 5 LiDARs, range-image w/ 2 returns | US, multi-city | Geography variation; classical methods see more failure modes. |
| nuScenes (Caesar 2020) | 32-beam + radar | Boston, Singapore | Sparser LiDAR; pure classical detection notably harder. |
| Argoverse 1/2 (Wilson 2023) | 64-beam + HD maps | US, multi-city | HD maps included; good for map-aided detection studies. |

**Both streams converge:** classical detection metrics (3D / BEV mAP) are weak proxies for planning usefulness. A wrong cluster split/merge can be catastrophic for tracking but barely move IoU. **Section 5.10 (safety & validation, in the renumbered chapter) needs to call this out** rather than present mAP as the end of the story.

### 1.13 Industry deployment & honest assessment (cross-cuts §5.9 and §5.10 in the renumbered chapter)

A message both research streams agreed on, **scoped precisely** so it does not become a universal claim the chapter cannot defend:

**The bounded claim.** In 2026 production stacks for high-speed open-road robotaxi / L4 (Waymo, Cruise, Pony, Apollo Go, MOIA-class), **primary 3D bounding-box prediction is universally DL-based** based on disclosed stack architectures and tech-report evidence. For consumer NOA with LiDAR (XPeng / Nio / Li-Auto class), public evidence and industry practice **strongly indicate** the same — but consumer-vehicle stack internals are partly opaque, so the chapter should phrase this as "strong evidence" rather than "universal." In both buckets, classical detection has been displaced from the *primary 3D bbox prediction step*; classical pieces survive elsewhere in the stack (next bullets). Three definitions need to be tight in the chapter prose:

- *"Production stacks"* = stacks deployed on public roads in passenger vehicles or revenue-service robotaxi.
- *"Primary detection"* = the step that outputs class + 3D bbox + heading + velocity to the planner. Excludes: AEB-style emergency obstacle detectors (often classical), generic obstacle / occupancy fallbacks (classical), redundancy monitors (classical).
- *"High-speed open-road AD"* = highway + urban-arterial, ≥ 30 km/h. Excludes: low-speed / restricted-ODD systems (next bullet).

**Where pure-classical primary detection still ships today:**
- Low-speed / restricted-ODD AD: ports, mines, warehouses, last-mile sidewalk robots, airport tugs.
- AEB-style safety modules and emergency braking obstacle detectors in production passenger vehicles, where determinism and ASIL-rateable behavior outweigh detection-rate.
- Curb / barrier / free-space monitors and redundancy / sanity-check layers in DL-primary stacks.
- Off-highway autonomy (agriculture, construction) where ODD is constrained and certification windows are different.

**Load-bearing classical pieces inside DL-primary production stacks:**
1. Preprocessing (deskew, outlier removal, voxel downsampling, ROI gating).
2. Ground segmentation (often classical in front of a CNN to reduce compute).
3. Tracking (Kalman / IMM / Hungarian / JPDA — on top of DL detections).
4. Generic obstacle detection / occupancy — the safety fallback for unknown classes.
5. Map-aided ROI gating (Apollo, Autoware).

**Counter-narratives worth a sentence, not a tour.** Tesla camera-only is the Western counter-position to LiDAR; out of scope for this LiDAR chapter. China-vs-US deployment priors (LiDAR-heavy consumer ADAS in China; robotaxi-LiDAR + camera-only ADAS split in the US) is one paragraph in §5.9 deployment, not a recurring theme.

This bounded framing is what justifies the chapter to a reader who already knows DL detection wins on the primary task.

### 1.14 Notable classical-era papers still cited

Curated from both streams, organized by topic:

- **Ground segmentation:** Himmelsbach 2010; Douillard 2011; Lim 2021 (Patchwork); Lee 2022 (Patchwork++).
- **Clustering:** Bogoslavskyi 2016 (range-image segmentation); Ester 1996 (DBSCAN — classic ML baseline).
- **Shape fitting:** Zhang 2017 (L-shape, IV); Zhao 2021 (L-shape pose tracking).
- **Tracking:** Weng & Kitani 2020 (AB3DMOT, IROS).
- **Mapping:** Hornung 2013 (OctoMap).
- **Library:** Rusu 2011 (PCL).
- **Datasets:** Geiger 2012 (KITTI); Sun 2020 (Waymo); Caesar 2020 (nuScenes); Wilson 2023 (Argoverse 2).
- **Historical roots:** Thrun 2006 (Stanley); Urmson 2008 (Boss / Urban Challenge) — useful for opening the chapter with the DARPA lineage.

---

## 2. Where the streams agreed, disagreed, or had different emphasis

**Agreed (high confidence):**
- The pipeline structure (preprocess → ground → cluster → fit → track) and the ROS2 wiring.
- The list of canonical methods per stage.
- The "load-bearing classical in DL-era production" framing.
- Patchwork as the modern classical-leaning ground-seg endpoint.
- AB3DMOT as the canonical tracking baseline.
- Failure-mode pedagogy is essential, not optional.

**Different emphasis (no contradiction):**
- **Codex** spent more time on production failure modes, sensor-spec caveats, China-vs-US deployment context, and the "classical pieces inside DL stacks" message. Suits §5.8 (deployment) and §5.9 (safety).
- **Gemini** spent more time on algorithmic identity, paper lineage, and dataset baseline tables. Suits §5.2–§5.4 (algorithm sections).
- **Vault scan** confirmed the prerequisite and forward-pointer chain (Ch 2 → Ch 5 §5.5; Ch 5 → Ch 6 / Ch 7) and the existing 10-section structure as the working baseline.

**Items resolved by Phase 2 deal-loop with codex (rounds 1–3):**
1. **Patchwork / Patchwork++ classification.** Resolved as **fully classical** — geometric / heuristic, no learned model. The earlier "hybrid" framing was wrong and has been removed from §1.3.
2. **Object-shape fitting structural status.** Resolved as **first-class new §5.4** (not a decimal §5.3.5). Surfaced to the user as a structural decision (see §3, decision 1).
3. **Map-aided detection placement.** Resolved as **subsection inside renamed §5.7** ("Occupancy, free-space & map-aided ROI gating"). The rename of a canonical TOC section is itself a structural change and is surfaced to the user as a structural decision (see §3, decision 2).
4. **Representations as a topic.** Resolved as **an explicit named subsection §5.1.x "Representation map"** at the end of §5.1, plus distributed treatment thereafter (range image in §5.3, BEV grid in §5.7). No dedicated top-level section. See §1.4.

**Adversarial-review-driven framing fixes also accepted:**
- Sensor primer (§1.1) reorganized around four hardware axes (scan topology / FoV / ranging principle / photodetector); product names demoted from market-survey to one-line illustrations.
- Registration framing (§1.8) explicitly states its four perception roles (deskew refinement / map subtraction / accumulation alignment / map-aided ROI consistency) so the section does not feel like Ch 2 / SLAM material dumped into Ch 5.
- "Nobody ships pure classical..." claim (§1.13) tightened with explicit definitions of "production stacks," "primary detection," and "high-speed open-road AD," plus an explicit list of where pure-classical *does* still ship.

---

## 3. Structural changes recommended to the user (two items, bundled)

The Phase 1 brief and the spec say structural changes (anything that alters the canonical TOC — section count, section title, ordering) are *proposed-not-adopted*: they require **explicit user approval** and a **lockstep update across memory + CLAUDE.md + README + TOC + chapter overview** before drafting begins.

After the Phase 2 deal-loop, **two structural changes** are recommended to the user as a single bundle.

### Decision 1 — Promote object-shape fitting to a first-class §5.4

**Change:** insert a new section "Object-shape fitting — L-shape, OBB, class priors" between current §5.3 (clustering) and current §5.4 (tracking). Existing sections 5.4–5.9 shift to 5.5–5.10. **Section count goes from 10 to 11.**

**Why:**
- Both research streams independently flagged shape-fitting as a major classical topic the current overview omits.
- The classical pipeline is preprocess → ground → cluster → **fit** → track. Tracking consumes fitted boxes, not raw clusters; placing fit *between* clustering and tracking matches the dependency order.
- L-shape fitting (Zhang 2017), PCA / OBB, min-area rectangle, convex hull, class-prior box dimensions are too consequential to fold inside a clustering section. Codex's Phase-2 round-1 critique explicitly rejected the "decimal §5.3.5" alternative as structurally underweighted.

### Decision 2 — Rename §5.7 to "Occupancy, free-space & map-aided ROI gating"

**Change:** rename what is currently §5.6 "Occupancy grids & free-space" (which becomes §5.7 after Decision 1) to **"Occupancy, free-space & map-aided ROI gating."** No new section; the scope of the existing section is broadened to include map-aided ROI gating as a major subsection.

**Why:**
- Codex foregrounded map-aided ROI gating as load-bearing classical content (Apollo HDMap ROI LUT, Autoware `compare_map_segmentation`, free-space carving with map priors).
- The content is conceptually adjacent to occupancy / free-space — they share BEV-grid representation and the "is space drivable / occupied?" pedagogy.
- A rename of a canonical TOC section is a structural change per the spec and therefore goes through the same user-approval gate as Decision 1, even though section count is unaffected by this decision alone.

### Final recommended Ch 5 section list (11 sections, after both decisions)

```
5.0   Overview
5.1   Point-cloud preprocessing (with end-of-section "Representation map" primer)
5.2   Ground segmentation (RANSAC / Himmelsbach / Patchwork / Patchwork++ / heightmaps)
5.3   Clustering & segmentation (Euclidean / DBSCAN / range-image CC / depth-jump)
5.4   Object-shape fitting — L-shape, OBB, class priors                      ← NEW
5.5   Multi-object tracking — Kalman / IMM / JPDA / AB3DMOT                  (was 5.4)
5.6   Registration — ICP / NDT / GICP (with the four perception roles)       (was 5.5)
5.7   Occupancy, free-space & map-aided ROI gating                           (was 5.6, renamed)
5.8   ROS2 integration                                                       (was 5.7)
5.9   Deployment & runtime constraints                                       (was 5.8)
5.10  Safety & validation (template instance)                                (was 5.9)
```

### Items resolved without structural change (decisions to record, not propose to the user)

- **Representations as a topic** — explicit named subsection §5.1.x "Representation map" + distributed treatment in §5.3 / §5.7. No section added.
- **Patchwork / Patchwork++ classification** — fully classical, no caveat. Resolved factually.
- **Sensor / industry-context density** — sensor primer reorganized around hardware axes (§1.1); industry deployment claim tightened with explicit definitions and a "strong evidence" qualifier for consumer NOA (§1.13). Editorial adjustments, not structural.
- **Registration framing** — four explicit perception roles (§1.8) with phrasing tightened so registration refines poses, not timestamps, and so registration is *one mechanism* for frame consistency, not the enforcer.

### Lockstep updates required if the user approves the bundle

Per `feedback_update_in_lockstep.md` and the spec's Phase-2 protocol, the following four artifacts update **together** in one `lockstep(chapter-5):` commit before Phase 3 drafts the chapter plan:

1. `00_table_of_contents.md` — insert a 5.4 row "Object-shape fitting — L-shape, OBB, class priors"; shift 5.4→5.5 ... 5.9→5.10 with their wikilinks updated to the new file slugs; rename the (renumbered) §5.7 row to "Occupancy, free-space & map-aided ROI gating."
2. `chapter_5_classical_lidar_detection/5_0_overview_EN.md` — same renumbering in the section table; insert §5.4 row; rename §5.7 row; update learning-objectives bullets to add a shape-fitting bullet and broaden the occupancy bullet to include map-aided ROI; update the abstract to mention "fit" in the pipeline narrative and "map-aided ROI gating" in the content list.
3. `chapter_5_classical_lidar_detection/5_0_overview_ZH.md` — mirrored renumber + rename + abstract update.
4. `README.md` §8 row 5 — update section count from `10` to `11`; update the parenthetical chapter description to mention shape fitting and ROI gating.

Memory and `CLAUDE.md` do not need touch-ups for a section-count change or a section rename inside an existing chapter (the canonical 13-chapter outline is unchanged).

---

## 4. Open questions (for user decision)

The Phase 2 deal-loop resolved every adjudicable item that did not require user authority. The questions below are the ones only the user can decide.

1. **Approve the structural-change bundle in §3?**
   - Decision 1 — insert §5.4 "Object-shape fitting" (10 → 11 sections).
   - Decision 2 — rename the (renumbered) §5.7 to "Occupancy, free-space & map-aided ROI gating."
   - Approval of the bundle triggers the four-artifact lockstep update specified in §3.
2. **Bilingual workflow at section level** — current vault has paired `_EN.md` / `_ZH.md`. The writer subagents will draft EN only (per the spec's open question 12.3). Confirm that ZH drafting remains a separate post-completion phase outside the writer pipeline for Ch 5 specifically.
3. **Code-language hygiene for §§5.1–5.8 (renumbered)** — book deployment policy says C++ for classical perception (PCL / Eigen / OpenCV). Pedagogical examples may benefit from short Python / `numpy` sketches for clarity (e.g., RANSAC plane fit in 10 lines). Confirm: C++ is mandatory for any code that would actually ship; Python sketches are allowed inline for explanation. (Phase-3 plan input, surfaced now.)
4. **Industry-context callout in §5.9 deployment (renumbered)** — recommended density: one paragraph total covering China-vs-US LiDAR deployment priors. Confirm or push back. (Editorial, not structural.)

---

## 5. Sources (deduplicated and grouped)

### Primary papers / books
- Himmelsbach, "Fast Segmentation of 3D Point Clouds for Ground Vehicles," IEEE IV 2010.
- Douillard, "On the Segmentation of 3D LIDAR Point Clouds," ICRA 2011.
- Lim et al., "Patchwork: Concentric Zone-based Region-wise Ground Segmentation…," IEEE RA-L / IROS 2021.
- Lee et al., "Patchwork++: Fast and Robust Ground Segmentation Solving Partial Under-Segmentation…," IROS 2022.
- Bogoslavskyi & Stachniss, "Fast Range Image-Based Segmentation of Sparse 3D Laser Scans for Online Operation," IROS 2016.
- Ester et al., "A Density-Based Algorithm for Discovering Clusters in Large Spatial Databases with Noise" (DBSCAN), KDD 1996.
- Zhang, "Efficient L-Shape Fitting for Vehicle Detection Using Laser Scanners," IEEE IV 2017.
- Zhao et al., "L-Shape Fitting-based Vehicle Pose Estimation and Tracking Using 3D-LiDAR," T-ITS / T-IV 2021.
- Weng & Kitani, "3D Multi-Object Tracking: A Baseline and New Evaluation Metrics" (AB3DMOT), IROS 2020.
- Hornung et al., "OctoMap: An Efficient Probabilistic 3D Mapping Framework Based on Octrees," Autonomous Robots 2013.
- Rusu & Cousins, "3D is Here: Point Cloud Library (PCL)," ICRA 2011.
- Besl & McKay, "A Method for Registration of 3-D Shapes" (ICP), TPAMI 1992.
- Magnusson, "The Three-Dimensional Normal-Distributions Transform — an Efficient Representation for Registration, Surface Analysis, and Loop Detection" (NDT), thesis 2009.
- Segal, Haehnel, Thrun, "Generalized-ICP" (GICP), RSS 2009.
- Thrun et al., "Stanley: The Robot that Won the DARPA Grand Challenge," JFR 2006.
- Urmson et al., "Autonomous Driving in Urban Environments: Boss and the Urban Challenge," JFR 2008.

### Datasets
- Geiger et al., KITTI Vision Benchmark Suite, CVPR 2012.
- Sun et al., Waymo Open Dataset, CVPR 2020.
- Caesar et al., nuScenes, CVPR 2020.
- Wilson et al., Argoverse 2, NeurIPS Datasets & Benchmarks 2023.

### Production-stack documentation
- Apollo: HDL64E S3 Installation Guide; 3D Obstacle Perception (Apollo Auto docs).
- Autoware Universe / Core: `autoware_pointcloud_preprocessor`, `autoware_ground_segmentation`, `autoware_euclidean_cluster_object_detector`, `autoware_shape_estimation`, `autoware_compare_map_segmentation`.
- ROS 2 Humble: `sensor_msgs/msg/PointCloud2`; tf2 docs.

### Sensor datasheets / product pages
- Velodyne VLP-16, HDL-64E S3.
- Ouster OS1 Rev7 datasheet.
- Livox Mid-40, Avia.
- Hesai AT128, Pandar128.
- RoboSense M1, Ruby Plus.
- Innoviz One / Two.
- Aeva Atlas Ultra.

### Industry milestones
- XPeng-Livox 2021 production-LiDAR partnership (XPeng IR 2020).
- RoboSense first automotive-grade solid-state LiDAR production line (RoboSense 2021).
- Hesai AT128 powering Didi/GAC L4 robotaxi (Hesai PR 2025).

---

## 6. Phase status

**Phase 1 (research, parallel) — complete.** Three streams collected (main vault scan + `gemini-researcher` + `codex-collaborator` MODE: RESEARCH). Synthesis drafted.

**Phase 2 (research deal-loop with codex CONFLICT) — converging.** Round 1 raised six items; round 2 conceded four, raised four further (representations subsection naming, two overstated registration phrases, NOA claim still slightly overconfident, map-aided ROI rename is itself structural and not "resolved without structural change"). All four addressed; round 3 should reach AGREED.

**Phase 2 outcomes that converged in this synthesis:**
- 4 items resolved without user input (Patchwork++ → fully classical; representations → §5.1.x named subsection + distributed; sensor density → axes-not-vendors; industry claim → tightened with explicit definitions and "strong evidence" qualifier for consumer NOA).
- 4 framing fixes accepted (sensor primer reorg, registration four-roles framing with corrected phrasing, NOA claim qualifier, representation primer named-subsection).
- **2 structural decisions** bundled for the user (§5.4 insertion + §5.7 rename), with the four-artifact lockstep plan attached in §3.

**Next gates:**
- Codex CONFLICT round 3 → AGREED on the synthesis.
- After AGREED: present synthesis to the user with the two-decision bundle. On approval, run lockstep update in one `lockstep(chapter-5):` commit; then Phase 3 (chapter plan + allocation) begins.
