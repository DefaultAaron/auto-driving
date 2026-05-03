---
title: §5.1 preprocessing — extension brief
doc_type: section-extension-brief
chapter: 5
section: 1
phase: 4-extension
writer: codex-writer
status: draft
created: 2026-05-03
related:
  - "[[ch5_chapter_plan]]"
  - "[[ch5_extension_plan]]"
  - "[[ch5_5_3_extension_brief]]"
tags: [workflow, chapter-5, extension, brief, codex-writer]
---

# §5.1 preprocessing — extension brief

Sequential extension after the §5.3 pilot AGREED at commit `c323d10`. Inherits all pilot-calibrated rules.

> [!info] Section assignment
> - **Section path:** `chapter_5_classical_lidar_detection/5_1_pointcloud_preprocessing_EN.md`
> - **Writer:** **codex-writer** (round-W all-codex). §5.1 was originally codex-drafted; lightweight protected-framing list applies (see §10).
> - **Length:** **4500–6000 words** (target ~5500; trim threshold 5800; hard ceiling 6000; current 2708 → ~2.0× expansion).
> - **Anchor algorithm:** **Deskew (motion compensation).** It is the most AD-specific algorithm in §5.1 (per-point time + ego-pose interpolation is the AD-distinctive depth that the rest of the chapter assumes works), and the most pedagogically load-bearing (the bent-pole / doubled-car failure mode is referenced by §5.3, §5.4, §5.5 catalog rows). De-noising (SOR/ROR), voxel grid, accumulation, intensity get mechanics-depth-for-reading-production-code (non-anchor).
> - **Workflow gate after this section:** Phase-5 Path B deal-loop on §5.1 → AGREED commit → next sequential extension §5.2.

**Binding taxonomy:** five canonical blocks (Concept / Mechanics / Worked Example / Usage / Failure Modes). Same as §5.3.

## 1. Per-algorithm gap analysis

The current §5.1 covers six algorithmic-topic groups: deskew; de-noising / preprocessing gates (SOR + ROR + return selection + near-far clipping + height gates); intensity calibration caveats; multi-frame accumulation; voxel downsampling; and the §5.1.x representation map primer (typology, not algorithm). The §5.1.x representation map is a typology, not an algorithm, and is exempt from the five-block pattern; it stays as a tabular primer.

Per-algorithm gaps (similar to §5.3 pre-extension):
- **Deskew (anchor):** Concept ✓; Mechanics ◐ (transform-chain + interpolation present, but full implementation depth missing — quaternion slerp vs linear interp choice, time-indexed ego-pose buffer construction, rosbag-clock semantics for replay, TF2 lookup discipline); Worked Example ✗ (no concrete numerical walk-through of a single point's deskew); Usage ◐ (latency/freshness mentioned, no parameter table); Failure Modes ◐ (stale-deskew duplications mentioned, no DL displacement story — DL doesn't displace deskew because it's a precondition, but the explicit "DL stacks still need deskew" framing is missing).
- **De-noising / preprocessing gates (SOR / ROR / return selection / near-far clipping / height gates):** Concept ✓; Mechanics ◐ (SOR's mean-distance + std-dev test, ROR's neighbor count + radius test, return selection's first/strongest/last semantics, near-far clipping for sensor-housing-and-ODD bounds, height gates for sky/bridge/hood — all present at sketch level, not implementation depth). **Treat near-far clipping and height gates as explicit per-gate sub-blocks**, not lumped into "de-noising" — each has its own parameters, default values, failure modes, and downstream hazards (per round-1 codex e1-c1: production preprocessing gates with parameters and failure modes are not just prose details). Worked Example ✗; Usage ◐ (default parameters cited, tuning ladder missing); Failure Modes ◐ (rain spray catalog entry referenced, no DL displacement).
- **Intensity caveats:** Concept ✓ (intensity is unstable across sensor / range / weather / firmware); Mechanics minimal because there's no algorithm to teach — this is a discipline section. Worked Example optional; Usage = the caveat list; Failure Modes ✓ (catalog row `5_1.fm.intensity_misclassification`). Treat as mention-level rather than five-block.
- **Multi-frame accumulation:** Concept ✓; Mechanics ◐ (transform-and-append described, ego-pose accuracy + time window tradeoff present, no implementation depth); Worked Example ✗; Usage ◐; Failure Modes ◐ (ghost-obstacle prose present, catalog connection implicit, no DL displacement).
- **Voxel downsampling:** Concept ✓ (PCL VoxelGrid centroid + ApproximateVoxelGrid snap); Mechanics ◐ (leaf size = ODD decision, branched leaf sizes); Worked Example ✗; Usage ◐ (leaf size guidance present, tuning ladder light); Failure Modes ◐ (ring-adjacency loss + scan-line implications stated, no DL displacement story — voxel sizes propagate into VoxelNet/SECOND learned encoders, worth one sentence).

## 2. Per-algorithm length budget (calibrated from pilot)

- **Anchor (deskew):** Concept ~150–250 + Mechanics 700–1100 (sub: transform chain + ego-pose interpolation 250–350; quaternion slerp + linear translation 150–200; time-indexed buffer + rosbag clock 200–250; TF2 lookup discipline 150–200) + Worked Example 200–300 + Usage 200–350 + Failure Modes 200–300 = **~1450–2300**.
- **Non-anchor (de-noising-with-gating-sub-blocks, accumulation, voxel) — three algorithm-families:** ~700–950 each = **~2100–2850 combined**. Within de-noising, the SOR / ROR / return selection / near-far clipping / height gates sub-blocks share the family budget; each gets at most ~150–200 words rather than full per-algorithm five-block. Five-block coverage is enforced per *family*, not per individual gate.
- **Intensity caveats (mention-level):** ~150–250.
- **§5.1.x representation map primer:** **preserved as-is** (the table from the original §5.1 is the chapter-wide representation primer; freeze its content) ~400–500.
- **§5.1.x output contract:** preserved ~150.
- **Section framing prose:** ~400–600.
- **Failure-mode catalog block (frozen):** ~300.
- **Visual artifacts:** range-of-deskew-effect diagram + voxel-downsampling-tradeoff diagram ~200–300.

**Target total (revised per round-1 codex e1-c6):** ~5400–7100 (upper-budget arithmetic). **Aim ~5500; trim prose / non-anchor first if over 5800. Hard ceiling 6000.** Non-anchor caps: de-noising-family ≤ 950, accumulation ≤ 850, voxel ≤ 950 (each). If approaching ceiling, trim de-noising-family connective prose first; the gating sub-blocks (SOR / ROR / clipping / height) are content-load-bearing and should be compressed only by removing transition prose, not by dropping a gate.

## 3. Visual artifact discipline

- **Required: spatial visual for deskew** (load-bearing) — ASCII diagram showing sweep-direction smear before deskew and corrected geometry after, OR the "duplicated car / bent pole / curved lane" failure-mode visualization. Place inside the deskew block.
- **Recommended: voxel-downsampling tradeoff visual** — a small 2-D BEV grid showing centroid vs ApproximateVoxelGrid behavior, OR a leaf-size-vs-detail comparison.
- The §5.1.x representation map TABLE counts as the section's typology artifact (existing tabular content) but does NOT satisfy the spatial visual rule for the geometric methods.

**Note (round-1 codex e1-c4):** depth additions *adjacent to* the representation map table are allowed (e.g., a short post-table "how to read this map" paragraph or per-row cross-reference paragraph that points at where each representation gets its Worked Example / Mechanics treatment in §§5.2–5.7). The table cells themselves are verbatim-protected per §10 item 3; the surrounding prose is not.

## 4. Catalog block discipline

3 rows (`5_1.fm.rain_spray_ghosts`, `5_1.fm.deskew_failure_doubling`, `5_1.fm.intensity_misclassification`) preserved verbatim. **No row text changes inside this dispatch.** Proposed changes only via change log + manifest flag (none expected).

## 5. Forward / cross-references

- Inputs (preserve verbatim): `[[1_1_coordinate_frames_EN|Ch 1 §1.1]]`, `[[1_3_lidar_calibration_EN|Ch 1 §1.3]]`, `[[1_4_sensor_time_sync_EN|Ch 1 §1.4]]`, `[[2_1_ego_state_estimation_EN|Ch 2 §2.1]]`, `[[2_2_gnss_ins_imu_fusion_EN|Ch 2 §2.2]]`, `[[2_3_lidar_localization_EN|Ch 2 §2.3]]`, `[[2_5_map_relative_localization_EN|Ch 2 §2.5]]`.
- Outputs (preserve): `[[5_2_ground_segmentation_EN|§5.2]]` consumes the residual cloud; `[[5_3_clustering_EN|§5.3]]` and `[[5_6_registration_EN|§5.6]]` consume the five-row representation primer (raw / voxel / OctoMap / range image / BEV); `[[5_7_occupancy_freespace_map_roi_EN|§5.7]]` consumes the BEV grid + OctoMap row; `[[5_10_safety_and_validation_EN|§5.10]]` catalog contract.
- Forward to Ch 6 (add): production DL stacks **generally consume motion-compensated sweeps** — preprocessing (deskew, de-noising, voxel downsampling, ROI gating) is one of the five load-bearing-classical pieces inside DL-primary stacks per §5.9; learned 3D detectors (VoxelNet, PointPillars, CenterPoint) consume deskewed clouds rather than raw sweeps. Voxel size choice (classical leaf size) maps to learned voxel-grid resolution. Learned / joint LiDAR-IMU motion-compensation research exists, but it does not remove the production need to validate deskew, per-point timestamps, and TF freshness — even systems that learn part of the compensation still validate against ego-pose-driven deskew baselines (round-1 codex e1-c5: don't sound like learned systems can never model motion compensation; the practitioner-true claim is "production validates against deskew," not "deskew is impossible to learn"). Reference: `[[6_0_overview_EN|Ch 6]]`.

## 6. Voice rules

All chapter-plan Item 6 voice rules apply. New / strengthened: five-block, visual artifact discipline (spatial visual required for deskew), wikilink convention (intra-Ch-5 `§N.M`), code policy (C++ for shippable; Python ≤ ~10 lines for pseudocode in worked examples).

## 7. Phase-5 path

Path B (codex-drafted) — main rounds 1..N-1 + codex-collaborator final-round sanity pass. Five Path B bias axes including framing-preservation (light, for the §10 protected-framing list).

**Rule 3b two-tier rule:** no spot-check for already-present conceptual content; required for new numeric / product / paper / runtime / DL displacement claims. Manifest must list every new claim.

## 8. Frontmatter

```yaml
---
chapter: 5
section: 1
title: Point-cloud preprocessing
language: EN
workflow_status: reviewing
tags:
  - book/section
  - book/chapter-5
  - lang/EN
---
```

## 9. Process

Same shape as §5.3 pilot. Read brief + current §5.1 + plan + standard memory. Map existing prose to five-block per algorithm. Interleave new depth blocks; do not rewrite present prose. Anchor = deskew, full implementation depth in Mechanics. Add two visual artifacts. Per-algorithm Usage with numerical defaults + tuning ladder. Failure Modes blocks tying back to catalog rows + DL displacement story.

## 10. Lightweight protected-framing spans for §5.1

§5.1 was originally codex-drafted; lightweight protection applies. Preserve verbatim or with formatting-only changes:

1. **The `> [!tip]` deskew-mandatory callout** ("Treat deskew as mandatory for road-speed evaluation logs..." — line 33-34 of current §5.1). This is the section's load-bearing operational stance.

2. **The intensity-as-auxiliary-channel framing** (currently in the Intensity Caveats block — "intensity is an auxiliary channel whose distribution must be monitored per sensor family and ODD"). The chapter-wide terminology contract from chapter plan Item 9 says "Intensity is **not** a stable material classifier"; the §5.1 framing is the authoritative version.

3. **The §5.1.x representation map TABLE** — the **five-row** representation typology (raw point cloud / voxel grid / probabilistic octree (OctoMap) / range image / BEV grid) is the chapter's foundational typology (round-1 codex e1-c3 fix: the table has five rows, not four; OctoMap is its own row, not a footnote on voxel grid). Preserve **table cell content verbatim** — five rows × five columns, including methods-it-enables, sensor topology assumptions, downstream Ch-5-use cells. Minor formatting tweaks OK; no row drop, no method drop, no merging of rows. **Adjacent depth additions are allowed** outside the cells (round-1 codex e1-c4): a short post-table paragraph explaining how to read the typology, or per-row cross-reference sentences pointing at where each representation gets Mechanics / Worked Example coverage in §§5.2–5.7.

4. **The §5.1.x output contract opening sentence** (currently in §5.1: "§5.1 publishes a deskewed, de-noised, voxel-downsampled `PointCloud2` in `base_link` at sweep-end time"). The downstream branch table (the four-row consumer/input/preprocessing matrix that follows this sentence) is also part of the contract — preserve cells verbatim. Do not paraphrase the opening sentence; do not change the four consumer rows. (Round-1 codex e1-c2 fix: earlier version of this brief mis-quoted the contract sentence; corrected here.)

5. **Cross-section contract terms** (must remain exactly): `deskew` (one word, lowercase); `PointCloud2`; `point cloud` (two words, no hyphen unless attributive); `pcl::VoxelGrid`, `pcl::ApproximateVoxelGrid`; `5_1.fm.<short_slug>` ID format.

The framing-preservation Path B axis applies in light form. Main-conflict checks §10's items every round.

## 11. Return manifest

- File path written.
- New `wc -w` word count vs 4500–6000 band (target ~5500; trim threshold 5800; hard ceiling 6000).
- Per-algorithm five-block coverage confirmation (deskew anchor full-implementation; non-anchor mechanics-for-reading; intensity mention-level).
- Anchor declared (deskew) and full-implementation-depth confirmed in Mechanics.
- Visual artifacts present: deskew spatial visual + voxel-downsampling tradeoff (or alternative).
- Catalog block: untouched (default) or change-log entries listed.
- §5.1.x representation map table: untouched (preserved verbatim).
- New factual-claim inventory (per §7 two-tier Rule 3b): every new numeric / product / paper / runtime / DL displacement claim with writer's recommendation on Rule 3b spot-check.
- Any deviations from the brief and why.
