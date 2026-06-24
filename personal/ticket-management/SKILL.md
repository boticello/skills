---
name: "ticket-manage"
description: "Create, inspect, update, and relate tickets through the me CLI with clear workflow state and durable notes."
alwaysAllow:
  - Bash
requiredSources:
  - system-files
---

# ticket-manage

Use this skill when managing actionable work in `me tk`.

## Primary commands

- `me tk create`
- `me tk list`
- `me tk show --json`
- `me tk start`
- `me tk pause`
- `me tk done`
- `me tk maybe`
- `me tk reopen`
- `me tk edit`
- `me tk note`
- `me tk dep`
- `me tk link`
- `me tk parent`

## Purpose

This skill provides a disciplined workflow for ticket-based work so that tasks, process items, audits, and chores have clear state and durable supporting notes.

## Workflow

1. Inspect first when the current state matters.
2. Clarify whether the user wants to create, review, update, transition, or relate tickets.
3. Use the smallest command that performs the intended change.
4. Record meaningful progress or decisions with `me tk note`.
5. Summarise outcome and next possible actions.

## Closing a ticket

When a ticket's work is complete and committed:

1. Ensure at least one commit exists with `Refs #<id>` in the message.
2. Record the commit SHA in a closing progress note. Use `--file` for longer notes:
   ```
   me tk note <id> --file /tmp/closing-note.md
   ```
3. Close the ticket:
   ```
   me tk done <id>
   ```
   Or combine note and closure:
   ```
   me tk done <id> --file /tmp/closing-note.md
   ```
4. If the work is in a CLI repo and changed the command surface, rebuild the gem:
   ```
   script/install-global --force
   ```
5. If the change is user-visible, create a release-note jot.

Never close a ticket without recording the commit SHA. See `docs/governance/ticket-commit-workflow.md` for the full procedure.

## Decision rules

- Use tickets for actionable work, not for general reference material.
- Use notes for progress, decisions, design briefs, and important observations tied to the work.
- Use dependencies, parent/child links, and related links deliberately; do not over-link casually.
- When status changes, explain the workflow meaning if it is relevant.

## Good patterns

```bash
me tk list --status open
me tk show 120 --json
me tk create "Review something" -k task -p 2 -s s --path 00-system/me-cli
me tk start 120
me tk note 120 "Progress: reviewed command surface and identified gaps."
me tk done 120
```

## Output pattern

When acting, report:
- what ticket state you inspected
- what changed
- why that status or structure makes sense
- what follow-up work is now available


//


```
me tk show <X> --json
```

Read the contract and all notes before writing code. Then:

1. Check for parent ticket and linked dependencies (`me tk tree <X>`).
2. Pull any referenced docs or skills.
3. `me tk start <X>` to set status to in_progress.
4. Implement the smallest change that makes the contract true.
5. Record progress notes as you go (`me tk note <X> "<text>" --kind progress`).

Read more:
- [`skills/ticket-manage/SKILL.md`](skills/ticket-manage/SKILL.md)
- [`skills/me-feature-build/SKILL.md`](skills/me-feature-build/SKILL.md)

## Coding
- Working on a feature, refactor or bug : [`skills/ticket-manage/CLI.md`](Follow the CLI ticket management workflow)

`me tk new "<title>" --kind <kind> --size <size> --json --file /tmp/desc.md`


Read more:
- [`skills/ticket-manage/SKILL.md`](skills/ticket-manage/SKILL.md)
- [`docs/reference/ticket-sizing-rubric.md`](docs/reference/ticket-sizing-rubric.md)


///

### Completing a ticket

1. Commit with `Refs #<id>` in the message.
2. Record the commit SHA in a closing progress note (`me tk done <id> --file /tmp/closing-note.md`).
3. If the CLI command surface changed, rebuild the gem (`script/install-global --force` in the CLI repo).
4. If the change is user-visible, create a release-note jot.


///



Read more:
- [`docs/governance/ticket-commit-workflow.md`](docs/governance/ticket-commit-workflow.md)
- [`skills/ticket-manage/SKILL.md`](skills/ticket-manage/SKILL.md)
- [`skills/me-feature-build/SKILL.md`](skills/me-feature-build/SKILL.md)
