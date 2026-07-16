---
name: br
description: >-
  Use when creating issues, triaging backlogs, managing dependencies, or
  finding ready work with `br` (beads_rust). Defines the minimal operating
  rules an agent needs mid-task: the auto-export sync model, cross-tracker
  routing, and the commands that fail silently. For command shapes, flags,
  and JSON shapes, use the `br` cheatsheet.
license: MIT
domain: project-management
role: specialist
scope: operations
output-format: commands
triggers:
  - br
  - beads
  - beads_rust
  - issue tracker
  - issue triage
  - backlog
  - dependencies
  - ready work
metadata:
  author: Dicklesworthstone
  version: 2.0.0
---

<!-- TOC: Scope | Required Workflow | Operating Rules | Related -->

# br -- Beads Rust Issue Tracker

`br` is the local-first issue tracker. This skill carries only the operating
rules that prevent a wrong action mid-task — not the command reference. For
exact command shapes, flags, JSON shapes, and the full gotcha list, consult
the `br` cheatsheet.

## Scope

`br` tracks issue lifecycles, priorities, dependencies, and ready/blocked
state across one or more `.beads/` trackers. Use it to find actionable work,
claim and close issues, and manage the dependency graph that gates `br ready`.

How and when to triage, commit, or coordinate across agents belongs to the
execution, VCS, and coordination skills — not here. This skill owns `br`
operation only.

## Required Workflow

The load-bearing order, by command name (full syntax in the cheatsheet):

1. `br ready` — find unblocked work; `br show <id>` to read the contract.
2. `br update --claim` — claim and move to `in_progress`.
3. Do the work.
4. `br close --reason` — close with evidence (commit SHA, file, or behaviour).
5. Commit `.beads/` — the JSONL is already current (see Operating Rules).

## Operating Rules

These are the gotchas that cause a *wrong action* (not just a forgotten flag)
if an agent doesn't internalize them on the way in:

- **Writes auto-export.** Every mutation writes `issues.jsonl` immediately.
  Commit `.beads/` directly — no flush step. The only manual sync is
  `br sync --import-only` **after `git pull`** (the pull may bring in JSONL
  written elsewhere). `--flush-only` earns its keep only for bulk triage
  paired with `--no-auto-flush`.
- **JSON shapes are not uniform.** `br ready`/`br blocked` return **arrays**;
  `br list` returns `{issues, total, ...}`; `br count` returns
  `{groups, total}`. Assuming they match makes `jq` fail silently. Exact
  recipes live in the cheatsheet.
- **Cross-tracker routing.** Each tracker owns a prefix (e.g. `agents-*`,
  `system-*`). A foreign-prefix ID needs `--db <path>` or a `cd` into the
  owning repo — bare `br show <foreign-id>` looks in the wrong DB and reports
  "not found" (or worse, a collision).
- **Close reasons are the durable record.** `--reason` is where the outcome
  and evidence live. Don't close without it; if you're unsure the work is
  verifiably done, leave a comment instead of closing.
- **Never run bare `bv`.** It launches an interactive TUI that blocks the
  session. Always use `--robot-*` flags (`--robot-next`, `--robot-triage`).
- **No cycles.** `br dep cycles` must return empty — circular dependencies
  break the graph and make `br ready` unreliable.

## Related

- `br` cheatsheet — command shapes, flags, JSON-shape `jq` recipes, full
  gotcha list, and storage layout. This is the primary reference.
- `git-vcs` / `git-change-manage` — how to commit and end a session (the
  `.beads/` commit follows the same rules as any other).
- `execution-spine` / `supervisor` — triage method and phase management.
