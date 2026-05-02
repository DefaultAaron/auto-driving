# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository type

This is an **Obsidian vault** used to write a **book-style learning resource on autonomous driving**. There is no build system, package manager, or test suite. Content is Markdown notes (`.md`), Canvas files (`.canvas`), and Bases (`.base`) authored for the Obsidian app.

Treat new files as long-form pedagogical writing for the user, not source code.

## Book goal and scope

A **comprehensive pedagogical guide for mastering autonomous driving** — fundamentals plus current novel work. **Not project-driven**: the mingtai traffic-light project at `~/Documents/Projects/mingtai/traffic-light` is a *worked example* used where useful, not the structural spine.

**Canonical 13-chapter outline** (full section list in `README.md` and `00_table_of_contents.md`):

0. Book overview
1. Foundations
2. **Localization, mapping & ego-state estimation** *(substrate)*
3. Object detection fundamentals + YOLO conceptual lineage *(theory only)*
4. Comprehensive camera perception systems for AD *(applied — YOLO family + DETR + dense perception + mono / multi-cam 3D + foundation features + AD targets incl. mingtai walkthrough)*
5. Classical LiDAR detection
6. Deep-learning LiDAR detection
7. Camera + LiDAR sensor fusion (perception "Goal 1")
8. Classical motion planning, prediction & control
9. Deep-learning planning, prediction & control
10. **AD data engine, labeling & ML operations** *(synthesis)*
11. Safety, validation & operational discipline *(precedes E2E so the reader has the vocabulary)*
12. End-to-end AD *(capstone)*

**Ordering rationale:** prerequisites first; localization as substrate before perception; theory before applied (Ch 3 vs 4); classical before DL (Ch 5→6, 8→9); fusion sits between perception and planning; data + safety precede E2E.

**Three classical layers — do not conflate:** classical-LiDAR-detection (Ch 5), classical-planning + prediction + control (Ch 8), ROS2/Humble middleware (substrate, Ch 1 §1.5 + Ch 5 §5.8 + threaded everywhere a node lands).

**Pinned deployment target:** PyTorch training → ONNX/TensorRT inference → C++ ROS2 nodes → edge GPU on vehicle → rosbag logging/replay.

**Open user-input questions** (do not silently pick — ask): "end-to-end AD" definition (Ch 12 §12.1); exact edge-GPU class (Jetson-class default); "YOLO26" source/repo (Ch 4 §4.1); bilingual workflow.

**Graphify** is **manual only** for this vault — no auto-update hook (graphify is a Claude skill, not shell-callable). Default to `_EN.md`-only input. See README §12.

**When planning or drafting chapters:** follow the canonical pedagogical order above; the user's personal deployment milestones are context, not constraint; use mingtai only where it actually clarifies a concept.

## Subagents and the per-chapter pipeline

The vault uses a five-actor team and a six-phase per-chapter pipeline. Verbose authoritative spec lives at `_workflow/subagents_design.md`; this section is the concise summary.

**Agent team:**

- **Main session** — Claude Code (this CLI). Orchestrator and sole authority for `CLAUDE.md`, `README.md`, memory, TOC, chapter overviews, and final commits.
- **`codex-collaborator`** — codex-companion runtime, no `--write`. Dual-mode RESEARCH \| CONFLICT. **Sole conflictor.** Pass `RESUME: true` to continue a critique thread with `--resume-last`.
- **`gemini-researcher`** — Gemini CLI, `--approval-mode plan`. Research only; never critique, never drafting. Also performs mandatory factual spot-checks for codex-drafted sections (Phase 5 Rule 3b).
- **`cc-writer`** — Claude Code subagent. Drafts one section file per dispatch into the main repo. Path scope is hard-enforced by the `PreToolUse` hook (`.claude/hooks/check_writer_path_scope.mjs`) reading `.claude/active_writer_batch.json`.
- **`codex-writer`** — codex-companion runtime, `--write` enabled, `--cwd` set to the sacrificial worktree at `../auto-driving-codex-worktree`. Drafts one section file per dispatch inside the worktree; main session copies the assigned path back to the main repo after the writer returns.

**Per-chapter pipeline (six phases):**

1. **Research** — main + gemini + codex RESEARCH in parallel; main integrates.
2. **Research deal-loop** — main + codex CONFLICT iterate; codex may *propose* structural changes (proposed-not-adopted; user approves before lockstep update).
3. **Chapter plan + allocation deal-loop** — main drafts an 11-item plan (sections, DAG, batches, writer assignments, handoff snippets, style anchor, prerequisite chain, TOC slice, must-preserve terminology, reader assumptions, downstream commitments); codex CONFLICT reviews all 11 items including DAG correctness and ratio appropriateness.
4. **Per-section drafting** (parallel where independent) — main builds section briefs, enforces full-repo `git status --porcelain` clean precondition, writes the batch sentinel listing assigned paths, dispatches cc-writer / codex-writer per the 1:1 dynamic ratio, copies codex-writer outputs back from the worktree, runs structured post-batch validation, removes the sentinel.
5. **Per-section deal-loop** — main + codex CONFLICT iterate on the draft (framing + terminology + surface voice + handoff fidelity + scope creep); codex-drafted sections also require a gemini factual spot-check on 2–3 claims (Rule 3b) and a codex-bias checklist pass (Rule 3c).
6. **Chapter voice pass (terminal)** — main + codex harmonize **surface concerns only** (transitions, pacing, redundancy, terminology drift). No structural rewrites at Phase 6 — kicks back to Phase 5. On AGREED, main sets every section's `workflow_status: complete` and commits.

**Convergence protocol** — every CONFLICT-mode response from codex ends with `STILL DISAGREEING: <one-line>` (loop continues with `RESUME: true`) or `AGREED: <one-line>` (phase complete). Trivial / docs-only / single-sentence edits skip the deal-loop.

**Section file lifecycle:** one file per section, `chapter_<N>_<slug>/<N>_<M>_<section_slug>_EN.md`. Frontmatter `workflow_status: draft → reviewing → complete` is kept indefinitely (no stripping at completion).

**Git commit strategy (Strategy C+):** WIP commits on every writer return AND milestone commits at every AGREED gate. Default no squash. Six-prefix taxonomy: `wip / revert / agreed / plan / chapter / lockstep`. See spec §7 for examples.

**Same-model bias mitigation (procedural):**
- Rule 3a — when ratio is tied, cc-writer drafts novel/contested content; codex-writer drafts well-known applied content.
- Rule 3b — codex-drafted sections require gemini factual spot-check in Phase 5.
- Rule 3c — codex-drafted sections run against a codex-bias checklist (markdown over-listing, analogy register, foundational example choice, depth defaults).

**Important constraints:**
- Codex-collaborator is the **sole** conflictor. Do not add Gemini as a second adversary.
- `codex-collaborator` is read-only (no `--write`); `gemini-researcher` runs in `--approval-mode plan`. Only `codex-writer` runs Codex with `--write`, and only inside the sacrificial worktree.
- Project-scoped subagents are loaded at session start. After editing `.claude/agents/` or `.claude/settings.json`, the user must restart the Claude Code session.
- The full-repo `git status --porcelain` clean-state precondition (§6.1 of the spec) means the user must commit/stash any in-progress edits across the entire vault before main session can dispatch a writer batch.

**Modification discipline (load-bearing — see `feedback_workflow_discipline.md` + `feedback_update_in_lockstep.md` in project memory):**
- **Never apply a modification before codex `AGREED`.** Even direct user instructions that change the agreed plan go through the deal loop first. The rule applies to workflow / meta-architecture changes, not just book content.
- **Never act on downstream artifacts before the user explicitly approves the plan.** "Give me the plan" means present-then-wait, not implement.
- **When you do change anything substantive, update memory + CLAUDE.md + README + TOC + affected chapter overviews together** so the four sources never drift. Memory and CLAUDE.md stay concise; README is the verbose authoritative plan; `_workflow/subagents_design.md` is the verbose authoritative workflow spec.

A `UserPromptSubmit` hook at `.claude/hooks/codex_conflict_reminder.sh` injects a reminder of this discipline on every prompt. The hook is a reminder, not enforcement — the discipline still lives in the rule above.

## Working in the vault

- Prefer Obsidian Flavored Markdown features (wikilinks `[[Note]]`, embeds `![[Note]]`, callouts, frontmatter properties, tags) over plain Markdown when authoring notes — see the `obsidian:obsidian-markdown` skill.
- For `.canvas` files use the `obsidian:json-canvas` skill; for `.base` files use `obsidian:obsidian-bases`.
- To read or manipulate the live vault (search, list notes, open files, run vault operations), use the `obsidian:obsidian-cli` skill rather than ad-hoc shell commands.
- When the user provides a URL to ingest into the vault, use `obsidian:defuddle` to extract clean Markdown (skip it for `.md` URLs).

## Vault configuration

- Enabled core plugins are listed in `.obsidian/core-plugins.json` (Bases, Canvas, Daily Notes, Templates, etc. are on; Slides, Audio Recorder, Publish, Workspaces are off).
- `.claude/settings.local.json` enables the `obsidian@obsidian-skills` plugin, which is what exposes the `obsidian:*` skills above.
- Do not commit edits to `.obsidian/workspace.json` — it tracks transient UI state.
