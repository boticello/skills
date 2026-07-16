---
name: br
description: >-
  Use when working with the `br` (beads_rust) issue tracker: creating issues,
  triaging, managing dependencies, or finding ready work. Carries the operating
  rules an agent needs mid-task — the auto-export sync model, cross-tracker
  routing, and silent-failure commands. For command shapes, flags, and JSON
  shapes, use the `br` cheatsheet.
license: MIT
domain: project-management
role: specialist
scope: operations
output-format: commands
triggers:
  - br
  - beads
  - beads_rust
  - br ready
  - br close
metadata:
  author: Dicklesworthstone
  version: 2.1.0
---

<!-- TOC: Scope | Workflow | Operating Rules | Related -->

# br -- Beads Rust Issue Tracker

Local-first issue tracker. This skill carries only the rules that prevent a
wrong action mid-task — not the command reference. Command shapes, flags, JSON
shapes, and the full gotcha list live in the `br` cheatsheet.

## Scope

`br` tracks issue lifecycles, priorities, dependencies, and ready/blocked state
across one or more `.beads/` trackers: find actionable work, claim and close
issues, manage the dependency graph that gates `br ready`.

Triage method, commit workflow, and cross-agent coordination belong to the
execution, VCS, and coordination skills.

## Workflow

The load-bearing command order (full syntax in the cheatsheet):

1. `br ready` — find unblocked work; `br show <id>` to read the contract.
2. `br update --claim` — claim and move to `in_progress`.
3. `br close --reason` — close with evidence (commit SHA, file, or behaviour).

## Operating Rules

The gotchas that cause a wrong action if not internalized up front:

- **Writes auto-export.** Every mutation writes `issues.jsonl` immediately —
  commit `.beads/` with no flush step. The only manual sync is
  `br sync --import-only` after `git pull` (the pull may bring in JSONL written
  elsewhere). `--flush-only` matters only for bulk triage paired with
  `--no-auto-flush`.
- **JSON shapes are not uniform.** `br ready`/`br blocked` return arrays;
  `br list` returns `{issues, total, ...}`; `br count` returns
  `{groups, total}`. Assuming they match makes `jq` fail silently. Exact
  recipes in the cheatsheet.
- **Cross-tracker routing.** Each tracker owns a prefix (`agents-*`,
  `system-*`). A foreign-prefix ID needs `--db <path>` or a `cd` into the
  owning repo — bare `br show <foreign-id>` queries the wrong DB and reports
  "not found" or a collision.
- **Close reasons are the durable record.** `--reason` holds the outcome and
  evidence — never close without it. If the work is not verifiably done, leave
  a comment instead of closing.
- **Never run bare `bv`.** It launches an interactive TUI that blocks the
  session. Always use `--robot-*` flags (`--robot-next`, `--robot-triage`).
- **No cycles.** `br dep cycles` must return empty — circular dependencies
  break the graph and make `br ready` unreliable.

## Related

- `br` cheatsheet — command shapes, flags, JSON-shape `jq` recipes, full gotcha
  list, storage layout.
- `git-vcs` / `git-change-manage` — commit and session-end workflow.
- `execution-spine` / `supervisor` — triage method and phase management.
