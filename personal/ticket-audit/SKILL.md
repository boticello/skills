---
name: "ticket-audit"
description: "Run focused ticket audit and backlog-hygiene passes over ticket state, drift, priorities, and next actions using the me CLI."
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

# ticket-audit

Use this skill for focused audit sessions over ticketed work.

## Relationship To `orientate`

This is the narrower ticket-audit skill.

Use [`orientate`](/Users/bear/Me/00-system/agents/skills/orientate/SKILL.md) when the session needs broader orientation across:
- projects
- jots and reflections
- domain context
- emerging system gaps

Use `ticket-audit` when the question is mainly about the ticket system itself.

## Primary commands

- `me tk list`
- `me tk show`
- `me search`
- `me jot`

## Purpose

This skill supports ticket audit and backlog hygiene rather than just ticket mutation. It helps surface drift, stale items, missing structure, unclear priorities, and next actions inside the ticket layer.

## Audit questions

During audit, look for:
- stale open items
- overgrown or ambiguous tickets
- missing notes/progress context
- tickets lacking clear domain or path
- items that should be paused, maybe, done, split, or linked
- clusters suggesting a missing higher-level capability or routine

## Workflow

1. Start with a focused list or slice of tickets.
2. Inspect notable tickets in more detail.
3. Group findings into patterns, not just isolated comments.
4. Recommend a small number of concrete actions.
5. Record important audit observations in notes/jots when appropriate.

## Decision rules

- Do not churn statuses unnecessarily.
- Prefer surfacing patterns and decisions over making a long list of trivial edits.
- If an audit uncovers a missing system capability, say so explicitly.
- Use `me jot` for reflections that should survive beyond the session.
- Keep this audit centered on ticket state and ticket structure.
- If the session needs wider orientation across projects, narrative, reflections, or domain direction, widen into [`orientate`](/Users/bear/Me/00-system/agents/skills/orientate/SKILL.md).

## Typical commands

```bash
me tk list --status open
me tk list --domain 00-system
me tk show 84 120
me search "review rhythm"
me jot -k reflection "Audit finding: several tickets imply a missing review capability layer."
```

## Output pattern

A good audit output should include:
- scope audited
- ticket slice audited
- key patterns found
- highest-value ticket actions
- any durable note or follow-up recommended
