---
chapter: 5
section: 5
title: Multi-object tracking — Kalman / IMM / JPDA
language: EN
workflow_status: complete
tags:
  - book/section
  - book/chapter-5
  - lang/EN
---

# 5.5 Multi-object tracking — Kalman / IMM / JPDA

The Ch 5 classical pipeline is `preprocess → ground → cluster → fit → track`. Tracking is the temporal step: it turns per-frame fitted boxes from [[5_4_object_shape_fitting_EN|§5.4]] into object histories with identity, velocity, lifecycle status, and uncertainty. A detector answers "what boxes exist in this frame?" A tracker answers "which boxes belong to the same actor over time?"

The input contract has a fixed **binding tuple** plus required message metadata and optional side-channel diagnostics. §5.4 produces, per frame:

- **Binding tuple per detection** (the eight fields any §5.4 implementation must emit):

  ```text
  (x, y, z, l, w, h, yaw, optional class)
  ```

- **Required message metadata**: `header.stamp` (the §5.1 sweep-end deskew timestamp), `header.frame_id` (typically `base_link`).
- **Optional side-channel diagnostic fields** (not part of the binding tuple, may be absent): `extent_source`, `class_prior_source`, `yaw_confidence`, `corner_visibility` — see the *§5.4 side-channel integration* paragraph below for how this section consumes them when present and how it falls back when they are absent.

This section consumes those boxes, not raw clusters and not `PointCloud2`. The tracking output is published every frame as:

```text
(x, y, z, l, w, h, yaw, vel, optional class, track_id, age, status)
```

with a covariance estimate.

**The tracking state is maintained in `odom`, not `base_link`.** A track's velocity is the actor's velocity in the locally-consistent `odom` frame; `base_link` is the ego-vehicle's body frame, so a stationary actor in `base_link` carries the *negative* ego velocity, and a CV-KF in `base_link` would treat every parked car as moving backward at ego speed. Tracking in `odom` (per [[2_3_lidar_localization_EN|Ch 2 §2.3]]) handles ego-motion compensation through the `base_link → odom` transform applied at the measurement timestamp.

The timestamp contract: §5.4 boxes carry a `header.stamp` equal to the §5.1 sweep-end deskew time (the same convention `PointCloud2` uses, per [[5_8_ros2_integration_EN|§5.8]]). When a detection arrives, the tracker (1) advances each existing track's prediction to that `header.stamp` (computing `dt` from the previous track update), (2) looks up `T_odom_base_link(header.stamp)` from TF2 to transform the detection into `odom`, and (3) runs the Kalman update at that timestamp. Late or out-of-order detections (where `header.stamp < latest_track_time`) are either rejected, buffered for short-window reordering, or processed by an out-of-sequence-measurement (OOSM) update — the choice is policy. TF2 lookups beyond the buffer horizon, or when the `base_link → odom` chain is stale, must surface as a diagnostic; silently using the latest available transform is the same kind of bug as silently consuming stale `/tf` in §5.1 deskew.

Published tracks are emitted in `odom` with `header.frame_id = odom`; downstream consumers that need `base_link` (planner near-field, visualization) reproject using the same ego-pose lookup. `map` is used when global consistency over hours of operation is required (HD-map-relative consumers, longer-horizon prediction). The frame must be explicit on every message; `base_link`, `odom`, and `map` are not interchangeable labels, and a tracker that runs filter math in `base_link` without explicit ego-motion compensation is a known failure pattern, not a stylistic choice.

The prerequisites are small. A Kalman filter is a recursive estimator with a state, prediction model, measurement model, and covariance. Association assigns detections to existing tracks. The ego-state from Ch 2 provides ego-pose and ego-motion ([[2_1_ego_state_estimation_EN|Ch 2 §2.1]] / [[2_2_gnss_ins_imu_fusion_EN|Ch 2 §2.2]]) — its freshness and accuracy bound the tracker's correctness because every measurement transform from `base_link` to `odom` consumes a timestamped ego-pose lookup.

> [!info]
> Classical LiDAR tracking is Tracking-by-detection. The tracker does not rediscover objects from points. It consumes fitted 3D boxes and repairs the temporal defects left by clustering and shape fitting: missed boxes, yaw flips, split boxes, merged boxes, and identity ambiguity.

## CV-KF as the entry point

### Concept

The constant-velocity Kalman filter is the first tracker worth building because it makes the contract visible. It is not the most expressive motion model in this section, but it is the cleanest mathematical foundation: one state vector, one prediction model, one measurement model, one covariance, and one update per associated detection. If this version is wrong, CTRV, IMM, JPDA, and AB3DMOT will inherit the same frame and timestamp mistakes.

In bird's-eye view, the dynamic state can be

```text
x = [ px, py, vx, vy ]ᵀ
```

or, when vertical motion matters,

```text
x = [ px, py, pz, vx, vy, vz ]ᵀ
```

For most road actors, `z`, `l`, `w`, `h`, and `yaw` are measured fields carried alongside the dynamic state or lightly filtered with scalar filters. The hot path is BEV motion: `x`, `y`, velocity, covariance, and identity. The tracker may still publish `z`, dimensions, and yaw every frame, but the identity decision is usually dominated by the BEV center and its uncertainty.

### Mechanics

For a timestep `dt`, the CV prediction is:

```text
x_k|k-1 = F(dt) x_k-1|k-1
P_k|k-1 = F(dt) P_k-1|k-1 F(dt)ᵀ + Q(dt)

F(dt) = [ 1 0 dt 0
          0 1 0  dt
          0 0 1  0
          0 0 0  1  ]
```

`dt` is computed from timestamps, not from an assumed frame rate. A 10 Hz LiDAR normally yields `dt ≈ 0.1 s`, but dropped frames, delayed TF lookup, replay speed, and multi-sensor batching all break the "constant frame interval" shortcut. The filter should clamp or reject pathological `dt` values by policy: `dt <= 0` is an out-of-order measurement case, while a very large `dt` should usually force a coast-quality check before the prediction is allowed to gate new detections.

The process noise `Q(dt)` encodes unmodeled acceleration. A common CV model assumes white acceleration noise with standard deviation `σ_a`:

```text
Q(dt) = σ_a² [ dt⁴/4  0       dt³/2  0
               0       dt⁴/4  0       dt³/2
               dt³/2  0       dt²     0
               0       dt³/2  0       dt²    ]
```

Larger `σ_a` makes the gate follow maneuvers and sparse measurements more forgivingly; smaller `σ_a` makes the tracker hold straight motion tightly but increases `5_5.fm.kf_diverges_on_turn`. In a simple class-aware implementation, vehicles, cyclists, and pedestrians can use different `σ_a` values because their plausible acceleration envelopes differ. In an even simpler implementation, range and side-channel quality can inflate measurement noise instead of process noise, keeping the motion model stable while admitting that a far partial box is a poor observation.

The measurement from §5.4 is normally the box center, sometimes plus yaw and dimensions:

```text
z_k = [ x_box, y_box ]ᵀ
z_k = H x_k + v_k

H = [ 1 0 0 0
      0 1 0 0 ]
```

with `H` selecting position from the state. The measurement covariance `R` says how noisy the fitted box center is:

```text
R = [ σ_x²  0
      0     σ_y² ]
```

Near, dense, high-confidence L-shape boxes should have smaller `R`; sparse far boxes, partial-view boxes, low `yaw_confidence` boxes, and boxes whose `extent_source = visible_only` should have larger `R`. This is how the §5.4 side-channel contract enters the filter without changing the binding tuple. `R` is also the right place to express anisotropy: a broadside vehicle with a well-observed side but weak front corner may have tighter lateral center uncertainty than longitudinal center uncertainty in the box-local frame, then that covariance is rotated into `odom`.

The Kalman update uses the innovation `y`, innovation covariance `S`, Kalman gain `K`, and posterior covariance:

```text
y_k = z_k - H x_k|k-1
S_k = H P_k|k-1 Hᵀ + R_k
K_k = P_k|k-1 Hᵀ S_k⁻¹
x_k|k = x_k|k-1 + K_k y_k
P_k|k = (I - K_k H) P_k|k-1
```

Production code often uses the Joseph covariance form,

```text
P_k|k = (I - K H) P (I - K H)ᵀ + K R Kᵀ
```

because it is more numerically stable when roundoff would otherwise make `P` slightly asymmetric or non-positive. The invariant is operational, not cosmetic: `P` must stay symmetric positive semidefinite because gating and uncertainty publication both consume it.

Gating is based on the normalized innovation squared:

```text
d² = yᵀ S⁻¹ y
```

For a 2-D position measurement, `d²` is compared with a chi-square threshold for two degrees of freedom. The exact threshold is a tuning choice; the important point is that the test is covariance-aware. A track that has coasted for two frames has a larger `P`, therefore a larger `S`, therefore a wider physically honest gate. A fresh track with small covariance should not be allowed to jump across a lane simply because the Euclidean center distance is under a fixed radius.

### Worked Example

Take one BEV track with

```text
x_0 = [10.0, 2.0, 5.0, 0.0]ᵀ
P_0 = diag(0.25, 0.25, 1.00, 1.00)
σ_a = 2.0 m/s²
R = diag(0.16, 0.16)
dt = 0.1 s
```

At frame 1, prediction gives `px = 10.5`, `py = 2.0`; the velocity stays `(5.0, 0.0)`. The process noise terms are small over 0.1 s (`dt⁴/4 * σ_a² = 0.0001`, `dt³/2 * σ_a² = 0.002`, `dt² * σ_a² = 0.04`), but they still grow the velocity covariance. Suppose the associated measurement is `z_1 = [10.6, 2.1]ᵀ`. The innovation is `[0.1, 0.1]ᵀ`; with predicted position variance around `0.26`, `S` is about `diag(0.42, 0.42)`, so the position gain is about `0.62`. The update moves the center to roughly `[10.56, 2.06]ᵀ` and nudges velocity upward because position and velocity became correlated during prediction.

At frame 2, the updated track predicts to about `[11.08, 2.09]ᵀ`. If `z_2 = [11.05, 2.00]ᵀ`, the innovation is small and the posterior tightens. At frame 3, suppose a sparse partial box arrives at `[11.70, 2.40]ᵀ` with low side-channel confidence, so `R` is inflated to `diag(0.64, 0.64)`. The same geometric offset now produces a smaller gain: the track moves toward the detection, but does not let a weak partial-view measurement fully rewrite velocity. If the NIS `d²` exceeds the gate, the update is skipped and the track coasts instead.

This three-frame example is the whole tracker in miniature. Prediction transports the state to the detection timestamp; `Q` grows uncertainty for unmodeled acceleration; `R` decides how much to trust the box; `K` balances prediction and measurement; `P` tightens on good observations and widens during coast.

### Usage

Start with CV-KF in `odom` (per the frame discussion above), Mahalanobis gating, and Hungarian association before adding model complexity. Use one track object per active actor, store the last filter timestamp per track, and make every prediction call accept an explicit `target_stamp`. Initialize a new track from an unmatched detection with position from the transformed box center, velocity either zero or inherited from a short two-hit estimate, and a large velocity covariance so the second and third frames can learn velocity quickly.

Shape fields need separate discipline. A track can keep dimensions as an exponential moving average, a scalar Kalman filter per dimension, or a class-prior-backed state. Yaw should be updated only when the detection yaw is trustworthy; otherwise velocity-derived heading or the previous filtered yaw is often safer. This is the tracking-layer counterpart to §5.4's `yaw_confidence` and `corner_visibility` diagnostics.

### Failure Modes

CV-KF fails predictably. If process noise is too small, the gate misses turning vehicles and `5_5.fm.kf_diverges_on_turn` appears. If process noise is too large, the tracker accepts implausible jumps and identity switches increase. If measurement noise is too small for partial boxes, the filter chases centroid jitter; if too large for near clean boxes, it lags real motion. If `dt` is computed from wall-clock arrival rather than message stamps, replay and bursty middleware turn into false acceleration. If filter math runs in `base_link`, ego motion is misread as actor motion, which violates the section's frame contract.

> [!tip]
> Start with CV-KF in `odom` (per the frame discussion above), Mahalanobis gating, and Hungarian association before adding model complexity. Most tracking bugs are frame, timestamp, association, or lifecycle bugs, not filter-equation bugs.

## CTRV and CTRA

### Concept

CV breaks when motion is not approximately straight over the association horizon. A vehicle entering an intersection, a cyclist turning across the ego lane, or a car following a curved ramp may have a center trajectory that no constant `vx, vy` model can predict. The observable symptom is a tracker that lags the turn, rejects the correct detection, and spawns a new track.

### Mechanics

CTRV, the constant turn-rate and velocity model, changes the state to match the vehicle-like geometry:

```text
x = [ px, py, v, yaw, yaw_rate ]ᵀ
```

Instead of independent `vx` and `vy`, the model predicts the center by integrating speed along heading while yaw changes at `yaw_rate`. CTRA adds longitudinal acceleration:

```text
x = [ px, py, v, a, yaw, yaw_rate ]ᵀ
```

These models are nonlinear, so implementations usually use an extended Kalman filter or unscented Kalman filter. The measurement still comes from the same §5.4 box tuple `(x, y, z, l, w, h, yaw, optional class)`. The difference is the state transition, not the detector interface.

For nonzero `yaw_rate`, CTRV integrates an arc instead of a straight line. In simplified form:

```text
px'  = px + v / yaw_rate * (sin(yaw + yaw_rate * dt) - sin(yaw))
py'  = py + v / yaw_rate * (-cos(yaw + yaw_rate * dt) + cos(yaw))
yaw' = yaw + yaw_rate * dt
```

When `yaw_rate` approaches zero, the implementation uses the straight-line limit:

```text
px' = px + v * cos(yaw) * dt
py' = py + v * sin(yaw) * dt
```

This branch is not optional. Dividing by a tiny yaw rate produces numerical spikes exactly when the actor is driving straight, which is the common case. CTRA adds acceleration by integrating `v` over the step; the same small-yaw-rate limit still applies.

### Usage

Use CTRV / CTRA when the tracker repeatedly loses turning vehicles under CV despite reasonable `Q`, `R`, and gating. They are most useful for vehicles and bicycles whose heading is meaningful and whose center motion follows a heading-constrained body. They are less attractive for short-lived tentative tracks because yaw-rate and acceleration states are poorly observed before the track has several good measurements.

### Failure Modes

CTRV / CTRA are natural for vehicles but awkward for pedestrians. A pedestrian can stop, sidestep, turn in place, and violate the minimum-turning-radius intuition that makes CTRV useful. A tracker that applies one motion model to every actor will either overfit vehicles or underfit pedestrians.

## IMM

### Concept

IMM, the Interacting Multiple Model filter, is the classical answer when one motion model is too brittle. It runs several filters in parallel, mixes their states through a transition-probability matrix, updates each model with the same measurement, and weights the models by measurement likelihood. The output is a weighted state and covariance.

### Mechanics

A practical LiDAR tracker might use:

| model | actor behavior it covers |
|---|---|
| stationary / low-speed CV | parked vehicles, stopped traffic, standing pedestrians |
| CV | straight cruise and most short-horizon road motion |
| CTRV | turning vehicles and curved-lane motion |
| CTRA | braking, accelerating, and ramp entries |

The IMM cycle has four steps. First, mode probabilities from the previous frame are mixed through a transition matrix, for example "stationary usually stays stationary, CV usually stays CV, but CV has some probability of switching to CTRV." Second, each model receives a mixed initial state and covariance. Third, each filter predicts and updates with the same detection. Fourth, the measurement likelihood from each model reweights the mode probabilities, and the tracker publishes the weighted mean and covariance. The implementation detail readers should watch for is covariance mixing: averaging state vectors alone underestimates uncertainty because disagreement between models is itself uncertainty.

### Usage

IMM is useful when class-specific single models are not enough but JPDA / MHT-level association complexity is not justified. A road vehicle can be stationary at a light, accelerate straight, and then turn; IMM lets one `track_id` move between those regimes without a hand-authored switch statement. It also gives the lifecycle code a softer signal: if all models assign low likelihood to the associated detection, the problem may be association, not just motion-model mismatch.

### Failure Modes

IMM cannot recover from bad detections or impossible association. Its value is that covariance and prediction shape follow observed dynamics. A track can behave like stationary clutter, cruise straight, and then shift weight toward CTRV as the vehicle turns without changing `track_id`.

## Association

### Concept

Association is the other half of tracking. Prediction says where each existing track should be. Association decides which detection, if any, belongs to each track. The cost can be 3D IoU, BEV IoU, center distance, Mahalanobis distance, yaw difference, class mismatch penalty, or a weighted combination. Gating removes impossible pairs before optimization.

Nearest-Neighbor (NN) is the simplest rule: for each track, take the closest gated detection. It works in sparse scenes where boxes are well separated. It breaks under crossing actors because local choices steal detections from each other. Two pedestrians passing at close range, or two cars in adjacent lanes during a lane change, are enough to create an identity switch.

### Mechanics: Hungarian GNN

Global Nearest Neighbor (GNN) solves one assignment for the whole frame. In production classical trackers, GNN usually means a cost matrix plus the Hungarian algorithm — and because GNN+Hungarian is the production default, it deserves more depth than a one-paragraph mention. The cost matrix has one row per existing track and one column per current-frame detection; the cell `C[i, j]` is the assignment cost (e.g. Mahalanobis distance from the track's predicted measurement mean to detection `j`, or `1 − BEV_IoU(track_i, det_j)`, or a weighted sum).

Pairs that fail a **gating test** — typically a Mahalanobis distance threshold derived from the predicted measurement covariance, with a class / dimension consistency check stacked on top — are **ineligible**, and the implementation must encode them so the optimizer can never select them. Two patterns work: (a) restructure the assignment as a constrained problem and exclude gated-out pairs from the cost matrix entirely; or (b) fill gated-out cells with a sentinel cost that is **strictly larger than any unmatched-dummy cost**, and discard any sentinel-matched pair as "unmatched" in post-processing. Pattern (b) is common because it keeps the matrix rectangular for vanilla Hungarian, but it relies on the post-filter — a sentinel value alone is not a guarantee. Gating is *not* the same as cost weighting: gating decides which pairs are *eligible*, while cost decides which *eligible* pair is preferred. Mahalanobis gating is preferred over a fixed metric distance because the predicted measurement covariance grows during coast (no detection associated → wider gate next frame), so the gate widens *honestly* in proportion to track uncertainty.

Hungarian also requires a square cost matrix; rectangular cases are handled by padding with **dummy rows or columns at a fixed unmatched cost** — the cost the assignment is "willing to pay" to leave a track or detection unmatched. The unmatched cost should be set strictly *less than* any gated-out sentinel so the optimizer prefers leaving things unmatched over forcing an infeasible match. The output is a one-to-one assignment plus the unmatched tracks (which then enter coast) and unmatched detections (which seed births). The implementation is `O(n³)` worst-case in `n = max(#tracks, #detections)`; fast enough for dozens of objects, deterministic, and easy to diagnose by inspecting the gated cost matrix.

> [!example] Hungarian gating artifact
> Three predicted tracks `T1..T3` and two detections `D1..D2` produce a rectangular cost matrix. Use `9` as the unmatched-dummy cost and `999` as the gated-out sentinel. After padding one dummy detection column, the square matrix is:
>
> ```text
>              D1    D2   dummy
> T1          0.7   6.0     9
> T2          4.5   0.8     9
> T3          999   999     9
> ```
>
> Hungarian chooses `(T1,D1)`, `(T2,D2)`, and `(T3,dummy)`. `T3` coasts. If `T3,D1` had cost `8` instead of sentinel `999`, the optimizer might force an implausible match to avoid the dummy cost; that would be a gating bug, not a Hungarian bug. If the optimizer ever returns a sentinel pair, post-processing discards it and treats both sides as unmatched.

### Mechanics: JPDA and MHT

JPDA, Joint Probabilistic Data Association, keeps multiple plausible associations instead of committing to one hard pair. Each track update is a probability-weighted mixture over gated detections, with clutter and missed-detection hypotheses included. JPDA is useful in dense scenes where two or three detections are genuinely ambiguous for several frames. The tradeoff is that identities can become smeared if the scene remains ambiguous and the implementation does not manage covariance inflation carefully.

MHT, Multiple Hypothesis Tracking, pushes the idea further. It maintains a tree of association hypotheses across frames, prunes low-probability branches, and delays commitment until later evidence resolves ambiguity. MHT is principled and expensive. It earns its keep in hard occlusion and crossing scenarios, but the branch management, pruning policy, and latency budget are more complex than Hungarian GNN. For the Ch 5 pilot, MHT belongs in the "understand the upgrade path" bucket, not the first deployable implementation.

### Usage

Use Hungarian GNN as the first full association implementation. It is deterministic, debuggable, and composes directly with CV-KF, CTRV, IMM, and AB3DMOT. Use JPDA when the same small group of detections remains ambiguous for several frames and a hard one-frame commitment causes ID switches. Use MHT when delayed commitment is worth the extra memory, latency, and branch-pruning complexity.

### Failure Modes

Association failure usually appears as `5_5.fm.id_switch_under_occlusion`, but the root cause can be different in each implementation. NN fails by local greediness. Hungarian fails when costs or gates are wrong, or when a one-to-one assignment is too brittle for the scene. JPDA fails by smearing identities through long ambiguity. MHT fails by pruning the correct branch or by exceeding the latency budget.

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

### Concept

AB3DMOT (Weng et al., IROS 2020) is the canonical published LiDAR 3D MOT baseline used as a reference end-to-end pipeline in academic and open-source contexts. Its strength is restraint: take 3D detections, run a Kalman filter per object, associate detections and tracks with Hungarian, and gate with simple 3D IoU or distance-style costs. It is fast and competitive because Tracking-by-detection depends heavily on stable detections, reasonable motion prediction, and conservative identity management — *not* on a clever filter equation.

AB3DMOT is also a useful teaching boundary. It assumes the detector already emits boxes. It does not solve LiDAR shape fitting, semantic classification, re-identification, or prediction. A long occlusion or a clean crossing with similar boxes can still produce an identity switch.

AB3DMOT remains a baseline because it exposes the minimum working skeleton: state, covariance, gating, Hungarian association, lifecycle, and metrics.

### Mechanics

The default state for this section is the 10D AB3DMOT-style state:

```text
x = (x, y, z, yaw, l, w, h, vx, vy, vz)
```

The CV-KF foundation above explains the dynamic part. AB3DMOT applies that filtering discipline to complete 3D boxes: predict each track to the current timestamp, form a predicted 3D box, compute association costs between predicted boxes and detections, run Hungarian, update matched tracks, coast unmatched tracks, and birth unmatched detections. Implementations vary in whether dimensions are part of the Kalman state or are smoothed separately; the operational contract is the same: every track publishes center, dimensions, yaw, velocity, identity, lifecycle, and covariance.

3D IoU is the common AB3DMOT association gate because it compares the full box geometry instead of only center distance. A predicted car-sized box and a detection with high 3D IoU are likely the same actor even if the center shifted slightly; a pedestrian-sized detection inside a vehicle gate should fail dimension and class consistency even if its center is close. BEV IoU is sometimes used when vertical extent is noisy; Mahalanobis distance is useful when covariance quality is strong. The key is to keep the cost and gate consistent with the uncertainty model: a coasted track may need a wider center gate, but it should not ignore impossible shape or class conflicts.

> [!example] AB3DMOT pipeline artifact
> ```text
> §5.4 boxes in base_link at header.stamp
>        |
>        v
> transform boxes to odom using T_odom_base_link(header.stamp)
>        |
>        v
> Kalman predict all tracks to header.stamp
>        |
>        v
> build 3D-IoU / Mahalanobis gated cost matrix
>        |
>        v
> Hungarian assignment
>        |
>        +--> matched: Kalman update + shape/yaw smoothing
>        +--> unmatched tracks: coast + covariance growth
>        +--> unmatched detections: birth tentative tracks
>        |
>        v
> lifecycle policy -> publish active tracks / tombstones
> ```

### Worked Example

Frame `k=0` has two detections after §5.4 and the `base_link → odom` transform:

```text
D_A0 = car at (10.0, 1.0, 0.0), size (4.4, 1.8, 1.6), yaw 0.00
D_B0 = car at (18.0, 3.5, 0.0), size (4.5, 1.9, 1.6), yaw 0.05
```

There are no existing tracks, so AB3DMOT births two tentative tracks: `T17` from `D_A0` and `T18` from `D_B0`. Both start with low or unknown velocity and large velocity covariance.

At frame `k=1`, `dt = 0.1 s`. The tracks predict forward. Because they are tentative and velocity is weakly known, the predicted boxes remain near their previous centers with widened covariance. The detector emits:

```text
D_A1 = (10.6, 1.0, 0.0), yaw 0.01
D_B1 = (18.0, 4.0, 0.0), yaw 0.08
```

The gated cost matrix using `1 - 3D_IoU` looks like:

```text
             D_A1   D_B1
T17          0.18   999
T18          999    0.22
```

Hungarian returns `(T17,D_A1)` and `(T18,D_B1)`. Both tracks update. Their velocity estimates now point roughly from frame 0 to frame 1: `T17` is moving forward along `x`; `T18` is moving laterally in `y`.

At frame `k=2`, `T17` predicts to about `(11.2, 1.0)`. `T18` predicts to about `(18.0, 4.5)`. The detector emits `D_A2 = (11.1, 1.0)` but misses actor B behind a partial occluder. The assignment matrix has one real detection plus a dummy column:

```text
             D_A2   dummy
T17          0.20     9
T18          999      9
```

AB3DMOT updates `T17`, coasts `T18`, grows `T18`'s covariance, and keeps `T18` alive if the coast budget has not expired. If frame `k=3` later contains a box near `(18.0, 5.0)`, the wider coasted gate allows reassociation; if the box never returns or quality falls below the lifecycle threshold, `T18` is deleted and may emit a tombstone.

### Usage

Use AB3DMOT as the synthesis reference after the CV-KF and Hungarian pieces work independently. It is especially useful as a regression baseline: if a learned temporal tracker beats AB3DMOT only on aggregate accuracy but produces worse ID switches, worse coast behavior, or less interpretable covariance, the gain may not be deployable. AB3DMOT also gives Ch 7 and Ch 8 a stable interface: boxes become tracks with velocity, identity, status, and uncertainty.

Tracking is one of the load-bearing classical pieces that **survives inside DL-primary stacks**. The detection layer in production L4 robotaxi and many disclosed or inferred consumer NOA stacks is commonly learned (PointPillars / SECOND / CenterPoint and successors — see Ch 6), and the temporal layer over those detections is commonly a Kalman / Hungarian / lifecycle pipeline of the kind this section teaches, with learned ID-embeddings or appearance cues as optional add-ons. Learned alternatives also ship: transformer-based MOT heads can learn association, learned motion forecasting can subsume the tracker's prediction step, and BEV-temporal-fusion architectures such as BEVFormer and BEVDet can push temporal consistency into the detector head rather than a separate tracker. The bounded claim is not that classical tracking is universal; it is that Kalman + Hungarian remains one common, interpretable integration pattern whose failure modes are easy to diagnose and whose output composes with downstream prediction (Ch 8) and fusion (Ch 7). [[5_9_deployment_runtime_EN|§5.9]] picks up this argument with explicit ODD bounds and stronger evidence for the consumer-NOA case.

### Failure Modes

AB3DMOT inherits the failures of every piece it composes. Bad §5.4 boxes produce bad measurements. Weak gates produce ID switches. A too-short coast budget deletes temporarily occluded actors; a too-long coast budget creates `5_5.fm.coasted_track_outlives_object`. 3D IoU can fail under yaw flips or poor dimension estimates because two boxes for the same actor may overlap weakly when yaw is wrong. Pure geometry also has no appearance memory, so two similar vehicles crossing under occlusion can still swap identities.

## Track lifecycle

### Concept

A tracker needs a lifecycle because detections are noisy. A single fitted box should not instantly become a planning-grade object, and one missed frame should not instantly delete a real actor.

### Mechanics

Birth starts from an unmatched detection. Many systems use M-of-N confirmation: a tentative track becomes confirmed only if it receives at least `M` associated detections in the last `N` frames. The output `status` is `birth` until the track is trusted.

Confirm means the track is stable enough to publish as a normal object. Confirmed tracks carry `track_id`, `age`, velocity, covariance, and filtered shape fields. Ch 7 fusion can merge them with camera or radar tracks; Ch 8 prediction can use their velocity history.

Coast means predict-only. No detection was associated this frame, but the track is still plausible. Coasting is what prevents a one-frame missed box from creating a disappearing-and-reappearing object. The covariance grows during coast, and the published status is `coast` so downstream consumers know the track is not freshly observed.

Delete means the track is removed after `K` consecutive misses, after its covariance grows past a quality threshold, after it exits the region of interest, or after its likelihood falls below a lifecycle threshold. Deletion policy is safety-relevant: delete too quickly and real occluded actors vanish; delete too slowly and ghost tracks outlive objects.

> [!example] Track lifecycle state machine
> ```text
> unmatched detection
>        |
>        v
>    [birth]
>        |
>        v
> [tentative] -- miss / fails M-of-N --> [deleted]
>        |
>        | M hits in last N frames
>        v
> [confirmed] -- matched --> [confirmed]
>        |
>        | miss
>        v
>   [coast] -- matched within K frames --> [confirmed]
>        |
>        | K misses, covariance too large, ROI exit, or low likelihood
>        v
>   [deleted] -- optional one-frame tombstone --> gone
> ```
>
> The lifecycle thresholds are policy, but the states are not just labels. They control publication, covariance growth, association gates, and whether Ch 7 / Ch 8 should treat the track as freshly observed or predicted-only.

### Usage

Tune lifecycle separately for tentative and confirmed tracks. Tentative tracks should require evidence before publication so rain spray, reflections, and split clusters do not become planning objects. Confirmed tracks should survive short misses because §5.4 boxes can disappear behind occluders or sparse returns. Coasted tracks should remain clearly marked as `coast`, and their covariance should grow with every prediction-only step.

### Failure Modes

Lifecycle must connect directly to §5.4 failure modes. Yaw flips should not create new identities if center and dimensions remain consistent. Missed boxes from sparse far clusters should trigger coast, not immediate delete. Split boxes should either associate to the strongest existing track or be suppressed by shape and IoU gates.

## Camera tracker handoff

[[4_6_camera_tracking_EN|Ch 4 §4.6]] covers ByteTrack, OC-SORT, and BoT-SORT on the camera side. The conceptual machinery — prediction, association, lifecycle, identity management — migrates. The **signal sources do not.** Camera trackers exploit per-detection score distributions (ByteTrack's two-stage low/high-score association) and appearance embeddings (BoT-SORT's re-ID head, OC-SORT's observation-centric updates) to disambiguate identity through occlusion. Classical §5.4 LiDAR boxes have no learned semantic confidence and no appearance signal; they have geometry, covariance, and the side-channel diagnostics. So the LiDAR equivalent of "lower the score threshold and re-associate" is "widen the Mahalanobis gate using the coasted covariance and re-attempt assignment with shape-consistency stacked into the cost." The lifecycle decision is the same; the evidence the tracker reasons about is different.

This distinction matters for [[7_0_overview_EN|Ch 7]] fusion. Fusion receives tracks that already have metric position and covariance, not image-plane rectangles. It also matters for [[8_0_overview_EN|Ch 8]] prediction: prediction should see stable identity and velocity, but it should not inherit unmarked coasted states as if they were fresh observations.

## Output contract

§5.5 publishes a track-array message per frame. Each entry has **required message metadata** plus the per-track tuple:

- **Metadata** (per-message): `header.stamp` = the perception timestamp the tracks are valid at (the `header.stamp` of the latest §5.4 box batch); `header.frame_id = odom`; per-track `track_state_time` field equal to the time the track's filter state was last updated (usually equals `header.stamp` for actively-associated tracks; lags for coasted ones — the difference is the track's *coast age*).
- **Per-track tuple** (the binding payload):

  ```text
  (x, y, z, l, w, h, yaw, vel, optional class, track_id, age, status)
  ```

  with `vel` = `(vx, vy)` for BEV consumers or `(vx, vy, vz)` when vertical velocity is estimated, and `status ∈ {birth, confirm, coast}` for **active** tracks.
- **Tombstone** (optional, separately published): `status = delete` is emitted as a final per-track tombstone message **for one frame after deletion**, then the track id never reappears. Tombstones are not active tracks and may travel on a separate topic in some stacks; consumers that only care about active tracks can subscribe to the active stream and ignore tombstones.

The uncertainty estimate is typically the Kalman covariance over dynamic state, attached as a per-track field. Treating "active tracks" and "tombstones" as one bucket (the round-1 framing) blurs the contract; treating them separately makes the lifecycle explicit on the wire.

Frame policy for this chapter: the tracker maintains and publishes primary tracks in `odom` (per the section opening). Diagnostics monitor ego-pose freshness — staleness in the `base_link → odom` transform shows up as a tracking failure, not a §5.1 or §5.8 failure, because every measurement transform consumes that lookup. Downstream `base_link` consumers (planner near-field, visualization) reproject from `odom`. [[5_6_registration_EN|§5.6]] is relevant when localization is degraded enough that the `odom → map` connection or even the `base_link → odom` consistency must be refreshed by registration.

Per the [[5_4_object_shape_fitting_EN|§5.4]] output contract, fitted boxes carry side-channel diagnostic fields alongside the binding tuple: `extent_source ∈ {visible_only, class_prior_backfill}`, `class_prior_source ∈ {none, dimension_lookup, upstream_class, tracker_history}`, `yaw_confidence ∈ [0, 1]`, and `corner_visibility ∈ {two_corners, one_corner, no_corner}`. These fields adjust §5.5 measurement noise, yaw update eligibility, and shape-state confirmation — they do not add a "class confidence" the binding tuple does not have:

- when `extent_source = visible_only`, the tracker inflates the measurement noise on `(l, w, h)` and treats the extent as a low-confidence observation; it does **not** publish a class-confidence score (§5.4's binding tuple has `optional class`, no confidence).
- when `class_prior_source = dimension_lookup` (the prior was a gross-dimension guess), the tracker keeps `optional class` from the latest detection but downweights any consistency-with-class lifecycle gates accordingly.
- when `yaw_confidence` is low or `corner_visibility = no_corner`, the tracker prefers its own velocity-derived heading prior over the per-frame `yaw` and gates yaw-rate updates more conservatively (this is what neutralizes `5_4.fm.l_pointing_wrong_way` at the tracking layer).
- the tracker maintains a separate **shape state** per track in the track's local box frame (centered on `track_id`, oriented by the filtered yaw); shape accumulation across frames happens in that local frame only when both `yaw_confidence` is high and the detection is associated, so partial-view centroid shifts cannot masquerade as object growth.
- when these side-channel fields are absent (a different §5.4 implementation that does not emit them), the tracker treats them as `unknown / unset` and falls back to its default policy.

> [!warning] Failure modes for §5.10 catalog
> | id | cause | observable_symptom | downstream_hazard | mitigation | validation_test |
> |---|---|---|---|---|---|
> | `5_5.fm.id_switch_under_occlusion` | Two actors overlap or one actor is briefly occluded; hard NN or poorly gated Hungarian association commits to the wrong detection after reappearance. | `track_id` swaps between nearby actors, often at crossings, merge zones, or beside large trucks. | Ch 7 fusion fuses the wrong histories; Ch 8 prediction inherits another actor's velocity and intent. | Use GNN with Mahalanobis / IoU gates, class and dimension consistency, coast through short misses, add JPDA or MHT for dense ambiguous scenes. | Replay crossing-pedestrian, adjacent-lane cut-in, and truck-occlusion bags; measure ID switches and post-occlusion velocity error. |
> | `5_5.fm.kf_diverges_on_turn` | CV-KF predicts straight motion while a vehicle follows a curved path; process noise is too low for the turn. | Correct detection falls outside the gate, track coasts, and a new track is born on the turning vehicle. | Planner sees a disappearing object plus a new object; prediction receives discontinuous velocity and identity. | Increase turn-aware process noise, use CTRV / CTRA for vehicle classes, or use IMM with CV and CTRV models. | Run intersection-left-turn and ramp-curve sequences; assert track continuity and bounded covariance through the turn. |
> | `5_5.fm.ghost_track_from_clutter` | Rain spray, reflections, split clusters, or one-frame shape-fit artifacts pass birth logic too easily. | Short-lived tracks appear near wheels, guardrails, wet roads, or sparse far returns. | False obstacles suppress free-space, trigger unnecessary braking, or pollute fusion with non-physical objects. | Require M-of-N confirmation, range-aware birth thresholds, minimum size / persistence checks, and class-consistent lifecycle tuning. | Replay wet-road, spray, and reflective-glass scenarios; measure false confirmed tracks, not just false tentative tracks. |
> | `5_5.fm.coasted_track_outlives_object` | Delete threshold `K` is too large or coast quality checks are missing after an object exits, turns behind a static occluder, or was a false birth. | Track remains published with growing covariance and no associated detections. | Prediction and planning reserve space for an object that no longer exists; fusion may preserve the ghost through stale priors. | Cap coast duration by speed, covariance, ROI, and last-seen quality; publish `coast` status distinctly from `confirm`; delete low-likelihood coasts. | Use object-exit, parked-car-pass-by, and occlusion-clear bags; assert stale-track lifetime stays below the §5.10 threshold. |

## Runtime-budget row

Per the [[5_9_deployment_runtime_EN|§5.9]] contract, the section contributes one row to the chapter-wide runtime table. Values below assume C++ implementation, CV-KF / optional IMM prediction, Hungarian GNN association, 3D / BEV IoU plus Mahalanobis gating, ~50 detections/frame, and ~30 active tracks.

| stage | compute | frame_rate_assumption | point_count_assumption | latency_p50_ms | latency_p99_ms | memory_mb | cadence | tf_freshness_assumption | assumptions_and_caveats |
|---|---|---|---:|---:|---:|---:|---|---|---|
| `5_5_classical_tracking` | cpu | 10 Hz LiDAR boxes | ~50 detections/frame, ~30 active tracks | ~1.5 | ~5.0 | ~16 | every-frame | ≤ 50 ms for the `base_link → odom` lookup applied to every detection | **Illustrative** budget for a C++ ROS2 Tracking-by-detection node tracking in `odom` per the section's frame policy: Kalman filter / IMM prediction, gated Hungarian GNN association, lifecycle management, and covariance publishing. Every measurement consumes one TF2 timestamped lookup to transform from `base_link` to `odom`, so `/tf` and `/tf_static` freshness is mandatory, not optional. Excludes §5.4 fitting and Ch 7 fusion. JPDA and MHT raise latency and memory because they maintain association hypotheses. |
