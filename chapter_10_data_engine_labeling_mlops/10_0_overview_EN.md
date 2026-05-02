---
chapter: 10
section: 0
title: AD Data Engine, Labeling & ML Operations — Overview
language: EN
status: planned
tags:
  - book/section
  - book/chapter-10
  - book/overview
  - lang/EN
---

# Chapter 10 — AD Data Engine, Labeling & ML Operations

> [!info] Status & canonical state
> Frontmatter `status` is canonical. [[00_table_of_contents|TOC]] badges are a manual display copy.

> [!abstract] What this chapter covers
> The discipline that turns one model into a continuously-improving model: log mining, scenario selection, manual + auto labeling, label QA, active learning, dataset governance, training infrastructure, experiment / model lineage, CI for ML, production monitoring, and the data flywheel. Synthesizes the data-spine that has appeared in every prior model chapter (3, 4, 5, 6, 7, 8, 9). Sits before [[11_0_overview_EN|Ch 11 — Safety]] so safety can talk about validation evidence and replay sets that this chapter just established.

## Learning objectives
- Define and operate a data flywheel — what makes AD work data-dominated.
- Mine fleet-scale logs for interesting events and long-tail scenarios.
- Design a labeling pipeline (manual + auto-label) with credible QA and inter-annotator-agreement controls.
- Apply active learning to spend labeling budget where it moves metrics.
- Govern datasets — splits, regression sets, leakage prevention, versioning.
- Stand up training infrastructure that scales from one workstation to distributed training.
- Track experiments + models with credible lineage and CI gates.
- Monitor models in production: drift detection, replay evaluation, on-vehicle telemetry → log loop.

## Prerequisites
- [[3_0_overview_EN|Ch 3]] / [[5_0_overview_EN|Ch 5]] / [[6_0_overview_EN|Ch 6]] / [[9_0_overview_EN|Ch 9]] — by this point the reader has seen multiple DL subsystems and felt the data pain.

## Sections
| § | Title | Status (EN) | Status (ZH) |
|---|-------|:-----------:|:-----------:|
| 10.0 | Overview (this page) | ◐ | ◐ |
| 10.1 | The data flywheel — what it is, why AD is data-dominated | ○ | ○ |
| 10.2 | Log mining & scenario selection — fleet-scale search, interesting-event detection, long-tail mining | ○ | ○ |
| 10.3 | Labeling — manual vs auto-labeling pipelines, label QA, inter-annotator agreement, bias control | ○ | ○ |
| 10.4 | Active learning & uncertainty-driven sampling | ○ | ○ |
| 10.5 | Dataset governance — splits, regression sets, leakage prevention, versioning | ○ | ○ |
| 10.6 | Training infrastructure — distributed training, mixed precision, large-model practicalities | ○ | ○ |
| 10.7 | Experiment tracking, model registry & lineage | ○ | ○ |
| 10.8 | CI for ML — automated retraining, evaluation gates, regression alarms | ○ | ○ |
| 10.9 | Production monitoring — drift detection, replay evaluation, on-vehicle telemetry → log loop | ○ | ○ |
| 10.10 | Closing the loop — how perception / planning / E2E teams share one data engine | ○ | ○ |

## Further reading
- _See [[reading_list]] (Chapter 10 entries — data-flywheel writeups, auto-labeling pipelines, active-learning surveys, MLflow / Weights & Biases / DVC docs, AD-specific dataset papers)._

## Cross-references
- ⬅ Previous: [[9_0_overview_EN]]
- ➡ Next: [[11_0_overview_EN]]
- 🌐 Other language: [[10_0_overview_ZH]]
- 🗂 Master TOC: [[00_table_of_contents]]
