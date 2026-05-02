---
chapter: 12
section: 0
title: End-to-End Autonomous Driving — Overview (Capstone)
language: EN
status: planned
tags:
  - book/section
  - book/chapter-12
  - book/overview
  - lang/EN
---

# Chapter 12 — End-to-End Autonomous Driving (Capstone)

> [!info] Status & canonical state
> Frontmatter `status` is canonical. [[00_table_of_contents|TOC]] badges are a manual display copy.

> [!warning] Open definitional question
> "End-to-end AD" is overloaded — it can mean camera-to-control, full sensor-suite-to-trajectory, perception-to-planning integration, imitation/BC, VLA-style driving models, or full vehicle autonomy. §12.1 must pin a working definition before the rest of the chapter is written. The reader should expect §12.1 to enumerate the candidates and commit to one (or to a small taxonomy).

> [!abstract] What this chapter covers
> The book's capstone. By this point the reader has the perception stack (Ch 3–7), the localization substrate (Ch 2), the planning + control toolbox (Ch 8–9), the data engine (Ch 10), and the safety vocabulary (Ch 11) — all now turned on E2E systems: definition + taxonomy, UniAD-style one-model designs, VLA / foundation-model drivers, training at scale, sim + safety case (forward-references Ch 11), integration considerations, and open research problems.

> [!info] Industry context
> Leading E2E efforts differ sharply by region: Wayve / Waymo / Cruise / Tesla in the US; Apollo / Pony / Momenta / XPeng's NGP in China; Mobileye / Bosch in Europe. Each carries different sensor suites, regulatory contexts, and definitions of "end-to-end". Reading-list entries are region-tagged.

## Learning objectives
- Pin a working definition of "end-to-end AD" and place leading systems in a taxonomy.
- Read and reproduce key results from UniAD-style one-model architectures.
- Reason about VLA / foundation-model-based driving systems and what they buy.
- Understand training-at-scale concerns (data curation, distributed training, eval suites, sim) — leveraging Ch 10's data engine.
- Read and critique an end-to-end AD safety case using Ch 11 vocabulary.

## Prerequisites
- [[7_0_overview_EN|Chapter 7 — Sensor Fusion]]
- [[9_0_overview_EN|Chapter 9 — DL Planning, Prediction & Control]]
- [[10_0_overview_EN|Chapter 10 — Data Engine + MLOps]]
- [[11_0_overview_EN|Chapter 11 — Safety, Validation & Operational Discipline]]

## Sections
| § | Title | Status (EN) | Status (ZH) |
|---|-------|:-----------:|:-----------:|
| 12.0 | Overview (this page) | ◐ | ◐ |
| 12.1 | Definition & taxonomy (resolves the open question) | ○ | ○ |
| 12.2 | UniAD & one-model paradigms | ○ | ○ |
| 12.3 | VLA & foundation-model drivers | ○ | ○ |
| 12.4 | Data & training at scale (leveraging [[10_0_overview_EN\|Ch 10]]) | ○ | ○ |
| 12.5 | Eval / sim / safety case (using [[11_0_overview_EN\|Ch 11]] vocabulary) | ○ | ○ |
| 12.6 | Integration considerations | ○ | ○ |
| 12.7 | Open research problems | ○ | ○ |

## Further reading
- _See [[reading_list]] (Chapter 12 entries — UniAD, VAD, DriveGPT-style models, VLA papers, end-to-end AD surveys)._

## Cross-references
- ⬅ Previous: [[11_0_overview_EN]]
- 🌐 Other language: [[12_0_overview_ZH]]
- 🗂 Master TOC: [[00_table_of_contents]]
