---
name: jj-vcs
description: Canonical Jujutsu (jj) playbook for linear-history workflow, safe change splitting, troubleshooting, and recovery in agent-driven repositories.
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

## Core Mental Model

In `jj`, the working copy is already attached to a change.

That means:
- the current change may already carry workflow meaning before new edits start
- change identity and commit identity are not the same thing
- "finish this work" and "start new work" often mean creating or selecting the right change, not only making a final commit

## Related Skills

When the work happens inside a system with additional meaning attached to the `jj` working copy, use a process skill as well.

Example:
- [`work-unit-manage`](/Users/bear/Me/00-system/agents/skills/work-unit-manage/SKILL.md) provides the abstract lifecycle guidance.
- [`jj-change-manage`](/Users/bear/Me/00-system/agents/skills/jj-change-manage/SKILL.md) provides the concrete `jj` workflow for classifying and managing the current change correctly.
