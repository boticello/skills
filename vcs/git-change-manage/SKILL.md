---
name: git-change-manage
description: Manage a coherent unit of work in Git by choosing the right branch or worktree, keeping staging intentional, and closing with a coherent commit history.
---

# git-change-manage

Use this skill whenever work happens in a `git`-managed repository and the agent needs to manage the lifecycle of a branch-based work unit cleanly rather than improvising at the end.

## Relationship To The Wider Stack

Use:
- [`work-unit-manage`](/Users/bear/Me/00-system/agents/skills/work-unit-manage/SKILL.md) for the abstract lifecycle of a work unit
- [`git-vcs`](/Users/bear/Me/00-system/agents/skills/git-vcs/SKILL.md) for safe `git` command usage and mental models

This skill adds the concrete `git` workflow:
- how to classify the current branch or worktree
- when to keep working where you are versus switch or create fresh context
- how to shape staged and committed state so the work unit remains coherent

## Purpose

This skill prevents end-of-session commit chaos in `git`-centric repos and harnesses.

It is for moments when the agent would otherwise drift into:
- "I'll just commit everything at the end"
- "this branch is probably fine"
- "staging is optional"

## Core Mental Model

- The generic `git` rules come from [`git-vcs`](/Users/bear/Me/00-system/agents/skills/git-vcs/SKILL.md).
- In `git`, the branch or worktree usually carries the unit-of-work context.
- The working tree is in-progress state.
- The index is the selected diff for the next commit.
- Commits are intentional boundaries, not an afterthought.

## Mandatory Procedure

Before starting work in a `git` repo:

1. Run `git status --short --branch`
2. Check the current branch with `git branch --show-current`
3. Inspect recent history with `git log --oneline -n 5` when the context is not obvious
4. Classify the current branch or worktree state
5. Only then decide whether to continue, switch, or create fresh context
6. If the surrounding system uses ticket, PR, or review linkage, inspect that linkage before deciding

## Canonical Work-Unit States

### Active branch
Criteria:
- current branch clearly matches the intended work
- any local changes belong to that work

Action:
- continue, but keep staging and commits disciplined

### Clean ready branch
Criteria:
- current branch matches the intended work
- working tree is clean

Action:
- continue in place

### Dirty unrelated branch
Criteria:
- local changes exist
- they do not belong to the intended work unit

Action:
- do not pile more work onto it
- switch, branch, or otherwise establish clean context first

### Wrong branch or detached state
Criteria:
- current branch does not match the intended work
- or repository state is ambiguous for continued work

Action:
- establish the correct work unit before editing

## Work Phase Rules

- Keep one coherent intent per branch-level work unit.
- Stage intentionally with explicit paths or `git add -p`.
- Use commits to preserve meaningful boundaries, not only as a final cleanup step.
- Do not hide scope drift inside a large staged diff.
- If a new issue is discovered, capture it separately instead of widening the current unit.

## End Phase Rules

- Inspect both unstaged and staged diffs before committing.
- Ensure the commit or small commit sequence reflects one coherent outcome.
- Leave the branch understandable to the next person or next session.
- Make follow-up work explicit instead of bundling it in "while I'm here" edits.

## Red Flags

- "Just commit everything"
- `git add .` without understanding the diff
- treating the branch as correct without checking it
- using staging as an afterthought instead of a shaping tool
- mixing unrelated fixes into the same commit history

## Good Patterns

```bash
git status --short --branch
git branch --show-current
git log --oneline -n 5
git diff
git add -p
git diff --cached
git commit -m "Implement review-mode preflight checks"
```

## Output Pattern

When reporting, explicitly say:
- how you classified the current branch or worktree
- whether you are continuing, switching, or creating fresh context
- how you are shaping staged and committed state
- what follow-up work should become its own branch, commit, or ticket
