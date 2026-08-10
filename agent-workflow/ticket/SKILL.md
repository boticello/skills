---
name: ticket
description: >-
  Main-agent workflow for the project tracker (Backlog.md): decide whether
  work needs a ticket (including filing defects as bug tickets), construct
  rich ticket content, and delegate the mechanics to the ticket-specialist
  task agent. Use whenever the user asks to create, revise, comment on,
  check, or close a ticket — "create a ticket for X", "implement PUZZLE-49",
  "what's the current ticket?", "close that task", "file a bug" — or when
  the closure gate or a task's Definition of Done is mentioned.
license: MIT
domain: project-management
role: specialist
scope: project
output-format: workflow
triggers:
  - ticket
  - tickets
  - backlog
  - PUZZLE-
  - create a ticket
  - revise a ticket
  - close a ticket
  - current ticket
  - closure gate
  - definition of done
  - DoD
  - bug
  - defect
  - file a bug
---

# Ticket workflow (alan-puzzle)

Tickets are the unit of work; Backlog.md (folder `backlog/`) is the tracker;
the `backlog` CLI is the only interface. **Reads and writes have different
owners.** Main agents run read-only lookups (`backlog task view <id>` /
`backlog show <id>`) directly — nothing is committed and the CLI is safe to
read from. Every *write* — create, revise, comment, close, claim — and every
*search* is delegated to the **ticket-specialist** task agent
(`.omp/agents/ticket-specialist.md`): searches because the specialist carries
the index-staleness guard, writes because each must be verified by re-reading
and committed.

## When to create a ticket

Ask: "Do I need to think about HOW to do this?"

- **Yes** — planning, decisions, handoff, reviewable commitment, work another
  agent or session will pick up → create a ticket.
- **No** — mechanical edits, quick lookups, obvious fixes → do it directly;
  a ticket is overhead.
- **Found a defect** (broken tooling, corrupted artefact, wrong output)? File
  **one bug ticket per defect** — report format (Observed / Reproduction /
  Expected / Impact), never the four-element task format, never batched.

Search before creating (`backlog search <term>`, or ask the specialist):
reuse an existing ticket instead of duplicating.

## Constructing a ticket (compulsory reading)

Creating is a construction task: you write the content, the specialist files
it. Read **`process/ticket-writing.md` before creating or revising any
ticket** — it is the content standard: how to structure a ticket (bug,
feature, question), the four elements (title, Brief, references, acceptance
criteria), language rules, and the closure gate. The standard is the single
source; do not re-derive it here.

## The five actions

| Action | What you supply | Example instruction |
|---|---|---|
| **Create** | The full four-element content (title, Brief, refs, ACs) plus labels/priority — **bugs use the report format instead** (see `ticket-writing.md` §Bug reports) | "Create a ticket: <title>. Description: <brief>. References: <paths + why>. Acceptance criteria: <list>. Priority High." — or "File a bug: <observed / reproduction / expected / impact>" |
| **Revise** | The id, exactly what changes (title/body/ACs/refs/labels/priority/status), and why (as a comment) | "Revise PUZZLE-12: set status In Progress, add acceptance criterion <X>; comment: <why>" |
| **Comment** | The id and the text (with `@user` if the author matters) | "Add a comment to PUZZLE-9: <text>" |
| **Close** | The id and the evidence — which ACs are verified and how | "Close PUZZLE-49: ACs 1–3 verified by <evidence>; write the final summary" |
| **Claim** | The id, at the moment execution starts | "Claim PUZZLE-33: status In Progress, assign to @bear; comment: <why>" |
| **Check — show/view** | Nothing — run it yourself | "Show PUZZLE-29" → `backlog task view PUZZLE-29` directly; no specialist |
| **Check — search** | The query | "Search for <term>", "What's the current In Progress ticket?" → specialist (index-staleness guard) |

**Claiming.** Investigating a ticket — reading it, researching, evaluating
whether it is worth doing — never changes its status. *Claiming* is the moment
you commit to executing: the ticket can be done, it should be done, and you
have what you need to do it. Claim through the specialist (Revise: status In
Progress + assignee, with a comment). Do not leave a ticket To Do while you
are executing it.

**Handoff.** When work is complete but held for review — or parked for any
reason — write the review-ready summary on the ticket before stopping: what
changed, where it lives (branch/commit), and the verification evidence. The
reviewer reads the ticket, not the conversation. Implementation notes via the
specialist (`--append-notes`); the same summary becomes the close evidence.

## Mechanics — instruct the ticket-specialist (writes and searches)

One `task` dispatch, `agent: ticket-specialist`, with the request above. The
specialist translates it onto the CLI, verifies every write by re-reading the
task, and commits every change (granular). It returns the verified state
(id, status, commits, evidence). That is the write loop — the specialist owns
all writes and searches. Reads (`view`/`show`) need no specialist: run them
directly, and never hand-edit `backlog/` files.

## Gotchas

- The CLI fails silently (exit 0 on "Task not found") — that is why the
  specialist re-reads after every write; trust its verification, and if it
  reports a commit failure under a sandbox, surface it.
- Do not create tickets for questions, explanations, or mechanical edits —
  the specialist will say so too.
- Verify an id after searching (`--search` matches task bodies).
- Same-task edits must serialize (last-writer-wins): one change at a time,
  one commit.

## Related

- `process/ticket-writing.md` — the content contract (four elements, language
  rules, closure gate).
- `process/tracker.md` — tracker mechanics, conventions, gaps, git policy.
- `.omp/agents/ticket-specialist.md` — the operator: its prompt carries the
  CLI usage and process guidance.
- AGENTS.md §Process — the tracker paragraph.
- `backlog instructions overview` — generated agent-facing guidance (the
  specialist reads it before lifecycle actions).
