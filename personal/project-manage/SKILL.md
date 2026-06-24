---
name: "project-manage"
description: "Create, inspect, update, and relate projects through the me CLI with clear lifecycle handling."
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

# project-manage

Use this skill when managing projects in the `me` system.

## Primary commands

- `me proj create`
- `me proj list`
- `me proj show`
- `me proj update`
- `me proj note`
- `me proj start`
- `me proj pause`
- `me proj maybe`
- `me proj done`
- `me proj abandon`
- `me proj parent`
- `me proj children`
- `me proj link`

## Purpose

Projects are larger, more durable containers for coordinated work than tickets. This skill helps create and manage them with clear lifecycle state, structure, and relationship to tickets.

## Workflow

1. Inspect the current project state first when needed.
2. Clarify whether the user wants to:
   - create a new project
   - review or update a project
   - change lifecycle state
   - add notes
   - relate tickets
   - create hierarchy (parent/child)
3. Use the project commands directly.
4. Summarise both the structural and workflow implications of the change.

## Decision rules

- Use a project when the work has enduring identity, multiple moving parts, or likely related tickets.
- Use tickets for discrete actionable work within or around a project.
- Use notes for durable commentary, rationale, or progress.
- Be careful with lifecycle states: `active`, `paused`, `maybe`, `completed`, `abandoned` carry real meaning.
- Link tickets to projects when the relationship will help review and navigation.

## Good patterns

```bash
me proj list
me proj show P0121
me proj create "Review support in me-cli" --domain 00 --type build
me proj start P0121
me proj note P0121 "Need to connect review support to rhythm system and ticket context."
me proj link P0121 120
```

## Output pattern

When acting, report:
- what project state you inspected
- what changed
- how the project now sits in the broader workflow
- any next ticketing or review implications
