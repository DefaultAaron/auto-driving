---
title: §5.7 occupancy + ROI gating — extension brief
doc_type: section-extension-brief
chapter: 5
section: 7
phase: 4-extension
writer: codex-writer
status: draft
created: 2026-05-03
related:
  - "[[ch5_chapter_plan]]"
  - "[[ch5_extension_plan]]"
tags: [workflow, chapter-5, extension, brief, codex-writer]
---

# §5.7 occupancy + ROI gating — extension brief

Sequential after §5.6 AGREED `9711112`. §5.7 originally cc-drafted (contested combination — occupancy + map-aided integration was Phase-2 structural rename). Round-W: all-codex with **FULL Safeguard-1**. Already largest section at 4297 words.

> [!info] Section assignment
> - **Section path:** `chapter_5_classical_lidar_detection/5_7_occupancy_freespace_map_roi_EN.md`
> - **Writer:** **codex-writer**. FULL Safeguard-1.
> - **Length:** **5500–7000 words** (target ~6200, trim 6500, ceiling 7000; current 4297 → ~1.45× expansion — modest because already substantial).
> - **Dual anchor (round-1 codex e1-c4):** §5.7 has two distinct algorithmic foundations — **(a) 2D occupancy grid in log-odds + ray casting** is the **evidence anchor** (probabilistic mathematical foundation that occupancy / OctoMap / GOD all build on); **(b) HD-map ROI gating with Apollo + Autoware `compare_map_segmentation` patterns** is the **integration/production anchor** (the map-prior filtering pattern that classical detection survives in DL-primary stacks via). Both get full implementation depth in Mechanics. OctoMap is non-anchor (3-D extension of evidence anchor); Generic Obstacle Detection is non-anchor (safety-fallback wiring); the two map-aided patterns share the integration anchor's depth budget. Single-anchor would force half the section into shallow non-anchor treatment — codex round-1 e1-c4 flagged this as the section's structural ambiguity.
> - **Workflow gate:** Path B → AGREED → §5.8.

**Binding taxonomy:** five canonical blocks per algorithm-family.

## 1. Per-algorithm gap analysis

Current §5.7 has 7 algorithm sections (2D occupancy, ray casting, OctoMap, GOD, HD-map ROI, `compare_map_segmentation`, why-this-survives) + Failure modes catalog.

- **2D occupancy log-odds (anchor):** Concept ✓; Mechanics ✓ (recursive Bayes + log-odds form + clamping + initialization — solid); Worked Example ✗ (no concrete grid update walk-through); Usage ◐ (parameters mentioned, no ladder); Failure Modes ✗ (this algorithm's specific failure modes — clamping pathology, initialization-as-free bug — not catalogued explicitly though the section warns about them).
- **Ray casting / free-space carving (sub-anchor):** Concept ✓ (Bresenham mention, "every laser ray clears cells along its path" framing); Mechanics ◐ (algorithm sketched, no implementation depth on first-return policy + l_free magnitude); Worked Example ✗.
- **OctoMap (non-anchor):** Concept ✓ (Hornung 2013 + hierarchical octree + log-odds inheritance); Mechanics ◐; Worked Example ✗.
- **Generic Obstacle Detection / GOD (non-anchor; safety pattern):** Concept ✓; Mechanics ◐ (occupancy threshold + class-agnostic blob extraction sketched); Worked Example ✗.
- **HD-map ROI gating / Apollo (non-anchor):** Concept ✓; Mechanics ✓ (precomputed BEV LUT + per-cluster point-in-polygon test, the C++ snippet at lines 75-87 already strong); Worked Example ◐ (the C++ snippet IS a worked example); Usage ◐; Failure Modes ✓.
- **`compare_map_segmentation` / Autoware (non-anchor):** Concept ✓; Mechanics ◐ (NDT-aligned prior cloud + per-point distance test sketched); Worked Example ✗; Usage ◐.
- **Why-this-survives** (synthesis paragraph): preserved verbatim.

## 2. Per-algorithm length budget

Already-large section; modest extension (~1.45×) primarily fills five-block gaps + one or two Worked Examples.

- **Evidence anchor (2D occupancy log-odds + ray casting):** combined ~1200–1500 (Concept ~250 + Mechanics ~600 + Worked Example ~200–250 (small grid update walk-through with concrete log-odds values across 3 sweeps) + Usage ~150 + Failure Modes ~100).
- **Integration anchor (HD-map ROI gating + `compare_map_segmentation`):** combined ~1300–1700. HD-map ROI gating ~700–950 (Mechanics: polygon rasterization + cell-center convention + ROI dilation/buffer + cluster-rejection policy for actors straddling boundaries; Worked Example: walk a truck cluster through ROI gating with a pose-on-edge case — round-1 codex e1-c3: snippet is not a worked example). `compare_map_segmentation` ~600–750 (Mechanics + Worked Example: NDT-aligned scan + per-point distance threshold + dynamic-residual extraction).
- **OctoMap (non-anchor):** ~500–700 (Concept ~150 + Mechanics ~200 + Usage ~100 + Failure Modes ~50; Worked Example optional/short — Hornung 2013 reference suffices to find the paper).
- **Generic Obstacle Detection (non-anchor; safety pattern):** ~500–700 (full five-block including Worked Example: occupancy threshold → blob extraction → minimum-cluster-size gate).
- **Why-this-survives synthesis:** ~300 (preserved + minor refinement).
- **Failure-mode catalog (frozen):** ~500.
- **Section framing prose** (intro + prerequisites): ~500.
- **Visual artifacts:** occupancy log-odds update sketch + HD-map ROI suppress visual + ray-casting-through-glass visual ~250–350.

**Target total:** ~5750–6850. **Aim ~6500 (round-1 codex e1-c6: 6200 was too tight given dual-anchor + nine Safeguard-1 + visuals); trim threshold 6800; hard ceiling 7000.** Cut order: (1) compress OctoMap to mention-level (Hornung 2013 reference is enough to find the paper); (2) trim non-anchor connective prose; (3) drop ray-casting-through-glass visual if budget tight (the catalog row carries the failure mode independently). **Never trim:** evidence-anchor occupancy mechanics + Worked Example, integration-anchor HD-map ROI + `compare_map_segmentation` mechanics + Worked Examples, GOD safety-fallback discipline, output contract, catalog.

## 3. Visual artifact discipline

- **Required: occupancy log-odds update visual** (load-bearing for anchor) — small 5×5 BEV grid showing log-odds before/after one sweep with cells receiving `l_occ` / `l_free` / no-update.
- **Required: HD-map ROI suppress visual** (load-bearing for the cross-half integration) — overhead view showing ROI-gated detection passing + ROI-gated-out actor that GOD fallback catches.
- **Recommended: ray-casting-through-glass visual** — the `5_7.fm.ray_casting_through_glass` mechanism (specular returns clearing cells beyond the surface).

## 4. Catalog block

4 rows preserved verbatim. No row text changes.

## 5. Forward / cross-references

- Inputs (preserve): §5.1 BEV grid representation; §5.6 Roles 2 (`compare_map_segmentation` map subtraction), 3 (multi-frame accumulation alignment), 4 (map-aided ROI consistency); §2.5 map-relative localization; §2.7 HD-map management.
- Outputs (preserve): §5.10 catalog; planner consumption of free-space + ROI; Ch 7 fusion may consume occupancy as a fusion gate.
- Forward to Ch 6 (already present in §5.7's "Why this classical substrate survives" paragraph): occupancy + ROI gating + GOD are load-bearing classical inside DL-primary stacks per §5.9. Production DL stacks generally consume ROI-gated input; OctoMap or planar occupancy survives as the safety fallback for unknown classes. Phrase consistent with §5.2 / §5.4 / §5.5 / §5.6 narrowing.

## 6. Voice rules

All chapter-plan Item 6 voice rules. OctoMap CamelCase; "occupancy grid" lowercase generic; "free-space carving" hyphenated; "drivable area" no hyphen; "Generic Obstacle Detection" capitalized; "HD-map ROI gating" consistent dashing; "Apollo HDMap" proper noun; "`compare_map_segmentation`" Autoware package name.

## 7. Phase-5 path

Path B with **FULL Safeguard-1** framing-preservation strict. Five Path B bias axes.

## 8. Frontmatter

```yaml
---
chapter: 5
section: 7
title: Occupancy, free-space & map-aided ROI gating
language: EN
workflow_status: reviewing
tags:
  - book/section
  - book/chapter-5
  - lang/EN
---
```

## 9. FULL Safeguard-1 protected-framing spans for §5.7

§5.7 was renamed at Phase 2 to combine occupancy + map-aided gating; the **integration thesis** is the section's reason to exist. FULL Safeguard-1.

1. **The §5.7 opening paragraph** (current line 15 — "This section unifies two classical machineries..."). **Verbatim-protected.** The unification thesis is referenced by §5.10 + §5.9 catalogs.
2. **The "two halves share substrate and roles" paragraph** (line 17) — verbatim. Cross-references §5.1 BEV substrate + §5.6 Roles 2/3/4.
3. **The "failure modes are stories about how the two halves couple" paragraph** (line 19) — verbatim. Pedagogical center.
4. **The `> [!abstract] What this section covers` callout** (line 21–22) — verbatim. Names the algorithms + scope.
5. **The "Why this classical substrate survives" closing paragraph** (line 117–119) — verbatim. The section's bounded DL-displacement claim, referenced by §5.9 + §5.10.
6. **The HD-map ROI gating C++ snippet** (lines 75–87 area) — **content-protected with permission to fix factual / production-correctness defects** (round-1 codex e1-c1). Codex flagged: `static_cast<int>` truncates toward zero, not floor (negative coordinates index wrong cell instead of returning false); `rows_` / `cols_` vs `i` / `j` axis mapping ambiguous. The writer should fix to floor-based integer math (`std::floor` or `static_cast<int>(std::floor(...))`), clarify row=y / col=x convention, and keep the rest of the snippet's structure. The pseudocode-style snippet is preserved as a structural anchor but is not "shippable verbatim" given the truncation bug.
7. **The output contract** (whatever §5.7 publishes — occupancy grid + ROI mask + free-space layer + GOD candidates). Verbatim.
8. **The Apollo-vs-Autoware framing** — current text says "Autoware's subtraction gates **what is dynamic** (whatever the prior cloud does not explain)." Round-1 codex e1-c2 flagged that "what is dynamic" overstates: residual is *only approximately* dynamic; operationally it is "unexplained" (the current §5.7 prose elsewhere uses this safer framing). **Soften to:** "the Apollo lookup gates **where to look** (drivable polygons); Autoware's subtraction gates **what the static prior fails to explain** (operationally 'unexplained,' which is only approximately 'dynamic'). They are complementary and a stack may use both." The softened version is **content-protected, not verbatim-locked** (allow narrowing per §5.2 / §5.4 precedent; forbid broadening).
9. **Cross-section terminology:** OctoMap CamelCase; "occupancy grid" lowercase generic; "Generic Obstacle Detection" capitalized; "HD-map ROI gating"; "Apollo HDMap" proper noun; `compare_map_segmentation` Autoware package; 5_7.fm.* IDs.

The framing-preservation Path B axis is **strict**.

## 10. Process

1. Read brief + current §5.7 + pilot patterns.
2. Map existing prose to five-block per algorithm-family.
3. Build out occupancy log-odds anchor with full Mechanics + Worked Example.
4. Add Worked Examples for `compare_map_segmentation` and Generic Obstacle Detection (the two with most-thinly-developed depth).
5. Add three visual artifacts.
6. Word-count yourself. Aim ~6200.

## 11. Return manifest

Per pilot pattern. Confirm: file path, word count, per-algorithm five-block coverage, **dual-anchor sub-budget confirmation** (evidence anchor + integration anchor), visual artifacts present, catalog status, 9 Safeguard-1 items confirmed (item 6 with permission-to-fix-defects-applied; item 8 softened content-protected; rest verbatim), output contract preserved, **new factual-claim inventory mandatory** (round-1 codex e1-c5): every production claim ("Apollo's classical pipeline used X"; "Autoware exposes Y as a parameter"; "Production DL stacks generally consume ROI-gated input"; runtime budget p50/p99/memory) listed with writer's recommendation on whether Rule 3b spot-check is required. The manifest is the enforcement point.
