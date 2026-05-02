---
chapter: 5
section: 5
title: Multi-object tracking — Kalman / IMM / JPDA
language: EN
workflow_status: reviewing
tags:
  - book/section
  - book/chapter-5
  - lang/EN
---

# 5.5 Multi-object tracking — Kalman / IMM / JPDA

The Ch 5 classical pipeline is `preprocess → ground → cluster → fit → track`. Tracking is the temporal step: it turns per-frame fitted boxes from [[5_4_object_shape_fitting_EN|Ch 5 §5.4]] into object histories with identity, velocity, lifecycle status, and uncertainty. A detector answers "what boxes exist in this frame?" A tracker answers "which boxes belong to the same actor over time?"

The input contract is fixed. §5.4 produces fitted boxes per frame:

```text
(x, y, z, l, w, h, yaw, optional class)
```

This section consumes those boxes, not raw clusters and not `PointCloud2`. The tracking output is published every frame as:

```text
(x, y, z, l, w, h, yaw, vel, optional class, track_id, age, status)
```

with a covariance estimate.

**The tracking state is maintained in `odom`, not `base_link`.** A track's velocity is the actor's velocity in the world; `base_link` is the ego-vehicle's body frame, so a stationary actor in `base_link` carries the *negative* ego velocity, and a CV-KF in `base_link` would treat every parked car as moving backward at ego speed. Tracking in `odom` (the locally-consistent ego-pose frame from [[2_3_lidar_localization_EN|Ch 2 §2.3]]) makes ego-motion compensation implicit: detections from §5.4 arrive in `base_link` and the tracker transforms them into `odom` using the timestamped ego-pose at `header.stamp` before predict/update. Published tracks are emitted in `odom` with a frame-of-reference field; downstream consumers that need `base_link` (planner near-field, visualization) reproject from `odom` using the same ego-pose. `map` is used when global consistency over hours of operation is required (HD-map-relative consumers, longer-horizon prediction). The frame must be explicit on every message; `base_link`, `odom`, and `map` are not interchangeable labels, and a tracker that runs filter math in `base_link` without explicit ego-motion compensation is a known failure pattern, not a stylistic choice.

The prerequisites are small. A Kalman filter is a recursive estimator with a state, prediction model, measurement model, and covariance. Association assigns detections to existing tracks. The ego-state from Ch 2 provides ego-pose and ego-motion ([[2_1_ego_state_estimation_EN|Ch 2 §2.1]] / [[2_2_gnss_ins_imu_fusion_EN|Ch 2 §2.2]]) — its freshness and accuracy bound the tracker's correctness because every measurement transform from `base_link` to `odom` consumes a timestamped ego-pose lookup.

> [!info]
> Classical LiDAR tracking is Tracking-by-detection. The tracker does not rediscover objects from points. It consumes fitted 3D boxes and repairs the temporal defects left by clustering and shape fitting: missed boxes, yaw flips, split boxes, merged boxes, and identity ambiguity.

## CV-KF as the entry point

The constant-velocity Kalman filter is the first tracker worth building because it makes the contract visible. In bird's-eye view, the state can be

```text
x = [ px, py, vx, vy ]ᵀ
```

or, when vertical motion matters,

```text
x = [ px, py, pz, vx, vy, vz ]ᵀ
```

For most road actors, `z`, `l`, `w`, `h`, and `yaw` are measured fields carried alongside the dynamic state or lightly filtered with scalar filters. The hot path is BEV motion: `x`, `y`, velocity, covariance, and identity.

For a timestep `dt`, the CV prediction is:

```text
x_k|k-1 = F x_k-1|k-1
P_k|k-1 = F P_k-1|k-1 Fᵀ + Q

F = [ 1 0 dt 0
      0 1 0  dt
      0 0 1  0
      0 0 0  1  ]
```

The measurement from §5.4 is normally the box center, sometimes plus yaw and dimensions:

```text
z_k = [ x_box, y_box ]ᵀ
z_k = H x_k + v_k
```

with `H` selecting position from the state. The update is the standard Kalman filter step:

```text
y = z - H x
S = H P Hᵀ + R
K = P Hᵀ S⁻¹
x ← x + K y
P ← (I - K H) P
```

`Q` says how much unmodeled acceleration is expected. `R` says how noisy the fitted box measurement is. Sparse far clusters should have larger `R`; fresh near-field boxes can be trusted more. A coasted track should grow `P` during prediction so association gates widen honestly.

> [!tip]
> Start with CV-KF in `odom` (per the frame discussion above), Mahalanobis gating, and Hungarian association before adding model complexity. Most tracking bugs are frame, timestamp, association, or lifecycle bugs, not filter-equation bugs.

## CTRV and CTRA

CV breaks when motion is not approximately straight over the association horizon. A vehicle entering an intersection, a cyclist turning across the ego lane, or a car following a curved ramp may have a center trajectory that no constant `vx, vy` model can predict. The observable symptom is a tracker that lags the turn, rejects the correct detection, and spawns a new track.

CTRV, the constant turn-rate and velocity model, changes the state to match the vehicle-like geometry:

```text
x = [ px, py, v, yaw, yaw_rate ]ᵀ
```

Instead of independent `vx` and `vy`, the model predicts the center by integrating speed along heading while yaw changes at `yaw_rate`. CTRA adds longitudinal acceleration:

```text
x = [ px, py, v, a, yaw, yaw_rate ]ᵀ
```

These models are nonlinear, so implementations usually use an extended Kalman filter or unscented Kalman filter. The measurement still comes from the same §5.4 box tuple `(x, y, z, l, w, h, yaw, optional class)`. The difference is the state transition, not the detector interface.

CTRV / CTRA are natural for vehicles but awkward for pedestrians. A pedestrian can stop, sidestep, turn in place, and violate the minimum-turning-radius intuition that makes CTRV useful. A tracker that applies one motion model to every actor will either overfit vehicles or underfit pedestrians.

## IMM

IMM, the Interacting Multiple Model filter, is the classical answer when one motion model is too brittle. It runs several filters in parallel, mixes their states through a transition-probability matrix, updates each model with the same measurement, and weights the models by measurement likelihood. The output is a weighted state and covariance.

A practical LiDAR tracker might use:

| model | actor behavior it covers |
|---|---|
| stationary / low-speed CV | parked vehicles, stopped traffic, standing pedestrians |
| CV | straight cruise and most short-horizon road motion |
| CTRV | turning vehicles and curved-lane motion |
| CTRA | braking, accelerating, and ramp entries |

IMM cannot recover from bad detections or impossible association. Its value is that covariance and prediction shape follow observed dynamics. A track can behave like stationary clutter, cruise straight, and then shift weight toward CTRV as the vehicle turns without changing `track_id`.

## Association

Association is the other half of tracking. Prediction says where each existing track should be. Association decides which detection, if any, belongs to each track. The cost can be 3D IoU, BEV IoU, center distance, Mahalanobis distance, yaw difference, class mismatch penalty, or a weighted combination. Gating removes impossible pairs before optimization.

Nearest-Neighbor (NN) is the simplest rule: for each track, take the closest gated detection. It works in sparse scenes where boxes are well separated. It breaks under crossing actors because local choices steal detections from each other. Two pedestrians passing at close range, or two cars in adjacent lanes during a lane change, are enough to create an identity switch.

Global Nearest Neighbor (GNN) solves one assignment for the whole frame. In production classical trackers, GNN usually means a cost matrix plus the Hungarian algorithm. Rows are tracks, columns are detections, and invalid gated pairs receive a large cost. Hungarian returns the minimum-cost one-to-one assignment. It is deterministic, fast enough for dozens of objects, and easy to diagnose.

JPDA, Joint Probabilistic Data Association, keeps multiple plausible associations instead of committing to one hard pair. Each track update is a probability-weighted mixture over gated detections, with clutter and missed-detection hypotheses included. JPDA is useful in dense scenes where two or three detections are genuinely ambiguous for several frames. The tradeoff is that identities can become smeared if the scene remains ambiguous and the implementation does not manage covariance inflation carefully.

MHT, Multiple Hypothesis Tracking, pushes the idea further. It maintains a tree of association hypotheses across frames, prunes low-probability branches, and delays commitment until later evidence resolves ambiguity. MHT is principled and expensive. It earns its keep in hard occlusion and crossing scenarios, but the branch management, pruning policy, and latency budget are more complex than Hungarian GNN. For the Ch 5 pilot, MHT belongs in the "understand the upgrade path" bucket, not the first deployable implementation.

> [!example]
> ```python
> predict_all_tracks(dt)
> C = build_gated_cost_matrix(tracks, detections)
> matches, unmatched_tracks, unmatched_dets = hungarian(C)
> update_matched_tracks(matches)
> coast_unmatched_tracks(unmatched_tracks)
> birth_tracks(unmatched_dets)
> delete_stale_tracks()
> ```

## AB3DMOT

AB3DMOT from Weng and Kitani (2020) is the canonical 3D MOT baseline for this section. Its strength is restraint: take 3D detections, run a Kalman filter per object, associate detections and tracks with Hungarian, and gate with simple 3D IoU or distance-style costs. It is fast and competitive because Tracking-by-detection depends heavily on stable detections, reasonable motion prediction, and conservative identity management.

AB3DMOT is also a useful teaching boundary. It assumes the detector already emits boxes. It does not solve LiDAR shape fitting, semantic classification, re-identification, or prediction. A long occlusion or a clean crossing with similar boxes can still produce an identity switch.

AB3DMOT remains a baseline because it exposes the minimum working skeleton: state, covariance, gating, Hungarian association, lifecycle, and metrics.

Tracking is one of the load-bearing classical pieces that **survives inside DL-primary stacks**. The detection layer in production L4 robotaxi and most consumer NOA stacks is now learned (PointPillars / SECOND / CenterPoint and successors — see Ch 6), but the temporal layer over those detections is still very often a Kalman / Hungarian / lifecycle pipeline of the kind this section teaches, with learned ID-embeddings or appearance cues as optional add-ons. The reasons are practical: the math is interpretable, the failure modes are diagnosable, and the layer has to compose with downstream prediction (Ch 8) and fusion (Ch 7) which themselves have classical components. [[5_9_deployment_runtime_EN|§5.9]] picks up this argument with explicit ODD bounds.

## Track lifecycle

A tracker needs a lifecycle because detections are noisy. A single fitted box should not instantly become a planning-grade object, and one missed frame should not instantly delete a real actor.

Birth starts from an unmatched detection. Many systems use M-of-N confirmation: a tentative track becomes confirmed only if it receives at least `M` associated detections in the last `N` frames. The output `status` is `birth` until the track is trusted.

Confirm means the track is stable enough to publish as a normal object. Confirmed tracks carry `track_id`, `age`, velocity, covariance, and filtered shape fields. Ch 7 fusion can merge them with camera or radar tracks; Ch 8 prediction can use their velocity history.

Coast means predict-only. No detection was associated this frame, but the track is still plausible. Coasting is what prevents a one-frame missed box from creating a disappearing-and-reappearing object. The covariance grows during coast, and the published status is `coast` so downstream consumers know the track is not freshly observed.

Delete means the track is removed after `K` consecutive misses, after its covariance grows past a quality threshold, after it exits the region of interest, or after its likelihood falls below a lifecycle threshold. Deletion policy is safety-relevant: delete too quickly and real occluded actors vanish; delete too slowly and ghost tracks outlive objects.

Lifecycle must connect directly to §5.4 failure modes. Yaw flips should not create new identities if center and dimensions remain consistent. Missed boxes from sparse far clusters should trigger coast, not immediate delete. Split boxes should either associate to the strongest existing track or be suppressed by shape and IoU gates.

## Camera tracker handoff

[[4_6_camera_tracking_EN|Ch 4 §4.6]] covers ByteTrack, OC-SORT, and BoT-SORT on the camera side. The ideas migrate: prediction, association, lifecycle, confidence thresholds, and identity management are the same conceptual machinery. The measurement model is different. Camera trackers associate 2D image boxes and often lean on detector confidence and appearance cues. LiDAR trackers associate 3D boxes in `odom` (per the frame discussion at the section opening), with metric distance, 3D/BEV IoU, yaw, dimensions, and covariance.

This distinction matters for [[7_0_overview_EN|Ch 7]] fusion. Fusion receives tracks that already have metric position and covariance, not image-plane rectangles. It also matters for [[8_0_overview_EN|Ch 8]] prediction: prediction should see stable identity and velocity, but it should not inherit unmarked coasted states as if they were fresh observations.

## Output contract

§5.5 publishes one track message per active track every frame:

```text
(x, y, z, l, w, h, yaw, vel, optional class, track_id, age, status)
```

`vel` is normally `(vx, vy)` for BEV consumers or `(vx, vy, vz)` when vertical velocity is estimated. `status` is one of `birth`, `confirm`, `coast`, `delete`. `delete` can be emitted as a final tombstone for one frame, or represented by absence after the last coasted publish. The uncertainty estimate is typically the Kalman covariance over dynamic state.

Frame policy for this chapter: the tracker maintains and publishes primary tracks in `odom` (per the section opening). Diagnostics monitor ego-pose freshness — staleness in the `base_link → odom` transform shows up as a tracking failure, not a §5.1 or §5.8 failure, because every measurement transform consumes that lookup. Downstream `base_link` consumers (planner near-field, visualization) reproject from `odom`. [[5_6_registration_EN|Ch 5 §5.6]] is relevant when localization is degraded enough that the `odom → map` connection or even the `base_link → odom` consistency must be refreshed by registration.

Per the [[5_4_object_shape_fitting_EN|§5.4]] output contract, fitted boxes carry side-channel diagnostic fields alongside the binding tuple: `extent_source ∈ {visible_only, class_prior_backfill}`, `yaw_confidence ∈ [0, 1]`, and `corner_visibility ∈ {two_corners, one_corner, no_corner}`. The tracker consumes these to gate behavior:

- when `extent_source = visible_only` (sparse far cluster), the tracker accumulates extent over several confirmed frames before promoting class confidence;
- when `yaw_confidence` is low or `corner_visibility = no_corner`, the tracker prefers its own velocity-derived heading prior over the per-frame `yaw` and gates yaw-rate updates more conservatively (this is what neutralizes `5_4.fm.l_pointing_wrong_way` at the tracking layer);
- when these fields are absent (a different §5.4 implementation that does not emit them), the tracker treats them as `unknown / unset` and falls back to its default policy.

> [!warning] Failure modes for §5.10 catalog
> | id | cause | observable_symptom | downstream_hazard | mitigation | validation_test |
> |---|---|---|---|---|---|
> | `5_5.fm.id_switch_under_occlusion` | Two actors overlap or one actor is briefly occluded; hard NN or poorly gated Hungarian association commits to the wrong detection after reappearance. | `track_id` swaps between nearby actors, often at crossings, merge zones, or beside large trucks. | Ch 7 fusion fuses the wrong histories; Ch 8 prediction inherits another actor's velocity and intent. | Use GNN with Mahalanobis / IoU gates, class and dimension consistency, coast through short misses, add JPDA or MHT for dense ambiguous scenes. | Replay crossing-pedestrian, adjacent-lane cut-in, and truck-occlusion bags; measure ID switches and post-occlusion velocity error. |
> | `5_5.fm.kf_diverges_on_turn` | CV-KF predicts straight motion while a vehicle follows a curved path; process noise is too low for the turn. | Correct detection falls outside the gate, track coasts, and a new track is born on the turning vehicle. | Planner sees a disappearing object plus a new object; prediction receives discontinuous velocity and identity. | Increase turn-aware process noise, use CTRV / CTRA for vehicle classes, or use IMM with CV and CTRV models. | Run intersection-left-turn and ramp-curve sequences; assert track continuity and bounded covariance through the turn. |
> | `5_5.fm.ghost_track_from_clutter` | Rain spray, reflections, split clusters, or one-frame shape-fit artifacts pass birth logic too easily. | Short-lived tracks appear near wheels, guardrails, wet roads, or sparse far returns. | False obstacles suppress free-space, trigger unnecessary braking, or pollute fusion with non-physical objects. | Require M-of-N confirmation, range-aware birth thresholds, minimum size / persistence checks, and class-consistent lifecycle tuning. | Replay wet-road, spray, and reflective-glass scenarios; measure false confirmed tracks, not just false tentative tracks. |
> | `5_5.fm.coasted_track_outlives_object` | Delete threshold `K` is too large or coast quality checks are missing after an object exits, turns behind a static occluder, or was a false birth. | Track remains published with growing covariance and no associated detections. | Prediction and planning reserve space for an object that no longer exists; fusion may preserve the ghost through stale priors. | Cap coast duration by speed, covariance, ROI, and last-seen quality; publish `coast` status distinctly from `confirm`; delete low-likelihood coasts. | Use object-exit, parked-car-pass-by, and occlusion-clear bags; assert stale-track lifetime stays below the §5.10 threshold. |

## Runtime-budget row

Per the [[5_9_deployment_runtime_EN|Ch 5 §5.9]] contract, the section contributes one row to the chapter-wide runtime table. Values below assume C++ implementation, CV-KF / optional IMM prediction, Hungarian GNN association, 3D / BEV IoU plus Mahalanobis gating, ~50 detections/frame, and ~30 active tracks.

| stage | compute | frame_rate_assumption | point_count_assumption | latency_p50_ms | latency_p99_ms | memory_mb | cadence | tf_freshness_assumption | assumptions_and_caveats |
|---|---|---|---:|---:|---:|---:|---|---|---|
| `5_5_classical_tracking` | cpu | 10 Hz LiDAR boxes | ~50 detections/frame, ~30 active tracks | ~1.5 | ~5.0 | ~16 | every-frame | ≤ 50 ms if projecting between `base_link` and `odom` | **Illustrative** budget for a C++ ROS2 Tracking-by-detection node using Kalman filter / IMM prediction, gated Hungarian GNN association, lifecycle management, and covariance publishing. Excludes §5.4 fitting and Ch 7 fusion. JPDA and MHT raise latency and memory because they maintain association hypotheses. |
