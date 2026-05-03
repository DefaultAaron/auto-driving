---
title: §5.10 Phase-5 round-2 revision brief
doc_type: revision-brief
chapter: 5
section: 10
batch: 4
writer: cc-writer
phase: 5
round: 2
status: draft
created: 2026-05-03
related:
  - "[[ch5_5_10_safety_and_validation_brief]]"
tags: [workflow, chapter-5, batch-4, revision-brief, cc-writer]
---

# §5.10 Phase-5 round-2 revision brief

Round-1 codex-collaborator critique returned 6 numbered defects. Apply each in the existing §5.10 file. Do not introduce new content beyond what these fixes require. Do not rewrite the catalog index. Word-count yourself against the **binding 2000–2200 word band** before returning.

## r1-c1 — mAP factual overclaim on track-continuity entries

**Defect:** The current text says "`5_5.fm.id_switch_under_occlusion`, `5_5.fm.coasted_track_outlives_object`, and `5_5.fm.ghost_track_from_clutter` leave per-frame numbers untouched while breaking Ch 7 fusion and Ch 8 prediction." Ghost tracks (`ghost_track_from_clutter`) and stale tracks (`coasted_track_outlives_object`) emit boxes that *do* show up as false positives in per-frame mAP and degrade precision. The "untouched" claim is wrong for those two. ID switch (`id_switch_under_occlusion`) is correctly invisible per-frame because the box still matches; only the identity changes.

**Fix:** Narrow the claim to **identity / continuity** being invisible to per-frame mAP. Acknowledge that ghost or stale boxes can be penalized as false positives when they appear in evaluated frames. Keep the cross-frame critique — that's the real point — but do not overstate what per-frame mAP misses.

**Acceptable rewrite (illustrative, not binding):** "Track continuity and identity: mAP is per-frame, so the *identity* in `5_5.fm.id_switch_under_occlusion` is invisible to per-frame matching even though the box itself matches. Ghost or stale boxes from `5_5.fm.ghost_track_from_clutter` and `5_5.fm.coasted_track_outlives_object` *can* register as per-frame false positives where they fall in evaluated frames; what mAP cannot see is that the same identity is being persisted incorrectly across frames, which is the failure shape Ch 7 fusion and Ch 8 prediction inherit."

## r1-c2 — mAP factual overclaim on scheduler starvation

**Defect:** The current text says "`5_cross.fm.subrate_registration_starves_under_load` is invisible to per-frame mAP by construction." Codex is right: if scheduler starvation produces stale or ghost detections in runtime logs, per-frame mAP can see them. What per-frame mAP does *not* directly measure is scheduling freshness, sub-rate cadence, or correlated runtime overload behaviour as causal phenomena.

**Fix:** Rephrase to: per-frame mAP does not directly measure scheduler freshness, sub-rate cadence, or correlated tail-load behaviour, even though downstream false positives or misses *can* affect mAP when evaluated on runtime scenarios.

**Acceptable rewrite (illustrative):** "Behaviour-level correctness: whether ego's gap to a leading actor is right, whether free-space is honestly cleared, whether the system silently drops a frame under correlated tail load. `5_cross.fm.subrate_registration_starves_under_load` produces false positives that per-frame mAP *can* register on runtime scenarios; what mAP does not measure is the scheduling-freshness causal mechanism — that the failure originates in the scheduler missing a sub-rate slot, not in the algorithms themselves."

## r1-c3 — Bucket placement: `5_7.fm.map_suppresses_real_actor` should NOT be in Bucket 3

**Defect:** Currently in Bucket 3 (cross-stage). The host row's mitigation lives entirely inside §5.7's wiring and policy: "Run Generic Obstacle Detection on the ungated occupancy grid in parallel with ROI-gated per-class detection; require the planner to consume the union; widen the ROI by a buffer (e.g., 2 m) around drivable polygons." All three are §5.7-internal architecture / configuration choices, not a different-stage fix. By the binding "where the fix lands" rule, this is **not** cross-stage.

**Fix:** Move `5_7.fm.map_suppresses_real_actor` to **Bucket 4 (configuration / scheduler / deployment-time)** because the dominant fix is system-wiring / deployment-policy (run Generic Obstacle Detection ungated in parallel; planner union; ROI buffer width). All three are configuration / architecture decisions rather than algorithm-correctness changes inside a single stage's algorithm. Update Bucket 3 row count from 4 → 3 and Bucket 4 row count from 11 → 12.

**Note:** The other Bucket 3 entries — `5_cross.fm.deskew_then_cluster_doubling`, `5_7.fm.localization_drift_offsets_roi`, `5_7.fm.ray_casting_through_glass` — stay in Bucket 3 because their fixes genuinely span §5.1 + §5.3 / §5.6 + §5.7 / §5.1 + §5.7 respectively.

## r1-c4 — Terminology drift: "GOD" abbreviation leaked into the prose and index

**Defect:** "GOD" appears in three places ("ungated GOD fallback", "GOD may miss pedestrians behind glass" in the Bucket 3 hazard cell for `5_7.fm.ray_casting_through_glass`, and "why the GOD fallback is wired ungated" in the Ch 11 vocabulary callout). The terminology contract has only "Generic Obstacle Detection" capitalized; the abbreviation is not a sanctioned short form.

**Fix:** Replace every "GOD" with either "Generic Obstacle Detection" (where the full term reads naturally) or "the occupancy fallback" / "the class-agnostic fallback" (where repetition is too heavy). Verify the Bucket 3 hazard cell for `5_7.fm.ray_casting_through_glass` stays ≤ 15 words after the substitution.

## r1-c5 — Length: 2291 words exceeds the 2000–2200 binding band

**Defect:** Whole-file `wc -w` is 2291; codex's prose-only count is ~1199 (i.e., ~91 words over after subtracting frontmatter and table cell pipes — the overage is real, not artifact). The brief's compression discipline is "trim prose blocks 3/4/5 by 10–15% each before touching the index."

**Fix:** Cut 100–150 words from the three prose blocks (3 = "What the index reveals at chapter scale", 4 = "mAP as a planning-usefulness proxy: necessary, not sufficient", 5 = "ODD anchor and the informal practical safety argument"). Distribute the cuts ~40 / 60 / 40 words. The mAP block grew slightly under r1-c1 + r1-c2 fixes, so absorb those additions inside the trim. **Do not touch the catalog index.** **Do not cut the Ch 11 vocabulary callout.**

## r1-c6 — Cell-cap violation in `5_9.fm.frame_budget_overrun_p99` cause cell

**Defect:** The Bucket 4 row for `5_9.fm.frame_budget_overrun_p99` has cause cell "Correlated tails on §5.6 + §5.3 + §5.2 push the every-frame chain past 100 ms" — codex counts this as exceeding the ≤ 15-word cap (e.g., "every-frame" as a hyphenated compound and "100 ms" both contribute >1 word in their counting).

**Fix:** Compress the cause cell to ≤ 15 words conservatively. Suggested: "Correlated stage tails push the every-frame chain past the 100 ms 10 Hz frame budget." (~13 words). Or "Correlated tails across stages push the every-frame chain past 100 ms." (11 words). Pick whichever preserves the cause-class semantics best.

## Process

1. Apply r1-c1 + r1-c2 to the mAP block. Expect a small word-count increase from the more-precise wording — that is fine, the r1-c5 trim absorbs it.
2. Apply r1-c3: move `5_7.fm.map_suppresses_real_actor` from Bucket 3 to Bucket 4. Update bucket headers' row counts.
3. Apply r1-c4: global replace "GOD" with "Generic Obstacle Detection" or contextual variants. Verify no Bucket-3-or-4 cells exceed 15 words after the swap.
4. Apply r1-c6: compress the `5_9.fm.frame_budget_overrun_p99` cause cell to ≤ 15 words.
5. Apply r1-c5: trim prose blocks 3/4/5 by 100–150 words total. Run `wc -w` on the file before returning; the binding band is 2000–2200.
6. Do not touch the index entries other than r1-c3 (bucket move) and r1-c6 (cell compression). Do not change the section structure. Do not introduce new claims.

## Return

Return a manifest with: file path written, new word count, bucket distribution recount (should be 18 / 4 / 3 / 12 = 37 after r1-c3 fix), the explicit text of every change made (so codex can verify in round 2), any deviations.
