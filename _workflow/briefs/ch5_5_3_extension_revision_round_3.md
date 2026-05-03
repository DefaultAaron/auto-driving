---
title: §5.3 extension revision — round 3 brief (Rule 3b factual fixes)
doc_type: revision-brief
chapter: 5
section: 3
phase: 5-extension-path-b
round: 3
writer: codex-writer
status: draft
created: 2026-05-03
related:
  - "[[ch5_5_3_extension_brief]]"
  - "[[ch5_5_3_extension_revision_round_2]]"
tags: [workflow, chapter-5, extension, revision-brief, codex-writer]
---

# §5.3 extension — Path B round-3 revision brief (Rule 3b factual fixes)

Phase-5 Path B round 2 closed at commit `a7e0259` (codex-writer applied c1, c2, c4 prose-pedagogy fixes). Round 3 applies c3 — the Rule 3b factual spot-check from gemini-researcher. Gemini returned 3 findings; this round addresses all 3 plus one bonus enhancement.

# Critiques to apply (c3a, c3b, c3c, c3d)

## c3a — VLP-32C non-uniform vertical resolution (gemini Claim 1, PARTIALLY CORRECT)

**Defect (line 185 of current §5.3):** The current text states "VLP-32C `1.33°` vertical and `0.2°` horizontal" as if VLP-32C has uniform 1.33° vertical resolution. Gemini's finding: this is **factually misleading**. The VLP-32C "Ultra Puck" is intentionally non-uniform — the channel distribution gives **0.33° vertical resolution near the horizon (0°)**, expanding to **~1.33° at FOV extremes**. The non-uniform pattern is the sensor's *defining architectural feature* (designed for AV use cases where actor density is highest near the horizon). Stating a single 1.33° value erases this and misleads the reader on what `α` to use for the β test.

**Source (gemini-cited):** Velodyne VLP-32C / Ultra Puck datasheet.

**Fix:** Rewrite the sensor-spec sentence at line 185 to:
- Keep HDL-32E ≈ 1.33° vertical (broadly correct as average across the uniform pattern).
- Keep HDL-64E ≈ 0.4° vertical (gemini agreed with the rough ~0.43° value as average; can simplify to ~0.4°).
- **Replace** the VLP-32C single-value claim with a non-uniform statement: "VLP-32C (Ultra Puck) is non-uniform by design — `0.33°` vertical near the horizon expanding to roughly `1.33°` at the FOV extremes; the dense near-horizon band is the sensor's intended AV operating zone."
- Strengthen the closing line: "A production implementation should use the sensor calibration table, **not a single average**, and especially not for non-uniform sensors like the VLP-32C where the same algorithm sees very different `α` at different elevations."

**Acceptable rewrite (illustrative, not binding):**

> The threshold rationale is geometric, not magical. `β_thresh = 10°` is permissive for smooth surfaces because same-surface pairs with small `α` produce angles near 90°. It is strict for foreground/background discontinuities because a large ratio `d1/d2` collapses the angle toward the line of sight. The sensor's `α` still matters: vertical adjacency for an HDL-32E is uniform at ~1.33°; the HDL-64E samples vertically at ~0.4° on average across its 64-beam non-linear pattern; the VLP-32C "Ultra Puck" is non-uniform by design — ~0.33° vertical near the horizon expanding to ~1.33° at the FOV extremes, the dense near-horizon band being the sensor's intended AV operating zone. Horizontal angular step at 10 Hz is roughly 0.16° for HDL-32E and HDL-64E, 0.2° for VLP-32C. A production implementation should use the sensor calibration table, not a single average, and especially not on non-uniform sensors where the same algorithm sees very different `α` at different elevations.

## c3b — PointNet/PointNet++ → PointPillars/CenterPoint as production replacement (gemini Claim 3, PARTIALLY CORRECT)

**Defect (lines 94, 242):** Two places state PointNet / PointNet++ as the primary production replacement for classical clustering. Gemini's finding: this is **historically and technically inaccurate**. PointNet families are primarily **research baselines**, not production-stack proposal generators (the computational expense of permutation-invariant point-wise operations doesn't scale to 100k+ points/frame in a real-time perception loop). The actual production replacements in L4 robotaxi / consumer NOA stacks are **voxel-based and pillar-based architectures**: SECOND (Yan 2018), PointPillars (Lang 2019), CenterPoint (Yin 2021). These transform the cloud into pseudo-images or dense tensors for efficient GPU convolutions.

**Sources (gemini-cited):**
- PointPillars: Fast Encoders for Object Detection from Point Clouds — Lang et al., CVPR 2019.
- Center-based 3D Object Detection and Tracking — Yin et al., CVPR 2021.

**Fix:**

**Line 94 (Euclidean clustering DL displacement story):** Replace "PointNet / PointNet++-style point-set semantic segmentation or voxel networks normally own the primary proposal path" with "voxel- and pillar-based architectures (SECOND, PointPillars, CenterPoint) own the primary proposal path; PointNet / PointNet++ remain research baselines because permutation-invariant point-wise operations don't scale to 100k+ points/frame in real-time perception."

**Line 242 (closing paragraph DL displacement story):** Replace "PointNet++ and voxel/point transformer families mostly displace Euclidean and DBSCAN as primary proposal generators in open-road DL stacks" with "voxel-grid and pillar-based detectors (SECOND, PointPillars, CenterPoint) displaced Euclidean and DBSCAN as primary proposal generators in open-road DL stacks; PointNet / PointNet++ are research baselines, not production proposal generators."

**Acceptable rewrites — both lines are constrained by the lightweight protected-framing list (§10 of the original brief).** Line 242 is *adjacent* to the bounded "Where classical clustering still ships" deployment paragraph (which is verbatim-protected at level 1) and the four-narrower-roles list (level 2 content-protected). The rewrite of line 242 is *adjacent* and qualifies as allowed local elaboration; do not touch the bounded paragraph itself.

## c3c — Bogoslavskyi 2016 runtime numbers (gemini Claim 2, CONFIRMED with bonus material)

**Defect:** Line 211 states "It is `O(N)` over occupied pixels, cache-friendly, and deterministic." Both claims confirmed by gemini against the original IROS 2016 paper. **The paper provides empirical runtime numbers** the section currently does not cite: **>100 Hz for 64-beam scans, >400 Hz for 16-beam scans on a single mobile CPU core**. These would significantly strengthen the Mechanics block's "fast" claim and give the reader a concrete budget point.

**Source:** Bogoslavskyi & Stachniss, "Fast Range Image-Based Segmentation of Sparse 3D Laser Scans for Online Operation," IROS 2016.

**Fix:** Add the runtime numbers to line 211. Acceptable rewrite:

> Range-image clustering is attractive before voxelization or after preserving ring/azimuth metadata. It is `O(N)` over occupied pixels, cache-friendly because the algorithm iterates over contiguous 2-D array memory rather than chasing pointers through a KD-tree, and deterministic. The original paper reports **>100 Hz on 64-beam scans and >400 Hz on 16-beam scans on a single mobile CPU core** (Bogoslavskyi & Stachniss, IROS 2016) — substantially faster than KD-tree Euclidean clustering on equivalent hardware. It also keeps scan-line evidence that Euclidean clustering loses.

This is c3c — a strengthening, not a correction. Apply it.

## c3d — DBSCAN-vs-strict-Euclidean nuance (gemini bonus point)

**Defect (line 123):** Gemini flagged that "production stacks frequently favor a highly optimized, strict KD-tree Euclidean clustering over true DBSCAN for deterministic runtime latency." The current §5.3 does not state this nuance — readers may assume DBSCAN is the natural production upgrade from Euclidean when in fact production often goes the other direction (strict Euclidean for latency determinism).

**Fix (light, optional):** Append one sentence to the DBSCAN closing paragraph (around line 123) acknowledging the production-latency-determinism preference for strict Euclidean. Acceptable rewrite:

> ... DBSCAN remains a useful diagnostic baseline: if a learned detector misses an object that DBSCAN groups cleanly, the failure is probably semantic or training-data related; if DBSCAN also fails, the raw geometry may be too sparse or contaminated. **Production stacks often favor a highly optimized, strict KD-tree Euclidean clustering over true DBSCAN, not because DBSCAN's noise model is wrong but because Euclidean's runtime is more deterministic — DBSCAN's region-query cost varies with local point density in a way the scheduler must absorb.**

Apply if you can fit it without exceeding the 5700-word ceiling. If the round-3 changes already push close to 5700, defer c3d to a later micro-revision.

# Hard rules (still binding)

- Length band 4850–5700; current 5005. Round-3 changes (c3a expansion, c3b two-place rewrite, c3c runtime sentence, optional c3d) likely add ~50–120 words. Net target ~5050–5150. **Do not exceed 5700.**
- **Lightweight protected-framing spans** (original brief §10) preserved. The bounded "Where classical clustering still ships" paragraph (line 234) is verbatim-protected at level 1; the four-narrower-roles list is level-2 content-protected. The c3b rewrite of line 242 is *adjacent* to the bounded paragraph and qualifies as allowed local elaboration; **do not modify line 234 itself**.
- **No catalog row text changes.** Catalog block frozen.
- **No new factual claims beyond gemini-confirmed ones.** Specifically:
    - Sensor specs: HDL-32E 1.33°, HDL-64E ~0.4°, VLP-32C non-uniform 0.33°–1.33°.
    - Bogoslavskyi runtime: >100 Hz / >400 Hz from the paper.
    - DL displacement: voxel/pillar (SECOND / PointPillars / CenterPoint) for 3D detection; RangeNet / SqueezeSeg for range-image semantic.
    - DBSCAN-vs-Euclidean production-latency-determinism nuance.
    - **Do not introduce any other new factual claim** in this round; if you encounter a tempting addition, log it as a future-revision candidate in the manifest.

# Return manifest expectations

- File path written.
- New `wc -w` word count vs the 4850–5700 band.
- The exact before/after text for c3a (sensor spec rewrite at line 185), c3b (DL displacement rewrites at line 94 + line 242), c3c (Bogoslavskyi runtime addition at line 211), and c3d if applied (DBSCAN-vs-Euclidean nuance at line 123).
- Confirmation no other content changed.
- Confirmation no new factual claims beyond the gemini-verified set.
- Confirmation the bounded "Where classical clustering still ships" paragraph (line 234) is unchanged.
