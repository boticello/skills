---
name: "feature-build"
description: "Design and implement new me CLI functionality from a ticket using the established ticket, jot, jj, schema, and testing workflow."
alwaysAllow:
  - Bash
requiredSources:
  - system-files
  - me-cli-files
---

# me-feature-build

Use this skill when building new `me` CLI functionality from a ticket.

## Primary tools and commands

- `me tk`
- `me jot`
- `jj`
- repo files under `me-cli-files`

## Purpose

This skill exists to keep feature work disciplined: understand requirements, externalise design, respect the repo workflow, implement carefully, and record progress durably.

## Workflow

1. Read the relevant ticket (`me tk show <id> --json`).
2. Review relevant observations/reflections/jots if they exist.
3. Read repo context (`CLAUDE.md`, `ARCHITECTURE.md`, `CLI-REFERENCE.md`, relevant command files).
4. Read any file you intend to change with enough surrounding context to understand its role; do not rely only on search hits or patch targets when editing maintained notes, schema files, or reference docs.
5. Clarify scope and design questions before coding.
6. Record a design brief on the ticket when appropriate.
7. Respect jj working-copy state before editing.
8. Implement in the correct files.
9. Add tests as part of the implementation.
10. Use the consuming project's validation ladder to choose the right sequence
    of diff inspection, syntax checks, focused unit tests, early live-query
    probes, integration validation, and full-suite validation.
11. If the slice required real debugging, correction of a mistaken assumption, or repair of a broken validation path, run a short self-audit before considering it complete: what failed, what category of failure it was, what should change next time, and whether the lesson belongs on the ticket, in a jot, or in maintained guidance.
12. At the end of each stable implementation slice, write progress back to the ticket and explicitly reflect on what the slice taught.
13. If the lesson is broader than the ticket, record a jot reflection.
14. If the lesson becomes durable workflow policy, update or propose a maintained note and/or skill refinement.

## Critical rules

- Do not mix unrelated work into an existing jj working-copy change.
- Do not bypass schema discipline: `schema/setup.surql` and live schema must stay aligned.
- Do not move business logic into Ruby if it belongs in SurQL.
- New functionality requires tests.
- Do not wait until ticket closure to reflect if a stable implementation slice has completed.
- The durable record belongs in tickets/jots/notes, not only in chat.

## Reflection cycle

For code tickets, reflection happens at **stable slice boundaries**, not only at ticket closure.

A stable implementation slice usually means:
- a bounded behaviour change exists
- relevant tests pass
- practical validation has happened where appropriate
- there is something real to learn from

When a slice reaches that state:
1. write a progress note on the ticket
2. record what worked, what was awkward, what changed in understanding, and what should be repeated or changed next time
3. decide whether the lesson belongs only on the ticket, also as a jot reflection, or in a maintained note / skill update

Use this distinction:
- **ticket notes** = local progress and slice-specific learning
- **jots** = broader workflow or design reflections
- **maintained notes / skills** = repeated lessons that have become policy or durable guidance

## Completion sequence

When implementation and reflection are finished:

15. Commit the work with `Refs #<id>` in the message, following the
    consuming project's ticket-commit guidance.
16. If the CLI command surface changed, rebuild and reinstall the gem:
    ```
    script/install-global --force
    ```
    Use `script/dev-refresh` to rebuild and verify both installed and repo-local entrypoints in one step.
17. Record a closing progress note on the ticket that includes the commit SHA. Use `--file` for longer notes:
    ```
    me tk note <id> --file /tmp/closing-note.md
    ```
    Or combine note and closure in one step:
    ```
    me tk done <id> --file /tmp/closing-note.md
    ```
18. If the change is user-visible or workflow-visible, create a release-note jot:
    ```
    me jot release-note -t <id> --what "Summary" --why "Motivation" --validation "How tested"
    ```

## Decision rules

- If the work is design-heavy or prerequisites are unclear, stay in design mode first.
- If the current repo working copy is already carrying another change, either defer edits or deliberately begin the new work at an appropriate change boundary.
- Prefer one coherent capability per ticket/change.

## Output pattern

For each substantial step, report:
- what ticket/capability you inspected
- whether you are in design, implementation, or review mode
- what changed
- what remains open
