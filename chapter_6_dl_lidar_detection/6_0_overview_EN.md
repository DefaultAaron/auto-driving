---
chapter: 6
section: 0
title: Deep-Learning LiDAR Detection — Overview
language: EN
status: planned
tags:
  - book/section
  - book/chapter-6
  - book/overview
  - lang/EN
---

# Chapter 6 — Deep-Learning LiDAR Detection

> [!info] Status & canonical state
> Frontmatter `status` is canonical. [[00_table_of_contents|TOC]] badges are a manual display copy.

> [!abstract] What this chapter covers
> Deep-learning approaches for LiDAR object detection — the modern alternative to (and, often, hybrid extension of) [[5_0_overview_EN|Chapter 5 — Classical LiDAR Detection]]. PointNet / PointNet++, voxel-based families (VoxelNet / SECOND), pillar representations (PointPillars), anchor-free heads (CenterPoint), and recent transformer-based 3D detectors. Closes with 3D-detection metrics, deployment, and safety.

## Learning objectives
- Compare point-, voxel-, and pillar-based representations of point clouds.
- Train and evaluate PointPillars / SECOND / CenterPoint variants on standard datasets.
- Understand the role of transformer-based 3D detectors.
- Reason about 3D-detection metrics (KITTI, nuScenes NDS, Waymo APH) and their pitfalls.
- Take a trained model from PyTorch through ONNX / TensorRT to a real-time C++ ROS2 node on edge GPU.

## Prerequisites
- [[5_0_overview_EN|Chapter 5 — Classical LiDAR Detection]] (concepts and baseline)
- [[1_0_overview_EN|Chapter 1 — Foundations]] (esp. §1.3 LiDAR basics, §1.6 evaluation, §1.9 deployment target)

## Sections
| § | Title | Status (EN) | Status (ZH) |
|---|-------|:-----------:|:-----------:|
| 6.0 | Overview (this page) | ◐ | ◐ |
| 6.1 | PointNet / PointNet++ | ○ | ○ |
| 6.2 | VoxelNet / SECOND | ○ | ○ |
| 6.3 | PointPillars | ○ | ○ |
| 6.4 | CenterPoint & anchor-free 3D detection | ○ | ○ |
| 6.5 | Transformer-based 3D detectors | ○ | ○ |
| 6.6 | Eval metrics for 3D detection | ○ | ○ |
| 6.7 | Deployment | ○ | ○ |
| 6.8 | Safety & validation (template instance) | ○ | ○ |

## Further reading
- _See [[reading_list]] (Chapter 6 entries — PointNet / PointPillars / CenterPoint / transformer-3D, KITTI / nuScenes / Waymo)._

## Cross-references
- ⬅ Previous: [[5_0_overview_EN]]
- ➡ Next: [[7_0_overview_EN]]
- 🌐 Other language: [[6_0_overview_ZH]]
- 🗂 Master TOC: [[00_table_of_contents]]
