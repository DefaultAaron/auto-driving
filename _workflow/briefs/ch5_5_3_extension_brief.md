---
title: §5.3 clustering — extension brief (round-W pilot)
doc_type: section-extension-brief
chapter: 5
section: 3
phase: 4-extension
writer: codex-writer
status: draft
created: 2026-05-03
related:
  - "[[ch5_chapter_plan]]"
  - "[[ch5_extension_plan]]"
tags: [workflow, chapter-5, extension, brief, codex-writer, pilot]
---

# §5.3 clustering — extension brief (round-W pilot)

This is the **first round-W extension** dispatch — §5.3 clustering serves as the pilot under the AGREED extension plan (`_workflow/plans/ch5_extension_plan.md`). The brief calibrates the five-block depth standard, the visual artifact discipline, and the codex-writer Path B extension workflow for the rest of the chapter.

**Binding taxonomy (per `feedback_section_depth_standard.md`):** the five blocks are exactly **Concept / Mechanics / Worked Example / Usage / Failure Modes**. Any other shorthand a reviewer might use (legacy "Idea / Usage / Limitations"; alternate "Why-this-algo / Mechanics / Tradeoffs / Deployment / Forward-link"; etc.) is **not binding** and must be mapped into the five canonical blocks before being used as an acceptance criterion. The writer satisfies the standard by covering the five canonical blocks; the reviewer accepts on those five names.

> [!info] Section assignment
> - **Section path:** `chapter_5_classical_lidar_detection/5_3_clustering_EN.md`
> - **Writer:** **codex-writer** (round-W: all-codex extension default). **§5.3 does not get full Safeguard-1 treatment** (Safeguard 1's full verbatim-protection is reserved for §5.4 / §5.6 / §5.7 / §5.9 / §5.10), **but the lightweight §10 protected-framing list IS binding** for this section per round-1 codex e1-c6. The framing-preservation Path B axis applies in light form; main-conflict review checks §10's items every round.
> - **Length:** **4000–5500 words** (extension band; current draft is 2416 words). Calibration target ~4500 mid-band.
> - **Anchor algorithm:** **Range-image connected components (Bogoslavskyi 2016).** It is the most mechanically interesting algorithm in §5.3 (range-adaptive by construction; the β-angle test is the section's pedagogical center) and is where full implementation depth pays off most. Euclidean and DBSCAN get mechanics-depth-for-reading-production-code (non-anchor).
> - **Reader entry-point preserved:** **Euclidean clustering remains the section's opening baseline and the fixed-tolerance reference point that motivates the alternatives.** "Anchor algorithm" means *deepest mechanics treatment*, not *rhetorical protagonist* or *replacement for Euclidean as the reader's entry*. The section opens with Euclidean (the production baseline most learners and code-readers meet first), establishes the fixed-radius problem, then DBSCAN softens the noise model, then range-image solves the range-bias problem at the projection level. The narrative arc is preserved; the depth allocation shifts toward range-image.
> - **Workflow gate after this section:** Phase-5 Path B deal-loop on §5.3 → AGREED commit → next sequential extension §5.1.

---

## 1. What's currently in §5.3 vs what the five-block standard requires

The current §5.3 covers three algorithms (Euclidean clustering / DBSCAN / range-image connected components) + scan-line variants + cluster post-processing. The five-block coverage is partial — most algorithms have Concept and Mechanics depth but the Worked Example, Usage (parameter rationale + tuning-knob → observable-symptom pairs), and Failure Modes blocks are thinner than the standard. Visual artifact is missing entirely.

### Per-algorithm gap analysis

**Euclidean clustering (non-anchor)**
- ✓ Concept: PCL entry point, KD-tree flood-fill — present.
- ◐ Mechanics: C++ snippet with `setClusterTolerance / setMinClusterSize / setMaxClusterSize` shown; the **algorithmic step-by-step** of how the flood-fill traverses the KD-tree (radius search → mark visited → push to cluster → recurse on unvisited neighbors → terminate at size cap) is not stated. Mechanics-depth-for-reading-production-code requires the reader to know what `extract()` does internally without consulting PCL source.
- ✗ Worked Example: missing. Need a concrete artifact — e.g., a 6-point toy cloud at known coordinates and a tolerance value, walking through which points end up in which cluster, plus the PCL pseudocode adjacent to the artifact.
- ◐ Usage: tolerance = 0.45 m is shown but the **rationale** is absent (why 0.45 vs 0.30 vs 0.60? what observable symptom changes when you move it?). Sensor / ODD applicability and cadence / budget mostly absent (the budget table at the end has p50/p99/memory but the prose doesn't tie back to it).
- ◐ Failure Modes: range-bias mentioned in prose; the catalog has the rows. The DL displacement story is buried in the closing paragraph; the prose should treat it explicitly per the standard.

**DBSCAN (non-anchor)**
- ✓ Concept: Ester 1996, density reachability, eps/minPts, noise model — present.
- ◐ Mechanics: density-reachability core / border / noise classification is referenced but the step-by-step (how a region query enumerates neighbors; how core points propagate cluster labels; how points become noise) needs to be tighter.
- ✗ Worked Example: missing. Need a concrete artifact — e.g., a small 2-D point set with eps and minPts shown explicitly, and a walk through which points become core, which become border, which become noise.
- ◐ Usage: eps = 0.4 m, minPts = 6 cited but rationale and tuning ladder absent. HDBSCAN escape mentioned but the conditions under which to switch are vague. Cadence / budget for DBSCAN vs Euclidean comparison absent.
- ◐ Failure Modes: range-density inheritance mentioned; the catalog has `5_3.fm.dbscan_eps_too_small`. DL displacement story missing.

**Range-image connected components — ANCHOR**
- ✓ Concept: Bogoslavskyi 2016, the depth-jump test, the geometric intuition that β stays near 90° on same-surface and collapses toward 0 on depth-jump — present.
- ✓ Mechanics: the β formula is given and explained correctly. **As the anchor algorithm, the section needs full implementation depth** — the reader should be able to write a toy version of the algorithm. Currently missing: the projection step (how `(x, y, z)` becomes `(ring, azimuth)` indices); the connected-components iteration (BFS / two-pass labeling on the range image); the threshold β_thresh choice rationale; the post-processing (component size gating, projection back to point indices).
- ✗ Worked Example: missing. The β formula is derived but not exercised on concrete numbers. The natural worked example: take a 3-pixel range-image strip with two same-surface returns at d1=10.0, d2=10.05 (β ≈ 89.7°) and a depth-jump pair at d1=30.0, d2=10.0 (β ≈ 8.7°); show the calculation; show how the threshold β_thresh = 10° classifies each.
- ◐ Usage: β_thresh = 10° cited; α (angular step) noted as "fixed sensor parameter" but specific values for HDL-32E / HDL-64E / VLP-32C / AT128 absent. Cadence / budget rough; the budget table has the row but no in-text mapping.
- ◐ Failure Modes: missing rings, non-repetitive scan, multi-LiDAR fusion mentioned; the catalog has `5_3.fm.range_image_projection_holes`. DL displacement story missing — does RangeNet / SqueezeSeg displace this?

**Scan-line variants (mention-level)**
- ◐ Brief paragraph; treated as a row-wise variant of range-image. Acceptable as mention-level; the standard does not require five-block coverage for every method-variant.

**Cluster post-processing (operational layer)**
- ✓ Operational concern, not a standalone algorithm. Min/max size gates, height/aspect sanity, deduplication, point-index preservation. Acceptable as-is.

### Visual artifact gap

§5.3 is geometry-heavy. **Required: ≥1 spatial visual artifact.** Two candidates fit naturally:
1. **Range-bias diagram** — the section's pedagogical center for "why one Euclidean tolerance can't serve the whole range." A small ASCII or canvas figure showing two beams diverging with range; the lateral spacing growing approximately as α·d; pedestrian / vehicle / wall-with-pedestrian-behind cases. **This is the load-bearing visual for the section.**
2. **β-angle geometry diagram** — for the anchor algorithm. A small ASCII figure showing the two adjacent beams hitting the same surface (β ≈ 90°) vs depth-jump (β ≈ 0°), with the chord and the angle drawn out.

Both can fit. Range-bias is required (load-bearing for the section's three-algorithm comparison). β-angle is the natural anchor-algorithm visual.

---

## 2. Per-algorithm length budget

Per-algorithm budget per `feedback_section_depth_standard.md`, with **anchor Mechanics raised** per round-1 codex e1-c3 (the original 400–700 was too tight for projection + connected-components + β test + post-processing).

- Anchor (range-image):
    - Concept ~150–250
    - **Mechanics ~700–1100** (sub-budgets: projection from `(x, y, z)` to `(ring, azimuth)` ~150–250; connected-components iteration with two-pass labeling ~150–250; β threshold rationale + derivation walk-through ~200–300; post-processing + projection-back to point indices ~200–300)
    - Worked Example ~150–300
    - Usage ~200–350
    - Failure Modes ~150–250
    - **Anchor total: ~1350–2250 words.**
- Non-anchor (Euclidean, DBSCAN): per algorithm ~700–1300 = **~1400–2600 words combined**.
- Scan-line variants (mention-level): ~150–300 words.
- Section framing prose (intro, prerequisite restatement, output contract, post-processing, section closer): ~800–1100 words.
- Failure-mode catalog block (already-AGREED rows, **do not edit**): ~400 words preserved as-is.
- Visual artifacts (range-bias diagram + β-angle diagram): ~150–300 words including caption.

**Target allocation (writer aims at ~5000 words; round-2 codex e2-c2 fix):**
- Anchor (range-image): ~1700–1900 words.
- Euclidean (non-anchor): ~850–1050 words.
- DBSCAN (non-anchor): ~850–1050 words.
- Scan-line variants (mention-level): ~150–200 words.
- Section framing prose (intro / prerequisites / output contract / post-processing / closer): ~700–850 words.
- Failure-mode catalog block (preserved verbatim): ~400 words.
- Visual artifacts (range-bias + β-angle diagrams): ~200–250 words including captions.
- **Target total: ~4850–5700 words.** Aim at the middle ~5000.

**Maxima as overflow guidance** (per-algorithm budget arithmetic from earlier in this section): if a block runs over its target, the upper-block-maximum (anchor Mechanics 1100; non-anchor 1300; etc.) is the hard ceiling. **If section total exceeds 5500, trim connective prose or non-anchor elaboration first** — do not trim anchor Mechanics, do not trim catalog rows, do not trim either visual. **Do not exceed 5700.**

---

## 3. Catalog block discipline (cross-cutting; protects §5.10 freeze)

§5.10 is **frozen** during this and all §§5.1–5.9 extensions per the AGREED plan §6 + §4.1. The §5.3 catalog block (5 rows: 4 per-section + 1 cross-section `5_cross.fm.deskew_then_cluster_doubling`) **must be preserved verbatim**. The writer **does not edit any row's `cause` or `downstream_hazard` text in the dispatch**, regardless of how compelling the case for an update seems while drafting (round-1 codex e1-c4 fix: edit-now-review-later allows drift; pilot precedent must be tighter).

If the writer discovers a row whose text genuinely needs a material update (e.g., the extension's deeper mechanics reveals that the row's `cause` line is mechanically wrong, not just compressible), the writer:
1. **Leaves the row text untouched in the section file.**
2. **Adds a proposed change-log entry** to `_workflow/briefs/ch5_extension_catalog_changes.md` (created if not present) with the schema: `host_section / id / current_cause / proposed_cause / current_hazard / proposed_hazard / reason`. The proposed text is a *recommendation* for §5.10's terminal integration to consume.
3. **Flags the proposed change in the dispatch manifest.**

Main session reviews proposed change-log entries at brief-AGREED-time before any subsequent extension dispatch reads the same catalog row. **No catalog row text changes happen inside the §5.3 extension dispatch.** This protects against pilot drift cascading into §§5.1, 5.2, 5.4, 5.5, 5.6, 5.7, 5.8, 5.9 dispatches that would inherit the drifted row.

**Default expectation: zero proposed change-log entries from the §5.3 extension.** The current rows are AGREED at chapter close; they are paragraph-level fingerprints of the failure modes the section identifies. The extension surfaces new *mechanism* detail in prose, but the catalog rows are summary and remain stable.

---

## 4. Forward / cross-references the extension preserves

- Inputs (preserve verbatim): `[[5_1_pointcloud_preprocessing_EN|§5.1]]` representation map + preprocessing contract; `[[5_2_ground_segmentation_EN|§5.2]]` residual non-ground cloud contract.
- Outputs (preserve verbatim): `[[5_4_object_shape_fitting_EN|§5.4]]` consumes per-cluster point indices + cluster-bbox approximation; `[[5_5_classical_tracking_EN|§5.5]]` Tracking-by-detection cross-pointer; `[[5_7_occupancy_freespace_map_roi_EN|§5.7]]` Generic Obstacle Detection over occupancy mention; `[[5_10_safety_and_validation_EN|§5.10]]` catalog contract.
- Prerequisites (preserve verbatim): `[[1_1_coordinate_frames_EN|Ch 1 §1.1]]` frame conventions; `[[1_3_lidar_calibration_EN|Ch 1 §1.3]]` PointCloud2 schema; `[[1_4_sensor_time_sync_EN|Ch 1 §1.4]]` per-point time + sync.
- Forward to Ch 6 (add): the DL displacement story per algorithm — what learned method displaces / hybridizes / leaves alone. Specifically: PointNet / PointNet++ for point-set semantic segmentation displacing Euclidean for primary semantic clustering on robotaxi stacks; RangeNet / SqueezeSeg for range-image semantic segmentation as a learned analogue to Bogoslavskyi connected components; HDBSCAN as the ML-adjacent escape but not a DL replacement. Cross-pointer: `[[6_0_overview_EN|Ch 6]]` for inheritance.

---

## 5. Voice rules (binding; from chapter plan Item 6)

All Item 6 voice rules apply unchanged. New / strengthened under round-W:

- **Per-algorithm five-block pattern** (Concept / Mechanics / Worked Example / Usage / Failure Modes). Anchor algorithm gets full implementation depth in Mechanics; non-anchor gets mechanics-depth-for-reading-production-code.
- **Visual artifact discipline** (binding): range-bias diagram is required (load-bearing); β-angle geometry diagram is the anchor-algorithm visual. Both should use ASCII / Markdown structure or `> [!example]` callouts; no external figure path needed for the pilot but a `.canvas` file is acceptable if the writer prefers.
- **Code policy**: C++ for shippable perception (the existing `pcl::EuclideanClusterExtraction` C++ snippet stays); Python ≤ ~10 lines as compact pseudocode (acceptable for the worked-example walkthroughs of DBSCAN core/border/noise classification or the Bogoslavskyi β computation).
- **Wikilinks**: intra-Ch-5 cross-references display as `§N.M`; cross-chapter as `Ch N §N.M` (chapter-plan Item 6 round-1 clarification, post-2026-05-03).
- **No emojis**; no marketing-style adjectives.

---

## 6. Frontmatter

```yaml
---
chapter: 5
section: 3
title: Clustering
language: EN
workflow_status: reviewing
tags:
  - book/section
  - book/chapter-5
  - lang/EN
---
```

`workflow_status: reviewing` because Phase-5 deal-loop runs immediately. The flip back to `complete` happens at the chapter's Phase-6 close lockstep (after all sections extension-AGREED + §5.10 terminal integration + §5.0 update).

---

## 7. Phase-5 path (codex-drafted → Path B)

After codex-writer dispatch returns:
- **Round 1+ (main session conflicts):** main reviews using **five named bias axes** (Rule 3c folded in): markdown over-listing, analogy register, foundational example choice, depth defaults, and (under round-W) framing-preservation. §5.3 was originally codex-drafted, **but the framing-preservation axis still applies in light form** (round-1 codex e1-c6: codex-on-codex extension can drift already-AGREED framing when adding 1600–3000 words around it). See §10 of this brief for the §5.3 lightweight protected-framing-spans list.
- **Final round (round N):** codex-collaborator does the final-round sanity pass; both sides AGREE before commit.
- **Rule 3b (gemini factual spot-check) — two-tier rule (round-1 codex e1-c5):**
    - **No spot-check needed** for already-present conceptual content (KD-tree flood-fill, density reachability, β-formula derivation, range-bias intuition).
    - **Rule 3b required** if the extension adds: numeric sensor specs (HDL-32E / HDL-64E / VLP-32C / AT128 angular resolution α; ring counts; firing rates), product/model-specific values, paper-specific thresholds (e.g., specific β_thresh values from Bogoslavskyi 2016 reference implementations), runtime comparisons (HDBSCAN vs DBSCAN scaling claims), or materially new DL displacement claims (PointNet++ vs Euclidean displacement story; RangeNet vs Bogoslavskyi).
    - **Manifest must list every new numeric / product-specific / paper-threshold claim** the writer adds, even if the writer judges Rule 3b unnecessary. Main session reviews the list and decides whether to dispatch gemini.
- **Rule 3d escape hatch:** under round-W, mandatory user-approval gate before any cc-writer dispatch. Default expectation: §5.3 converges in 2–3 Path B rounds without escalation.

---

## 8. What this brief does NOT change

- **Original framing of the three-algorithm comparison.** The section's structure (Euclidean → DBSCAN → range-image → scan-line variants → post-processing) stays. Extension is depth-on-existing-structure, not re-architecting.
- **Failure-mode catalog block.** 5 rows preserved verbatim in the section file; **no row text changes inside this dispatch.** Any needed material update is proposed only through the change log (`_workflow/briefs/ch5_extension_catalog_changes.md`) and flagged in the manifest. See §3 for the full discipline.
- **Per-stage runtime budget row.** The 8 ms p50 / 24 ms p99 / 96 MB / every-frame / ≤ 50 ms TF freshness numbers stay. Extension does not re-derive them; the prose may explain how the numbers connect to the algorithm choice (Euclidean KD-tree vs range-image O(N) vs DBSCAN region-query) but the row itself is the §5.9 contract.
- **The `5_3.fm.*` IDs.** No new IDs added. The catalog stays at the 37-entry chapter-wide total.

---

## 10. Lightweight protected-framing spans for §5.3 (round-1 codex e1-c6)

§5.3 was originally codex-drafted, so it does not get the full Safeguard-1 treatment that §5.4 / §5.6 / §5.7 / §5.9 / §5.10 receive. But codex-on-codex extension can still drift already-AGREED framing when adding 1600–3000 words around it. The writer **preserves the following spans verbatim or with only formatting changes**:

1. **The "proposal generation, not classification" thesis callout** (currently `> [!info]`):
   > Clustering in this section is proposal generation, not classification. A cluster says "these non-ground points may belong to one object"; shape fitting, Tracking-by-detection in [[5_5_classical_tracking_EN|Ch 5 §5.5]], map/ROI checks in [[5_7_occupancy_freespace_map_roi_EN|Ch 5 §5.7]], and validation in [[5_10_safety_and_validation_EN|Ch 5 §5.10]] decide whether that proposal is usable.
   This is the section's load-bearing pedagogical frame — what clustering *is* in this chapter's pipeline. The wikilinks may be renormalized (e.g., `Ch 5 §5.5` → `§5.5` per the round-1 wikilink rule clarification), but the prose is fixed.

2. **The output contract sentence** (current §5.3 paragraph 1):
   > The output contract is simple: a cluster is point indices plus a cluster-bbox approximation, and [[5_4_object_shape_fitting_EN|Ch 5 §5.4]] fits L-shapes, PCA-OBBs, min-area rectangles, convex hulls, and class-prior box dimensions to those clusters.
   The output contract is the binding handoff to §5.4 and is referenced by §5.4's own brief. Do not paraphrase, do not re-order the list of fitters.

3. **The bounded "Where classical clustering still ships" deployment-bucket paragraph** (currently the second-to-last paragraph before the failure-mode catalog) — **two-level protection** per round-2 codex e2-c5:
   > Where classical clustering still ships is best understood by deployment bucket rather than as a single claim. In **restricted, low-speed ODDs** (campus shuttles, factory yards, airport tugs) classical clustering can remain primary, because the ODD bounds the variety of objects and false-positive cost is lower. In **DL-primary L4 robotaxi and consumer NOA stacks**, learned semantic / instance segmentation owns the primary proposal path; classical clustering survives in narrower roles — embedded fallback, Generic Obstacle Detection over occupancy, a pre-filter that cheaply rejects ground-segmentation leftovers before a learned head, and a regression / diagnostic baseline when learned perception is degraded. In **research and academic** contexts classical clustering remains the canonical baseline against which DL detectors are measured. [[5_9_deployment_runtime_EN|Ch 5 §5.9]] picks up the production-survival argument; this section's claim is bounded to "classical clustering retains specific bounded roles," not "classical clustering is still a viable primary path on the open road."

   **Verbatim-protected (level 1):** the three deployment-bucket distinctions (restricted-low-speed-ODD / DL-primary L4-NOA / research-academic) and the bounded "specific bounded roles" closing claim. These mirror §5.9's bounded-claim framing on a per-stage scale and must not be paraphrased.

   **Content-protected (level 2):** the four narrower-roles list (embedded fallback / Generic Obstacle Detection over occupancy / pre-filter for ground-segmentation leftovers / regression-diagnostic baseline). No role may be **dropped, broadened, or re-ordered**, but local elaboration *adjacent to* the list is allowed if it preserves order and scope. For example, the writer may add one sentence after the list explaining the per-algorithm DL displacement story (per §4 of this brief) without re-ordering the list itself. The writer may also expand a single role with a parenthetical example that is consistent with the existing scope (e.g., "Generic Obstacle Detection over occupancy" → "Generic Obstacle Detection over occupancy (e.g., the OctoMap-fed safety-fallback path in DL-primary stacks)"). The writer may **not** add a fifth role, broaden any of the four roles to claim "primary path" status, or drop one because the extension argues it is redundant.

4. **Cross-section contract terms** (must remain exactly):
    - `Tracking-by-detection` (capitalized + hyphenated; never "track-by-detect" or "tracking by detection" without hyphen).
    - `Generic Obstacle Detection` (capitalized; not abbreviated to "GOD" — the chapter-wide terminology contract from chapter plan Item 9).
    - `5_3.fm.<short_slug>` and `5_cross.fm.<short_slug>` ID formats.
    - The §5.3-row schema fields exactly: `id / cause / observable_symptom / downstream_hazard / mitigation / validation_test`.

The framing-preservation axis check during Path B applies: protected thesis unchanged; scoped claims unchanged; no broadened or weakened deployment-bucket claims; no renamed contract terms. If main session's review flags any of these, the writer revises in the next round.

---

## 11. Return manifest expectations

After codex-writer returns, the manifest must include:
- File path written.
- New `wc -w` word count vs the 4000–5500 band.
- Per-algorithm five-block coverage confirmation (all 5 blocks present for Euclidean / DBSCAN / range-image; mention-level OK for scan-line variants).
- Anchor algorithm declared and full-implementation-depth confirmed for Mechanics.
- Visual artifacts present: range-bias diagram (load-bearing) + β-angle geometry diagram (anchor).
- Catalog block: untouched? Or change-log entries listed?
- **New factual-claim inventory:** list every new numeric, product/model-specific, paper-threshold, runtime-comparison, or materially new DL displacement claim. For each, mark whether the writer believes Rule 3b spot-check is required and the reason. Main session uses the inventory to decide gemini dispatch (the manifest is the enforcement point per the §7 two-tier rule).
- Any deviations from the brief and why.
