---
chapter: 5
section: 8
title: ROS2 integration
language: EN
workflow_status: reviewing
tags:
  - book/section
  - book/chapter-5
  - lang/EN
---

# 5.8 ROS2 integration

The Ch 5 pipeline lives inside ROS2 / Humble: raw LiDAR packets become `sensor_msgs/PointCloud2`, pass through `preprocess → ground → cluster → fit → track`, and leave the chapter as boxes, tracks, occupancy, and diagnostics. This section is not a ROS2 tutorial; [[1_5_ros2_humble_essentials_EN|Ch 1 §1.5]] owns publishers, subscribers, executors, and basic TF2 usage. Here the concern is narrower: the LiDAR-perception integration patterns that keep the classical pipeline correct under timing, frame, lifecycle, and replay constraints.

[[1_1_coordinate_frames_EN|Ch 1 §1.1]] covered coordinate frames and TF2 mathematical conventions; [[1_5_ros2_humble_essentials_EN|Ch 1 §1.5]] introduced publishers, subscribers, lifecycle nodes, and TF2 broadcast; [[1_4_sensor_time_sync_EN|Ch 1 §1.4]] covered sensor timing, per-point timestamps, and clock discipline. Localization frame conventions -- what `odom` and `map` mean and when they exist -- come from [[2_3_lidar_localization_EN|Ch 2 §2.3]] and [[2_5_map_relative_localization_EN|Ch 2 §2.5]]. This section restates only the pieces needed to make Ch 5 perception nodes behave like deployable C++ ROS2 components rather than offline scripts.

The section is a wiring section, not a fifth algorithm section. Each topic follows the same small pattern: concept, mechanics, and the failure mode that belongs in [[5_10_safety_and_validation_EN|§5.10]]. The anchor is the combined `PointCloud2` and TF2 contract because every later classical step inherits it. If the cloud schema, timestamp convention, or frame lookup is ambiguous, RANSAC, Patchwork++, Euclidean clustering, L-shape fitting, Kalman tracking, occupancy, and map ROI gating all debug the wrong symptom.

## PointCloud2 message conventions

Concept. The first production boundary is the full ROS msg name `sensor_msgs/PointCloud2`; in C++ the type is `sensor_msgs::msg::PointCloud2`. A Ch 5 LiDAR cloud normally carries fields named `x`, `y`, `z`, `intensity`, `ring`, and `time`. The first three are geometric coordinates in the message `frame_id`; `intensity` is useful for filters and diagnostics but is not a stable material classifier; `ring` identifies the laser channel; `time` stores the point's relative firing time inside the scan. That per-point `time` field lets §5.1 deskew a cloud using ego-pose or IMU integration instead of treating the whole scan as instantaneous.

Mechanics. `header.stamp` names the time of the cloud as a message-level object. **Ch 5 commits to a concrete convention so downstream sections can reference §5.8 as a stable interface:** `header.stamp` is the **end-of-scan reference time** (the timestamp of the last firing in the sweep), and the per-point `time` field is a **non-negative `Δt` relative to `header.stamp`**, in seconds -- i.e. each point's absolute time is `header.stamp − time`. §5.1 deskew, §5.2 ground segmentation, §5.3 range-image clustering, rosbag replay tooling, and §5.10 validation all use this convention. A point with `time = 0.000` is at the sweep end. A point with `time = 0.080` in a 10 Hz scan was fired 80 ms before the sweep-end stamp. Drivers that publish `time` relative to start-of-scan, store absolute GPS time, or omit the field must be normalized at the message boundary, not silently consumed.

The `frame_id` starts as the `lidar` frame, not `base_link`, because the cloud is measured in the sensor frame before extrinsics are applied. §5.1 publishes a deskewed, de-noised, voxel-downsampled `PointCloud2` in `base_link` at the same sweep-end `header.stamp`; §5.2 and §5.3 normally consume that `base_link` cloud. Registration and ROI branches may transform into `odom` or `map`, but they should say so in the topic name, message frame, and diagnostics. Silent frame changes create bugs that look like sloped-road errors, split clusters, yaw flips, or map-gating misses.

`PointCloud2` is a packed binary layout, so field names alone are not enough. At startup, validate unsupported layouts before the first frame reaches the hot path: `is_bigendian`, `point_step`, field offsets, and datatype. A Ch 5 component should accept only the layouts it was written to decode, usually little-endian `FLOAT32` `x/y/z/intensity`, integer or `UINT16` `ring` by explicit policy, and `FLOAT32` or `FLOAT64` `time` by explicit policy. Padding bytes are legal, but the offsets must match the declared `point_step`. Consumers should use `sensor_msgs::PointCloud2Iterator` or a small validated decoder; they should not reinterpret `data` as a local struct unless the exact ABI layout is checked. The strict-rejection-of-unsupported-PointCloud2-layouts policy is deliberately conservative: a wrong `time` offset by four bytes can bend walls and smear cars while RViz still shows a plausible raw cloud. That is the catalog row `5_8.fm.pointcloud2_offset_drift`.

QoS is part of the same message contract. Live LiDAR clouds should normally use `rclcpp::SensorDataQoS()`: keep-last history, small depth, best-effort reliability, and volatile durability. The intent is to process the newest sensor data at sensor cadence, not to force the middleware to deliver every old cloud after the pipeline is late. Recorded data is different. A bag made from a reliable publisher and replayed into a best-effort subscription may work; the reverse may not preserve the drop behavior validation expects. rosbag QoS override files should be checked into the replay harness for the cloud topic, `/tf`, and `/tf_static` instead of relying on automatic adaptation. History depth affects both live and replay behavior: depth `1` keeps latency bounded but drops during bursts; a deeper queue can survive short compute spikes but can also feed stale clouds into tracking and occupancy. The table later in this section makes those assumptions visible per stage.

Failure mode. The symptom is rarely "ROS message layout failed." It is curved poles after deskew, `NaN` clusters after field misdecode, far objects disappearing because a queue dropped old frames, or a tracker coasting through a real actor because the cluster node processed every third cloud. The mitigation is to make schema, frame, timestamp, and QoS validation an activation gate, not an after-the-fact warning.

## TF2 frame and lookup discipline

Concept. The Ch 5 frame chain is `lidar → base_link → odom/map`. The `lidar → base_link` transform is sensor extrinsics and usually belongs on `/tf_static`; `base_link → odom` is the local ego-pose estimate; `odom → map` connects local odometry to map-relative localization when the stack has a global or HD-map frame. Some stacks collapse the last hop for local-only perception, but the interface should still state whether outputs are in `base_link`, `odom`, or `map`.

Mechanics split into two distinct use cases.

Use case (a) is to transform a whole cloud as a rigid frame at the reference time. This is what a ground node, clusterer, or shape fitter does when it receives the already-deskewed §5.1 cloud in `base_link`, or when a map-ROI branch needs one sweep-end transform into `map`. The lookup time is the message reference time: `header.stamp`. The node should preflight with `canTransform(target, source, header.stamp, timeout)` and then call `lookupTransform(target, source, header.stamp, timeout)` for the actual transform. The preflight gives a clean diagnostic path; the lookup is still the authoritative operation because the buffer can change between checks. Static transforms such as `lidar → base_link` can be cached after validation; dynamic transforms must be time-specific. Never use `TimePointZero` inside the hot path unless the contract explicitly says "latest available transform," because latest transform is often wrong for delayed sensor data.

```cpp
const auto stamp = msg->header.stamp;
const auto src = msg->header.frame_id;
const auto dst = target_frame_;
if (!tf_buffer_.canTransform(dst, src, stamp, tf2::durationFromSec(0.05))) {
  diagnostics_.mark_tf_missing(dst, src, stamp);
  return;  // primary obstacle path: reject, do not clamp
}
const auto T_dst_src = tf_buffer_.lookupTransform(
  dst, src, stamp, tf2::durationFromSec(0.05));
```

Use case (b) is deskew by interpolating ego motion over per-point times across the scan interval. The node does not need one transform; it needs coverage across `[header.stamp − sweep_duration, header.stamp]`, or more tightly across `[header.stamp − max(point.time), header.stamp − min(point.time)]`. With the Ch 5 convention, `t_point = header.stamp − point.time`, and the output common time is usually `header.stamp`. The deskew node needs `lidar → base_link` static extrinsics and time-varying ego pose for every point time. TF2 can supply the discrete transforms if the buffer has enough history; an ego-pose trajectory buffer can do the interpolation when the stack owns a continuous or high-rate odometry source. The policy is the same either way: if the buffer does not cover the sweep window, reject the frame on the primary obstacle path. Do not clamp early points to the oldest transform or late points to the newest transform; clamping creates an apparently valid cloud with speed-dependent residual distortion.

Worked example. A 10 Hz mechanical LiDAR publishes a sweep with `header.stamp = 12.300 s`, `min(time)=0.000`, and `max(time)=0.096`. The rigid whole-cloud transform for map ROI gating asks for one `map ← base_link` lookup at `12.300 s`. Deskew asks for the ego trajectory over `[12.204 s, 12.300 s]`. If `/tf` contains transforms only from `12.250 s` onward, use case (a) can still succeed while use case (b) must fail. Treating those two cases as the same lookup is how scan-interval bugs enter a stack that appears to have a healthy TF tree.

TF freshness and extrapolation policy should be explicit. For the primary obstacle path, fail fast when the requested time is outside the buffer, when the transform age exceeds the declared budget, or when TF2 would extrapolate. For non-safety diagnostics, visualization, and offline inspection, a fallback path may use latest transform or clamp to buffer bounds, but the output must be labeled as degraded and must not feed boxes, tracks, occupancy, or ROI decisions. The distinction is not bureaucratic. Rejecting a cloud causes a visible drop; clamping silently moves points into the wrong pose and creates confident false geometry.

Failure mode. Missing `/tf_static` removes the `lidar → base_link` edge. Stale dynamic TF makes map ROI masks slide relative to the cloud. TimePointZero latest-transform code works in RViz and fails under rosbag replay. Deskew may need an old transform near sweep start even when a single sweep-end lookup succeeds. These failures are owned by the catalog rows `5_8.fm.missing_tf_static`, `5_8.fm.sim_time_not_honored`, and the cross-section deskew symptoms in §5.1 / §5.3.

## Lifecycle / managed nodes

Concept. Shippable Ch 5 perception nodes should be C++ `rclcpp_lifecycle::LifecycleNode` components, not long-running scripts with implicit startup order. The four primary steady states are `unconfigured`, `inactive`, `active`, and `finalized`; transitions between them go through transitional states such as `configuring`, `activating`, `deactivating`, `cleaningup`, `shuttingdown`, and `errorprocessing`. Ch 5 perception nodes spend almost all useful runtime in `active`, but the earlier states are where integration correctness is enforced.

Mechanics. `on_configure` declares and reads parameters: input topic, output topics, expected frames, QoS policy, voxel sizes, clustering thresholds, TF timeout, sweep duration bounds, and whether `map` is required. It creates the `PointCloud2` subscription, TF2 buffer/listener, lifecycle publishers, diagnostics, and any fixed-size scratch buffers. It also validates the `PointCloud2` schema if a sample message is available, or records a pending hard gate to validate the first received sample before activation. `on_activate` should verify parameter completeness, the `/tf_static` chain, topic remappings, and publisher activation before any obstacle output can be produced. Static transforms should be cached only after the exact `lidar → base_link → odom/map` chain required by the node has been checked. `on_deactivate` stops publishing so a supervisor can switch pipelines without half-valid boxes. `on_cleanup` releases large buffers after driver restarts.

The activation gate is the important pattern. A ground node can activate with only `base_link` output if it consumes a pre-deskewed cloud; a map ROI node must require `map` availability; a tracker must require the `base_link → odom` dynamic chain. A launch file that brings nodes up before `/tf_static` exists should leave them inactive with a clear diagnostic, not active and quietly publishing in the wrong frame.

Failure mode. Partial availability looks healthy in ROS graphs: topics exist, components are loaded, and callbacks fire. The failure appears later as frame-shifted boxes, no map ROI candidates, or non-reproducible replay. Lifecycle gates convert that partial availability into a visible startup refusal.

## Executors, callback groups, and backpressure

Concept. ROS2 executor policy is runtime behavior, not plumbing trivia. A LiDAR pipeline can be algorithmically correct and still fail because callbacks queue faster than the executor drains them, because TF callbacks share a mutually-exclusive group with a long clustering callback, or because a publisher boundary keeps accepting stale results after the tracker has already moved on.

Mechanics. Use queue depth deliberately. Early cloud subscriptions usually prefer small keep-last depth: process the newest frame and drop when the CPU is late. A tracking input can tolerate a short bounded queue if it preserves order and rejects stale stamps. Diagnostics and low-rate map updates can use deeper queues because they are not on the primary obstacle cadence. Callback groups should follow shared-state ownership. A clustering callback that mutates scratch buffers belongs in a mutually-exclusive group unless the code was written for concurrent calls. TF listener callbacks, timers, and low-rate diagnostics can be reentrant when they do not mutate the same state. MultiThreadedExecutor only helps if callback groups allow useful overlap; otherwise it creates the illusion of parallelism while one long callback blocks the path.

Backpressure belongs at the cluster-publisher boundary. Preprocess and ground segmentation touch the full cloud and should drop old input under overload. Cluster, fit, and track publish smaller messages, but they must still preserve timestamp order. If a cluster node falls behind, it should skip stale clouds according to policy before publishing old boxes; the tracker should reject out-of-order detections or route them through an explicit out-of-sequence path as §5.5 describes. History depth is therefore not a pure throughput knob. It decides whether the pipeline drops frames visibly or produces outputs that are late but syntactically valid.

Failure mode. The observable symptom is bursty callbacks, apparently low compute time with missing sequence numbers, or tracks that coast and then jump when a late box batch arrives. The mitigation is to publish per-stage input stamp, output stamp, queue depth, dropped-frame count, callback duration, and TF age.

## Composable / component nodes

Concept. Large clouds make serialization overhead visible. The Velodyne HDL-64E publishes about 1.3 M points per second at 10 Hz, roughly 130k points per frame in single-return mode; with a 32-byte `point_step`, that is about 4.2 MB of raw `PointCloud2.data` per frame before dual-return or fusion. Cross-process serialize/deserialize at every Ch 5 stage can waste the same memory bandwidth the algorithms need.

Mechanics. Composable nodes put multiple C++ components in one process under `rclcpp_components::ComponentManager`. With `use_intra_process_comms: true` and compatible QoS, intra-process pass-through avoids DDS serialization and can avoid copies under the right ownership, QoS, and mutation conditions. The softened phrase matters: a `PointCloud2` with dynamically-sized `data` is not magically zero-copy in every ROS2 Humble RMW, and any stage that mutates the cloud should publish a new message or a clear derived representation rather than modifying a shared buffer in place. Loaned messages can help fixed-size POD traffic on RMWs that support them, but they are not the core solution for large `PointCloud2` clouds.

The typical Ch 5 deployment is one component container for the primary perception path and separate processes for drivers, localization, and safety supervision:

```text
perception_container  (one OS process)
├── deskew_preprocess_component       /points_raw -> /points_deskewed
├── ground_segmentation_component     /points_deskewed -> /points_nonground
├── cluster_component                 /points_nonground -> /clusters
├── shape_fit_component               /clusters -> /objects_raw
├── tracking_component                /objects_raw -> /tracks
├── occupancy_component               /points_deskewed + /tracks -> /occupancy_grid
└── subrate_registration_component    /points_deskewed -> /registration_diagnostics

separate processes:
  lidar_driver, localization, tf_static_publisher, lifecycle_manager,
  recorder/replay harness, watchdog/safety monitor
```

The container-vs-process tradeoff is operational. One container gives cheap pass-through and simpler component loading. Separate processes give fault isolation, easier CPU affinity, independent restarts, and clearer crash containment. A reasonable split is to co-locate full-cloud stages that pass large messages and isolate external trust boundaries: sensor drivers, localization, lifecycle manager, recorder, and safety monitor. Sub-rate registration is shown as a component because it consumes the full cloud but does not need to run every frame; in some stacks it is isolated when map memory or optimizer failures are large enough to justify a process boundary.

Failure mode. The overly strong claim is "composable nodes give zero-copy clouds." The correct claim is narrower: they avoid serialization and can avoid copies under right ownership/QoS/mutation conditions. If a container crosses QoS incompatibility, mutates shared data, or runs a single mutually-exclusive callback group, the expected transport win disappears or becomes a concurrency bug.

## rosbag replay validity

Concept. rosbag replay is useful for §5.8 only when it preserves the same clock, QoS, frame, and per-point timing assumptions as live operation. A bag that looks fine in RViz may still be invalid for perception regression.

Mechanics. The bag must include the cloud topic, `/tf`, `/tf_static`, and `/clock` when simulated time is used. Nodes under replay should set `use_sim_time: true` so `rclcpp::Clock` and TF2 lookups use `/clock`, not wall time. The replay launch should fail fast when `/clock` is missing after `use_sim_time: true` is set, because otherwise timers, TF2 lookups, lifecycle transitions, and diagnostics compare incompatible time domains. The bag must also preserve the `PointCloud2` per-point `time` field. A cloud with correct `header.stamp` but missing relative point times cannot validate deskew.

QoS is the replay trap. `/tf_static` needs durable behavior (`transient_local` / durable) so late-joining perception components receive static extrinsics. Live clouds often use `SensorDataQoS` best-effort; recorded regression may choose reliable replay to avoid accidental packet loss, or may deliberately preserve best-effort loss to match a live failure. Either choice is acceptable only when written into rosbag QoS override files. History depth affects lossy replay: depth `1` may drop bursts when the CPU stalls; deeper history can replay every message but increase latency and make the tracker see old boxes. For validation, record the intended QoS profile, replay override file, processed stamp count, dropped stamp count, and whether `/tf_static` was received before activation.

Worked example. Suppose a live driver publishes `/points_raw` with `SensorDataQoS` best-effort depth `5`, while the bag records a reliable profile and replay offers reliable depth `10`. A best-effort subscription can match, but the replay no longer represents live packet loss. If the validation question is "does the algorithm pass on a clean deterministic log," reliable replay is fine. If the question is "does the system tolerate the original wireless bridge or overloaded network," the override should preserve the lossy QoS and the expected drop policy. In both cases, `/tf_static` should be transient-local/durable and available before lifecycle activation.

Failure mode. Missing `/tf_static` removes the `lidar → base_link` edge. Mismatched timestamps produce TF2 extrapolation errors or silent latest-transform lookups. Wrong rosbag QoS drops large clouds or latched static transforms. Replay without `use_sim_time: true` makes deterministic data non-deterministic because node time is wall time while message time is bag time.

## Output contract and per-stage cadence

The publishing contract is the narrow interface between §5.8 and the algorithm sections:

```text
/points_raw:       frame_id = lidar,     header.stamp = sweep end,
                   per-point time = non-negative Δt, t_point = header.stamp − time
/points_deskewed:  frame_id = base_link, header.stamp = same sweep end,
                   per-point time preserved unless a derived message explicitly drops it
/points_nonground: frame_id = base_link, header.stamp = same sweep end
/clusters:         frame_id = base_link, header.stamp = source cloud stamp
/objects_raw:      frame_id = base_link, header.stamp = source cloud stamp
/tracks:           frame_id = odom,      header.stamp = latest associated detection stamp
/occupancy_grid:   frame_id = odom or map by branch policy, timestamp = update time,
                   cells carry age / last_update when consumed as free-space evidence
```

| Ch-5 stage | expected QoS profile | expected rate | TF freshness budget | executor / queue-depth assumption |
|---|---|---:|---|---|
| §5.1 preprocess / deskew | `SensorDataQoS`, keep-last `1-5`, volatile; replay override explicit | LiDAR rate, usually 10 Hz | `/tf_static` cached; ego pose covers full sweep window; dynamic TF age ≤ 50 ms | Mutually-exclusive hot callback unless scratch buffers are per-call; drop stale input under overload |
| §5.2 ground segmentation | Intra-process compatible with preprocess; small keep-last | Every frame | Usually no new lookup if input already `base_link`; verify stamp/frame | Same container; queue depth `1-2`; publish residual count diagnostics |
| §5.3 clustering | Intra-process for residual cloud; small keep-last | Every frame or configured sub-rate | No latest-transform lookup in hot path; consume source stamp | Mutually-exclusive if using shared KD-tree/work buffers; backpressure before cluster publish |
| §5.4 shape fitting | Reliable or intra-process for small cluster messages; keep-last `5` acceptable | Every cluster frame | Source frame/stamp preserved; no silent frame conversion | Can be reentrant if fit state is per-message; preserve output order |
| §5.5 tracking | Reliable small messages; bounded keep-last `5-10` | Every detection frame; prediction may tick faster | `base_link → odom` at detection `header.stamp`; reject out-of-buffer | Mutually-exclusive track-state callback; reject or explicitly handle OOSM |
| §5.6 registration roles | Reliable diagnostics; cloud input may be `SensorDataQoS`; sub-rate | 1-10 Hz by role | Needs map/odom coverage at source stamp or accumulation window | Separate callback group or component; long optimizer must not block TF/listener callbacks |
| §5.7 occupancy / ROI | Reliable for small grids/masks; cloud input intra-process or `SensorDataQoS` | Every frame for free-space; ROI table lower-rate | ROI branches need `map`; occupancy declares `odom` vs `map` | Queue depth chosen by freshness; stale grids should be aged, not silently reused |
| §5.8 integration diagnostics | Reliable, low-rate; `/tf_static` transient-local/durable | 1-10 Hz diagnostics | Reports measured age and activation status | Reentrant diagnostics timers are acceptable if they do not mutate hot-path state |

## Reference stacks

Reference stacks are useful here for conventions, not as parameter or safety proofs. Autoware Universe / Autoware Core / Apollo perception / MOLA name the families worth reading, but the copyable unit is the boundary pattern: componentization, timestamp discipline, TF contracts, diagnostics, and map/occupancy separation.

| stack | relevant package / area | convention to copy | convention not to copy |
|---|---|---|---|
| Autoware Universe | `autoware_pointcloud_preprocessor`, ground segmentation, Euclidean cluster detector, shape estimation, map comparison nodes | Component boundaries, launch-time parameters, point-cloud preprocessing split, diagnostics around filtering and detection | Treating default parameters or topic names as portable across sensors and ODDs |
| Autoware Core | Core perception and component architecture subset | Conservative integration contracts and deployable component shape | Assuming a smaller curated stack covers every experimental package pattern |
| Apollo perception | LiDAR perception, HDMap ROI filtering, object proposal / tracking integration | Separation of transport, map ROI gating, object geometry, tracking state, and safety fallback branches | Copying a historical detector architecture without matching Apollo's map, calibration, and runtime context |
| MOLA | Modular LiDAR odometry / mapping / dataset replay workflows | Frame-aware registration, replay discipline, explicit timing assumptions around mapping and localization | Treating it as a drop-in object detector; it is closer to localization/mapping substrate than Ch 5 detection |

The bounded lesson is the same across the table. Copy explicit interfaces and diagnostics. Do not copy a parameter set without the sensor, calibration, map frame, ODD, CPU, and validation harness that made it meaningful.

> [!warning] Failure modes for §5.10 catalog
> | id | cause | observable_symptom | downstream_hazard | mitigation | validation_test |
> |---|---|---|---|---|---|
> | `5_8.fm.missing_tf_static` | rosbag replay, launch, or bridge omits `/tf_static`, so the `lidar → base_link` transform is unavailable. | TF2 lookup fails for every cloud, or all detections remain in the `lidar` frame while downstream modules expect `base_link`. | Clusters, fitted boxes, and tracks shift relative to ego-pose; HD-map ROI gating can reject true obstacles or accept background. | Publish static extrinsics before activating perception nodes; require a startup gate that verifies the full `lidar → base_link → odom → map` chain when `map` is needed. | Replay a short rosbag with `/tf_static` removed; assert the lifecycle node refuses to activate or emits a hard diagnostic instead of publishing detections. |
> | `5_8.fm.qos_mismatch_drops_clouds` | Cloud publisher, component subscription, or rosbag replay uses incompatible QoS (durability/reliability/history) for large sensor data. | Frame rate drops below the LiDAR rate, callbacks arrive in bursts, or diagnostics show missing sequence numbers without algorithm overload. | Tracking coasts through real objects, occupancy becomes stale, and runtime budgets look artificially good because frames are skipped. | Use `rclcpp::SensorDataQoS()` deliberately for live clouds, record/replay with matching QoS overrides, count input stamps at every component boundary. | Replay at nominal 10 Hz; verify the count of processed `PointCloud2` stamps matches the recorded cloud count within the declared drop policy. |
> | `5_8.fm.sim_time_not_honored` | Replay nodes do not set `use_sim_time: true`, so TF2 and lifecycle timers use wall time while messages use bag time. | TF2 extrapolation errors, stale-transform diagnostics, or transforms that work live but fail under rosbag replay. | Deskew, ROI gating, and tracking validation become non-reproducible across runs. | Set `use_sim_time: true` for all perception, TF2, and diagnostic nodes during replay; fail fast when `/clock` is missing. | Run the same rosbag twice with deterministic parameters; compare cloud stamps, TF2 lookup times, and detection counts. |
> | `5_8.fm.pointcloud2_offset_drift` | Producer and consumer disagree about `PointCloud2` field offsets, padding, or `time` scalar type. | Deskew creates curved walls, NaN clusters, or range-dependent object smearing while raw visualization appears plausible. | Ground segmentation and clustering receive geometrically corrupted points and produce unstable boxes. | Validate field names, offsets, datatype, `point_step`, and `is_bigendian` at subscription startup; reject unsupported layouts explicitly. | Feed a synthetic cloud with known `x, y, z, intensity, ring, time` bytes; assert decoded values match the fixture exactly. |

## Runtime-budget row

| stage | compute | frame_rate_assumption | point_count_assumption | latency_p50_ms | latency_p99_ms | memory_mb | cadence | tf_freshness_assumption | assumptions_and_caveats |
|---|---|---:|---:|---:|---:|---:|---|---|---|
| `5_8_ros2_integration` | `cpu` | 10 Hz mechanical-spinning | ~130k points/frame HDL-64E (single return; ~1.3 M pts/sec ÷ 10 Hz) | ~0.6 | ~2.0 | ~8, plus the shared ~4.2 MB cloud buffer | `every-frame` | ≤ 50 ms for `/tf`; `/tf_static` present before activation | **Illustrative** ROS2 plumbing overhead only: subscribe + intra-process pass-through through one composable component + one timestamped TF2 lookup. Assumes C++ components in one process, compatible QoS, intra-process `std::shared_ptr` pass-through for `PointCloud2` (loaned-message zero-copy does *not* apply to the dynamically-sized cloud `data`), single LiDAR, no algorithmic filtering included. Per-deployment numbers vary with RMW choice, allocator, and CPU class; should be measured. |
