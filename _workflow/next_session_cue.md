---
title: Next-session cue — Ch 6 (Deep-Learning LiDAR Detection) Phase 1 research start
doc_type: workflow-cue
status: pending
created: 2026-05-03
for_commit: 611fd3f
tags: [workflow, ch6, phase-1, research]
---

# Next-session cue — Ch 6 Phase 1 research start

> [!warning] Freshness check before pasting
> This cue updates only at coarse checkpoints (phase / batch / chapter boundaries). The live workflow status lives in [[STATE|`_workflow/STATE.md`]] and updates at every WIP / AGREED commit. **Before pasting:** compare this cue's `for_commit` (`611fd3f`) against `git rev-parse HEAD`. If HEAD is `for_commit` exactly, or 1–2 commits ahead with only `wip(...)` between them, the cue is current. If HEAD is more commits ahead OR includes any `agreed(...)` / `plan(...)` / `chapter(...)` / `lockstep(...)` since `for_commit`, treat this cue as **stale** and use STATE.md `next_action` instead.

When the user starts a fresh Claude Code session after the Ch 5 extension close (`611fd3f chapter(5): Classical LiDAR Detection — extension complete`), this is the first prompt to run. Paste it verbatim.

## Paste this

```
Ch 5 is complete (original close + round-W extension run; ~30k → ~50.8k EN words; 10 sections at workflow_status: complete; codex worktree clean and ff'd to current main HEAD). Ready to start Chapter 6 — Deep-Learning LiDAR Detection — at Phase 1 (research).

Before dispatching:

1. Read `_workflow/STATE.md` end-to-end and verify `last_known_head` matches `git rev-parse HEAD`. If they differ, trust git over STATE.md.

2. Verify infrastructure: (a) `git status --porcelain` empty in main repo; (b) codex worktree at `../auto-driving-codex-worktree` clean and ff'd to current main HEAD; (c) `.claude/active_writer_batch.json` does NOT exist (no stale sentinel).

3. Read the Ch 6 specification:
   - `00_table_of_contents.md` Ch 6 entries — section list + handoff context.
   - `_workflow/plans/ch5_chapter_plan.md` Item 11 "Downstream commitments" Ch 6 — what Ch 6 inherits from Ch 5 (the five canonical representations; classical pipeline as DL displacement baseline; failure-mode catalog inheritance; load-bearing-classical-in-DL-stacks list).
   - `chapter_5_classical_lidar_detection/5_9_deployment_runtime_EN.md` for the bounded "Nobody ships pure classical primary detection..." claim that Ch 6 supports + Ch 6's hybrid learned-classical interfaces caveat (per §5.9 round-1 codex e1-c6).
   - Memory: `feedback_section_depth_standard.md` (five-block standard applies forward to Ch 6+); `feedback_billing_constraint_writer_allocation.md` (round-W all-codex allocation default); `feedback_writer_subagents.md` (writer pipeline rules).

4. **Phase 1 — Research:** dispatch three streams in parallel:
   - Main session research (this Claude Code session) on Ch 6 topics: PointNet / PointNet++ / DGCNN; VoxelNet / SECOND / PointPillars; CenterPoint + anchor-free 3D; Transformer-based 3D (3DETR, BEVFormer, etc.); evaluation metrics (3D mAP / NDS / KITTI); deployment (TensorRT / ONNX / Jetson); safety + validation.
   - `codex-collaborator` MODE: RESEARCH on the same topics in parallel.
   - `gemini-researcher` on the same topics, in parallel.
   - Integrate the three streams into `_workflow/research/ch6_dl_lidar_detection_synthesis.md`.

5. **Phase 2 — Research deal-loop:** main + codex CONFLICT iterate on the synthesis to AGREED. Codex may propose structural changes (e.g., insertion of a section, renumbering); proposed-not-adopted; user approves before lockstep update.

6. **Phase 3 — Chapter plan + allocation deal-loop:** main session drafts the 11-item Ch 6 chapter plan; codex CONFLICT reviews. Under round-W, writer allocation defaults to all-codex with the five safeguards (protected framing spans, synthesis-section terminal audit, user-approval-gated cc escape, framing-preservation Path B 5th axis, no section-specific deterministic rules). The Phase-3 plan still classifies sections that would have been cc under original Rule 3a (synthesis / theoretically-loaded / contested-framing) because that classification sets the protected-framing-spans rationale.

7. **Phase 4 onward:** drafting under round-W rules (all-codex by default; five-block per algorithm + visual artifact discipline binding from the start; no separate "extension" phase — the depth standard applies at Phase-4 drafting).

If any infrastructure check fails, stop and tell me — do not work around it.
```

## Why each piece

- **Step 1** — STATE.md recovery is the first move after `/clear`. The hook reminds; the discipline is to actually read it.
- **Step 2** — clean-state precondition per spec §6.1; worktree ff is hygiene.
- **Step 3** — reloads the Ch 5 → Ch 6 inheritance contract (the load-bearing-classical-in-DL list is the spine of Ch 6's relationship to Ch 5).
- **Step 4** — Phase 1 three-stream parallel research is the existing per-chapter pipeline pattern.
- **Step 5** — Phase 2 deal-loop is where structural changes get adjudicated (whether Ch 6 needs section insertion / renumbering / scope adjustment).
- **Step 6** — Phase 3 chapter plan locks scope + writer allocation. Round-W defaults apply.
- **Step 7** — Phase 4 drafting + Phase 5 deal-loops + Phase 6 voice pass run as standard.

## Session-end state (for reference)

- Last commit: `611fd3f chapter(5): Classical LiDAR Detection — extension complete; ~30k → ~57k EN words`.
- Working tree: clean.
- Worktree (`../auto-driving-codex-worktree`): on `codex-writer-isolated`, ff'd to `611fd3f`. Clean.
- Memory: round-W rules stable; five-block depth standard stable; writer-allocation rules stable.
- TOC + EN/ZH overviews + README + CLAUDE.md unchanged this turn (they were lockstep-updated at the round-W reallocation commit `a8255c9` and the chapter(5) extension close `611fd3f`).

## Ch 6 outline (from chapter plan)

| § | Title |
|---|---|
| 6.0 | Overview |
| 6.1 | PointNet / PointNet++ |
| 6.2 | VoxelNet / SECOND |
| 6.3 | PointPillars |
| 6.4 | CenterPoint & anchor-free 3D detection |
| 6.5 | Transformer-based 3D detectors |
| 6.6 | Eval metrics for 3D detection |
| 6.7 | Deployment |
| 6.8 | Safety & validation (template instance) |

Ch 6 will likely follow the Ch 5 pattern: research → research deal-loop → chapter plan → drafting batches → per-section deal-loops → voice pass → chapter close.

## Post-Ch-6 outlook

- ZH translations of Ch 5 deferred until at least Ch 6 is underway (per the original chapter-close convention; ZH phase is post-EN-completion).
- Ch 7 (camera+LiDAR fusion) inherits Ch 5 + Ch 6 as the two perception inputs.
- Memory + chapter plan + CLAUDE.md + README stay stable unless Ch 6 surfaces a workflow change.
