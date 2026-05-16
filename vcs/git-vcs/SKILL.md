---
name: git-vcs
description: Canonical Git playbook for branch-based linear-history workflow, safe staging, inspection, and recovery in agent-driven repositories.
---

# git-vcs

## Purpose

This is the shared `git` tool-adapter skill.

Use it to understand:
- what `git` state means
- how to inspect and manipulate that state safely
- which habits are safe in a linear-history, agent-driven workflow

This skill is the shared command and affordance layer.

Use [`git-change-manage`](/Users/bear/Me/00-system/agents/skills/git-change-manage/SKILL.md) when you need the concrete workflow for managing a work unit in a `git`-centric repo or harness.

## Scope

This skill covers:
- generic `git` command usage
- working tree and index semantics
- linear-history expectations
- safe inspection and recovery patterns

It does not by itself define:
- how a particular project wants branches named
- how tickets or PRs relate to a branch
- when a team considers a work unit review-ready

## Core Mental Model

In `git`, the relevant layers are:
- branch or worktree: the current line of work
- working tree: unstaged file changes
- index: the selected diff to be committed
- commit history: the durable record of completed slices

Use this model deliberately.

The index is not just an implementation detail. It is part of how a coherent work unit is shaped.

## Core Rules

- Always run `git status --short --branch` before mutating `git`.
- Keep history linear unless the repo explicitly says otherwise.
- Stage deliberately. Do not use `git add .` blindly.
- Prefer explicit paths or `git add -p` when shaping a commit.
- Avoid destructive commands such as `git reset --hard`, `git checkout --`, or `git clean -fd` unless explicitly asked.
- Never mutate `git` in parallel in the same working copy.
- Never fetch, pull, push, or force-push unless explicitly asked.

## Safe Inspection

Useful commands:

```bash
git status --short --branch
git branch --show-current
git diff
git diff --cached
git log --oneline -n 10
```

Inspect first. Act second.

## Safe Shaping

Useful commands:

```bash
git add path/to/file
git add -p
git restore --staged path/to/file
git restore path/to/file
git commit -m "..."
git rebase <base>
```

Prefer small, intentional commits over large end-of-session dumps.

## Recovery

Start with inspection:

```bash
git status
git log --oneline --graph -n 20
git reflog -n 20
```

If recovery is needed, prefer the least destructive option and explain the plan before mutating history.

## Related Skills

- [`work-unit-manage`](/Users/bear/Me/00-system/agents/skills/work-unit-manage/SKILL.md) for the abstract work-unit lifecycle
- [`git-change-manage`](/Users/bear/Me/00-system/agents/skills/git-change-manage/SKILL.md) for the concrete `git` workflow
