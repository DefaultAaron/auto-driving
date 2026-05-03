---
title: Ch 5 content extension + pipeline depth update — plan
doc_type: chapter-plan
chapter: 5
phase: extension-planning
status: draft
created: 2026-05-03
related:
  - "[[ch5_chapter_plan]]"
tags: [workflow, chapter-5, extension, plan]
---

# Chapter 5 content extension + pipeline depth update

User direction (2026-05-03): "most parts in the sections are still brief, i want the parts be specific illustrated the idea, usage, and limitation that provide detailed pictures for the reader. you may review and extend the content section by section. use codex as the main writer, use cc writer only when necessary. update the pipeline to produce detailed contents."

This plan covers (a) what the depth standard should be, (b) the pipeline changes to make that standard the new default, and (c) the sequencing for extending all 10 already-AGREED Ch 5 sections.

---

## 1. The depth standard — five-block pattern (Concept / Mechanics / Worked Example / Usage / Failure Modes)

(Round-1 codex feedback r1-c2 + r1-c3 + r1-c4: the original three-block "Idea / Usage / Limitations" decomposition was too coarse — it buried the worked example inside "Idea" and overpromised "implement from this section alone" against an unrealistic per-block budget; visuals were treated as optional despite the user's exact "detailed pictures" ask. Five blocks instead of three; legacy "I/U/L" shorthand is no longer used in load-bearing rules.)

For every distinct algorithm or technique a section introduces (RANSAC, Patchwork, DBSCAN, ICP, NDT, Hungarian, Kalman, OctoMap, etc.), the section must cover five blocks. The order is fixed; the heading is the writer's choice.

### Concept (what it is and why it exists)
- The mathematical / algorithmic core stated cleanly enough that the reader knows what the method computes and what its inputs/outputs are.
- Where the method came from historically (paper + year, in one sentence — already a chapter convention).
- Why this method exists, i.e., what failure of the previous method it addresses (one paragraph max).
- **Implementation-depth promise downgraded to "understand production implementation choices."** Anchor-algorithms-only get full implementation depth; see the Mechanics block.

### Mechanics (how it works)
- Step-by-step description of the algorithm (numbered list or short prose) so the reader can read it linearly.
- The key data structure or update rule that distinguishes this method from the previous (e.g., NDT's per-cell Gaussian vs ICP's nearest-neighbor pairs).
- For the section's **anchor algorithm** (one per section, declared in the brief) — full implementation depth: enough detail that the reader could write a toy version. For non-anchor algorithms, mechanics depth is enough that the reader can read production code without surprise.

### Worked Example (the picture the user asked for)
- **One concrete numerical or visual artifact per major algorithm.** Numerical inputs / outputs through one iteration; or a small ASCII / canvas / table illustration of the spatial intuition (e.g., a 5×5 BEV grid showing log-odds before/after an update; a 4-point cluster with the L-shape fit and yaw drawn out; a one-iteration ICP correspondence list).
- Pseudocode in Python (≤ ~15 lines) or short C++ snippet for shippable patterns (per the chapter-plan code policy). The pseudocode is part of the worked example, not a standalone block.
- The Worked Example is **load-bearing visual content**; if the section has no concrete artifact, it has not satisfied the standard.

### Usage (operational depth)
- The default parameters and the rationale (e.g., "RANSAC distance threshold ≈ 5 cm because LiDAR returns scatter ~2 cm and the curb threshold is 8–15 cm; threshold sits between them so the road wins consensus and the curb does not.")
- Tuning advice: which parameter to change first when results look wrong, and what change in observable symptom corresponds to which change in parameter.
- Sensor / ODD applicability: which sensor classes (HDL-32E / HDL-64E / VLP-32C / AT128 / FMCW) and which ODD slices (highway / urban / port / wet / steep grade) the method works well in vs poorly in.
- Cadence and budget: per-frame / sub-rate / on-demand; rough latency on a Jetson-class CPU/GPU.

### Failure Modes (where it breaks)
- The specific scenes that break the method, with one-sentence symptom each.
- The classical-vs-DL displacement story for that algorithm (does DL replace it, hybrid with it, or leave it alone?).
- The cross-pointers to (a) the failure-mode catalog row(s) the section already commits, and (b) the next-chapter context (e.g., DL ground seg in Ch 6 §6.2).

### Visual / artifact discipline (binding)

Per round-1 codex feedback r1-c4 + round-2 r2-c5: the user said "detailed pictures." Visuals are not optional, and tables alone do not satisfy the rule for geometry-heavy methods.

- **At least one spatial visual artifact per section** for sections that teach spatial / geometric methods (§§5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7). Acceptable forms: ASCII diagram showing geometric relationship (e.g., curb cross-section; L-shape corner search; BEV grid with ray-casting line); embedded canvas (`![[...]]` to a `.canvas` file built in this vault); externalized figure path with a documented source; range-image sketch; BEV cell sketch with log-odds annotations. **Markdown tables and pseudocode alone do not satisfy the rule** for these sections — they may supplement the spatial artifact, not replace it.
- **§5.8 (ROS2 integration) and §5.9 (deployment & runtime) may use tables instead of spatial diagrams** because their content is wiring / numeric budget, not spatial geometry. A composable-node container diagram or per-stage budget table satisfies the rule for these two.
- **§5.10 (safety synthesis) is exempt** from the artifact discipline — its index is the artifact.
- **Per-algorithm-family visual where spatial intuition is load-bearing.** Examples: range bias diagram in §5.3, RANSAC ground failure in §5.2, L-shape fitting geometry in §5.4, ICP convergence in §5.6, occupancy log-odds update in §5.7, ROI map suppression illustration in §5.7, tracking association graph in §5.5. This is per-algorithm-*family*, not per-method — Kalman / IMM / JPDA share one tracking-association visual rather than three.

### What's NOT changing

- The 6-field failure-mode catalog schema (id / cause / observable_symptom / downstream_hazard / mitigation / validation_test) stays binding per chapter plan Item 5; the Failure Modes block points to those rows, doesn't replace them.
- The chapter's overall structure (10 drafted sections + §5.0 overview) stays.
- The §5.10 chapter-wide-index discipline stays — §5.10 is a synthesis section, not a per-algorithm section, and the five-block pattern does not apply to it directly.

---

## 2. Length-band recalibration

Current section lengths and proposed new bands:

| § | Title | Current EN words | Proposed band | Rationale |
|---|---|---:|---:|---|
| 5.0 | Overview | 616 | 800–1200 | Overview should preview the chapter's scope and learning objectives; current is acceptable but slim. |
| 5.1 | Preprocessing + representation map | 2708 | 4500–6000 | Multiple algorithms (deskew, SOR/ROR, voxel grid, accumulation) + the four-representation primer; each needs full five-block. |
| 5.2 | Ground segmentation | 2796 | 4500–6000 | RANSAC, Himmelsbach, radial-bin/heightmap, GP-INSAC, Patchwork/Patchwork++ — five algorithms minimum, each five-block. |
| 5.3 | Clustering | 2416 | 4000–5500 | Euclidean / DBSCAN / range-image (Bogoslavskyi). Three algorithms; range-bias deep-dive needed. |
| 5.4 | Object-shape fitting | 3368 | 4500–6000 | L-shape (Zhang 2017 search), PCA/OBB, min-area rectangle, convex hull, class priors. Multiple methods + the side-channel contract. |
| 5.5 | Classical tracking | 3773 | 5500–7000 | Kalman / IMM / Hungarian / JPDA / MHT / AB3DMOT. Six methods; track lifecycle is its own algorithm. |
| 5.6 | Registration | 2697 | 4500–6000 | ICP point-to-point + point-to-plane, NDT, GICP. Three algorithms + the four perception roles framing. |
| 5.7 | Occupancy + ROI gating | 4297 | 5500–7000 | Already substantial; small extension to bring map-aided gating up to five-block parity with occupancy. |
| 5.8 | ROS2 integration | 2287 | 3500–4500 | PointCloud2 schema, TF2, lifecycle, composable nodes, rosbag. Less algorithmic; more "how to wire it" depth. |
| 5.9 | Deployment & runtime | 2721 | 3500–4500 | Synthesis section; modest extension on the per-stage budget table interpretation, field-robustness depth. |
| 5.10 | Safety & validation | 2231 | **2000–2200 (unchanged)** | Synthesis section; the relaxed band already accommodates the 37-entry index. §5.10 is **frozen during §§5.1–5.9 extensions** and re-touched only as a terminal integration pass for paraphrase drift; see §6 of this plan. (Round-1 codex r1-c1 fix: the earlier draft proposed 2500–3000 here while §4.4 forbade changing it — internal contradiction; resolved by keeping the band fixed.) |

**Total target:** ~50–60k EN words (vs current ~30k). Roughly doubles the chapter.

**Per-section bands are calibration targets, not hard caps** — the binding constraint is the five-block coverage (Concept / Mechanics / Worked Example / Usage / Failure Modes) plus the visual artifact discipline; a writer that achieves it in fewer words is allowed.

---

## 3. Pipeline changes (chapter plan + brief template)

### 3.1 Voice rule update (chapter plan Item 6)

Add a new voice-rule bullet:

> **Per-algorithm depth (five-block pattern):** every distinct algorithm or technique a section introduces gets five coverage blocks — **Concept** (what it computes + history + why it exists), **Mechanics** (step-by-step + key data structure / update rule; full implementation depth for the section's declared anchor algorithm, mechanics-depth-for-reading-production-code for non-anchor methods), **Worked Example** (concrete numerical or visual artifact + ≤15-line pseudocode, load-bearing — prose alone does not satisfy), **Usage** (numerical default parameters + rationale + tuning-knob → observable-symptom pairs + sensor/ODD applicability + cadence/budget), **Failure Modes** (failure scenes + DL displacement story + catalog cross-pointer). Order is fixed; headings are the writer's choice. Synthesis sections (§5.0 overview, §5.10 safety) are exempt. **Visual artifact discipline:** ≥1 spatial artifact per section (ASCII / canvas / figure / BEV sketch / range-image sketch — not a Markdown table) for geometry-heavy sections; per-algorithm-family visual where spatial intuition is load-bearing (range bias, RANSAC ground failure, L-shape geometry, ICP convergence, occupancy log-odds, ROI map suppression, tracking association).

### 3.2 Writer ratio (chapter plan Item 4)

(Round-1 codex feedback r1-c5: the original cc-writer assignment for §5.4, §5.6, §5.7, §5.9 was made because of "novel content / theoretically loaded / contested combination / contested framing" — pedagogical risks that **sharpen** at the extension stage, not loosen. Flipping all four to codex-writer was overconfident.)

Per Rule 3a, codex-writer is the default; cc-writer is reserved for sections where pedagogical-framing risks dominate. The Phase-3 chapter plan locked the Phase-4 *drafting* assignments. The **extension** dispatches use the same locked-at-Phase-3 logic, with one calibration:

- **§5.0 overview** is updated by **main session direct edits at Phase-6 close**, same convention as the original chapter ("§5.0 overview is updated by main session at Phase 6 commit, not drafted by writers" — chapter plan Item 1). It is **outside the writer ratio**.
- **Writer ratio over the 10 drafted sections §§5.1–5.10:**
    - **cc-writer (5 sections):** §5.4 (default per the deterministic rule below; original cc-writer for novel-section framing), §5.6 (theoretically loaded — ICP/NDT/GICP math + four-perception-roles framing), §5.7 (contested combination — the integration is the pedagogy), §5.9 (contested framing — bounded "Nobody ships..." claim + load-bearing-classical-in-DL list), §5.10 (synthesis).
    - **codex-writer (5 sections):** §5.1 preprocessing, §5.2 ground segmentation, §5.3 clustering, §5.5 tracking, §5.8 ROS2 integration. These are algorithm-bounded, code-heavy, well-documented per method — codex-writer's strength, and the Phase-3 plan picked them codex originally.

**§5.4 deterministic rule (round-2 codex r2-c4 fix):** §5.4 stays **all-cc-writer by default**. A two-writer split (codex on Mechanics/Worked-Example/Usage; cc on framing prose + intro + planner-consumable thesis + side-channel contract narrative) is **only allowed if the brief deal-loop produces an explicit before-dispatch isolation of exactly which subsections each writer owns**, named at the heading level. If the brief deal-loop cannot produce such isolation cleanly (e.g., the framing and mechanics interleave at paragraph granularity throughout the section), the dispatch defaults to all-cc-writer with no midstream fallback — the choice is made at brief-AGREED time and not revisited based on overhead-felt-during-execution.

This preserves the codex / cc balance over the 10 drafted sections at 5:5 and respects the chapter-plan-locked rationale for the cc-writer choices. §5.0 overview is outside the ratio (main session direct).

### 3.3 Phase-5 path under the extension

Per §3.2 above, the extension dispatches over the 10 drafted sections §§5.1–5.10 are: cc-writer (5: §5.4 default, §5.6, §5.7, §5.9, §5.10) + codex-writer (5: §5.1, §5.2, §5.3, §5.5, §5.8). §5.4 may be split into a two-writer dispatch only if the brief deal-loop produces explicit before-dispatch heading-level isolation; otherwise all-cc-writer. §5.0 overview is updated by main session direct edits at Phase-6 close, outside the ratio.

- **cc-drafted sections → Path A** (bidirectional with codex-collaborator every round).
- **codex-drafted sections → Path B** (main conflicts rounds 1..N-1; codex-collaborator final-round sanity pass at round N; re-pass on any fix).
- Path B main-conflict review must explicitly check the four named bias axes (Rule 3c folded in): markdown over-listing, analogy register, foundational example choice, depth defaults. Special attention to the "depth defaults" axis since the explicit goal is *more depth*; main must not over-correct toward more depth than the standard requires.

**Depth-defaults check rule (binding for Path B during the extension):** main session's per-round critique must distinguish "more depth that meets the five-block standard" from "depth-padded marketing-style elaboration." The check uses three concrete questions per algorithm:
1. Does the section's coverage of this algorithm contain all five blocks (Concept / Mechanics / Worked Example / Usage / Failure Modes), or does it pad one block (typically Mechanics) at the expense of another (typically Worked Example or Failure Modes)? Padding without coverage parity is a depth-defaults flag.
2. Is the Worked Example a concrete artifact (numerical / visual / pseudocode), or has it degenerated into prose that *describes* what an example would look like? The latter is a depth-defaults flag.
3. Does the Usage block contain at least one parameter with a numerical default + rationale, and at least one tuning-knob → observable-symptom pair? If both are absent and the prose discusses parameters in the abstract, that is a depth-defaults flag.

Any of the three triggering on a round-1 codex critique gets the explicit `depth-defaults` axis tag in main session's per-round response.

### 3.4 Brief template change (default for all future chapters)

The default Phase-4 brief template in `_workflow/templates/section-brief-template.md` (to be created) should include:
- A "Per-algorithm coverage table" required field listing every algorithm the section introduces, declaring one **anchor algorithm** per section, and confirming the five blocks (Concept / Mechanics / Worked Example / Usage / Failure Modes) for each.
- The per-algorithm length budget per block (rough): Concept ~150–250 words, Mechanics ~200–350 words for non-anchor and ~400–700 words for anchor (where full implementation depth lives), Worked Example ~150–300 words including pseudocode and concrete artifact, Usage ~200–350 words, Failure Modes ~150–250 words. Per-algorithm total ~850–1700 words for anchor and ~700–1300 words for non-anchor; multiplies by algorithm count to give the section budget.
- Required artifacts list (mandatory, not aspirational):
    - ≥1 pseudocode block per section.
    - ≥1 worked numerical example per section (concrete inputs / outputs through one iteration).
    - ≥3 cross-references inline-restated.
    - **≥1 spatial visual artifact** (ASCII diagram showing geometric relationship; embedded canvas; externalized figure; range-image sketch; BEV cell sketch with annotations) for sections that teach spatial / geometric methods. Markdown tables alone do not satisfy this for geometry-heavy sections.
    - **Wiring / runtime sections** (§5.8-class, §5.9-class) may use composable-node container diagram or per-stage budget table in lieu of spatial diagram.
    - **Synthesis sections** (§5.0-class overview, §5.10-class safety) are exempt — the index or overview is the artifact.

Existing chapter briefs do not get retrofitted; the template applies from Ch 6 forward.

---

## 4. Sequencing for the Ch 5 extension

### 4.1 Approach options

**Option A — sequential by section number (5.0, 5.1, 5.2, ..., 5.10).** Each section: extension brief → brief deal-loop → writer dispatch → Phase-5 deal-loop → AGREED commit. ~10 sections × ~3 rounds avg = ~30 deal-loop iterations. Time cost: high. Predictability: high.

**Option B — batched by content similarity.** Group §§5.1–5.6 (algorithm-heavy) into 2–3 batches; §5.7, §5.8, §5.9 (substrate / wiring / synthesis) as one batch each; §5.0 + §5.10 (overview / synthesis) as one batch. ~5 batches × multi-section parallel = faster, but parallel codex-writer dispatches need worktree hygiene per batch.

**Option C — incremental (start with the thinnest, see if standard works, then scale).** Run §5.3 (2416 words → 4000–5500 target) as a pilot. If the five-block pattern produces the depth the user wants, scale to the rest. If the pilot reveals issues with the standard, revise before scaling.

**Recommendation: Option C — pilot §5.3, then sequential by section number for the remaining 8 algorithm/wiring sections, with §5.10 explicitly frozen until terminal integration.** §5.3 is one of the thinnest, has 3 well-known algorithms (Euclidean / DBSCAN / range-image), is mid-DAG (depends on §5.2, feeds §5.4), and the pilot result calibrates the writer briefs for §§5.1, 5.2, 5.4–5.9.

**Final order:** pilot §5.3 → §5.1 → §5.2 → §5.4 → §5.5 → §5.6 → §5.7 → §5.8 → §5.9 → **§5.10 terminal integration** (after all the above are at extension-AGREED) → **§5.0 overview update (main-session direct, at Phase-6 close — chapter-plan Item 1 convention)** → Phase-6 chapter voice pass → `chapter(5):` re-publish commit. §5.0 is updated as part of the Phase-6 close lockstep alongside TOC and chapter-overview status flips, not as a standalone extension dispatch.

**§5.10 is frozen** during §§5.0, 5.1–5.9 extensions per round-1 codex feedback r1-c6. The change log at `_workflow/briefs/ch5_extension_catalog_changes.md` accumulates row-text drift across §§5.1–5.9 extensions; §5.10's terminal integration consumes the log and produces one paraphrase-update + pattern-block-update pass.

### 4.2 Per-section process (each section repeats this)

1. Re-flip `workflow_status: complete → reviewing` in the section frontmatter and §5.0 overview's section table.
2. Build extension brief: list every algorithm/technique in the current draft; identify which five-block blocks are present vs missing; specify per-algorithm extension targets.
3. Phase-4 brief deal-loop with codex-collaborator (every round, regardless of writer model — this is brief review, same as original Ch 5).
4. Writer dispatch — per the §3.2 assignment table:
    - **codex-writer in worktree** for §5.1, §5.2, §5.3, §5.5, §5.8.
    - **cc-writer** for §5.4 (default; or split-codex+split-cc only if the brief deal-loop produced explicit before-dispatch heading-level isolation), §5.6, §5.7, §5.9, §5.10.
    - **§5.0 is main-session direct edits** — no writer dispatch; main session updates the overview at Phase-6 close, same convention as the original chapter.
    - Multi-path sentinel only if extending multiple sections in one batch (Option B not selected; sequential Option C means single-path sentinel per dispatch).
5. Phase-5 deal-loop per writer model (Path A for cc-drafts, Path B for codex-drafts). Path B main-conflict review must enumerate which of the four bias axes (markdown over-listing / analogy register / foundational example / depth defaults) are flagged each round.
6. Per-section AGREED commit; re-flip frontmatter to `complete` only after Phase-6 voice pass at the end of the extension.

### 4.3 Phase-6 voice pass (final, after all sections extended)

After all 10 sections at extension-AGREED, run a chapter-wide voice pass exactly like the original Ch 5 Phase-6:
- Cross-section terminology drift check.
- five-block heading style consistency.
- Pacing across the now-doubled chapter.
- Cross-references between extended and not-yet-extended sections (none expected — all 10 extend).

Single `chapter(5):` re-publish commit with updated TOC + chapter-overview lockstep + final extended state.

### 4.4 What NOT to do during the extension

- **Do not change the algorithm coverage** (no adding "now also include FastICP", no removing "Himmelsbach is historical only"). Phase 3 plan choices stay locked; the extension is depth-only on the existing scope.
- **Do not extend the failure-mode catalog** beyond the 37 entries committed at chapter close. New failures discovered during extension surface as Phase-5 critique on the host section, but the catalog stays at 37 unless a new structural decision is taken (which would be Phase-3-class work, kicked back from Phase 5).
- **Do not change the §5.10 length band** — it stays 2000–2200 (round-1 codex r1-c1 fix). Current 2231 is **31 words above the nominal upper edge**; this is accepted because §5.10 is frozen except for the terminal integration pass, the overage is < 2%, and the index alone (~1380 words for 37 rows) sets the structural lower bound. The terminal integration may add another ~50–100 words for change-log paraphrase updates, pushing total to ~2280–2330; this is also accepted under the same reasoning. If the terminal pass produces > 2400 words, a brief deal-loop micro-revision is required to compress prose blocks.
- **Do not edit §5.10 during §§5.0, 5.1–5.9 extensions** — the §5.10 freeze + change-log discipline is binding (round-1 codex r1-c6 fix).
- **Do not retrofit the brief template change to Ch 5 briefs** — the briefs that got committed are historical record; the template applies forward.

---

## 5. Memory / lockstep updates after this plan AGREEs

Memory:
- New `feedback_section_depth_standard.md` — five-block rule (Concept / Mechanics / Worked Example / Usage / Failure Modes), anchor-algorithm-only-for-full-implementation-depth, binding visual artifact discipline (spatial visual for geometry-heavy sections; tables OK for §5.8/§5.9-class; synthesis sections exempt).
- Update `feedback_writer_subagents.md` — clarify that the codex-default rule applies to **algorithm-bounded extension dispatches** (algorithm depth where the per-algorithm scope is well-shaped). cc-writer is **retained** for chapter-classified high-judgment / contested-framing / theoretically-loaded / contested-combination sections (Rule 3a rationales carry forward into extension), and for synthesis sections (overview / safety / E2E-class). §5.4-class novel-section-framing defaults to all-cc; codex-cc split only with explicit before-dispatch heading-level isolation.

Chapter plan (`_workflow/plans/ch5_chapter_plan.md`):
- Item 6 (voice rules) — add the five-block bullet + visual artifact discipline.
- Item 1 (length cells) — update each section's length band per §2 of this plan (§5.10 stays at 2000–2200 unchanged).
- Item 4 (writer assignments) — note the "codex-writer is default for algorithm-bounded extension; cc-writer retained for chapter-classified high-judgment/framing sections" rule, with explicit forward-apply scope. Document the §5.4 deterministic rule.

CLAUDE.md:
- Update the "Subagents and the per-chapter pipeline" section's writer-default rule — codex-writer is the default for **algorithm-bounded** per-algorithm-depth dispatches; cc-writer is **retained** for synthesis (overview / safety / E2E-class) and for chapter-classified high-judgment / contested-framing / theoretically-loaded / contested-combination sections.
- Update the Phase-4 process to mention that the brief template enforces per-algorithm five-block coverage + the visual artifact discipline.

README.md:
- Update §11 (or wherever the chapter-plan summary lives) to reflect the new chapter-5 length band and the five-block standard.

`00_table_of_contents.md` — no change at this stage; updates only when sections cross AGREED.

`_workflow/STATE.md` — main session updates with extension-state at every AGREED commit and at session end.

---

## 6. Risks / tradeoffs

- **Time cost.** Option C is ~10–15 deal-loop sessions across multiple Claude Code conversations. The user has indicated they want this level of investment; surfacing the cost is the discipline.
- **Bias toward over-extension.** With "depth defaults" as a Path B bias-axis flag, main session must be vigilant that codex-writer extensions stay in the five-block standard and don't pad with marketing-style elaboration. Round-1 main-conflict review must check this axis specifically.
- **§5.10 paraphrase drift (mitigation upgraded per round-1 codex r1-c6).** §5.10 indexes 37 failure-mode rows from §§5.1–5.9; piecemeal spot-checks at every host-section AGREED would invite stale paraphrases and inconsistent hazard language. Replaced with a stronger discipline:
    - **Freeze §5.10 during §§5.0, 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7, 5.8, 5.9 extensions.** No edits to `5_10_safety_and_validation_EN.md` during these dispatches.
    - **Maintain a change log** at `_workflow/briefs/ch5_extension_catalog_changes.md` listing every host-section catalog row whose `cause` or `downstream_hazard` text changed materially during its extension's Phase-5 deal-loop. Each entry: `host_section / id / old_cause / new_cause / old_hazard / new_hazard / reason`. The log is appended at every per-section AGREED commit.
    - **Run §5.10 as a terminal integration pass** after §§5.1–5.9 are all at extension-AGREED. The §5.10 brief at that point reads the change log and produces a one-shot paraphrase update plus any pattern-block updates the index changes imply. cc-writer dispatch; Path A bidirectional with codex-collaborator. **§5.0 overview is updated after §5.10 AGREEs**, as part of the Phase-6 close lockstep alongside TOC + chapter-overview status flips (chapter-plan Item 1 convention: "§5.0 overview is updated by main session at Phase 6 commit, not drafted by writers"). After the Phase-6 voice pass AGREEs (the voice pass is what reaches AGREED), the `chapter(5):` re-publish commit lands.
- **§5.7 + §5.5 are already substantial.** Their proposed extension band (5500–7000 / 5500–7000) is only modestly above current (4297 / 3773). If the extension brief deal-loop concludes the existing depth meets the five-block standard, the section may close at "no extension needed" — that is a valid outcome and should be the default if the standard is already met.
- **§5.9 dependency on §§5.1–5.8 budget rows.** If any extension changes the per-stage runtime budget row's numbers (it shouldn't — extension is depth, not data), §5.9 needs the update propagated. Flag at brief deal-loop.

---

## 7. Decision asks for codex CONFLICT review

1. Is the five-block pattern (Concept / Mechanics / Worked Example / Usage / Failure Modes) the right depth standard, with anchor-algorithm-only full implementation depth + binding visual artifact discipline? **Round-1 codex AGREED on this decomposition and on visuals-required.**
2. Are the proposed length bands realistic, or do they over- or under-estimate? Is doubling the chapter the right scale?
3. Is Option C (pilot §5.3) the right sequencing, or is sequential-by-section-number (Option A) cleaner because each predecessor's extension lands before the dependent's brief is built?
4. Is the **restored 5:5 writer ratio** (cc: §5.4-default + §5.6 + §5.7 + §5.9 + §5.10; codex: §5.1 + §5.2 + §5.3 + §5.5 + §5.8) and the **§5.4 deterministic rule** (all-cc by default; split only on before-dispatch heading-level isolation; no midstream fallback) sound? Round-2 codex r2-c3 + r2-c4 surfaced this; round-3 critique to confirm the restored allocation is deal-loop-stable.
5. Does the brief-template change belong in this plan, or is it scope creep? If it stays, what fields are mandatory vs optional?
6. Are there any depth-standard items the five-block pattern misses? **Round-1 codex flagged visual artifacts (r1-c4); now binding per §1's "Visual / artifact discipline" subsection. The artifact must be spatial (ASCII / canvas / figure / BEV sketch / range-image sketch) for geometry-heavy methods — Markdown tables alone do not satisfy.**

---

## 8. Phase status

- 8 items above drafted by main session.
- Codex CONFLICT round 1 pending.
- Once AGREED + user approval, this plan triggers Phase-Extension-§5.3-pilot dispatch.
