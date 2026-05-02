---
title: Workflow state snapshot
doc_type: state-snapshot
state_kind: manual_snapshot
last_updated: 2026-05-02T22:00:00.000Z
last_checked_commit: f7f5bd7
generated_from: main_session
---

# Workflow state snapshot

> [!warning] NOT a source of truth
> This file is a fast-recovery snapshot for resuming work after `/compact` or `/clear`. Verify against `git log` and section-file frontmatter before acting on anything below. Mechanical fields (`last_updated`, `last_checked_commit`, `last_known_head`, `worktree_status`, `active_batch_sentinel`) are auto-refreshed by `.claude/hooks/snapshot_state.mjs` on `PreCompact`. Reasoning fields below are manually maintained by main session at each AGREED commit, each WIP commit, and at session end.

## Mechanical state (auto-refreshed by PreCompact hook)

- last_known_head: `f7f5bd7`
- worktree_status: clean (main: clean; codex worktree: clean and ff'd to `55d2c32` — was at `32884a9` with 3 stale Batch-2 leftovers, cleaned + ff'd before §5.9 cc-writer dispatch; behind main HEAD by ~3 commits since the Batch-3 deal-loop ran on main)
- active_batch_sentinel: null

## Reasoning state (main session updates manually)

- active_chapter: 5 (Classical LiDAR Detection)
- active_phase: 4 (per-section drafting); Batch 1 closed; Batch 2 closed; **Batch 3 closed** — §5.9 at Phase-5 AGREED in 3 rounds. Batch 4 (§5.10 safety synthesis alone) pending dispatch, awaiting user checkpoint.
- active_batch: none — Batch 3 just closed
- last_agreed_commit: `f7f5bd7` — `agreed(5/5_9_deployment_runtime): per-section deal-loop complete`
- next_action: All 9 Batch-1+2+3 sections (§§5.1–5.9) at Phase-5 AGREED. Next is Batch 4 (§5.10 safety synthesis — depends on the §§5.1–5.9 failure-mode catalog entries now all populated). §5.10 was classified cc-writer at Phase 3 (high-judgment synthesis); per new Rule 3a (codex-default, allocation locked at Phase 3, no mid-run fallback), §5.10 stays cc-writer. **Batch 4 runs under the new post-2026-05-02 workflow rules:** Phase 5 asymmetric (cc-drafted §5.10 → Path A bidirectional with codex-collaborator every round; existing pattern); all section-content writes through writers (drafts AND revisions); only `main-direct: writer-overhead` survives narrow definition (spelling, dup word, broken Markdown, format artifact — no semantic change); `main-direct: minor` and `main-direct: adjudication` deprecated. Path A means §5.10 looks much like Ch 5 prior cc-drafted sections (§§5.4, 5.6, 5.7, 5.9). Infrastructure check before dispatch: clean main, no stale sentinel, optional worktree ff (cc-writer doesn't use worktree, optional this round). The first measurable codex-drafted section under the new Path B rules will be in a future chapter (Ch 5 has no remaining codex-drafted sections).

### open_conflict_threads

(none — all 5 Batch-2 deal-loops closed at AGREED; no in-flight CONFLICT threads)

### blocked_user_inputs

(none — per `feedback_user_role_in_phases.md`, codex AGREED is the decision; the only thing pending user input is the Batch 3 dispatch checkpoint, which is a workflow checkpoint, not a content decision)

### do_not_redo

Short bullets of completed work that is not obvious from `next_action` or the latest commit subject. Used so a resumed session does not re-litigate.

- Phase 1 research synthesis at `_workflow/research/ch5_classical_lidar_detection_synthesis.md` — Phase 2 AGREED at commit `f32e0a4`. Two structural decisions (insert §5.4, rename §5.7) bundled and lockstep-applied.
- Lockstep §5.4 insertion + §5.7 rename — applied at commit `8653e90` (TOC + EN/ZH overviews + README + CLAUDE.md cross-cutting threads).
- Phase 3 chapter plan at `_workflow/plans/ch5_chapter_plan.md` — AGREED at commit `e9b63ce`. 11-section chapter, 4 batches, 5cc:5codex writer ratio.
- ZH filename convention — Chinese slugs for `_ZH.md` overviews — applied at commit `ec5ad8b`. README §2 + memory `reference_zh_filename_convention.md` + 13 file renames + 93 wikilink rewrites.
- Ch 5 Phase-4 **Batch 1** drafts (§5.1, §5.6, §5.8) — Phase 5 AGREED at commits `6392e15`, `f29f2ba`, `96d782a`. cc-writer drafted §5.6; codex-writer drafted §5.1 and §5.8 (each got Rule 3b gemini factual spot-check + Rule 3c codex-bias checklist).
- Ch 5 Phase-4 **Batch 2** drafts (§5.2, §5.3, §5.4, §5.5, §5.7) — Phase 5 AGREED at commits `5046122`, `acd529b`, `0ccaf75`, `d99806a`, `8dd9cc2`. cc-writer drafted §5.4 + §5.7; codex-writer drafted §5.2, §5.3, §5.5 (each got Rule 3b gemini factual spot-check — §5.2 needed Patchwork++ revision, §5.3 + §5.5 PASS — and Rule 3c codex-bias checklist). Deal-loop rounds: §5.2 (3), §5.3 (4), §5.4 (5), §5.5 (4), §5.7 (6). §5.4 / §5.7 needed extra rounds because of contract-side-channel design (§5.4 / §5.5 contract: `extent_source`, `class_prior_source`, `yaw_confidence`, `corner_visibility` ride alongside the binding tuple) and ROI/GOD-boundary policy consistency across §5.7's six reference points.
- Ch 5 Phase-4 **Batch 3** draft (§5.9 deployment & runtime) — Phase 5 AGREED at commit `f7f5bd7` in 3 rounds. cc-drafted (Rule 3a contested framing). Phase-4 brief deal-loop ran first (codex round 1: 6 critiques on cadence math / p99 / forward-contract redundancy / terminology / structure / length-budgets; codex round 2: AGREED). Phase-5 round 1: 6 codex critiques (frame-rate/period conflation, production-default overclaim, padded passages, terminology drift, p99 validation_test envelope, missing inline ROS2 prereqs) — applied via cc-writer one-section revision sentinel (round 2). Phase-5 round 2: 1 critique (r2-c1 field-robustness opener wrong: low light does not directly degrade LiDAR returns) — applied via main-direct minor (single-sentence wording fix). Round 3: AGREED. Brief artifacts at `_workflow/briefs/ch5_5_9_deployment_runtime_brief.md` + `_workflow/briefs/ch5_5_9_revision_round_2.md`.
- Codex worktree at `../auto-driving-codex-worktree` is on branch `codex-writer-isolated`, currently at `55d2c32` (ff'd from `32884a9` before §5.9 dispatch; 3 stale Batch-2 leftover files were verified byte-identical to round-1 wip commits, deleted, then ff'd via `git merge --ff-only main`); now ~3 commits behind main HEAD `f7f5bd7` since the §5.9 deal-loop ran on main.
- Memory rules established earlier: `feedback_user_role_in_phases.md` (codex AGREED is the decision; no human review; no open questions for user), `reference_zh_filename_convention.md` (Chinese slugs for `_ZH.md` files), `feedback_state_md_discipline.md` (STATE.md is fast-recovery snapshot, NOT source of truth).
- **Phase-5 discipline update at `69e2d6e`** — codex-collaborator + main-session AGREED on three changes after Batch 2 surfaced an enforcement gap: (1) Phase-5 revisions default to re-dispatching the original writer (cc-writer or codex-writer), with a one-section revision sentinel and `main-direct: minor / adjudication / writer-overhead` audit tags for direct edits; (2) bidirectional convergence — main may push back via `CONTESTED: <critique-id> — <category>: <one-line>` with closed-list categories `already-satisfied / technically-wrong / pedagogically-worse / out-of-scope / over-budget / chapter-context`; (3) Rule 3b risk-based rerun, Rule 3c per-substantial-revision, new Rule 3d for round-4+ codex-only editorial loops. New memory file `feedback_phase5_revisions.md` carries the concise rule list. Applies to Batch 3 forward; Batch 2 commits stay as historical record.

## Recovery checklist after `/clear` or `/compact`

1. Read this file (`_workflow/STATE.md`) end-to-end.
2. Verify `last_known_head` matches `git rev-parse HEAD` in the main repo. If they differ, the snapshot is stale; trust git over STATE.md.
3. Read `CLAUDE.md` and the indexed memory files (`MEMORY.md` lists them).
4. Read `next_action` above; cross-check it against the latest commits via `git log --oneline -10`.
5. If `active_batch_sentinel` is non-null, a writer batch is in flight — do NOT dispatch a new batch; first read the sentinel and check both repos for in-scope vs out-of-scope writes per spec §6.4.
6. If `open_conflict_threads` is non-empty, a CONFLICT loop is mid-iteration — resume that thread with `RESUME: true` before starting any new work.
7. If `_workflow/next_session_cue.md` exists, compare its `for_commit` to current HEAD: if HEAD == `for_commit`, or 1–2 commits ahead with only `wip(...)` between them, the cue is current and safe to paste; otherwise the cue is **stale** and STATE.md `next_action` is authoritative.
