# Auto-Driving Book — Plan & Vault Conventions

A bilingual (English / Chinese) Obsidian vault that hosts a comprehensive book for **mastering autonomous driving** — fundamentals plus current novel work, from foundations through end-to-end systems. The book is **not project-driven**; it follows a pedagogical sequence designed for a reader who wants to operate as a research-and-deployment engineer on an AD team. The mingtai traffic-light project at `~/Documents/Projects/mingtai/traffic-light` appears as a worked example only, not as the structural spine.

This README is the canonical plan. Open [[00_table_of_contents]] for the live progress tracker.

---

## 1. Vault layout

```
auto-driving/
├── README.md                                     ← this plan
├── 00_table_of_contents.md                       ← live, section-level checkboxes
├── reading_list.md                               ← global, chapter-organised
├── chapter_0_book_overview/
├── chapter_1_foundations/
├── chapter_2_localization_mapping_state_estimation/
├── chapter_3_object_detection_foundations_yolo_family/
├── chapter_4_comprehensive_camera_detection/
├── chapter_5_classical_lidar_detection/
├── chapter_6_dl_lidar_detection/
├── chapter_7_sensor_fusion/
├── chapter_8_classical_planning_prediction_control/
├── chapter_9_dl_planning_prediction_control/
├── chapter_10_data_engine_labeling_mlops/
├── chapter_11_safety_validation_operational_discipline/
├── chapter_12_end_to_end_ad/
├── _templates/
│   ├── _section.md
│   ├── _chapter_overview.md
│   ├── _reading_list_entry.md
│   └── _code_example.md
└── _assets/
    ├── code/
    └── figures/
```

Folders prefixed with `_` are support, not content.

---

## 2. File naming

`N_M_<slug>_LANG.md` — `N` chapter (0–12), `M` section (0 = chapter overview), `LANG` ∈ `{EN, ZH}`. Each section = two files. Underscore suffix `_EN` / `_ZH` (not dotted) keeps Obsidian wikilinks clean.

**Slug language matches LANG**:

- `_EN.md` → English slug (lowercase, underscore-separated, e.g. `5_1_pointcloud_preprocessing_EN.md`).
- `_ZH.md` → Chinese slug — a stable, idiomatic Chinese rendering of the section title. Idiomatic Chinese technical terms stay Chinese (`激光雷达`, `点云`, `占据栅格`); ASCII product names and library names stay ASCII (`ROS2`, `PCL`, `Eigen`, `LiDAR` if the project uses the English form). Examples: `5_0_概览_ZH.md`, `5_1_点云预处理_ZH.md`, `5_8_ROS2_集成_ZH.md`. Pairing between `_EN.md` and `_ZH.md` of the same section is enforced by the `N_M` numbering plus the `_LANG` suffix, **not** by literal slug translation.

Chapter-overview slug is uniformly `概览` across all 13 chapters (so `<N>_0_概览_ZH.md` everywhere).

**Recommended git ergonomics:** `git config core.quotepath false` so `git status` / `git log` displays Chinese filenames as readable characters instead of `\xx\xx` octal escapes.

---

## 3. Bilingual progress tracking

**Frontmatter is canonical.** Every section file declares `workflow_status`: `planned` → `draft` → `reviewing` → `complete`. The legacy `status` field is deprecated; new and updated section files use `workflow_status`.

**TOC display is a manual copy.** [[00_table_of_contents]] shows:
- One **section-level checkbox** `[ ]` per section, language-agnostic. Tick only when both `_EN` + `_ZH` reach `workflow_status: complete`.
- Two **per-language workflow_status badges** ( ○ ◐ ◑ ● ) beside each language wikilink, mirroring frontmatter.
- **Legend:** `○` planned · `◐` draft · `◑` reviewing · `●` complete.

Re-sync badges manually when frontmatter changes.

---

## 4. Templates

In `_templates/` (point the Obsidian Templates plugin's folder here):

- `_section.md` — bilingual-aware section starter.
- `_chapter_overview.md` — chapter-overview starter.
- `_reading_list_entry.md` — copy-paste skeleton; entries go into `reading_list.md`, **not** as separate files.
- `_code_example.md` — code-block scaffold honoring the code policy below.

---

## 5. Code-example policy

- **Deep learning → PyTorch.**
- **Inference for deployment → ONNX / TensorRT** (or vendor SDK), called from C++.
- **ROS2 nodes → C++** (with `rclpy` / Python alternatives only when concise).
- **Classical perception / control → C++** where feasible (PCL, OpenCV, Eigen); otherwise keep original.
- **Long examples** reference paths in `~/Documents/Projects/mingtai/traffic-light/<path>:Lxx-yy`.
- **Very long examples** (~> 40 lines) move to `_assets/code/N_M_<slug>.{py,cpp}` and embed.

---

## 6. Pinned deployment target the book teaches against

- Training & dev: PyTorch on workstation / server GPU.
- Inference / on-vehicle: ONNX → TensorRT (or vendor equivalent), wrapped in C++ ROS2 nodes.
- Edge GPU on the vehicle: **Jetson-class default** (exact device class is a flagged user-input question, see §13).
- Integration: ROS2 / Humble pub/sub, TF2 transforms, message timing & sync.
- Logging / replay: rosbag + per-vehicle log capture.
- Calibration management: kept versioned alongside data.

---

## 7. Obsidian features used

- **Wikilinks** `[[...]]` for internal references; **embeds** `![[...]]` for figures and externalised code.
- **Callouts** for highlights: `> [!info]` (status / metadata), `> [!abstract]` (chapter / section summary), `> [!warning]` (open questions, gotchas), `> [!example]` (code blocks), `> [!tip]` (operational guidance).
- **Frontmatter** for `chapter`, `section`, `title`, `language`, `workflow_status`, `tags`.
- **Tags**: `book/section`, `book/chapter-<N>`, `book/overview`, `book/toc`, `book/reading-list`, `lang/EN`, `lang/ZH`, `region/cn` / `region/us` / `region/eu` (reading-list industry context).
- **Templates** core plugin → `_templates/`.
- **Bases** (deferred) — for reading-list filtering and section-status views.

See the `obsidian:obsidian-markdown` skill for syntax reference.

---

## 8. Chapter outline (canonical pedagogical order — 13 chapters)

| # | Chapter | Sections |
|---|---------|---------:|
| **0** | Book overview | 4 |
| **1** | Foundations (frames, calib, sync, ROS2/Humble, eval, datasets, vehicle dynamics, deployment target, ODD primer, hazard-analysis intro) | 12 |
| **2** | Localization, mapping & ego-state estimation *(substrate — added per round-6 codex critique)* | 11 |
| **3** | Object detection fundamentals + YOLO conceptual lineage *(theory only)* | 6 |
| **4** | Comprehensive camera perception systems for AD *(applied; YOLO/DETR/RT-DETR/DEIM/anchor-free/open-vocab/MOT/dense perception/monocular & multi-cam 3D/foundation features/specialized AD targets incl. mingtai walkthrough/deployment/safety)* | 13 |
| **5** | Classical LiDAR detection (with object-shape fitting, occupancy + map-aided ROI gating, deployment + runtime constraints) | 11 |
| **6** | Deep-learning LiDAR detection | 9 |
| **7** | Camera + LiDAR sensor fusion (perception "Goal 1") | 9 |
| **8** | Classical motion planning, prediction & control (with deployment + control-loop timing) | 10 |
| **9** | Deep-learning planning, prediction & control | 8 |
| **10** | AD data engine, labeling & ML operations *(synthesis — added per round-6 codex critique)* | 11 |
| **11** | Safety, validation & operational discipline *(precedes E2E so the reader has the vocabulary)* | 10 |
| **12** | End-to-end autonomous driving *(capstone)* | 8 |

Full section list lives in [[00_table_of_contents]]. Per-chapter overview pages (`N_0_overview_*.md`) hold each chapter's learning objectives, prerequisites, and section table.

### Cross-cutting threads

- **Deployment spine.** Pinned in Ch 1 §1.9; recurring "Deployment" section in chapters 2, 4, 5, 6, 7, 8; synthesised in Ch 10 (data engine + MLOps); capped by Ch 11 §11.9 (on-vehicle bring-up).
- **Safety thread.** Introduced in Ch 1 §§1.10–1.11; recurring "Safety & validation" template instance in chapters 2, 4, 5, 6, 7, 8, 9; canonically owned by Ch 11; forward-referenced from Ch 12 §12.5.
- **Industry-context callout.** A `> [!info] Industry context` block appears in Ch 0, Ch 11 (safety standards by region), Ch 12 (E2E systems by region), with reading-list region tags.

### Three classical layers — do not conflate

- **Classical LiDAR detection** = Ch 5 (preprocess / RANSAC / clustering / Kalman-IMM-JPDA tracking / ICP-NDT-GICP / occupancy grids).
- **Classical motion planning, prediction & control** = Ch 8 (behavior + state machines / CV-CTRV-IMM-social-force prediction / A*-RRT-lattice planners / PID-pursuit-Stanley-LQR-MPC controllers).
- **ROS2 / Humble middleware** = Ch 1 §1.5 + Ch 5 §5.8 + threaded through every node-integrating chapter.

---

## 9. Workflow conventions — five-actor team, six-phase pipeline

The vault uses a five-actor team and a six-phase per-chapter pipeline. The verbose authoritative spec is `_workflow/subagents_design.md`. `CLAUDE.md` carries the concise summary. This section gives the full overview a new collaborator (or Claude session) needs to operate the workflow.

### 9.1 The five actors

| Role | Runtime | Writes to vault? | Modes |
|---|---|---|---|
| Main session | Claude Code (this CLI) | yes — sole authority for `CLAUDE.md`, `README.md`, memory, TOC, chapter overviews, final commits | orchestrator |
| `codex-collaborator` | codex-companion runtime, no `--write` | no | RESEARCH \| CONFLICT (sole conflictor) |
| `gemini-researcher` | Gemini CLI, `--approval-mode plan` | no | RESEARCH only + factual spot-check |
| `cc-writer` | Claude Code subagent | yes — only the batch-assigned section path, hook-enforced | WRITER only |
| `codex-writer` | codex-companion runtime, `--write`, `--cwd` to sacrificial worktree | only the assigned section path is copied back to main repo | WRITER only |

### 9.2 The six phases (per chapter)

1. **Research** — main session, `gemini-researcher`, and `codex-collaborator` (`MODE: RESEARCH`) run in parallel; main session integrates the three `## Findings / ## Sources / ## Open questions` streams into a synthesis.
2. **Research deal-loop** — main + `codex-collaborator` (`MODE: CONFLICT`, `RESUME: true` across rounds) iterate on what to keep/cut and on any structural proposals codex raises (new section, reorder, additions beyond the canonical 13-chapter plan). Structural changes are *proposed-not-adopted*: they require explicit user approval and a lockstep update across memory + CLAUDE.md + README + TOC + chapter overviews before drafting begins.
3. **Chapter plan + allocation deal-loop** — main session drafts an 11-item plan: section list (scope-in/out, depth, length band) · section dependency DAG · parallel batch groups · writer assignments (cc/codex per section, with rationale) · handoff snippets · style anchor reference · prerequisite chain · canonical TOC slice · must-preserve terminology list · reader knowledge assumptions · downstream commitments. Codex CONFLICT reviews all 11 items.
4. **Per-section drafting (parallel where independent)** — main session enforces a full-repo `git status --porcelain` clean precondition, writes the batch sentinel (`.claude/active_writer_batch.json`) listing assigned paths, dispatches all writers in the batch in a single message (parallel `Agent` tool calls), copies codex-writer outputs back from the worktree, runs structured post-batch validation, removes the sentinel.
5. **Per-section deal-loop** — main + codex CONFLICT iterate on the draft (framing + terminology + surface voice + handoff fidelity + scope creep). For codex-drafted sections, main also dispatches `gemini-researcher` for a factual spot-check on 2–3 claims (Rule 3b) and runs the codex-bias checklist (Rule 3c).
6. **Chapter voice pass (terminal)** — main + codex harmonize **surface concerns only**: cross-section transitions, pacing, redundancy, surface-voice smoothing, terminology drift catch. **No structural rewrites at Phase 6** — if a section needs structural rework, it goes back to Phase 5. On AGREED, main session sets every section's `workflow_status: complete` and commits the chapter with TOC + chapter-overview lockstep updates bundled in.

### 9.3 Section file lifecycle

One file per section: `chapter_<N>_<slug>/<N>_<M>_<section_slug>_EN.md` (and `_ZH.md` per the bilingual convention).

Frontmatter `workflow_status` field:
- `draft` — writer just produced first version, not yet critiqued
- `reviewing` — one or more deal-loop revisions applied
- `complete` — chapter voice pass AGREED, section published

The field is kept indefinitely (no stripping). If an export pipeline is added later, that pipeline strips at export time.

### 9.4 Allocation ratio and same-model bias mitigation

**Default ratio**: 1:1 cc-writer : codex-writer. Main session adjusts dynamically per chapter using context-size pressure on the main session (proxy for Claude quota stress), recent codex usage, chapter character (theory-heavy → cc bias; applied/code-heavy → codex bias), and explicit user override. Codex CONFLICT can challenge the chosen ratio in Phase 3.

**Procedural bias mitigation:**
- **Rule 3a — allocation skew.** When ratio is tied, cc-writer drafts novel/contested/theoretically-loaded sections; codex-writer drafts well-known applied sections.
- **Rule 3b — gemini factual spot-check on codex-drafted sections.** Main selects 2–3 claims, dispatches gemini, only proceeds toward AGREED after verification.
- **Rule 3c — codex-bias checklist.** Main runs codex-drafted sections against an explicit checklist before AGREED (markdown over-listing, analogy register, foundational example choice, depth defaults).

### 9.5 Path scoping and safety

Four-layer model (full detail in `_workflow/subagents_design.md` §6):

1. **Full-repo clean-state precondition** — main session aborts a writer batch if `git status --porcelain` is non-empty anywhere in the repo. User must commit/stash before drafting.
2. **cc-writer hard guard via PreToolUse hook** — `.claude/hooks/check_writer_path_scope.mjs` reads `.claude/active_writer_batch.json` and blocks Write/Edit calls outside the batch's assigned-paths allowlist. Permissive when no sentinel exists.
3. **codex-writer hard isolation** — `git worktree add ../auto-driving-codex-worktree codex-writer-isolated` creates a sacrificial worktree. Codex always runs with `--cwd <worktree>`. Only the assigned section path is copied back to main. The worktree's `reset --hard` is destructive *only inside the worktree*, never main.
4. **Structured post-batch validation** — main computes the change set against the batch sentinel and reverts out-of-scope events file-by-file (never blanket `git restore .`).

### 9.6 Git commit strategy — Strategy C+

WIP commits on every writer return AND milestone commits at every AGREED gate. Default no squash. Six-prefix taxonomy:

| Prefix | When |
|---|---|
| `wip(<chapter>/<section>)` | Every writer return |
| `revert(<chapter>/<section>)` | Post-batch validation reverts an out-of-scope edit |
| `agreed(<chapter>/<section>)` | Phase 5 AGREED on a section |
| `plan(<chapter>)` | Phase 2 or 3 AGREED |
| `chapter(<N>)` | Phase 6 AGREED, chapter published |
| `lockstep(<topic>)` | Multi-artifact lockstep update |

Filter examples: `git log --grep '^chapter('` (milestones); `git log --grep '^wip(' --grep '^revert(' -E` (drafting trail).

### 9.7 Convergence protocol

Every `codex-collaborator` CONFLICT-mode response ends with exactly one of:
- `STILL DISAGREEING: <one-line>` → main dispatches round N+1 with `RESUME: true`.
- `AGREED: <one-line>` → phase complete, main proceeds.

Trivial / docs-only / single-sentence edits skip the deal-loop entirely.

> [!warning] Modification discipline (load-bearing)
> **Never apply a modification before codex `AGREED`** at the relevant phase, including for workflow / meta-architecture changes — not just book content. **Never act on downstream artifacts before the user explicitly approves the plan.** "Give me the plan" means present-then-wait. **When you change anything substantive, update memory + CLAUDE.md + README + TOC + affected chapter overviews together.** See `feedback_workflow_discipline.md` and `feedback_update_in_lockstep.md` in project memory. A `UserPromptSubmit` hook at `.claude/hooks/codex_conflict_reminder.sh` reinforces the rule on every prompt.

---

## 10. Open user-input questions

Items the scaffold deliberately leaves to the user; resolve before writing the affected sections.

1. **"End-to-end AD" definition** — owed by Ch 12 §12.1. Candidates: camera-to-control · sensor-suite-to-trajectory · perception-to-planning integration · imitation/BC · VLA · full vehicle autonomy.
2. **Exact edge-GPU class** — Jetson-class default. Concrete options: Jetson Orin AGX, Orin Nano, Drive AGX, custom — confirm.
3. **"YOLO26" source** — owned by Ch 4 §4.1. Confirm whether YOLOv13 / Ultralytics fork / internal label / custom.
4. **Bilingual workflow** — EN-first-then-translate vs parallel? Affects pacing.
5. **Reading-list automation** — manual now; later a `reading_list.base` can render filtered views.
6. **Anchor-codebase access** — references use `~/Documents/Projects/mingtai/traffic-light/<path>:Lxx-yy`. Confirm path stability.

---

## 11. How to add a new section

Two paths: writer-pipeline drafting (the default for sections drafted via cc-writer / codex-writer) or manual scaffolding (when you want to seed an empty section file before drafting).

**Writer pipeline (preferred):**

1. Decide chapter `N` and section number `N_M`.
2. Add the section to the Phase 3 chapter plan (scope, depth, length band, dependency edges, writer assignment per the 1:1 dynamic ratio, handoff snippet if dependent).
3. After Phase 3 AGREED, the writer subagent creates the file at `chapter_N_*/N_M_<slug>_EN.md` with frontmatter `workflow_status: draft` plus the brief-required fields (`chapter`, `section`, `title`, `language`, `tags`). The writer never creates the `_ZH.md` — bilingual translation is a separate post-completion phase.
4. Phase 5 deal-loop revisions flip the file to `workflow_status: reviewing`.
5. Phase 6 voice pass AGREED → `workflow_status: complete`. Field is **kept** on the file indefinitely (no stripping).
6. The chapter overview's sections table and `00_table_of_contents.md` row are updated by main session as part of the Phase 6 commit (lockstep) — not by the writer.

**Manual scaffold (when you want a stub before drafting):**

1. Create `chapter_N_*/N_M_<slug>_EN.md` (and optionally `..._ZH.md`) from `_templates/_section.md`.
2. Set frontmatter with `workflow_status: planned` plus the standard fields.
3. Add the row to the chapter overview and TOC manually.
4. When the section enters the writer pipeline, the writer overwrites the stub and flips `workflow_status` to `draft`.

The legacy `status` field is deprecated; new and updated section files use `workflow_status`.

---

## 12. Graphify usage

This vault uses the global `graphify` skill (`~/.claude/skills/graphify/SKILL.md`) to produce a knowledge graph + community detection + audit report from the vault content. **Manual invocation only — no auto-update hook is installed (graphify has no shell entrypoint, so a Stop / PostToolUse hook cannot invoke it).**

Run when there is content worth graphing (typically after several sections have moved past `draft` status):

```
/graphify . --obsidian --obsidian-dir . --update --whisper-model medium
```

Conventions:
- **Default to `_EN.md`-only input** (filter at invocation time) to avoid bilingual graph pollution. The EN/ZH file pair would otherwise produce parallel-but-redundant nodes that distort communities.
- For an explicit translation-coverage check, run a separate pass on `_ZH.md` and diff communities.
- Graphify creates its own output directory on first run; decide tracked-vs-ignored policy then.
- Use `/graphify add <url>` to incrementally ingest external papers / docs cited from `reading_list.md`.

See `reference_graphify_project_setup.md` in project memory for the recipe.

---

## 13. Where to look for what

- **Live progress** → [[00_table_of_contents]]
- **Reading list** → [[reading_list]]
- **Templates** → `_templates/`
- **Static assets / externalised code** → `_assets/`
- **Workflow rules + project memory** → `CLAUDE.md` + project memory directory referenced from it.
