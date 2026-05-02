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

**Three classical layers — do not conflate:** classical-LiDAR-detection (Ch 5), classical-planning + prediction + control (Ch 8), ROS2/Humble middleware (substrate, Ch 1 §1.5 + Ch 5 §5.7 + threaded everywhere a node lands).

**Pinned deployment target:** PyTorch training → ONNX/TensorRT inference → C++ ROS2 nodes → edge GPU on vehicle → rosbag logging/replay.

**Open user-input questions** (do not silently pick — ask): "end-to-end AD" definition (Ch 12 §12.1); exact edge-GPU class (Jetson-class default); "YOLO26" source/repo (Ch 4 §4.1); bilingual workflow.

**Graphify** is **manual only** for this vault — no auto-update hook (graphify is a Claude skill, not shell-callable). Default to `_EN.md`-only input. See README §12.

**When planning or drafting chapters:** follow the canonical pedagogical order above; the user's personal deployment milestones are context, not constraint; use mingtai only where it actually clarifies a concept.

## Subagents and the three-stage workflow

This vault has two project-scoped subagents in `.claude/agents/`:

- **`codex-collaborator`** — dual-mode codex wrapper. `MODE: RESEARCH` produces an independent research stream (used in parallel with the main session and gemini). `MODE: CONFLICT` is the adversarial reviewer for plans and drafts. Pass `RESUME: true` (and the agent appends `--resume-last`) to continue a critique thread across rounds.
- **`gemini-researcher`** — single-mode research assistant. Used during the research stage only; never for critique or planning.

**Three stages**, applied to any non-trivial book content:

1. **Research** — main session dispatches `gemini-researcher` and `codex-collaborator` (RESEARCH mode) in parallel, runs its own search in parallel, then integrates the three `## Findings / ## Sources / ## Open questions` blocks into a single synthesis. Then enters the conflict-deal loop with codex on what to keep / cut.
2. **Planning** — main session drafts the plan; conflict-deal loop with codex; finalize.
3. **Generating** — main session drafts the prose; conflict-deal loop with codex; write the final note(s) to the vault.

**Convergence protocol** — every CONFLICT-mode response from codex ends with exactly one of:
- `STILL DISAGREEING: <one-line>` → loop continues, dispatch round N+1 with `RESUME: true`.
- `AGREED: <one-line>` → deal done, main session writes the deliverable.

The main session reads this marker programmatically. Trivial / docs-only / single-sentence edits skip the deal loop.

**Important constraints:**
- Codex is the **sole** conflictor. Do not add Gemini as a second adversary — the deal loop is single-counterparty by design.
- Both subagents are read-only (codex never gets `--write`; gemini runs in `--approval-mode plan`).
- Project-scoped subagents are loaded at session start. After editing files in `.claude/agents/`, the user must restart the Claude Code session for changes to take effect.

**Modification discipline (load-bearing — see `feedback_workflow_discipline.md` + `feedback_update_in_lockstep.md` in project memory):**
- **Never apply a modification before codex `AGREED`.** Even direct user instructions that change the agreed plan go through the deal loop first.
- **Never act on downstream artifacts before the user explicitly approves the plan.** "Give me the plan" means present-then-wait, not implement.
- **When you do change anything substantive, update memory + CLAUDE.md + README + TOC + affected chapter overviews together** so the four sources never drift. Memory and CLAUDE.md stay concise; README is the verbose authoritative plan.

## Working in the vault

- Prefer Obsidian Flavored Markdown features (wikilinks `[[Note]]`, embeds `![[Note]]`, callouts, frontmatter properties, tags) over plain Markdown when authoring notes — see the `obsidian:obsidian-markdown` skill.
- For `.canvas` files use the `obsidian:json-canvas` skill; for `.base` files use `obsidian:obsidian-bases`.
- To read or manipulate the live vault (search, list notes, open files, run vault operations), use the `obsidian:obsidian-cli` skill rather than ad-hoc shell commands.
- When the user provides a URL to ingest into the vault, use `obsidian:defuddle` to extract clean Markdown (skip it for `.md` URLs).

## Vault configuration

- Enabled core plugins are listed in `.obsidian/core-plugins.json` (Bases, Canvas, Daily Notes, Templates, etc. are on; Slides, Audio Recorder, Publish, Workspaces are off).
- `.claude/settings.local.json` enables the `obsidian@obsidian-skills` plugin, which is what exposes the `obsidian:*` skills above.
- Do not commit edits to `.obsidian/workspace.json` — it tracks transient UI state.
