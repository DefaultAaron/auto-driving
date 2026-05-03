---
title: §5.8 ROS2 integration — extension brief
doc_type: section-extension-brief
chapter: 5
section: 8
phase: 4-extension
writer: codex-writer
status: draft
created: 2026-05-03
related:
  - "[[ch5_chapter_plan]]"
  - "[[ch5_extension_plan]]"
tags: [workflow, chapter-5, extension, brief, codex-writer]
---

# §5.8 ROS2 integration — extension brief

Sequential after §5.7 AGREED `f2ec9ad`. §5.8 is a **wiring / runtime section** — per the extension plan §3 visual rule, this section may use composable-node container diagrams or per-stage budget tables in lieu of spatial visuals. Originally codex-drafted; lightweight protected-framing.

> [!info] Section assignment
> - **Section path:** `chapter_5_classical_lidar_detection/5_8_ros2_integration_EN.md`
> - **Writer:** **codex-writer**. Lightweight protected-framing.
> - **Length:** **3500–4500 words** (target ~4000, trim 4300, ceiling 4500; current 2287 → ~1.75× expansion). Smaller target than algorithm sections because the content is wiring, not algorithms — depth comes from production patterns and timing diagnostics, not five-block per algorithm.
> - **Anchor topic (NOT five-block algorithm):** **PointCloud2 + TF2 frame discipline.** The most pedagogically load-bearing pattern: timestamps, per-point time, frame_id chain, ego-pose lookup discipline. Lifecycle / composable / rosbag get mechanics-for-reading depth.
> - **Workflow gate:** Path B → AGREED → §5.9.

## 1. Coverage gap analysis

§5.8 is wiring not algorithms; the five-block-per-algorithm pattern doesn't apply. Instead, each topic gets a tighter pattern: Concept (what the convention is) / Mechanics (how a node uses it correctly) / Failure Mode (what goes wrong; cross-pointer to catalog).

Current §5.8 has 6 topic sections (PointCloud2 conventions, TF2 conventions, Lifecycle, Composable nodes, rosbag replay, Reference stacks) + Runtime budget row.

Gaps:
- **PointCloud2 conventions:** ◐ (header, fields, schema mentioned; per-point `time` field semantic deserves explicit example; QoS profile choice missing — round-1 codex e1-c4 enumerated the cases that must be named: `SensorDataQoS` for live clouds, transient-local for `/tf_static`, reliable-vs-best-effort tradeoffs for recorded data, history depth effects, rosbag QoS override files).
- **TF2 conventions:** ◐ (frame chain mentioned; lookup discipline needs more depth — `canTransform` vs `lookupTransform`; static vs dynamic; extrapolation policy). **Round-1 codex e1-c2:** must distinguish two distinct TF2 use cases: (a) "transform a whole cloud as a rigid frame at the reference time" and (b) "deskew by interpolating ego motion over per-point times across the scan interval." TF2 mechanics differ — (a) is a single lookup at `header.stamp`; (b) needs availability across the scan interval, with extrapolation policy if the buffer doesn't cover the full sweep.
- **Lifecycle / managed nodes:** ✓ (concept good, mechanics light).
- **Executors / callback groups / backpressure (round-1 codex e1-c1):** new sub-topic. Currently delegated to §1.5, but executor choice / callback-group / subscription queue depth / backpressure are runtime-correctness issues that affect §5.8 directly. Add to the cadence/QoS table.
- **Composable / component nodes:** ◐ (intra-process zero-copy `std::shared_ptr` mentioned). **Round-1 codex e1-c3:** the zero-copy claim is too categorical — soften to "avoids serialization and can avoid copies under right ownership/QoS/mutation conditions." Add: container vs node-process tradeoff.
- **rosbag replay:** ◐ (`use_sim_time` mentioned; record/replay QoS gotchas missing — name explicitly: rosbag QoS override files; reliable-vs-best-effort recorded data; history depth effects on lossy replay).
- **Reference stacks (round-1 codex e1-c5):** ✓ but name-dropping. Add a small comparison table: stack / relevant package / convention to copy / convention not to copy.

## 2. Length budget

- **PointCloud2 + TF2 (anchor topic, combined):** ~1300–1700 (most-load-bearing wiring; concrete lookup-discipline + per-point-time worked example + QoS choice).
- **Lifecycle:** ~400–600.
- **Composable nodes / zero-copy:** ~500–700 (concrete intra-process pattern + container-vs-process tradeoff).
- **rosbag replay validity:** ~500–700 (full QoS/clock walk-through + record/replay gotcha worked example).
- **Reference stacks:** ~300–400.
- **Section framing prose:** ~300–400.
- **Failure-mode catalog block (frozen):** ~500.
- **Runtime budget row:** preserved.
- **Two structural artifacts (tables, NOT spatial visuals):** composable-node container diagram + per-stage cadence/QoS table ~200–300.

**Target ~4000; trim 4300; hard ceiling 4500.** Cut order: trim reference-stacks list breadth → connective prose → composable-node tradeoff depth.

## 3. Visual artifact discipline

Wiring/runtime exemption: tables OK in lieu of spatial visuals. Two structural artifacts:
- **Composable-node container diagram** (ASCII tree showing perception_container with deskew + ground + cluster + fit + track + occupancy nodes inside one process; sub-rate registration as separate component).
- **Per-stage cadence / QoS table** (each Ch-5 node, expected QoS profile, expected rate, TF freshness budget).

## 4. Catalog block

4 rows preserved verbatim.

## 5. Forward / cross-references

- Inputs (preserve): §1.5 ROS2 essentials; §1.4 sensor time sync; §1.1 frames.
- Outputs (preserve): §5.9 deployment & runtime (the runtime budget table aggregates per-stage rows); §5.10 catalog.

## 6. Voice rules

All chapter-plan Item 6 voice rules. C++ code policy applies — show concrete C++ patterns where shippable. ROS2 / Humble / `sensor_msgs/PointCloud2` / `tf2_ros` terminology preserved.

## 7. Phase-5 path

Path B; lightweight framing-preservation.

## 8. Frontmatter `workflow_status: reviewing`.

## 9. Lightweight protected-framing spans for §5.8

§5.8 is the integration glue between sections — most spans are reference-table-shaped already. **Round-1 codex e1-c6** flagged that the protection list emphasized names/slogans over fragile technical commitments; expanded below.

1. **Section opener** (line 15) — verbatim. The "ROS2 / Humble" framing + "narrowly the LiDAR-perception integration patterns that keep the pipeline correct" thesis.
2. **PointCloud2 schema fields** (`x, y, z, intensity, ring, time`) — verbatim list. **Plus per-point `time` semantics** (round-1 codex e1-c6): the **end-of-scan `header.stamp` convention** + the **per-point `time` sign convention** (e.g., `time` is non-negative offset from `header.stamp - sweep_duration`, or whatever convention §5.1 uses). These are referenced by §5.1 deskew and §5.3 catalog rows; semantics must be unambiguous.
3. **TF2 chain `lidar → base_link → odom/map`** — verbatim notation. Used in §§5.1, 5.5, 5.6. **Plus TF freshness / extrapolation policy** (round-1 codex e1-c6): explicit policy on what happens when the buffer doesn't cover requested time (fail fast for hot path; fallback for diagnostics; reject vs clamp).
4. **`use_sim_time: true` discipline** for rosbag replay — verbatim.
5. **Output contract** (round-1 codex e1-c6 expansion): exact output frames + timestamp semantics + per-point `time` convention. The §5.8 publishing contract is the binding interface for §5.1 / §5.3 / §5.5.
6. **Strict-rejection-of-unsupported-PointCloud2-layouts policy** (round-1 codex e1-c6) — at startup, validate `is_bigendian`, `point_step`, field offsets, datatype; reject unsupported layouts explicitly rather than producing curved-walls / NaN-cluster artifacts. Catalog row `5_8.fm.pointcloud2_offset_drift` references this discipline.
7. **Reference-stack names** (Autoware Universe, Autoware Core, Apollo perception, MOLA) — preserve verbatim.
8. **Cross-section terminology:** ROS2 / Humble; `PointCloud2`; `tf2_ros`; lifecycle / managed nodes; composable / component nodes; intra-process; `sensor_msgs`; 5_8.fm.* IDs.

## 10. Process

1. Read brief + current §5.8 + pilot patterns.
2. Build out PointCloud2 + TF2 anchor topic with full mechanics + worked example.
3. Lifecycle, composable nodes, rosbag — mechanics-for-reading depth.
4. Add composable-node container diagram + cadence/QoS table.
5. Reference stacks preserved + minor.
6. Word-count yourself. Aim ~4000.

## 11. Return manifest

- File path written.
- New `wc -w`.
- Topic-by-topic coverage confirmation.
- Anchor (PointCloud2 + TF2) full mechanics + worked example.
- Two structural artifacts (composable-node diagram + cadence/QoS table) present.
- 7 protected-framing items confirmed.
- Catalog status.
- New factual-claim inventory (Rule 3b two-tier; new product / runtime / DL claims listed).
