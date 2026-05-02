---
chapter: 3
section: 0
title: Object Detection Fundamentals + YOLO Conceptual Lineage — Overview
language: EN
status: planned
tags:
  - book/section
  - book/chapter-3
  - book/overview
  - lang/EN
---

# Chapter 3 — Object Detection Fundamentals + YOLO Conceptual Lineage

> [!info] Status & canonical state
> Frontmatter `status` is canonical. [[00_table_of_contents|TOC]] badges are a manual display copy.

> [!abstract] What this chapter covers
> The mechanics of object detection at the **theory** level: boxes, labels, IoU, losses, data, metrics, failure analysis — and the *idea* of single-stage detection introduced via YOLOv1's grid intuition. Lineage is referenced briefly so the reader knows where to find depth, but the full **deployed** YOLO family — including the user's "YOLO26" project label and the mingtai traffic-light worked example — lives in [[4_0_overview_EN|Ch 4 — Comprehensive camera perception systems]].

## Learning objectives
- Describe the object-detection problem precisely (box parameterization, label formats, IoU, confidence).
- Reason about classification + localization losses, focal loss, and IoU-based losses.
- Build, augment, and debug a detection dataset.
- Evaluate detectors with mAP / PR curves and read failure patterns.
- Understand single-stage detection conceptually via YOLOv1's grid intuition; know where the family goes from there (with depth deferred to Ch 4).

## Prerequisites
- [[1_0_overview_EN|Chapter 1 — Foundations]] (esp. §1.6 evaluation methodology, §1.8 datasets)

## Sections
| § | Title | Status (EN) | Status (ZH) |
|---|-------|:-----------:|:-----------:|
| 3.0 | Overview (this page) | ◐ | ◐ |
| 3.1 | Problem framing — boxes, labels, IoU, confidence | ○ | ○ |
| 3.2 | Loss intuition for detection | ○ | ○ |
| 3.3 | Data — datasets, augmentation, label noise | ○ | ○ |
| 3.4 | Metrics & failure analysis | ○ | ○ |
| 3.5 | Single-stage detection — YOLOv1 grid intuition; brief lineage pointer (depth in [[4_0_overview_EN\|Ch 4]]) | ○ | ○ |

> [!note] What's NOT in this chapter
> The YOLO family as deployed systems (v3 / v5 / v8 / "YOLO26"), DETR-family detectors, anchor-free designs, open-vocabulary, MOT, dense perception, monocular 3D, foundation-model features, AD-specific targets, deployment patterns, and per-chapter safety section all live in [[4_0_overview_EN|Chapter 4]]. This chapter is theory-only.

## Further reading
- _See [[reading_list]] (Chapter 3 entries — YOLOv1 paper, focal loss, mAP / COCO eval, augmentation methods)._

## Cross-references
- ⬅ Previous: [[2_0_overview_EN]]
- ➡ Next: [[4_0_overview_EN]]
- 🌐 Other language: [[3_0_概览_ZH]]
- 🗂 Master TOC: [[00_table_of_contents]]
