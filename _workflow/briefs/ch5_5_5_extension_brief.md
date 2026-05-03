---
title: §5.5 classical tracking — extension brief
doc_type: section-extension-brief
chapter: 5
section: 5
phase: 4-extension
writer: codex-writer
status: draft
created: 2026-05-03
related:
  - "[[ch5_chapter_plan]]"
  - "[[ch5_extension_plan]]"
tags: [workflow, chapter-5, extension, brief, codex-writer]
---

# §5.5 classical tracking — extension brief

Sequential after §5.4 AGREED `2d2a3a9`. Inherits all pilot+§5.1+§5.2+§5.4 calibration.

> [!info] Section assignment
> - **Section path:** `chapter_5_classical_lidar_detection/5_5_classical_tracking_EN.md`
> - **Writer:** **codex-writer** (round-W). §5.5 originally codex-drafted; lightweight protected-framing.
> - **Length:** **5500–7000 words** (target ~6200, trim 6500, ceiling 7000; current 3773 → ~1.7× expansion). Largest non-§5.7 section per chapter plan Item 1.
> - **Anchor algorithm:** **CV-KF (constant-velocity Kalman filter)** as the **mathematical foundation** with full implementation depth (Bayesian recursive-estimator state + prediction + measurement + covariance evolution + dt-handling + NIS gating). **AB3DMOT (Weng & Kitani 2020) is the end-to-end synthesis closer** that integrates CV-KF + Hungarian + lifecycle into a complete tracking-by-detection system; presented after the foundations are established (round-1 codex e1-c3 fix: anchor = first-principles foundation; AB3DMOT = synthesis that ties together CV-KF + Hungarian + lifecycle). AB3DMOT's role is "the published baseline most readers will encounter in literature and reproduce as a starting reference," not "the most-mechanically-interesting algorithm — that's CV-KF + Hungarian." (Round-1 codex e1-c2 fix: don't overstate AB3DMOT as canonical baseline for everything; specify "the canonical published LiDAR 3D MOT baseline used as the reference end-to-end pipeline in academic + open-source contexts," which is more accurate than "canonical baseline" alone.) IMM, CTRV/CTRA, JPDA, MHT non-anchor; Hungarian gets full mechanics depth as the foundation for AB3DMOT's association step.
> - **Workflow gate:** Path B → AGREED → §5.6.

**Binding taxonomy:** five canonical blocks. Compatible with the multi-method shape of §5.5 (similar to §5.2's multi-method case): the family-level five-block coverage is enforced; per-method sub-blocks within Mechanics carry the per-method depth.

## 0. Round-1 codex e1-c1 — AB3DMOT state-vector dimensionality (gemini-pending)

The AB3DMOT state-vector dimensionality is being verified by gemini Rule 3b spot-check: 10D `(x, y, z, vx, vy, vz, l, w, h, yaw)` per the original Weng & Kitani 2020 paper, vs 11D adding `yaw_rate`. The brief defaults to **10D** per the most common AB3DMOT references; the writer applies whichever gemini confirms. If gemini refutes both candidates, defer to writer's research and flag in manifest.

## 1. Per-algorithm gap analysis

Current §5.5 has 8 algorithm sections (CV-KF, CTRV/CTRA, IMM, Association/Hungarian/JPDA/MHT, AB3DMOT, lifecycle, camera-tracker handoff) + Output contract. Anchor (AB3DMOT) Concept + Mechanics decent; per-method depths uneven.

- **CV-KF (entry baseline):** Concept ✓; Mechanics ◐ (state vector, transition, measurement, prediction-update sketched, no full implementation depth — Q/R covariance choices, dt-handling, NIS test, observability discussion); Worked Example ✗; Usage ◐ (defaults missing); Failure Modes ◐ (turn-divergence catalog row referenced).
- **CTRV/CTRA (non-anchor):** Concept ✓; Mechanics ◐ (yaw-rate state mentioned, Jacobian-EKF or UKF implicit); Worked Example ✗.
- **IMM (non-anchor):** Concept ✓; Mechanics ◐ (mode-mixing + likelihood-weighted combination sketched); Worked Example ✗.
- **Association (Hungarian / JPDA / MHT) family:** Concept ✓ for each; Mechanics ◐ for Hungarian (cost matrix, gating, sentinel costs, padding — already extended in Phase-6 voice pass); JPDA + MHT mention-level; Worked Example for Hungarian ✗.
- **AB3DMOT (anchor):** Concept ✓; Mechanics ◐ (Kalman + Hungarian + 3D-IoU gating + birth/death tested mentioned, no end-to-end walkthrough); Worked Example ✗ (the canonical baseline NEEDS a worked example); Usage ◐; Failure Modes ◐.
- **Track lifecycle (non-anchor):** Concept ✓; Mechanics ◐ (M-of-N confirmation, coast, delete states described).
- **Camera tracker handoff:** mention-level cross-pointer to §4.6.

## 2. Per-algorithm length budget

- **Anchor (CV-KF):** Concept ~150–250 + Mechanics 700–1100 (sub: state-space form + dt-handling ~200–300; prediction step + Q noise model ~150–250; measurement step + R noise + Kalman gain ~200–300; covariance evolution + NIS gating ~150–250) + Worked Example ~200–300 (single-track 3-step prediction-update walkthrough with concrete numbers) + Usage ~200–350 + Failure Modes ~200–300 = **~1450–2300**.
- **AB3DMOT (synthesis closer):** ~900–1300 (Concept + integration story + 11D-or-10D state vector + 3D-IoU gating choice + Worked Example 2 actors × 3 frames + Usage + Failure Modes condensed). The Worked Example here is the integration; CV-KF Worked Example already covers single-track filtering depth.
- **Hungarian (non-anchor; partial extension already in Phase 6):** ~600–900 (cost matrix + gating + sentinel + dummy padding + 3×3 Worked Example).
- **CTRV/CTRA + IMM + JPDA/MHT — three remaining non-anchor blocks:** ~400–650 each = **~1200–1950 combined**.
- **Lifecycle:** ~250–400.
- **Camera tracker handoff (mention-level):** ~100–150.
- **Output contract + side-channel integration (preserved verbatim):** ~600.
- **Failure-mode catalog block (frozen):** ~500.
- **Section framing prose:** ~500–700.
- **Visual artifacts:** track lifecycle state machine + Hungarian cost matrix gating + AB3DMOT pipeline diagram ~250–350.

**Target total:** ~6500–9000 (upper-budget arithmetic). **Aim ~6200; trim threshold 6500; hard ceiling 7000.**

**Cut order (round-1 codex e1-c4):**
1. Trim non-anchor connective prose (CTRV/CTRA, IMM, JPDA/MHT intros and closing sentences).
2. Compress AB3DMOT Worked Example to 2 actors × 2 frames if needed (round-1 codex e1-c5 already made it 2 actors × 3 frames, not 3 × 4).
3. Trim Hungarian Worked Example to a single sentinel-padded 3×3 case.
4. Trim CV-KF Worked Example concrete numbers to a single-step iteration if needed.

**Never trim:**
- Anchor (CV-KF) full Mechanics depth.
- AB3DMOT integration story (state vector + gating choice + lifecycle integration).
- Output contract verbatim.
- Catalog rows.
- §5.4 side-channel integration paragraph.

## 3. Visual artifact discipline

- **Required: track lifecycle state machine** (load-bearing) — ASCII state-transition diagram with birth → tentative → confirmed → coasting → deleted, with M-of-N + coast-K + delete-policy annotations.
- **Recommended: Hungarian cost matrix + gating example** — small 3×3 cost matrix showing assignment with sentinel costs vs gated-out cells (already partially in current §5.5 since the Phase-6 voice pass; verify still present and integrate).
- **Recommended: AB3DMOT pipeline diagram** — Kalman predict → Hungarian assign → update → lifecycle blocks.

## 4. Catalog block

4 rows preserved verbatim. No row text changes.

## 5. Forward / cross-references

- Inputs (preserve): §5.4 binding tuple `(x, y, z, l, w, h, yaw, optional class)` + side-channel metadata; §2 ego-pose for `base_link → odom` transform; §1.4 sensor time sync.
- Outputs (preserve): Ch 7 fusion; Ch 8 prediction.
- Forward to Ch 6 (already present in §5.9 + §5.10): "Tracking (Kalman / IMM / Hungarian / JPDA on top of DL detections)" is one of the five load-bearing-classical-in-DL pieces. **Production stacks commonly use classical trackers on top of learned 3D detection** — phrase consistent with §5.2 and §5.4 narrowing. Acknowledge alternative DL-era patterns (round-1 codex e1-c6): some production stacks now run **learned association** (e.g., transformer-based MOT heads), **learned motion forecasting** that subsumes the tracker's prediction step, and **BEV-temporal-fusion** architectures (e.g., BEVFormer, BEVDet) where temporal consistency is handled by the detector head itself rather than a separate tracker. The bounded claim: classical Kalman + Hungarian survives as one common pattern; learned alternatives also ship; the integration point varies by stack. Specifically avoid "universally" / "always" qualifiers on the classical-tracker survival claim.

## 6. Voice rules

All chapter-plan Item 6 voice rules. Five-block, visual artifact discipline, intra-Ch-5 wikilink as `§N.M`. Tracking-by-detection (capitalized + hyphenated, never "track-by-detect").

## 7. Phase-5 path

Path B (codex-drafted) — main rounds 1..N-1 + codex-collaborator final-round sanity pass. Five-axis review including framing-preservation (light, for §10).

## 8. Frontmatter

```yaml
---
chapter: 5
section: 5
title: Multi-object tracking — Kalman / IMM / JPDA
language: EN
workflow_status: reviewing
tags:
  - book/section
  - book/chapter-5
  - lang/EN
---
```

## 9. Lightweight protected-framing spans

§5.5 was originally codex-drafted; lightweight protection. Preserve verbatim:

1. **The "track in `odom`, not `base_link`" framing paragraph** (line 36 area) — load-bearing operational rule.
2. **The §5.4 input-contract structure with binding tuple + message metadata + side-channel diagnostics + the "must function correctly when fields are absent" robustness rule** (lines 17-26 + the §5.4 side-channel integration paragraph) — verbatim. This is the §5.4-§5.5 binding interface.
3. **The output contract** `(x, y, z, l, w, h, yaw, vel, optional class, track_id, age, status)` + covariance — verbatim.
4. **The Tracking-by-detection callout** (line 44-45) — verbatim.
5. **Cross-section terminology:** `Tracking-by-detection` (capitalized + hyphenated, never "track-by-detect"); `Kalman filter`; `IMM` / `JPDA` / `MHT` / `Hungarian` / `AB3DMOT`; `track_id` / `age` / `status`; `5_5.fm.<short_slug>` ID format.
6. **The frame discipline** (`base_link / odom / map` not interchangeable; tracker math runs in `odom`).
7. **The timestamp / OOSM contract** (line 38) — handling of late detections.

The framing-preservation Path B axis applies in light form.

## 10. Process

1. Read brief + current §5.5 + pilot patterns.
2. Map existing prose to five-block per algorithm. Anchor (AB3DMOT) gets full implementation depth in Mechanics + Worked Example end-to-end on 3 actors × 4 frames.
3. CV-KF entry baseline gets full Mechanics depth.
4. Non-anchor (CTRV/CTRA, IMM, JPDA/MHT) get mechanics-for-reading.
5. Add the visual artifacts.
6. Word-count yourself. Aim ~6200.

## 11. Return manifest

Per pilot pattern. Confirm: file path, word count, per-algorithm five-block coverage, anchor declaration with sub-budget, visual artifacts, catalog status, output contract preservation, side-channel-integration paragraph preserved, new factual-claim inventory.
