---
title: §5.6 registration — extension brief
doc_type: section-extension-brief
chapter: 5
section: 6
phase: 4-extension
writer: codex-writer
status: draft
created: 2026-05-03
related:
  - "[[ch5_chapter_plan]]"
  - "[[ch5_extension_plan]]"
tags: [workflow, chapter-5, extension, brief, codex-writer]
---

# §5.6 registration — extension brief

Sequential after §5.5 AGREED `37bac3a`. §5.6 originally cc-drafted (theoretically loaded math + four-perception-roles framing). Round-W: all-codex with **FULL Safeguard-1** protected-framing-spans (not lightweight).

> [!info] Section assignment
> - **Section path:** `chapter_5_classical_lidar_detection/5_6_registration_EN.md`
> - **Writer:** **codex-writer**. FULL Safeguard-1.
> - **Length:** **4500–6000 words** (target ~5500, trim 5800, ceiling 6000; current 2697 → ~2.0× expansion).
> - **Anchor algorithm:** **ICP (point-to-point + point-to-plane variants).** It is the foundational algorithm; NDT and GICP are improvements over ICP that the reader can only fully appreciate after understanding ICP's correspondence + alignment iteration. NDT and GICP are non-anchor with mechanics-depth-for-reading.
> - **Workflow gate:** Path B → AGREED → §5.7.

**Binding taxonomy:** five canonical blocks.

## 1. Per-algorithm gap analysis

Current §5.6 has 3 algorithm sections (ICP, NDT, GICP) + Four perception roles + Production references + Failure modes catalog.

- **ICP (anchor):** Concept ✓ (Besl & McKay 1992 + Chen & Medioni 1991 point-to-plane); Mechanics ◐ (correspondence + alignment iteration sketched, Kabsch SVD mentioned, point-to-plane linearization sketched, full implementation depth missing — robust kernels, outlier rejection, downsampling strategy, convergence criteria); Worked Example ✗; Usage ◐ (max iterations / distance threshold mentioned, no parameter ladder); Failure Modes ✓ (failure modes named up front in callout style).
- **NDT (non-anchor with elevated weight):** Concept ✓; Mechanics ◐ (voxel-grid Gaussian + Newton optimization sketched); Worked Example **✗ (round-1 codex e1-c3 fix: NDT cannot stay light because §5.7 map subtraction `compare_map_segmentation` depends on NDT-style scan-to-map; NDT gets a Worked Example and elevated mechanics depth — voxel resolution, covariance degeneracy, score shape, initialization tolerance, ICP-vs-NDT preference rationale)**.
- **GICP (non-anchor):** Concept ✓; Mechanics ◐ (per-point covariance + plane-to-plane formulation sketched); Worked Example optional (compress if budget tight).
- **Four perception roles** (deskew refinement / map subtraction / accumulation alignment / map-aided ROI consistency): present and well-framed in original; no extension needed except cross-referencing into Mechanics blocks above.

## 2. Per-algorithm length budget

- **Anchor (ICP):** Concept ~150–250 + Mechanics 700–1100 (sub: correspondence step + KD-tree + outlier rejection ~200–300; alignment step Kabsch / Horn SVD point-to-point ~150–250; point-to-plane linearization + Gauss-Newton ~200–300; convergence criteria + robust kernels ~150–250) + Worked Example ~250–350 (point-to-point single-iteration walkthrough on small toy correspondence set with concrete numbers) + Usage ~200–350 + Failure Modes ~200–300 = **~1500–2350**.
- **NDT (non-anchor with elevated weight per round-1 codex e1-c3):** ~900–1200 (voxel-grid Gaussian estimation + Newton step + Hessian; voxel resolution choice + covariance degeneracy diagnostics; score shape + initialization tolerance; ICP-vs-NDT preference rationale per §5.7 use case; production parameters; failure modes; Worked Example: small voxel-grid scan-to-map with concrete numbers).
- **GICP (non-anchor):** ~600–800 (per-point covariance from neighborhood; plane-to-plane formulation; Mahalanobis distance; production parameters; failure modes; Worked Example optional and short).
- **Four perception roles:** preserved + minor extension ~600–800 (each role gets a short paragraph; deskew refinement role connects to §5.1 anchor; map subtraction connects to §5.7).
- **Production references** (Open3D, PCL, point_cloud_pyramid, etc.): preserved + minor extension ~200.
- **Failure-mode catalog block (frozen):** ~400.
- **Section framing prose:** ~400–500.
- **Visual artifacts:** ICP correspondence + iteration convergence diagram + NDT voxel Gaussian visualization ~250–350.

**Target total:** ~5650–7000 (upper-budget arithmetic with NDT elevation). **Aim ~5500; trim threshold 5800; hard ceiling 6000.** **Cut order (round-1 codex e1-c6 fix):** (1) trim production-references list breadth first; (2) compress connective prose (intro/closing in each algorithm block); (3) compress GICP Worked Example to a single Mahalanobis-distance computation if needed. **Never trim:** ICP anchor depth, NDT mechanics + Worked Example, four-perception-roles paragraphs, output contract, catalog.

## 3. Visual artifact discipline

- **Required: ICP correspondence + convergence visual** (load-bearing) — small ASCII diagram showing point-to-point pairs, the iteration trajectory in transform space, or the basin-of-convergence region. Place inside ICP Mechanics.
- **Recommended: NDT voxel Gaussian visual** — small voxel grid with per-cell ellipsoid showing the Gaussian distribution NDT fits.

## 4. Catalog block

3 rows preserved verbatim. No row text changes.

## 5. Forward / cross-references

- Inputs (preserve): §5.1 raw point cloud / voxel grid / range image; §5.2 ground residual (registration usually downsamples and aligns on residual + ground separately); §1.1 TF2; §2.1 ego-pose; §2.3 LiDAR localization (the section's parent reference).
- Outputs (preserve): §5.7 occupancy + ROI gating (Roles 2-4 feed §5.7); §5.1 deskew refinement (Role 1 closes the loop with §5.1).
- Forward to Ch 6 (add): production DL stacks **commonly** consume registered / aligned clouds (deskew + accumulation alignment are upstream of every learned 3D detector). Learned registration (3DRegNet, DeepGMR, FCGF + RANSAC, Predator, etc.) exists; in 2024–2026 open-source AV stacks the deployed registration step is most commonly ICP/NDT/GICP variant for stability and well-understood failure modes. Don't claim "deployment-leading" without scoping (round-1 codex e1-c2): the right phrasing is "classical registration remains the more common production choice in open-source AV stacks (Autoware, Apollo, MOLA) as of 2024–2026; learned registration leads on benchmark accuracy but production deployment data is partial and stack-dependent." Phrase consistent with §5.5 narrowing.

## 6. Voice rules

All chapter-plan Item 6 voice rules. ICP / NDT / GICP uppercase (no expansion after first mention); SE(3); Kabsch; Horn; Gauss-Newton; Mahalanobis.

## 7. Phase-5 path

Path B with **FULL Safeguard-1** framing-preservation axis (not lightweight). Five Path B bias axes with framing-preservation strict. Rule 3b two-tier — ICP Besl-McKay 1992 + Chen-Medioni 1991 / NDT Magnusson 2009 / GICP Segal-Haehnel-Thrun 2009 citations are well-known but flag in manifest.

## 8. Frontmatter

```yaml
---
chapter: 5
section: 6
title: Registration — ICP / NDT / GICP
language: EN
workflow_status: reviewing
tags:
  - book/section
  - book/chapter-5
  - lang/EN
---
```

## 9. FULL Safeguard-1 protected-framing spans for §5.6

§5.6 was originally cc-drafted because the "four perception roles" framing is the section's reason to exist. FULL Safeguard-1 treatment.

1. **The "you saw these names in Ch 2 §2.3" framing line** (current line 15) — verbatim. The chapter plan Item 1 explicitly preserves this framing line as binding ("Framing line: 'you saw these names in Ch 2 §2.3; here is how they actually work + four perception uses.'").
2. **The What-this-section-covers `> [!abstract]` callout** (line 17-18) — verbatim. Names the three algorithms + four-roles structure that downstream sections reference.
3. **The four perception roles enumeration** (Roles 1-4: deskew refinement / map subtraction / accumulation alignment / map-aided ROI consistency, with Role 5 being localization handled by Ch 2). **Verbatim-protected** — these are referenced in §5.1 brief, §5.7 brief, §5.9 + §5.10 catalogs. Don't drop a role, don't add a fifth (Role 5 = localization is explicitly Ch 2's, not §5.6's). Don't reorder.
4. **The "ICP is a refiner, not a solver from scratch" callout** ("What 'convergence' means here") — verbatim. Load-bearing pedagogical caveat.
5. **The source/target convention** ("Throughout this section, 'source' is the live cloud being aligned and 'target' is the cloud (or map) it is being aligned to. The output is a rigid transform `T ∈ SE(3)` that maps source-frame points into the target frame.") — verbatim. This is the binding terminology contract for the section.
6. **Cross-section terminology:** ICP / NDT / GICP uppercase; Besl & McKay 1992; Magnusson 2009; Segal/Haehnel/Thrun 2009; Chen & Medioni 1991; Kabsch / Horn SVD; SE(3); 5_6.fm.* IDs; "registration" / "alignment" usage.
7. **The Role-1 / Role-2 / Role-3 / Role-4 nomenclature** is referenced in the §5.7 brief and §5.9 + §5.10 catalogs. Don't rename; don't change role numbers.
8. **Pipeline framing:** "the section earns its place in a *detection* chapter by showing four perception roles registration plays beyond the localization use the reader has already met." This bounded justification is the §5.6-in-Ch-5 thesis.

The framing-preservation Path B axis is **strict**.

## 10. Process

1. Read brief + current §5.6 + pilot patterns.
2. Map existing prose to five-block per algorithm. Anchor (ICP) full implementation depth.
3. NDT + GICP non-anchor mechanics-for-reading.
4. Four perception roles preserved + minor extension.
5. Add the two visual artifacts.
6. Word-count yourself. Aim ~5500.

## 11. Return manifest

Per pilot pattern. Confirm: file path, word count, per-algorithm five-block coverage, anchor (ICP) sub-budget confirmation, visual artifacts, catalog status, 8 Safeguard-1 items confirmed, four-perception-roles preservation, new factual-claim inventory (Rule 3b two-tier).
