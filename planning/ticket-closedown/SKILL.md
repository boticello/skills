---
name: ticket-closedown
description: >
  Orchestrates the full closedown sequence for a ticket that has a working
  folder under ~/Me/02-tickets. Use when a ticket's implementation is complete
  and the agent must prepare closeout materials, verify the archive context,
  and complete closeout through `me tk done`. Do not use for tickets without a
  working folder, or for status-only transitions.
---

## Overview

Ticket closedown is a two-part process: an **authoring step** that produces the
required materials from live context, followed by a **deterministic execution
step** that commits the archive and closes the ticket.

The skill owns the end-to-end closeout workflow from the user's point of view:
it gathers context, drafts the closeout material, verifies the working copy,
and then invokes `me tk done` once the materials exist.

Never collapse these into a single status change. Closedown is a workflow, not
a flag flip.

## Prerequisites

- Implementation work is complete in all relevant repos.
- The working folder `~/Me/02-tickets/<number>-<slug>/` exists.
- You know the ticket number, title, and slug.
- You have read the live `closeout.md` (if it exists) and the full ticket
  context.

## Workflow

- [ ] Step 1 — **Verify jj context**
  Run `jj status` in `~/Me/02-tickets` and inspect the working-copy state.
  Run `jj log -r @ -T description` in `~/Me/02-tickets` and confirm `@` is on
  the correct ticket change. Check for a `Ticket-ID:` marker in the
  description. If the change looks wrong, use `me tk resume <id>` before
  touching any files.

- [ ] Step 2 — **Finalise `closeout.md`**
  Write or update `~/Me/02-tickets/<folder>/closeout.md` using the structure
  below. This is the working draft — not the archival record.

  ```
  Outcome:
  - what was completed

  Implementation:
  - brief high-level summary

  Validation:
  - what was checked

  Follow-on risks:
  - likely next issues or unresolved questions

  Archive:
  - full implementation record lives in the `jj` description for the ticket
    change in `~/Me/02-tickets`
  ```

- [ ] Step 3 — **Draft the concise ticket closedown note**
  This is what gets written into the ticket system. Keep it short — outcome,
  implementation summary, validation, follow-on risks, archive pointer.
  Match the template at `~/Me/00-system/templates/ticket-closedown-note.md`.
  Do not dump full working documents into the ticket note.

- [ ] Step 4 — **Draft the full `jj` change description**
  This is the archival record for the ticket's parent change in `02-tickets`.
  Use the template at `~/Me/00-system/templates/jj-change-description.md`.
  It should include: ticket number/title, outcome, problem, implementation
  summary, maintained docs updated, validation, assumptions, follow-on risks,
  and a future-agent start point.

- [ ] Step 5 — **Note any follow-on tickets**
  If follow-on tickets are created, link them back to the originating ticket.
  Do not create a working folder for a follow-on ticket unless it is being
  started immediately.

- [ ] Step 6 — **Invoke `me tk done`**
  Once Steps 2–5 are complete, hand off to the deterministic execution step.
  Invoke it with two explicit authored inputs:
  - `--set-file note PATH` for the concise ticket note
  - `--set-file archive PATH` for the full `jj` archive description

  `me tk done` will:
  - refuse unless the ticket is still in the expected pre-closeout state
  - ensure `@` is the correct ticket change
  - rewrite the `jj` description from the supplied archive record
  - create a child deletion change
  - delete the working folder from the filesystem
  - write the supplied concise note into the ticket system
  - close the ticket only after postflight verification passes

  Use file-backed or stdin-backed input for substantial text (see Rules below).

## Key Rules

- **Two-change shape**: the parent change preserves the final folder state;
  the child change deletes it. Do not merge these into one.
- **Closedown note ≠ full narrative**: the ticket jot is concise; the `jj`
  description is the full record. Do not copy large working documents into the
  ticket note.
- **`02-tickets` is not a code repo**: also commit implementation changes in
  Dotfiles, `00-system`, or the relevant project repo. Do not skip those just
  because `02-tickets` was updated.
- **Deferred scope goes in `closeout.md`**, not `handoff.md`.
  `handoff.md` is for live continuation only.
- **Large artefacts** (exports, zips, generated bundles) need an explicit
  tracking decision. Document any temporary ignore or exclusion rather than
  silently omitting them.

## Gotchas

- `me tk done` and raw `jj edit` are not equivalent. Do not use `jj edit`
  directly inside `~/Me/02-tickets` during closedown — that is recovery-only.
- `me tk new` uses `--file PATH`; `me tk update` uses `--set-file description PATH`.
  `me tk done` uses `--set-file note PATH` and `--set-file archive PATH`.
  These are different flags. Do not assume they match.
- Shell-quoted rich text is a transport risk when it contains backticks, flags,
  quotes, command fragments, or multiple lines. Use a temp file instead.
- `@` can drift between sessions. Always verify with `jj log -r @ -T description`
  before writing anything. A `Ticket-ID:` marker in the description confirms
  the right change.
- Follow-on tickets created during closedown should be folderless until
  actually started.

## References

Load before performing closedown on any ticket:

- `~/Me/00-system/docs/system/ticket-management/reference/ticket-management-rules.md`
- `~/Me/00-system/docs/system/ticket-management/reference/ticket-closedown-procedure.md`
- `~/Me/00-system/templates/ticket-closedown-note.md`
- `~/Me/00-system/templates/jj-change-description.md`

Load if the ticket also touches code:

- `~/Me/00-system/agents/skills/me-feature-build/SKILL.md`
- `~/Me/00-system/agents/skills/change-manage/SKILL.md`
- `~/Me/00-system/tools/cli/AGENTS.md`
