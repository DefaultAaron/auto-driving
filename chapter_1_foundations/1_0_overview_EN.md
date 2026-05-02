---
chapter: 1
section: 0
title: Foundations — Overview
language: EN
status: planned
tags:
  - book/section
  - book/chapter-1
  - book/overview
  - lang/EN
---

# Chapter 1 — Foundations

> [!info] Status & canonical state
> Frontmatter `status` is canonical. [[00_table_of_contents|TOC]] badges are a manual display copy.

> [!abstract] What this chapter covers
> The shared prerequisites every later chapter assumes: coordinate frames, calibration, sensor sync, ROS2 essentials, evaluation methodology, datasets / data versioning, vehicle dynamics, the deployment target the book teaches against, and a first pass at safety concepts (ODD, hazard analysis) that Chapter 10 develops fully.

## Learning objectives
- Read and reason about coordinate frames, transforms, and TF2.
- Calibrate cameras and LiDAR and reason about the resulting projection.
- Understand sensor time sync, ROS2 message flow, and rosbag logging.
- Use principled evaluation methodology and dataset hygiene for AD problems.
- Understand the book's pinned deployment target (PyTorch → ONNX/TensorRT → C++ ROS2 nodes → edge GPU on vehicle).
- Grasp ODD and basic hazard analysis well enough to read every following chapter's safety section.

## Prerequisites
- [[0_0_overview_EN|Chapter 0 — Book Overview]]
- Comfort with Python and Linux; undergraduate linear algebra and probability.

## Sections
| § | Title | Status (EN) | Status (ZH) |
|---|-------|:-----------:|:-----------:|
| 1.0 | Overview (this page) | ◐ | ◐ |
| 1.1 | Coordinate frames & TF2 | ○ | ○ |
| 1.2 | Camera intrinsics / extrinsics calibration | ○ | ○ |
| 1.3 | LiDAR calibration & point-cloud basics | ○ | ○ |
| 1.4 | Sensor time sync | ○ | ○ |
| 1.5 | ROS2 / Humble essentials | ○ | ○ |
| 1.6 | Evaluation methodology | ○ | ○ |
| 1.7 | Vehicle dynamics & control primer | ○ | ○ |
| 1.8 | Datasets & data versioning basics | ○ | ○ |
| 1.9 | Deployment target & constraints | ○ | ○ |
| 1.10 | Operational design domain (ODD) primer | ○ | ○ |
| 1.11 | Hazard analysis intro | ○ | ○ |

## Further reading
- _See [[reading_list]] (Chapter 1 entries)._

## Cross-references
- ⬅ Previous: [[0_0_overview_EN]]
- ➡ Next: [[2_0_overview_EN]]
- 🌐 Other language: [[1_0_overview_ZH]]
- 🗂 Master TOC: [[00_table_of_contents]]
