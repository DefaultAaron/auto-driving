---
chapter: 5
section: 0
title: 经典激光雷达检测 — 概览
language: ZH
status: planned
tags:
  - book/section
  - book/chapter-5
  - book/overview
  - lang/ZH
---

# 第 5 章 — 经典激光雷达检测

> [!info] 状态与权威来源
> Frontmatter 中的 `status` 字段是权威来源。[[00_table_of_contents|目录]] 中的状态标记为手动同步的展示副本。

> [!abstract] 本章内容
> AD 团队多年来在用、且至今仍在用的经典(非 DL)激光雷达检测工具箱:点云预处理(含统一的 *Representation map* 速览)、地面 / 非地面分割、聚类、**目标形状拟合(L-shape、OBB、类别先验)**、多目标跟踪、配准(定位章节前向指针指向这里,本章给出感知侧的四个用途)、**占据 / 可行驶空间推理与 HD-Map ROI 门控**、ROS2 集成,以及让一切真正能跑起来的部署 / 运行时约束。经典管线为 `preprocess → ground → cluster → fit → track`,周围环绕配准、占据 / ROI 门控与 ROS2 接线。本章是 [[6_0_overview_ZH|第 6 章 — 深度学习激光雷达检测]] 在主 3D 检测框预测上要替换或混合的基线;预处理、跟踪、占据、地图辅助 ROI 门控在 DL 为主的生产栈中仍是载力的经典层。

## 学习目标
- 对原始点云进行预处理(下采样 / 体素滤波 / 离群点剔除 / 运动补偿),并按任务选择合适的表示(原始点云 / 体素 / 距离图像 / BEV)。
- 用 RANSAC 类方法做地面分割,理解其失败模式;掌握现代经典基线(Patchwork / Patchwork++)。
- 用 Euclidean / DBSCAN / 距离图像连通域对非地面点聚类得到目标候选。
- 拟合目标形状 —— L-shape(Zhang 2017)、OBB、类别先验尺寸 —— 把聚类块转成对规划器友好的检测框。
- 用 Kalman / IMM / JPDA / AB3DMOT 实现多目标跟踪。
- 用 ICP / NDT / GICP 配准多帧或多激光雷达扫描 —— [[2_0_overview_ZH|第 2 章 §2.3]] 激光雷达定位的算法深度,以及配准在第 5 章感知侧的四个用途(去畸变细化 / 地图差分 / 多帧累积对齐 / ROI 一致性)。
- 构建占据栅格、估计可行驶空间,并应用 HD-Map ROI 门控先验(Apollo HDMap LUT、Autoware `compare_map_segmentation`)。
- 将整条管线封装为 ROS2 节点 / topic。
- 推理部署约束(CPU/GPU 预算、延迟、ROS2 时序、现场鲁棒性)。

## 先修要求
- [[1_0_overview_ZH|第 1 章 — 基础知识]](尤其 §1.3 激光雷达基础、§1.4 传感器同步、§1.5 ROS2 基础)
- [[2_0_overview_ZH|第 2 章 — 定位]](提供本章输出所要依附的本体位姿语境)

## 各小节
| § | 标题 | 状态 (EN) | 状态 (ZH) |
|---|-------|:-----------:|:-----------:|
| 5.0 | 概览(本页) | ◐ | ◐ |
| 5.1 | 点云预处理(含 *Representation map* 速览) | ○ | ○ |
| 5.2 | 地面分割(RANSAC 等) | ○ | ○ |
| 5.3 | 聚类 — Euclidean、DBSCAN | ○ | ○ |
| 5.4 | 目标形状拟合 — L-shape、OBB、类别先验 | ○ | ○ |
| 5.5 | 多目标跟踪 — Kalman / IMM / JPDA | ○ | ○ |
| 5.6 | 配准 — ICP / NDT / GICP([[2_0_overview_ZH\|第 2 章]] 定位的算法深度,加上感知侧四个用途) | ○ | ○ |
| 5.7 | 占据、可行驶空间与地图辅助 ROI 门控 | ○ | ○ |
| 5.8 | ROS2 集成 | ○ | ○ |
| 5.9 | 部署与运行时约束 — CPU/GPU 预算、延迟、时序、现场鲁棒性 | ○ | ○ |
| 5.10 | 安全与验证(模板实例) | ○ | ○ |

## 延伸阅读
- _见 [[reading_list]] 第 5 章相关条目(PCL、经典激光雷达论文、RANSAC、ICP / NDT、占据建图)_。

## 相关链接
- ⬅ 上一章: [[4_0_overview_ZH]]
- ➡ 下一章: [[6_0_overview_ZH]]
- 🌐 其他语言版本: [[5_0_overview_EN]]
- 🗂 目录总表: [[00_table_of_contents]]
