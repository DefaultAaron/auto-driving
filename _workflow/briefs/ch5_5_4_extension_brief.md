---
title: §5.4 object-shape fitting — extension brief
doc_type: section-extension-brief
chapter: 5
section: 4
phase: 4-extension
writer: codex-writer
status: draft
created: 2026-05-03
related:
  - "[[ch5_chapter_plan]]"
  - "[[ch5_extension_plan]]"
tags: [workflow, chapter-5, extension, brief, codex-writer]
---

# §5.4 object-shape fitting — extension brief

§5.4 was originally **cc-drafted** (chapter plan Item 4 rationale: novel-section framing — "where clusters become planner-consumable boxes"). Under round-W reallocation, §5.4 is now codex-writer with **FULL Safeguard-1 protected-framing-spans treatment** (not lightweight as for §5.3 / §5.1 / §5.2). The §5.4 deterministic rule from earlier rounds was retired; current rule per `feedback_billing_constraint_writer_allocation.md`: §5.4 is all-codex-writer with protected framing spans + locked side-channel contract terms.

> [!info] Section assignment
> - **Section path:** `chapter_5_classical_lidar_detection/5_4_object_shape_fitting_EN.md`
> - **Writer:** **codex-writer** (round-W all-codex). §5.4 was originally cc-drafted; **FULL Safeguard-1** treatment applies (not lightweight). The framing-preservation Path B axis is **strictly binding** (not light).
> - **Length:** **4500–6000 words** (target ~5500, trim 5800, ceiling 6000; current 3368 → ~1.6× expansion).
> - **Anchor algorithm:** **L-shape fitting (Zhang 2017).** It is the section's pedagogical center — the canonical method that addresses the L-shape geometry that LiDAR sweeps actually capture (round-1 codex e1-c3 fix: don't claim "only method"; RANSAC L-fit also addresses L geometry but is mention-level). PCA / OBB / min-area-rectangle / convex hull are non-anchor with mechanics-depth-for-reading-production-code. RANSAC L-fit is mention-level inside the L-shape block (already in a `> [!tip]` callout in the original).
> - **Workflow gate after this section:** Phase-5 Path B → AGREED → §5.5.

**Binding taxonomy:** five canonical blocks (Concept / Mechanics / Worked Example / Usage / Failure Modes).

## 0. Round-1 codex e1-c1 — Zhang 2017 citation factual correction

The current §5.4 cites "Zhang, Wang, Wei & Wang (IV 2017)" for the L-shape paper. Codex round-1 e1-c1 flagged this as factually wrong. Correct authorship per codex: **Xiao Zhang, Wenda Xu, Chiyu Dong, John M. Dolan** ("Efficient L-Shape Fitting for Vehicle Detection Using Laser Scanners," CMU Robotics Institute, IEEE IV 2017). gemini-researcher Rule 3b spot-check dispatched in parallel to verify; if confirmed, codex-writer must update the citation throughout §5.4 (anchor algorithm intro + any other reference). The chapter plan and `feedback_section_depth_standard.md` references that may have inherited the wrong citation should also be updated (lockstep) — but those are out-of-scope for §5.4 dispatch; flag in manifest if encountered.

This is a factual correction, not a framing change. Apply unconditionally once gemini confirms; if gemini refutes, defer to writer's research.

## 1. Per-algorithm gap analysis

Current §5.4 has 5 algorithm sections (L-shape, PCA/OBB, min-area rectangle, convex hull, class-prior box dimensions) + Output contract + Failure-mode pedagogy. Anchor (L-shape) has good Concept + Mechanics depth; non-anchors are mention-level.

- **L-shape fitting (anchor):** Concept ✓; Mechanics ◐ (Zhang search-based scoring with three criteria — area / closeness / variance — described, search resolution mentioned, complexity stated; full implementation depth missing — projection-onto-rotated-axes math, the closeness-objective formula, coarse-to-fine search procedure, the corner-strength score that feeds `yaw_confidence`); Worked Example ✗ (no concrete numerical walk-through of one search step); Usage ◐ (Autoware reference, search resolution mentioned, no parameter ladder); Failure Modes ✓ (catalog rows present); DL displacement story present at section opening (PointPillars, SECOND, CenterPoint); strong, but per-algorithm DL framing missing in non-anchor blocks.
- **PCA / OBB (non-anchor):** Concept ✓; Mechanics ◐ (eigendecomposition mentioned); Worked Example ✗; Usage ◐; Failure Modes ◐ (yaw-flip catalog row referenced).
- **Min-area rectangle (non-anchor):** Concept ✓; Mechanics ◐ (rotating calipers mentioned); Worked Example ✗; Usage ◐; Failure Modes ◐.
- **Convex hull (non-anchor):** Concept ✓ (optional footprint payload); Mechanics ◐ (Graham scan / Andrew's monotone chain implicit); Worked Example ✗; Usage ◐; Failure Modes ◐.
- **Class-prior box dimensions (non-anchor):** Concept ✓; Mechanics ◐ (gross-dimension lookup vs tracker-history); Worked Example ✗; Usage ◐; Failure Modes ◐ (wrong-prior-inflated-box catalog row).

## 2. Per-algorithm length budget

- **Anchor (L-shape):** Concept ~150–250 + Mechanics 700–1100 (sub-budgets: rotated-axis projection 150–200; closeness/area/variance objective formulas + comparison 250–350; coarse-to-fine search procedure 150–200; corner-strength score → `yaw_confidence` 150–250) + Worked Example 200–300 + Usage 200–350 + Failure Modes 200–300 = **~1450–2300**.
- **Non-anchor (PCA/OBB, min-area rectangle, convex hull, class-prior) — four algorithms:** ~600–900 each = **~2400–3600 combined**. Class-prior is shorter (mostly Mechanics + Usage; concrete back-fill rule).
- **Section framing prose** (Why-this-section + prerequisites + closer): ~500–700.
- **Output contract + side-channel metadata** (PROTECTED VERBATIM): preserved ~700.
- **Failure-mode catalog block (frozen):** ~600.
- **Visual artifact:** L-shape geometry diagram + maybe min-area-rectangle rotating-calipers diagram ~200–300.

**Target total (round-1 codex e1-c6 cut-line):** ~5450–7800 is upper-budget arithmetic; **aim ~5500, trim threshold 5800, hard ceiling 6000.** Cut order if over 5800: (1) trim non-anchor connective prose (PCA/OBB / min-area / convex-hull / class-prior intro and closing sentences); (2) compress non-anchor Worked Examples (one example per non-anchor instead of multiple); (3) trim L-shape Mechanics sub-block ordering prose (the math + Worked Example are protected). **Never trim:** (a) protected-framing-spans items 1-8 of §9; (b) catalog block; (c) L-shape geometry visual; (d) the binding tuple + side-channel metadata contract; (e) per-algorithm Failure-Modes catalog cross-references.

## 3. Visual artifact discipline

- **Required: L-shape geometry visual** (load-bearing) — ASCII diagram showing a vehicle's two-face L pattern from a typical observation pose; the candidate yaw search; how the closeness objective scores a good vs bad yaw. Place inside L-shape Mechanics.
- **Recommended: rotating-calipers / convex-hull visual** — small 6–8 point hull with the rotating-caliper iteration, illustrating how min-area rectangle finds the optimum on a polygon.

## 4. Catalog block discipline

6 rows preserved verbatim. **No row text changes inside this dispatch.** Proposed changes via change log + manifest flag (none expected — these rows are referenced by §5.10 paraphrase).

## 5. Forward / cross-references

- Inputs (preserve verbatim): `[[5_3_clustering_EN|§5.3]]` cluster contract; `[[5_2_ground_segmentation_EN|§5.2]]` non-ground frame; §5.1 BEV / `base_link` frame.
- Outputs (preserve verbatim): `[[5_5_classical_tracking_EN|§5.5]]` consumes the binding tuple `(x, y, z, l, w, h, yaw, optional class)` + side-channel metadata; Ch 7 fusion + Ch 8 prediction also consume the tuple.
- Forward to Ch 6 (already present): "Classical shape fitting has been largely displaced in production primary-detection paths by learned 3D box regressors (PointPillars, SECOND, CenterPoint)" — this framing is correct and preserved verbatim per Safeguard 1 below.
- DL displacement per non-anchor algorithm (extension adds): each non-anchor's Failure Modes block notes that learned regressors handle the same case differently (e.g., learned models implicitly absorb the partial-view problem via training-data variance rather than explicit `extent_source` flagging). Don't broaden the production claims.

## 6. Voice rules

All chapter-plan Item 6 voice rules apply. Five-block, visual artifact discipline, intra-Ch-5 wikilink as `§N.M`. Object-shape fitting / shape fitting (never "shape estimation" except citing Autoware's `autoware_shape_estimation`).

## 7. Phase-5 path

Path B (codex-drafted) — main rounds 1..N-1 + codex-collaborator final-round sanity pass. **Five Path B bias axes including framing-preservation BINDING (not light) for §5.4.** Per §5.10's framing-preservation rule: protected thesis unchanged; scoped claims unchanged; no broadened production claims; no renamed contract terms.

**Rule 3b two-tier:** spot-check required for new numeric defaults / paper-specific thresholds / runtime claims / DL displacement claims. Manifest must list every new claim.

## 8. Frontmatter

```yaml
---
chapter: 5
section: 4
title: Object-shape fitting — L-shape, OBB, class priors
language: EN
workflow_status: reviewing
tags:
  - book/section
  - book/chapter-5
  - lang/EN
---
```

## 9. FULL Safeguard-1 protected-framing spans for §5.4

§5.4 was originally cc-drafted because the framing IS the section's reason to exist. Full Safeguard-1 treatment: codex-writer extends *around* these spans, **must not paraphrase or restate them**.

1. **The "Why this section exists" thesis paragraph** (currently lines 15-19 — "A cluster is not yet an object... binding tuple `(x, y, z, l, w, h, yaw, optional class)`... cluster quality and box quality are not the same metric..."). **Verbatim-protected** — do not paraphrase. The "planner-consumable box" thesis is the section's reason to exist; the chapter's downstream sections (§5.5 / Ch 7 / Ch 8) reference this contract directly. Local elaboration adjacent to (not within) this paragraph is allowed.

2. **The DL displacement claim** ("Classical shape fitting has been largely displaced in production primary-detection paths by learned 3D box regressors (PointPillars, SECOND, CenterPoint — see [[6_3_pointpillars_EN|Ch 6 §6.3]] and Ch 6); classical fits survive as a generic-obstacle fallback, a safety-redundant secondary path, and the box layer behind occupancy-derived clusters."). **Content-protected, not verbatim-locked** (round-1 codex e1-c2 fix; the §5.2 narrowing precedent established that broad production claims should be evidence-calibrated). The framing aligns with §5.9 + §5.10 + §5.2 narrowed-DL-displacement rules. **Allowed:** rephrasing for evidence-calibrated narrowing (e.g., "largely displaced" → "displaced in many production stacks; some keep classical as one of several integration patterns" if the evidence base supports the narrowing). **Forbidden:** broadening ("completely displaced" / "universally displaced"); dropping any of the three survival roles; adding new survival claims without evidence; replacing the named DL family list (PointPillars / SECOND / CenterPoint) with PointNet-class research families (per §5.3 round-W e1-c5 fix). Three-survival-roles list (generic-obstacle fallback / safety-redundant secondary path / box layer behind occupancy-derived clusters) is **content-protected** — no role drop, no addition, but local elaboration adjacent to a role is allowed.

3. **The binding tuple `(x, y, z, l, w, h, yaw, optional class)` and its semantics block** (currently lines 70-83). **Verbatim-protected.** The tuple is the binding handoff to §5.5 / Ch 7 / Ch 8 — every downstream section reads exactly these eight fields. Frame, (x,y,z), (l,w,h), yaw, and optional-class semantics are all part of the binding contract.

4. **The side-channel metadata contract** (currently lines 84-91 — `extent_source`, `class_prior_source`, `yaw_confidence`, `corner_visibility`). **Verbatim-protected** including the corner-visibility three-value definition (`one_corner` canonical L-shape; `two_corners` broadside / near-full-side; `no_corner` single visible face). These contract terms are referenced by §5.5's deal-loop and the §5.4 catalog rows. **Do not rename, do not add fields, do not change enum values** — these are §5.5 coordination handles. (Round-1 codex e1-c5 acknowledged the enum is brittle compared to a fully-general taxonomy: missing values like `unknown / unset / hull_derived / regressed` are real-world possibilities, but adding them now requires §5.5 coordination beyond §5.4's scope. The §5.5 robustness contract — "§5.5 must function correctly when these fields are absent" — is the operational escape hatch for that brittleness; treat absence-as-unknown rather than expanding the enum.) The brief's specification of `yaw_confidence ∈ [0, 1]` is **a contract, not an arbitrary scalar** (round-1 codex e1-c4): the extension's Mechanics block must commit a **stable definition** of how the 0-1 scale is computed locally for §5.4's chosen implementation, so §5.5 has something it can trust. The choice of *which signals* to combine (L-score margin, two-arm support, corner angle quality, point density, PCA eigenvalue ratio, etc.) is the writer's design call; the brief does **not** mandate a specific formula because PCA-eigenvalue-ratio + corner-strength is not necessarily the right ingredient for every implementation (round-2 codex acknowledged). What is mandated: the writer commits to a mapping (whichever it is), states it explicitly, and shows how the value falls toward 0 in single-face / no-corner / sparse-cluster cases. §5.5 reads the value as an opaque 0-1 scalar with documented monotonicity (high = trustworthy, low = use tracker prior).

The enum value list given for `extent_source` / `class_prior_source` / `corner_visibility` is **not a complete taxonomy of all possible shape-origin sources** (round-2 codex acknowledgement on e1-c5). It is the §5.4-§5.5 binding interface; alternative shape-fitting implementations may have other sources; downstream consumers should treat values outside the documented enum as `unknown`. Don't imply the enum exhausts the world.

5. **The "diagnostics, not part of the binding tuple" discipline sentence** ("These side-channel fields are **diagnostics, not part of the binding tuple**, and §5.5 must function correctly when they are absent..."). Verbatim-protected; this is the §5.5 robustness contract.

6. **The five-method scope statement** ("This section covers L-shape fitting (Zhang 2017) for vehicles, PCA / OBB as the cheap fallback, min-area rectangle as the convex-hull optimum, convex hull as an *optional footprint payload*, and class-prior dimensions for partial views."). Verbatim-protected — the section's algorithm scope was set at Phase-3 plan. Don't add a sixth method, don't drop one, don't reorder.

7. **The pedagogical-center claim** ("The pedagogical center is the failure-mode catalog: classical fits routinely produce *planner-hostile boxes* even when the underlying cluster looks fine."). Verbatim-protected.

8. **Cross-section contract terms:** `Object-shape fitting` / `shape fitting` (never "shape estimation" except citing Autoware); `L-shape fitting`; `PCA / OBB`; `min-area rectangle`; `convex hull`; `class-prior box dimensions`; `5_4.fm.<short_slug>` ID format. Mention-level RANSAC L-fit `> [!tip]` callout content (line 33-34) preserved.

The framing-preservation Path B axis applies in **strict** form (not light). Main-conflict review checks all 8 items every round. Any drift on items 2 (DL displacement scope), 3 (binding tuple), or 4 (side-channel enum values) is a hard fail.

## 10. Process

1. Read brief end-to-end + current §5.4 + pilot pattern.
2. Map every existing paragraph to five-block per algorithm. Extension fills gaps.
3. Anchor (L-shape): full implementation depth — projection onto rotated axes (closed-form math); the three Zhang scoring criteria (area / closeness / variance) with formulas; coarse-to-fine search procedure (5° → 0.5°); corner-strength score → `yaw_confidence` mapping. Worked Example: walk one search step on a 12-point L-cluster with concrete numbers.
4. Non-anchor (PCA/OBB / min-area / convex hull / class-prior): mechanics-depth-for-reading-production-code; Worked Example for at least PCA/OBB and min-area rectangle (rotating calipers). Usage with default parameters.
5. Add the L-shape geometry visual + recommended rotating-calipers visual.
6. Word-count yourself. Aim ~5500.

## 11. Return manifest

Per pilot pattern. Confirm: file path, word count, per-algorithm five-block coverage, anchor declaration with sub-budget confirmation, visual artifacts present, catalog block status, **8 protected-framing-span items confirmed verbatim** (Safeguard 1 strict), output contract preservation, side-channel-metadata enum values preserved, new factual-claim inventory (Rule 3b two-tier).
