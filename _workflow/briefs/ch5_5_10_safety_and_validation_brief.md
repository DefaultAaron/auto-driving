---
title: §5.10 safety & validation — cc-writer brief
doc_type: section-brief
chapter: 5
section: 10
batch: 4
writer: cc-writer
phase: 4
status: draft
created: 2026-05-03
related:
  - "[[ch5_chapter_plan]]"
  - "[[ch5_classical_lidar_detection_synthesis]]"
  - "[[ch5_5_9_deployment_runtime_brief]]"
tags: [workflow, chapter-5, batch-4, brief, cc-writer]
---

# §5.10 safety & validation — cc-writer brief (Batch 4)

> [!info] Section assignment
> - **Section path:** `chapter_5_classical_lidar_detection/5_10_safety_and_validation_EN.md`
> - **Writer:** cc-writer (Rule 3a — high-judgment synthesis; classified at Phase 3, locked)
> - **Length:** **2000–2200 words**, medium depth. (The Phase-3 plan listed 1000–1800; that band was set before the chapter-wide failure-mode index was scoped to all 37 entries. The catalog index alone is ~1400 words; the prose blocks add ~700–800. The relaxed band is recorded here and is the binding target for the writer; the Phase-3 plan length cell will be updated in the Phase-6 lockstep alongside the chapter close.)
> - **Predecessors:** §§5.1–5.9 all at Phase-5 AGREED (Batches 1+2+3 closed)
> - **Workflow gate after this section:** chapter complete; Phase 6 chapter voice pass next, then `chapter(5):` commit

---

## 1. Why this section exists

§5.10 is the **chapter-level safety / validation synthesizer**. It does three jobs no other Ch 5 section can do:

1. **Integrate the chapter-wide failure-mode catalog.** §§5.1–5.9 each committed per-section catalog rows under the schema fixed in `_workflow/plans/ch5_chapter_plan.md` Item 5. §5.10 owns the cross-section IDs (`5_cross.fm.*`) and presents the catalog as one organized table the reader can scan as a hazard inventory for the classical LiDAR pipeline.
2. **Critique 3D / BEV mAP as a planning-usefulness proxy.** Synthesis §1.12 and §1.13 converged on this: a wrong cluster split/merge can be catastrophic for tracking but barely move IoU; mAP is necessary, not sufficient. §5.10 makes that critique explicit and points to scenario-based testing as the missing half.
3. **Anchor ODD constraints inherited from [[1_10_odd_primer_EN|Ch 1 §1.10]] and forward-point to [[11_0_overview_EN|Ch 11]] for the formal process.** §5.10 introduces vocabulary (HARA, ASIL, SOTIF) carefully — labels each as "introduced here, formal definition in Ch 11" — and commits to no claims about ASIL ratings or formal safety case structure. This is the load-bearing constraint: §5.10 must read as a synthesis section that gives the reader a map for the rest of the chapter and a doorway to Ch 11, not as a substitute for Ch 11.

This is **high-judgment synthesis** because the section must hold three things at once: (a) the catalog is a chapter-wide hazard inventory, but (b) hazard analysis as a formal process belongs to Ch 11, and (c) the mAP critique is an evaluation-discipline argument, not a metric-deprecation announcement. cc-writer per Rule 3a (locked at Phase 3); Phase 5 runs as Path A bidirectional with codex-collaborator every round.

---

## 2. Phase-3 plan row (binding, verbatim)

**Scope-in (must cover):**
- **Per-stage hazard analysis** — organize the chapter-wide failure-mode catalog as a hazard inventory; identify chapter-wide patterns the per-section entries do not name individually.
- **ODD constraints inherited from [[1_10_odd_primer_EN|Ch 1 §1.10]]** — anchor the catalog against ODD; what ODD assumptions does each failure mode bind?
- **Metric weakness** — 3D / BEV mAP as a poor proxy for planning usefulness; cluster split/merge example; what scenario-based testing would catch.
- **Failure-mode taxonomy** — the catalog needs a small organizing structure (e.g., perception bug / scheduler bug / deployment-time bug; or geometric / temporal / configuration). Pick one and be consistent.
- **Cross-pointer to [[11_0_overview_EN|Ch 11]]** — HARA, ASIL, SOTIF vocabulary introduced here, formal definitions there.

**Scope-out (do not cover):**
- ISO-26262 / SOTIF process detail — Ch 11 §11.8 owns these.
- Scenario-based testing depth — Ch 11 §11.3 owns this; §5.10 references it as the missing half of validation, no more.
- Per-stage algorithm details — §§5.1–5.9 own them; §5.10 only references via wikilinks.
- Formal safety-case argument structure (GSN, etc.) — Ch 11.

**Depth:** medium. **Length:** **2000–2200 words** (relaxed from the Phase-3 plan's 1000–1800 band; see the Section-assignment box above for the rationale).

---

## 3. The chapter-wide failure-mode catalog §5.10 must integrate

Each section §§5.1–5.9 committed per-section rows under the contract in `ch5_chapter_plan.md` Item 5 (id, cause, observable_symptom, downstream_hazard, mitigation, validation_test). §5.10 owns the cross-section `5_cross.fm.*` IDs surfaced in the host sections.

**Total catalog: 34 per-section entries + 3 cross-section entries = 37 entries.**

### Per-section entries to integrate (34 total)

**§5.1 (3):** `5_1.fm.rain_spray_ghosts`, `5_1.fm.deskew_failure_doubling`, `5_1.fm.intensity_misclassification`.

**§5.2 (5):** `5_2.fm.curb_eaten_as_ground`, `5_2.fm.ramp_misclassified`, `5_2.fm.flatbed_truck_as_ground`, `5_2.fm.overpass_single_layer`, `5_2.fm.standing_water_sparse_returns`.

**§5.3 (4):** `5_3.fm.range_bias_oversegmentation`, `5_3.fm.merged_close_vehicles`, `5_3.fm.dbscan_eps_too_small`, `5_3.fm.range_image_projection_holes`.

**§5.4 (6):** `5_4.fm.yaw_flip`, `5_4.fm.partial_view_undersized_box`, `5_4.fm.wrong_prior_inflated_box`, `5_4.fm.l_pointing_wrong_way`, `5_4.fm.spray_inflated_box`, `5_4.fm.subcluster_halves_one_box`.

**§5.5 (4):** `5_5.fm.id_switch_under_occlusion`, `5_5.fm.kf_diverges_on_turn`, `5_5.fm.ghost_track_from_clutter`, `5_5.fm.coasted_track_outlives_object`.

**§5.6 (3):** `5_6.fm.icp_local_minimum`, `5_6.fm.ndt_voxel_size_mismatch`, `5_6.fm.gicp_degenerate_covariance`.

**§5.7 (4):** `5_7.fm.map_suppresses_real_actor`, `5_7.fm.stale_map_after_construction`, `5_7.fm.localization_drift_offsets_roi`, `5_7.fm.ray_casting_through_glass`.

**§5.8 (4):** `5_8.fm.missing_tf_static`, `5_8.fm.qos_mismatch_drops_clouds`, `5_8.fm.sim_time_not_honored`, `5_8.fm.pointcloud2_offset_drift`.

**§5.9 (1 per-section):** `5_9.fm.frame_budget_overrun_p99`.

### Cross-section entries §5.10 owns (3 total)

| id | surfaced in | cross-section reason |
|---|---|---|
| `5_cross.fm.deskew_then_cluster_doubling` | §5.3 | Symptom is in clustering; root cause is §5.1 deskew. |
| `5_cross.fm.subrate_registration_starves_under_load` | §5.9 | Scheduler-side starvation that breaks §5.6 + §5.7 jointly. |
| `5_cross.fm.sensor_class_mismatch_at_deploy` | §5.9 | Tuned-on-A, deployed-on-B mismatch that degrades many stages at once. |

### What §5.10 does with the catalog

§5.10 is **not** a full reproduction of the 6-field catalog — that would be ~10–14k words for 37 rows, which blows the section's 2000–2200 word target by an order of magnitude. The full schema already lives in §§5.1–5.9. §5.10 publishes a **chapter-wide index** that lets a reader scan the hazard inventory at a glance and jump to the host section for full detail.

**Required artifact: a compressed index table with these three columns only**

| column | content |
|---|---|
| `id` | the catalog ID, wikilinked to the host section header that contains the full row (e.g., `[[5_2_ground_segmentation_EN#failure-modes\|5_2.fm.curb_eaten_as_ground]]`). The wikilink anchor format depends on what the host section actually uses; if anchor-linking is fragile, link to the section file and let the reader scroll. |
| `one-line cause` | a paraphrased ≤ 15-word version of the host section's `cause` field. Paraphrase, do not copy verbatim — copy-paste leaks original phrasing into a different rhetorical context. |
| `downstream hazard` | a paraphrased ≤ 15-word version of the host section's `downstream_hazard` field. Same paraphrase discipline. |

`observable_symptom`, `mitigation`, and `validation_test` are **not** in the index — those live in the host section's full row and the index's wikilink is what gets the reader to them. **Source-of-truth discipline:** the host section's row is authoritative; the index paraphrases for skim-readability and must not contradict the host. If the writer notices a host-row error while indexing, surface it as a Phase-5 critique on the relevant earlier section, not a §5.10 fix.

Estimated index length at 37 entries × ~35 words per row (id + 15-word cause + 15-word hazard + table cell overhead) ≈ **1300 words** for the table proper, plus ~100 words for the framing paragraph and bucket headers ≈ **~1400 words** total for the index block. §10's catalog-block budget is set to that figure.

**Primary organizing axis (committed, not optional): cause-class.** The index is grouped into four cause-class buckets in this fixed order:

1. **Geometric / single-stage** — algorithm produces wrong geometry inside one stage; fix lands inside that stage (e.g., `5_4.fm.yaw_flip`, `5_3.fm.range_bias_oversegmentation`, `5_2.fm.curb_eaten_as_ground`).
2. **Temporal / single-stage** — algorithm produces wrong behaviour over time inside one stage; fix lands inside that stage's temporal logic (e.g., `5_5.fm.kf_diverges_on_turn`, `5_5.fm.coasted_track_outlives_object`).
3. **Cross-stage** — fix lands in a different stage from where the symptom appears (e.g., `5_cross.fm.deskew_then_cluster_doubling` — symptom in §5.3, fix in §5.1).
4. **Configuration / scheduler / deployment-time** — fix lands in tuning, parameter management, or runtime scheduling rather than algorithm correctness (e.g., `5_8.fm.missing_tf_static`, `5_9.fm.frame_budget_overrun_p99`, `5_cross.fm.sensor_class_mismatch_at_deploy`, `5_2.fm.flatbed_truck_as_ground` because the dominant fix is elevation-band misconfiguration, not a §5.2 algorithm change).

The bucket-assignment rule below makes these examples binding, not illustrative — every entry in the index lands in exactly one of the four buckets per the same rule.

**Secondary tags (optional, no separate column):** ODD-binding (weather / road-grade / map-freshness / dynamic-actor / etc.) may be noted parenthetically inside the cause line. Do not add a column — the table stays three columns.

**Bucket-assignment rule (binding, not optional):** primary cause-class is chosen by **where the fix lands**, not where the symptom appears. So `5_cross.fm.deskew_then_cluster_doubling` is **cross-stage** (fix lands in §5.1; symptom in §5.3); `5_2.fm.flatbed_truck_as_ground` is **configuration / scheduler / deployment-time** (fix is elevation-band misconfiguration, not a §5.2 algorithm change); `5_3.fm.range_bias_oversegmentation` is **geometric / single-stage** (fix lands inside §5.3 via range-aware tolerances). State this rule once at the top of the index and apply it uniformly. The writer may not invent an alternative rule; if the rule produces a clearly wrong placement on a specific entry, surface that as a Phase-5 critique on the host section's `mitigation` field rather than overriding the rule in §5.10.

**Explicitly: §5.10 does not invent new failure-mode IDs.** The catalog is the binding artifact frozen at the 37 entries enumerated above. §5.10 organizes and indexes; it does not extend.

---

## 4. The mAP critique (synthesis §1.12 — binding)

Synthesis §1.12 commits to: "classical detection metrics (3D / BEV mAP) are weak proxies for planning usefulness. A wrong cluster split/merge can be catastrophic for tracking but barely move IoU." §5.10 must make this critique explicit and pedagogically grounded — and *factually correct* about what mAP does and does not score. The argument has four pieces:

1. **What mAP scores correctly.** mAP is a per-frame box-overlap statistic computed from predicted-vs-ground-truth matches at one or more IoU thresholds. The matching step **does** penalize missed detections (recall) and duplicate / spurious detections (precision); a "missing pedestrian" or "extra ghost obstacle" in a single frame is reflected in the score. Do not write the critique as if mAP "ignores object count" — that overstates and the deal-loop will catch it.
2. **What mAP under-weights or does not score at all.**
    - **Severity weighting.** A 2 cm box-edge error on a far parked car and a 30° yaw error on a leading vehicle both can leave IoU above 0.5; the planner cares about the second one and not the first. mAP weights them equally up to the threshold and uniformly above it.
    - **Track continuity and identity.** mAP is a per-frame statistic. ID switches (`5_5.fm.id_switch_under_occlusion`), track-coast-too-long (`5_5.fm.coasted_track_outlives_object`), and ghost-track-from-clutter (`5_5.fm.ghost_track_from_clutter`) leave per-frame mAP untouched but break Ch 7 fusion and Ch 8 prediction.
    - **Topology failures within an object.** `5_4.fm.yaw_flip` and `5_4.fm.l_pointing_wrong_way` are heading-only failures that often stay above the IoU threshold (because IoU compares the box footprint, not the heading axis); the planner reads a wrong heading and reacts to a phantom yaw rate.
    - **Behaviour-level correctness.** Whether the planner's *gap* between ego and a leading actor is right, whether *free-space* is honestly cleared, and whether the *system* never silently drops a frame under correlated tail load are not on the mAP axis at all.
    - **ODD coverage.** mAP on a benchmark dataset measures performance on that dataset's ODD distribution. Failure modes outside the benchmark's ODD are absent from the score and absent from the catalog unless deployment-side validation finds them.
3. **Concrete examples from the chapter (chosen so each illustrates a different gap above):** `5_3.fm.range_bias_oversegmentation` (severity-weight gap — splitting a far pedestrian still gives partial IoU credit), `5_4.fm.yaw_flip` (topology gap), `5_5.fm.id_switch_under_occlusion` (track-continuity gap), `5_cross.fm.subrate_registration_starves_under_load` (behaviour-level gap not visible per-frame at all).
4. **The missing half is scenario-based testing** — replay against curated logs with engineering-grade ground truth (free-space polygons, track continuity, gap correctness), assert behaviour, not just per-frame overlap. [[11_0_overview_EN|Ch 11 §11.3]] owns the formal scenario-based-testing methodology; §5.10 references it.

**Tone discipline:** mAP is necessary, not sufficient. Do not write the critique as a dismissal — Ch 6 still uses 3D mAP, and the reader needs to know why both views matter. Do **not** claim mAP "ignores object count," "doesn't penalize misses," or "doesn't score duplicates" — it does, via the matching step. The argument is about *what is invisible above the IoU threshold and across frames*, not about mAP being broken at the within-frame matching level.

---

## 5. ODD anchor + informal practical safety argument + Ch 11 forward-pointer

§5.10 is the chapter's "Safety & validation" section, and the section title implies more than a vocabulary doorway. The Phase-3 plan scope-in is "**Per-stage hazard analysis; ODD constraints; metric weakness; failure-mode taxonomy**" — that is an informal practical safety argument grounded in the catalog. §5.10 owes the reader that argument; what it does **not** owe — and must not attempt — is the formal Ch 11 process (HARA structure, ASIL ratings, SOTIF compliance arguments, GSN safety cases). The boundary is *informal-practical here, formal-process there*, not "vocabulary here, everything there."

### 5.1 ODD anchor

[[1_10_odd_primer_EN|Ch 1 §1.10]] introduces ODD (Operational Design Domain). §5.10 ties the catalog to ODD by noting that **most failure modes are ODD-bounded**: `5_2.fm.ramp_misclassified` binds to road-grade ODD; `5_2.fm.standing_water_sparse_returns` binds to weather ODD; `5_7.fm.stale_map_after_construction` binds to map-freshness ODD; `5_5.fm.kf_diverges_on_turn` binds to dynamic-actor ODD; etc. The synthesis is: the catalog is *a starting hazard inventory for the ODD bounds the classical LiDAR pipeline can defend*, and ODD-relaxation studies (Ch 11 §11.2) extend or shrink it.

### 5.2 Informal practical safety argument (allowed; this is the section's job)

§5.10 may make these informal claims, grounded in the catalog and the chapter's algorithm choices:

- **What classical LiDAR detection can defend inside its tuned ODD.** Given the catalog and the mitigations the host sections committed, the classical pipeline can defend a bounded set of ODD assumptions — flat or near-flat road grade, weather inside the tuned envelope, map freshness inside the freshness budget, sensor class matching the tuned profile, and actor dynamics inside the tracker's process noise. Outside those assumptions the catalog has gaps, and the gap structure is itself a safety claim.
- **What the catalog cannot defend on its own.** The catalog is necessary, not sufficient — it captures what was anticipated; SOTIF-class failures (unanticipated triggering conditions) are by construction outside the catalog. The Generic Obstacle Detection / occupancy fallback (§5.7) is the chapter's primary defence for unanticipated classes; it is a backstop, not a substitute for the formal SOTIF process Ch 11 owns.
- **Which catalog entries are safety-load-bearing vs. operational.** `5_7.fm.map_suppresses_real_actor` (real actor suppressed by ROI gating) and `5_2.fm.flatbed_truck_as_ground` (vehicle removed from residual cloud) are safety-load-bearing — failure means the planner does not see an actor that exists. `5_8.fm.qos_mismatch_drops_clouds` and `5_5.fm.id_switch_under_occlusion` are operational degradations the planner sees but interprets wrong; they are still safety-relevant but at a lower severity. The writer may use this two-tier distinction or refuse it; either way, do not flatten the catalog into "all entries are equally severe."

### 5.3 Ch 11 forward-pointer (vocabulary first introduction)

§5.10 introduces three formal terms that Ch 11 owns:
- **HARA** (Hazard Analysis and Risk Assessment) — formally defined in Ch 11 §11.2.
- **ASIL** (Automotive Safety Integrity Level) — formally defined in Ch 11 §11.8.
- **SOTIF** (Safety of the Intended Functionality, ISO 21448) — formally defined in Ch 11 §11.8.

**Discipline:** §5.10 may use these terms with the explicit phrasing "introduced here; formal definition in [[11_0_overview_EN|Ch 11]] §11.2 / §11.8." The terms may appear more than once when the informal argument legitimately needs them (e.g., naming SOTIF as the framework that handles unanticipated triggering conditions in §5.2 above), but every formal use must include the Ch-11 hand-off pattern at first mention and may be referenced with a short form ("SOTIF-class failures") afterwards. **Hard rules — do NOT do any of these inside §5.10:**
- Assign ASIL ratings to the pipeline or any stage.
- Propose a HARA structure or a fault tree.
- Make compliance claims about ISO 26262 / ISO 21448 / SOTIF.
- Construct a formal safety case (GSN structure, safety argument argumentation, residual-risk argument).

§5.10 is the chapter's safety-argument *doorway*: it commits the informal practical argument the catalog supports and points to Ch 11 for the formal process. The doorway is more than vocabulary, less than the room.

---

## 6. §5.10 does NOT commit its own catalog row

Per `ch5_chapter_plan.md` Item 5, the catalog contract binds **§§5.1–5.9** ("Each section §5.1–§5.9 must end with a failure-mode catalog entry"). §5.10 is the synthesis section that integrates and indexes the 37 entries committed by those nine sections; it does **not** add new catalog rows of its own. This was an error in an earlier draft of this brief.

The two would-be rows that earlier drafts proposed — *metric-only validation misses planning failures* and *catalog blind spots at ODD boundary* — are the substance of §4 and §5.2 of this brief. They are real and important observations, and §5.10 should make both points pedagogically; they are simply made as **prose claims with catalog references**, not as new schema-formatted rows that would inflate the catalog past 37.

**Concretely:**
- The "metric-only validation" point lives in §5.10's mAP-critique block (§4 of this brief; §10's block 4 below).
- The "catalog blind spots at ODD boundary" point lives in §5.10's informal-practical-safety block (§5.2 of this brief; §10's block 5 below).

**The catalog stays at 37 entries.** The section's organizing role is integration and indexing, not extension.

---

## 7. Terminology contract (Item 9 — must-preserve)

The writer must use these terms exactly. Drift triggers Phase-5 deal-loop revision.

- `lidar` frame (lowercase); `base_link`; `odom`; `map`; `world`. Never "vehicle frame" without parenthetical clarification.
- `PointCloud2` (the ROS2 message), not "point-cloud message."
- "**point cloud**" (two words, no hyphen unless attributive).
- "**ICP**" / "**NDT**" / "**GICP**" (uppercase); "**Hungarian**"; "**Kalman filter**"; "**IMM**"; "**JPDA**"; "**MHT**"; "**AB3DMOT**".
- "**Patchwork**" / "**Patchwork++**" — fully classical (no "hybrid" caveat); "**RANSAC**"; "**DBSCAN**"; "**Euclidean clustering**"; "**L-shape fitting**"; "**OBB**".
- "**OctoMap**" (CamelCase); "**occupancy grid**" (lowercase generic); "**free-space carving**" (hyphen); "**drivable area**" (no hyphen).
- "**Generic Obstacle Detection**" (capitalized) when meaning the safety-fallback occupancy-based classical detector.
- "**HD-map ROI gating**" (consistent dashing); "**Apollo HDMap**" (proper noun).
- The Ch-5 pipeline is `preprocess → ground → cluster → fit → track`. Arrows are `→`, never `->`.
- "**deskew**" (one word, lowercase).
- "**ego-pose**" / "**ego-state**" (hyphen, lowercase).
- "**Tracking-by-detection**" — never "track-by-detect."
- "**Object-shape fitting**" or "**shape fitting**" — never "shape estimation" except when literally citing Autoware's `autoware_shape_estimation`.
- "**ODD**" (uppercase, no expansion after first mention); "**HARA**" / "**ASIL**" / "**SOTIF**" (each with the "introduced here, formal definition in Ch 11" pattern on first use).

**Cautions:**
- Do not flatten the two-tier evidence: primary 3D bbox prediction is "universally DL-based" for robotaxi/L4; "strong evidence indicates DL" for consumer NOA. §5.10 inherits the §5.9 framing.
- Intensity is **not** a stable material classifier.
- mAP is **necessary, not sufficient** — never "deprecated," "obsolete," or "wrong." The argument is about completeness of validation, not metric replacement.

---

## 8. Voice rules (Item 6 — binding)

- **Tense:** present for what algorithms / pipelines do; past for historical lineage.
- **Register:** technical-pedagogical, not lecture-academic. Short paragraphs (3–5 sentences). Lists when enumerating failure modes; prose otherwise.
- **Code policy:** §5.10 is a synthesis section; expect zero code. If a small pseudocode block helps illustrate a validation pattern, ≤ 10 lines.
- **Callouts:** `> [!info]` for status / metadata; `> [!abstract]` for section summary; `> [!warning]` for failure modes / catalog tables; `> [!tip]` for operational guidance; `> [!note]` for "introduced here, formal definition in Ch 11."
- **Wikilinks:** `[[N_M_slug_EN|Ch N §N.M]]` for cross-references. Heavy use here — every catalog row should wikilink back to the host section.
- **No emojis**; no marketing-style adjectives.
- **Failure-mode pedagogy is mandatory** — the catalog is the section's structural center, not a closing appendix.
- **Honest assessment over enthusiasm** — the chapter has been honest throughout that primary classical detection is displaced; §5.10 inherits that tone and applies it to safety claims (no overstating what classical can defend; no understating Ch 11's role).
- **Inline-restate prerequisites** — Ch 0–Ch 4 sections are mostly `planned`. Re-state minimum prerequisite knowledge inline (1–3 sentences) before using a Ch-1 concept (ODD, evaluation methodology).

---

## 9. Prerequisite chain (Item 7)

Cross-references the writer should embed:
- [[1_6_evaluation_methodology_EN|Ch 1 §1.6]] — evaluation methodology; §5.10's mAP critique builds on the metric definitions here.
- [[1_10_odd_primer_EN|Ch 1 §1.10]] — ODD primer; §5.10 anchors the catalog against ODD bounds.
- [[1_11_hazard_analysis_intro_EN|Ch 1 §1.11]] — hazard-analysis intro; §5.10 reuses the vocabulary (HARA / ASIL / SOTIF) at first-introduction level.
- [[3_4_detection_metrics_EN|Ch 3 §3.4]] — detection metrics & failure analysis; the mAP critique continues this.
- Forward-points: [[11_0_overview_EN|Ch 11]] (Safety) for the formal hazard-analysis process; [[11_3_scenario_based_testing_EN|Ch 11 §11.3]] specifically for scenario-based testing.

---

## 10. Section structure (suggested, not binding) + length budget per block

The writer may rearrange, but should hit each block. The per-block budget below sums to ~2110 words (120 + 1400 + 250 + 280 + 200 + 60 = 2310 if every block hits its upper estimate; ~2110 with mid-range prose). That fits the relaxed 2000–2200 word band committed in §1's Section-assignment box. The catalog index dominates the budget — that is correct, because the catalog is the section's structural center; if total length exceeds 2200 words, **trim the prose blocks (3, 4, 5) by ~10–15% each before touching the index**. The 37 catalog entries are non-negotiable in count.

**Lead with the framing center** (the catalog is a chapter-wide hazard inventory; mAP is necessary not sufficient; ODD-bounded; Ch 11 owns the formal process) — readers who just finished §§5.1–5.9 already know per-section failures; what they need first is the synthesis interpretation that organizes them.

1. **Opening (≤120 words, 1 paragraph).** What §5.10 is and why it exists — the chapter-level synthesis. State the three jobs (catalog integration, mAP critique, ODD-bounded informal safety argument + Ch 11 anchor) in one sentence each. Foreshadow the Ch 11 forward-pointer without launching into HARA / ASIL / SOTIF.

2. **The chapter-wide failure-mode index — the section's structural center (~1400 words: ~100 prose + ~1300 table).** A three-column index (id with wikilink / one-line cause ≤ 15 words / one-line hazard ≤ 15 words) covering all **37 entries**, grouped under the four cause-class buckets from §3 of this brief in this fixed order: geometric/single-stage, temporal/single-stage, cross-stage, configuration/scheduler/deployment-time. Wikilink each `id` back to its host section. Open the block with one paragraph (~100 words) explaining the binding bucket-assignment rule (primary cause-class chosen by where the fix lands, not where the symptom appears) and the paraphrase-don't-copy discipline. Do **not** invent new IDs. Do **not** reproduce the full 6-field schema — that lives in the host sections; the index points there. Estimated: 37 rows × ~35 words per row (id + ≤15-word cause + ≤15-word hazard + table cell overhead) = ~1300 words for the table proper + ~100 words for the framing paragraph and bucket headers = ~1400 words.

3. **Chapter-wide patterns the index reveals (~250 words, 2–3 paragraphs).** Cross-cutting observations the per-section entries do not name individually. Pick 2–3 patterns; do not enumerate all. Suggested candidates (writer picks):
    - Configuration-time vs runtime failures both produce silent degradation; "silent" is the through-line.
    - Cross-stage failures (`5_cross.fm.*`) are under-counted because the chapter awards one ID per cross-stage symptom even when the failure spans three stages.
    - Safety-load-bearing entries cluster in §5.7 (occupancy / ROI gating) and §5.2 (ground segmentation) — the stages where "did not see an actor that exists" is the dominant failure mode.
    - ODD-relaxation typically multiplies failure modes faster than algorithm improvement reduces them.

4. **mAP as a planning-usefulness proxy: necessary, not sufficient (~280 words, 2 paragraphs).** The four-piece argument from §4 of this brief: what mAP scores correctly (matching, recall, precision); what it under-weights or misses (severity weighting, track continuity, topology, behaviour, ODD coverage); concrete examples from the catalog (`5_3.fm.range_bias_oversegmentation`, `5_4.fm.yaw_flip`, `5_5.fm.id_switch_under_occlusion`, `5_cross.fm.subrate_registration_starves_under_load`); the missing half is scenario-based testing, [[11_0_overview_EN|Ch 11 §11.3]] forward-pointer. **Tone:** necessary-not-sufficient, not "deprecated/obsolete/wrong."

5. **ODD anchor + informal practical safety argument + Ch 11 vocabulary doorway (~200 words, 2 paragraphs).** From §5 of this brief. Paragraph 1: ODD anchor + the informal "what classical LiDAR detection can defend inside its tuned ODD" claim, grounded in the catalog and the §5.7 GOD/occupancy fallback as the chapter's primary defence for unanticipated classes. Paragraph 2: the Ch-11 forward-pointer with the three formal terms (HARA / ASIL / SOTIF) introduced once each with the explicit "formal definition in Ch 11" pattern. **Hard rule:** no ASIL ratings, no HARA structure, no SOTIF compliance claims, no formal safety-case construction.

6. **Forward-point closer (≤60 words).** [[11_0_overview_EN|Ch 11]] picks up the formal hazard-analysis process and the scenario-based testing methodology; [[6_0_overview_EN|Ch 6]] inherits the catalog's failure modes for DL primary detection — most survive structurally, some shift cause-class (e.g., classical-clustering bugs become learned-feature bugs).

**Compression discipline:** if a block goes over its budget, cut prose, not catalog rows. The 37 catalog entries are non-negotiable in count; the index format (3 columns, paraphrased one-liners) is the only fit-into-budget option that preserves chapter-wide visibility. The taxonomy organization is fixed at four cause-class buckets per §3.

---

## 11. What §5.10 does NOT do

- **Does not extend the catalog with new failure-mode IDs.** The 37 inherited entries are the catalog. §5.10 indexes; it does not add rows.
- **Does not reproduce the full 6-field catalog schema.** The full schema lives in the host sections; §5.10 publishes a 3-column index (id / cause / hazard) and wikilinks back.
- **Does not assign ASIL ratings, propose a HARA structure, or claim SOTIF compliance.** The Ch-11 forward-pointer is real but bounded — informal practical safety argument is allowed; formal-process claims are not.
- **Does not introduce scenario-based testing methodology in detail.** One reference paragraph + wikilink to [[11_3_scenario_based_testing_EN|Ch 11 §11.3]]; that section owns the method.
- **Does not re-explain per-stage algorithms.** Wikilinks back to §§5.1–5.9 are the explanation; §5.10 cites the IDs and patterns.
- **Does not propose new mitigations.** The mitigations live in the catalog rows the host sections committed; §5.10 organizes, does not redesign.
- **Does not deprecate mAP.** Necessary, not sufficient; both views matter. Do not write "ignores object count" or similar overstatements — mAP penalizes misses and duplicates through matching; the gap is severity weighting, track continuity, topology, behaviour, and ODD coverage.

---

## 12. Frontmatter

```yaml
---
chapter: 5
section: 10
title: Safety & validation
language: EN
workflow_status: reviewing
tags:
  - book/section
  - book/chapter-5
  - lang/EN
---
```

Note: `workflow_status: reviewing` because Phase 5 deal-loop runs immediately after the writer returns. `complete` is set only at Phase 6 chapter AGREED.
