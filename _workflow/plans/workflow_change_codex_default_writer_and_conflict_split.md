---
title: Workflow change proposal — codex-writer default + writer-only revisions + conflict role split by writer
doc_type: workflow-change-proposal
phase: meta
status: draft
created: 2026-05-02
related:
  - "[[subagents_design]]"
  - "[[feedback_writer_subagents]]"
  - "[[feedback_phase5_revisions]]"
tags: [workflow, meta, proposal, ratio, conflict, usage-budget]
---

# Workflow change proposal

User instruction (verbatim, 2026-05-02):

> you should use more codex writer than cc writer due to the usage budget -- you need extra usage for coordinate. update the work flow -- all writing tasks should be assigned to writers includes drafts and updates, for codex writer's work -- conflict by you, for cc writer's work -- conflict by codex collaborator.

This proposal translates that instruction into three concrete spec changes (A, B, C) plus the implication chain each one drives, and surfaces five open questions for the codex deal-loop. Nothing applied yet — codex `AGREED` first, then lockstep updates to spec / CLAUDE.md / memory / STATE.md / cue.

---

## Change A — codex-writer is the default; cc-writer reserved for the most editorial / contested content

**Current Rule 3a (commit `e9b63ce` Phase-3 plan + `feedback_writer_subagents.md`):**

> Writer ratio defaults to 1:1 dynamic. cc-writer drafts novel / contested / theoretically-loaded content; codex-writer drafts well-known applied content. When the ratio is tied for a given section, cc-writer takes novel/contested; codex-writer takes applied.

Ch 5 produced 5 cc-drafted (§§5.4, 5.6, 5.7, 5.9, 5.10) and 5 codex-drafted (§§5.1, 5.2, 5.3, 5.5, 5.8) under that rule.

**Proposed new Rule 3a:**

> Writer ratio defaults to codex-writer. cc-writer is reserved for sections that the chapter has explicitly classified at Phase 3 as "contested framing" / "high-judgment synthesis" / "novel pedagogical integration." **Writer assignment is finalized at the Phase-3 deal-loop with codex-collaborator and does not change mid-run** — there is no "codex round 1 failed → fall back to cc" escape, because the "codex round 1 failed" judgment would itself be a high-judgment call main session should not make alone. The default tilts toward codex-writer to preserve main-session Claude usage budget for orchestration, conflict review (under Change C below), and lockstep updates.

**Implications:**

- Per-chapter expected ratio shifts from 1:1 to roughly 2cc : 8codex (rough; actual depends on chapter content).
- For Ch 5 specifically: §5.10 (still pending Batch 4) was classified cc-writer at Phase 3 per current Rule 3a (high-judgment synthesis). Under the new rule, §5.10 stays cc-writer because the Phase-3 plan explicitly classified it as such — and the no-mid-run-fallback rule means we don't try codex first.
- Same-model bias mitigation now relies more heavily on Change C (cross-model conflict) plus the Phase-3 deal-loop's adjudication of writer assignment than on Change A's writer-side bias-break.
- Rule 3d (round-4+ cc-writer fresh-eye revision on codex-drafted residual disagreement) becomes the writer-side break when the model-side break (codex-collaborator no longer-as-frequent-conflictor on codex-drafts) is reduced — see Q5.

---

## Change B — all section-content writing goes through writers (drafts AND revisions)

**Current Phase-5 discipline (`feedback_phase5_revisions.md` + `_workflow/subagents_design.md` Phase 5 + §8.1):**

> Phase-5 revisions default to re-dispatching the original writer. Main-direct edits are permitted with audit tags `main-direct: minor / adjudication / writer-overhead` for: typos, wikilink fixes, single-sentence wording fixes, terminology drift fixes, single-cell table-row tightening.

Ch 5 §5.9 round-3 demonstrated this — the field-robustness factual fix went `main-direct: minor` (single-sentence wording).

**Proposed new Phase-5 discipline:**

> All section-content writing — drafts AND revisions — goes through a writer dispatch wrapped in a sentinel. The `main-direct: minor` and `main-direct: adjudication` audit tags are deprecated. The **`writer-overhead` audit tag survives under the narrow Q3 definition** (spelling, duplicated word, broken Markdown, obvious syntax/format artifact — no semantic changes, no sentence rewrites) as the single explicit escape hatch. Even single-sentence fixes that change meaning, tone, framing, or technical content go to a writer dispatch. Lockstep / workflow / memory / STATE.md / cue / TOC / chapter-overview / README / CLAUDE.md edits are NOT section-content writing and remain main-direct (these are coordination, not writing).

**Implications:**

- Per-section deal-loop round count probably stays similar, but every round costs one writer dispatch instead of zero on minor fixes. Net writer-dispatch volume goes up, main-session direct-write volume drops to zero on section content.
- The `main-direct: minor` Phase-5 round-3 commit `7e6ee7f` would have been a writer dispatch under the new rule. The single-sentence fix would have been: write a one-sentence revision sentinel + brief, dispatch the original writer, copy result back, commit `wip(5/5_9_*): writer round 3 minor`. Heavier per-round cost, cleaner separation.
- This rule needs an escape hatch for **adjudication** (when codex CONFLICT and main session disagree about a critique's correctness) — see open question Q2.
- `writer-overhead` tag is still useful for cases where the writer dispatch overhead is disproportionate (e.g., a single typo) — see open question Q3.

---

## Change C — conflict role split by writer model (cross-model adversarial review)

**Current rule (`_workflow/subagents_design.md` §8 + `CLAUDE.md`):**

> Codex-collaborator is the SOLE conflictor. Both writers' drafts are reviewed by codex-collaborator in CONFLICT mode. Same-model bias when codex-writer drafts is mitigated procedurally by Rule 3b (gemini factual spot-check), Rule 3c (codex-bias checklist), Rule 3d (round-4+ cc-writer fresh-eye revision).

**Proposed new rule:**

> Conflict role is split by writer model, with a final-round safeguard for codex-drafts:
> - **cc-writer drafts → codex-collaborator conflicts every round.** Bidirectional convergence (current pattern) — both main session and codex-collaborator must AGREE; main may push back via `CONTESTED: <critique-id> — <category>: <one-line>`. Unchanged from current spec.
> - **codex-writer drafts → main session conflicts rounds 1..N-1; codex-collaborator does a final-round sanity pass at round N, with re-review after any fix (per wf-c7).** Main session unilaterally drives the deal-loop until it has no further critiques. Before declaring AGREED, main dispatches codex-collaborator for one CONFLICT round acting as an independent sanity check. If codex-collaborator raises any critique, main must either (a) re-dispatch writer to fix, then re-dispatch codex-collaborator for another final-round pass on the changed text — looping until codex-collaborator AGREEs on the actual final state — or (b) push back via `CONTESTED:`, which is itself an independent-reviewer-resolvable disagreement. **The fix-then-AGREED-without-re-review path is closed:** any change made in response to a codex-collaborator final-round critique requires a fresh codex-collaborator pass on the fixed text. Convergence requires codex-collaborator AGREED on the actual final commit, not just on a pre-fix version.
> - Gemini still does NOT conflict. Gemini's role remains research (Phase 1) and content-risk-triggered factual spot-check on codex-drafted (Rule 3b — kept unchanged, see Q4).

**Implications:**

- Cross-model adversarial review provides the primary same-model bias break (main on codex; codex on cc); the codex-collaborator final-round sanity pass on codex-drafts provides the safeguard against main-session blind spots when main is the only conflictor for the now-default writing path.
- Bidirectional convergence becomes asymmetric:
  - cc-drafted: bidirectional every round (main ↔ codex-collaborator) — unchanged.
  - codex-drafted: unilateral main rounds 1..N-1; bidirectional final round (main + codex-collaborator) before AGREED. `CONTESTED:` applies only at the final-round bidirectional step.
- Rule 3b (gemini factual spot-check on codex-drafted) — kept unchanged from current spec ("rerun on factual changes" — content-risk-triggered, not round-number-narrowed). Codex correctly pushed back on a narrower-than-current proposal in round 1.
- Rule 3c (codex-bias checklist after every substantial codex-writer revision) — the codex-bias checklist's axes (markdown over-listing, analogy register, foundational example choice, depth defaults) overlap heavily with what main session covers in conflict review. Recommend: deprecate Rule 3c as a separate procedural step; main session's conflict review explicitly checks these axes (subagents_design.md adds a one-line reminder: "main-as-conflictor on codex-drafts must check the legacy Rule 3c axes in every round"). The checklist becomes part of main's conflict prompt, not a separate run.
- Rule 3d (round-4+ cc-writer fresh-eye revision on codex-drafted residual editorial disagreement) — KEPT and STRENGTHENED. Under the asymmetric convergence model, main-vs-codex-writer stalemates have no model-side break until the final-round codex-collaborator pass. Rule 3d remains available as the writer-side break: at round 4+ on a codex-drafted section where main has applied the same critique 3+ times without codex-writer convergence, dispatch a cc-writer fresh-eye revision on the disputed passage.

---

## Implication chain — net usage budget effect

**Old Ch 5-shape budget (rough, per chapter):**

- ~5 cc-writer drafts (heavy Claude work each)
- ~5 codex-writer drafts (Codex usage)
- ~10 codex-collaborator conflict cycles, ~3 rounds avg = ~30 critique cycles (Codex usage)
- ~10 main-direct minor revisions across all sections (light Claude work)
- ~main-session orchestration: research integration, brief construction, dispatch, validation, commit, lockstep (medium Claude work)

**New Ch 5-shape budget (rough, per chapter):**

- ~2 cc-writer drafts (heavy Claude work each)
- ~8 codex-writer drafts (Codex usage)
- ~2 codex-collaborator conflict cycles on cc-drafts, ~3 rounds avg = ~6 critique cycles (Codex usage)
- ~8 main-session conflict cycles on codex-drafts, ~3 rounds avg = ~24 critique cycles (Claude usage, **new**)
- 0 main-direct minor revisions (deprecated under Change B)
- ~main-session orchestration: same as before
- All revision rounds (~30 across the chapter) become writer dispatches under Change B.

**Net Claude usage:**

- −3 heavy cc-writer drafts → big saving
- +24 main-session conflict critique cycles → significant addition
- 0 main-direct minor revisions → zero saving (negligible category before)
- All revision rounds dispatched, but the dispatches go to whichever writer drafted the section (so the heavy Claude work is on the cc-revised rounds, light Claude orchestration on the codex-revised rounds)

**Estimate:** Claude usage net should drop because each cc-writer draft (heavy multi-paragraph synthesis) is substantially more costly than 3 conflict critique rounds (each is a focused review). Codex usage net rises (more drafts + conflict on cc-drafts + final-round sanity pass on codex-drafts). Both budgets stay below their respective limits if the user's intent is correct that Claude usage is the binding constraint.

**Measurement caveat (per codex round-1 wf-c4):** the arithmetic above is asserted, not measured. Main-session conflict cycles on codex-drafts may end up heavier than projected (each requires a full-section read + state context + structured critique). Batch 4 (§5.10 cc-writer per Change A; this means the first measurable codex-drafted section under the new rules will be the first §5.10 round of any future chapter, not Ch 5). **The first codex-drafted section dispatched under the new rules is the first measurable data point.** If main-session conflict on codex-drafts costs more than projected, re-evaluate the writer ratio in Change A — possibly tighten cc-writer reservation further, or fall back to 1:1 if usage savings don't materialize.

---

## Open questions for the deal-loop

**Q1 — How tight is "the chapter explicitly classified this section as contested framing / high-judgment synthesis"?** **(resolved per codex round-1 wf-c2 + round-2 wf-c8)**

**Resolution:** classification is the Phase-3 deal-loop's responsibility, finalized once per chapter, **no mid-run fallback**. Ch 5's 5 sections classified at Phase 3 (§§5.4, 5.6, 5.7, 5.9, 5.10) all stay cc-writer for the remainder of Ch 5. New chapters: Phase-3 plan classifies each section and codex-collaborator adjudicates in the chapter-plan deal-loop. Once the chapter plan reaches AGREED, writer assignment is locked. The **previously-considered "AND codex-writer round 1 failed" branch is rejected** — that judgment would itself be a high-judgment call main session should not make alone, exactly the wf-c2 concern.

**Q2 — When main session and codex-collaborator disagree on a critique, who adjudicates?**
Under the current bidirectional rule, both must AGREE. Under Change B, main can no longer apply edits directly even when codex-collaborator's critique is wrong. What's the escape hatch? Three options:
- (a) dispatch the original writer with the critique + the rationale for rejecting it; let the writer judge.
- (b) main session writes a `CONTESTED: <critique-id> — <category>: <one-line>` rationale and codex-collaborator must agree with the contest before the round closes (current pattern).
- (c) main session writes the contest, dispatches the writer for a "no-op revision with rationale recorded" so the writer can document the contest in the section's deal-loop log without changing content.
Recommend (b) — preserve current bidirectional protocol — but Change B blocks main from applying the no-change result directly. Resolution: contest is itself a coordination act, not a write; main can record the contest in commit message + STATE.md without writer dispatch.

**Q3 — Single-typo / wikilink fixes — escape hatch?** **(resolved per codex round-1 wf-c5)**

Change B says all section-content writing goes through writers. A single-character typo fix would need: revision brief + sentinel + writer dispatch + copy back + commit. That's ~10× the overhead of the fix itself.

**Resolution:** Keep `writer-overhead` audit tag with codex's verbatim narrow definition: **spelling, duplicated word, broken Markdown, obvious syntax/format artifact. No semantic changes. No sentence rewrites. If it changes meaning, tone, framing, or technical content, dispatch to writer.** This is the only `main-direct` exception that survives Change B; `main-direct: minor` and `main-direct: adjudication` are deprecated. The `writer-overhead` tag is the explicit escape hatch with audit-trail and the narrow definition above is binding — any ambiguity is resolved by dispatching the writer.

**Q4 — Is Rule 3b (gemini factual spot-check on codex-drafted) still needed?** **(resolved per codex round-1 wf-c3)**

**Resolution:** Keep current Rule 3b unchanged ("rerun only when a codex-writer revision adds or materially changes factual claims"). Codex correctly pushed back on a first-round-only narrowing — revisions can introduce factual errors, especially under critique pressure. The trigger is content-risk (substantial factual revision, newly added examples, external claims, safety/regulatory claims, changed technical explanations), not round-number. Gemini provides the only externally-fresh factual eye on codex-drafts; removing or narrowing that loses externality main session and codex-collaborator (final-round only) cannot replicate.

**Q5 — Are Rule 3c (codex-bias checklist) and Rule 3d (round-4+ cc-writer fresh-eye) still needed?** **(resolved per codex round-1 — folded into Change C above)**

**Resolution:**
- Rule 3c — **deprecated as a separate procedural step but the named axes are preserved (per wf-c9).** The codex-bias checklist's four axes — **markdown over-listing**, **analogy register**, **foundational example choice**, **depth defaults** — are folded into main session's conflict-review prompt for codex-drafts as a binding named-axis check. The dispatch prompt and `_workflow/subagents_design.md` Phase 5 must explicitly enumerate all four axes; a vague "check for codex-style bias" is insufficient. `feedback_phase5_revisions.md` (or its successor) reflects the absorption with the four axes named verbatim.
- Rule 3d — **kept and strengthened, with sameness defined by issue identity not wording (per wf-c10).** At round 4+ on a codex-drafted section, dispatch a cc-writer fresh-eye revision on the disputed passage when main has raised the same critique 3+ times without codex-writer convergence. **"Same critique" is defined by three factors that must all match across rounds: same passage (line-anchored), same unresolved defect (not a paraphrase that introduces a different requested outcome), same requested outcome.** Persistent critique IDs (e.g. `5.X-r2-c3` reused across rounds 2/3/4 when the concern persists) are required so the trigger is not gameable by varying phrasing. This is the writer-side break, distinct from the final-round codex-collaborator sanity pass which is the model-side break.

---

## Lockstep edits required after AGREED

**Code/spec/memory:**

1. `_workflow/subagents_design.md` — verbose authoritative spec.
   - §5 Rule 3a — rewrite (codex-writer default).
   - §5 Rule 3b — update per Q4 resolution.
   - §5 Rule 3c — update or deprecate per Q5 resolution.
   - §5 Rule 3d — update per Q5 resolution.
   - §8 / Phase 5 — rewrite to reflect Change B (all writing through writers; deprecate `main-direct: minor / adjudication`; keep `writer-overhead` per Q3).
   - §8 / Phase 5 — rewrite to reflect Change C (conflict role split by writer model; main session new role as conflictor for codex-drafts; bidirectional/unilateral asymmetry per Q2).

2. `CLAUDE.md` — "Subagents and the per-chapter pipeline" section.
   - Agent team: main session role expands to include conflictor for codex-drafted.
   - Phase 5 description: rewrite per Change B + C.
   - Convergence protocol: asymmetric per Change C.
   - Bias-mitigation rules: rewrite per Q4/Q5 resolution.

3. Memory files:
   - `feedback_subagent_design.md` — update.
   - `feedback_writer_subagents.md` — update.
   - `feedback_phase5_revisions.md` — substantial rewrite (or new file `feedback_phase5_writer_only.md` and supersede the old one).
   - Possibly new `feedback_conflict_role_split.md` if Change C deserves its own concise reference.
   - `MEMORY.md` — index updates.

4. `_workflow/STATE.md` — `next_action` updates to reflect new Batch-4 process under the new rules.

5. `_workflow/next_session_cue.md` — Batch-4 cue rewritten under the new rules.

**Single `lockstep(workflow): codex-writer default + writer-only revisions + conflict role split by writer` commit covers all of the above.**

**Pre-commit consistency checklist (per codex round-1 wf-c6) — main session runs this before staging the lockstep commit:**

1. `grep -rn "main-direct: minor\|main-direct: adjudication"` — every match is either deleted or relabeled `writer-overhead` per the narrow definition. Both deprecated tags are gone everywhere.
2. `grep -rn "Rule 3a\|Rule 3b\|Rule 3c\|Rule 3d"` — every reference is updated to the new rule set: 3a (codex-default), 3b (unchanged content-risk-triggered), 3c (deprecated, folded into main-as-conflictor prompt), 3d (kept, strengthened).
3. `grep -rn "1:1\|1cc:1codex\|5cc:5codex\|cc-writer.*default\|codex-writer.*default"` — every ratio reference is updated to the new codex-default rule.
4. `grep -rn "codex-collaborator is.*sole conflictor\|sole.*conflictor"` — every claim that codex-collaborator is the sole conflictor is updated to reflect the writer-model split.
5. `grep -rn "main session.*not.*conflict\|main.*orchestrator only\|main session.*sole orchestrator"` — every claim that main does not conflict is updated.
6. Cross-file consistency: CLAUDE.md "Subagents and the per-chapter pipeline" section + `_workflow/subagents_design.md` Phase 5 + memory `feedback_phase5_*` + memory `feedback_writer_subagents.md` + memory `feedback_subagent_design.md` — all four sources describe the same Phase 5 process. Any contradiction is a blocker.
7. STATE.md `next_action` + cue Step 4 (Phase-4 brief deal-loop) + cue Step 7 (Phase-5 deal-loop) — both reflect the new rules.

If any item fails, fix and re-check. The lockstep commit lands only when every item passes.

---

## What does NOT change

- Phase 1–3 process (research, deal-loop, plan).
- Phase 6 (chapter voice pass).
- Strategy C+ commits with the six-prefix taxonomy.
- The full-repo clean-state precondition for writer batches.
- The batch sentinel + PreToolUse hook mechanism.
- The codex-writer worktree mechanism.
- Gemini's role in Phase 1 (research) — never a conflictor.
- The fundamental discipline rules (never modify before AGREED; lockstep updates; no open questions for user).
- Strategy C+ commit prefix taxonomy (`wip / revert / agreed / plan / chapter / lockstep`).
