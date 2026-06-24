---
name: "filing-process"
description: "Inspect, classify, propose, and execute filing work carefully using me fs, me tk, me jot, and explicit routing logic."
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

# filing-process

Use this skill when processing inbox or domain filing material.

## Primary commands

- `me fs scan`
- `me fs audit`
- `me fs log`
- `me fs info`
- `me fs tags`
- `me fs find`
- `me tk`
- `me jot`

## Purpose

This skill provides a careful, general filing workflow across `~/Me`. It should support inspection, classification, routing, and durable recording of filing decisions.

## Core principle

Do not treat filing as mere moving of files. Filing work often includes:
- understanding what something is
- deciding whether it has value
- choosing the right destination or holding area
- recording follow-up work when needed
- reducing ambiguity and clutter

## Workflow

1. Select a focused filing target (folder, batch, or item set).
2. Create or identify a ticket for the filing unit when the work is substantial, repeatable, or likely to span more than one conversational step.
3. Inspect before acting:
   - use `me fs scan` for structure/stats
   - use `me fs info` and file reads for material understanding
   - use `me fs tags` or Spotlight metadata where helpful
4. **Consult audit trail and rules** before routing unfamiliar patterns:
   - `me fs log list --path <similar-path>` to check past rulings on similar items
   - `me fs log list --src-path <path>` to see what was previously moved from that location
   - Reference filing rules (F-R01–F-R29) in `00-system/docs/reference/filing-rules.md` for known patterns
   - When applying a rule, record it with `--rules` on the log entry
5. Classify the material:
   - record
   - reference
   - note
   - template
   - project material
   - archive candidate
   - trash candidate
   - uncertain
6. Propose a routing/disposition plan before significant moves or deletions.
7. Record important findings and intended next actions in the ticket when the filing work is being tracked formally.
8. If filing reveals follow-up work, create or update tickets/jots.
9. Use `me fs log` to record meaningful processing actions where appropriate:
   - For single moves: `me fs log <path> moved "description" --from <src> --to <dest> --rules F-R07 --rationale "reason"`
   - For bulk operations: `me fs log <path> moved "batch description" --batch <id> --count <n>`
   - Always include `--rules` and `--rationale` when the decision is non-obvious or policy-driven
10. Execute approved moves carefully and summarise the results.
11. Close the loop by recording what was done in the ticket or a durable jot when the session ends or the filing batch completes.

## Decision rules

- Prefer one folder or coherent batch at a time.
- Do not infer content solely from filenames when content inspection is feasible.
- Route uncertain items conservatively rather than overcommitting to a wrong destination.
- Use a ticket not only for downstream actionable work, but also for the filing batch itself when the batch deserves an audit trail.
- Use ticket notes to record intent, progress, and completion for filing work that spans multiple steps or sessions.
- Use jots when filing reveals observations, decisions, or reflections worth preserving beyond the task record.
- Distinguish between immediate execution and analysis/planning mode.

## Domain sensitivity

Always take the domain context into account. For example:
- `01-inbox` is a staging area, not a final home
- `50-business` needs stronger record/reference distinctions
- `70-research` needs provenance-aware handling
- `60-creative` requires gentler treatment of scraps and fragments

## Good patterns

```bash
# Inspection
me fs scan /Users/bear/Me/01-inbox/To\ Process --depth 2
me fs audit /Users/bear/Me/50-business/50-inbox
me fs info /Users/bear/Me/01-inbox/some-file.pdf

# Audit consultation — check past rulings before routing
me fs log list --path 80-tech
me fs log list --src-path 01-inbox/drafts

# Logging with audit trail fields
me fs log 01-inbox/drafts moved "Triage complete" --from 01-inbox/drafts --to 80-tech/80-inbox --rules F-R07 --rationale "Tech snippets"
me fs log 01-inbox/drafts moved "Bulk drafts triage" --batch drafts-2026-04-05 --count 1569

# Ticket and note creation
me tk create "Review ambiguous research captures" -k process -p 2 -s s --path 70-research
me jot -k observation "The research root contains many uncategorised capture files needing provenance cleanup."
```

## Output pattern

A good filing response should include:
- scope inspected
- ticket context (existing, created, or recommended)
- classification summary
- proposed dispositions
- any executed changes
- tickets/jots created, updated, or recommended
