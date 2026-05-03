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

- **Main session** — Claude Code (this CLI). Orchestrator + **conflictor for codex-drafted sections** (Phase 5 Path B rounds 1..N-1) + sole authority for `CLAUDE.md`, `README.md`, memory, TOC, chapter overviews, and final commits.
- **`codex-collaborator`** — codex-companion runtime, no `--write`. Dual-mode RESEARCH \| CONFLICT. Conflictor for **cc-drafted sections every round** (Phase 5 Path A); **final-round sanity pass on codex-drafted sections** (Phase 5 Path B round N + any re-pass triggered by fixes). Pass `RESUME: true` to continue a critique thread with `--resume-last`.
- **`gemini-researcher`** — Gemini CLI, `--approval-mode plan`. Research only; never critique, never drafting. Also performs **content-risk-triggered** factual spot-checks for codex-drafted sections (Rule 3b — rerun on factual changes).
- **`cc-writer`** — Claude Code subagent. Drafts AND revises one section file per dispatch into the main repo. Path scope is hard-enforced by the `PreToolUse` hook (`.claude/hooks/check_writer_path_scope.mjs`) reading `.claude/active_writer_batch.json`.
- **`codex-writer`** — codex-companion runtime, `--write` enabled, `--cwd` set to the sacrificial worktree at `../auto-driving-codex-worktree`. Drafts AND revises one section file per dispatch inside the worktree; main session copies the assigned path back to the main repo after the writer returns.

**Per-chapter pipeline (six phases):**

1. **Research** — main + gemini + codex RESEARCH in parallel; main integrates.
2. **Research deal-loop** — main + codex CONFLICT iterate; codex may *propose* structural changes (proposed-not-adopted; user approves before lockstep update).
3. **Chapter plan + allocation deal-loop** — main drafts an 11-item plan (sections, DAG, batches, writer assignments, handoff snippets, style anchor, prerequisite chain, TOC slice, must-preserve terminology, reader assumptions, downstream commitments); codex CONFLICT reviews all 11 items including DAG correctness, writer assignment, and ratio appropriateness. **Writer assignment is finalized here and locked for the chapter** — no mid-run fallback.
4. **Per-section drafting** (parallel where independent) — main builds section briefs, enforces full-repo `git status --porcelain` clean precondition, writes the batch sentinel listing assigned paths, dispatches cc-writer / codex-writer per the **codex-default ratio** (cc-writer reserved for chapter-classified contested-framing / high-judgment-synthesis sections per new Rule 3a), copies codex-writer outputs back from the worktree, runs structured post-batch validation, removes the sentinel.
5. **Per-section deal-loop** — **asymmetric by writer model**:
   - **Path A (cc-drafted)** — main + codex-collaborator CONFLICT iterate every round under bidirectional convergence (§8). Both must AGREE.
   - **Path B (codex-drafted)** — main session conflicts rounds 1..N-1 unilaterally; codex-collaborator does a **final-round sanity pass** at round N. Any fix to a codex-collaborator final-round critique requires another codex-collaborator pass on the changed text — convergence requires codex-collaborator AGREED on the actual final commit.
   - Path B main-conflict review must explicitly check the **five** named bias axes (Rule 3c folded in + round-W addition): **markdown over-listing**, **analogy register**, **foundational example choice**, **depth defaults**, and **`framing-preservation`** (under round-W, for flipped former-cc sections — protected thesis unchanged, scoped claims unchanged, no broadened production claims, no renamed contract terms).
   - Codex-drafted sections also require gemini factual spot-check on 2–3 claims **on content-risk trigger** (Rule 3b — rerun when facts change, not per round).
   - **Revisions go through writer dispatch — drafts AND revisions.** Main session direct-edits section content only via `main-direct: writer-overhead` (narrow definition: spelling, duplicated word, broken Markdown, obvious syntax/format artifact — no semantic changes, no sentence rewrites). The `main-direct: minor` and `main-direct: adjudication` audit tags are **deprecated**.
   - Round 4+ codex-drafted residual editorial disagreement (pedagogy / framing / analogy / depth, not facts) may dispatch a **cc-writer fresh-eye revision** on the disputed passage (Rule 3d — writer-side break). "Same critique" trigger requires same passage + same unresolved defect + same requested outcome across rounds, with persistent critique IDs.
6. **Chapter voice pass (terminal)** — main + codex harmonize **surface concerns only** (transitions, pacing, redundancy, terminology drift). No structural rewrites at Phase 6 — kicks back to Phase 5. On AGREED, main sets every section's `workflow_status: complete` and commits.

**Convergence protocol (asymmetric per Phase 5)** — every CONFLICT-mode response from codex ends with `STILL DISAGREEING: <one-line>` (loop continues) or `AGREED: <one-line>` (phase complete; or final-round pass complete on Path B). **Main session may push back** when a critique is wrong, off-target, or out of scope: `CONTESTED: <critique-id> — <rationale-category>: <one-line>` where rationale-category ∈ {`already-satisfied`, `technically-wrong`, `pedagogically-worse`, `out-of-scope`, `over-budget`, `chapter-context`}. Codex's next round must answer the contested rationale before introducing new objections. **`CONTESTED:` applies in Path A every round, in Path B only at the final round and beyond, and in Phases 2 / 3 / 6 every round.** Convergence requires both sides AGREED at the bidirectional steps. Trivial / docs-only / single-sentence edits skip the deal-loop.

**Section file lifecycle:** one file per section, `chapter_<N>_<slug>/<N>_<M>_<section_slug>_EN.md`. Frontmatter `workflow_status: draft → reviewing → complete` is kept indefinitely (no stripping at completion).

**Git commit strategy (Strategy C+):** WIP commits on every writer return AND milestone commits at every AGREED gate. Default no squash. Six-prefix taxonomy: `wip / revert / agreed / plan / chapter / lockstep`. See spec §7 for examples.

**Same-model bias mitigation (now primarily structural via Phase 5 Path A/B asymmetry, plus residual procedural rules):**
- Rule 3a — codex-writer is the default; cc-writer reserved for chapter-classified contested-framing / high-judgment-synthesis / novel-pedagogical-integration sections at Phase 3 classification. **Under round-W (user billing constraint, 2026-05-03):** writer allocation defaults to all-codex-writer for both initial drafts and extensions; the chapter-plan classification still happens at Phase 3 (it sets the protected-framing-spans rationale used by Safeguard 1) but the writer-allocation default is codex-with-five-safeguards. cc-writer reserved as Rule 3d round-4+ user-approval-gated escape hatch only. See `feedback_billing_constraint_writer_allocation.md`.
- Rule 3b — codex-drafted sections require gemini factual spot-check **on content-risk trigger** (round-1 substantive factual claims OR a revision adds/materially changes factual claims). Not auto-rerun per round.
- Rule 3c — **deprecated as a separate procedural step**. The four named axes (markdown over-listing / analogy register / foundational example choice / depth defaults) are folded into main session's Phase-5 Path B conflict-review prompt; main's critique must enumerate which axes (if any) flagged each round. **Under round-W: a fifth axis `framing-preservation` is added for flipped former-cc sections.**
- Rule 3d — round-4+ writer-side break: cc-writer fresh-eye revision on the disputed passage when main has raised the same critique 3+ times across rounds. "Same critique" defined by issue identity (same passage + same unresolved defect + same requested outcome), persistent critique IDs required. **Under round-W: mandatory user-approval gate before any cc-writer dispatch.** Default fallback if user declines: main-direct revision (codex-collaborator must AGREE) or another narrowed-brief codex-writer round.

**Section depth standard (round-W, applies forward to Ch 6+):** every section that introduces algorithms must cover the **five-block per-algorithm pattern** — Concept (what it computes + history + why it exists) / Mechanics (step-by-step + key data structure; full implementation depth only for the section's declared anchor algorithm) / Worked Example (concrete numerical or visual artifact + ≤15-line pseudocode, load-bearing — prose alone does not satisfy) / Usage (numerical default parameters + tuning-knob → observable-symptom pairs + sensor / ODD applicability + cadence / budget) / Failure Modes (failure scenes + DL displacement story + catalog cross-pointer). Synthesis sections exempt. **Visual artifact discipline:** ≥1 spatial visual artifact per section for geometry-heavy sections (ASCII / canvas / figure / range-image / BEV sketch — not Markdown table); wiring/runtime sections may use composable-node container diagrams or per-stage budget tables; synthesis sections exempt. See `feedback_section_depth_standard.md`.

**Important constraints:**
- **Conflict role splits by writer model.** codex-collaborator is the conflictor for cc-drafted (every round); main session is the conflictor for codex-drafted (rounds 1..N-1, with codex-collaborator final-round sanity pass at round N). Phases 2 / 3 / 6 use codex-collaborator every round (not split by writer model).
- Gemini is **never** a conflictor. Gemini does research (Phase 1) and content-risk-triggered factual spot-check on codex-drafts (Rule 3b).
- `codex-collaborator` is read-only (no `--write`); `gemini-researcher` runs in `--approval-mode plan`. Only `codex-writer` runs Codex with `--write`, and only inside the sacrificial worktree.
- Project-scoped subagents and `.claude/settings.json` hook changes are normally picked up automatically by Claude Code's file watcher. After editing those files, run `/hooks` to verify the new entries are visible; restart the Claude Code session only if they are not picked up.
- The full-repo `git status --porcelain` clean-state precondition (§6.1 of the spec) means the user must commit/stash any in-progress edits across the entire vault before main session can dispatch a writer batch.

**Modification discipline (load-bearing — see `feedback_workflow_discipline.md` + `feedback_update_in_lockstep.md` in project memory):**
- **Never apply a modification before codex `AGREED`.** Even direct user instructions that change the agreed plan go through the deal loop first. The rule applies to workflow / meta-architecture changes, not just book content.
- **Never act on downstream artifacts before the user explicitly approves the plan.** "Give me the plan" means present-then-wait, not implement.
- **When you do change anything substantive, update memory + CLAUDE.md + README + TOC + affected chapter overviews together** so the four sources never drift. Memory and CLAUDE.md stay concise; README is the verbose authoritative plan; `_workflow/subagents_design.md` is the verbose authoritative workflow spec.

A `UserPromptSubmit` hook at `.claude/hooks/codex_conflict_reminder.sh` injects a reminder of this discipline on every prompt. The hook is a reminder, not enforcement — the discipline still lives in the rule above.

**Live workflow state — `_workflow/STATE.md`:** a fast-recovery snapshot of where the vault is in the per-chapter pipeline (active phase, active batch, next action, open CONFLICT threads, do-not-redo notes). **NOT a source of truth** — verify against `git log` and section frontmatter before acting. Mechanical fields are auto-refreshed by the `PreCompact` hook (`.claude/hooks/snapshot_state.mjs`); reasoning fields are updated by main session at each AGREED commit, each WIP commit, and at session end. A `SessionStart` hook (matchers `clear` + `compact`) emits a one-line reminder to read STATE.md after context loss. See `feedback_state_md_discipline.md` in project memory.

**Cue / STATE.md authority:** `_workflow/next_session_cue.md` is the paste-able multi-step prompt for fresh sessions and updates at coarse checkpoints (phase / batch / session boundaries); STATE.md is the live status and updates at every WIP / AGREED commit. **STATE.md is authoritative on conflict.** The cue's `for_commit` frontmatter field flags staleness — compare to current HEAD per the rules in `feedback_state_md_discipline.md` before pasting; if stale, trust STATE.md `next_action`. Past cues are recoverable from git log (`git show <sha>:_workflow/next_session_cue.md`); no `_workflow/archive/` folder.

## Working in the vault

- Prefer Obsidian Flavored Markdown features (wikilinks `[[Note]]`, embeds `![[Note]]`, callouts, frontmatter properties, tags) over plain Markdown when authoring notes — see the `obsidian:obsidian-markdown` skill.
- For `.canvas` files use the `obsidian:json-canvas` skill; for `.base` files use `obsidian:obsidian-bases`.
- To read or manipulate the live vault (search, list notes, open files, run vault operations), use the `obsidian:obsidian-cli` skill rather than ad-hoc shell commands.
- When the user provides a URL to ingest into the vault, use `obsidian:defuddle` to extract clean Markdown (skip it for `.md` URLs).

## Vault configuration

- Enabled core plugins are listed in `.obsidian/core-plugins.json` (Bases, Canvas, Daily Notes, Templates, etc. are on; Slides, Audio Recorder, Publish, Workspaces are off).
- `.claude/settings.local.json` enables the `obsidian@obsidian-skills` plugin, which is what exposes the `obsidian:*` skills above.
- Do not commit edits to `.obsidian/workspace.json` — it tracks transient UI state.
