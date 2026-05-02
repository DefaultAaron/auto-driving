---
chapter: 8
section: 0
title: Classical Motion Planning, Prediction & Control — Overview
language: EN
status: planned
tags:
  - book/section
  - book/chapter-8
  - book/overview
  - lang/EN
---

# Chapter 8 — Classical Motion Planning, Prediction & Control

> [!info] Status & canonical state
> Frontmatter `status` is canonical. [[00_table_of_contents|TOC]] badges are a manual display copy.

> [!abstract] What this chapter covers
> The classical, non-DL stack that turns perception output (Ch 7 fusion) and ego-state (Ch 2 localization) into vehicle commands: behavior planning + state machines; classical prediction (CV / CTRV / IMM / social-force / rule-based); graph-search / sampling / lattice motion planners; controllers from PID through MPC; deployment & control-loop timing constraints; safety. Baseline that [[9_0_overview_EN|Chapter 9 — DL Planning, Prediction & Control]] will displace or hybridize.

## Learning objectives
- Design behavior planners and state machines for typical AD scenarios.
- Implement classical prediction (CV / CTRV / IMM / social-force) and reason about its failure modes against learned alternatives.
- Compare A*, D*-Lite, hybrid A*, RRT / RRT*, lattice and spline planners on AD-relevant problems.
- Tune PID, pure-pursuit, and Stanley controllers; understand when MPC is justified.
- Reason about real-time deployment constraints — control-loop timing, ROS2 deterministic comms, jitter budgets, failover.

## Prerequisites
- [[7_0_overview_EN|Chapter 7 — Camera + LiDAR Fusion]] (consumes its `tracks + uncertainty` output)
- [[2_0_overview_EN|Chapter 2 — Localization]] (consumes ego-state)
- [[1_0_overview_EN|Chapter 1 — Foundations]] (esp. §1.7 vehicle dynamics)

## Sections
| § | Title | Status (EN) | Status (ZH) |
|---|-------|:-----------:|:-----------:|
| 8.0 | Overview (this page) | ◐ | ◐ |
| 8.1 | Behavior planning & state machines | ○ | ○ |
| 8.2 | Classical prediction — CV / CTRV / IMM / social-force / rule-based intent | ○ | ○ |
| 8.3 | Graph search — A*, D*-Lite, hybrid A* | ○ | ○ |
| 8.4 | Sampling planners — RRT, RRT* | ○ | ○ |
| 8.5 | Lattice & spline planners | ○ | ○ |
| 8.6 | Control — PID, pure pursuit, Stanley | ○ | ○ |
| 8.7 | MPC & optimal control | ○ | ○ |
| 8.8 | Deployment & control-loop timing — real-time scheduling, ROS2 deterministic comms, jitter budgets, failover | ○ | ○ |
| 8.9 | Safety & validation (template instance) | ○ | ○ |

## Further reading
- _See [[reading_list]] (Chapter 8 entries — classical planning, IMM, MPC primer, pure-pursuit / Stanley, real-time control papers)._

## Cross-references
- ⬅ Previous: [[7_0_overview_EN]]
- ➡ Next: [[9_0_overview_EN]]
- 🌐 Other language: [[8_0_概览_ZH]]
- 🗂 Master TOC: [[00_table_of_contents]]
