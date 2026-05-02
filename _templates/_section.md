---
chapter: <N>
section: <M>
title: <Section title>
language: EN
workflow_status: planned
tags:
  - book/section
  - book/chapter-<N>
  - lang/EN
---

# <Chapter N>.<M> — <Section title>

> [!info] Workflow status & canonical state
> The frontmatter `workflow_status` field above is the **canonical** progress indicator for this file (`planned` → `draft` → `reviewing` → `complete`).
> `planned` is the manual-scaffold starting state. The writer pipeline (cc-writer / codex-writer) sets `draft` on first write, `reviewing` after deal-loop revisions, and `complete` after the chapter voice pass.
> The status badges in [[00_table_of_contents|the table of contents]] are a **manual display copy** — re-sync them when you change `workflow_status` here.

> [!abstract] Summary
> One-paragraph summary of what this section covers and why it matters.

## Learning objectives
- _What the reader can do after this section._

## Prerequisites
- [[<previous section wikilink>]]

## Body
_Main content goes here. Prefer Obsidian features:_
- _Wikilinks `[[Other section]]` for internal references._
- _Embeds `![[image.png|600]]` for diagrams._
- _Callouts `> [!warning]` / `> [!example]` / `> [!tip]` for highlighted points._
- _Math with `$inline$` and `$$block$$`._

## Code examples
> Use [[_templates/_code_example|the code-example template]] for new blocks.
> **DL → PyTorch.** **ROS2 nodes / classical perception / control → C++** when feasible (else original).

```python
# PyTorch example skeleton
```

```cpp
// C++ ROS2 / PCL / Eigen example skeleton
```

## Worked example reference (optional)
_If this section illustrates a concept with the mingtai project, link the path + line range:_
- `~/Documents/Projects/mingtai/traffic-light/<path>:Lxx-yy`

## Further reading
_Curated entries from [[reading_list]]._

## Cross-references
- ⬅ Previous: [[<N>_<M-1>_*_EN]]
- ➡ Next: [[<N>_<M+1>_*_EN]]
- 🌐 Other language: [[<N>_<M>_*_ZH]]
