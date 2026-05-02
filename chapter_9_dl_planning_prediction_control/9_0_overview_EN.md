---
chapter: 9
section: 0
title: Deep-Learning Planning, Prediction & Control — Overview
language: EN
status: planned
tags:
  - book/section
  - book/chapter-9
  - book/overview
  - lang/EN
---

# Chapter 9 — Deep-Learning Planning, Prediction & Control

> [!info] Status & canonical state
> Frontmatter `status` is canonical. [[00_table_of_contents|TOC]] badges are a manual display copy.

> [!abstract] What this chapter covers
> The DL alternative (and hybrid) to [[8_0_overview_EN|Chapter 8]]: imitation learning and behavior cloning; reinforcement learning for driving; learned trajectory prediction with multi-modal interaction reasoning; learned motion planners; neural MPC and hybrid systems; the simulators (CARLA, Apollo) where this work is most often developed and validated. Closes with eval and safety. The data discipline this chapter implicitly demands is owned by [[10_0_overview_EN|Chapter 10 — AD Data Engine, Labeling & ML Operations]].

## Learning objectives
- Set up imitation / behavior-cloning pipelines and understand their limits (covariate shift, dataset balance).
- Apply RL to driving sub-problems and reason about reward design and sim-to-real risk.
- Implement multi-modal trajectory prediction (Trajectron / VectorNet / MTR / TNT lineage).
- Compare learned motion planners with classical baselines from Ch 8.
- Use CARLA / Apollo as development and validation harnesses.

## Prerequisites
- [[8_0_overview_EN|Chapter 8 — Classical Motion Planning, Prediction & Control]] (baseline + concepts)
- Familiarity with PyTorch from earlier DL chapters.

## Sections
| § | Title | Status (EN) | Status (ZH) |
|---|-------|:-----------:|:-----------:|
| 9.0 | Overview (this page) | ◐ | ◐ |
| 9.1 | Imitation learning & behavior cloning | ○ | ○ |
| 9.2 | Reinforcement learning for driving | ○ | ○ |
| 9.3 | Learned trajectory prediction & multi-modal interaction (Trajectron / VectorNet / MTR) | ○ | ○ |
| 9.4 | Learned motion planners | ○ | ○ |
| 9.5 | Neural MPC & hybrid systems | ○ | ○ |
| 9.6 | Simulation — CARLA / Apollo | ○ | ○ |
| 9.7 | Evaluation & safety (template instance) | ○ | ○ |

## Further reading
- _See [[reading_list]] (Chapter 9 entries — IL / BC / RL for driving, prediction lineage, CARLA / Apollo papers)._

## Cross-references
- ⬅ Previous: [[8_0_overview_EN]]
- ➡ Next: [[10_0_overview_EN]]
- 🌐 Other language: [[9_0_概览_ZH]]
- 🗂 Master TOC: [[00_table_of_contents]]
