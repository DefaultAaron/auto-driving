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

`N_M_short_slug_LANG.md` — `N` chapter (0–12), `M` section (0 = chapter overview), `LANG` ∈ `{EN, ZH}`. Each section = two files. Underscore suffix `_EN` / `_ZH` (not dotted) keeps Obsidian wikilinks clean.

---

## 3. Bilingual progress tracking

**Frontmatter is canonical.** Every section file declares `status`: `planned` → `draft` → `review` → `done`.

**TOC display is a manual copy.** [[00_table_of_contents]] shows:
- One **section-level checkbox** `[ ]` per section, language-agnostic. Tick only when both `_EN` + `_ZH` reach `status: done`.
- Two **per-language status badges** ( ○ ◐ ● ) beside each language wikilink, mirroring frontmatter.
- **Legend:** `○` planned · `◐` draft · `●` review/done.

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
- **Frontmatter** for `chapter`, `section`, `title`, `language`, `status`, `tags`.
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
| **5** | Classical LiDAR detection (with deployment + runtime constraints) | 10 |
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
- **ROS2 / Humble middleware** = Ch 1 §1.5 + Ch 5 §5.7 + threaded through every node-integrating chapter.

---

## 9. Workflow conventions

This vault uses a project-scoped three-stage workflow (defined in `CLAUDE.md`):

1. **Research** — main session dispatches `gemini-researcher` and `codex-collaborator` (`MODE: RESEARCH`) in parallel, integrates streams.
2. **Planning** — main session drafts the plan; deal-loop with `codex-collaborator` (`MODE: CONFLICT`) until `AGREED`.
3. **Generating** — main session drafts the prose; deal-loop with codex; write final notes.

Codex is the **sole** conflictor; Gemini is research-only. Trivial / docs-only / single-sentence edits skip the deal loop.

> [!warning] Modification discipline
> **Never apply a modification before codex `AGREED`.** **Never act on downstream artifacts before the user explicitly approves the plan.** "Give me the plan" means present-then-wait. **When you do change anything substantive, update memory + CLAUDE.md + the affected vault content together** so the four sources stay in sync. See `feedback_workflow_discipline.md` and `feedback_update_in_lockstep.md` in the project memory.

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

1. Decide chapter and section number `N.M`.
2. Create both `chapter_N_*/N_M_<slug>_EN.md` and `..._ZH.md` from `_templates/_section.md`.
3. Set frontmatter (`chapter`, `section`, `title`, `language`, `status: planned`, `tags`).
4. Add a row to the parent chapter overview's sections table (badges = `○`).
5. Add a row to [[00_table_of_contents]] under the chapter, with checkbox + both language wikilinks.
6. Draft → set `status: draft` (badge `◐`) → review/done (badge `●`). Re-sync badges manually.
7. Tick the master TOC checkbox only when both `_EN` and `_ZH` reach `done`.

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
