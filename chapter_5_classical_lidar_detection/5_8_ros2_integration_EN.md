---
chapter: 5
section: 8
title: ROS2 integration
language: EN
workflow_status: draft
tags:
  - book/section
  - book/chapter-5
  - lang/EN
---

# 5.8 ROS2 integration

The Ch 5 pipeline lives inside ROS2 / Humble: raw LiDAR packets become `sensor_msgs/PointCloud2`, pass through `preprocess → ground → cluster → fit → track`, and leave the chapter as boxes, tracks, occupancy, and diagnostics. This section is not a ROS2 tutorial; [[1_5_ros2_humble_essentials_EN|Ch 1 §1.5]] owns publishers, subscribers, executors, and basic TF2 usage. Here the concern is narrower: the LiDAR-perception integration patterns that keep the classical pipeline correct under timing, frame, lifecycle, and replay constraints.

[[1_5_ros2_humble_essentials_EN|Ch 1 §1.5]] introduced publishers, subscribers, lifecycle nodes, and TF2 broadcast. [[1_4_sensor_time_sync_EN|Ch 1 §1.4]] covered sensor timing, per-point timestamps, and clock discipline. This section restates only the pieces needed to make Ch 5 perception nodes behave like deployable C++ ROS2 components rather than offline scripts.

## PointCloud2 message conventions

The first production boundary is the full ROS msg name `sensor_msgs/PointCloud2`; in C++ the type is `sensor_msgs::msg::PointCloud2`. A Ch 5 LiDAR cloud normally carries fields named `x`, `y`, `z`, `intensity`, `ring`, and `time`. The first three are geometric coordinates in the message `frame_id`; `intensity` is useful for filters and diagnostics but is not a stable material classifier; `ring` identifies the laser channel; `time` stores the point's relative firing time inside the scan. That per-point `time` field lets §5.1 deskew a cloud using ego-pose or IMU integration instead of treating the whole scan as instantaneous.

`header.stamp` names the time of the cloud as a message-level object. Teams choose either the start of scan or a reference time near the end of scan, but the choice must stay constant across the driver, deskew, rosbag replay, and evaluation tooling. The `frame_id` normally starts as the `lidar` frame, not `base_link`, because the cloud is measured in the sensor frame before extrinsics are applied. After deskew and transform, downstream components may publish a `base_link` cloud if the interface contract says so, but silent frame changes are a source of bugs.

`PointCloud2` is a packed binary layout, so field names alone are not enough. Each `fields[i].offset` must match the byte layout implied by `point_step`; padding bytes are legal; and consumers must verify offsets before casting. Most automotive deployments are little-endian, but `is_bigendian` should be checked at the component boundary. A common failure is to publish `x, y, z, intensity, ring, time` in the visible schema while the `time` offset is wrong by padding or by a float/double mismatch, which makes deskew look algorithmically unstable when the real error is serialization layout.

## TF2 conventions

The Ch 5 frame chain is `lidar → base_link → odom → map`. The `lidar → base_link` transform is sensor extrinsics and usually belongs on `/tf_static`; `base_link → odom` is the local ego-pose estimate; `odom → map` connects local odometry to map-relative localization when the stack has a global or HD-map frame. Some stacks collapse the last hop for local-only perception, but the interface should still state whether outputs are in `base_link`, `odom`, or `map`.

Perception nodes should use `tf2_ros::Buffer` with bounded lookup timeouts. A zero-time lookup can mask latency because it asks for the latest transform, not necessarily the transform valid at `header.stamp`; a timestamped lookup makes the frame contract explicit. The usual pattern is to reject or defer a cloud when the needed transform is missing, stale, or extrapolated beyond the buffer horizon. §5.9 will collect that gate in the `tf_freshness_assumption` field; for this section, assume `/tf` is no older than 50 ms and `/tf_static` is present before activation.

`/tf` and `/tf_static` have different durability expectations. Dynamic transforms on `/tf` change over time and need enough buffer history for delayed clouds. Static transforms on `/tf_static` are latched/durable; if a rosbag or bridge drops them, every timestamped lookup from `lidar` to `base_link` fails even though the runtime graph may look healthy.

## Lifecycle / managed nodes

Shippable Ch 5 perception nodes should be C++ `rclcpp_lifecycle::LifecycleNode` components, not long-running scripts with implicit startup order. The lifecycle states are `unconfigured`, `inactive`, `active`, and `finalized`. In `unconfigured`, the node declares parameters such as topic names, QoS, frame names, voxel size, and TF timeout. In `inactive`, it has allocated buffers and validated parameters but does not publish detections. In `active`, callbacks produce outputs. In `finalized`, resources are released and the node should not be restarted in place.

The transition handlers make startup explicit. `on_configure` creates the `PointCloud2` subscription, TF2 buffer/listener, publishers, and diagnostics. `on_activate` activates lifecycle publishers and clears stale state such as trackers or multi-frame accumulators. `on_deactivate` stops publishing so supervisors can switch pipelines without half-valid boxes. `on_cleanup` releases large buffers after driver restarts. This discipline matters because LiDAR perception often fails by partial availability: the cloud topic exists, but TF2 does not; `/tf_static` exists, but the clock does not; the node is active, but the upstream driver has switched profiles.

## Composable / component nodes for zero-copy

Large clouds make serialization overhead visible. A 1.3 M point HDL-64 frame with 32-byte `point_step` is roughly 42 MB before derived buffers. If each stage serializes and deserializes that cloud across processes, ROS2 plumbing can consume more time and memory bandwidth than a simple classical filter.

Composable nodes put multiple C++ components in one process under `rclcpp_components::ComponentManager`. With intra-process communication and loaned messages where the RMW implementation supports them, `PointCloud2` can move through a pipeline without copying or serializing its full byte buffer at every boundary. The exact zero-copy behavior depends on allocator support, publisher/subscription options, QoS compatibility, and whether each component mutates the cloud in place or publishes a derived message. The honest rule is simple: ROS2 introduces overhead at process and DDS boundaries; intra-process component wiring makes most of that cost vanish for pass-through clouds, but it does not make algorithm memory access free.

A typical Ch 5 container wires `preprocess → ground → cluster → fit → track` as composable C++ nodes. Preprocessing may produce a deskewed `PointCloud2` or a filtered index set. Ground segmentation publishes a non-ground cloud or mask. Clustering emits cluster indices. Shape fitting turns clusters into boxes, and tracking consumes boxes rather than raw points. The zero-copy win is largest in the early stages that touch the full cloud; later box and track messages are small enough that clarity usually matters more than transport micro-optimization.

## rosbag replay validity

rosbag replay is valid for §5.8 only when timing and frame assumptions are preserved. The bag must include the cloud topic, `/tf`, `/tf_static`, and the clock topic when simulated time is used. Nodes under replay should set `use_sim_time: true` so `rclcpp::Clock` and TF2 lookups use `/clock`, not wall time. The bag must also preserve the `PointCloud2` per-point `time` field, because a cloud with correct `header.stamp` but missing relative point times cannot validate deskew.

The common breakages are mundane. Missing `/tf_static` removes the `lidar → base_link` edge. Mismatched timestamps produce TF2 extrapolation errors or silent latest-transform lookups. Wrong rosbag QoS drops large clouds or latched static transforms. A replay that cannot reproduce `header.stamp`, `/clock`, `/tf`, `/tf_static`, and per-point timing is useful for visualization, but not for perception regression.

## Reference stacks

Autoware Universe / Core is the closest open reference for copying Ch 5 wiring patterns. `autoware_pointcloud_preprocessor` shows crop boxes, filtering, distortion correction, and point-cloud accumulation as separate components. `autoware_ground_segmentation` provides the ground-removal boundary that §5.2 elaborates. `autoware_euclidean_cluster_object_detector` is a Euclidean clustering reference, while `autoware_shape_estimation` shows fitted object geometry. `autoware_compare_map_segmentation` is the map-subtraction pattern that §5.7 uses for HD-map ROI gating and dynamic-object residuals. Copy the component boundaries and diagnostics more than any single parameter set.

Apollo perception is useful because it shows where classical pieces survive inside a larger stack. Apollo's LiDAR perception historically used ROI filtering, BEV representations, connected components, MinBox-style geometry, map priors, and tracking around learned modules. The reusable pattern is the separation of transport, map ROI gating, object proposal geometry, and tracking state. Even when primary 3D bbox prediction is DL-based, the classical plumbing around timing, transforms, ROI lookup, and safety fallback remains load-bearing.

MOLA is a reference stack for modular localization and mapping workflows close to Ch 5 registration concerns. It is not a drop-in detector, but it demonstrates LiDAR odometry / mapping componentization, dataset replay discipline, and frame-aware processing. Ch 5 readers can borrow its habit of keeping frame contracts and timing assumptions explicit when registration feeds deskew refinement, accumulation alignment, or map-aided ROI consistency.

> [!example]
> ```cpp
> class LidarPerceptionNode final : public rclcpp_lifecycle::LifecycleNode {
> public:
>   explicit LidarPerceptionNode(const rclcpp::NodeOptions& opts)
>     : LifecycleNode("lidar_perception", opts), tf_buffer_(get_clock()),
>       tf_listener_(tf_buffer_) {}
>
>   CallbackReturn on_configure(const rclcpp_lifecycle::State&) override {
>     sub_ = create_subscription<sensor_msgs::msg::PointCloud2>(
>       "/points_raw", rclcpp::SensorDataQoS(),
>       [this](sensor_msgs::msg::PointCloud2::ConstSharedPtr msg) {
>         auto tf = tf_buffer_.lookupTransform(
>           "base_link", msg->header.frame_id, msg->header.stamp,
>           tf2::durationFromSec(0.05));
>         process_cloud(*msg, tf);
>       });
>     return CallbackReturn::SUCCESS;
>   }
>
>   CallbackReturn on_activate(const rclcpp_lifecycle::State&) override {
>     reset_pipeline_state(); return CallbackReturn::SUCCESS;
>   }
> private:
>   rclcpp::Subscription<sensor_msgs::msg::PointCloud2>::SharedPtr sub_;
>   tf2_ros::Buffer tf_buffer_; tf2_ros::TransformListener tf_listener_;
> };
> ```

> [!warning] Failure modes
> - id: `5_8.fm.missing-tf-static`
>   cause: rosbag replay, launch, or bridge omits `/tf_static`, so the `lidar → base_link` transform is unavailable.
>   observable_symptom: TF2 lookup fails for every cloud, or all detections remain in the `lidar` frame while downstream modules expect `base_link`.
>   downstream_hazard: clusters, fitted boxes, and tracks shift relative to ego-pose; HD-map ROI gating can reject true obstacles or accept background.
>   mitigation: publish static extrinsics before activating perception nodes; require a startup gate that verifies the full `lidar → base_link → odom → map` chain when `map` is needed.
>   validation_test: replay a short rosbag with `/tf_static` removed and assert that the lifecycle node refuses to activate or emits a hard diagnostic instead of publishing detections.
> - id: `5_8.fm.qos-mismatch-drops-clouds`
>   cause: cloud publisher, component subscription, or rosbag replay uses incompatible QoS for large sensor data.
>   observable_symptom: frame rate drops below the LiDAR rate, callbacks arrive in bursts, or diagnostics show missing sequence numbers without algorithm overload.
>   downstream_hazard: tracking coasts through real objects, occupancy becomes stale, and runtime budgets look artificially good because frames are skipped.
>   mitigation: use sensor-data QoS deliberately for live clouds, record/replay with matching QoS overrides, and count input stamps at every component boundary.
>   validation_test: replay at nominal 10 Hz and verify that the number of processed `PointCloud2` stamps matches the recorded cloud count within the declared drop policy.
> - id: `5_8.fm.sim-time-not-honored`
>   cause: replay nodes do not set `use_sim_time: true`, so TF2 and lifecycle timers use wall time while messages use bag time.
>   observable_symptom: TF2 extrapolation errors, stale-transform diagnostics, or transforms that work live but fail under rosbag replay.
>   downstream_hazard: deskew, ROI gating, and tracking validation become non-reproducible across runs.
>   mitigation: set `use_sim_time: true` for all perception, TF2, and diagnostic nodes during replay; fail fast when `/clock` is missing.
>   validation_test: run the same rosbag twice with deterministic parameters and compare cloud stamps, TF2 lookup times, and detection counts.
> - id: `5_8.fm.pointcloud2-offset-drift`
>   cause: producer and consumer disagree about `PointCloud2` field offsets, padding, or `time` scalar type.
>   observable_symptom: deskew creates curved walls, NaN clusters, or range-dependent object smearing while raw visualization appears plausible.
>   downstream_hazard: ground segmentation and clustering receive geometrically corrupted points and produce unstable boxes.
>   mitigation: validate field names, offsets, datatype, `point_step`, and `is_bigendian` at subscription startup; reject unsupported layouts explicitly.
>   validation_test: feed a synthetic cloud with known `x, y, z, intensity, ring, time` bytes and assert that decoded values match the fixture exactly.

## Runtime-budget row

| stage | compute | frame_rate_assumption | point_count_assumption | latency_p50_ms | latency_p99_ms | memory_mb | cadence | tf_freshness_assumption | assumptions_and_caveats |
|---|---|---:|---:|---:|---:|---:|---|---|---|
| `5_8_ros2_integration` | `cpu` | 10 Hz mechanical-spinning | 1.3M points/frame HDL-64 | 0.6 | 2.0 | 8 plus shared ~42 MB cloud buffer | `every-frame` | <= 50 ms for `/tf`; `/tf_static` present before activation | ROS2 plumbing overhead only: subscribe + intra-process pass-through through one composable component + one timestamped TF2 lookup; assumes C++ components in one process, compatible QoS, loaned or shared intra-process `PointCloud2`, single LiDAR, no algorithmic filtering included. |
