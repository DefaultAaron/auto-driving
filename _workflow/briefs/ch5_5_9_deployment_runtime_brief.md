---
title: §5.9 deployment & runtime constraints — cc-writer brief
doc_type: section-brief
chapter: 5
section: 9
batch: 3
writer: cc-writer
phase: 4
status: draft
created: 2026-05-02
related:
  - "[[ch5_chapter_plan]]"
  - "[[ch5_classical_lidar_detection_synthesis]]"
tags: [workflow, chapter-5, batch-3, brief, cc-writer]
---

# §5.9 deployment & runtime constraints — cc-writer brief (Batch 3)

> [!info] Section assignment
> - **Section path:** `chapter_5_classical_lidar_detection/5_9_deployment_runtime_EN.md`
> - **Writer:** cc-writer (Rule 3a — contested framing)
> - **Length:** 1200–2000 words, medium depth
> - **Predecessors:** §§5.1–5.8 all at Phase-5 AGREED (Batch 1 + Batch 2 closed)
> - **Workflow gate after this batch:** §5.10 safety synthesis (Batch 4) — pause for explicit user approval before dispatching

---

## 1. Why this section exists

§5.9 is the **chapter-level synthesizer** for runtime, deployment, and the bounded "where pure-classical still ships" claim. It does three jobs that no other Ch 5 section can do:

1. **Synthesize the eight per-stage runtime budget rows** §§5.1–5.8 each commit into a chapter-level budget table, reconciling sensor-class assumptions and cadence so the totals are coherent.
2. **State the bounded "Nobody ships pure classical primary detection..." claim with three explicit definitions** (production stacks / primary detection / high-speed open-road AD), and list where pure-classical primary detection still ships today.
3. **Enumerate the load-bearing classical pieces inside DL-primary production stacks** (the five-item list from synthesis §1.13) so a reader who has just learned classical pipelines understands what survives into Ch 6 territory and why.

This is contested framing because the section must hold two seemingly opposite claims at once: classical primary detection has been displaced for high-speed open-road AD; classical pieces remain load-bearing in the same production stacks that did the displacing. cc-writer per Rule 3a.

---

## 2. Phase-3 plan row (binding, verbatim)

**Scope-in (must cover):**
- Per-stage CPU / GPU / latency budgets (preprocess / ground / cluster / fit / track / occupancy / registration / ROS2 plumbing) — synthesized from §§5.1–5.8 rows.
- ROS2 timing and message synchronization at the chapter level (composable nodes, intra-process pass-through, sub-rate registration cadence, TF2 freshness gate). §5.8 owns the per-stage plumbing; §5.9 reconciles cadences across the pipeline.
- Field robustness (rain, fog, low light, sensor degradation) — short paragraph, not a survey.
- **Bounded "Nobody ships pure classical primary detection..." claim** with three explicit definitions per synthesis §1.13.
- **One paragraph** on China-vs-US LiDAR deployment priors per synthesis §1.13 — not a recurring theme.
- Load-bearing classical pieces in DL-primary stacks (the five-item list from synthesis §1.13).

**Scope-out (do not cover):**
- Compiler / tooling details — Ch 1 §1.9 owns those.
- Dataset / labeling — Ch 10.
- Per-section algorithm details — §§5.1–5.8 own them; §5.9 only references via wikilinks.
- Hard-coded edge-GPU class — see §5 below; this stays an open user-input question.

**Depth:** medium. **Length:** 1200–2000 words.

---

## 3. The eight runtime budget rows §5.9 must reconcile

Each row was committed in the corresponding section's Phase-5 AGREED draft. The table below reproduces the binding numbers; the writer must enumerate them in the §5.9 chapter-level budget table and reconcile the assumptions.

| stage | compute | frame_rate | point_count | p50 (ms) | p99 (ms) | mem (MB) | cadence | tf_freshness |
|---|---|---|---|---|---|---|---|---|
| `5_1_pointcloud_preprocessing` | cpu | 10 Hz mechanical-spinning | VLP-32C single-return ~60k pts/frame | ~6 | ~18 | ~96 | every-frame | ≤ 50 ms |
| `5_2_ground_segmentation` | cpu | 10 Hz HDL-32E or VLP-32C single-roof | ~35k–70k pts/frame after §5.1 | 8 | 22 | 80 | every-frame for §5.3; optional lower-rate branch for §5.7 | ≤ 50 ms |
| `5_3_clustering` | cpu | 10 Hz mechanical-spinning | residual non-ground ~30k pts after §5.2 | 8 | 24 | 96 | every-frame | ≤ 50 ms |
| `5_4_object_shape_fitting` | cpu | 10 Hz | ~50 clusters/frame, median ~120 pts/cluster | ~3 | ~9 | ~24 | every-frame | ≤ 50 ms |
| `5_5_classical_tracking` | cpu | 10 Hz LiDAR boxes | ~50 detections/frame, ~30 active tracks | ~1.5 | ~5.0 | ~16 | every-frame | ≤ 50 ms (per-detection `base_link → odom`) |
| `5_6_registration` | cpu | 10 Hz spinning | ~70k voxel-downsampled (HDL-32E) | 20 | 45 | 200 | Role 1 every-frame (point-to-plane ICP, ~½ p50); Role 2 every-3-frames (GICP scan-to-map for map subtraction) | ≤ 50 ms |
| `5_7_occupancy_freespace_map_roi` | cpu (gpu-optional) | 10 Hz spinning | ~60k pts/frame after §5.1 (VLP-32C) | 8 | 25 | 220 | every-frame for occupancy + ROI; map-subtraction sub-rate (every 3rd frame) | ≤ 50 ms |
| `5_8_ros2_integration` | cpu | 10 Hz mechanical-spinning | ~130k pts/frame HDL-64E single-return | ~0.6 | ~2.0 | ~8 + ~4.2 MB shared cloud buffer | every-frame | ≤ 50 ms `/tf`; `/tf_static` present |

### Reconciliation work the writer owes:

1. **Sensor-class divergence — must be addressed explicitly.** Six rows assume VLP-32C / HDL-32E (~60–70k pts/frame after preprocessing); §5.8 alone uses HDL-64E (~130k pts/frame because it's measuring transport overhead at the higher density). The chapter-level budget table should normalize to one canonical sensor class (VLP-32C or HDL-32E single-roof) for comparability, with a callout that §5.8's HDL-64E figure rescales linearly with point count for transport overhead. Do **not** silently average across sensor classes.
2. **Cadence reconciliation — both Role 1 and Role 2 of §5.6 must be handled distinctly.** §5.6 commits `cadence: every-frame`; the assumptions cell explicitly says "for inter-sweep deskew refinement (Role 1) cadence is every-frame and uses point-to-plane ICP rather than GICP" (point-to-plane ICP is roughly half the GICP latency, so ~10 ms p50), and "for map subtraction (Role 2) cadence drops to every-3-frames" (the full GICP scan-to-map ~20 ms p50). The writer must split: (a) every-frame chain `preprocess → ground → cluster → fit → track + occupancy + ROS2 plumbing + §5.6 Role 1 ICP` ≈ `6 + 8 + 8 + 3 + 1.5 + 8 + 0.6 + ~10 ≈ 45 ms p50`; (b) sub-rate Role-2 GICP tick (every 3rd frame, gating §5.7's map-subtraction update) adds `~20 ms p50` when it fires. **Do not present a single 35 ms or 55 ms total** — both are misleading. Either present the split explicitly or, if the writer chooses to keep Role 1 disabled in the canonical budget, say so as an explicit deployment choice and re-derive.
3. **p99 / tail reconciliation is mandatory, not optional.** The eight rows commit p99 numbers (§5.6 = 45 ms, §5.7 = 25 ms, §5.3 = 24 ms, §5.2 = 22 ms, §5.1 = 18 ms, §5.4 = 9 ms, §5.5 = 5 ms, §5.8 = 2 ms). Naive sum ≈ 150 ms — well past the 100 ms 10-Hz frame budget. Tails do not sum cleanly because they are not perfectly correlated, but worst-case scheduling must reserve for them. The writer must include either a worked p99 reconciliation (with the standard caveat that real worst-case is bounded by but not equal to the sum) or an explicit "tails do not sum cleanly; the scheduler must be sized for tail-correlated stalls, not just p50" paragraph. **Skipping tail discussion in a deployment-and-runtime section is a Phase-5 critique waiting to happen.**
4. **Memory total.** Naive sum ≈ 740 MB working set. The writer should note this is per-pipeline-instance, single-LiDAR; multi-LiDAR roughly multiplies preprocessing/ground/cluster/fit memory and the prior-map tile is shared. OctoMap is explicitly excluded from §5.7's 220 MB and adds 50–200 MB if enabled.
5. **TF freshness.** All eight rows commit to ≤ 50 ms `/tf` freshness. The writer should call this out as a chapter-wide invariant, not eight separate constraints.
6. **Frame-rate consistency.** All eight rows assume 10 Hz mechanical-spinning. The writer should add one paragraph noting that 20 Hz solid-state (e.g. AT128) and FMCW sensors shift the trade-offs; the chapter-level budgets above are the 10-Hz canonical case.

---

## 4. The bounded industry-context claim (synthesis §1.13)

The exact wording is up to the writer's voice, but the **three definitions must be present and tight**:

- **"Production stacks"** = stacks deployed on public roads in passenger vehicles or revenue-service robotaxi.
- **"Primary detection"** = the step that outputs class + 3D bbox + heading + velocity to the planner. Excludes AEB-style emergency obstacle detectors, generic obstacle / occupancy fallbacks, and redundancy monitors.
- **"High-speed open-road AD"** = highway + urban-arterial, ≥ 30 km/h. Excludes low-speed / restricted-ODD systems.

The two-tier evidence quality must also be preserved:

- **Robotaxi L4** (Waymo, Cruise, Pony, Apollo Go, MOIA-class): primary 3D bbox prediction is **universally DL-based** based on disclosed stack architectures.
- **Consumer NOA with LiDAR** (XPeng / Nio / Li-Auto class): public evidence **strongly indicates** the same; consumer-vehicle stack internals are partly opaque, so phrasing is "strong evidence" rather than "universal."

**Where pure-classical primary detection still ships today** (the four-bullet list from synthesis §1.13):
1. Low-speed / restricted-ODD AD: ports, mines, warehouses, last-mile sidewalk robots, airport tugs.
2. AEB-style safety modules / emergency braking obstacle detectors in production passenger vehicles.
3. Curb / barrier / free-space monitors and redundancy / sanity-check layers in DL-primary stacks.
4. Off-highway autonomy (agriculture, construction).

**Load-bearing classical pieces inside DL-primary production stacks** (the five-item list from synthesis §1.13):
1. Preprocessing (deskew, outlier removal, voxel downsampling, ROI gating) — §5.1.
2. Ground segmentation as a CNN front-end to reduce compute — §5.2.
3. Tracking (Kalman / IMM / Hungarian / JPDA on top of DL detections) — §5.5.
4. Generic Obstacle Detection / occupancy as the safety fallback for unknown classes — §5.7.
5. Map-aided ROI gating (Apollo HDMap, Autoware `compare_map_segmentation`) — §5.7.

Each of these five points should wikilink back to the section that owns it.

**One paragraph on China-vs-US deployment priors:** LiDAR-heavy consumer ADAS in China (XPeng-Livox 2021, Hesai AT128 in Didi/GAC L4 robotaxi); robotaxi-LiDAR + camera-only ADAS split in the US (Tesla camera-only is the explicit counter-position, but the LiDAR chapter only acknowledges it in passing). One paragraph total. Do not turn this into a vendor tour.

---

## 5. Open user-input question — DO NOT hard-code

Per `README.md` §10.2, the **exact edge-GPU class** (Jetson Orin AGX / Orin Nano / Drive AGX / custom) is an open user-input question. §5.9 must NOT hard-code a specific class. Use "Jetson-class CPU" or "Jetson-class edge GPU" language, mark numbers as **illustrative**, and add an explicit caveat that per-deployment numbers should be measured rather than assumed. The eight per-stage rows already follow this discipline; §5.9 inherits it.

---

## 6. Forward contracts §5.9 commits to §5.10

§5.10 (Batch 4) consumes a per-section failure-mode catalog row from §§5.1–5.9. The §5.9 row must use these exact fields:

| Field | Required content |
|---|---|
| `id` | per-section identifier `5_9.fm.<short_slug>`; cross-section / emergent failures use `5_cross.fm.<short_slug>` (owned by §5.10, surfaced here if first observed) |
| `cause` | mechanistic explanation (1 sentence) |
| `observable_symptom` | what the system or operator sees (1 sentence) |
| `downstream_hazard` | planner / safety implication (1 sentence) |
| `mitigation` | classical / data / monitor (1 sentence) |
| `validation_test` | how Ch 11 §11.3 scenario testing would surface it (1 sentence) |

**Suggested §5.9 failure-mode entries** (writer chooses 2–3, no more). Per-section TF / deskew / NDT-voxel / DBSCAN / Kalman bugs are already owned by §§5.1–5.8 (see existing IDs `5_1.fm.deskew_failure_doubling`, `5_3.fm.dbscan_eps_too_small`, `5_5.fm.kf_diverges_on_turn`, `5_6.fm.ndt_voxel_size_mismatch`, `5_8.fm.missing_tf_static`, etc., plus the `5_cross.fm.deskew_then_cluster_doubling` already in §5.3). §5.9 entries must be **chapter-wide / scheduler / deployment-time** failures, not duplicates:

- `5_9.fm.frame_budget_overrun_p99` — when correlated tails on §5.6 + §5.3 + §5.2 push the every-frame chain past the 100 ms 10-Hz budget, the scheduler skips frames or executors back up; tracker covariance grows; occupancy update misses cells. Distinct from any per-stage latency claim because it is a budget-arithmetic / scheduling failure, not an algorithm bug.
- `5_cross.fm.subrate_registration_starves_under_load` — sustained CPU pressure causes §5.6 Role-2 GICP to miss its every-3-frames slot. Map subtraction (§5.7) keeps using a stale registered prior-map; ego drift accumulates inside the registration period; `compare_map_segmentation` quietly degrades. Distinct from `5_6.fm.icp_local_minimum` (algorithm convergence) and `5_7.fm.localization_drift_offsets_roi` (pose-source error) because the cause is **scheduler starvation**, not an algorithm or pose bug.
- `5_cross.fm.sensor_class_mismatch_at_deploy` — pipeline tuned on VLP-32C / HDL-32E single-roof; deployed on HDL-64E or AT128 (or multi-LiDAR). Preprocessing voxel size, ground region geometry, clustering tolerance, NDT voxel resolution, and registration prior-map pyramid level all become wrong-shaped at once; pipeline silently degrades across stages. Distinct from `5_6.fm.ndt_voxel_size_mismatch` because that's a single-stage tuning bug; this is the **chapter-wide deployment-time tuning-budget mismatch**.

---

## 7. Terminology contract (Item 9 — must-preserve)

The writer must use these terms exactly. Drift triggers Phase-5 deal-loop revision.

- `lidar` frame (lowercase); `base_link`; `odom`; `map`; `world`. Never "vehicle frame" without parenthetical clarification.
- `PointCloud2` (the ROS2 message), not "point-cloud message."
- "**point cloud**" (two words, no hyphen unless attributive: "point-cloud preprocessing").
- "**ICP**" / "**NDT**" / "**GICP**" (uppercase); "**Hungarian**"; "**Kalman filter**"; "**IMM**"; "**JPDA**"; "**MHT**"; "**AB3DMOT**".
- "**Patchwork**" / "**Patchwork++**" — fully classical (no "hybrid" caveat); "**RANSAC**"; "**DBSCAN**".
- "**OctoMap**" (CamelCase); "**occupancy grid**" (lowercase generic); "**free-space carving**" (hyphen); "**drivable area**" (no hyphen).
- "**Generic Obstacle Detection**" (capitalized) when meaning the safety-fallback occupancy-based classical detector.
- "**HD-map ROI gating**" (consistent dashing); "**Apollo HDMap**" (proper noun; HDMap is Apollo's term); "**`compare_map_segmentation`**" when naming Autoware's package by its package name.
- The Ch-5 pipeline is `preprocess → ground → cluster → fit → track`. Arrows are `→`, never `->`.
- "**deskew**" (one word, lowercase).
- "**ego-pose**" / "**ego-state**" (hyphen, lowercase).
- "**Tracking-by-detection**" — never "track-by-detect."
- "**Object-shape fitting**" or "**shape fitting**" — never "shape estimation" except when literally citing Autoware's `autoware_shape_estimation`.

**Cautions:**
- Intensity is **not** a stable material classifier.
- Patchwork / Patchwork++ are **fully classical** — no "hybrid" caveat.
- Primary 3D bbox prediction is "universally DL-based" for robotaxi/L4; "strong evidence indicates DL" for consumer NOA. Don't flatten the distinction.

---

## 8. Voice rules (Item 6 — binding)

- **Tense:** present for what algorithms / pipelines do; past for historical lineage.
- **Register:** technical-pedagogical, not lecture-academic. Short paragraphs (3–5 sentences). Lists when enumerating; prose otherwise.
- **Code policy:** C++ for shippable perception; Python ≤ 10 lines as compact pseudocode only. §5.9 likely has zero or near-zero code — it's a synthesis section. If you do show ROS2 timing or composable-node pseudocode, keep it minimal.
- **Callouts:** `> [!info]` for status / metadata; `> [!abstract]` for section summary; `> [!warning]` for failure modes; `> [!tip]` for operational guidance.
- **Wikilinks:** `[[N_M_slug_EN|Ch N §N.M]]` for cross-references.
- **No emojis**; no marketing-style adjectives.
- **Failure-mode pedagogy is mandatory** — §5.9 ends with at least one failure-mode subsection / callout per the §5.10 catalog contract.
- **Honest assessment over enthusiasm** — when classical has been displaced, say so plainly and explain what classical role survives.
- **Inline-restate prerequisites** — Ch 0–Ch 4 sections are mostly `planned`. Re-state minimum prerequisite knowledge inline (1–3 sentences) before using a Ch-1 or Ch-2 concept.

---

## 9. Prerequisite chain (Item 7)

Cross-references the writer should embed:
- Ch 1 §1.5 — ROS2 / Humble essentials (the lifecycle / composable-node vocabulary).
- Ch 1 §1.9 — pinned deployment target (PyTorch → ONNX/TensorRT → C++ ROS2 → Jetson-class edge GPU). This is where the deployment policy lives.
- Ch 1 §1.10–§1.11 — ODD primer + hazard-analysis intro; §5.9 anchors the "where pure-classical still ships" list against ODD constraints.
- Ch 2 §2.1–§2.2 — ego-pose feeds §5.1 deskew; §5.9's TF freshness invariant traces here.
- Forward-points: Ch 6 (DL LiDAR detection) inherits the load-bearing-classical-in-DL-stacks list; Ch 11 (Safety) owns the formal hazard-analysis process §5.10 introduces vocabulary for.

---

## 10. Section structure (suggested, not binding) + length budget per block

The writer may rearrange, but should hit each block. The per-block length budget below sums to ~1700 words, leaving ~300 words of slack inside the 1200–2000 target. **Lead with the framing center** (the bounded claim) — readers who just finished §§5.1–5.8 already know per-section budgets; what they need first is the synthesis interpretation that gives those numbers meaning.

1. **Opening (≤120 words, 1 paragraph).** What §5.9 is and why it exists — the chapter-level synthesis. Foreshadow the bounded claim without stating it yet.
2. **The bounded industry claim — the framing center (~350 words, 3 paragraphs).** Three explicit definitions ("production stacks" / "primary detection" / "high-speed open-road AD"); two-tier evidence (robotaxi L4 = "universally DL-based"; consumer NOA with LiDAR = "strong evidence"); the four-bullet "where pure-classical primary detection still ships" list as a tight bullet list (≤ 8 lines total).
3. **Load-bearing classical pieces inside DL-primary stacks (~250 words, tight bullet list of 5 items).** Each item: 1–2 sentences, wikilink back to the owning section. Do not re-explain the algorithms; the owning sections did that.
4. **One paragraph on China-vs-US deployment priors (~120 words).** XPeng-Livox 2021 / Hesai AT128 in Didi-GAC L4 / Tesla camera-only counter-position acknowledged in passing. **Hard limit: one paragraph.** Not a vendor tour.
5. **Per-stage runtime budget table — the deployment consequence (~450 words).** The chapter-level table reproducing the eight rows in canonical form (normalize §5.8 to VLP-32C / HDL-32E for comparability, with a note that HDL-64E rescales linearly), plus 2–3 paragraphs walking through: sensor-class normalization, cadence reconciliation (every-frame chain ~45 ms p50 *including* §5.6 Role 1 + sub-rate Role-2 GICP tick adding ~20 ms p50 every 3 frames), p99 reconciliation (tails do not sum cleanly; scheduler must be sized for tail-correlated stalls), memory total, multi-LiDAR scaling note.
6. **ROS2 timing reconciliation (~150 words, 1–2 paragraphs).** Composable-node intra-process pass-through for cloud data; sub-rate registration as a separate component; **TF2 ≤ 50 ms freshness as a chapter-wide invariant** (one place, not eight); 10-Hz canonical case + brief note on 20-Hz solid-state shift. Wikilink heavily to §5.8 — do not re-teach.
7. **Field robustness (~150 words, 1 paragraph).** Rain / fog / low light / sensor degradation. **Hard limit: one paragraph.** Forward-point to Ch 11.
8. **Failure-mode catalog entries — 2–3 entries chosen from §6 of this brief (~100 words for the table rows themselves).** Use the §5.10 contract schema. The entries must be chapter-wide / scheduler / deployment-time, not per-section duplicates.
9. **Forward-point closer (≤80 words).** §5.10 picks up the hazard-analysis vocabulary; Ch 6 inherits the load-bearing-classical list as the part-of-the-stack-it-does-not-displace.

**Compression discipline:** if a block goes over its budget, cut prose, not lists / tables. The four-item ships list and five-item load-bearing list are both load-bearing structurally and must not be paraphrased into prose.

---

## 11. Frontmatter

```yaml
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
```

Note: `workflow_status: reviewing` because Phase 5 deal-loop runs immediately after the writer returns. `complete` is set only at Phase 6 chapter AGREED.
