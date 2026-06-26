# Closedown Ceremony

Tracker-agnostic closedown workflow, salvaged from the retired `me`-CLI
ticket-closedown skill and translated to `br`. Use this when an issue's work
is complete and you need to close it cleanly with a durable record.

Closedown is a **workflow, not a flag flip**. Do not collapse it into a single
status change. It has two parts: an *authoring* step that produces the record
from live context, followed by a *deterministic execution* step that closes
the issue and syncs.

## Prerequisites

- Implementation is complete in all relevant repos.
- The work has been committed (you know the commit SHA / PR).
- You have read the issue context (`br show <id> --json`).

## Workflow

1. **Verify the issue is actually done.** `br show <id> --json`. Re-read the
   contract/notes. Do not close against a stale mental model.
2. **Author the concise closedown note.** Keep it short — this goes into the
   issue, not a narrative dump:
   - Outcome: what was completed
   - Implementation: brief high-level summary
   - Validation: what was checked
   - Follow-on risks: likely next issues or unresolved questions
   - Archive pointer: where the full record lives (commit SHA / PR / doc)
3. **Record it as a comment** with evidence:
   ```bash
   br comments add --actor "$ACTOR" <id> \
     --message "Closedown: <outcome>. Validation: <checked>. See commit <sha>."
   ```
4. **Close with a reason that names the evidence** — never close without it:
   ```bash
   br close --actor "$ACTOR" <id> --reason "Implemented X in commit <sha>"
   ```
5. **Link follow-on issues back** to the originating one
   (`br dep add <followon> <origin>`) if you create any.
6. **Sync explicitly** (br never auto-commits):
   ```bash
   br sync --flush-only
   git add .beads/ && git commit -m "Close <id>: <reason>"
   ```

## Key rules

- **Closedown note != full narrative.** The issue comment is concise; the
  commit message / PR / maintained doc is the full record. Do not paste large
  working documents into the issue.
- **Evidence is mandatory.** Commit SHA, PR, file, or observed behaviour. If
  you are unsure the work is verifiably done, leave a comment with the open
  question instead of closing.
- **Use file-backed input for substantial text.** Shell-quoted multi-line text
  is a transport risk when it contains backticks, flags, quotes, or command
  fragments. Write the note to a temp file and pass it through rather than
  inlining.
- **Close only the issue you mean.** Do not modify unrelated issues during
  closedown.

## Triage classification (for bulk closedown)

When closing several issues, classify each first, then act:

| Classification      | Action                                              |
|---------------------|-----------------------------------------------------|
| `implemented`       | Close with evidence (commit/PR/file/behaviour)      |
| `out-of-scope`      | Close with explicit boundary reason                 |
| `needs-clarification` | Comment with specific unanswered questions        |
| `actionable`        | Keep open; correct status/priority/labels/deps      |

If unsure, comment instead of closing. Do not invent evidence.
