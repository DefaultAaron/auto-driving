---
chapter: 9
section: 0
title: 深度学习规划、预测与控制 — 概览
language: ZH
status: planned
tags:
  - book/section
  - book/chapter-9
  - book/overview
  - lang/ZH
---

# 第 9 章 — 深度学习规划、预测与控制

> [!info] 状态与权威来源
> Frontmatter 中的 `status` 字段是权威来源。[[00_table_of_contents|目录]] 中的状态标记为手动同步的展示副本。

> [!abstract] 本章内容
> [[8_0_overview_ZH|第 8 章]] 的 DL 替代或混合方案:模仿学习与行为克隆;面向驾驶的强化学习;具备多模态交互推理的学习式轨迹预测;学习式运动规划器;神经 MPC 与混合系统;以及这一切常用的开发 / 验证仿真器(CARLA、Apollo)。本章末覆盖评估与安全。本章隐含所要求的数据纪律由 [[10_0_overview_ZH|第 10 章 — 自动驾驶数据引擎、标注与 ML Ops]] 持有。

## 学习目标
- 搭建模仿 / 行为克隆管线,理解其局限(协变量漂移、数据集平衡)。
- 把 RL 应用到驾驶子问题上,推理奖励设计与 sim-to-real 风险。
- 实现多模态轨迹预测(Trajectron / VectorNet / MTR / TNT 谱系)。
- 与第 8 章经典基线对比学习式运动规划器。
- 把 CARLA / Apollo 用作开发与验证平台。

## 先修要求
- [[8_0_overview_ZH|第 8 章 — 经典运动规划、预测与控制]](基线 + 概念)
- 来自前面 DL 章节的 PyTorch 经验。

## 各小节
| § | 标题 | 状态 (EN) | 状态 (ZH) |
|---|-------|:-----------:|:-----------:|
| 9.0 | 概览(本页) | ◐ | ◐ |
| 9.1 | 模仿学习与行为克隆 | ○ | ○ |
| 9.2 | 面向驾驶的强化学习 | ○ | ○ |
| 9.3 | 学习式轨迹预测与多模态交互(Trajectron / VectorNet / MTR) | ○ | ○ |
| 9.4 | 学习式运动规划器 | ○ | ○ |
| 9.5 | 神经 MPC 与混合系统 | ○ | ○ |
| 9.6 | 仿真 — CARLA / Apollo | ○ | ○ |
| 9.7 | 评估与安全(模板实例) | ○ | ○ |

## 延伸阅读
- _见 [[reading_list]] 第 9 章相关条目(IL / BC / RL for driving、预测谱系、CARLA / Apollo 论文)_。

## 相关链接
- ⬅ 上一章: [[8_0_overview_ZH]]
- ➡ 下一章: [[10_0_overview_ZH]]
- 🌐 其他语言版本: [[9_0_overview_EN]]
- 🗂 目录总表: [[00_table_of_contents]]
