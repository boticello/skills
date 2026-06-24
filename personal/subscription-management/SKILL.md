---
name: "subscription-manage"
description: "Manage subscriptions, renewals, costs, and related notes through the me CLI."
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

# subscription-manage

Use this skill when managing subscriptions, recurring payments, or renewal reviews with the `me` CLI.

## Primary commands

- `me sub`
- `me source`

## Purpose

This skill gives a consistent way to inspect, create, update, pause, resume, cancel, and review subscriptions.

## Workflow

1. Inspect first when the current state matters (`me sub list`, `me sub upcoming`, `me sub cost`).
2. Clarify whether the task is:
   - adding a subscription
   - reviewing renewals
   - cost auditing
   - changing lifecycle state
   - linking notes or related work
3. Use `me sub` commands directly rather than inventing side workflows.
4. Summarise the state and the implication of any change.

## Decision rules

- Use `auto_renew=true` for genuinely ongoing subscriptions.
- Use `--no-auto-renew` for fixed-term access or one-off annual purchases.
- Set `account` where it matters for reporting (`personal` or `business`).
- If a source matters, ensure it exists in `me source` first.
- Prefer relating a subscription to a ticket or project when there is clear follow-on work.

## Key behaviours to remember

- `me sub list` and `me sub upcoming` may auto-advance renewal dates for active auto-renewing subscriptions.
- `cancelled` and `expired` are terminal states.
- `me sub cost` normalises costs across frequencies, so explain that if the summary might surprise the user.
- `me sub edit` uses YAML via `$EDITOR`; prefer direct commands when possible and interactive editing when bulk changes are needed.

## Typical commands

```bash
me sub list
me sub upcoming --days 30
me sub cost --account business
me sub add "Tidal" --cost 9.99 --frequency monthly --account personal
me sub pause 3
me sub cancel 3
```

## Output pattern

When acting, report:
- what you inspected
- what changed
- any lifecycle implications
- any follow-up review worth doing
