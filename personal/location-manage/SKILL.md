---
name: "location-manage"
description: "Create, inspect, and set hierarchical locations and current-location context through the me CLI."
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

# location-manage

Use this skill when managing locations or current-location state in the `me` system.

## Primary commands

- `me location add`
- `me location list`
- `me location show`
- `me location here`

## Purpose

Locations provide hierarchical physical or contextual place information such as `Ledbury`, `Herefordshire`, `UK`, or `Online`. They support context-sensitive workflows such as shopping and, in future, task selection.

## Workflow

1. Inspect current locations when duplication or hierarchy matters.
2. Clarify whether the user wants to:
   - create a location
   - define a parent/child relationship
   - inspect a location
   - get/set/clear the current location
3. Use the direct `me location` command.
4. Summarise both the hierarchy and the practical effect of the change.

## Decision rules

- Prefer stable, recognisable place names.
- Use `--within` to build hierarchy deliberately.
- Treat `Online` as a valid location when it supports workflow logic.
- Mention current-location effects when they may alter later commands such as shopping lists.

## Good patterns

```bash
me location list
me location add "Online"
me location add "Herefordshire" --within UK
me location add "Ledbury" --within Herefordshire
me location show "Ledbury"
me location here Ledbury
me location here --clear
```

## Output pattern

When acting, report:
- what location structure you inspected or changed
- whether current location changed
- what downstream workflows this is likely to affect
