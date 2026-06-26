---
name: "orientate"
description: "Run broader orientation sessions across tickets, projects, jots, and domain context to surface drift, next actions, and missing system support."
alwaysAllow:
  - Bash
requiredSources:
  - system-files
exclude_tools:
  - claude_code
  - codex
  - opencode
  - pi

---

# orientate

Use this skill for broader orientation sessions across the `me` system.

## Relationship To `br` audit

This is the broader orientation skill.

Use the [`br`](tools/br) issue tracker's audit surface (`br ready`, `br blocked`, `br stale`, `br lint`) for:
- focused ticket audit
- backlog hygiene
- ticket-state diagnosis

Use [`system-self-care`](/Users/bear/Me/00-system/agents/skills/system-self-care/SKILL.md) when the job is maintenance of the governance memory system itself.

Use `orientate` when the orientation question is larger:
- where are we in this domain?
- what are tickets, projects, jots, and recent signals pointing toward?
- what is drifting or missing across the system, not only inside the ticket list?

## Primary commands

- `me tk list`
- `me tk show`
- `me proj list`
- `me proj show`
- `me jot list`
- `me jot show`
- `me search`

## Purpose

This skill provides the broader orientation workflow before dedicated `me` orientation support exists. It helps identify drift, stale work, missing structure, narrative direction, and the next highest-value actions.

## Orientation lenses

An orientation pass may focus on one or more of:
- open tickets
- a domain (`00-system`, `30-personal`, etc.)
- active or stalled projects
- recent reflections/observations
- missing context, unclear status, or neglected maintenance
- structural gaps suggesting a needed new capability

## Workflow

1. Define the scope of the orientation pass.
2. Create or identify a ticket when the pass is a substantial session, recurring orientation practice, or part of tracked system work.
3. Pull the source sets needed for that scope: tickets, projects, jots, and any other relevant context.
4. Use [`br`](tools/br) audit commands (`br ready`, `br blocked`, `br stale`, `br lint`) explicitly when ticket audit is one orientation lens rather than the whole job.
5. Inspect notable items in detail.
6. Look for cross-source patterns, not just isolated ticket comments.
7. Summarise findings into a small number of clear actions or decisions.
8. Record durable insights in jots or ticket notes where helpful.
9. Close the loop by recording orientation outcomes in the ticket or a durable jot if the pass should inform future sessions.

## Common patterns to surface

- stale open work
- clusters that should become a routine or project
- repeated friction suggesting missing CLI support
- work lacking path/domain/context
- tickets that should be paused, maybe, linked, or split
- useful reflections that are not yet captured durably

## Decision rules

- `orientate` should reduce ambiguity and improve orientation, not just produce a long list.
- Prefer a few high-leverage actions over many low-value tweaks.
- Use a ticket when the orientation pass itself is part of tracked work, not only when it creates follow-up actions.
- If the pass reveals a system design gap, say so explicitly.
- Use `me jot` for reflections that should survive beyond the session.
- Use ticket notes for orientation scope, major findings, and chosen follow-up when the pass is part of an auditable workstream.
- If the task is only ticket audit or backlog hygiene, use [`br`](tools/br) audit commands (`br ready`, `br stale`, `br lint`) instead of widening into a full `orientate`.
- If the task is about tending drift, boundaries, and corpus health inside the governance memory system, use [`system-self-care`](/Users/bear/Me/00-system/agents/skills/system-self-care/SKILL.md).

## Good patterns

```bash
me tk list --status open
me proj list --status active
me jot list -k reflection -n 10
me tk show 84 120
me search "review rhythm"
me jot -k reflection "Orientation finding: current workflows need stronger orientation-mode support."
```

## Output pattern

A good orientation output should include:
- scope covered
- orientation lenses used
- ticket context (existing, created, or recommended)
- key patterns found
- highest-value next actions
- durable notes recommended, captured, or written back to the ticket
