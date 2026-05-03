---
title: §5.7 extension — Path B round-2 revision brief
doc_type: revision-brief
chapter: 5
section: 7
phase: 5-extension-path-b
round: 2
writer: codex-writer
status: draft
created: 2026-05-03
related:
  - "[[ch5_5_7_extension_brief]]"
tags: [workflow, chapter-5, extension, revision-brief, codex-writer]
---

# §5.7 round-2 revision brief

Path B final-round codex-collaborator critique returned 5 critiques. All apply.

## final-c1 — `compare_map_segmentation` factually misdescribed

**Defect:** §5.7 currently describes the Autoware `compare_map_segmentation` node as performing NDT/GICP registration internally. The node actually filters input points against the prior map using KD-tree distance / voxel-based comparison / elevation tests — it consumes a transform from upstream localization (which may use NDT) but does NOT itself register.

Gemini Rule 3b spot-check is dispatched in parallel to verify the exact filter modes; if confirmed, soften the description to:
- The node receives a transform from upstream localization (Autoware's `ndt_localizer` / pose-estimator node, etc.).
- The node filters live points against the prior map using KD-tree distance, voxel-based comparison, or elevation tests.
- Output: unexplained / residual points (operationally only approximately "dynamic").

Update the Worked Example accordingly: it should walk the per-point distance test against the registered prior map, NOT show NDT/GICP registration happening inside `compare_map_segmentation`.

## final-c2 — Autoware "ROI granularity as a parameter" unsupported

**Defect:** §5.7 currently claims "Autoware exposes ROI granularity as a parameter." Codex flagged that `compare_map_segmentation` parameters are `distance_threshold`, dynamic map loading, map loader radius, etc. — not ROI granularity. ROI gating in Autoware is handled by separate lanelet / drivable-area filters.

**Fix:** either remove the claim, or rename to the actual Autoware parameter ("`distance_threshold`" + "voxel-based vs elevation-based filter selection") and clarify that ROI gating per se is handled by separate Autoware modules (lanelet filters, drivable-area extraction) that this section doesn't cover in depth.

## final-c3 — Factual-claim inventory not in section

**Defect:** Writer's manifest listed 8 production-claim items awaiting Rule 3b spot-check, but the section file itself doesn't carry that inventory. Per the brief's mandatory-inventory rule, the writer manifest is the enforcement point — main session decides which claims to dispatch gemini on; the section text needs to read cleanly without inventory bookkeeping inline.

**Fix:** The inventory stays in the manifest record (already there); main session decides gemini dispatches. No section-text change required for c3 — this is a process-tracking critique, not a content one. We're handling it via the gemini dispatch on c1 + the softening on c2 + flagging the others for §5.10 / Phase-6 voice-pass review later.

## final-c4 — Numeric / product claims need softening

**Defect:** Several runtime / production claims are textbook-uncertain:
- "map-subtraction registration sub-rate (every 3rd frame)" — actually present in the §5.9 catalog as `5_cross.fm.subrate_registration_starves_under_load`; the every-3-frames is illustrative.
- "map subtraction adds a fraction of a millisecond per frame" — illustrative.
- "GPU acceleration of ray casting … can roughly halve the CPU latency" — illustrative.
- "OctoMap … adds ~50–200 MB" — this comes from §5.9; preserve the figure with explicit "illustrative per the §5.9 budget."
- "Apollo's classical pipeline used a footprint-overlap variant with a buffer" — narrow to "Apollo's open-source ROI gating module ([apollo/perception/lidar/lib/detector/...]) implements a footprint-overlap variant" if you can find the reference path; otherwise soften to "Apollo-style ROI gating commonly uses a footprint-overlap variant with a buffer (e.g., 2 m)."

**Fix:** Add "illustrative" qualifiers where appropriate; cite §5.9 for the runtime numbers (which originate there); soften the Apollo claim to a non-attributed pattern statement.

## final-c5 — OctoMap compression explanation too clean

**Defect:** Current §5.7 says: "A cell subdivides into eight children only where occupancy varies." Codex flagged this as too oracular — the actual mechanism is: OctoMap allocates nodes along updated rays/endpoints during sensor updates, then can later prune homogeneous subtrees (where all 8 children have the same occupancy state).

**Fix:** Replace the phrase with: "Internal nodes are allocated along the rays/endpoints touched during sensor updates; homogeneous subtrees (all 8 children at the same occupancy state) can be pruned later, leaving an adaptive tree that uses memory only where occupancy varies."

# Hard rules

- All other content unchanged. Length 6486 ± 100.
- Frontmatter `workflow_status: reviewing`.
- 9 Safeguard-1 items still preserved.
- Catalog frozen.

# Return manifest

- File path written.
- New `wc -w`.
- Before/after for c1 (compare_map_segmentation rewrite + Worked Example update).
- Before/after for c2 (ROI granularity claim).
- Before/after for c4 illustrative qualifiers (5 spots).
- Before/after for c5 OctoMap subdivision explanation.
- Confirmation no other content changed.
