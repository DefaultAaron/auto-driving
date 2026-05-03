---
title: §5.4 extension — Path B round-2 revision brief (Zhang formulas + foundational example)
doc_type: revision-brief
chapter: 5
section: 4
phase: 5-extension-path-b
round: 2
writer: codex-writer
status: draft
created: 2026-05-03
related:
  - "[[ch5_5_4_extension_brief]]"
tags: [workflow, chapter-5, extension, revision-brief, codex-writer]
---

# §5.4 extension — round-2 revision brief

Phase-5 Path B final-round codex-collaborator sanity pass returned 2 critiques. Both apply now.

## final-c1 — Zhang scoring formulas factually wrong (gemini-confirmed)

Gemini Rule 3b spot-check on the Zhang 2017 paper (IEEE IV 2017) confirmed codex's claim. Current §5.4 lines 78–100 have three factual errors:

### Error 1 — Closeness criterion

**Current (REFUTED):** "minimize sum of distances from each point to the nearest of the four edges":
```text
d_i(θ) = min( |u_i - u_min|, |u_i - u_max|, |v_i - v_min|, |v_i - v_max| )
J_close(θ) = Σ_i d_i(θ)
```

**Correct (CONFIRMED by gemini against Zhang 2017 §III-C / Algorithm 4):**
```text
C(θ) = Σ_i 1 / max(d_i(θ), d_0)
```
where `d_i(θ)` is the distance to the **closest of the two L-shape edges** (not four), `d_0` is a small floor threshold preventing division by zero and capping voting power of near-perfect alignments, and the criterion is **maximized**, not minimized.

### Error 2 — Variance criterion edge groups

**Current (REFUTED):** "first assigns each point to the closest edge and then measures how evenly the edge residuals behave" with **four** edge groups (E_j for j=1..4).

**Correct (CONFIRMED by gemini against Zhang 2017 §III-D / Algorithm 5):** Project the cluster onto the two orthogonal axes for orientation θ. Split points into **exactly two** disjoint sets (E1 / E2) determined by which of the two orthogonal lines (the two edges of the L-shape, not four rectangle edges) they are closer to. The criterion minimizes the sum of variances of these two sets:
```text
E1(θ) = { i : point i closer to first L-edge }
E2(θ) = { i : point i closer to second L-edge }
σ²_1(θ) = variance of d_i for i ∈ E1
σ²_2(θ) = variance of d_i for i ∈ E2
J_var(θ) = σ²_1(θ) + σ²_2(θ)   (minimize)
```
Equivalently, maximize negative variance.

### Error 3 — "Maximize -J_close ≡ minimize J_close" equivalence claim

**Current (line 94, REFUTED):** "Some implementations maximize `-J_close` or a reciprocal score; the decision is the same."

**Correct (CONFIRMED by gemini):** This claim is **false**. Because the reciprocal transformation `f(x) = 1/max(x, d_0)` is applied per-point before summation, `argmin Σ d_i` and `argmax Σ 1/max(d_i, d_0)` behave completely differently:
- `argmin Σ d_i` is L1-like, sensitive to outliers (a single far point can dominate the sum).
- `argmax Σ 1/max(d_i, d_0)` heavily rewards inliers near the edge (each contributes up to 1/d_0) and strongly suppresses outliers (each contributes a small 1/d).

They yield different optimal yaws on noisy real-world data. Remove the equivalence claim.

### Fix

Rewrite lines 78–100 with the corrected formulas. The block structure stays (area / closeness / variance), the area criterion is correct as-is, the closeness and variance criteria need the corrections above. Cite the formulas as Zhang 2017's actual definitions, not as "the common pedagogical default."

Add a short note that production implementations sometimes approximate or tweak these for real-time latency (e.g., `d_0` tuning varies by sensor resolution; some pipelines use only the closeness criterion for speed because variance is computationally heavier).

## final-c2 — Foundational example weak (toy L-cluster too square)

Current Worked Example uses a toy L-cluster ~3.5 × 3.6 m — almost square in BEV. This hides the heading-vs-width convention that §5.4 is supposed to teach.

**Fix:** Use vehicle-realistic proportions. A typical sedan is ~4.5 m × 1.8 m (roughly 2.5:1 aspect ratio). Rebuild the toy example with elongated extents so the reader sees:
- The L's long arm (rear face) at length ~2.5 m visible (half the vehicle's full length)
- The L's short arm (side face) at length ~1.0–1.5 m visible (most of the half-width)
- The full extracted box being ~4.5 × 1.8 m after class-prior back-fill
- Clear `l` (length, along heading) vs `w` (width, perpendicular to heading) distinction

This pedagogically demonstrates that yaw determines `l` direction; a near-square example loses that.

## Hard rules

- Length 5576 → expect minimal delta (formula corrections are similar word counts; pedagogical example is rebuilt with similar word count). Aim within 5500-5700.
- All other content unchanged.
- 8 Safeguard-1 items still preserved.
- Catalog frozen.
- Frontmatter `workflow_status: reviewing`.

## Return manifest

- File path written.
- New `wc -w`.
- Before / after for the closeness criterion math (lines 86-94).
- Before / after for the variance criterion math (lines 95-100).
- Before / after for the "maximize -J_close" equivalence claim removal (line 94 area).
- Before / after for the Worked Example (vehicle-realistic 4.5×1.8 proportions).
- Confirmation no other content changed.
