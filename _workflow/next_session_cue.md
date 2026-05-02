---
title: Next-session cue — Ch 5 pilot kickoff
doc_type: workflow-cue
status: pending
created: 2026-05-02
tags: [workflow, pilot, ch5]
---

# Next-session cue — Ch 5 pilot

When the user starts a fresh Claude Code session after the writer-subagent rollout (commits `53345dd` initial snapshot + `c41b47f` lockstep + `5000c44` spec frontmatter), this is the first prompt to run. Paste it verbatim.

## Paste this

```
Start the Ch 5 (classical LiDAR detection) pilot of the writer-subagent pipeline.

1. Read `_workflow/subagents_design.md` — authoritative spec for the six-phase pipeline. Also load context from CLAUDE.md and the feedback_writer_subagents.md memory.

2. Verify infrastructure: (a) `.claude/agents/` contains cc-writer.md, codex-writer.md, codex-collaborator.md, gemini-researcher.md; (b) the worktree at `../auto-driving-codex-worktree` is on branch `codex-writer-isolated`, clean, fast-forwardable from main; (c) main repo `git status --porcelain` is empty; (d) `.claude/active_writer_batch.json` does NOT exist (no stale sentinel).

3. Run Phase 1 (research) for Ch 5: dispatch gemini-researcher and codex-collaborator (MODE: RESEARCH) in parallel with your own vault search of the Ch 5 scope (chapter overview, README §8 for the Ch 5 section count, related Ch 1 / Ch 2 prior chapters). Integrate the three streams into a single synthesis at `_workflow/research/ch5_classical_lidar_detection_synthesis.md`.

4. Stop after Phase 1 and present the synthesis for my review before entering the Phase 2 research deal-loop.

If any infrastructure check fails, stop and tell me — do not work around it.
```

## Why each piece

- **Step 1** — gives the fresh session the authoritative spec path immediately. CLAUDE.md is auto-loaded but the verbose six-phase spec lives at `_workflow/subagents_design.md`.
- **Step 2** — sanity check that the rollout commits actually persisted across the restart. Catches the case where the user is on a different branch or the worktree was deleted.
- **Step 3** — defines the actual work. Phase 1 is the autonomous research phase; deal-loop comes later.
- **Step 4** — explicit hand-off back to the user before the Phase 2 deal-loop, which is the next adversarial gate. Preserves the "never act on downstream artifacts before user explicitly approves" discipline.

## Post-pilot

Once Phase 1 completes and you've reviewed the synthesis, the natural next prompts are:
- "Run the Phase 2 research deal-loop" — main session enters CONFLICT-mode iteration with codex on what to keep / cut from the synthesis, and on any structural proposals codex raises.
- After Phase 2 AGREED: "Run Phase 3 — draft the 11-item chapter plan + allocation." Main produces the plan; codex CONFLICT reviews all 11 items.
- After Phase 3 AGREED: "Begin Phase 4 drafting." Main builds section briefs, runs the clean-state precondition, writes the batch sentinel, dispatches writers in parallel.

Delete this file after the pilot finishes (or move to `_workflow/archive/`).
