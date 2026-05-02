---
title: Table of Contents
tags:
  - book/toc
---

# Table of Contents

> [!info] How this TOC works
> - **Section-level checkbox** `[ ]` is the user's progress tracker. It is **language-agnostic** — tick it only when *both* the EN and ZH versions of a section are written and reviewed.
> - **Per-language status badges** ( ○ ◐ ● ) next to each language wikilink are a **manual display copy** of each file's frontmatter `status` field — frontmatter is canonical. Re-sync the badges when a file's status changes.
> - **Legend:** ○ planned · ◐ draft · ● review/done.

> [!tip] Conventions
> - Filenames: `N_M_short_slug_LANG.md` where `N` = chapter, `M` = section (0 = chapter overview), `LANG` ∈ `{EN, ZH}`.
> - Each section page lives in `chapter_N_*/`.
> - Templates live in `_templates/`. Static assets (figures, externalised long code) in `_assets/`.
> - See [[README]] for the full plan, conventions, cross-cutting threads, and graphify usage.

---

## Chapter 0 — Book Overview

- [ ] 0.0 Overview · [[0_0_overview_EN|EN]] ◐ · [[0_0_overview_ZH|ZH]] ◐
- [ ] 0.1 How to use this book · [[0_1_how_to_use_EN|EN]] ○ · [[0_1_how_to_use_ZH|ZH]] ○
- [ ] 0.2 Roadmap & goals · [[0_2_roadmap_and_goals_EN|EN]] ○ · [[0_2_roadmap_and_goals_ZH|ZH]] ○
- [ ] 0.3 The mingtai project as a worked example · [[0_3_mingtai_as_example_EN|EN]] ○ · [[0_3_mingtai_as_example_ZH|ZH]] ○

## Chapter 1 — Foundations

- [ ] 1.0 Overview · [[1_0_overview_EN|EN]] ◐ · [[1_0_overview_ZH|ZH]] ◐
- [ ] 1.1 Coordinate frames & TF2 · [[1_1_coordinate_frames_EN|EN]] ○ · [[1_1_coordinate_frames_ZH|ZH]] ○
- [ ] 1.2 Camera intrinsics / extrinsics calibration · [[1_2_camera_calibration_EN|EN]] ○ · [[1_2_camera_calibration_ZH|ZH]] ○
- [ ] 1.3 LiDAR calibration & point-cloud basics · [[1_3_lidar_calibration_EN|EN]] ○ · [[1_3_lidar_calibration_ZH|ZH]] ○
- [ ] 1.4 Sensor time sync · [[1_4_sensor_time_sync_EN|EN]] ○ · [[1_4_sensor_time_sync_ZH|ZH]] ○
- [ ] 1.5 ROS2 / Humble essentials · [[1_5_ros2_humble_essentials_EN|EN]] ○ · [[1_5_ros2_humble_essentials_ZH|ZH]] ○
- [ ] 1.6 Evaluation methodology · [[1_6_evaluation_methodology_EN|EN]] ○ · [[1_6_evaluation_methodology_ZH|ZH]] ○
- [ ] 1.7 Vehicle dynamics & control primer · [[1_7_vehicle_dynamics_primer_EN|EN]] ○ · [[1_7_vehicle_dynamics_primer_ZH|ZH]] ○
- [ ] 1.8 Datasets & data versioning basics · [[1_8_datasets_and_versioning_EN|EN]] ○ · [[1_8_datasets_and_versioning_ZH|ZH]] ○
- [ ] 1.9 Deployment target & constraints · [[1_9_deployment_target_EN|EN]] ○ · [[1_9_deployment_target_ZH|ZH]] ○
- [ ] 1.10 Operational design domain (ODD) primer · [[1_10_odd_primer_EN|EN]] ○ · [[1_10_odd_primer_ZH|ZH]] ○
- [ ] 1.11 Hazard analysis intro · [[1_11_hazard_analysis_intro_EN|EN]] ○ · [[1_11_hazard_analysis_intro_ZH|ZH]] ○

## Chapter 2 — Localization, Mapping & Ego-State Estimation

- [ ] 2.0 Overview · [[2_0_overview_EN|EN]] ◐ · [[2_0_overview_ZH|ZH]] ◐
- [ ] 2.1 Ego-state estimation — odometry / IMU / GNSS basics, time-sync hygiene · [[2_1_ego_state_estimation_EN|EN]] ○ · [[2_1_ego_state_estimation_ZH|ZH]] ○
- [ ] 2.2 GNSS / INS / IMU fusion — EKF / UKF / factor graphs · [[2_2_gnss_ins_imu_fusion_EN|EN]] ○ · [[2_2_gnss_ins_imu_fusion_ZH|ZH]] ○
- [ ] 2.3 LiDAR-based localization — scan-to-map, NDT / ICP localization · [[2_3_lidar_localization_EN|EN]] ○ · [[2_3_lidar_localization_ZH|ZH]] ○
- [ ] 2.4 Camera-based localization — visual odometry, place recognition, image retrieval · [[2_4_camera_localization_EN|EN]] ○ · [[2_4_camera_localization_ZH|ZH]] ○
- [ ] 2.5 Map-relative localization — HD-map alignment, semantic landmark matching · [[2_5_map_relative_localization_EN|EN]] ○ · [[2_5_map_relative_localization_ZH|ZH]] ○
- [ ] 2.6 SLAM essentials — LIO / VIO families · [[2_6_slam_essentials_EN|EN]] ○ · [[2_6_slam_essentials_ZH|ZH]] ○
- [ ] 2.7 HD-map building (offline) and online local mapping; freshness & change detection · [[2_7_hd_map_building_EN|EN]] ○ · [[2_7_hd_map_building_ZH|ZH]] ○
- [ ] 2.8 Uncertainty, drift & relocalization — covariance, divergence detection, calibration drift · [[2_8_uncertainty_drift_EN|EN]] ○ · [[2_8_uncertainty_drift_ZH|ZH]] ○
- [ ] 2.9 Deployment & failure modes — GNSS-denied operation, urban canyon, sensor degradation · [[2_9_deployment_failure_modes_EN|EN]] ○ · [[2_9_deployment_failure_modes_ZH|ZH]] ○
- [ ] 2.10 Safety & validation (template instance) · [[2_10_safety_and_validation_EN|EN]] ○ · [[2_10_safety_and_validation_ZH|ZH]] ○

## Chapter 3 — Object Detection Fundamentals + YOLO Conceptual Lineage

- [ ] 3.0 Overview · [[3_0_overview_EN|EN]] ◐ · [[3_0_overview_ZH|ZH]] ◐
- [ ] 3.1 Problem framing — boxes, labels, IoU, confidence · [[3_1_problem_framing_EN|EN]] ○ · [[3_1_problem_framing_ZH|ZH]] ○
- [ ] 3.2 Loss intuition for detection · [[3_2_loss_intuition_EN|EN]] ○ · [[3_2_loss_intuition_ZH|ZH]] ○
- [ ] 3.3 Data — datasets, augmentation, label noise · [[3_3_data_and_augmentation_EN|EN]] ○ · [[3_3_data_and_augmentation_ZH|ZH]] ○
- [ ] 3.4 Metrics & failure analysis · [[3_4_metrics_and_failure_analysis_EN|EN]] ○ · [[3_4_metrics_and_failure_analysis_ZH|ZH]] ○
- [ ] 3.5 Single-stage detection — YOLOv1 grid intuition; brief lineage pointer · [[3_5_yolo_idea_v1_EN|EN]] ○ · [[3_5_yolo_idea_v1_ZH|ZH]] ○

## Chapter 4 — Comprehensive Camera Perception Systems for AD

- [ ] 4.0 Overview · [[4_0_overview_EN|EN]] ◐ · [[4_0_overview_ZH|ZH]] ◐
- [ ] 4.1 YOLO family as deployed systems (v3 / v5 / v8 + user's "YOLO26") · [[4_1_yolo_deployed_systems_EN|EN]] ○ · [[4_1_yolo_deployed_systems_ZH|ZH]] ○
- [ ] 4.2 DETR family lineage · [[4_2_detr_family_EN|EN]] ○ · [[4_2_detr_family_ZH|ZH]] ○
- [ ] 4.3 Real-time DETRs — RT-DETR, DEIM, D-FINE · [[4_3_real_time_detrs_EN|EN]] ○ · [[4_3_real_time_detrs_ZH|ZH]] ○
- [ ] 4.4 Other modern detectors — FCOS, CenterNet, RTMDet · [[4_4_other_modern_detectors_EN|EN]] ○ · [[4_4_other_modern_detectors_ZH|ZH]] ○
- [ ] 4.5 Open-vocabulary & grounded detection · [[4_5_open_vocab_grounded_EN|EN]] ○ · [[4_5_open_vocab_grounded_ZH|ZH]] ○
- [ ] 4.6 Multi-object tracking — ByteTrack, OC-SORT, BoT-SORT · [[4_6_multi_object_tracking_EN|EN]] ○ · [[4_6_multi_object_tracking_ZH|ZH]] ○
- [ ] 4.7 Dense camera perception — segmentation (Mask2Former) + online HD-map (MapTR) · [[4_7_dense_camera_perception_EN|EN]] ○ · [[4_7_dense_camera_perception_ZH|ZH]] ○
- [ ] 4.8 Monocular & multi-camera 3D perception — FCOS3D, camera-only BEV, occupancy / scene completion · [[4_8_mono_multi_camera_3d_EN|EN]] ○ · [[4_8_mono_multi_camera_3d_ZH|ZH]] ○
- [ ] 4.9 Foundation-model features for AD perception — DINOv2, SAM, CLIP · [[4_9_foundation_features_EN|EN]] ○ · [[4_9_foundation_features_ZH|ZH]] ○
- [ ] 4.10 Specialized AD targets + traffic-light worked example (mingtai) · [[4_10_ad_targets_traffic_light_EN|EN]] ○ · [[4_10_ad_targets_traffic_light_ZH|ZH]] ○
- [ ] 4.11 Deployment & latency budgets for camera stacks · [[4_11_deployment_latency_EN|EN]] ○ · [[4_11_deployment_latency_ZH|ZH]] ○
- [ ] 4.12 Safety & validation (template instance) · [[4_12_safety_and_validation_EN|EN]] ○ · [[4_12_safety_and_validation_ZH|ZH]] ○

## Chapter 5 — Classical LiDAR Detection

- [ ] 5.0 Overview · [[5_0_overview_EN|EN]] ◐ · [[5_0_overview_ZH|ZH]] ◐
- [ ] 5.1 Point-cloud preprocessing · [[5_1_pointcloud_preprocessing_EN|EN]] ○ · [[5_1_pointcloud_preprocessing_ZH|ZH]] ○
- [ ] 5.2 Ground segmentation (RANSAC etc.) · [[5_2_ground_segmentation_EN|EN]] ○ · [[5_2_ground_segmentation_ZH|ZH]] ○
- [ ] 5.3 Clustering — Euclidean, DBSCAN · [[5_3_clustering_EN|EN]] ○ · [[5_3_clustering_ZH|ZH]] ○
- [ ] 5.4 Multi-object tracking — Kalman / IMM / JPDA · [[5_4_classical_tracking_EN|EN]] ○ · [[5_4_classical_tracking_ZH|ZH]] ○
- [ ] 5.5 Registration — ICP / NDT / GICP · [[5_5_registration_EN|EN]] ○ · [[5_5_registration_ZH|ZH]] ○
- [ ] 5.6 Occupancy grids & free-space · [[5_6_occupancy_grids_EN|EN]] ○ · [[5_6_occupancy_grids_ZH|ZH]] ○
- [ ] 5.7 ROS2 integration · [[5_7_ros2_integration_EN|EN]] ○ · [[5_7_ros2_integration_ZH|ZH]] ○
- [ ] 5.8 Deployment & runtime constraints · [[5_8_deployment_runtime_EN|EN]] ○ · [[5_8_deployment_runtime_ZH|ZH]] ○
- [ ] 5.9 Safety & validation (template instance) · [[5_9_safety_and_validation_EN|EN]] ○ · [[5_9_safety_and_validation_ZH|ZH]] ○

## Chapter 6 — Deep-Learning LiDAR Detection

- [ ] 6.0 Overview · [[6_0_overview_EN|EN]] ◐ · [[6_0_overview_ZH|ZH]] ◐
- [ ] 6.1 PointNet / PointNet++ · [[6_1_pointnet_EN|EN]] ○ · [[6_1_pointnet_ZH|ZH]] ○
- [ ] 6.2 VoxelNet / SECOND · [[6_2_voxelnet_second_EN|EN]] ○ · [[6_2_voxelnet_second_ZH|ZH]] ○
- [ ] 6.3 PointPillars · [[6_3_pointpillars_EN|EN]] ○ · [[6_3_pointpillars_ZH|ZH]] ○
- [ ] 6.4 CenterPoint & anchor-free 3D detection · [[6_4_centerpoint_EN|EN]] ○ · [[6_4_centerpoint_ZH|ZH]] ○
- [ ] 6.5 Transformer-based 3D detectors · [[6_5_transformer_3d_EN|EN]] ○ · [[6_5_transformer_3d_ZH|ZH]] ○
- [ ] 6.6 Eval metrics for 3D detection · [[6_6_eval_3d_EN|EN]] ○ · [[6_6_eval_3d_ZH|ZH]] ○
- [ ] 6.7 Deployment · [[6_7_deployment_EN|EN]] ○ · [[6_7_deployment_ZH|ZH]] ○
- [ ] 6.8 Safety & validation (template instance) · [[6_8_safety_and_validation_EN|EN]] ○ · [[6_8_safety_and_validation_ZH|ZH]] ○

## Chapter 7 — Camera + LiDAR Sensor Fusion (Goal 1)

- [ ] 7.0 Overview · [[7_0_overview_EN|EN]] ◐ · [[7_0_overview_ZH|ZH]] ◐
- [ ] 7.1 Calibration & sync revisited · [[7_1_calibration_sync_revisited_EN|EN]] ○ · [[7_1_calibration_sync_revisited_ZH|ZH]] ○
- [ ] 7.2 Early / mid / late fusion designs · [[7_2_fusion_designs_EN|EN]] ○ · [[7_2_fusion_designs_ZH|ZH]] ○
- [ ] 7.3 BEV paradigm — BEVFormer / BEVFusion · [[7_3_bev_paradigm_EN|EN]] ○ · [[7_3_bev_paradigm_ZH|ZH]] ○
- [ ] 7.4 Attention fusion — TransFusion · [[7_4_attention_fusion_EN|EN]] ○ · [[7_4_attention_fusion_ZH|ZH]] ○
- [ ] 7.5 Fusion outputs: tracks + uncertainty for downstream prediction · [[7_5_fusion_outputs_EN|EN]] ○ · [[7_5_fusion_outputs_ZH|ZH]] ○
- [ ] 7.6 Eval & failure modes · [[7_6_eval_and_failure_modes_EN|EN]] ○ · [[7_6_eval_and_failure_modes_ZH|ZH]] ○
- [ ] 7.7 Deployment · [[7_7_deployment_EN|EN]] ○ · [[7_7_deployment_ZH|ZH]] ○
- [ ] 7.8 Safety & validation (template instance) · [[7_8_safety_and_validation_EN|EN]] ○ · [[7_8_safety_and_validation_ZH|ZH]] ○

## Chapter 8 — Classical Motion Planning, Prediction & Control

- [ ] 8.0 Overview · [[8_0_overview_EN|EN]] ◐ · [[8_0_overview_ZH|ZH]] ◐
- [ ] 8.1 Behavior planning & state machines · [[8_1_behavior_planning_EN|EN]] ○ · [[8_1_behavior_planning_ZH|ZH]] ○
- [ ] 8.2 Classical prediction — CV / CTRV / IMM / social-force / rule-based · [[8_2_classical_prediction_EN|EN]] ○ · [[8_2_classical_prediction_ZH|ZH]] ○
- [ ] 8.3 Graph search — A*, D*-Lite, hybrid A* · [[8_3_graph_search_EN|EN]] ○ · [[8_3_graph_search_ZH|ZH]] ○
- [ ] 8.4 Sampling planners — RRT, RRT* · [[8_4_sampling_planners_EN|EN]] ○ · [[8_4_sampling_planners_ZH|ZH]] ○
- [ ] 8.5 Lattice & spline planners · [[8_5_lattice_spline_EN|EN]] ○ · [[8_5_lattice_spline_ZH|ZH]] ○
- [ ] 8.6 Control — PID, pure pursuit, Stanley · [[8_6_control_classical_EN|EN]] ○ · [[8_6_control_classical_ZH|ZH]] ○
- [ ] 8.7 MPC & optimal control · [[8_7_mpc_and_optimal_control_EN|EN]] ○ · [[8_7_mpc_and_optimal_control_ZH|ZH]] ○
- [ ] 8.8 Deployment & control-loop timing · [[8_8_deployment_control_loop_EN|EN]] ○ · [[8_8_deployment_control_loop_ZH|ZH]] ○
- [ ] 8.9 Safety & validation (template instance) · [[8_9_safety_and_validation_EN|EN]] ○ · [[8_9_safety_and_validation_ZH|ZH]] ○

## Chapter 9 — Deep-Learning Planning, Prediction & Control

- [ ] 9.0 Overview · [[9_0_overview_EN|EN]] ◐ · [[9_0_overview_ZH|ZH]] ◐
- [ ] 9.1 Imitation learning & behavior cloning · [[9_1_imitation_learning_EN|EN]] ○ · [[9_1_imitation_learning_ZH|ZH]] ○
- [ ] 9.2 Reinforcement learning for driving · [[9_2_rl_for_driving_EN|EN]] ○ · [[9_2_rl_for_driving_ZH|ZH]] ○
- [ ] 9.3 Learned trajectory prediction & multi-modal interaction · [[9_3_learned_prediction_EN|EN]] ○ · [[9_3_learned_prediction_ZH|ZH]] ○
- [ ] 9.4 Learned motion planners · [[9_4_learned_motion_planners_EN|EN]] ○ · [[9_4_learned_motion_planners_ZH|ZH]] ○
- [ ] 9.5 Neural MPC & hybrid systems · [[9_5_neural_mpc_hybrid_EN|EN]] ○ · [[9_5_neural_mpc_hybrid_ZH|ZH]] ○
- [ ] 9.6 Simulation — CARLA / Apollo · [[9_6_sim_carla_apollo_EN|EN]] ○ · [[9_6_sim_carla_apollo_ZH|ZH]] ○
- [ ] 9.7 Evaluation & safety (template instance) · [[9_7_eval_and_safety_EN|EN]] ○ · [[9_7_eval_and_safety_ZH|ZH]] ○

## Chapter 10 — AD Data Engine, Labeling & ML Operations

- [ ] 10.0 Overview · [[10_0_overview_EN|EN]] ◐ · [[10_0_overview_ZH|ZH]] ◐
- [ ] 10.1 The data flywheel · [[10_1_data_flywheel_EN|EN]] ○ · [[10_1_data_flywheel_ZH|ZH]] ○
- [ ] 10.2 Log mining & scenario selection · [[10_2_log_mining_EN|EN]] ○ · [[10_2_log_mining_ZH|ZH]] ○
- [ ] 10.3 Labeling — manual + auto, QA, IAA · [[10_3_labeling_EN|EN]] ○ · [[10_3_labeling_ZH|ZH]] ○
- [ ] 10.4 Active learning & uncertainty-driven sampling · [[10_4_active_learning_EN|EN]] ○ · [[10_4_active_learning_ZH|ZH]] ○
- [ ] 10.5 Dataset governance · [[10_5_dataset_governance_EN|EN]] ○ · [[10_5_dataset_governance_ZH|ZH]] ○
- [ ] 10.6 Training infrastructure · [[10_6_training_infra_EN|EN]] ○ · [[10_6_training_infra_ZH|ZH]] ○
- [ ] 10.7 Experiment tracking, model registry & lineage · [[10_7_experiment_tracking_EN|EN]] ○ · [[10_7_experiment_tracking_ZH|ZH]] ○
- [ ] 10.8 CI for ML · [[10_8_ci_for_ml_EN|EN]] ○ · [[10_8_ci_for_ml_ZH|ZH]] ○
- [ ] 10.9 Production monitoring · [[10_9_production_monitoring_EN|EN]] ○ · [[10_9_production_monitoring_ZH|ZH]] ○
- [ ] 10.10 Closing the loop — shared data engine across teams · [[10_10_closing_the_loop_EN|EN]] ○ · [[10_10_closing_the_loop_ZH|ZH]] ○

## Chapter 11 — Safety, Validation & Operational Discipline

- [ ] 11.0 Overview · [[11_0_overview_EN|EN]] ◐ · [[11_0_overview_ZH|ZH]] ◐
- [ ] 11.1 ODD revisited · [[11_1_odd_revisited_EN|EN]] ○ · [[11_1_odd_revisited_ZH|ZH]] ○
- [ ] 11.2 Hazard analysis & risk assessment (HARA) · [[11_2_hara_EN|EN]] ○ · [[11_2_hara_ZH|ZH]] ○
- [ ] 11.3 Scenario-based testing · [[11_3_scenario_based_testing_EN|EN]] ○ · [[11_3_scenario_based_testing_ZH|ZH]] ○
- [ ] 11.4 Simulation limits & sim-to-real gap · [[11_4_sim_limits_sim2real_EN|EN]] ○ · [[11_4_sim_limits_sim2real_ZH|ZH]] ○
- [ ] 11.5 Runtime monitoring & graceful fallback · [[11_5_runtime_monitoring_EN|EN]] ○ · [[11_5_runtime_monitoring_ZH|ZH]] ○
- [ ] 11.6 Disengagement & failure-mode taxonomy · [[11_6_disengagement_failure_modes_EN|EN]] ○ · [[11_6_disengagement_failure_modes_ZH|ZH]] ○
- [ ] 11.7 Safety case structure & validation evidence · [[11_7_safety_case_EN|EN]] ○ · [[11_7_safety_case_ZH|ZH]] ○
- [ ] 11.8 ISO 26262 & SOTIF — background context · [[11_8_iso26262_sotif_EN|EN]] ○ · [[11_8_iso26262_sotif_ZH|ZH]] ○
- [ ] 11.9 On-vehicle bring-up & validation discipline · [[11_9_on_vehicle_bringup_EN|EN]] ○ · [[11_9_on_vehicle_bringup_ZH|ZH]] ○

## Chapter 12 — End-to-End Autonomous Driving (Capstone)

- [ ] 12.0 Overview · [[12_0_overview_EN|EN]] ◐ · [[12_0_overview_ZH|ZH]] ◐
- [ ] 12.1 Definition & taxonomy (resolves the open question) · [[12_1_definition_and_taxonomy_EN|EN]] ○ · [[12_1_definition_and_taxonomy_ZH|ZH]] ○
- [ ] 12.2 UniAD & one-model paradigms · [[12_2_uniad_one_model_EN|EN]] ○ · [[12_2_uniad_one_model_ZH|ZH]] ○
- [ ] 12.3 VLA & foundation-model drivers · [[12_3_vla_foundation_models_EN|EN]] ○ · [[12_3_vla_foundation_models_ZH|ZH]] ○
- [ ] 12.4 Data & training at scale · [[12_4_data_training_scale_EN|EN]] ○ · [[12_4_data_training_scale_ZH|ZH]] ○
- [ ] 12.5 Eval / sim / safety case · [[12_5_eval_sim_safety_case_EN|EN]] ○ · [[12_5_eval_sim_safety_case_ZH|ZH]] ○
- [ ] 12.6 Integration considerations · [[12_6_integration_considerations_EN|EN]] ○ · [[12_6_integration_considerations_ZH|ZH]] ○
- [ ] 12.7 Open research problems · [[12_7_open_research_problems_EN|EN]] ○ · [[12_7_open_research_problems_ZH|ZH]] ○

---

## Reading list

See [[reading_list]] for the curated list of papers, books, specs, and tech reports the reader should sample alongside each chapter (region-tagged: `region/cn`, `region/us`, `region/eu`).
