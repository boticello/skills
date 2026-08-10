---
name: jj-change-manage
description: Manage a coherent unit of work in Jujutsu by classifying the current working-copy change correctly, deciding when to reuse or create a new change, and closing work cleanly.
triggers:
  - Jujutsu work unit
  - jj change
  - jj workspace
  - manage a jj change
  - Jujutsu workflow
---

# jj-change-manage

Use this skill whenever work happens in a `jj`-managed repository and the current change must be interpreted correctly before editing.

## Relationship To The Wider Stack

This is not the generic `jj` command-surface skill.

Use:
- `work-unit-manage` for the abstract lifecycle of a work unit
- `jj-vcs` for safe `jj` command usage and mental models

This skill adds the concrete `jj` workflow:
- how to classify the current working-copy change
- when to continue an existing change versus create a new one
- how to avoid importing git reflexes into a `jj` workflow

## Purpose

This skill prevents git-brain errors in `jj` workflows.

In `jj`, the existence of a working-copy change does **not** by itself mean work is currently active or unfinished.

Agents must classify the current change correctly before editing.

## Core mental model

- The generic `jj` rules come from `jj-vcs`.
- In `jj`, the working copy is already attached to a change.
- A finished change may still be the current working-copy change until the next work unit is created.
- Modified files alone do not tell you whether the current change is the right place for the requested work.

## Mandatory procedure

Before starting work in a jj repo:

1. Run `jj st`
2. Inspect the current change with `jj log -r @`
3. Read the current change description
4. Classify the current change state
5. Only then decide whether to continue or create a new change
6. If the surrounding system uses external linkage such as tickets, plans, or reviews, inspect that linkage before deciding
7. When creating a new change, describe the planned work explicitly

## Canonical change states

### Finished change
Criteria:
- working copy has files
- description reflects completed or unrelated work

Action:
- create a **new jj change** before starting new work

### Active change
Criteria:
- working copy has files
- description reflects current/planned work

Action:
- continue only if the intended work belongs to that change

### Ready planned change
Criteria:
- working copy has no files
- description contains the planned work

Action:
- implement the described plan

### Ambiguous or inherited change
Criteria:
- current description does not clearly match the intended work
- the change may belong to an earlier session or a different unit of work

Action:
- stop and classify before editing
- if the intent differs, create a new change

## Key rule

**Do not interpret “working copy exists” as “unfinished work exists”.**
The deciding signals are:
- description meaning
- external linkage when present
- whether the description reflects completed work, planned work, or unrelated work

## Red flags

- saying “uncommitted changes” or “staging”
- editing a finished or unrelated change without creating a new one
- treating the current change as correct without reading its description
- assuming modified files alone determine the state
- mixing unrelated work into the current change

## Good patterns

```bash
cd /Users/bear/Me/00-system/me-cli
jj st
jj log --limit 5
jj new -m "Implement orientate skill integration\n\nTicket: 120\n\nPlan: ..."
```

## Output pattern

When reporting, explicitly say:
- how you classified the current change
- why
- whether you are continuing it or creating a new one
- what external linkage matters, if any
- whether follow-up or adjacent work should become a separate change
