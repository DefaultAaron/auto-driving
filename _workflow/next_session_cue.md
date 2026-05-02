---
title: Next-session cue — Ch 5 Phase-4 Batch 2 dispatch
doc_type: workflow-cue
status: pending
created: 2026-05-02
for_commit: d3a24eb
tags: [workflow, pilot, ch5, batch-2]
---

# Next-session cue — Ch 5 Phase-4 Batch 2 dispatch

> [!warning] Freshness check before pasting
> This cue updates only at coarse checkpoints (phase / batch / session boundaries). The live workflow status lives in [[STATE|`_workflow/STATE.md`]] and updates at every WIP / AGREED commit. **Before pasting:** compare this cue's `for_commit` (`d3a24eb`) against `git rev-parse HEAD`. If HEAD is `for_commit` exactly, or 1–2 commits ahead with only `wip(...)` between them, the cue is current. If HEAD is more commits ahead OR includes any `agreed(...)` / `plan(...)` / `chapter(...)` / `lockstep(...)` since `for_commit`, treat this cue as **stale** and use STATE.md `next_action` instead.

When the user starts a fresh Claude Code session after the Ch 5 Batch-1 close (commits up through `96d782a agreed(5/5_8_ros2_integration)`) and the STATE.md / hooks lockstep at `d3a24eb`, this is the first prompt to run. Paste it verbatim.

## Paste this

```
Continue the Ch 5 pilot. Phase-4 Batch 1 is fully Phase-5-AGREED (§5.1 / §5.6 / §5.8). Batch 2 dispatch is the next step.

1. Read `_workflow/plans/ch5_chapter_plan.md` Item 3 Batch 2 + Item 4 writer assignments + Item 5 handoff contracts (frozen, not predecessor drafts). Also reload context: CLAUDE.md, the feedback memories (especially feedback_user_role_in_phases.md = codex AGREED is the decision; no human review required; no open questions left for user), and the §5.1 / §5.6 / §5.8 AGREED drafts for style anchor.

2. Verify infrastructure: (a) `git status --porcelain` is empty in main repo; (b) `../auto-driving-codex-worktree` is on `codex-writer-isolated`, clean, fast-forwardable from main (and run the ff-only); (c) `.claude/active_writer_batch.json` does NOT exist (no stale sentinel).

3. Write the Batch-2 sentinel listing the 5 assigned paths (§5.2, §5.3, §5.4, §5.5, §5.7) and dispatch all 5 writers in a single message in parallel:
   - codex-writer → §5.2 (ground segmentation)
   - codex-writer → §5.3 (clustering)
   - cc-writer    → §5.4 (object-shape fitting — novel content per Rule 3a)
   - codex-writer → §5.5 (multi-object tracking)
   - cc-writer    → §5.7 (occupancy + map-aided ROI gating — novel combination per Rule 3a)

   Briefs follow the §5.1 / §5.6 / §5.8 brief template (chapter context, scope, frozen handoff contract from the plan, voice rules, terminology contract, runtime-budget row contract, failure-mode catalog contract, path constraint, return manifest).

4. After all 5 return: copy 3 codex-writer outputs back from worktree, run §6.4 post-batch validation, remove sentinel, 5 `wip(5/...)` commits.

5. Then run Phase-5 per-section deal-loops for each. For codex-drafted sections (§5.2, §5.3, §5.5): run codex CONFLICT + gemini factual spot-check (Rule 3b) + main-session Rule 3c codex-bias checklist. For cc-drafted sections (§5.4, §5.7): codex CONFLICT only.

6. After all 5 reach Phase-5 AGREED, the next natural step is Phase-4 Batch 3 (§5.9 deployment alone — depends on §§5.1–5.8 budget rows) — pause and tell me before dispatching Batch 3.

If any infrastructure check fails (worktree not ff-able, dirty main repo, stale sentinel), stop and tell me — do not work around it.
```

## Why each piece

- **Step 1** — reloads the AGREED plan, AGREED memory rules, and the three AGREED drafts that set the chapter's style anchor.
- **Step 2** — clean-state precondition per spec §6.1; without it the post-batch validation can collide.
- **Step 3** — the Batch-2 dispatch itself. 5 writers in parallel is the maximum parallelism in the chapter plan's DAG; later batches are smaller.
- **Step 4** — applies the post-batch protocol that worked cleanly in Batch 1.
- **Step 5** — Phase-5 sub-loops with the Rule-3b/3c discipline already proven in Batch 1.
- **Step 6** — explicit hand-off before Batch 3 because §5.9 (deployment) depends on the §§5.2–5.7 runtime-budget rows that Batch 2 publishes; verifying those rows are coherent before §5.9 dispatches is worth a checkpoint.

## Session-end state (for reference)

- Last commit: `96d782a agreed(5/5_8_ros2_integration): per-section deal-loop complete`
- Working tree: clean.
- Worktree (`../auto-driving-codex-worktree`): on `codex-writer-isolated`, clean, currently behind main by 5 commits (the 3 Batch-1 wip + 3 agreed + 1 lockstep). Will need ff-only at session start.
- Memory: `feedback_user_role_in_phases.md` (codex-AGREED-is-decision rule) and `reference_zh_filename_convention.md` (Chinese filename slugs for `_ZH.md`) both indexed in `MEMORY.md`.
- TOC + EN/ZH overviews + README §2 reflect the §5.4 insertion + §5.7 rename + Chinese ZH overview filenames.

## Post-pilot

After Batches 2 and 3 close (all 10 drafted sections at Phase-5 AGREED), Phase 6 is the chapter voice pass — main + codex CONFLICT harmonize surface concerns only (transitions, pacing, residual voice drift). On Phase-6 AGREED, every section's `workflow_status` flips to `complete` and one `chapter(5):` commit publishes the chapter with TOC + chapter-overview lockstep updates bundled in.

Delete this file after Batch 2 dispatch finishes (or move to `_workflow/archive/`).
