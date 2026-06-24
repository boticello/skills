---
name: "shopping-manage"
description: "Manage shopping items, sources, and locations through the me CLI."
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

# shopping-manage

Use this skill when managing shopping items, sources, categories, or locations with the `me` CLI.

## Primary commands

- `me shop`
- `me source`
- `me location`

## Purpose

This skill provides a consistent workflow for shopping-list work across items, places to buy from, and physical context.

## Operating model

Three command families work together:
- `me shop` — items to buy
- `me source` — named places or source categories
- `me location` — where you are and location hierarchy

Key idea: shopping is **contextual**. Current location affects which items are useful to surface.

## Workflow

1. Inspect the current state first (`me shop list`, `me source list`, `me location here`).
2. Clarify whether the user wants to:
   - add an item
   - review open items
   - record a purchase
   - adjust sources/categories
   - set or inspect location
3. Use the smallest `me` command that performs the required change.
4. Summarise the resulting state clearly.
5. Suggest the next relevant action if useful.

## Decision rules

- Use `--source` only when a specific source is known and meaningful.
- If an item is generic or the source is uncertain, omit source and add it later.
- Use `urgent`, `need`, `want`, `wishlist` carefully — they are action signals, not just labels.
- If the current location might change the result, check `me location here` and mention it.

## Key behaviours to remember

- Current location may automatically affect `me shop list`.
- Sources must exist before using them on `me shop add --source`.
- `me source add` creates a source when given a location; otherwise it acts more like category creation.
- Sourceless items are broadly visible.

## Typical commands

```bash
me location here
me shop list
me shop add "item" --priority need
me shop buy 3 --cost 12.99
me source add "Amazon" --is-a "Online retailer" --location Online
```

## Output pattern

When acting, report:
- what you inspected
- what changed
- any context assumptions (especially location)
- useful follow-up options
