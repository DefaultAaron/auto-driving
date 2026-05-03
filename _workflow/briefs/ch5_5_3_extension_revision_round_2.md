---
title: §5.3 extension revision — round 2 brief
doc_type: revision-brief
chapter: 5
section: 3
phase: 5-extension-path-b
round: 2
writer: codex-writer
status: draft
created: 2026-05-03
related:
  - "[[ch5_5_3_extension_brief]]"
tags: [workflow, chapter-5, extension, revision-brief, codex-writer]
---

# §5.3 extension — Path B round-2 revision brief

Phase-5 Path B round 1 (main session conflicts): main raised 4 critiques (c1, c2, c3, c4). c3 is a Rule 3b gemini factual spot-check dispatched in parallel — depending on gemini's findings, you may receive an additional c3-revision instruction in a later round. This round-2 brief covers c1, c2, c4 — the three non-factual prose / pedagogy critiques.

# Critiques to apply

## c1 — Pedagogical inconsistency between β prose and worked example

**Defect:** The prose at the β formula derivation says "for a same-surface case (`d1 ≈ d2`), ... `β` is **close to 90°**", but the first Worked Example uses `d1=10.05, d2=10.0` → β ≈ 34.8°. A reader sees a 5 cm depth fluctuation called "same-surface" yet getting 34.8° — and the gap between "close to 90°" and "34.8°" is unexplained. The reader is left wondering whether 34.8° qualifies as "same-surface" or not, and the section's own threshold (β_thresh = 10°) makes it pass, but the prose said 90°.

**Fix:** Add a reconciliation sentence after the worked example that clarifies the pedagogical scope of "same-surface."

**Acceptable rewrite (illustrative, not binding):**

> The 34.8° figure illustrates an important quantitative subtlety: "same-surface" in this section means *β > β_thresh*, not *β ≈ 90°*. The 90° limit is reached only when `d1 = d2` exactly (or to within a fraction of `α·d`); real surfaces with sub-decimeter depth fluctuation produce angles in the 30°–80° range, all comfortably above the 10° threshold. The classifier does not need β near 90° to declare same-surface — it only needs β to clear `β_thresh`.

The exact wording is the writer's choice; the constraint is that the prose-vs-example gap is closed and the reader knows quantitatively what "same-surface" means.

## c2 — Orphaned intuition restatement

**Defect:** The paragraph at line 209 ("In words: if two adjacent beams hit the same slanted car side, their ranges differ smoothly and `β` stays high. If one beam hits a pedestrian at 12 m and the next goes to a wall at 30 m, the range discontinuity makes the chord nearly aligned with the line of sight, and `β` collapses toward zero.") is now misplaced — it appears AFTER the post-processing block and projection-back description, where its intuition-building purpose is too late. In the original §5.3, this paragraph was right after the β formula derivation, providing intuition before the worked example. The extension moved the worked example up and left this paragraph stranded.

**Fix:** Either:
- (a) **Delete the paragraph** — the worked example with concrete numbers (d1=10.05/d2=10.0 → 34.8°; d1=30.0/d2=10.0 → 0.1°) does the same intuition-building job with arithmetic rather than words. This is the cleaner option.
- (b) **Move the paragraph up** to immediately after the β formula derivation block (before the worked-example block), where it serves as the bridge from formula to numerical example.

Writer chooses (a) or (b); main session leans toward (a) because the worked example is more concrete.

## c4 — Worked Example for β could include the ideal-limit (d1 = d2) case

**Defect:** The worked example shows d1=10.05/d2=10.0 → 34.8° (sub-decimeter depth difference), then briefly mentions d1=10.005/d2=10.0 → β ≈ 81.7° (sub-centimeter difference) without showing the calculation. The full geometric range is not closed because the *ideal limit* (d1 = d2 exactly) is not in the worked example. A reader doesn't see the 90° limit demonstrated.

**Fix:** Add a third numerical case to the same-surface block of the worked example: d1 = d2 = 10.0 (or with `d1 = d2 + ε` for some very small ε, e.g., 1 µm) → β ≈ 90° (specifically: numerator ≈ 0.0349, denominator ≈ 10·(1 - cos α) = 10·(α²/2) = 6e-5, β = atan2(0.0349, 6e-5) ≈ 89.9°). Show the calculation; the reader sees the geometric limit and the d1=10.05 case as two points along the same continuum.

**Acceptable rewrite (illustrative, not binding):**

```
For the geometric ideal limit (d1 = d2 = 10.0):
numerator   = 10.0 · sin(0.00349)         ≈ 0.0349
denominator = 10.0 − 10.0 · cos(0.00349)  ≈ 0.0000610   (= 10 · α²/2 to first order)
β = atan2(0.0349, 6.10e-5) ≈ 89.9°
```

This is the case the prose's "close to 90°" claim refers to. Real surfaces with sub-decimeter depth fluctuation (like the 5 cm in the d1=10.05 case) produce angles 30°–80°, still well above the threshold but not at the geometric limit.

# Process

1. Apply c1 (β-prose reconciliation), c2 (delete or move the orphaned paragraph), c4 (add ideal-limit β=89.9° example).
2. Word-count yourself; the band is 4850–5700, currently at 4966. Expect ~+50–100 words from c1 + c4, ~−40 from c2-deletion or 0 from c2-move. Net should land in 5000–5050.
3. Do not introduce new factual claims (sensor specs, complexity claims, DL-displacement specifics) — those are still under Rule 3b gemini review (c3). If gemini's findings (round-3 input) require revisions, those come in the next round, not this one.

# Hard rules (still binding)

- The five-block coverage stays intact — the changes are within the range-image Mechanics + Worked Example blocks, no other algorithm's blocks are touched.
- Lightweight protected-framing spans (brief §10) preserved verbatim. The β formula text and the existing prose "close to 90°" / "small for depth-jump" intuition language are not in the protected list, but they are part of the original §5.3 derivation that the reader has been studying — keep them, with the c1 reconciliation sentence added.
- Catalog block frozen.
- No new factual claims (numeric / product / paper / runtime / DL) added in this round. The gemini spot-check (c3) is still pending; new claims would have to wait.

# Return manifest expectations

- File path written.
- New `wc -w` word count vs the 4850–5700 band.
- The exact before/after text for c1 (added reconciliation sentence), c2 (paragraph deleted or moved — say which), c4 (added ideal-limit numerical block).
- Confirmation no other content changed.
- Confirmation no new factual claims added beyond the already-AGREED set.
