---
title: §5.2 ground segmentation — extension brief
doc_type: section-extension-brief
chapter: 5
section: 2
phase: 4-extension
writer: codex-writer
status: draft
created: 2026-05-03
related:
  - "[[ch5_chapter_plan]]"
  - "[[ch5_extension_plan]]"
  - "[[ch5_5_1_extension_brief]]"
tags: [workflow, chapter-5, extension, brief, codex-writer]
---

# §5.2 ground segmentation — extension brief

Sequential after §5.1 AGREED at `057d8f3`. Inherits all pilot+§5.1 calibration.

> [!info] Section assignment
> - **Section path:** `chapter_5_classical_lidar_detection/5_2_ground_segmentation_EN.md`
> - **Writer:** **codex-writer** (round-W). §5.2 was originally codex-drafted; lightweight protected-framing applies.
> - **Length:** **4500–6000 words** (target ~5500, trim 5800, ceiling 6000; current 2796 → ~2.0× expansion).
> - **Anchor algorithm:** **Patchwork++ (Lee 2022).** It is named in chapter plan Item 1 as the modern classical baseline; treat it as a **strong open-source classical baseline** (the ground-seg method most active 2024–2026 open-source pipelines reach for), not as benchmark-SOTA on any specific dataset. It synthesizes the lessons from RANSAC / Himmelsbach / radial-bin lineage. RANSAC stays as the entry baseline (the "where the lineage starts" anchor for the reader); Himmelsbach / radial-bin / heightmap / GP-INSAC are non-anchor with mechanics-depth-for-reading-production-code; Patchwork (the original Lim 2021 paper) is mention-level inside the Patchwork++ block since Patchwork++ subsumes it (round-1 codex e1-c2 fix: don't overstate "stabilized in 2024–2026" or claim SemanticKITTI SOTA leadership without citation).
> - **Workflow gate after this section:** Phase-5 Path B → AGREED → §5.4.

**Binding taxonomy:** five canonical blocks (Concept / Mechanics / Worked Example / Usage / Failure Modes).

## 1. Per-algorithm gap analysis

Current §5.2 has 5 algorithm sections (RANSAC, Himmelsbach scan-line, radial bins + grid heightmaps, GP-INSAC, Patchwork/Patchwork++) + Output contract + Shippable interface. Each algorithm has Concept and a brief failure-mode warning callout, but full five-block coverage is missing for all.

- **RANSAC plane fitting (entry baseline):** Concept ✓; Mechanics ◐ (sample-fit-count-keep loop sketched, distance-threshold + plane-normal-prior present, no full implementation depth — random sampling iteration count, max iterations, MSAC vs RANSAC variant, refinement step); Worked Example ✗; Usage ◐ (plane-normal prior toward gravity mentioned, no parameter ladder); Failure Modes ✓ (callout present); DL displacement story ✗.
- **Himmelsbach scan-line (non-anchor):** Concept ✓; Mechanics ◐ (radial scan-line ordering, segment-and-merge sketched, no full step-by-step); Worked Example ✗; Usage ◐ (slope thresholds mentioned, no parameter values); Failure Modes ✓ (callout present); DL displacement story ✗.
- **Radial bins + grid heightmaps (non-anchor; treat as one family):** Concept ✓; Mechanics ◐ (sector-and-radial-bin partitioning + heightmap projection sketched); Worked Example ✗; Usage ◐ (cell size mentioned); Failure Modes ✓; DL displacement story ✗.
- **GP-INSAC (mention-level historical):** brief paragraph as historical context — leave as mention-level, no five-block needed. The chapter plan Item 1 calls GP-INSAC "historical."
- **Patchwork / Patchwork++ (anchor):** Concept ◐ (concentric zone CZM + region-wise GPF + non-ground likelihood NGL mentioned); Mechanics ✗ (the four-stage pipeline — CZM, R-GPF, GLE, TGR — needs full implementation depth as anchor); Worked Example ✗; Usage ◐ (cited as modern classical baseline; no parameter values); Failure Modes ◐ (curb / vegetation / dynamic-actor mentions present, no DL displacement framing).
- **Heightmap as fallback** is mentioned in §5.2 — fold into the radial-bin + heightmap family.

## 2. Per-algorithm length budget

- **Anchor (Patchwork++):** Concept ~150–250 + Mechanics 700–1100 (sub-budgets: CZM concentric-zone partitioning ~150–250; R-GPF region-wise GPF + plane fitting ~200–300; GLE ground likelihood estimation ~150–250; TGR temporal ground revert + R-VPF ~200–300) + Worked Example ~150–300 + Usage ~200–350 + Failure Modes ~150–250 = **~1350–2250**. **Per round-1 codex e1-c3:** Mechanics must give a concrete **per-patch decision flow** (inputs → seeds → plane estimate → features → thresholds → accept / reject / revert → output) rather than shallow acronym paraphrase. Each acronym (CZM / R-GPF / GLE / TGR / R-VPF) is named with its expansion + the specific decision rule it implements; the reader should be able to walk a single patch from the seed-selection step through the temporal-revert step without going to the original paper.
- **Entry baseline (RANSAC):** ~700–950 (Concept ~150–200 + Mechanics ~250–350 + Worked Example ~150–250 + Usage ~150–200 + Failure Modes ~150–200).
- **Non-anchor (Himmelsbach, radial-bin/heightmap family) — two algorithm-families:** ~700–950 each = **~1400–1900 combined**.
- **GP-INSAC (mention-level historical):** ~150–200.
- **Output contract + Shippable interface:** preserved ~250–350.
- **Section framing prose** (intro + closer): ~400–500.
- **Failure-mode catalog block (frozen):** ~500.
- **Visual artifacts:** ground-vs-non-ground geometry on a slope/curb cross-section + Patchwork++ concentric-zone visual ~200–300.

**Target total:** ~5400–7150 (upper-budget arithmetic). **Aim ~5500; trim threshold 5800; hard ceiling 6000.** Trim connective prose / non-anchor family elaboration first if over.

## 3. Visual artifact discipline

- **Required: spatial visual for ground segmentation** (load-bearing) — ASCII cross-section of a road with curb / ramp / standing water, showing where ground / non-ground decision lives, OR a slope-vs-height-discontinuity diagram showing what RANSAC misses on a curb. Place near RANSAC failure-modes block.
- **Recommended: Patchwork++ concentric-zone visual** — top-down sketch of the CZM bins (concentric rings + sectors), or a side-view showing the per-zone plane fits.
- **Required: comparative method-comparison table** (round-1 codex e1-c5 fix to avoid checklist-prose risk on the four method families). One Markdown table with columns for *assumptions / strengths / failure signatures*, one row per family: global plane (RANSAC), scan-line (Himmelsbach), radial bins / heightmap (Douillard / grid-heightmap), local patches (Patchwork / Patchwork++). The five-block coverage per algorithm still holds; the table is a synthesis aid, not a replacement.
- **Required: explicit sensor-class declaration** (round-1 codex e1-c4 fix). The default LiDAR assumption for §5.2 is mechanical-spinning (HDL-32E, HDL-64E, VLP-32C class). Patchwork++ and Himmelsbach assume rough ring repeatability; non-repetitive scanners (Livox Mid-360, Avia, Horizon) and fused multi-LiDAR clouds need re-projection or per-sensor processing — state this once at the section opening or at each algorithm's Usage block.
- Heightmap as a tabular structure may supplement but does NOT satisfy the spatial visual rule.

## 4. Catalog block discipline

5 rows (`5_2.fm.curb_eaten_as_ground`, `5_2.fm.ramp_misclassified`, `5_2.fm.flatbed_truck_as_ground`, `5_2.fm.overpass_single_layer`, `5_2.fm.standing_water_sparse_returns`) preserved verbatim. **No row text changes inside this dispatch.** Proposed changes via change log.

## 5. Forward / cross-references

- Inputs (preserve): `[[5_1_pointcloud_preprocessing_EN|§5.1]]` deskewed/voxel-downsampled cloud; the four-representation primer.
- Outputs (preserve): `[[5_3_clustering_EN|§5.3]]` consumes residual non-ground cloud; `[[5_7_occupancy_freespace_map_roi_EN|§5.7]]` consumes ground labels for free-space.
- Forward to Ch 6 (add): some production DL stacks **run classical ground segmentation in front of learned detectors** as one of the five load-bearing-classical-in-DL pieces per §5.9. The pattern is "classical ground seg as a CNN front-end" used when cutting the input cloud reduces the learned head's compute meaningfully; not all stacks adopt it (some PointPillars / CenterPoint deployments run on the full preprocessed cloud and let the voxel encoder absorb the ground problem implicitly). Phrase as "a common pattern" rather than "the production default" — the section's bounded claim should be "classical ground seg survives as one of several integration patterns inside DL-primary stacks." Learned ground-segmentation networks exist (SalsaNet, RangeNet semantic ground class) but the *general pattern* on the classical side is hand-built ground seg as preprocessor; the *general pattern* on the DL side is "voxel encoder handles ground implicitly." Both ship.

## 6. Voice rules

All chapter-plan Item 6 voice rules apply. New / strengthened: five-block, visual artifact discipline, intra-Ch-5 wikilink as `§N.M`. Patchwork / Patchwork++ are **fully classical** — no "hybrid" caveat (chapter-plan Item 9 must-preserve terminology).

## 7. Phase-5 path

Path B (codex-drafted) — main rounds 1..N-1 + codex-collaborator final-round sanity pass. Five-axis review including framing-preservation (light, for §10).

**Rule 3b two-tier:** spot-check required for new numeric defaults / paper-specific thresholds / runtime claims / DL displacement claims. Manifest must list every new claim.

## 8. Frontmatter

```yaml
---
chapter: 5
section: 2
title: Ground segmentation
language: EN
workflow_status: reviewing
tags:
  - book/section
  - book/chapter-5
  - lang/EN
---
```

## 9. Lightweight protected-framing spans for §5.2

§5.2 was originally codex-drafted; lightweight protection applies. Preserve verbatim or with formatting-only changes:

1. **The output contract opening sentence** ("§5.2 produces a residual non-ground cloud: ground points are removed, or a mask is published beside the original cloud when consumers need original point indices...") — binding handoff to §5.3.
2. **The "RANSAC failure modes" `> [!warning]` callout** (currently "RANSAC eats curbs when the distance threshold is larger than curb height...") — load-bearing pedagogical anchor for the section's "why a single-plane assumption breaks" thesis.
3. **The "Himmelsbach failure modes" `> [!warning]` callout** ("Scan-line methods can label curb faces as ground when slope thresholds are permissive...") — same pedagogical role for scan-line methods.
4. **The "Radial-grid and heightmap failure modes" `> [!warning]` callout** ("Grid methods smear vertical structure inside a cell...") — same role for heightmap family.
5. **Cross-section contract terms** (must remain exactly): "Patchwork" / "Patchwork++" capitalized + fully classical (no "hybrid" caveat); "RANSAC" uppercase; "Himmelsbach" eponym; "ground segmentation" / "ground / non-ground"; `5_2.fm.<short_slug>` ID format; the chapter-pipeline arrow notation `preprocess → ground → cluster → fit → track`.
6. **Patchwork++ as the modern classical baseline framing** (currently "Patchwork (Lim 2021) and Patchwork++ (Lee 2022)... are the modern classical baseline this chapter recommends...") — the framing is referenced by §5.9 + §5.10 catalog blocks.

The framing-preservation Path B axis applies in light form. Main-conflict checks §9's items every round.

## 10. Process

1. Read brief + current §5.2 + §5.1 pilot (extended) + standard memory.
2. Map every existing paragraph to five-block per algorithm. Extension fills gaps.
3. Anchor = Patchwork++. Full implementation depth: CZM concentric zones, R-GPF region-wise plane fitting, GLE ground likelihood estimation, TGR temporal ground revert + R-VPF reflective-noise removal. Worked Example: walk a small concentric-zone scenario showing per-zone slope adaptation.
4. Entry baseline = RANSAC. Mechanics: sample-fit-count-keep loop with explicit iteration math (sample size 3 for plane, max iterations from inlier-ratio formula). Worked Example: small toy scene with road + curb + truck, show how a permissive distance threshold eats the curb.
5. Non-anchor (Himmelsbach, radial-bin/heightmap): mechanics-depth-for-reading-production-code; Worked Example for at least one (probably Himmelsbach scan-line cut + merge); Usage with default thresholds.
6. GP-INSAC stays mention-level historical (chapter plan Item 1 says "historical").
7. Add the two visual artifacts.
8. Word-count yourself. Aim ~5500.

## 11. Return manifest

Per pilot pattern. Include: file path, word count, per-algorithm five-block coverage confirmation (Patchwork++ anchor with full implementation; RANSAC entry baseline; Himmelsbach / radial-bin-heightmap non-anchor; GP-INSAC mention-level), anchor declaration + sub-budget confirmation, visual artifacts present, catalog block status, output contract preservation confirmation, new factual-claim inventory.
