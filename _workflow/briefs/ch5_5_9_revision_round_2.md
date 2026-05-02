---
title: §5.9 round-2 revision brief — codex Phase-5 round-1 critiques applied
doc_type: section-brief
chapter: 5
section: 9
batch: 3
writer: cc-writer
phase: 5
round: 2
status: revision
created: 2026-05-02
related:
  - "[[ch5_5_9_deployment_runtime_brief]]"
tags: [workflow, chapter-5, batch-3, revision, cc-writer]
---

# §5.9 round-2 revision brief — apply 6 codex Phase-5 round-1 critiques

> [!info] Section under revision
> - **File path (only path you may write):** `chapter_5_classical_lidar_detection/5_9_deployment_runtime_EN.md`
> - **Round 1 commit:** `c4c71d3 wip(5/5_9_deployment_runtime): cc-writer round 1 draft`
> - **Round 1 prose word count:** 1746 (within 1200–2000 target). Raw `wc -w` 2571 includes table cells, wikilink syntax, callout markers — that's the metric codex used.
> - **Original brief (still binding):** `_workflow/briefs/ch5_5_9_deployment_runtime_brief.md`

This is a **revision pass**, not a fresh draft. Keep everything you got right in round 1; targeted fixes only.

## What you got right in round 1 (keep)

- Section structure: bounded claim → load-bearing list → China-vs-US → runtime budget table → ROS2 timing → field robustness → failure-mode catalog → forward closer.
- Three explicit definitions of "production stacks" / "primary detection" / "high-speed open-road AD".
- Two-tier evidence preserved (robotaxi L4 universally DL; consumer NOA strong evidence).
- §5.6 Role 1 (every-frame ICP ~10 ms) + Role 2 (every-3-frames GICP ~20 ms) cadence split with the explicit `~45 ms p50` every-frame chain.
- p99 reconciliation with the tail-correlated-stalls operational implication.
- Sensor-class normalization (§5.8 HDL-64E rescale).
- Three chapter-wide failure-mode entries distinct from the 27 per-section entries.
- Wikilinks back to owning sections in the load-bearing-classical list.

Codex AGREED on the cadence math, the p99 caveat itself, and the framing structure.

## The 6 critiques to apply

### r1-c1 — Fix the 20 Hz / frame-budget conflation (binding)

**Where:** lines 72 (frame-rate consistency paragraph) and 76 (ROS2 timing reconciliation, "tightens the freshness requirement proportionally").

**The bug:** "20 Hz solid-state sensors … compress every per-stage budget by half" conflates frame *rate* with compute *time*. 20 Hz halves the **frame period** (50 ms instead of 100 ms — the *deadline* for the every-frame chain), not the *per-stage compute*. Compute time is a function of point count, algorithm complexity, and memory bandwidth — none of which the frame rate changes directly. The fix:

- 20 Hz makes the deadline tighter: the every-frame chain (~45 ms p50 today) now has to finish inside 50 ms, not 100 ms. That margin disappears.
- Compute does not automatically halve. If the sensor delivers the same point density per frame, the per-stage budget is unchanged in absolute terms; the budget arithmetic just gets less generous because the period shrank.
- Solid-state sensors *can* deliver fewer points per frame than a 10 Hz mechanical-spinning at the same scan resolution — that's a separate point-count-per-frame argument, not a frame-rate-halves-compute argument.
- The "tightens the freshness requirement proportionally" claim on line 76 needs the same qualifier: a tighter deadline tightens the staleness tolerance for `/tf` correspondingly *only if* the perception loop's correctness depends on sub-frame-period freshness, which is not always true.

Rewrite the paragraph to keep the 20 Hz / FMCW reference but remove the budget-halves overclaim.

### r1-c2 — Remove "production default" / "does not get re-learned" overclaims (binding)

**Where:** lines 38–39 (load-bearing classical list, items 1 and 2).

**The bug:** Synthesis §1.13 supports "Preprocessing" and "Ground segmentation (often classical in front of a CNN to reduce compute)" — that's the language. The draft says:

- Item 1: "the math from Ch 5 §5.1 does not get re-learned end-to-end in shipping stacks" — too strong; the synthesis says "Preprocessing" remains, not that no shipping stack ever learns parts of it.
- Item 2: "the classical version is the production default in front of an end-to-end-trainable network" — too strong; "production default" is a stronger claim than "often classical."

Soften to track synthesis §1.13 hedge:

- Item 1: "remains classical in shipping stacks" or "is typically not re-learned end-to-end in shipping stacks" — drop "does not."
- Item 2: "is often the classical version in front of an end-to-end-trainable network, since it reduces input cloud size by 40–60% before the learned detector runs" — replace "production default" with "often."

Keep the percentage figure (40–60% input reduction); that's defensible.

### r1-c3 — Trim padded passages codex named (partial — apply)

**Where:** China-vs-US paragraph (line 46) and field-robustness paragraph (line 80) and the failure-mode row prose.

**Triage note:** Prose-only word count is 1746 (within 1200–2000); raw `wc -w` 2571 is the metric codex used. We are NOT fighting the broader "over length" framing — we ARE applying codex's specific call-outs:

- **China-vs-US paragraph (line 46, currently ~145 words):** trim to ≤ 120 words. Cut: the "LiDAR economics and regulatory priors split the deployment story along regional lines" opener is filler; the "A LiDAR chapter acknowledges the camera-only counter-position once and moves on" sentence is meta-commentary that can be cut without losing the point.
- **Field robustness paragraph (line 80, currently ~165 words):** trim to ≤ 150 words. Cut: the "noisier and sparser" / "less stable as a signal" / "false positives ... false negatives" expansion is restating; one tighter sentence covers it.
- **Failure-mode row prose:** keep all 3 entries. Each row's `mitigation` and `validation_test` cells can lose ~10–15 words by removing connectives without losing testability.

Net target: shave ~50–80 words from prose without touching the bounded-claim or load-bearing-list content (those are structurally load-bearing per the brief).

### r1-c4 — Stabilize canonical terminology (binding)

**Where:** lines 42 (load-bearing list item 5), 64 (sensor-class normalization paragraph), 70 (memory total paragraph).

**Fixes:**

- Line 42 bullet header "**Map-aided ROI gating**" → "**HD-map ROI gating**" (Item 9 contract, hyphen, lowercase otherwise). The body of the bullet can keep "Apollo HDMap polygon ROI lookup" (Apollo's proper noun) and the §5.6 Role 4 description "map-aided ROI consistency" (which is §5.6's Role-4 name in the §5.6 file — that usage is fine because it describes the registration role, not the gating mechanism).
- Line 64 "the prior-map tile and HDMap LUT are shared" → "the prior-map tile and HD-map ROI LUT are shared" (generic context).
- Line 70 "the prior-map tile and HDMap LUT do not multiply" → "the prior-map tile and HD-map ROI LUT do not multiply" (same).

When you mean Apollo's specific data structure, write "Apollo HDMap LUT". When you mean the generic concept across stacks, write "HD-map ROI LUT" (or just "the HD-map LUT" if the antecedent is clear).

### r1-c5 — Clarify the p99 validation envelope (binding)

**Where:** lines 68 (p99 reconciliation prose) and 89 (`5_9.fm.frame_budget_overrun_p99` `validation_test` cell).

**The bug:** Line 68 prose says tails do not sum cleanly statistically — correct and honest. Line 89 `validation_test` says "assert the every-frame chain stays inside the 100 ms envelope" — but **which** envelope? Measured end-to-end p99? Worst sustained-load frame? Naive per-stage p99 sum (which is 127 ms — guaranteed to fail)?

The fix is to pick one and name it. Recommended: **measured end-to-end every-frame chain p99 inside 100 ms**, since:

- It's the metric the scheduler actually has to honor.
- It implicitly bounds tail-correlation by measurement rather than theory.
- The naive per-stage p99 sum (127 ms) is *not* the right test — it would fail 100% of the time in deployments that ship.

Rewrite the cell to say "measured end-to-end every-frame chain p99 ≤ 100 ms over a sustained-load replay window of ≥ 60 s" or equivalent. Keep the "require the scheduler to skip the Role-2 tick before it skips an every-frame stage" follow-on — that's a separate scheduler-policy assertion and is fine.

### r1-c6 — Inline-restate ROS2 prerequisites for planned chapters (binding)

**Where:** lines 50 (Ch 1 §1.9 reference) and 76 (Ch 1 §1.5 reference).

**The bug:** Brief Item 6 voice rule says "re-state the minimum prerequisite knowledge inline, in 1–3 sentences with the corresponding `[[...]]` cross-reference, before using a Ch-1 or Ch-2 concept." Ch 0–4 sections are mostly `planned`, so a §5.9 reader cannot rely on them being available. The draft uses these terms with link but no local explanation:

- "Composable nodes" / "intra-process pass-through" (line 76) — needs 1 sentence: composable nodes are ROS2 components loaded into one process so callbacks share the same address space, and intra-process pass-through is the optimization that lets a publisher hand a `std::shared_ptr<PointCloud2>` directly to a subscriber in the same process without a copy.
- "Lifecycle activation" — needs 1 sentence: ROS2 lifecycle nodes have a managed `inactive → active` transition gated on configuration completeness, used here to ensure `/tf_static` is published and the parameter set is loaded before perception starts publishing.
- "Pinned deployment target" (line 50) — already wikilinks Ch 1 §1.9; add 1 sentence: the book commits to a PyTorch-training → ONNX/TensorRT-inference → C++ ROS2 node → Jetson-class edge GPU pipeline, and §5.9's illustrative numbers assume that target's CPU/GPU class.

Keep the additions tight. The section is supposed to be synthesis, not re-teaching, so 1 sentence per concept, not 3.

## What NOT to change

- The bounded-claim wording (definitions + two-tier evidence) — codex AGREED.
- The load-bearing-classical 5-item list structure — codex AGREED.
- The cadence-math ~45 ms p50 + ~20 ms sub-rate split — codex AGREED.
- The 3 failure-mode entries' identifiers and core scope — codex AGREED.
- Frontmatter (`workflow_status: reviewing` stays).
- Section ordering (bounded claim leads, runtime table follows) — codex AGREED.

## Commit message convention (post-revision)

After you write, the dispatcher will commit `wip(5/5_9_deployment_runtime): cc-writer round 2 revisions`. You don't commit; you just write the file.

## Manifest format

Return a manifest like round 1: prose word count, which critiques you addressed and where, any new open questions for the deal-loop.
