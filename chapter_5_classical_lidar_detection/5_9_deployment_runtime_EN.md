---
chapter: 5
section: 9
title: Deployment & runtime constraints
language: EN
workflow_status: reviewing
tags:
  - book/section
  - book/chapter-5
  - lang/EN
---

# 5.9 Deployment & runtime constraints

§§5.1–5.8 each committed an algorithmic stage and a runtime-budget row. This section is where those rows have to add up. It reconciles the eight per-stage budgets into one chapter-level picture, calls out the deployment invariants that bind every stage at once (TF freshness, sensor class, scheduler tail behaviour), and gives the reader the framing they need before they meet [[6_0_overview_EN|Ch 6]]: what classical LiDAR detection still ships in production, where it has been displaced, and what survives inside the stacks that displaced it.

## The bounded industry claim

The chapter's honest assessment is narrower than a slogan but firmer than a hedge. It rests on three definitions that have to stay tight whenever the claim is restated.

- **"Production stacks"** — stacks deployed on public roads in passenger vehicles or revenue-service robotaxi. Test fleets, demo videos, and research benchmarks do not count.
- **"Primary detection"** — the step that outputs class, 3-D bounding box, heading, and velocity to the planner. This explicitly excludes AEB-style emergency obstacle detectors, generic obstacle / occupancy fallbacks, and redundancy / sanity-check monitors, all of which are often classical and remain so by design.
- **"High-speed open-road AD"** — highway and urban-arterial driving at speeds at or above 30 km/h. Low-speed and restricted-ODD systems are a separate bucket with their own rules ([[1_10_odd_primer_EN|Ch 1 §1.10]]).

With those definitions in place: in 2026 production stacks for high-speed open-road robotaxi / L4 — Waymo, Cruise, Pony, Apollo Go, MOIA-class — primary 3-D bounding-box prediction is **universally DL-based** based on disclosed stack architectures and tech-report evidence. For consumer NOA with LiDAR (XPeng, Nio, Li-Auto class), public evidence and industry practice **strongly indicate** the same — but consumer-vehicle stack internals are partly opaque, so the chapter says "strong evidence" rather than "universal." In both buckets, classical detection has been displaced from the primary 3-D bbox prediction step. The two-tier evidence quality matters: flatten it and the claim either over-reaches or under-claims.

Where pure-classical primary detection still ships today:

- Low-speed and restricted-ODD AD: ports, mines, warehouses, last-mile sidewalk robots, airport tugs.
- AEB-style safety modules and emergency-braking obstacle detectors in production passenger vehicles, where determinism and ASIL-rateable behaviour outweigh detection rate.
- Curb / barrier / free-space monitors and redundancy / sanity-check layers in DL-primary stacks.
- Off-highway autonomy (agriculture, construction) where ODD is constrained and certification windows are different.

## Load-bearing classical pieces inside DL-primary stacks

The same production stacks that displaced classical primary detection still depend on classical pieces elsewhere in the pipeline. Five survive intact, and each is taught in this chapter.

1. **Preprocessing** — deskew, outlier removal, voxel downsampling, ROI gating. The DL detector still consumes a deskewed, denoised, downsampled cloud; the math from [[5_1_pointcloud_preprocessing_EN|Ch 5 §5.1]] does not get re-learned end-to-end in shipping stacks.
2. **Ground segmentation as a CNN front-end** — running Patchwork or a Himmelsbach-style radial segmenter before the learned detector reduces the input cloud by 40–60 %. [[5_2_ground_segmentation_EN|Ch 5 §5.2]] explains why the classical version is the production default in front of an end-to-end-trainable network.
3. **Tracking** — Kalman / IMM / Hungarian / JPDA on top of DL detections. The temporal layer over the learned detector is still very often the lifecycle, gating, and motion-model machinery from [[5_5_classical_tracking_EN|Ch 5 §5.5]], with learned ID embeddings or appearance cues as optional add-ons.
4. **Generic Obstacle Detection / occupancy** as the safety fallback for unknown classes. A DL detector can only detect the classes it was trained on; the class-agnostic occupancy / OctoMap pipeline from [[5_7_occupancy_freespace_map_roi_EN|Ch 5 §5.7]] is what catches the overturned truck, the fallen mattress, and the road-debris pile.
5. **Map-aided ROI gating** — Apollo HDMap polygon ROI lookup and Autoware `compare_map_segmentation`. Both pieces from [[5_7_occupancy_freespace_map_roi_EN|Ch 5 §5.7]] still gate the input to the DL detector and contribute the map-subtraction residual, with [[5_6_registration_EN|§5.6]] Role 2 (map subtraction) and Role 4 (map-aided ROI consistency) keeping the alignment honest.

## China-vs-US deployment priors

LiDAR economics and regulatory priors split the deployment story along regional lines. China's consumer ADAS market embraced LiDAR early — XPeng's 2021 partnership with Livox brought solid-state LiDAR onto a production passenger vehicle, and Hesai's AT128 now powers Didi/GAC L4 robotaxi pilots. The US split is sharper: robotaxi programs (Waymo, Cruise, Zoox) are LiDAR-heavy on the L4 side, while Tesla maintains the explicit camera-only counter-position on the consumer side. The claim "primary detection is DL-based" holds across both regions; the claim "the production stack contains a LiDAR" does not. A LiDAR chapter acknowledges the camera-only counter-position once and moves on; the rest of the book is where that conversation belongs ([[4_0_overview_EN|Ch 4]]).

## Per-stage runtime budget — the deployment consequence

The eight committed runtime-budget rows reconciled into one chapter-level table, normalized to a 10 Hz mechanical-spinning VLP-32C / HDL-32E single-roof LiDAR on a Jetson-class edge module. Numbers are illustrative — per-deployment latency, memory, and tail behaviour vary with sensor, RMW, allocator, CPU class, and accumulation cadence, and should be measured rather than assumed. The pinned deployment target (PyTorch → ONNX/TensorRT → C++ ROS2 → Jetson-class edge GPU) lives in [[1_9_deployment_target_EN|Ch 1 §1.9]] and constrains every row below.

| stage | compute | p50 (ms) | p99 (ms) | memory (MB) | cadence |
|---|---|---:|---:|---:|---|
| [[5_1_pointcloud_preprocessing_EN\|§5.1]] preprocessing | cpu | ~6 | ~18 | ~96 | every-frame |
| [[5_2_ground_segmentation_EN\|§5.2]] ground segmentation | cpu | 8 | 22 | 80 | every-frame |
| [[5_3_clustering_EN\|§5.3]] clustering | cpu | 8 | 24 | 96 | every-frame |
| [[5_4_object_shape_fitting_EN\|§5.4]] shape fitting | cpu | ~3 | ~9 | ~24 | every-frame |
| [[5_5_classical_tracking_EN\|§5.5]] tracking | cpu | ~1.5 | ~5.0 | ~16 | every-frame |
| [[5_6_registration_EN\|§5.6]] registration — Role 1 ICP | cpu | ~10 | ~22 | (shared with Role 2) | every-frame |
| [[5_6_registration_EN\|§5.6]] registration — Role 2 GICP | cpu | 20 | 45 | 200 | every 3rd frame |
| [[5_7_occupancy_freespace_map_roi_EN\|§5.7]] occupancy + ROI | cpu (gpu-optional) | 8 | 25 | 220 | every-frame; map-subtraction sub-rate |
| [[5_8_ros2_integration_EN\|§5.8]] ROS2 plumbing | cpu | ~0.6 | ~2.0 | ~8 + ~4.2 shared cloud buffer | every-frame |

**Sensor-class normalization.** Six rows assume VLP-32C / HDL-32E single-roof at ~60–70k points per frame after preprocessing. §5.8's row was committed against HDL-64E at ~130k points per frame because that section measures *transport overhead*, where the higher density is the harder case. Transport latency rescales roughly linearly with point count, so the §5.8 number maps to ~0.3 ms p50 on a VLP-32C; the table above keeps the §5.8 figure as committed and flags the rescale here rather than silently averaging across sensor classes. Multi-LiDAR deployments multiply preprocessing, ground, clustering, and fitting memory by the number of sensors; the prior-map tile and HDMap LUT are shared.

**Cadence reconciliation.** §5.6 plays two roles at two different cadences and the budget arithmetic has to keep them apart. Role 1 (inter-sweep deskew refinement, point-to-plane ICP) runs **every frame** at roughly half the GICP cost, contributing ~10 ms p50. Role 2 (map subtraction for change detection, full GICP scan-to-map) runs at **sub-rate every 3rd frame**, contributing ~20 ms p50 only when it fires. The every-frame chain is therefore `preprocess + ground + cluster + fit + track + occupancy + ROS2 plumbing + §5.6 Role 1` ≈ `6 + 8 + 8 + 3 + 1.5 + 8 + 0.6 + 10 ≈ 45 ms p50`. The Role-2 GICP tick adds ~20 ms p50 on the frame it fires; the rest of the period it adds nothing. Reporting a single 35 ms or 55 ms total for the pipeline is misleading either way, and the deal-loop will surface the elision; the split is the honest figure.

**p99 / tail reconciliation.** The p99 column does not sum cleanly. A naive sum over the every-frame chain is `18 + 22 + 24 + 9 + 5 + 25 + 2 + 22 ≈ 127 ms`, well past the 100 ms 10 Hz frame budget; with the Role-2 GICP tick on its sub-rate frame it crosses 170 ms. Real worst-case is bounded by but not equal to the sum because the per-stage tails are not perfectly correlated — a hard frame for §5.6 ICP often coincides with a hard frame for §5.3 clustering (both stress on dense urban scenes, weather, or sparse far returns), but rarely with a §5.8 RMW jitter spike. The honest implication is operational, not arithmetic: the scheduler must be sized for **tail-correlated stalls**, not just p50. A pipeline tuned to fit p50 inside 100 ms but ignoring the p99 envelope will skip frames under correlated load, and the failure shows up not as latency but as tracker covariance growth, occupancy cells that miss updates, and registration that quietly stops keeping up — which is the `5_9.fm.frame_budget_overrun_p99` entry below.

**Memory total.** A naive working-set sum across the every-frame stages plus the Role-2 GICP allocation is roughly `96 + 80 + 96 + 24 + 16 + 200 + 220 + 8 + 4.2 ≈ 740 MB` per pipeline instance for a single LiDAR. OctoMap-as-a-3-D-layer is **excluded** from the §5.7 220 MB figure and adds 50–200 MB more if enabled. Multi-LiDAR roughly multiplies the preprocessing, ground, clustering, and fitting components; the prior-map tile and HDMap LUT do not multiply, because they are shared.

**Frame-rate consistency.** Every row above assumes 10 Hz mechanical-spinning, the canonical case the chapter's algorithms were tuned against. 20 Hz solid-state sensors (Hesai AT128, RoboSense M-series) compress every per-stage budget by half; FMCW sensors with per-point radial velocity simplify dynamic-object handling at the registration and tracking stages but do not change the budget arithmetic. Solid-state and FMCW deployments inherit the framework above and rescale the numbers; they do not change the failure modes.

## ROS2 timing reconciliation

The eight rows commit one shared invariant — `≤ 50 ms` `/tf` freshness — and one shared transport pattern. Both are chapter-wide, not per-stage. Composable nodes intra-process pass-through ([[1_5_ros2_humble_essentials_EN|Ch 1 §1.5]]; [[5_8_ros2_integration_EN|§5.8]]) keeps `PointCloud2` shared-pointer between components in one process; the algorithmic stages from §§5.1–5.7 are typically composed inside a single perception container with the registration sub-rate component running as a separate composable node so its longer GICP tick does not block the every-frame chain. TF2 freshness is the chapter-wide invariant: every stage transforms in or out of `lidar / base_link / odom / map` at some point in its callback, and a stale `/tf` lookup is not a §5.1 or §5.5 bug — it is a chapter-wide deployment failure that lands wherever the lookup happens to live. `/tf_static` must be present before activation. The 20 Hz solid-state shift mentioned above does not alter this invariant — it only tightens the freshness requirement proportionally.

## Field robustness

Rain, fog, low light, and sensor degradation all degrade the same way through the classical pipeline: returns become noisier and sparser, intensity becomes less stable as a signal, and the per-stage thresholds tuned on clear weather start producing false positives (rain spray as ghost obstacles) and false negatives (fog reducing useful range). The chapter has handled the per-stage half — §5.1's de-noising and intensity caveats, §5.2's ground-segmentation failure modes, §5.3's clustering breakdowns under sparse far returns. The deployment half is operational: validation sets must include adverse-weather rosbags, freshness monitors must detect when sensor health degrades faster than the planner can react, and the safety fallback (Generic Obstacle Detection on the ungated occupancy grid) must remain active so a DL primary detector that fails on weather-distorted classes still has a class-agnostic backstop. Formal hazard analysis for these failure modes — fault trees, risk acceptance, residual-risk argument — belongs to [[11_0_overview_EN|Ch 11]]; this section catalogs the runtime symptoms.

## Failure-mode catalog entries (chapter-wide)

§§5.1–5.8 contributed 27 per-section failure-mode entries. The three §5.9 entries below are the chapter-wide / scheduler / deployment-time failures those per-section entries cannot capture, using the [[5_10_safety_and_validation_EN|§5.10]] catalog schema.

> [!warning] Failure modes for §5.10 catalog
> | id | cause | observable_symptom | downstream_hazard | mitigation | validation_test |
> |---|---|---|---|---|---|
> | `5_9.fm.frame_budget_overrun_p99` | Correlated tails on §5.6 + §5.3 + §5.2 push the every-frame chain past the 100 ms 10 Hz budget under sustained load. | Scheduler skips frames or executors back up; per-stage timing diagnostics show p99 spikes simultaneously across stages, not just one. | Tracker covariance grows during skipped frames; occupancy update misses cells; planner sees stale state on the frames where everything backs up at once. | Size the scheduler for tail-correlated stalls, not for p50; reserve headroom on the every-frame chain (target ≤ 60 ms p50 budget for a 100 ms period); deprioritize the §5.6 Role-2 GICP tick first when overload is detected; surface a runtime monitor on the per-stage p99 envelope. | Replay sustained-load scenarios (dense urban, adverse weather, multi-LiDAR fusion) and assert the every-frame chain stays inside the 100 ms envelope; require the scheduler to skip the Role-2 tick before it skips an every-frame stage. |
> | `5_cross.fm.subrate_registration_starves_under_load` | Sustained CPU pressure causes the §5.6 Role-2 GICP scan-to-map to miss its every-3-frames slot for several consecutive scheduling windows. | Map subtraction (§5.7 `compare_map_segmentation`) keeps using a stale registered prior-map; ego drift accumulates inside the registration period; the residual cloud the subtraction emits drifts away from "dynamic." | Ghost static structure flagged as dynamic obstacles; tracker initializes false tracks on building shoulders and lane-line ghosts; planner sees a non-stationary world where reality is stationary. | Monitor the Role-2 registration cadence and refuse map-subtraction output when the most-recent transform is older than `2 × period`; degrade to occupancy-only fallback above the freshness threshold; raise the registration component's ROS2 priority above the every-frame chain when correlated overload is detected. | Inject controlled CPU load on the Role-2 component and assert the freshness monitor trips before the subtraction residual exceeds a per-cell drift budget; require degraded-mode behaviour to be a clean fallback, not silent corruption. |
> | `5_cross.fm.sensor_class_mismatch_at_deploy` | Pipeline tuned on VLP-32C / HDL-32E single-roof; deployed on HDL-64E, AT128, or multi-LiDAR. Preprocessing voxel size, ground-region geometry, clustering tolerance, NDT voxel resolution, and registration prior-map pyramid level all become wrong-shaped at once. | No single stage fails loudly; ground segmentation leaves more residual, clustering over-segments, NDT covariances become rank-deficient, registration alignment carries a sub-decimeter bias — all simultaneously. | Pipeline silently degrades across stages; mAP-style metrics drop modestly while planning-relevant cluster topology and track continuity degrade more sharply; the failure looks like "the sensor is bad" rather than "the parameters are wrong." | Carry sensor-class metadata (model, single/dual return, ring count, scan rate) on a configuration topic checked at activation; refuse activation when the sensor class does not match the tuned profile; require per-sensor-class parameter sets validated against held-out logs of that sensor. | At deploy-time, stage a known-good rosbag from each supported sensor class through the pipeline and assert per-stage diagnostics (cells-per-voxel, points-per-cluster median, NDT condition number) stay inside their tuned envelopes; require the activation gate to refuse mismatched configurations. |

## Forward-point closer

[[5_10_safety_and_validation_EN|§5.10]] picks up the failure-mode catalog as the chapter's safety synthesis and connects the runtime invariants here to the formal hazard-analysis vocabulary [[11_0_overview_EN|Ch 11]] will own. [[6_0_overview_EN|Ch 6]] inherits the five-item load-bearing-classical list above as the part of the stack DL primary detection does not displace; readers crossing into Ch 6 should expect to see those five pieces still there, surrounding a different bbox predictor.
