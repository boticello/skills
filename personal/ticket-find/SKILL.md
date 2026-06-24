---
name: "ticket-find"
description: "Find tickets."
alwaysAllow:
  - Bash
requiredSources:
  - system-files
---

# ticket-find

Use when gathering or searching for tickets on a topic.

## Primary commands

## Purpose


## Workflow


Gather a topic orientation: merged search hits with full context.

```
me search --semantic --in ticket "<topic>" --limit 5 --json
me search --in ticket "<topic>" --limit 5 --json
```

Run both in parallel. Deduplicate by ticket number. For each unique hit, gather context: `me tk show <N> --json`

This returns notes (progress, decisions), children, and parent in one call.

Present a compact report per ticket:
- Number, title, status, kind
- One-line description summary
- Key note headlines (kind + first line)
- Parent/child links if any

Do not list all open tickets unfiltered. Do not skip the `me tk show` step — notes and structure are where the orientation value is.

///

look through recent tickets to find criteria

Browse the recent queue with filters, then gather context on candidates.

```
me tk list --updated-since "10 days ago" --sort updated:desc -n 20 --json
me tk list --created-since "10 days ago" --sort created:desc -n 10 --json
```

If the user gives a topic, also run `me search --semantic --in ticket "<topic>"` and merge with the recent list. Present matches with `me tk show <N> --json` for context.


## Decision rules


## Good patterns

## Output pattern



////


```
me tk list --status in_progress --sort updated:desc --json
me tk list --updated-since "7 days ago" --sort updated:desc -n 15 --json
```


For each active or recently updated ticket, `me tk show <N> --json` to get the latest progress note. Summarise: what was done, what remains, any blockers.
