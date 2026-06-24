---
name: "source-manage"
description: "Create, inspect, and categorise sources and source categories through the me CLI."
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

# source-manage

Use this skill when managing named sources and source categories in the `me` system.

## Primary commands

- `me source add`
- `me source list`
- `me source show`
- `me source tag`

## Purpose

Sources represent named places or entities such as Amazon, Aldi, or a category like Supermarket. This skill helps manage those entities and their category memberships.

## Core distinction

`me source add` does two related but different things:
- with `--location` it creates a **source**
- without `--location` it creates a **category-like source taxonomy entry**

Agents should be explicit about which one they are creating.

## Workflow

1. Inspect existing sources/categories when duplication is possible.
2. Clarify whether the user wants:
   - a new source
   - a new category
   - new category membership for an existing entry
   - inspection of an existing source
3. Use the smallest command that performs the change.
4. Summarise the resulting structure clearly.

## Decision rules

- Use a source for a named place/entity you can buy from or relate to directly.
- Use category membership to express type/class rather than creating duplicate entities.
- Prefer clear, stable names.
- If physical context matters, pair this skill with `location-manage`.

## Good patterns

```bash
me source list
me source add "Supermarket"
me source add "Amazon" --is-a "Online retailer" --location Online
me source tag "Aldi" --is-a "Pharmacy"
me source show "Amazon"
```

## Output pattern

When acting, report:
- whether you created/inspected a source or category
- what category memberships exist or changed
- any useful related location implications
