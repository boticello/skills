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
  version: 2.2.0
---

<!-- TOC: Scope | What this skill does not own | Operating Rules | Related -->

# br -- Beads Rust Issue Tracker

Local-first issue tracker. This skill carries only the rules that prevent a
wrong action mid-task — not the command reference. Command shapes, flags, JSON
shapes, and the full gotcha list live in the `br` cheatsheet.

## Scope

`br` is an adapter for the beads_rust tool: issue records, priorities,
dependencies, ready/blocked state, and the storage/sync model across one or
more `.beads/` trackers. It owns how to operate the tool safely — commands,
flags, JSON shapes, cross-tracker routing, the gotchas that make a command
fail silently or hit the wrong database.

## What this skill does not own

`br` does not own the operational lifecycle. When work is ready, who claims it,
the execution/verification/review sequence, when closure is permitted, and how
phase transitions or handoffs happen are tracker-independent policy. They
belong to the coordination protocol and posture skills (`coordination-protocol`,
`supervisor`, `execution-spine`). The same lifecycle must work if the tracker
underneath changes. `br` supplies the verbs (`ready`, `update --claim`,
`close --reason`); it does not prescribe the order or the gates between them.

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
- **`--reason` is the durable record.** Whatever you close, `--reason` holds the
  outcome and evidence. Whether closure is the right move at a given point —
  whether the work is verified, reviewed, or ready to be closed — is a
  lifecycle decision, not a `br` rule; see `coordination-protocol`. If you are
  not closing, record progress as a comment instead.
- **Never run bare `bv`.** It launches an interactive TUI that blocks the
  session. Always use `--robot-*` flags (`--robot-next`, `--robot-triage`).
- **No cycles.** `br dep cycles` must return empty — circular dependencies
  break the graph and make `br ready` unreliable.

## Related

- `br` cheatsheet — command shapes, flags, JSON-shape `jq` recipes, full gotcha
  list, storage layout.
- `coordination-protocol` — owns the lifecycle this skill defers: readiness,
  claim, execution/review sequence, phase transition, and closure policy.
- `git-vcs` / `git-change-manage` — commit and session-end workflow.
- `execution-spine` / `supervisor` — posture skills that consume the lifecycle.
