---
name: ticket
description: >-
  Use whenever the user asks to create, work on, review, or close a ticket or
  task in this project — "implement PUZZLE-49", "create a ticket for X", "ticket
  this", "what's the current ticket?", "close that task" — or whenever the
  tracker is operated through `just ticket` / `just tlist` / `just tclose` /
  `just current`. Also load when the closure gate, the current-ticket signal,
  or a task's Definition of Done is mentioned. The project's ticket workflow
  rides on Backlog.md (folder `backlog/`): "ticket" is the unit of work and
  the workflow abstraction; Backlog.md is the implementation; `just ticket`
  and the typed recipes are the interface.
license: MIT
domain: project-management
role: specialist
scope: project
output-format: workflow
triggers:
  - ticket
  - tickets
  - task
  - backlog
  - just ticket
  - just tlist
  - just tclose
  - just current
  - PUZZLE-
  - closure gate
  - current ticket
---

# Ticket workflow (alan-puzzle)

The project's tracker: tickets are the unit of work; Backlog.md is the
implementation; `just ticket` and the typed recipes are the interface. Never
hand-edit files under `backlog/` — they are tool-managed; all changes go
through the CLI.

## When to create a ticket

Ask: "Do I need to think about HOW to do this?"

- **Yes** — planning, decisions, handoff, reviewable commitment, work another
  agent or session will pick up → create a ticket.
- **No** — mechanical edits, quick lookups, obvious fixes → do it directly;
  a ticket is overhead.

Search before creating (`backlog search <term>` or `just ticket list
--search <term>`): reuse an existing ticket instead of duplicating. Note
`--search` matches task bodies — verify the id after searching.

## Ticket anatomy (content contract: `process/ticket-writing.md`)

A ticket carries four elements, mapped onto Backlog.md's fields:

- **Title** — noun phrase naming the deliverable, not the activity.
- **Description** — Brief (current situation + deliverable), References
  (paths + why), and Plan (what to achieve) as markdown.
- **Acceptance criteria** (`--ac`) — checkable yes/no statements a third
  party can verify without re-deriving intent. The structured field is
  canonical — do not duplicate it as a body section.
- **DoD defaults** — auto-added to every task (closure gate + `doc check`
  green); leave them in place.

## Lifecycle

1. **Create** — `just tnew "Title"` for a bare task, or
   `just ticket create "Title" -d "$(cat body.md)" --ac "Criterion one" -l
   labels --priority High` for a full ticket. Multi-line values: write the
   body to a file and pass it with `-d "$(cat file)"` — the CLI keeps
   backticks, `$`, and quotes verbatim.
2. **Commit at creation, solo and immediately.** A new task is a published
   contract: visible to other agents and clones, safe from a clean/stash/
   worktree switch. Task-file edits (status, comments, plan) ride with the
   implementing commit; never leave a task file uncommitted across sessions.
3. **Work one ticket at a time** — one ticket per session keeps the context
   window reviewable. Read `backlog instructions overview` (plus the
   creation/execution/finalization guides) before working the tracker; the
   generated guidance is the agent-facing contract. Set status with
   `just ticket edit <id> -s "In Progress"`; note progress with
   `just tcomment <id> "text"`.
4. **Current ticket** — `just current` prints the In Progress ticket(s)
   ("No tasks found." when none). This is the render/default target signal.
5. **Verify before close** — the DoD items: confirmed records carried into
   maintained docs with `derived_from` back-links (closure gate), and
   `doc check` green where applicable.
6. **Close** — `just tclose <id>` sets Done and moves the file to
   `backlog/completed/` in one step (or `just ticket edit <id> -s "Done"`
   then `backlog task complete <id>`). Commit the close with its evidence.

## Gotchas

- Use the **typed recipes** (`tlist`/`tview`/`tnew`/`tcomment`/`tclose`) for
  multi-word values — they quote inside the recipe. The passthrough
  `just ticket <args>` splits on spaces: `just ticket list -s "To Do"` fails;
  escape as `-s \"To\ Do\"` or use `just tlist "To Do"`.
- `task list` shows only `backlog/tasks/`, not `backlog/completed/` — a
  closed ticket drops out of `list` but `task view <id>` still works.
- Priorities/labels/statuses are accepted case-insensitively and stored
  lowercase; ids are `PUZZLE-N`.
- `--search` is unscoped content search (title, description, notes,
  comments) — always verify an id by `just tview` before acting on it.

## Related

- `process/ticket-writing.md` — the content contract (four elements,
  language rules, closure gate).
- AGENTS.md §Process — the tracker paragraph (recipes, DoD, git policy).
- `backlog instructions overview` — generated agent-facing guidance.
