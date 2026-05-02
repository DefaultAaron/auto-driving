---
title: Next-session cue — Ch 5 Phase-4 Batch 3 dispatch checkpoint
doc_type: workflow-cue
status: pending
created: 2026-05-02
for_commit: 8dd9cc2
tags: [workflow, pilot, ch5, batch-3, checkpoint]
---

# Next-session cue — Ch 5 Phase-4 Batch 3 dispatch checkpoint

> [!warning] Freshness check before pasting
> This cue updates only at coarse checkpoints (phase / batch / session boundaries). The live workflow status lives in [[STATE|`_workflow/STATE.md`]] and updates at every WIP / AGREED commit. **Before pasting:** compare this cue's `for_commit` (`8dd9cc2`) against `git rev-parse HEAD`. If HEAD is `for_commit` exactly, or 1–2 commits ahead with only `wip(...)` between them, the cue is current. If HEAD is more commits ahead OR includes any `agreed(...)` / `plan(...)` / `chapter(...)` / `lockstep(...)` since `for_commit`, treat this cue as **stale** and use STATE.md `next_action` instead.

When the user starts a fresh Claude Code session after the Ch 5 Batch-2 close (commits up through `8dd9cc2 agreed(5/5_7_occupancy_freespace_map_roi)`), this is the first prompt to run. Paste it verbatim.

## Paste this

```
The Ch 5 pilot has reached the Batch-3 dispatch checkpoint. All 10 Batch-1 + Batch-2 drafted sections (§5.1, §5.2, §5.3, §5.4, §5.5, §5.6, §5.7, §5.8) are at Phase-5 AGREED. Batch 3 is §5.9 deployment alone — the runtime-budget synthesizer that depends on the §§5.1–5.8 budget rows now committed. Per the cue's previous Step 6, this dispatch needs explicit user approval first.

Before dispatching:

1. Read `_workflow/STATE.md` end-to-end and verify `last_known_head` matches `git rev-parse HEAD`. If they differ, trust git over STATE.md.

2. Verify infrastructure: (a) `git status --porcelain` is empty in main repo; (b) `../auto-driving-codex-worktree` is on `codex-writer-isolated`, fast-forwardable from main; if 3 untracked Batch-2 codex-writer leftovers (§5.2, §5.3, §5.5) are still in the worktree, verify they match the corresponding `wip(5/5_X_*)` commits in main, then delete them and ff-only the worktree to current main HEAD; (c) `.claude/active_writer_batch.json` does NOT exist (no stale sentinel).

3. Read `_workflow/plans/ch5_chapter_plan.md` Item 3 Batch 3 + Item 4 (§5.9 cc-writer per Rule 3a contested-framing) + Item 5 §5.9 contract (the per-stage runtime-budget table that §§5.1–5.8 each commit) + Item 9 terminology contract.

4. Confirm with the user that Batch 3 should dispatch. The pause is by design — §5.9 synthesizes per-stage runtime budgets from §§5.1–5.8, and the user may want to spot-check those rows for coherence (sensor-class assumptions, frame rates, single-vs-multi-LiDAR caveats) before dispatching the synthesizer that depends on them.

5. After user approves: write the Batch-3 sentinel listing the single assigned path (§5.9), dispatch one cc-writer with the §5.9 brief (per Item 4 Rule 3a — contested framing of "Nobody ships pure classical primary detection..." + load-bearing-classical-in-DL-stacks pedagogy + per-stage runtime synthesis from the eight committed rows). The brief should explicitly enumerate the §§5.1–5.8 rows for the writer to reconcile.

6. After §5.9 returns: copy back if codex-writer (n/a — cc-writer here writes directly to main), run §6.4 post-batch validation, remove sentinel, single `wip(5/5_9_deployment_runtime)` commit.

7. Then run Phase-5 per-section deal-loop on §5.9 alone (cc-drafted, codex CONFLICT only — no Rule 3b/3c).

8. After §5.9 reaches Phase-5 AGREED, the next natural step is Phase-4 Batch 4 (§5.10 safety & validation — depends on §§5.1–5.9 failure-mode catalog entries). Pause and tell me again before Batch 4 — same pattern as this checkpoint.

If any infrastructure check fails, stop and tell me — do not work around it.
```

## Why each piece

- **Step 1** — STATE.md recovery is the first move after `/clear`. The hook reminds; the discipline is to actually read it.
- **Step 2** — clean-state precondition per spec §6.1; the worktree leftover-cleanup is a routine post-batch hygiene step that worked cleanly between Batch 1 and Batch 2.
- **Step 3** — reloads the AGREED plan + the binding contracts §5.9 must honor. The runtime-budget contract is the section's reason for existing.
- **Step 4** — explicit user checkpoint per the previous cue's Step 6. The user may want to read §5.9's input (the eight runtime rows) before greenlighting the synthesizer.
- **Step 5** — Batch-3 dispatch. Single section, single writer, no parallelism — different from Batch 2.
- **Step 6** — post-batch protocol identical to Batch 2.
- **Step 7** — Phase-5 deal-loop with codex CONFLICT only (no Rule 3b/3c since cc-drafted). Likely fewer rounds than Batch 2 (no novel side-channel design in §5.9).
- **Step 8** — explicit hand-off before Batch 4 (§5.10 safety & validation), which depends on the chapter-wide failure-mode catalog the §§5.1–5.9 entries now populate.

## Session-end state (for reference)

- Last commit: `8dd9cc2 agreed(5/5_7_occupancy_freespace_map_roi): per-section deal-loop complete`
- Working tree: clean.
- Worktree (`../auto-driving-codex-worktree`): on `codex-writer-isolated`, currently at `e9b63ce` (was ff'd before Batch 2 dispatch); 3 codex-writer round-1 drafts (§5.2 / §5.3 / §5.5) live there as untracked files matching the `wip(5/5_X_*)` commits in main. Needs cleanup + re-ff before Batch 3 dispatch — though Batch 3 is a single cc-writer dispatch (§5.9), so the worktree re-ff is technically optional this round (cc-writer doesn't use it). Re-ff it anyway for hygiene before Batch 4 (which may or may not include codex-writer dispatch).
- Memory: no new rules established this batch; the existing `feedback_*` rules continue to apply.
- TOC + EN/ZH overviews + README + CLAUDE.md unchanged this batch.

## Batch-2 deal-loop summary (reference)

| Section | Rounds | Notes |
|---|---|---|
| §5.2 ground segmentation | 3 | codex-drafted; gemini Rule-3b NEEDS REVISION on Patchwork++ improvements (TGR / A-GLE / RNR not named) — addressed in round 1, refined in round 2. |
| §5.3 clustering | 4 | codex-drafted; gemini Rule-3b PASS. Round 2 caught Bogoslavskyi formula d1/d2 inversion; round 3 caught a follow-on range-adaptivity wording bug. |
| §5.4 object-shape fitting | 5 | cc-drafted novel content. Side-channel diagnostic fields (`extent_source`, `class_prior_source`, `yaw_confidence`, `corner_visibility`) designed across rounds 2-3; consumed by §5.5. Length compressed across rounds 3-4 from 3899 to ~3370. |
| §5.5 multi-object tracking | 4 | codex-drafted; gemini Rule-3b PASS. Round 1 codex returned only convergence marker (3 retry attempts dropped content); round 2 was first full structured critique. Frame correction was the central fix (`base_link` → `odom`); §5.4 side-channel integration; GNN+Hungarian production-default depth; AB3DMOT attribution. |
| §5.7 occupancy + ROI gating | 6 | cc-drafted contested combination. ROI/GOD boundary policy iterated across six reference points (opening thesis, line 70 framing, line 80 pseudocode comment, line 99 gating policy, line 101 "not seen" clause, line 114 survival paragraph, line 124 failure-mode cause). Length stayed at ~4150 words; codex did not block on length alone. |

## Post-pilot

After Batch 3 (§5.9) and Batch 4 (§5.10) close (all 10 drafted sections at Phase-5 AGREED), Phase 6 is the chapter voice pass — main + codex CONFLICT harmonize surface concerns only (transitions, pacing, residual voice drift). On Phase-6 AGREED, every section's `workflow_status` flips to `complete` and one `chapter(5):` commit publishes the chapter with TOC + chapter-overview lockstep updates bundled in.

Delete this file after Batch 3 dispatch finishes (the next-session cue at that point will be for Batch 4).
