---
name: jj-vcs
description: Canonical Jujutsu (jj) playbook for linear-history workflow, safe change splitting, troubleshooting, and recovery in agent-driven repositories.
triggers:
  - jj status
  - jj diff
  - jj log
  - jj restore
  - Jujutsu
---

# Jujutsu (jj) Playbook

## Purpose

This is the shared `jj` tool-adapter skill.

Use it to understand:
- what `jj` is doing
- how to manipulate changes safely
- what commands and habits are safe in a linear-history workflow

This skill is the shared core.

Contextual process skills may layer on top of it. For example, a domain-specific skill may add ticket linkage, repo-specific workflow rules, or change-state interpretation on top of the generic `jj` rules.

## Scope

Use `jj` only for version control. Do not use git commands for normal history editing.

This skill covers:
- generic `jj` command usage
- safe change manipulation
- linear-history expectations
- the `jj` mental model of changes and working-copy state

It does not by itself define domain-specific workflow semantics such as:
- how ticket state relates to the working copy
- when a working-copy change should be treated as finished in a particular system
- how a specific repo or project encodes linkage in change descriptions

## Core Rules

- Always run `jj status` before mutating `jj`.
- Keep history linear.
- Use sequential `jj commit <paths>` to split mixed work.
- Use `jj restore --from @- <path>` to remove paths from the current change.
- Never use `jj split`.
- Never use `jj file untrack`.
- NEVER run `jj` commands in parallel.
- Never create sibling changes unless explicitly asked.
- Never fetch or sync remote state unless explicitly asked.

## When to Record a Local Save-Point

When a scoped jj work unit has passed its acceptance checks, record the local
change using the repository's jj workflow; no separate approval is needed for
each local save-point under the adopted work-unit policy. Keep the change
within the ticket or explicit request's scope and inspect the resulting
description and diff.

This local rule does not authorise remote synchronisation, landing, deployment,
or publication. Those remain separate actions requiring explicit user approval.

## Core Mental Model

In `jj`, the working copy is already attached to a change.

That means:
- the current change may already carry workflow meaning before new edits start
- change identity and commit identity are not the same thing
- "finish this work" and "start new work" often mean creating or selecting the right change, not only making a final commit

## Agent Wrapper Functions

The following `jj-agent-*` shell functions wrap common jj operations
for agent workflows. Use these when available; they enforce the core
rules above and provide consistent output.

| Function | Purpose | Usage |
|---|---|---|
| `jj-agent-branch` | Create or switch branches | `jj-agent-branch feature-x` |
| `jj-agent-commit` | Commit with structured message | `jj-agent-commit "FEAT: add auth"` |
| `jj-agent-commit-files` | Commit specific files only | `jj-agent-commit-files "FIX: typo" src/main.rs` |
| `jj-agent-commit-interactive` | Interactive file selection | `jj-agent-commit-interactive "REFACTOR: split"` |
| `jj-agent-wip` | Mark work-in-progress checkpoint | `jj-agent-wip "WIP: halfway through"` |
| `jj-agent-log` | Show recent change log | `jj-agent-log` |
| `jj-agent-log-prefix` | Show log with change prefix | `jj-agent-log-prefix abc123` |
| `jj-agent-abandon` | Abandon current or specified change | `jj-agent-abandon` or `jj-agent-abandon @-` |
| `jj-agent-compare` | Compare two changes | `jj-agent-compare @ @-` |
| `jj-agent-cleanup` | Clean up stale branches/changes | `jj-agent-cleanup` |
| `jj-agent-restore` | Restore files from a prior change | `jj-agent-restore --from @- src/foo.rs` |
| `jj-agent-test` | Run tests against current change | `jj-agent-test` |

**Mandatory:** when a `jj-agent-*` function exists for an operation, use
it instead of the raw `jj` command. The wrappers enforce safety rules
(parallel prevention, linear history, structured messages).

## Recovery Patterns

When work goes wrong, prefer recovery over history rewriting:

1. **Wrong files committed:** Use `jj commit <paths>` to split into
   sequential commits (never `jj split`).
2. **Need to undo last change:** Use `jj restore --from @-` to remove
   paths, then recommit correctly.
3. **Abandoned approach:** Use `jj-agent-abandon` to discard, then
   start fresh with `jj new`.
4. **Need to inspect prior state:** Use `jj-agent-log` to find the
   change, then `jj diff -r <change>` to inspect.

## Related Skills

When the work happens inside a system with additional meaning attached to the `jj` working copy, use a process skill as well.

Example:
- `work-unit-manage` provides the abstract lifecycle guidance.
- `jj-change-manage` provides the concrete `jj` workflow for classifying and managing the current change correctly.
- `execution-spine` provides the tool-agnostic execution loop.
