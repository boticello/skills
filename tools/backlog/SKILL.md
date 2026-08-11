---
name: backlog
description: >-
  Use when working with Backlog.md — the markdown-native task tracker this
  machine uses for project tickets: creating tasks, working them through their
  lifecycle, searching, wiring dependencies/milestones, or migrating a corpus
  into it (the beads-to-backlog import script). Carries the operating rules
  that prevent a wrong action mid-task: the CLI-only write path (never edit
  task files), DoD defaults, JSON shapes, the quoting and concurrency gotchas,
  and the dependency-cycle gap. Triggers on "backlog task", "create a ticket",
  "what's my current ticket", or any task-lifecycle request.
license: MIT
domain: project-management
role: specialist
scope: operations
output-format: commands
triggers:
  - backlog
  - backlog task
  - create a ticket
  - close a ticket
  - DoD
  - definition of done
metadata:
  author: bear
  version: 1.0.0
---

<!-- TOC: Scope | Storage model | Operating Rules | Commands | JSON patterns | Import/migration | Related -->

# backlog — Backlog.md task tracker

Local-first, markdown-native task manager (CLI + optional web UI). This skill
carries the rules that prevent a wrong action mid-task, plus the command
surface a working agent actually needs.

**Before creating, executing, or finalizing a task, read the generated
guidance:** `backlog instructions overview`, then the matching guide
(`task-creation`, `task-execution`, `task-finalization`) before lifecycle
actions. The guides are the agent-facing contract; this skill adds the
machine-specific operating rules.

## Scope

Creating and working tasks: create/edit/view/list/search/complete, comments
with authors, dependencies, milestones, subtasks, DoD, JSON reads, and
migrating a corpus in (br/beads or any JSONL export). It does not own the
operational lifecycle (readiness, review gates, closure policy) — that is
tracker-independent and belongs to the coordination/posture skills.

## Storage model

- Tasks, milestones, drafts, docs and decisions are **plain Markdown files**
  under `backlog/` (config at `backlog/config.yml`). Git-native: commit the
  folder like any other source.
- **The CLI is the only sanctioned write path.** Never hand-edit task/milestone
  files — the CLI maintains ids, filenames, relationships, metadata sections
  and history. The one documented exception: config list keys (below).
- IDs: `<prefix>-<n>` (`puzzle-1`), dotted for subtasks (`puzzle-1.1`), from
  `task_prefix` in config (letters only, set at init, read-only thereafter).
- `backlog/config.yml` list keys (`statuses`, `priorities`,
  `definition_of_done`) cannot be set via `backlog config set` — edit the file
  directly, then `backlog config list` to confirm.
- DoD defaults in config apply to **every new task** automatically
  (`--no-dod-defaults` opts out, e.g. imported historical tickets).

## Operating Rules

The gotchas that cause a wrong action if not internalized up front:

- **Quoting, always.** Values with backticks need single quotes at the shell
  (double-quoted backticks are command substitution and the text is lost).
  Multi-line descriptions/ACs are passed as real newlines inside one quoted
  argument — the `--ac`/`-d` repeatable flags make the br-style
  `--flag="$(cat file)"` dance unnecessary.
- **`--dep` targets must exist.** Dependencies are wired by task id; a
  non-existent target records nothing (silent). Create all tasks first, then
  wire deps in a second pass. **No cycle detection exists** — before adding a
  dep, walk the target's deps (`backlog task view <id> --json` →
  `.task.dependencies`) to avoid cycles.
- **Edits are slow (~0.3–3 s/call, bun JIT + file IO).** Bulk operations are
  expensive serial; parallelize across *different* tasks (separate files, safe)
  but never parallel edits to the *same* task — same-file concurrent edits are
  last-writer-wins on the whole file. The hub-serialization pattern is the
  workaround for same-task contention.
- **Lifecycle:** To Do → In Progress → Blocked → Done (configured). Finalize
  only from `task-finalization`: verify each AC with evidence before
  `--check-ac N`, write `--final-summary`, then set the terminal status.
  `task complete` moves Done tasks to `completed/`; `task archive` is for
  non-Done tasks and refuses Done ones.
- **Milestone re-add is not idempotent** — "alias conflict" error; check
  `backlog milestone list` first.
- **Do not edit task files** to backdate dates unless the migration record
  explicitly requires it; `created_date`/`updated_date` frontmatter edits are
  tolerated by the CLI but are not the normal path.

## Commands

```bash
backlog task create "Title" -d "desc" --ac "criterion" --ac "criterion2" \
  -l type:task,label2 -a @bear --priority High -s "To Do" \
  -p PARENT --dep OTHER --ref path/to/file --doc docs/x.md
backlog task edit ID -s "In Progress" --plan "1. ..." --append-notes "..." \
  --comment "question" --comment-author @bear --add-label urgent \
  --check-ac 1 --check-dod 1 --final-summary "..." --dep TARGET
backlog task view ID --plain | --json
backlog task list -s "In Progress" --json          # statuses: To Do / In Progress / Blocked / Done
backlog task complete ID                            # Done → completed/ (not archive)
backlog milestone add "Title"; backlog milestone list
backlog search "query" --plain
backlog instructions overview | task-creation | task-execution | task-finalization
backlog doctor                                      # duplicate-id check
backlog config list | get KEY
```

## JSON patterns

`--json` on `task list`/`task view`/`search` — stable, versioned
(`schemaVersion: 1`), never combined with `--plain`. Task keys include `id`,
`title`, `status`, `priority`, `labels`, `assignees`, `dependencies`,
`milestone`, `parentTaskId`, `acceptanceCriteria`, `definitionOfDone`,
`implementationPlan`, `implementationNotes`, `finalSummary`, `comments`,
`createdAt`, `updatedAt`, `path`.

```bash
backlog task list -s "In Progress" --json | jq -r '.tasks[] | "\(.id) - \(.title)"'
backlog task view ID --json | jq -r '.task.dependencies[]'   # dep walk (cycle check)
backlog search "x" --json | jq -r '.results[].task.id'
```

## Import / migration

Bulk import has no built-in command; the reusable mechanism is the Ruby
importer pattern maintained in the consuming project (the alan-puzzle project
currently provides an example):
read the source export (issues.jsonl) read-only, shell out to
`backlog task create`, write a mapping CSV (resume-safe), then idempotent
second passes for deps/comments/closure. Key design points:

- parents before children (topological order from parent-child edges);
  one milestone per open epic (title = epic name); children → subtasks `-p`.
- passes are idempotent (skip when already wired/imported) so interrupted
  runs resume via the CSV; `--jobs N` parallelizes across tasks (~3 s/call
  serial is too slow for hundreds of tasks).
- backdate `created_date`/`updated_date` frontmatter from source dates if the
  tool must display them; the mapping CSV carries originals regardless.
- statuses map: open → To Do, claimed → In Progress, closed/abandoned → Done;
  deleted/tombstoned records are skipped and counted.

## Related

- `br` skill + cheatsheet — the retired predecessor tracker (beads); migration
  source. Its `.beads/` is frozen after cutover — never write to it.
- `cheatsheets` — the reference tier for command shapes.
- `supervisor` — lifecycle policy this skill defers to.
- `git-vcs` / `git-change-manage` — commit workflow (backlog/ is plain files).
- alan-puzzle's `ticket` skill — the main-agent ticket workflow; the
  project's ticket-specialist task agent uses this skill as its usage
  reference.
