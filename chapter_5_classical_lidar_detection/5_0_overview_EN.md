---
chapter: 5
section: 0
title: Classical LiDAR Detection — Overview
language: EN
status: complete
tags:
  - book/section
  - book/chapter-5
  - book/overview
  - lang/EN
---

# Chapter 5 — Classical LiDAR Detection

> [!info] Status & canonical state
> Frontmatter `status` is canonical. [[00_table_of_contents|TOC]] badges are a manual display copy.

> [!abstract] What this chapter covers
> The classical (non-DL) LiDAR detection toolbox AD teams have shipped for years and still ship today: point-cloud preprocessing (with the unifying *Representation map*), ground / non-ground segmentation, clustering, **object-shape fitting (L-shape, OBB, class priors)**, multi-object tracking, registration (which the localization chapter forward-pointed to, here with its four perception roles), **occupancy / free-space reasoning with HD-map ROI gating**, ROS2 integration, and the deployment & runtime constraints under which all of this has to actually run. The classical pipeline is `preprocess → ground → cluster → fit → track`, surrounded by registration, occupancy / ROI gating, and ROS2 wiring. This is the baseline that [[6_0_overview_EN|Chapter 6 — DL LiDAR Detection]] will displace or hybridize for primary 3D bounding-box prediction; preprocessing, tracking, occupancy, and map-aided ROI gating remain load-bearing classical even inside DL-primary production stacks.

## Learning objectives
- Preprocess raw point clouds (downsample / voxel filter / outlier removal / motion compensation) and pick an appropriate representation (raw / voxel / range image / BEV) per task.
- Apply RANSAC-style ground segmentation and reason about its failure modes; understand the modern classical baseline (Patchwork / Patchwork++).
- Cluster non-ground points (Euclidean / DBSCAN / range-image connected components) into object proposals.
- Fit object shapes — L-shape (Zhang 2017), oriented bounding boxes, class-prior box dimensions — to convert clusters into planner-consumable boxes.
- Track multi-object outputs with Kalman / IMM / JPDA / AB3DMOT.
- Register sequential or multi-LiDAR scans with ICP / NDT / GICP — the algorithmic depth behind [[2_0_overview_EN|Ch 2 §2.3]] LiDAR localization, plus the four perception roles registration plays inside Ch 5 (deskew refinement / map subtraction / accumulation alignment / map-aided ROI consistency).
- Build occupancy grids, estimate drivable free-space, and apply HD-map ROI gating priors (Apollo HDMap LUT, Autoware `compare_map_segmentation`).
- Wire the full pipeline into ROS2 nodes and topics.
- Reason about deployment constraints (CPU/GPU budget, latency, ROS2 timing, field robustness).

## Prerequisites
- [[1_0_overview_EN|Chapter 1 — Foundations]] (esp. §1.3 LiDAR basics, §1.4 sensor sync, §1.5 ROS2 essentials)
- [[2_0_overview_EN|Chapter 2 — Localization]] (provides ego-pose context this chapter's outputs feed into)

## Sections
| § | Title | Status (EN) | Status (ZH) |
|---|-------|:-----------:|:-----------:|
| 5.0 | Overview (this page) | ● | ◐ |
| 5.1 | Point-cloud preprocessing (incl. *Representation map* primer) | ● | ○ |
| 5.2 | Ground segmentation (RANSAC etc.) | ● | ○ |
| 5.3 | Clustering — Euclidean, DBSCAN | ◐ (extending) | ○ |
| 5.4 | Object-shape fitting — L-shape, OBB, class priors | ● | ○ |
| 5.5 | Multi-object tracking — Kalman / IMM / JPDA | ● | ○ |
| 5.6 | Registration — ICP / NDT / GICP (depth behind [[2_0_overview_EN\|Ch 2]] localization, plus four perception roles) | ● | ○ |
| 5.7 | Occupancy, free-space & map-aided ROI gating | ● | ○ |
| 5.8 | ROS2 integration | ● | ○ |
| 5.9 | Deployment & runtime constraints — CPU/GPU budget, latency, timing, field robustness | ● | ○ |
| 5.10 | Safety & validation (template instance) | ● | ○ |

## Further reading
- _See [[reading_list]] (Chapter 5 entries — PCL, classical LiDAR papers, RANSAC, ICP / NDT, occupancy mapping)._

## Cross-references
- ⬅ Previous: [[4_0_overview_EN]]
- ➡ Next: [[6_0_overview_EN]]
- 🌐 Other language: [[5_0_概览_ZH]]
- 🗂 Master TOC: [[00_table_of_contents]]
