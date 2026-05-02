---
title: Next-session cue — Ch 5 Phase-4 Batch 4 dispatch checkpoint
doc_type: workflow-cue
status: pending
created: 2026-05-02
for_commit: f7f5bd7
tags: [workflow, pilot, ch5, batch-4, checkpoint]
---

# Next-session cue — Ch 5 Phase-4 Batch 4 dispatch checkpoint

> [!warning] Freshness check before pasting
> This cue updates only at coarse checkpoints (phase / batch / session boundaries). The live workflow status lives in [[STATE|`_workflow/STATE.md`]] and updates at every WIP / AGREED commit. **Before pasting:** compare this cue's `for_commit` (`f7f5bd7`) against `git rev-parse HEAD`. If HEAD is `for_commit` exactly, or 1–2 commits ahead with only `wip(...)` between them, the cue is current. If HEAD is more commits ahead OR includes any `agreed(...)` / `plan(...)` / `chapter(...)` / `lockstep(...)` since `for_commit`, treat this cue as **stale** and use STATE.md `next_action` instead.

When the user starts a fresh Claude Code session after the Ch 5 Batch-3 close (commits up through `f7f5bd7 agreed(5/5_9_deployment_runtime)`), this is the first prompt to run. Paste it verbatim.

> [!important] Phase-5 discipline applies — same as Batch 3
> Batch 4 forward continues under the new Phase-5 discipline established in commit `69e2d6e`: Phase-5 revisions default to re-dispatching the original writer (cc-writer or codex-writer) wrapped in a one-section revision sentinel; main-direct edits require `main-direct: minor / adjudication / writer-overhead` commit tags; convergence is bidirectional (main may `CONTESTED: <critique-id> — <category>: <one-line>` push back); Rule 3b/3c/3d updated. Batch-3 §5.9 deal-loop demonstrated this in practice — round 1 multi-axis revisions went to cc-writer re-dispatch, round 2 single-sentence wording fix went `main-direct: minor`. See `_workflow/subagents_design.md` Phase 5 + §8.1 + §5 Rules 3a–3d, `CLAUDE.md` "Subagents and the per-chapter pipeline" section, and the memory file `feedback_phase5_revisions.md` for the full rule set.

## Paste this

```
The Ch 5 pilot has reached the Batch-4 dispatch checkpoint. All 9 Batch-1+2+3 drafted sections (§§5.1–5.9) are at Phase-5 AGREED. Batch 4 is §5.10 alone — the chapter-wide safety / validation synthesizer that depends on the §§5.1–5.9 failure-mode catalog entries now committed. Per the same pattern as Batch 3, this dispatch needs explicit user approval first.

Before dispatching:

1. Read `_workflow/STATE.md` end-to-end and verify `last_known_head` matches `git rev-parse HEAD`. If they differ, trust git over STATE.md.

2. Verify infrastructure: (a) `git status --porcelain` is empty in main repo; (b) `../auto-driving-codex-worktree` is on `codex-writer-isolated`, currently at `55d2c32` (~3 commits behind main HEAD `f7f5bd7`); ff-only the worktree to current main HEAD for hygiene before Batch 4 (`cd ../auto-driving-codex-worktree && git merge --ff-only main`); (c) `.claude/active_writer_batch.json` does NOT exist (no stale sentinel).

3. Read `_workflow/plans/ch5_chapter_plan.md` Item 1 §5.10 row + Item 4 §5.10 (cc-writer per Rule 3a high-judgment synthesis) + Item 5 §5.10 contract (the per-section failure-mode catalog row schema + cross-section `5_cross.fm.*` IDs that §5.10 owns) + Item 9 terminology contract.

4. Build the §5.10 brief like the §5.9 brief — drawn from the AGREED Phase-3 plan + the 27 per-section failure-mode entries (already enumerated in `_workflow/briefs/ch5_5_9_deployment_runtime_brief.md`) + the 3 §5.9 chapter-wide entries (`5_9.fm.frame_budget_overrun_p99`, `5_cross.fm.subrate_registration_starves_under_load`, `5_cross.fm.sensor_class_mismatch_at_deploy`) + any cross-section `5_cross.fm.*` IDs §5.10 owns. Codex CONFLICT brief review → AGREED before dispatching cc-writer.

5. After brief AGREED: write the Batch-4 sentinel listing the single assigned path (§5.10), dispatch one cc-writer with the §5.10 brief. The brief should explicitly enumerate all 30 failure-mode entries (27 per-section + 3 §5.9 chapter-wide) for §5.10 to integrate.

6. After §5.10 returns: run §6.4 post-batch validation, remove sentinel, single `wip(5/5_10_safety_and_validation)` commit.

7. Then run Phase-5 per-section deal-loop on §5.10 alone (cc-drafted, codex CONFLICT only — no Rule 3b/3c since cc-drafted). Use the §5.9 Phase-5 pattern: re-dispatch cc-writer for non-trivial multi-axis revisions; main-direct minor only for single-sentence/wording/typo/terminology fixes; CONTESTED: pushback if critique is wrong.

8. After §5.10 reaches Phase-5 AGREED, the chapter is fully drafted (10 of 10 sections at Phase-5 AGREED). Next is **Phase 6 — chapter voice pass** (terminal): main + codex CONFLICT harmonize surface concerns only (transitions, pacing, residual voice drift). On Phase-6 AGREED, every section's `workflow_status` flips to `complete` and one `chapter(5):` commit publishes the chapter with TOC + chapter-overview lockstep updates bundled in.

If any infrastructure check fails, stop and tell me — do not work around it.
```

## Why each piece

- **Step 1** — STATE.md recovery is the first move after `/clear`. The hook reminds; the discipline is to actually read it.
- **Step 2** — clean-state precondition per spec §6.1; worktree ff is hygiene. cc-writer doesn't use the worktree, but it's clean discipline before any future codex-writer dispatch.
- **Step 3** — reloads the AGREED plan + the binding contracts §5.10 must honor (failure-mode schema + cross-section ownership).
- **Step 4** — the Phase-4 brief deal-loop step established in Batch 3. Batch 3 demonstrated this catches multi-axis brief defects before they propagate into the draft (saved one round of cc-writer dispatch).
- **Step 5** — Batch-4 dispatch. Single section, single writer, no parallelism — same shape as Batch 3.
- **Step 6** — post-batch protocol identical to Batch 3.
- **Step 7** — Phase-5 deal-loop. §5.9 took 3 rounds (round 1 cc-writer re-dispatch on 6 critiques, round 2 main-direct minor on 1 critique, round 3 AGREED). §5.10 likely similar; high-judgment synthesis may need an extra round if the failure-mode integration triggers structural disagreement.
- **Step 8** — Phase 6 entry. The chapter is at 10/10 sections AGREED; all that remains is voice harmonization. No structural rewrites at Phase 6 — kicks back to Phase 5 if needed.

## Session-end state (for reference)

- Last commit: `f7f5bd7 agreed(5/5_9_deployment_runtime): per-section deal-loop complete`
- Working tree: clean.
- Worktree (`../auto-driving-codex-worktree`): on `codex-writer-isolated`, currently at `55d2c32` (was at `32884a9`; ff'd before Batch 3 dispatch after deleting 3 stale Batch-2 leftover files verified byte-identical to round-1 wip commits). Now ~3 commits behind main HEAD; ff to main before any Batch 4 codex-writer dispatch (cc-writer alone for §5.10, so technically optional this round).
- Memory: no new rules established this batch. The §5.9 deal-loop validated the Phase-5 discipline working as designed (cc-writer re-dispatch caught the multi-axis revision; main-direct minor caught the single-sentence factual fix).
- TOC + EN/ZH overviews + README + CLAUDE.md unchanged this batch.

## Batch-3 deal-loop summary (reference)

| Section | Phase-4 brief rounds | Phase-5 deal-loop rounds | Notes |
|---|---|---|---|
| §5.9 deployment & runtime | 2 | 3 | cc-drafted contested framing. Phase-4 brief had 6 critiques (cadence math / p99 / forward-contract redundancy / terminology / structure / length-budgets) — saved one cc-writer dispatch. Phase-5 round-1 6 critiques applied via cc-writer one-section sentinel; round-2 single critique applied via main-direct minor; round-3 AGREED. Brief artifacts at `_workflow/briefs/ch5_5_9_*.md`. |

## Post-pilot

After Batch 4 (§5.10) closes (all 10 drafted sections at Phase-5 AGREED), Phase 6 is the chapter voice pass — main + codex CONFLICT harmonize surface concerns only (transitions, pacing, residual voice drift). On Phase-6 AGREED, every section's `workflow_status` flips to `complete` and one `chapter(5):` commit publishes the chapter with TOC + chapter-overview lockstep updates bundled in.

Delete this file after Batch 4 dispatch finishes (the next-session cue at that point will be for Phase 6 chapter voice pass).
