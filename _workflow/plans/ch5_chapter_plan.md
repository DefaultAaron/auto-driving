---
title: Ch 5 chapter plan + writer allocation
doc_type: chapter-plan
chapter: 5
phase: 3
status: draft
created: 2026-05-02
related:
  - "[[ch5_classical_lidar_detection_synthesis]]"
tags: [workflow, chapter-5, plan, allocation]
---

# Chapter 5 chapter plan + writer allocation

This is the Phase-3 11-item plan for **Chapter 5 — Classical LiDAR Detection**, drafted by main session for the Phase-3 deal-loop with `codex-collaborator` (`MODE: CONFLICT`). It builds on the AGREED Phase-2 synthesis at `_workflow/research/ch5_classical_lidar_detection_synthesis.md` and the lockstep-applied 11-section TOC structure.

Phase-3 deal-loop adjudicates **all 11 items below**. Once AGREED, Phase 4 (per-section drafting in batches) begins.

---

## Item 1 — Section list (file names, slugs, scope-in / scope-out, target depth, length band)

| § | Title | File slug | Scope-in (must cover) | Scope-out (do not cover) | Depth | Length |
|---|---|---|---|---|---|---|
| 5.1 | Point-cloud preprocessing | `5_1_pointcloud_preprocessing` | Motion compensation / deskew (with Ch 2 ego-pose handoff); de-noising (SOR, ROR, return selection); intensity calibration with caveats; multi-frame accumulation; voxel downsampling; **§5.1.x "Representation map" primer** (raw / voxel / range image / BEV) | Learned voxelization (Ch 6); SLAM-grade scan-to-map (Ch 2 §2.6); calibration procedure (Ch 1 §1.3) | medium-deep | 1500–2500 words (original) → **4500–6000 words (extension band, applies for round-W extension dispatch)** |
| 5.2 | Ground segmentation | `5_2_ground_segmentation` | RANSAC plane fit (entry + failure modes); scan-line / radial-bin (Himmelsbach 2010); GP-INSAC (historical); **Patchwork / Patchwork++ as the modern classical baseline (fully classical)**; grid-based heightmaps; failure-mode pedagogy (curbs / ramps / overpasses / large vehicles) | DL-based ground seg (Ch 6); semantic ground (Ch 6 fusion) | medium-deep | 1500–2500 (original) → **4500–6000 (extension)** |
| 5.3 | Clustering — Euclidean, DBSCAN, range-image | `5_3_clustering` | Euclidean clustering on residual cloud; DBSCAN; range-image connected components (Bogoslavskyi 2016); depth-jump / scan-line; range-bias failure modes | Voxel-based learned segmentation (Ch 6); semantic clustering | medium | 1000–1800 (original) → **4000–5500 (extension; pilot section)** |
| 5.4 | Object-shape fitting — L-shape, OBB, class priors | `5_4_object_shape_fitting` | L-shape fitting (Zhang 2017 search-based, RANSAC L-fit); PCA / OBB; min-area rectangle; convex hull; class-prior box dimensions; "planner-hostile boxes" failure pedagogy | Learned bbox regression (Ch 6); 3D pose graph optimization (Ch 2) | medium | 1000–1800 (original) → **4500–6000 (extension)** |
| 5.5 | Multi-object tracking — Kalman / IMM / JPDA | `5_5_classical_tracking` | Constant-velocity Kalman; CTRV; IMM; NN/GNN/JPDA/MHT association; AB3DMOT (Weng & Kitani 2020) as canonical baseline; track lifecycle (birth / confirm / coast / delete); cross-handoff to Ch 4 §4.6 (camera-side trackers) | Learned trackers (later); end-to-end tracking; behavior prediction (Ch 8) | medium-deep | 1500–2500 (original) → **5500–7000 (extension)** |
| 5.6 | Registration — ICP / NDT / GICP | `5_6_registration` | ICP point-to-point + point-to-plane (Besl & McKay 1992); NDT (Magnusson 2009); GICP (Segal 2009); convergence guarantees and local-minima failures; **the four perception roles**: deskew refinement, map subtraction, accumulation alignment, map-aided ROI consistency. Framing line: "you saw these names in Ch 2 §2.3; here is how they actually work + four perception uses." | LIO-SAM / FAST-LIO at SLAM level (Ch 2 §2.6); learned registration | medium-deep | 1500–2500 (original) → **4500–6000 (extension)** |
| 5.7 | Occupancy, free-space & map-aided ROI gating | `5_7_occupancy_freespace_map_roi` | 2D occupancy log-odds; OctoMap (Hornung 2013); free-space carving / ray casting; **Generic Obstacle Detection** as the safety fallback for unknown classes; **Apollo HDMap ROI filter**; **Autoware `compare_map_segmentation`**; failure modes (map suppresses real actors, map-freshness coupling) | HD-map building details (Ch 2 §2.7); learned occupancy (Ch 4 §4.8 mono-3D occupancy / Ch 6) | medium-deep | 1500–2500 (original) → **5500–7000 (extension)** |
| 5.8 | ROS2 integration | `5_8_ros2_integration` | `sensor_msgs/PointCloud2` schema (`x, y, z, intensity, ring, time`); TF2 (`lidar → base_link → odom/map`); lifecycle / managed nodes; composable nodes for zero-copy intra-process; rosbag replay validity; reference stacks (Autoware Universe / Core, Apollo perception, MOLA); **C++ over Python** per book deployment policy | ROS2 fundamentals (Ch 1 §1.5); message-broker tuning beyond perception | medium | 1200–2000 (original) → **3500–4500 (extension)** |
| 5.9 | Deployment & runtime constraints | `5_9_deployment_runtime` | Per-stage CPU / GPU / latency budgets (preprocess / ground / cluster / fit / track / occupancy); ROS2 timing and message synchronization; field robustness (rain, fog, low light, sensor degradation); **bounded "Nobody ships pure classical primary detection..." claim with explicit definitions**; **one paragraph** on China-vs-US LiDAR deployment priors (no recurring theme); load-bearing classical pieces in DL-primary stacks | Compiler / tooling details (Ch 1 §1.9); dataset / labeling (Ch 10) | medium | 1200–2000 (original) → **3500–4500 (extension)** |
| 5.10 | Safety & validation (template instance) | `5_10_safety_and_validation` | Per-stage hazard analysis; ODD constraints inherited from Ch 1 §1.10; metric weakness (3D / BEV mAP as poor proxy for planning usefulness); failure-mode taxonomy (cluster split/merge, ghost obstacles from rain, deskew doubling, etc.); cross-pointer to Ch 11 (Safety) | ISO-26262 / SOTIF process detail (Ch 11 §11.8); scenario-based testing depth (Ch 11 §11.3) | medium | 2000–2200 words (relaxed at Phase-4 brief deal-loop after the 37-entry catalog index workload was scoped; original band 1000–1800; see `_workflow/briefs/ch5_5_10_safety_and_validation_brief.md`) |

**Total:** 10 drafted sections (5.1–5.10); §5.0 overview is updated by main session at Phase 6 commit, not drafted by writers.

---

## Item 2 — Section dependency DAG

```
                          5.1 preprocessing
                          (representation map primer)
                         ┌────────┼────────┐
                         │        │        │
                         ▼        ▼        ▼
                       5.2      5.6     5.8
                     ground    regis-  ROS2
                       seg     tration  integration
                         │        │
                         ▼        │
                       5.3      ┌─┴─────┐
                     clustering │       │
                         │      ▼       │
                         ▼     5.7      │
                       5.4   occupancy  │
                     shape    + ROI     │
                     fitting             │
                         │               │
                         ▼               │
                       5.5               │
                     tracking            │
                         │               │
                         └───────┬───────┘
                                 │
                                 ▼
                           5.9 deployment
                                 │
                                 ▼
                           5.10 safety
```

**Edges (predecessor → successor):**
- 5.1 → 5.2, 5.6, 5.7, 5.8
- 5.2 → 5.3
- 5.3 → 5.4
- 5.4 → 5.5
- 5.6 → 5.7
- {5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7, 5.8} → 5.9 (the runtime-budget contract requires a row from each of §5.1–§5.8, so §5.9 depends on all eight)
- {5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7, 5.8, 5.9} → 5.10 (the failure-mode catalog contract requires an entry from each of §5.1–§5.9; §5.10 also depends on §5.9's deployment context)

**Aggressive parallelism via handoff snippets:** dependent sections start drafting once the predecessor's handoff snippet is stable, not when the predecessor reaches `workflow_status: complete`. This collapses the strict serial chain (5.2→5.3→5.4→5.5) into one batch.

---

## Item 3 — Parallel batch groups

The original 3-batch plan hid a serial dependency (§5.10 ← §5.9 ← §5.7). Codex Phase-3 round-1 critique forced an explicit split. Final 4-batch plan:

**Batch 1 — independent leaves** (3 sections, parallel):
- §5.1 preprocessing (codex-writer)
- §5.6 registration (cc-writer)
- §5.8 ROS2 integration (codex-writer)

**Batch 2 — main pipeline + occupancy** (5 sections, parallel; each receives the **frozen handoff contracts from Item 5** in the section brief — they do *not* wait for an in-batch predecessor's draft to land. The handoff snippets are stable terminology contracts written by main session in advance, so §5.3 / §5.4 / §5.5 can draft against the §5.2 / §5.3 / §5.4 contract while those predecessors draft alongside.) Once Batch 1 reaches `workflow_status: reviewing`, §5.7 also receives the actual §5.1 representation map and §5.6 four-perception-roles paragraph as supplemental context, but the contract is the binding artifact:
- §5.2 ground segmentation (codex-writer) — handoff contract from §5.1
- §5.3 clustering (codex-writer) — handoff contract from §5.2
- §5.4 object-shape fitting (cc-writer) — handoff contract from §5.3
- §5.5 tracking (codex-writer) — handoff contract from §5.4
- §5.7 occupancy + ROI gating (cc-writer) — handoff contract from §5.1 + §5.6 (Batch-1 drafts are also available)

**Batch 3 — deployment synthesis** (1 section, alone):
- §5.9 deployment & runtime constraints (cc-writer) — receives the **per-stage runtime budget contract** filled in by Batches 1+2 (item 5 below specifies the schema each section must commit). §5.9 cannot dispatch until §5.1–§5.8 are at least `reviewing`.

**Batch 4 — safety synthesis** (1 section, alone):
- §5.10 safety & validation (cc-writer) — receives the **failure-mode catalog contract** populated by §5.1–§5.9 (item 5 below specifies the schema each section must commit). §5.10 cannot dispatch until §5.9 is at least `reviewing`.

**Batch summary:** 4 batches; max parallelism = 5 (Batch 2). The two final batches are deliberately sequential because §5.9 synthesizes algorithm + ROS2 deployment budgets and §5.10 synthesizes chapter-wide hazards + the budgets §5.9 commits. Total drafting cycles = 4 batch dispatches + 10 per-section deal-loops in Phase 5. With Strategy C+ commits, ~10 `wip(5/5_X_*)` commits and 10 `agreed(5/5_X_*)` commits expected during Phases 4–5, plus the eventual `chapter(5):` at Phase 6 AGREED.

---

## Item 4 — Writer assignments + Rule 3a rationale

| § | Writer | Rationale (Rule 3a) |
|---|---|---|
| 5.1 | codex-writer | Well-known applied content (PCL preprocessing, deskew, voxel filter); code-heavy; standard pipeline writeup. |
| 5.2 | codex-writer | Algorithm-bounded, well-documented family (RANSAC, Himmelsbach, Patchwork). Failure-mode pedagogy is the only novel piece; main session can inject in the brief. |
| 5.3 | codex-writer | Standard PCL / DBSCAN / Bogoslavskyi material. |
| 5.4 | **cc-writer** | **Novel content** — newly-inserted first-class section; pedagogical framing of "where clusters become planner-consumable boxes" is the section's reason for existing. Rule 3a says novel/contested → cc. |
| 5.5 | codex-writer | Well-known applied content (Kalman / IMM / Hungarian / AB3DMOT); code-heavy. |
| 5.6 | **cc-writer** | **Theoretically loaded** — ICP / NDT / GICP need careful mathematical treatment + the four-perception-roles framing is novel pedagogy. Rule 3a says theoretically-loaded → cc. |
| 5.7 | **cc-writer** | **Contested combination** — section was renamed by Phase 2 to combine occupancy + ROI gating; the integration is the novel pedagogy. Rule 3a says contested → cc. |
| 5.8 | codex-writer | Well-known applied content (ROS2 boilerplate, message conventions, Autoware references); code-heavy. |
| 5.9 | **cc-writer** | **Contested framing** — the bounded "Nobody ships..." claim with three explicit definitions, plus the "load-bearing classical inside DL stacks" pedagogy. Rule 3a says contested → cc. |
| 5.10 | **cc-writer** | **High-judgment synthesis** — must integrate chapter-wide failure modes, critique mAP-as-validation, anchor ODD constraints, and forward-point to Ch 11 without overclaiming safety process. Codex Phase-3 round-1 critique correctly flagged "template-driven" as an under-estimate; flipped from codex-writer to cc-writer. |

**Original ratio (historical record):** 5 cc-writer : 5 codex-writer (after the §5.10 reassignment). The 1:1 default ratio held during the original Phase-4 drafting and Phase-5 deal-loops; all 10 sections reached `workflow_status: complete` under this allocation. **The original cc-writer rationales (novel content / theoretically loaded / contested combination / contested framing / high-judgment synthesis) are the source of the protected-framing-spans rationale used by the round-W extension override below — do not erase.**

**Rule 3b applies to** §5.1, §5.2, §5.3, §5.5, §5.8 (codex-drafted): main dispatched `gemini-researcher` for a 2–3-claim factual spot-check before each reached Phase-5 AGREED. Rule 3b applies forward to round-W codex extensions on the same sections when the extension adds substantive new factual claims.

**Rule 3c applies to** the same five codex-drafted sections: codex-bias checklist (markdown over-listing, analogy register, foundational example, depth defaults). **Under round-W: a fifth axis `framing-preservation` is added to the four for flipped former-cc sections (§5.4 / §5.6 / §5.7 / §5.9 / §5.10) — protected thesis unchanged, scoped claims unchanged, no broadened production claims, no renamed contract terms.**

### Round-W extension override (2026-05-03; user billing constraint)

User constraint "cc usage is pretty tight" (verbatim) drives a writer reallocation for the extension dispatches. Round-W codex deal-loop AGREED in 4 rounds. The override applies to the **extension** dispatches only; the original drafts above are historical record.

**Allocation:** **all-codex-writer for §§5.1–5.10 extensions.** §5.0 overview stays main-session-direct at Phase-6 close. cc-writer reserved as Rule 3d round-4+ user-approval-gated escape hatch only.

**Five binding safeguards** (all required because the cc-writer rationale above is being overridden, not erased):

1. **Protected framing spans** declared verbatim in every extension brief for §5.4 / §5.6 / §5.7 / §5.9 / §5.10. codex-writer extends *around* these spans, does not paraphrase them.
2. **§5.10 mandatory terminal consistency audit** (row-by-row old/new diff against change log; vocabulary normalization scan; duplicate-hazard scan; whole-table sanity pass) as round-1 main-conflict critique input AND final-round-sanity-pass-blocking regardless of which round Path B converges at.
3. **User-approval gate** for any cc-writer escape-hatch dispatch. Default fallback if user declines: main-direct revision proposal that codex-collaborator must AGREE to, OR another codex-writer round on heavily-narrowed brief.
4. **`framing-preservation` Path B axis** added to the four Rule 3c axes for flipped former-cc sections.
5. **§5.4 deterministic rule retired** — the "all-cc-by-default-or-split-on-isolation" rule from earlier round-2 negotiation is superseded by all-codex-with-protected-framing.

See `_workflow/plans/ch5_extension_plan.md` §3.2 for the complete safeguard description and `feedback_billing_constraint_writer_allocation.md` in memory for the rule.

---

## Item 5 — Handoff snippets (for each dependent section)

**5.2 receives from 5.1:** "§5.1 establishes four canonical representations (raw point cloud / voxel grid / range image / BEV) in §5.1.x. The preprocessed cloud is deskewed to the vehicle frame, voxel-downsampled by `pcl::VoxelGrid`, and de-noised by SOR/ROR. Intensity is treated as unreliable across sensors and is *not* used as a stable material classifier. §5.2 ground segmentation operates on this preprocessed cloud, with optional projection to range image (Himmelsbach scan-line) or radial-grid (Patchwork concentric zones)."

**5.3 receives from 5.2:** "§5.2 produces a residual non-ground cloud (ground points removed/masked). Patchwork / Patchwork++ is the recommended modern classical baseline, with RANSAC as the pedagogical entry point. §5.3 clustering operates on this residual cloud and must handle range-bias (point density falls quadratically with range) — the residual is uniformly preprocessed but not uniformly dense."

**5.4 receives from 5.3:** "§5.3 produces clusters of non-ground points (each cluster a candidate object); methods discussed: Euclidean clustering, DBSCAN, range-image connected components (Bogoslavskyi 2016). The output cluster is a list of point indices plus a cluster-bbox approximation. §5.4 fits geometric shapes (L-shape via Zhang 2017 search; PCA-OBB; min-area rectangle; convex hull) to these clusters and applies class-prior box dimensions to produce planner-consumable 3D boxes."

**5.5 receives from 5.4:** "§5.4 produces fitted boxes per frame: `(x, y, z, l, w, h, yaw, optional class)`. §5.5 tracks these across time using Kalman / CTRV / IMM filters and Hungarian / GNN / JPDA / MHT association. AB3DMOT (Weng & Kitani 2020) is the canonical baseline. The detection input is per-frame fitted boxes, not raw clusters; track output goes downstream to Ch 7 fusion and Ch 8 prediction."

**5.7 receives from 5.6 + 5.1:** "§5.6 introduces ICP / NDT / GICP and four perception roles registration plays. §5.7 uses two of those roles directly: role 3 (multi-frame accumulation alignment) and role 4 (map-aided ROI consistency). §5.1's BEV grid representation is the substrate for both occupancy log-odds and the HD-map ROI lookup table. The Apollo HDMap LUT and Autoware `compare_map_segmentation` are the production reference patterns."

**5.9 receives from 5.1–5.8 (concrete contract).** Each section §5.1–§5.8 must end with a **runtime-budget table row** with these exact fields:

| Field | Required content |
|---|---|
| `stage` | section slug, e.g. `5_2_ground_segmentation` |
| `compute` | `cpu` / `gpu` / `cpu+gpu` / `lidar-driver` |
| `frame_rate_assumption` | per-second (e.g. 10 Hz spinning, 20 Hz solid-state) |
| `point_count_assumption` | per-frame (e.g. 130k for VLP-32; 1.3M for HDL-64; 1.5M for AT128) |
| `latency_p50_ms` | typical |
| `latency_p99_ms` | tail |
| `memory_mb` | working-set |
| `cadence` | `every-frame` / `every-N-frames (N=...)` / `on-demand` — explicit so §5.9 can compare like-with-like (e.g., registration / map subtraction often run sub-rate) |
| `tf_freshness_assumption` | the maximum allowed age of `/tf` and `/tf_static` for the stage's correctness (e.g. ≤ 50 ms) |
| `assumptions_and_caveats` | sensor class (mechanical-spinning / MEMS / FMCW), single vs multi-LiDAR, anything else not captured by the dedicated fields above |

§5.9 synthesizes these rows into a chapter-level budget table. **No specific edge-GPU latency target is committed at the chapter-plan stage** — §5.9 derives the chapter-level total from the rows §5.1–§5.8 actually publish, and notes the assumptions explicitly (sensor class, frame rate, single vs. multi-LiDAR, registration cadence, etc.). The bounded "Nobody ships pure classical primary detection..." claim (synthesis §1.13) is the section's framing center; the load-bearing-classical-in-DL-stacks list is the section's takeaway. The exact edge-GPU class (Jetson Orin AGX / Orin Nano / Drive AGX / custom) remains an open user-input question per `README.md` §10.2 and is *not* hard-coded in §5.9.

**5.10 receives from 5.9 + chapter-wide (concrete contract).** Each section §5.1–§5.9 must end with a **failure-mode catalog entry** with these exact fields:

| Field | Required content |
|---|---|
| `id` | per-section identifier, e.g. `5_2.fm.curb_eaten_as_ground`. **Cross-section / emergent failures use the pattern `5_cross.fm.<short_slug>`** (e.g. `5_cross.fm.deskew_then_cluster_doubling`) — owned by §5.10, surfaced by whichever section first observes them. |
| `cause` | mechanistic explanation (1 sentence) |
| `observable_symptom` | what the system or operator sees (1 sentence) |
| `downstream_hazard` | planner / safety implication (1 sentence) |
| `mitigation` | classical / data / monitor (1 sentence) |
| `validation_test` | how Ch 11 §11.3 scenario testing would surface it (1 sentence) |

§5.10 collects all entries into a hazard-analysis table and forward-points to Ch 11 §11.2 (HARA) for the formal process. mAP is explicitly *not* the end of the validation story (synthesis §1.12 + §1.13). Where Ch 5 introduces vocabulary that Ch 11 will define formally (HARA, ASIL, SOTIF), §5.10 uses it carefully and labels each as "introduced here, formal definition in Ch 11."

---

## Item 6 — Style anchor reference

**Anchor file:** No section-level style anchor exists yet (Ch 5 is the pilot chapter; no other section file has reached `workflow_status: complete`). Phase-4 writers therefore use **`chapter_5_classical_lidar_detection/5_0_overview_EN.md`** as the closest available stylistic reference, plus the explicit voice-rule bullets below derived from CLAUDE.md and the synthesis.

**Voice-rule bullets (binding for every Phase-4 draft):**
- **Tense:** present tense for what algorithms / pipelines do; past tense only for historical lineage ("Himmelsbach proposed..." / "AB3DMOT showed...").
- **Register:** technical-pedagogical, not lecture-academic. Short paragraphs (3–5 sentences). Lists when enumerating algorithms or failure modes; prose otherwise.
- **Vocabulary:** book-canonical terminology from Item 9 below. No drift to synonyms even when adversarial review tempts it.
- **Code policy:** C++ for shippable perception; Python / `numpy` ≤ ~10 lines as compact explanatory pseudocode only. No long Python implementations. Long examples move to `_assets/code/5_M_<slug>.{cpp,py}` and embed via `![[...]]`. (The mingtai project is a traffic-light camera example for Ch 4; not relevant to Ch 5 LiDAR sections.)
- **Callouts:** `> [!info]` for status / metadata, `> [!abstract]` for section summary, `> [!warning]` for failure modes / open issues, `> [!example]` for code, `> [!tip]` for operational guidance.
- **Wikilinks:** cross-chapter references display as `[[N_M_slug_EN|Ch N §N.M]]`; intra-chapter references may display as `[[N_M_slug_EN|§N.M]]` because the chapter context is implicit (refined at Phase 6 round 1; see `_workflow/briefs/ch5_phase6_voice_pass_brief.md`). Embeds `![[...]]` for figures and externalized code.
- **No emojis** (default vault rule); no marketing-style adjectives ("revolutionary," "state-of-the-art").
- **Failure-mode pedagogy is mandatory** — every algorithm section ends with at least one failure-mode subsection / callout. mAP-only validation is explicitly insufficient.
- **Honest assessment over enthusiasm** — when a classical method has been displaced by DL for primary use, say so plainly and explain what classical role survives.
- **Inline-restate prerequisites** — Ch 0–Ch 4 sections are mostly `planned`, not `complete`. Each Ch 5 writer therefore re-states the minimum prerequisite knowledge inline, in 1–3 sentences with the corresponding `[[...]]` cross-reference, before using a Ch-1 or Ch-2 concept. Specifically: TF2 / coordinate frames (Ch 1 §1.1), `PointCloud2` schema (Ch 1 §1.3), per-point timestamps + sync (Ch 1 §1.4), ego-pose / deskew sources (Ch 2 §2.1–§2.2), localization frame conventions (Ch 2 §2.3 / §2.5), detection metric definitions (Ch 1 §1.6 / Ch 3 §3.4). This makes Ch 5 readable even before earlier chapters reach `complete`.
- **Per-algorithm depth (five-block pattern; binding for round-W extension dispatches and forward to Ch 6+):** every distinct algorithm or technique a section introduces gets five coverage blocks — **Concept** (what it computes + history + why it exists), **Mechanics** (step-by-step + key data structure / update rule; full implementation depth for the section's declared anchor algorithm, mechanics-depth-for-reading-production-code for non-anchor methods), **Worked Example** (concrete numerical or visual artifact + ≤15-line pseudocode, load-bearing — prose alone does not satisfy), **Usage** (numerical default parameters + rationale + tuning-knob → observable-symptom pairs + sensor/ODD applicability + cadence/budget), **Failure Modes** (failure scenes + DL displacement story + catalog cross-pointer). Order is fixed; headings are the writer's choice. Synthesis sections (§5.0 overview, §5.10 safety) are exempt. See `feedback_section_depth_standard.md` for the full rule.
- **Visual artifact discipline (binding):** ≥1 spatial visual artifact per section for sections teaching spatial / geometric methods (§§5.1–5.7) — ASCII diagram of a geometric relationship, embedded canvas, externalized figure, range-image sketch, or BEV cell sketch with annotations. Markdown tables and pseudocode alone do not satisfy. Wiring / runtime sections (§5.8, §5.9) may use composable-node container diagrams or per-stage budget tables. Synthesis sections (§5.0, §5.10) are exempt — index or overview is the artifact.

---

## Item 7 — Prerequisite chain (chapters 0–4 inheritance)

Inherited terminology and concepts that Ch 5 sections must reference correctly:

- **Ch 1 §1.1** — coordinate frames (`world / map / odom / base_link / lidar`); TF2 tree conventions.
- **Ch 1 §1.3** — point-cloud basics (XYZI, returns, intensity caveats); LiDAR calibration extrinsics.
- **Ch 1 §1.4** — sensor time sync; per-point timestamps in `PointCloud2`; rosbag clock.
- **Ch 1 §1.5** — ROS2 / Humble essentials (publishers, subscribers, lifecycle nodes, TF2 broadcast).
- **Ch 1 §1.6** — evaluation methodology (metric definitions, train/val/test hygiene).
- **Ch 1 §1.9** — pinned deployment target (PyTorch → ONNX/TensorRT → C++ ROS2 → Jetson-class edge GPU).
- **Ch 1 §1.10–§1.11** — ODD primer + hazard-analysis intro (vocabulary §5.10 reuses).
- **Ch 2 §2.1–§2.2** — ego-state estimation (EKF/UKF/factor graphs); ego-pose feeds into §5.1 deskew.
- **Ch 2 §2.3** — LiDAR-based localization names ICP / NDT / GICP and **forward-points to Ch 5 §5.6 for algorithmic depth.** §5.6 honors this explicitly.
- **Ch 2 §2.5** — map-relative localization; HD-map alignment frame; §5.7 ROI gating depends on this.
- **Ch 2 §2.7** — HD-map freshness & change detection; §5.7 ROI failure-mode discussion references this.
- **Ch 3 §3.1** — detection problem framing (boxes, IoU, confidence); §5.5 tracking borrows IoU semantics.
- **Ch 3 §3.4** — metrics & failure analysis; §5.10 mAP-weakness pedagogy continues this.
- **Ch 4 §4.6** — camera-side multi-object tracking (ByteTrack / OC-SORT / BoT-SORT); §5.5 cross-pointer.
- **Ch 4 §4.7–§4.8** — dense camera perception + monocular/multi-cam 3D; §5.7 occupancy contrasts the LiDAR vs. camera-only stories.

---

## Item 8 — Canonical TOC slice (±2 chapters)

```
Ch 3  Object detection fundamentals + YOLO conceptual lineage  (theory)
Ch 4  Comprehensive camera perception systems for AD           (applied)
Ch 5  Classical LiDAR detection                                ← THIS CHAPTER
Ch 6  Deep-learning LiDAR detection
Ch 7  Camera + LiDAR sensor fusion (perception "Goal 1")
```

Ch 5's pedagogical role: bridge from camera perception (Ch 4) to LiDAR DL (Ch 6) by establishing the classical LiDAR baseline, including the production-stack pieces that survive into DL-primary stacks (preprocessing, ground seg, tracking, occupancy, ROI gating). Without Ch 5, the reader has no baseline to evaluate Ch 6 against; without Ch 7, Ch 5's tracks-and-occupancy outputs go nowhere — Ch 7 is where they meet camera detections.

---

## Item 9 — Must-preserve terminology list

The following terms are used **exactly** as written, no synonyms, no casing drift. Drafts that drift trigger Phase 5 deal-loop revision.

**Sensor + frame vocabulary (from Ch 1):**
- `lidar` frame (lowercase); `base_link`; `odom`; `map`; `world`. Never "vehicle frame" without parenthetical clarification.
- `PointCloud2` (the ROS2 message), not "point-cloud message" or "pcl message."
- "**point cloud**" (two words, no hyphen unless attributive: "point-cloud preprocessing").

**Classical algorithm names:**
- "**RANSAC**" (uppercase); "**Patchwork**" / "**Patchwork++**" (capitalized); "**Himmelsbach**" (eponym); "**Bogoslavskyi**" (eponym).
- "**Euclidean clustering**" (capital E); "**DBSCAN**" (uppercase, no hyphen).
- "**L-shape fitting**" (hyphen, lowercase otherwise); "**oriented bounding box**" or "**OBB**" (use OBB on second mention); "**convex hull**"; "**min-area rectangle**".
- "**Kalman filter**" / "**IMM**" / "**JPDA**" / "**MHT**" / "**Hungarian**" (named-method capitalization); "**AB3DMOT**" (uppercase).
- "**ICP**" / "**NDT**" / "**GICP**" (uppercase, no expansion after first mention).
- "**OctoMap**" (CamelCase); "**occupancy grid**" (lowercase generic).
- "**HD-map ROI gating**" (consistent dashing); "**Apollo HDMap**" (proper noun; HDMap is Apollo's term).

**Pipeline vocabulary (book-canonical):**
- The Ch-5 pipeline is `preprocess → ground → cluster → fit → track`. The arrows are `→`, never `->`.
- "**Object-shape fitting**" or "**shape fitting**"; never "shape estimation" (Autoware's own term — used only when literally citing Autoware's `autoware_shape_estimation`).
- "**Tracking-by-detection**"; never "track-by-detect."
- "**Generic Obstacle Detection**" (capitalized) when meaning the safety-fallback occupancy-based classical detector for unknown classes.
- "**Free-space carving**" (hyphen); "**drivable area**" (no hyphen).

**Cross-chapter:**
- "**ego-state**" (hyphen, lowercase) — Ch 2 owns this; never "vehicle state."
- "**ego-pose**" (hyphen, lowercase) — same.
- "**deskew**" (one word, lowercase) — never "de-skew" or "motion compensation" alone (deskew is the action; motion compensation is the broader concept).

**Cautions:**
- Intensity is **not** a stable material classifier — phrasing must reflect this (§5.1).
- Patchwork / Patchwork++ are **fully classical** — no "hybrid" caveat.
- Primary 3D bbox prediction in production stacks is "universally DL-based" for robotaxi/L4; "strong evidence indicates DL" for consumer NOA. Don't flatten the distinction.

---

## Item 10 — Reader knowledge assumptions at Ch 5 entry

**Pilot-chapter caveat:** Ch 0–Ch 4 are mostly `planned` in the current vault, not `complete`. The intended-end-state assumptions below describe what a Ch 5 reader is expected to know **once Ch 0–Ch 4 are themselves complete**. For the pilot drafting now, each section therefore inline-restates its minimum prerequisites (see Item 6 voice-rule "Inline-restate prerequisites").

In the intended end state, a reader entering Ch 5 has finished Ch 0–Ch 4 and:

- Can read coordinate-frame transforms and TF2 trees fluently (Ch 1 §1.1).
- Understands camera intrinsics / extrinsics and how a LiDAR-camera extrinsic is calibrated and validated (Ch 1 §1.2–§1.3).
- Knows what a `PointCloud2` looks like at the message level and what `header.stamp` / `frame_id` / per-point `time` mean (Ch 1 §1.3–§1.4).
- Has done a basic ROS2 / Humble pub-sub example end-to-end (Ch 1 §1.5).
- Can compute and interpret detection mAP, BEV-mAP, AP@IoU=0.5/0.7, and read confusion matrices (Ch 1 §1.6, Ch 3 §3.4, Ch 4 §4.6).
- Has internalized the pinned deployment target (PyTorch → ONNX/TensorRT → C++ ROS2 → Jetson) and can reason about latency budgets in milliseconds (Ch 1 §1.9).
- Has met ICP / NDT / GICP **by name** in Ch 2 §2.3 but does not yet know how they work — Ch 5 §5.6 owes the algorithmic depth.
- Has met camera-side trackers (ByteTrack / OC-SORT / BoT-SORT) in Ch 4 §4.6.
- Has seen the YOLO conceptual lineage and DETR/RT-DETR families (Ch 4 §§4.1–4.4) so the chapter can contrast classical bbox heuristics with learned bbox regression without re-explaining the latter.

A reader entering Ch 5 has **not** yet seen:
- Learned 3D point-cloud encoders (PointNet / VoxelNet / PointPillars / SECOND / CenterPoint) — Ch 6.
- Camera+LiDAR fusion designs (BEVFormer / BEVFusion / TransFusion) — Ch 7.
- Behavior prediction or trajectory planning — Ch 8 / Ch 9.
- Data-engine / labeling / MLOps — Ch 10.
- Formal safety-case process (HARA, ISO 26262, SOTIF) — Ch 11. §5.10 introduces vocabulary; Ch 11 owns process.

---

## Item 11 — Downstream commitments (what later chapters will inherit from Ch 5)

**Ch 6 (DL LiDAR detection)** inherits:
- The classical pipeline `preprocess → ground → cluster → fit → track` as the baseline DL displaces.
- The four representations (raw / voxel / range image / BEV) and which DL families consume which (PointNet → raw; VoxelNet/SECOND → voxel; RangeNet → range image; PointPillars/CenterPoint → BEV).
- Preprocessing and tracking remain classical in DL-primary production; Ch 6 does not re-teach them.
- mAP-as-weak-proxy from §5.10 — Ch 6's evaluation section continues the critique.

**Ch 7 (camera + LiDAR fusion)** inherits:
- Ch 5 tracks `(x, y, z, l, w, h, yaw, vel, optional class)` as one of the two fusion inputs.
- The L-shape-fitting / OBB convention as the LiDAR-side bbox representation.
- The occupancy + ROI gating substrate for fusion-side gating.

**Ch 8 (classical planning / prediction / control)** inherits:
- Track output (per-actor trajectory + uncertainty) as the prediction input.
- Drivable-area / free-space (§5.7) as the planner's collision-check substrate.

**Ch 9 (DL planning / prediction / control)** inherits:
- The same track and free-space outputs; only the prediction / planning model is learned.

**Ch 10 (data engine + MLOps)** inherits:
- The classical-pipeline failure-mode catalog (§5.10) as input to log-mining (§10.2) and active-learning (§10.4) targeting.

**Ch 11 (safety, validation, operational discipline)** inherits:
- The ODD-bounded "where pure-classical still ships" catalog from §5.9.
- The hazard-analysis vocabulary §5.10 introduces.

**Ch 12 (end-to-end AD)** inherits (or contrasts):
- Ch 5's modular pipeline is the explicit anti-pattern E2E "displaces" — Ch 12 §12.1 must define E2E precisely against this baseline.

---

---
status: agreed
agreed_on: 2026-05-02
---

## Phase 3 status

- 11 items drafted by main session.
- Codex CONFLICT round 1 raised 6 critiques (Batch 3 hidden serialization / §5.9 ungrounded runtime target / §5.10 misassigned to codex / mingtai path artifact / weak synthesis-handoff schema / over-optimistic prerequisite model). Round 2 raised 2 follow-ups (DAG edge list inconsistency / Batch 2 wording confused contracts vs drafts) plus 2 nice-to-have schema additions.
- All applied across 3 rounds. **Round 3 AGREED.**
- AGREED gate triggers Phase 4 Batch 1 dispatch (§5.1 codex, §5.6 cc, §5.8 codex) with full-repo `git status --porcelain` clean precondition.
