---
title: §5.9 deployment & runtime — extension brief
doc_type: section-extension-brief
chapter: 5
section: 9
phase: 4-extension
writer: codex-writer
status: draft
created: 2026-05-03
related:
  - "[[ch5_chapter_plan]]"
  - "[[ch5_extension_plan]]"
tags: [workflow, chapter-5, extension, brief, codex-writer]
---

# §5.9 deployment & runtime — extension brief

Sequential after §5.8 AGREED `ab23098`. **§5.9 is a synthesis section** (per chapter plan Item 1: "Per-stage CPU/GPU/latency budgets... bounded 'Nobody ships pure classical primary detection...' claim... load-bearing classical pieces in DL-primary stacks"). Originally cc-drafted (contested framing). Round-W: all-codex with **FULL Safeguard-1**.

> [!info] Section assignment
> - **Section path:** `chapter_5_classical_lidar_detection/5_9_deployment_runtime_EN.md`
> - **Writer:** **codex-writer**. FULL Safeguard-1 (synthesis section with contested framing).
> - **Length:** **3500–4500 words** (target ~4000, trim 4300, ceiling 4500; current 2721 → ~1.47× expansion). Modest expansion; synthesis content, not algorithm-heavy.
> - **Anchor (NOT five-block algorithm):** the **bounded "Nobody ships pure classical primary detection..." claim** with three explicit definitions (Production stacks / Primary detection / High-speed open-road AD), two-tier evidence (universal vs strong-evidence), four-bullet "where pure-classical still ships" list, and five-item load-bearing-classical-in-DL-stacks list. This is the section's reason to exist; depth comes from explicit framing + worked-budget table interpretation, not algorithm mechanics.
> - **Workflow gate:** Path B → AGREED → §5.10 terminal integration.

## 0. Round-1 codex critiques requiring revision (e1-c1..e1-c6)

The current §5.9 has six factual / framing weaknesses surfaced by round-1 codex critique. The writer extension must apply these corrections.

**e1-c1 — "Universally DL-based" + Cruise overclaim.** Current §5.9 says: "Waymo, Cruise, Pony, Apollo Go, MOIA-class — primary 3-D bounding-box prediction is **universally DL-based** based on disclosed stack architectures and tech-report evidence." Codex flagged: "universally DL-based" is too strong without per-stack citations; Cruise is problematic post-operational-pause/restructuring. **Fix:** narrow named-program list (drop Cruise; or add date-bounded "as of 2024–2026" qualifier with citation note); soften "universally" to "the publicly disclosed stack architectures consistently use DL-based primary 3D detection (e.g., Waymo Open Dataset stack disclosures, Apollo public source, Pony.ai tech reports as of 2024–2026)"; explain operationally what "primary" means.

**e1-c2 — 40–60% Patchwork claim unsourced.** Current §5.9 (Load-bearing classical paragraph): "Running Patchwork or a Himmelsbach-style radial segmenter before the learned detector reduces the input cloud by 40–60 %." **Fix:** either add scope conditions (sensor / ODD / voxel size / before-or-after voxelization) and source, or replace with qualitative "ground filtering can materially reduce downstream input size."

**e1-c3 — Consumer-NOA evidence boundary too vague.** Current §5.9: "For consumer NOA with LiDAR (XPeng, Nio, Li-Auto class), public evidence and industry practice **strongly indicate** the same..." **Fix:** name the evidence categories (teardown / patents / supplier disclosures / job postings / conference talks / observed behavior), cite representative examples, or lower the claim to an inference rather than "strong evidence."

**e1-c4 — Hesai AT128 / Didi-GAC claim fragile.** Current §5.9: "Hesai's AT128 now powers Didi/GAC L4 robotaxi pilots." **Fix:** remove the specific pairing and keep the regional-priors point, OR cite/date-bound the exact supplier/program relationship.

**e1-c5 — Eight-vs-nine rows arithmetic.** Current §5.9 says "The eight committed runtime-budget rows reconciled into one chapter-level table" but the displayed table has nine rows (§5.6 split into Role 1 ICP + Role 2 GICP; §5.8 included). **Fix:** clarify "eight source sections, nine displayed rows due to the §5.6 split (Role 1 and Role 2 carry different cadences and budgets)," or merge and explain the split before the table.

**e1-c6 — Hybrid learned-classical interfaces missing.** Bounded claim frames deployment as binary "classical vs DL primary detection" but production stacks blur it: learned segmentation → classical clustering/tracking, rule-based post-processing around neural detections, learned occupancy instead of bbox primaries, map/occupancy planning paths that reduce bbox centrality. **Fix:** add a short caveat that the claim is about the **primary bbox predictor role**, not every learned/classical boundary, and explicitly acknowledge hybrid interfaces without expanding the taxonomy.

These fixes apply to the existing prose AND to any newly-extended Worked Examples / cross-section inheritance. The 4-bullet ships list, 5-item load-bearing list, and per-stage runtime table structures are still preserved verbatim per Safeguard 1; only the named-program / numeric / evidence-category claims need narrowing.

## 1. Coverage gap analysis

§5.9 is synthesis; the five-block-per-algorithm pattern doesn't apply. Each topic has tighter coverage: claim + evidence + interpretation.

Current §5.9 has 7 topic sections + 3 catalog rows + runtime budget row aggregating §§5.1–5.8.

- **Bounded industry claim:** ✓ (three definitions + two-tier evidence + ships list — solid; minor extension for sourcing/scope clarity).
- **Load-bearing classical pieces:** ✓ (5-item list good; minor extension to deepen each per inheritance from §§5.1–5.8 extensions).
- **China-vs-US deployment priors:** ✓ (one-paragraph hard limit honored).
- **Per-stage runtime budget table:** ✓ (the eight rows + reconciliation paragraphs — solid; Worked Example for tail-correlated stall + memory total + frame-rate consistency present).
- **ROS2 timing reconciliation:** ◐ (composable nodes + TF freshness mention; can extend with cross-section §5.8 specific patterns).
- **Field robustness:** ◐ (rain/fog/sensor degradation paragraph — keep as one paragraph per chapter plan; minor refinement).
- **Failure-mode catalog entries (chapter-wide):** ✓ (3 rows — `5_9.fm.frame_budget_overrun_p99`, `5_cross.fm.subrate_registration_starves_under_load`, `5_cross.fm.sensor_class_mismatch_at_deploy`).

Extension primarily fills:
- Strengthen the Per-stage runtime budget interpretation (add cross-section pattern observations: e.g., the §5.6 Role 1 ICP cadence vs Role 2 GICP cadence reasoning).
- Add Worked Example for the bounded-claim three-definition logic (e.g., walk a hypothetical "is this stack 'production stacks running primary detection'" decision tree).
- Add a Worked Example for the per-stage budget reconciliation (correlated tail stall scenario).
- Strengthen ROS2 timing reconciliation with the §5.8 cadence/QoS table inheritance.

## 2. Length budget

- **Bounded industry claim (anchor):** ~700–900 (preserved 3-definition + 2-tier evidence + 4-bullet list + Worked Example: hypothetical-stack decision walk-through).
- **Load-bearing classical pieces:** ~600–800 (5 items × ~100-150 each + cross-§§5.1–5.8 inheritance specifics from the now-extended sections).
- **China-vs-US one paragraph:** ~150–200 (hard limit per chapter plan).
- **Per-stage runtime budget + reconciliation:** ~1000–1300 (table preserved + tail-correlated-stall Worked Example + memory total + sensor-class-divergence + frame-rate consistency interpretation).
- **ROS2 timing reconciliation:** ~300–400 (extended with §5.8 cadence/QoS inheritance).
- **Field robustness:** ~150–200 (one paragraph hard limit).
- **Failure-mode catalog (frozen, 3 rows):** ~400.
- **Section framing prose** (opener + closer): ~300–400.
- **One synthesis artifact:** every-frame-chain budget aggregation table (different from §5.8's per-stage cadence/QoS table — focused on p50/p99 budget arithmetic).

**Target ~4000; trim 4300; ceiling 4500.** Cut order: trim §5.8 timing-reconciliation overlap (§5.8 owns wiring; §5.9 owns synthesis); compress connective prose; never trim bounded claim, load-bearing list, runtime table, catalog.

## 3. Visual artifact discipline

§5.9 is synthesis with budget tables — **wiring/runtime exemption applies**: per-stage budget table (already in §5.9) + every-frame-chain budget aggregation table satisfy the artifact rule. No additional spatial visuals required.

## 4. Catalog block

3 rows preserved verbatim. (`5_9.fm.frame_budget_overrun_p99`, `5_cross.fm.subrate_registration_starves_under_load`, `5_cross.fm.sensor_class_mismatch_at_deploy`.) **Note:** these are the only `5_9.fm.*` + 2 of the 3 `5_cross.fm.*` IDs. The third cross-section ID (`5_cross.fm.deskew_then_cluster_doubling`) is hosted in §5.3.

## 5. Forward / cross-references

- Inputs (preserve): §§5.1–5.8 runtime-budget rows aggregated in the §5.9 table; §5.6 Role 1 vs Role 2 cadence; §5.8 cadence/QoS conventions.
- Outputs (preserve): §5.10 catalog (consumes 3 §5.9 rows + the §5.6/§5.7 rows it indexes); chapter forward-point to Ch 6 inheriting the load-bearing-classical list.
- Forward to Ch 6 (preserved): the load-bearing-classical-in-DL-stacks list is the primary §5.9 → Ch 6 inheritance.

## 6. Voice rules

All chapter-plan Item 6 voice rules. Bounded claim phrasing strict per chapter plan Item 9 ("universally DL-based" for L4; "strong evidence indicates" for consumer NOA — don't flatten the distinction).

## 7. Phase-5 path

Path B with **FULL Safeguard-1** strict (contested framing).

## 8. Frontmatter `workflow_status: reviewing`.

## 9. FULL Safeguard-1 protected-framing spans for §5.9

§5.9 was originally cc-drafted because the bounded claim is the section's reason to exist. FULL Safeguard-1.

1. **Three explicit definitions** (Production stacks / Primary detection / High-speed open-road AD) — verbatim. Referenced by §5.10 + §5.7 + §5.6 + §5.4 + §5.5 narrowing rules.
2. **Two-tier evidence** ("universally DL-based" for robotaxi/L4 vs "strong evidence indicates" for consumer NOA) — verbatim. Don't flatten.
3. **Four-bullet "where pure-classical primary detection still ships" list:** Low-speed/restricted-ODD AD; AEB-style safety modules; Curb/barrier/free-space monitors; Off-highway autonomy. **Verbatim** + no role drop, no addition, no reorder.
4. **Five-item load-bearing classical pieces list:** Preprocessing; Ground segmentation as CNN front-end; Tracking; Generic Obstacle Detection / occupancy; HD-map ROI gating. **Verbatim** + no item drop, no addition, no reorder. Each item's wikilink back to host section preserved.
5. **One paragraph hard limit on China-vs-US deployment priors** — verbatim hard limit (no expansion to recurring theme).
6. **Per-stage runtime budget table** (8 rows: §5.1 through §5.8) — verbatim. Numbers come from per-section commitments.
7. **Tail-correlated stall reasoning** ("tails do not sum cleanly" framing) — verbatim. Production discipline.
8. **TF freshness ≤ 50 ms invariant** — verbatim.
9. **Cross-section terminology:** "production stacks" / "primary detection" / "high-speed open-road AD" / "robotaxi/L4" / "consumer NOA" / "load-bearing classical pieces"; 5_9.fm.* IDs.
10. **Forward-point closer** ("§5.10 picks up the failure-mode catalog... Ch 6 inherits the five-item load-bearing-classical list...") — verbatim.

The framing-preservation Path B axis is **strict**.

## 10. Process

1. Read brief + current §5.9 + pilot patterns.
2. Strengthen the bounded claim with a Worked Example (hypothetical-stack decision walk-through).
3. Extend load-bearing classical pieces with §§5.1–5.8 inheritance specifics from now-extended sections.
4. Add tail-correlated-stall Worked Example to per-stage budget interpretation.
5. ROS2 timing reconciliation extends with §5.8 cadence/QoS table inheritance.
6. Catalog block frozen.
7. Word-count yourself. Aim ~4000.

## 11. Return manifest

Per pilot pattern. Confirm: file path, word count, topic-by-topic coverage, anchor depth (bounded claim + 4-bullet ships list + 5-item load-bearing list), per-stage runtime table preserved, 10 Safeguard-1 items confirmed, catalog status, new factual-claim inventory.
