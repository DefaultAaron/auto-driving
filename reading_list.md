---
title: Reading List
tags:
  - book/reading-list
---

# Reading List

> [!info] How this list works
> One global, chapter-organised reading list. Each entry follows the schema in [[_templates/_reading_list_entry|_reading_list_entry template]]. Tag every entry with `#book/reading-list`, `#book/chapter-N`, and (where relevant) a region tag `#region/cn` / `#region/us` / `#region/eu` for industry-context filtering. Do **not** invent papers — leave links blank if unverified.

> [!example] Example entry (replicate this shape)
> ### YOLOv1 — Redmon et al., 2016 (CVPR)
> - **Type**: paper
> - **Why read**: original single-stage detection idea — grid + per-cell box & class regression.
> - **Chapter**: Ch 3 (§3.5)
> - **Read status**: [ ] not started · [ ] reading · [ ] done
> - **Link**: _verify before pasting_
> - **Tags**: #book/reading-list #book/chapter-3 #region/us

---

## Chapter 0 — Book Overview
_(typically empty — meta-references only if any)_

## Chapter 1 — Foundations
_TBD: TF / TF2 docs, ROS2 Humble docs, Hartley & Zisserman (camera geometry), KITTI / nuScenes / Waymo overview papers, Murray-Li-Sastry (vehicle dynamics)._

## Chapter 2 — Localization, Mapping & Ego-State Estimation
_TBD: EKF / UKF tutorials, Barfoot "State Estimation for Robotics", factor-graph references (GTSAM), ICP (Besl & McKay), NDT (Biber), GICP (Segal), ORB-SLAM3, LIO-SAM, FAST-LIO, HD-map building literature, RTKLIB / GNSS+IMU references._

## Chapter 3 — Object Detection Fundamentals + YOLO Conceptual Lineage
_TBD: YOLOv1 (Redmon), focal loss (Lin et al.), mAP / COCO eval, IoU / GIoU / CIoU losses, augmentation surveys (Mosaic / CutMix)._

## Chapter 4 — Comprehensive Camera Perception Systems for AD
_TBD: YOLOv3 / v5 / v8 release notes, "YOLO26" source (TBC with user); DETR (Carion), Deformable DETR, DAB-DETR, DN-DETR, DINO; RT-DETR, DEIM, D-FINE; FCOS, CenterNet, RTMDet; OWL-ViT, GroundingDINO; ByteTrack, OC-SORT, BoT-SORT; Mask2Former, MapTR; FCOS3D, BEVFormer (cam-only), PETR, Sparse4D, occupancy / scene-completion papers; DINOv2, SAM, CLIP._

## Chapter 5 — Classical LiDAR Detection
_TBD: PCL (Rusu & Cousins), RANSAC (Fischler & Bolles), DBSCAN, Kalman / IMM / JPDA references, ICP / NDT / GICP, occupancy-grid mapping._

## Chapter 6 — Deep-Learning LiDAR Detection
_TBD: PointNet, PointNet++, VoxelNet, SECOND, PointPillars, CenterPoint, transformer-based 3D detectors, KITTI / nuScenes / Waymo benchmark conventions._

## Chapter 7 — Camera + LiDAR Sensor Fusion
_TBD: BEVFormer, BEVFusion, TransFusion, FUTR3D, multi-sensor calibration practices, fusion benchmark surveys._

## Chapter 8 — Classical Motion Planning, Prediction & Control
_TBD: Hybrid A* (Dolgov et al.), RRT* (Karaman & Frazzoli), lattice planners, MPC primer (Borrelli / Bemporad / Morari), pure-pursuit (Coulter), Stanley (Hoffmann et al.), IMM tracking, social-force model, real-time scheduling for ROS2._

## Chapter 9 — Deep-Learning Planning, Prediction & Control
_TBD: behavior cloning surveys, RL-for-driving surveys, Trajectron / Trajectron++, VectorNet, MTR, TNT, neural MPC papers, CARLA leaderboard reports, Apollo design papers._

## Chapter 10 — AD Data Engine, Labeling & ML Operations
_TBD: data-flywheel writeups (Tesla Autopilot blog series, Waymo / Cruise blogs); auto-labeling pipelines (FBLA / SAM-based); active-learning surveys; MLflow / Weights & Biases / DVC docs; CI-for-ML references; data-versioning patterns; AD-specific dataset papers (Argoverse, Lyft Level 5, ZOD)._

## Chapter 11 — Safety, Validation & Operational Discipline
_TBD: ISO 26262 (functional safety), ISO 21448 (SOTIF), UL 4600 (autonomous safety case), RSS (Mobileye), scenario-based testing surveys, simulation-to-real gap surveys, on-vehicle bring-up postmortems. Tag entries by region: `#region/eu` for ISO, `#region/us` for UL/RSS, `#region/cn` for MIIT autonomous-vehicle drafts._

## Chapter 12 — End-to-End Autonomous Driving
_TBD: UniAD, VAD, ThinkTwice, DriveGPT-style works, Wayve papers, Tesla Autopilot system writeups, VLA papers (RT-2 family for context), end-to-end AD surveys, end-to-end AD safety-case discussions. Region-tag entries: Wayve / Waymo / Cruise / Tesla `#region/us`, Apollo / Pony / Momenta / XPeng `#region/cn`, Mobileye / Bosch `#region/eu`._
