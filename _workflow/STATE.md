---
title: Workflow state snapshot
doc_type: state-snapshot
state_kind: manual_snapshot
last_updated: 2026-05-03T23:30:00.000Z
last_checked_commit: 611fd3f
generated_from: main_session
---

# Workflow state snapshot

> [!warning] NOT a source of truth
> This file is a fast-recovery snapshot for resuming work after `/compact` or `/clear`. Verify against `git log` and section-file frontmatter before acting on anything below. Mechanical fields (`last_updated`, `last_checked_commit`, `last_known_head`, `worktree_status`, `active_batch_sentinel`) are auto-refreshed by `.claude/hooks/snapshot_state.mjs` on `PreCompact`. Reasoning fields below are manually maintained by main session at each AGREED commit, each WIP commit, and at session end.

## Mechanical state (auto-refreshed by PreCompact hook)

- last_known_head: `611fd3f`
- worktree_status: clean (main: clean; codex worktree: clean, ff'd to main HEAD `611fd3f`)
- active_batch_sentinel: null

## Reasoning state (main session updates manually)

- active_chapter: **Chapter 5 EXTENSION COMPLETE**; next is Chapter 6 (Deep-Learning LiDAR Detection)
- active_phase: between chapters; ready to start Ch 6 Phase 1 (research)
- active_batch: none
- last_agreed_commit: `611fd3f chapter(5): Classical LiDAR Detection — extension complete; ~30k -> ~57k EN words`
- next_action: **Chapter 5 fully complete after extension run.** Original chapter close was `94827f4` at ~30k EN words; round-W extension run completed at `611fd3f` with ~50.8k EN words (1.69× expansion). All 10 drafted sections (§§5.1–5.10) at `workflow_status: complete`; §5.0 overview also `complete`. TOC carries the extended state. Chapter plan Items 1/4/6 lockstep updated (length bands, round-W writer reallocation override, five-block + visual artifact discipline). The codex worktree is clean and ff'd to `611fd3f`. **Ready to start Ch 6 (Deep-Learning LiDAR Detection) Phase 1 research.** Ch 6 spec from chapter plan: PointNet/++, VoxelNet/SECOND, PointPillars, CenterPoint + anchor-free 3D, Transformer-based 3D, eval metrics, deployment, safety. Ch 6 inherits Ch 5's failure-mode catalog (most entries survive structurally; some shift cause-class), the five canonical representations (raw / voxel / OctoMap / range image / BEV), and the load-bearing-classical-in-DL-stacks list (preprocessing, ground seg as CNN front-end, tracking, GOD/occupancy fallback, HD-map ROI gating). Ch 6 will be drafted under round-W all-codex allocation + five-block depth standard from the start (no separate "extension" phase needed — the round-W rules apply at Phase-4 drafting).

### Extension run summary (round-W, 2026-05-03)

- All 10 sections drafted by codex-writer; 0 cc-writer dispatches across the run; Rule 3d escape never triggered.
- 5 gemini Rule 3b factual spot-checks (sensor specs §5.3; Zhang authors + formulas §5.4; AB3DMOT 10D state §5.5; Chen-Medioni + GICP §5.6; Autoware compare_map_segmentation §5.7).
- §5.10 frozen-during-extensions discipline + change-log mechanism prevented drift cascade as designed; terminal audit at `7e5a3ad` PASSED with zero proposed changes.
- 4 main-direct writer-overhead fixes; 1 writer-unavailable-contingency (§5.7 Apollo softening when codex-writer rate-limited).
- §5.1 t_point convention micro-revision aligned to §5.8 chapter-canonical end-of-scan / non-negative-Δt convention.
- Phase-6 voice pass AGREED in 2 rounds (intra-Ch-5 wikilink normalization, §5.1.x renumber, §5.9 GOD compression, Deskew-heading capitalization CONTESTED + conceded).
- Production-claim narrowing across §§5.2/5.4/5.5/5.6/5.7/5.9 consistent with the round-W §5.2 e1-c1 precedent.
- Hybrid learned-classical caveats added in §5.5 + §5.9.

### open_conflict_threads

(none — Phase-6 chapter voice pass AGREED in 3 rounds; no in-flight CONFLICT threads)

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
- Codex worktree at `../auto-driving-codex-worktree` is on branch `codex-writer-isolated`, currently at `55d2c32` (ff'd from `32884a9` before §5.9 dispatch); behind main HEAD since the Ch 5 §5.9 + §5.10 deal-loops + Phase-6 voice pass + chapter-close commit all ran on main without codex-writer involvement (Ch 5 had no codex-drafted sections in Batch 3 + Batch 4). Ff to main before any Ch 6 codex-writer dispatch.
- **Ch 5 §5.10 (Batch 4) close** — Phase-4 brief deal-loop with codex-collaborator AGREED in 5 rounds at commit `8135022` (round 1: 6 critiques on catalog ownership / 600-word budget / source-of-truth / mAP wording / taxonomy / Ch 11 boundary; rounds 2–5 closed remaining arithmetic / bucket-rule / stale-text issues). cc-writer round 1 draft at `d3e638b`; round 2 cc-writer revision at `a41cd2d` after codex round-1 critique listed 6 defects (mAP overclaim×2 / `5_7.fm.map_suppresses_real_actor` bucket misplacement / `GOD` terminology drift / 91-word length overage / cell-cap violation). Per-section AGREED at `e0bddc1`.
- **Ch 5 Phase-6 voice pass close** — round 1 codex returned 6 surface critiques at the 4-files-touched scope (terminology drift `GOD`/`freespace`, wikilink display rule, §5.7 over-long opener, §5.5 dense paragraph, §5.10 row/count consistency); main session contested `p6-c3` with category `pedagogically-worse` and codex conceded; resulting plan: 2 main-direct: writer-overhead fixes + 3 cc-writer fixes + chapter-plan rule clarification at commit `ca7133a`. Round 2 codex caught 2 remaining `GOD` instances main missed in §5.7:119 + 5_7.fm.map_suppresses_real_actor cause cell. Round 3 AGREED.
- **§5.10 length-band update** — Phase-3 plan Item 1 §5.10 cell updated from "1000–1800" → "2000–2200" to match the brief's relaxed band (catalog index workload was not foreseeable when the chapter plan was drafted). Lockstep applied in chapter-close commit.
- **Wikilink rule clarification** — Phase-3 plan Item 6 voice rule updated: cross-chapter wikilinks display as `Ch N §N.M`; intra-chapter wikilinks may display as bare `§N.M` because chapter context is implicit. Existing wikilinks unchanged. This was the codex-conceded `p6-c3` outcome.
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
