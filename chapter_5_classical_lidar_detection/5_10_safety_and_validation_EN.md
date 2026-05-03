---
chapter: 5
section: 10
title: Safety & validation
language: EN
workflow_status: reviewing
tags:
  - book/section
  - book/chapter-5
  - lang/EN
---

# 5.10 Safety & validation

Sections 5.1 through 5.9 each closed with a per-section failure-mode catalog row. This section is the chapter-level synthesis. It does three things no algorithm section can: it organizes the 37 catalog entries into one chapter-wide hazard inventory the reader can scan at a glance; it argues that 3D / BEV mAP is necessary but not sufficient as a validation signal for a classical LiDAR pipeline; and it anchors the catalog to the ODD vocabulary from [[1_10_odd_primer_EN|Ch 1 §1.10]] before pointing forward to [[11_0_overview_EN|Ch 11]] for the formal hazard-analysis process. The doorway is more than vocabulary, less than the room.

## The chapter-wide failure-mode index

The catalog has 37 entries: 34 per-section rows owned by §§5.1–5.9 and 3 cross-section rows owned by §5.10 itself. Each per-section row already lives in its host section under the 6-field schema (id / cause / observable\_symptom / downstream\_hazard / mitigation / validation\_test); reproducing that schema 37 times here would balloon the section by an order of magnitude with no pedagogical gain. The index below is therefore a 3-column digest: the wikilinked id, a paraphrased ≤ 15-word cause, and a paraphrased ≤ 15-word downstream hazard. The host section is authoritative; the index paraphrases for skim-readability and is the reader's jump table back to the full row.

The entries are grouped under four cause-class buckets in this fixed order: (1) geometric / single-stage, (2) temporal / single-stage, (3) cross-stage, (4) configuration / scheduler / deployment-time. The bucket-assignment rule is **where the fix lands, not where the symptom appears**. So `5_cross.fm.deskew_then_cluster_doubling` is cross-stage even though the symptom shows up in §5.3, because the fix is at §5.1's deskew. `5_2.fm.flatbed_truck_as_ground` is configuration/deployment-time even though the symptom is in §5.2, because the dominant fix is elevation-band tuning rather than a §5.2 algorithm change. The rule is binding for every row below.

### Bucket 1 — geometric / single-stage (18)

| id | cause | downstream hazard |
|---|---|---|
| [[5_1_pointcloud_preprocessing_EN\|5_1.fm.rain_spray_ghosts]] | Spray, fog, or exhaust returns survive simple SOR/ROR thresholds. | Phantom obstacles trigger braking or block free-space clearance. |
| [[5_1_pointcloud_preprocessing_EN\|5_1.fm.deskew_failure_doubling]] | Missing per-point time or stale `/tf` skews points to inconsistent poses. | Doubled or curved structures break clustering, fitting, and tracking. |
| [[5_2_ground_segmentation_EN\|5_2.fm.curb_eaten_as_ground]] | Loose ground thresholds absorb curb tops and faces into the ground class. | Low road-edge obstacles are missed and free-space clears across curbs. |
| [[5_2_ground_segmentation_EN\|5_2.fm.ramp_misclassified]] | Near-horizontal local-plane assumptions break on grades, ramps, and banked roads. | Phantom obstacle bands on slopes or false residual creates planner-blocking actors. |
| [[5_2_ground_segmentation_EN\|5_2.fm.overpass_single_layer]] | Single-surface ground model cannot represent road below and deck above at one BEV cell. | Free-space clears under elevated structure or broad false residual sheets appear. |
| [[5_2_ground_segmentation_EN\|5_2.fm.standing_water_sparse_returns]] | Wet or specular surfaces deliver missing or unstable low returns. | False obstacles trigger braking or genuinely drivable wet road fails to clear. |
| [[5_3_clustering_EN\|5_3.fm.range_bias_oversegmentation]] | Fixed Euclidean tolerance is too tight for sparse far-range density. | Far pedestrians fragment into multiple tracks or drop out as unstable. |
| [[5_3_clustering_EN\|5_3.fm.merged_close_vehicles]] | Tolerance too large in dense near-field, or low-residual bridges actors. | Oversized fitted box blocks free space and biases planner clearance. |
| [[5_3_clustering_EN\|5_3.fm.dbscan_eps_too_small]] | DBSCAN eps and minPts tuned on dense near returns reject sparse far points. | Distant pedestrians or cones go unclustered; planner sees no obstacle. |
| [[5_3_clustering_EN\|5_3.fm.range_image_projection_holes]] | Missing rings, bad deskew, or fused projection creates artificial holes or adjacency. | Components flicker; tracker oscillates between birth and deletion. |
| [[5_4_object_shape_fitting_EN\|5_4.fm.yaw_flip]] | Near-square cluster or weak L-corner makes yaw choice unstable across frames. | Planner sees an actor "rotating in place" and over-brakes for phantom yaw. |
| [[5_4_object_shape_fitting_EN\|5_4.fm.partial_view_undersized_box]] | Sparse partial cluster fits visible extent without class-prior back-fill. | Tracker absorbs spurious extent change as motion; planner under-reserves clearance. |
| [[5_4_object_shape_fitting_EN\|5_4.fm.wrong_prior_inflated_box]] | Misidentified corner or wrong gross-class lookup back-fills the wrong dimensions. | Inflated box over-reserves clearance; lane-change decisions become wrongly conservative. |
| [[5_4_object_shape_fitting_EN\|5_4.fm.l_pointing_wrong_way]] | Single visible face leaves L-search no second arm to anchor yaw. | Leading vehicle reads as crossing actor; ACC and lane logic misfire. |
| [[5_4_object_shape_fitting_EN\|5_4.fm.spray_inflated_box]] | Spray points attach to a vehicle cluster and bias the closeness score. | Following gap shrinks; trailing-edge oscillation confuses distance estimation. |
| [[5_4_object_shape_fitting_EN\|5_4.fm.subcluster_halves_one_box]] | Clustering splits one vehicle along a low-return seam into two sub-clusters. | Two half-tracks per actor invent a non-existent gap or overtakeable obstacle. |
| [[5_6_registration_EN\|5_6.fm.icp_local_minimum]] | Small ICP basin plus weak prior or near-symmetric geometry traps the optimizer. | Map subtraction produces ghost dynamic obstacles; accumulation doubles structure. |
| [[5_6_registration_EN\|5_6.fm.gicp_degenerate_covariance]] | GICP per-point covariance collapses on featureless or single-line geometry. | Deskew refinement injects worse trajectory than the IMU baseline. |

### Bucket 2 — temporal / single-stage (4)

| id | cause | downstream hazard |
|---|---|---|
| [[5_5_classical_tracking_EN\|5_5.fm.id_switch_under_occlusion]] | Occlusion or crossing tempts hard NN association into the wrong post-reappearance match. | Fusion and prediction inherit another actor's history and intent. |
| [[5_5_classical_tracking_EN\|5_5.fm.kf_diverges_on_turn]] | Constant-velocity Kalman process noise too low for curved-path actors. | Track coasts off, new track is born; planner sees disappearance plus appearance. |
| [[5_5_classical_tracking_EN\|5_5.fm.ghost_track_from_clutter]] | Birth thresholds too permissive for spray, reflections, or one-frame fit artifacts. | False obstacles suppress free-space and trigger unnecessary braking. |
| [[5_5_classical_tracking_EN\|5_5.fm.coasted_track_outlives_object]] | Delete threshold or coast quality checks too lenient after exit or false birth. | Planner reserves space for a non-existent object; fusion preserves the ghost. |

### Bucket 3 — cross-stage (4)

| id | cause | downstream hazard |
|---|---|---|
| [[5_3_clustering_EN\|5_cross.fm.deskew_then_cluster_doubling]] | Stale `/tf` or missing per-point time leaves residual smear past ground segmentation. | Two undersized boxes per actor or one mis-yawed box; ID switches at every turn. |
| [[5_7_occupancy_freespace_map_roi_EN\|5_7.fm.map_suppresses_real_actor]] | ROI gating filters a real cluster outside the rasterized drivable polygon. | Planner does not see actor; safety miss unless the ungated GOD fallback is wired. |
| [[5_7_occupancy_freespace_map_roi_EN\|5_7.fm.localization_drift_offsets_roi]] | Localization drifts more than one BEV cell relative to the precomputed ROI lookup. | Edge clusters flicker in and out of gating; planner sees a non-stationary world. |
| [[5_7_occupancy_freespace_map_roi_EN\|5_7.fm.ray_casting_through_glass]] | Specular returns through glass let ray casting clear cells beyond the surface. | GOD may miss pedestrians behind glass; corridor reads as drivable. |

### Bucket 4 — configuration / scheduler / deployment-time (11)

| id | cause | downstream hazard |
|---|---|---|
| [[5_1_pointcloud_preprocessing_EN\|5_1.fm.intensity_misclassification]] | Rule treats intensity as material identity across sensor, weather, and incidence drift. | Lane, reflector, or ROI filters suppress real objects or invent semantic cues. |
| [[5_2_ground_segmentation_EN\|5_2.fm.flatbed_truck_as_ground]] | Weak elevation rejection or wrong sensor-height config admits horizontal vehicle surfaces. | Truck beds removed; planner sees free space under a real vehicle. |
| [[5_6_registration_EN\|5_6.fm.ndt_voxel_size_mismatch]] | NDT voxel size from one sensor reused on a sparser or denser one. | Slow alignment bias drifts ROI off drivable polygon; clusters flicker at edges. |
| [[5_7_occupancy_freespace_map_roi_EN\|5_7.fm.stale_map_after_construction]] | HD map older than the road state — repaint, new lane, construction barrier installed. | Phantom dynamics flood tracker, or a real lane is gated out of detection. |
| [[5_8_ros2_integration_EN\|5_8.fm.missing_tf_static]] | Replay or launch omits `/tf_static`; `lidar → base_link` extrinsic is unavailable. | Detections shift relative to ego-pose; ROI gating rejects real obstacles. |
| [[5_8_ros2_integration_EN\|5_8.fm.qos_mismatch_drops_clouds]] | Incompatible QoS profiles drop large sensor messages between publisher and subscriber. | Tracker coasts through real objects; runtime budget looks falsely healthy. |
| [[5_8_ros2_integration_EN\|5_8.fm.sim_time_not_honored]] | Replay nodes use wall time while messages carry bag time on `/clock`. | TF2 extrapolation errors; deskew, ROI, and tracking are non-reproducible. |
| [[5_8_ros2_integration_EN\|5_8.fm.pointcloud2_offset_drift]] | Producer and consumer disagree on field offsets, padding, or `time` datatype. | Deskew creates curved walls or NaN clusters; ground and clustering corrupted. |
| [[5_9_deployment_runtime_EN\|5_9.fm.frame_budget_overrun_p99]] | Correlated tails on §5.6 + §5.3 + §5.2 push the every-frame chain past 100 ms. | Tracker covariance grows; occupancy misses cells; planner sees stale state. |
| [[5_9_deployment_runtime_EN\|5_cross.fm.subrate_registration_starves_under_load]] | Sustained CPU pressure makes the §5.6 Role-2 GICP miss its sub-rate slot for windows. | Stale prior-map drift; building shoulders flagged as dynamic obstacles. |
| [[5_9_deployment_runtime_EN\|5_cross.fm.sensor_class_mismatch_at_deploy]] | Pipeline tuned on one LiDAR class is deployed on a denser, sparser, or multi-LiDAR one. | All stages drift quietly; failure looks like a bad sensor, not bad parameters. |

## What the index reveals at chapter scale

Three patterns are visible only when the 37 entries sit on one page. The first is that **the chapter's most common failure mode is silent degradation, not loud failure**. Bucket 4 holds eleven entries — close to a third of the catalog — and almost every one is a configuration mismatch that produces metric drift rather than a crash. A §5.8 QoS mismatch shows up as a runtime budget that looks healthy because frames have been silently dropped; an NDT voxel-size mismatch produces a sub-decimeter alignment bias that nothing in the per-stage diagnostics flags. The catalog's `validation_test` column lives in the host sections; the chapter-wide observation is that without those tests, most of these failures pass unit-level review.

The second pattern is that **safety-load-bearing entries cluster in §5.7 and §5.2** — the stages where "did not see an actor that exists" is the dominant failure shape. `5_7.fm.map_suppresses_real_actor` and `5_2.fm.flatbed_truck_as_ground` both delete a real obstacle from the residual the planner consumes; the planner cannot recover what perception did not pass through. Other entries (id switches, oscillating clusters, stale tracks) degrade what the planner sees but do not erase actors, and that distinction is operationally meaningful.

The third is that **cross-stage failures (Bucket 3) are under-counted by construction**. The catalog convention awards one ID per cross-stage symptom, but the symptom often spans three or four stages — `5_cross.fm.deskew_then_cluster_doubling` lives in §5.1, surfaces in §5.3, and breaks §5.4 fitting and §5.5 tracking simultaneously. Treating each as one entry is bookkeeping discipline, not a claim about how widely the fault propagates.

## mAP as a planning-usefulness proxy: necessary, not sufficient

3D and BEV mAP are well-defined matching statistics: predicted boxes are matched to ground truth at one or more IoU thresholds, missed actors penalize recall, and duplicate or spurious boxes penalize precision. Within a frame, mAP correctly registers a missing pedestrian or an extra ghost cluster. The pedagogical mistake — and the one [[3_4_detection_metrics_EN|Ch 3 §3.4]] is careful to avoid — is treating that within-frame matching as the full validation story.

mAP under-weights or does not score five things the planner cares about. **Severity weighting**: a 2 cm box-edge error on a far parked car and a 30° yaw error on a leading vehicle can both stay above IoU 0.5, and mAP weights them equally. **Track continuity**: mAP is per-frame, so `5_5.fm.id_switch_under_occlusion`, `5_5.fm.coasted_track_outlives_object`, and `5_5.fm.ghost_track_from_clutter` leave per-frame numbers untouched while breaking Ch 7 fusion and Ch 8 prediction. **Topology within an actor**: `5_4.fm.yaw_flip` and `5_4.fm.l_pointing_wrong_way` are heading-only failures that often stay above the IoU threshold because IoU compares footprints, not heading axes. **Behaviour-level correctness**: whether ego's gap to a leading actor is right, whether free-space is honestly cleared, whether the system silently drops a frame under correlated tail load — `5_cross.fm.subrate_registration_starves_under_load` is invisible to per-frame mAP by construction. **ODD coverage**: a benchmark mAP measures performance on the benchmark's ODD; failure modes outside that distribution are absent from the score.

The four catalog entries above each illustrate a different gap: `5_3.fm.range_bias_oversegmentation` is severity-weighting, `5_4.fm.yaw_flip` is topology, `5_5.fm.id_switch_under_occlusion` is track continuity, and `5_cross.fm.subrate_registration_starves_under_load` is behaviour-level. The missing half of validation is **scenario-based testing** — replay against curated logs with engineering-grade ground truth (free-space polygons, track continuity, gap correctness) and assert behaviour, not just per-frame overlap. The methodology belongs to [[11_3_scenario_based_testing_EN|Ch 11 §11.3]]. The discipline here is that mAP is necessary, not sufficient. It remains the right metric for what it measures; the chapter's failure modes show what it does not.

## ODD anchor and the informal practical safety argument

The catalog is not a free-floating hazard list — every entry binds to assumptions [[1_10_odd_primer_EN|Ch 1 §1.10]] groups under the **Operational Design Domain (ODD)**. Weather ODD anchors `5_2.fm.standing_water_sparse_returns` and `5_1.fm.rain_spray_ghosts`; road-grade ODD anchors `5_2.fm.ramp_misclassified`; map-freshness ODD anchors `5_7.fm.stale_map_after_construction`; sensor-class ODD anchors `5_cross.fm.sensor_class_mismatch_at_deploy`; dynamic-actor ODD anchors `5_5.fm.kf_diverges_on_turn`. Inside its tuned ODD — flat or near-flat grade, weather inside the calibrated envelope, map freshness inside the budget, sensor class matching the tuned profile, actor dynamics inside the tracker's process noise — the classical pipeline can defend a bounded set of behaviours given the mitigations the host sections committed. Outside those bounds the catalog has gaps, and that gap structure is itself a safety claim. The Generic Obstacle Detection / occupancy fallback from [[5_7_occupancy_freespace_map_roi_EN|§5.7]] is the chapter's primary defence for object classes the per-class detector was never designed for; it is a backstop, not a substitute for an unanticipated-conditions process.

> [!note] Vocabulary doorway
> Three terms are introduced here and formally defined in [[11_0_overview_EN|Ch 11]]: **HARA** (Hazard Analysis and Risk Assessment, [[11_0_overview_EN|Ch 11]] §11.2), **ASIL** (Automotive Safety Integrity Level, §11.8), and **SOTIF** (Safety of the Intended Functionality, ISO 21448, §11.8). The catalog supports an informal practical argument about what classical LiDAR detection can defend inside its ODD; it does not assign ASIL ratings, propose a HARA structure, claim ISO 26262 or 21448 compliance, or construct a formal safety case. SOTIF-class failures — unanticipated triggering conditions outside the catalog — are by construction outside this section's scope and are why the GOD fallback is wired ungated.

## Forward point

[[11_0_overview_EN|Ch 11]] picks up the formal hazard-analysis process and the scenario-based testing methodology this section deferred. [[6_0_overview_EN|Ch 6]] inherits most of the catalog: many entries survive structurally under DL primary detection, while §5.3 and §5.4 entries shift cause-class as classical clustering and shape fitting are replaced.
