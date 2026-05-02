---
chapter: 11
section: 0
title: Safety, Validation & Operational Discipline — Overview
language: EN
status: planned
tags:
  - book/section
  - book/chapter-11
  - book/overview
  - lang/EN
---

# Chapter 11 — Safety, Validation & Operational Discipline

> [!info] Status & canonical state
> Frontmatter `status` is canonical. [[00_table_of_contents|TOC]] badges are a manual display copy.

> [!abstract] What this chapter covers
> The discipline that makes the previous chapters' models actually shippable: ODD, hazard analysis, scenario-based testing, simulation limits, runtime monitoring & graceful fallback, disengagement and failure-mode taxonomies, the structure of a safety case, ISO 26262 and SOTIF as background context, and on-vehicle bring-up & validation discipline. Owns the safety thread that has appeared as a recurring section in every applied chapter. Sits **before** [[12_0_overview_EN|Chapter 12 — End-to-End AD]] so the reader gains safety vocabulary before encountering end-to-end claims.

> [!info] Industry context
> Standards differ by region: ISO 26262 + SOTIF dominate EU/JP; UL 4600 + RSS-style frameworks are influential in the US; China's draft autonomous-vehicle standards are evolving rapidly under MIIT. Reading-list entries are tagged `region/cn` / `region/us` / `region/eu`.

## Learning objectives
- Define an ODD precisely and reason about ODD changes.
- Perform a HARA at the level a small AD team can sustain.
- Build scenario-based test plans that map to identified hazards.
- Reason about what simulation can and cannot validate.
- Design runtime monitors and graceful-fallback behaviors.
- Read and write the skeleton of a safety case.
- Conduct on-vehicle bring-up with discipline (not vibes).

## Prerequisites
- [[1_0_overview_EN|Chapter 1 — Foundations]] (esp. §1.10 ODD primer, §1.11 hazard analysis intro)
- The recurring safety sections in chapters 2, 4, 5, 6, 7, 8, 9 (each a template instance referencing back here).
- [[10_0_overview_EN|Chapter 10 — Data Engine + MLOps]] (validation evidence and replay sets are managed there).

## Sections
| § | Title | Status (EN) | Status (ZH) |
|---|-------|:-----------:|:-----------:|
| 11.0 | Overview (this page) | ◐ | ◐ |
| 11.1 | ODD revisited | ○ | ○ |
| 11.2 | Hazard analysis & risk assessment (HARA) | ○ | ○ |
| 11.3 | Scenario-based testing | ○ | ○ |
| 11.4 | Simulation limits & sim-to-real gap | ○ | ○ |
| 11.5 | Runtime monitoring & graceful fallback | ○ | ○ |
| 11.6 | Disengagement & failure-mode taxonomy | ○ | ○ |
| 11.7 | Safety case structure & validation evidence | ○ | ○ |
| 11.8 | ISO 26262 & SOTIF — background context | ○ | ○ |
| 11.9 | On-vehicle bring-up & validation discipline | ○ | ○ |

## Further reading
- _See [[reading_list]] (Chapter 11 entries — UL 4600, ISO 26262 / 21448 SOTIF, RSS, scenario-testing surveys)._

## Cross-references
- ⬅ Previous: [[10_0_overview_EN]]
- ➡ Next: [[12_0_overview_EN]]
- 🌐 Other language: [[11_0_overview_ZH]]
- 🗂 Master TOC: [[00_table_of_contents]]
