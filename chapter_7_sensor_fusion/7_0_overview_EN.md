---
chapter: 7
section: 0
title: Camera + LiDAR Sensor Fusion — Overview
language: EN
status: planned
tags:
  - book/section
  - book/chapter-7
  - book/overview
  - lang/EN
---

# Chapter 7 — Camera + LiDAR Sensor Fusion (Goal 1 of AD perception)

> [!info] Status & canonical state
> Frontmatter `status` is canonical. [[00_table_of_contents|TOC]] badges are a manual display copy.

> [!abstract] What this chapter covers
> Integration of camera and LiDAR perception into a single environment representation that downstream prediction and planning consume — the perception "Goal 1" of an AD stack. Calibration & sync revisited; early / mid / late fusion; the BEV paradigm (BEVFormer, BEVFusion); attention fusion (TransFusion); the boundary between fusion outputs (tracks + uncertainty) and downstream prediction (Ch 8 / Ch 9).

## Learning objectives
- Decide between early-, mid-, and late-fusion designs given a task and latency budget.
- Read and reproduce a BEV-paradigm fusion model (BEVFormer / BEVFusion).
- Explain how attention-based fusion (TransFusion) handles modality misalignment.
- Define the fusion-prediction boundary: what `tracks + uncertainty` should look like for downstream consumers.
- Diagnose fusion failure modes (calibration drift, sync slip, occlusion mishandling).
- Take a fused stack from PyTorch through ONNX / TensorRT into ROS2 on edge GPU.

## Prerequisites
- [[4_0_overview_EN|Chapter 4 — Comprehensive Camera Perception Systems]]
- [[6_0_overview_EN|Chapter 6 — DL LiDAR Detection]]
- [[2_0_overview_EN|Chapter 2 — Localization]] (fusion runs in localized world frame)
- [[1_0_overview_EN|Chapter 1 — Foundations]] (esp. §1.2 camera calib, §1.3 LiDAR calib, §1.4 sync)

## Sections
| § | Title | Status (EN) | Status (ZH) |
|---|-------|:-----------:|:-----------:|
| 7.0 | Overview (this page) | ◐ | ◐ |
| 7.1 | Calibration & sync revisited | ○ | ○ |
| 7.2 | Early / mid / late fusion designs | ○ | ○ |
| 7.3 | BEV paradigm — BEVFormer / BEVFusion | ○ | ○ |
| 7.4 | Attention fusion — TransFusion | ○ | ○ |
| 7.5 | Fusion outputs: tracks + uncertainty for downstream prediction | ○ | ○ |
| 7.6 | Eval & failure modes | ○ | ○ |
| 7.7 | Deployment | ○ | ○ |
| 7.8 | Safety & validation (template instance) | ○ | ○ |

## Further reading
- _See [[reading_list]] (Chapter 7 entries — BEVFormer / BEVFusion / TransFusion / PETR / nuScenes fusion benchmarks)._

## Cross-references
- ⬅ Previous: [[6_0_overview_EN]]
- ➡ Next: [[8_0_overview_EN]]
- 🌐 Other language: [[7_0_overview_ZH]]
- 🗂 Master TOC: [[00_table_of_contents]]
