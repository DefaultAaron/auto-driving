---
chapter: 4
section: 0
title: Comprehensive Camera Perception Systems for AD — Overview
language: EN
status: planned
tags:
  - book/section
  - book/chapter-4
  - book/overview
  - lang/EN
---

# Chapter 4 — Comprehensive Camera Perception Systems for AD

> [!info] Status & canonical state
> Frontmatter `status` is canonical. [[00_table_of_contents|TOC]] badges are a manual display copy.

> [!abstract] What this chapter covers
> Modern, AD-relevant camera perception as deployed systems: the full YOLO family (v3 / v5 / v8 + the user's "YOLO26"), the DETR lineage and its real-time variants (RT-DETR, DEIM, D-FINE), anchor-free detectors (FCOS / CenterNet / RTMDet), open-vocabulary / grounded detection, multi-object tracking, **dense camera perception** (segmentation + online HD-map estimation incl. MapTR), **monocular & multi-camera 3D perception** (FCOS3D, camera-only BEV, occupancy / scene completion), **foundation-model features for perception** (DINOv2, SAM, CLIP), AD-specific perception targets (with the mingtai traffic-light walked-through end-to-end), deployment patterns common across model families, plus the safety template instance.

## Learning objectives
- Trace the YOLO family as deployed systems and the DETR lineage; explain why real-time DETRs exist.
- Choose between anchor-based, anchor-free, query-based, and open-vocabulary designs for a given AD problem.
- Apply MOT (ByteTrack / OC-SORT / BoT-SORT) to detector outputs.
- Reason about dense camera perception (segmentation + online vector maps) as a peer to bounding-box detection.
- Reason about monocular & multi-camera 3D perception (FCOS3D, camera-only BEV, occupancy / scene completion) — when camera-only 3D is enough vs when fusion is needed.
- Use foundation-model features (DINOv2 / SAM / CLIP) as encoders, label amplifiers, or open-vocabulary backbones.
- Walk a real YOLO model end-to-end on the mingtai traffic-light task: PyTorch training → ONNX → TensorRT → C++ ROS2 node.

## Prerequisites
- [[3_0_overview_EN|Chapter 3 — Object detection fundamentals + YOLO conceptual lineage]] (theory)
- [[2_0_overview_EN|Chapter 2 — Localization]] (multi-camera surround vision references ego-pose & frames)

## Sections
| § | Title | Status (EN) | Status (ZH) |
|---|-------|:-----------:|:-----------:|
| 4.0 | Overview (this page) | ◐ | ◐ |
| 4.1 | YOLO family as deployed systems (v3 / v5 / v8 + user's "YOLO26") | ○ | ○ |
| 4.2 | DETR family lineage (DETR → Deformable → DAB → DN → DINO) | ○ | ○ |
| 4.3 | Real-time DETRs — RT-DETR, DEIM, D-FINE | ○ | ○ |
| 4.4 | Other modern detectors — FCOS, CenterNet, RTMDet | ○ | ○ |
| 4.5 | Open-vocabulary & grounded detection — OWL-ViT, GroundingDINO | ○ | ○ |
| 4.6 | Multi-object tracking — ByteTrack, OC-SORT, BoT-SORT | ○ | ○ |
| 4.7 | Dense camera perception — semantic / instance / panoptic segmentation (Mask2Former), online HD-map estimation (MapTR) | ○ | ○ |
| 4.8 | Monocular & multi-camera 3D perception — FCOS3D, depth, camera-only BEV (PETR / BEVFormer cam-only), occupancy & semantic scene completion | ○ | ○ |
| 4.9 | Foundation-model features for AD perception — DINOv2, SAM, CLIP-style encoders, pseudo-label amplification | ○ | ○ |
| 4.10 | Specialized AD targets — vehicles / pedestrians / cyclists / signs / barriers; **traffic-light worked example** end-to-end on mingtai | ○ | ○ |
| 4.11 | Deployment & latency budgets for camera stacks | ○ | ○ |
| 4.12 | Safety & validation (template instance) | ○ | ○ |

## Further reading
- _See [[reading_list]] (Chapter 4 entries — YOLO releases, DETR / Deformable / DINO / RT-DETR / DEIM / D-FINE / FCOS / CenterNet / GroundingDINO / ByteTrack / Mask2Former / MapTR / FCOS3D / BEVFormer / PETR / DINOv2 / SAM)._

## Cross-references
- ⬅ Previous: [[3_0_overview_EN]]
- ➡ Next: [[5_0_overview_EN]]
- 🌐 Other language: [[4_0_overview_ZH]]
- 🗂 Master TOC: [[00_table_of_contents]]
