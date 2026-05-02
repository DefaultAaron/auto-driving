---
chapter: 5
section: 0
title: Classical LiDAR Detection — Overview
language: EN
status: planned
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
> The classical (non-DL) LiDAR detection toolbox AD teams have shipped for years and still ship today: point-cloud preprocessing, ground / non-ground segmentation, clustering, multi-object tracking, registration (which the localization chapter forward-pointed to), occupancy / free-space reasoning, ROS2 integration, and the deployment & runtime constraints under which all of this has to actually run. This is the baseline that [[6_0_overview_EN|Chapter 6 — DL LiDAR Detection]] will displace or hybridize.

## Learning objectives
- Preprocess raw point clouds (downsample / voxel filter / outlier removal) for downstream tasks.
- Apply RANSAC-style ground segmentation and reason about its failure modes.
- Cluster non-ground points (Euclidean / DBSCAN) into object proposals.
- Track multi-object outputs with Kalman / IMM / JPDA.
- Register sequential or multi-LiDAR scans with ICP / NDT / GICP — the algorithmic depth behind [[2_0_overview_EN|Ch 2 §2.3]] LiDAR localization.
- Build occupancy grids and estimate drivable free-space.
- Wire the full pipeline into ROS2 nodes and topics.
- Reason about deployment constraints (CPU/GPU budget, latency, ROS2 timing, field robustness).

## Prerequisites
- [[1_0_overview_EN|Chapter 1 — Foundations]] (esp. §1.3 LiDAR basics, §1.4 sensor sync, §1.5 ROS2 essentials)
- [[2_0_overview_EN|Chapter 2 — Localization]] (provides ego-pose context this chapter's outputs feed into)

## Sections
| § | Title | Status (EN) | Status (ZH) |
|---|-------|:-----------:|:-----------:|
| 5.0 | Overview (this page) | ◐ | ◐ |
| 5.1 | Point-cloud preprocessing | ○ | ○ |
| 5.2 | Ground segmentation (RANSAC etc.) | ○ | ○ |
| 5.3 | Clustering — Euclidean, DBSCAN | ○ | ○ |
| 5.4 | Multi-object tracking — Kalman / IMM / JPDA | ○ | ○ |
| 5.5 | Registration — ICP / NDT / GICP (depth behind [[2_0_overview_EN\|Ch 2]] localization) | ○ | ○ |
| 5.6 | Occupancy grids & free-space | ○ | ○ |
| 5.7 | ROS2 integration | ○ | ○ |
| 5.8 | Deployment & runtime constraints — CPU/GPU budget, latency, timing, field robustness | ○ | ○ |
| 5.9 | Safety & validation (template instance) | ○ | ○ |

## Further reading
- _See [[reading_list]] (Chapter 5 entries — PCL, classical LiDAR papers, RANSAC, ICP / NDT, occupancy mapping)._

## Cross-references
- ⬅ Previous: [[4_0_overview_EN]]
- ➡ Next: [[6_0_overview_EN]]
- 🌐 Other language: [[5_0_overview_ZH]]
- 🗂 Master TOC: [[00_table_of_contents]]
