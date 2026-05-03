---
title: Ch 5 Phase-6 voice pass — cc-writer brief
doc_type: revision-brief
chapter: 5
phase: 6
writer: cc-writer
status: draft
created: 2026-05-03
related:
  - "[[ch5_chapter_plan]]"
tags: [workflow, chapter-5, phase-6, voice-pass, cc-writer]
---

# Ch 5 Phase-6 voice pass — three surface fixes

Phase-6 chapter voice pass. Three surface defects identified by codex-collaborator and AGREED with main session. **Three files in scope; do not touch any other section.** All fixes are surface harmonization — no structural rewrites, no new arguments, no new claims.

The two terminology fixes — `GOD` → `Generic Obstacle Detection` (§5.7) and `freespace` → `free-space` (§5.2) — were already applied directly by main session as `main-direct: writer-overhead` and are not in this brief.

---

## p6-c4 — §5.7 opening paragraph too long, self-defending

**File:** `chapter_5_classical_lidar_detection/5_7_occupancy_freespace_map_roi_EN.md`

**Current state (line 15):** One single mega-paragraph runs from "This section unifies two classical machineries..." through "Teaching one half without the other obscures the safety story." The defect: it reads as the section *justifying its own existence* rather than as the technical-pedagogical opener the rest of the chapter uses. The phrasing "deliberate pedagogical choice" and "earns its place when we get to the failure-mode catalog" is meta-tone, not content.

**Fix:** Split into 2–3 shorter paragraphs (3–5 sentences each per Item 6 voice rules) and remove the meta-justifying phrases. The substantive content — what the section covers (occupancy + map-aided gating + their coupling) and the load-bearing-classical claim — must stay. The pedagogical-justification framing must go.

**Acceptable rewrite (illustrative, not binding — preserve all the technical content; cut only the meta-tone):**

Paragraph 1: "This section unifies two classical machineries that Ch 5 has been pointing at since [[5_1_pointcloud_preprocessing_EN|§5.1]]: probabilistic **occupancy grids** (with their 3-D extension **OctoMap**, free-space ray carving, and the Generic Obstacle Detection fallback) and **map-aided filtering / gating** (Apollo's HDMap polygon ROI lookup table together with Autoware's `compare_map_segmentation`)."

Paragraph 2: Why they go together — "Both consume the BEV grid substrate from §5.1; both depend on registration roles from [[5_6_registration_EN|§5.6]] (Role 2 for `compare_map_segmentation`, Role 4 for HDMap ROI gating, Role 3 when occupancy is built from accumulated sweeps); and both are the load-bearing classical pieces that survive inside DL-primary stacks."

Paragraph 3: The coupling that the failure modes will surface — "The failure modes are stories about how the two halves couple: a stale HD map suppresses a real actor that the class-agnostic occupancy fallback would have caught; localization drift offsets ROI cells relative to the live cloud and the occupancy update writes evidence into the wrong row of the grid."

The exact prose is the writer's choice; the constraint is **no meta-tone, 2–3 paragraphs of 3–5 sentences each, all original technical content preserved**.

---

## p6-c5 — §5.5 GNN/Hungarian paragraph too dense

**File:** `chapter_5_classical_lidar_detection/5_5_classical_tracking_EN.md`

**Current state (line 138):** One paragraph covers cost matrix construction, gating tests, ineligible-pair encoding, two implementation patterns (constrained vs sentinel-cost), pattern-(b) post-filter discipline, gating-vs-cost-weighting distinction, Mahalanobis vs fixed-distance reasoning, square-matrix padding, dummy unmatched cost, complexity, and diagnostics. That is 9–10 distinct concepts in one block, far denser than the rest of the §5.5 prose.

**Fix:** Split into 2–3 shorter paragraphs OR restructure into one short opening paragraph + a compact bullet list. **All the technical content must survive** — this is a pacing fix, not a content cut. The reader should be able to skim the algorithm structure on first pass and dive into the implementation details (sentinel costs, dummy padding) on second pass.

**Acceptable rewrite (illustrative):**

Paragraph 1 (intro + cost matrix): "Global Nearest Neighbor (GNN) solves one assignment for the whole frame. In production classical trackers, GNN means a cost matrix plus the Hungarian algorithm. The cost matrix has one row per existing track and one column per current-frame detection; cell `C[i, j]` is the assignment cost (Mahalanobis distance from the track's predicted measurement mean to detection `j`, or `1 − BEV_IoU(track_i, det_j)`, or a weighted sum)."

Paragraph 2 (gating + eligibility encoding): "Pairs that fail a **gating test** — a Mahalanobis distance threshold derived from the predicted measurement covariance, with a class / dimension consistency check stacked on top — are **ineligible** and the implementation must encode them so the optimizer cannot select them. Two patterns work: (a) restructure as a constrained problem and exclude gated-out pairs from the cost matrix entirely; or (b) fill gated-out cells with a sentinel cost strictly larger than any unmatched-dummy cost, and discard sentinel-matched pairs as 'unmatched' in post-processing. Pattern (b) is common because it keeps the matrix rectangular for vanilla Hungarian, but it relies on the post-filter — the sentinel value alone is not a guarantee."

Paragraph 3 (gating vs cost + Mahalanobis rationale + padding + complexity): "Gating decides which pairs are *eligible*; cost decides which *eligible* pair is preferred. Mahalanobis gating beats fixed-distance gating because the predicted measurement covariance grows during coast, so the gate widens honestly in proportion to track uncertainty. Hungarian requires a square cost matrix; rectangular cases are handled by padding with **dummy rows or columns at a fixed unmatched cost** — the cost the assignment is willing to pay to leave a track or detection unmatched. The unmatched cost must be strictly *less than* any gated-out sentinel so the optimizer prefers leaving things unmatched over forcing an infeasible match. The output is a one-to-one assignment plus unmatched tracks (which enter coast) and unmatched detections (which seed births). Implementation is `O(n³)` worst-case in `n = max(#tracks, #detections)` — fast enough for dozens of objects, deterministic, and easy to diagnose by inspecting the gated cost matrix."

Three short paragraphs is preferred over a bullet list because the §5.5 surrounding prose is paragraph-form. Bullet-list restructuring is also acceptable if the writer judges it clearer.

---

## p6-c6 — §5.10 internal consistency: row count + "five things / four entries"

**File:** `chapter_5_classical_lidar_detection/5_10_safety_and_validation_EN.md`

### p6-c6a (line 15) — "row" should be plural

**Current:** "Sections 5.1 through 5.9 each closed with a per-section failure-mode catalog row."

**Fix:** Sections close with **catalog blocks** (multiple rows per section: §5.2 has 5 rows, §5.4 has 6, §5.5 has 4, etc.). Change to "Sections 5.1 through 5.9 each closed with a per-section failure-mode catalog block" or "Sections 5.1 through 5.9 each closed with per-section failure-mode catalog rows" (writer chooses; the pluralization is the fix).

### p6-c6b (lines 92 + 94) — "five things" vs "These four entries"

**Current:** Line 92 says "mAP under-weights or does not score five things the planner cares about" and enumerates **five** gap-types: severity weighting, track continuity, topology, behaviour, ODD coverage. Line 94 says "These four entries each illustrate a different gap: severity, topology, track continuity, behaviour" — four catalog example IDs (`5_3.fm.range_bias_oversegmentation`, `5_4.fm.yaw_flip`, `5_5.fm.id_switch_under_occlusion`, `5_cross.fm.subrate_registration_starves_under_load`) illustrate four of the five gap-types; ODD coverage is the fifth gap-type and is not given a catalog example.

The internal logic is **correct** (5 gap-types; 4 catalog examples illustrate 4 of them; ODD coverage is the fifth and is addressed by scenario-based testing rather than a single catalog example). The writing makes it look inconsistent because the reader has to infer the 5-vs-4 relationship.

**Fix:** Rewrite line 94 to make the relationship explicit. Acceptable rewrite (illustrative): "Four of the five gaps each have a catalog illustration above: `5_3.fm.range_bias_oversegmentation` (severity), `5_4.fm.yaw_flip` (topology), `5_5.fm.id_switch_under_occlusion` (track continuity), and `5_cross.fm.subrate_registration_starves_under_load` (behaviour). The fifth — ODD coverage — is by construction outside any single catalog example and is the part scenario-based testing must cover."

---

## Hard rules (still binding)

- **No structural rewrites.** Phase 6 is voice-only. If a defect requires a Phase-5 critique (rewriting an argument, changing a catalog row, re-arguing a Phase-3 plan choice), surface it as out-of-scope and stop — do not silently apply.
- **Frontmatter:** all three section files keep `workflow_status: reviewing`. Phase 6 AGREED is the gate to flip them to `complete`, and that flip is done by main session in the chapter-close commit, not by the writer.
- **Word counts:** §5.5, §5.7, §5.10 should not change materially. The §5.10 fixes are word-level (singular→plural; rewriting one sentence). §5.7 reorganizes one paragraph into two-or-three; the total word count should land within ±50 words of the pre-fix count. §5.5 paragraph split is structural-only; word count change should be ≤ ±30 words.
- **No emojis. No marketing-style adjectives.** Voice rules from Phase 3 remain.
- **Terminology contract** (Item 9) — verify nothing drifts during the rewrites. `lidar` lowercase, `PointCloud2`, "point cloud" two words, ICP/NDT/GICP, OctoMap CamelCase, "free-space" hyphenated, "drivable area" no hyphen, "Generic Obstacle Detection" capitalized, "Tracking-by-detection" hyphenated, etc.
- **Wikilink convention is now**: intra-Ch-5 cross-references display as `§N.M`; cross-chapter references display as `Ch N §N.M`. (This is the p6-c3 clarification main session contested and codex AGREED.) Don't normalize the existing wikilinks during this revision.

## Return

Manifest:
- Files written.
- Brief description of each change applied with before/after for the key sentences.
- Word-count delta per file (`wc -w` if available; estimate otherwise).
- Confirmation no out-of-scope edits made.
