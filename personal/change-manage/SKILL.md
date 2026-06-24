---
name: "change-manage"
description: "Interpret and manage jj working-copy state correctly in the me-system workflow, without importing git assumptions."
alwaysAllow:
  - Bash
requiredSources:
  - me-cli-files
  - system-files
---

# change-manage

Use this skill whenever work touches a jj-managed repository in the `~/Me` system, especially `me-cli`.

## Purpose

This skill prevents git-brain errors. In this workflow, the existence of a jj working-copy change does **not** by itself mean work is unfinished.

Agents must classify the working-copy state correctly before editing.

## Core mental model

- jj is **not** git.
- There is no staging area.
- There are no “uncommitted changes” in the git sense.
- The working copy **is** a change.
- A finished change may still be the current working-copy change until the next agent starts the next change.

## Mandatory procedure

Before starting work in a jj repo:

1. Run `jj st`
2. Read the current change description
3. Identify the linked `Ticket:` line if present
4. Check the ticket status with `me tk show <id> --json` when applicable
5. If the intended work is substantial and not already represented, create or identify the ticket before creating a new change
6. Classify the change state
7. Only then decide whether to continue or create a new change
8. When creating a new change, include the ticket linkage and planned work explicitly in the description

## Canonical change states

### Finished change
Criteria:
- working copy has files
- description reflects completed work
- linked ticket is done

Action:
- create a **new jj change** before starting new work

### Active change
Criteria:
- working copy has files
- description reflects current/planned work
- linked ticket is open or in progress

Action:
- continue only if the intended work belongs to that change

### Ready planned change
Criteria:
- working copy has no files
- description contains the planned work

Action:
- implement the described plan

## Key rule

**Do not interpret “working copy exists” as “unfinished work exists”.**
The deciding signals are:
- description meaning
- linked ticket status
- whether the description reflects completed work or planned work

## Red flags

- saying “uncommitted changes” or “staging”
- editing a finished change without creating a new one
- starting work without checking ticket linkage
- assuming modified files alone determine the state
- mixing unrelated work into the current change

## Good patterns

```bash
cd /Users/bear/Me/00-system/me-cli
jj st
jj log --limit 5
me tk show 120 --json
jj new -m "Implement review-run skill integration\n\nTicket: 120\n\nPlan: ..."
me tk note 120 "Started implementation in a new jj change for review-run integration."
```

## Relationship to reflection

This skill governs **change-boundary discipline**, not the whole implementation lifecycle.

Its job is to ensure that code work starts from the correct jj state and the correct ticket anchor.
Once a clean change boundary exists, broader implementation and reflection procedure belongs with the build workflow.

In particular, post-debug self-audit is **not** primarily owned by this skill.
If work moves into implementation and a real debugging or correction loop occurs, that self-audit belongs with the implementation-oriented skill governing the build slice.

## Output pattern

When reporting, explicitly say:
- how you classified the current change
- why
- whether you are continuing it or creating a new one
- what ticket the change belongs to
- whether the ticket trail has been updated or still needs updating
- whether the repo is now at a clean boundary for implementation work
