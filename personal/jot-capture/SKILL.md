---
name: "jot-capture"
description: "Capture durable notes, observations, reflections, decisions, and progress entries through the me jot workflow."
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

# jot-capture

Use this skill when creating, reviewing, or linking durable jot entries with the `me` CLI.

## Primary commands

- `me jot "text"`
- `me jot -k KIND "text"`
- `me jot -t TICKET ...`
- `me jot --project CODE ...`
- `me jot list`
- `me jot show`

## Purpose

`jot` is the generic capture container for documented information in the `me` system.
The semantic meaning is carried by:
- `kind`
- parent linkage (ticket/project)
- tags
- the surrounding workflow

This skill should therefore treat `jot` as a **generic durable note mechanism**, not as a single note type.

## Current kinds

Use the existing kinds deliberately:
- `note`
- `reflection`
- `observation`
- `idea`
- `decision`
- `design-brief`
- `spec`
- `progress`

## Workflow

1. Clarify what kind of durable note is needed.
2. Decide whether it should be standalone or linked to a ticket/project.
3. Prefer linking the jot when it records intent, progress, decisions, or reflections about a tracked workstream.
4. Choose the smallest appropriate `kind`.
5. Capture concise, durable text rather than chat-like rambling.
6. If relevant, suggest how the jot should influence follow-up work or future recall.

## Decision rules

- Use `observation` for noticed facts or patterns.
- Use `reflection` for interpretation, lessons, or retrospective meaning.
- Use `decision` when something has been chosen and should be remembered.
- Use `progress` for durable workflow updates tied to ongoing work.
- Use `design-brief` or `spec` when the jot is intended to guide future implementation.
- Link to a ticket or project when the jot belongs to a concrete workstream.
- Prefer linked jots when the note is meant to serve as part of the audit trail or session handover.
- Use standalone jots when the note is broadly useful beyond any single work item.

## Good patterns

```bash
me jot "Quick thought"
me jot -k observation "There is a recurring split between domain and activity naming."
me jot -k reflection -t 120 "Review workflows need dedicated CLI support rather than ad hoc queries."
me jot -k decision --project P0121 "Use entity-activity naming for the canonical skill taxonomy."
me jot list -k reflection
```

## Output pattern

When acting, report:
- what kind of jot you are capturing or reviewing
- whether it is standalone or linked
- why that kind is appropriate
- whether it serves audit trail, reflection, handover, or general memory purposes
- any follow-up action or retrieval suggestion if useful
