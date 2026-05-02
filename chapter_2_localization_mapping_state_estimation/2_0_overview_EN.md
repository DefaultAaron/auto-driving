---
chapter: 2
section: 0
title: Localization, Mapping & Ego-State Estimation — Overview
language: EN
status: planned
tags:
  - book/section
  - book/chapter-2
  - book/overview
  - lang/EN
---

# Chapter 2 — Localization, Mapping & Ego-State Estimation

> [!info] Status & canonical state
> Frontmatter `status` is canonical. [[00_table_of_contents|TOC]] badges are a manual display copy.

> [!abstract] What this chapter covers
> The substrate every later chapter depends on: how the vehicle knows where it is, how it tracks its own state through time, and how it relates that state to a map. Ego-state estimation, GNSS/INS/IMU fusion, LiDAR-/camera-based localization, HD-map alignment, SLAM essentials, uncertainty / drift / relocalization. Methods are introduced at survey level here; deeper algorithm coverage lives with the matching sensor chapters (LiDAR registration in [[5_0_overview_EN|Ch 5]], camera detectors in [[4_0_overview_EN|Ch 4]]) — this chapter owns the *concepts*.

## Learning objectives
- Explain ego-state, world / vehicle / sensor frames, and time alignment as the substrate for everything later.
- Fuse GNSS, INS, IMU, and odometry into a stable ego-state via EKF / UKF / factor-graph approaches.
- Reason about LiDAR-based and camera-based localization at survey level — when each is appropriate.
- Align an ego-pose to an HD-map and reason about freshness, drift, and change detection.
- Read modern SLAM literature (LIO-SAM, FAST-LIO, ORB-SLAM3 lineage) and choose between online vs offline mapping.
- Diagnose common failure modes: GNSS-denied operation, urban canyon, sensor degradation, calibration drift.

## Prerequisites
- [[1_0_overview_EN|Chapter 1 — Foundations]] (esp. §1.1 frames & TF2, §1.4 sensor sync)

## Sections
| § | Title | Status (EN) | Status (ZH) |
|---|-------|:-----------:|:-----------:|
| 2.0 | Overview (this page) | ◐ | ◐ |
| 2.1 | Ego-state estimation — odometry / IMU / GNSS basics, time-sync hygiene | ○ | ○ |
| 2.2 | GNSS / INS / IMU fusion — EKF / UKF / factor graphs | ○ | ○ |
| 2.3 | LiDAR-based localization — scan-to-map, NDT / ICP localization, point-cloud map matching | ○ | ○ |
| 2.4 | Camera-based localization — visual odometry, place recognition, image retrieval | ○ | ○ |
| 2.5 | Map-relative localization — HD-map alignment, semantic landmark matching | ○ | ○ |
| 2.6 | SLAM essentials — LIO / VIO families (LIO-SAM, FAST-LIO, ORB-SLAM3); offline vs online | ○ | ○ |
| 2.7 | HD-map building (offline) and online local mapping; map freshness & change detection | ○ | ○ |
| 2.8 | Uncertainty, drift & relocalization — covariance, divergence detection, calibration drift | ○ | ○ |
| 2.9 | Deployment & failure modes — GNSS-denied operation, tunnel / urban canyon, sensor degradation | ○ | ○ |
| 2.10 | Safety & validation (template instance) | ○ | ○ |

## Forward-pointers
- §2.3 introduces ICP / NDT briefly — full algorithmic depth in [[5_0_overview_EN|Ch 5 §5.5]].
- §2.4 introduces visual odometry / place recognition briefly — feature extraction & detection backbones in [[4_0_overview_EN|Ch 4]].
- §2.7 cross-references online vector-map estimation in [[4_0_overview_EN|Ch 4]] (MapTR-style).

## Further reading
- _See [[reading_list]] (Chapter 2 entries — EKF / UKF / factor graphs, ICP / NDT / GICP, ORB-SLAM3, LIO-SAM, FAST-LIO, HD-map literature)._

## Cross-references
- ⬅ Previous: [[1_0_overview_EN]]
- ➡ Next: [[3_0_overview_EN]]
- 🌐 Other language: [[2_0_overview_ZH]]
- 🗂 Master TOC: [[00_table_of_contents]]
