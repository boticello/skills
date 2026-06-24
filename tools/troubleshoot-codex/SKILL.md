---
name: troubleshoot-codex
description: Diagnose and fix OpenAI Codex Desktop session problems — missing conversations, phantom sessions, corrupted transcripts, and index inconsistencies. Also provides tools for inspecting, extracting, and visualising Codex session transcripts stored locally on macOS.
---

# Troubleshoot Codex Desktop

This skill diagnoses and repairs problems with the OpenAI Codex Desktop app's local session data on macOS. Use it when a conversation has disappeared from the sidebar, when transcripts are corrupted, or when you need to inspect or extract session content outside the app.

## File Layout

All paths are relative to `CODEX_HOME` (default `~/.codex`).

| Path | Purpose |
|------|---------|
| `state_5.sqlite` | **Primary thread database** — the app sidebar reads from here via `thread/list` RPC. If a session is missing from here, it is invisible regardless of `session_index.jsonl`. |
| `sessions/YYYY/MM/DD/*.jsonl` | Session transcript files (the primary data) |
| `session_index.jsonl` | Secondary/fallback index — one JSON object per line, keyed by session ID. Written to by the app but **not** the primary read path for the sidebar. |
| `logs_2.sqlite` | Structured agent logs (can grow very large). |
| `goals_1.sqlite` | Agent goal tracking. |
| `memories_1.sqlite` | Agent memory store. |
| `.codex-global-state.json` | Electron persisted state: prompt history, heartbeat permissions, unread thread IDs, workspace roots, window bounds. |
| `archived_sessions/*.jsonl` | Older sessions moved out of the active directory. |
| `attachments/UUID/*` | Files pasted or attached to sessions. |
| `config.toml` | User configuration (shell policies, model, permissions). |
| `computer-use/` | Browser use / computer-use agent state. |
| `skills/` | Installed agent skills. |
| `shell_snapshots/` | Saved shell environment snapshots. |

App logs (Electron main/renderer process):

```
~/Library/Logs/com.openai.codex/YYYY/MM/DD/codex-desktop-<uuid>-<pid>-t<N>-i<I>-<HHMMSS>-<seq>.log
```

Each log file is identified by a process UUID. The `t0` file is the main (browser) thread; `t1` is the utility/GPU thread. To find which log covers a given session, grep for the session ID:

```bash
grep 'SESSION_ID' ~/Library/Logs/com.openai.codex/$(date +%Y/%m/%d)/*.log
```

## Thread State (state_5.sqlite)

The Codex Desktop app stores thread metadata in `state_5.sqlite`, a SQLite database. The sidebar reads from this database via the CLI backend's `thread/list` RPC. **This is the primary data source for sidebar display.** A session with a valid transcript and `session_index.jsonl` entry can still be invisible if it's missing from `state_5.sqlite`.

### threads table

Key columns:

| Column | Type | Purpose |
|--------|------|----------|
| `id` | TEXT PK | Session UUID |
| `title` | TEXT | Display name in sidebar |
| `cwd` | TEXT | Working directory (used for workspace filtering) |
| `rollout_path` | TEXT | Path to the JSONL transcript file |
| `archived` | INTEGER | 0 = visible, 1 = archived (hidden) |
| `archived_at` | INTEGER | Unix timestamp of archival |
| `thread_source` | TEXT | `"user"`, `"subagent"`, or `"automation"` |
| `source` | TEXT | `"vscode"`, `"cli"`, or JSON subagent spawn object |
| `has_user_event` | INTEGER | Whether the thread has user-initiated events |
| `first_user_message` | TEXT | First user prompt (also used as fallback title) |
| `tokens_used` | INTEGER | Cumulative token count |
| `updated_at` | INTEGER | Unix timestamp (seconds) of last update |
| `created_at` | INTEGER | Unix timestamp (seconds) of creation |
| `model` | TEXT | Model used (e.g. `"codex-1"`) |
| `agent_nickname` | TEXT | Subagent nickname (e.g. `"Hypatia"`, `"Meitner"`) |
| `agent_role` | TEXT | Subagent role (e.g. `"worker"`, `"explorer"`) |

### thread_spawn_edges table

Maps parent→child relationships for subagent sessions:

| Column | Purpose |
|--------|----------|
| `parent_thread_id` | Parent session UUID |
| `child_thread_id` | Child (subagent) session UUID |
| `status` | Edge status (e.g. `"closed"`) |

### Key SQL queries

```bash
CODEX_DB=~/.codex/state_5.sqlite

# Is a session in the database? (the real visibility check)
sqlite3 "$CODEX_DB" "SELECT id, title, archived, thread_source FROM threads WHERE id = 'SESSION_ID';"

# List sessions for a workspace (sidebar view)
sqlite3 -header "$CODEX_DB" "SELECT id, substr(title,1,50), thread_source, updated_at FROM threads WHERE cwd = 'WORKSPACE_PATH' AND archived = 0 ORDER BY updated_at DESC;"

# Find sessions with blank titles (potential invisibility cause)
sqlite3 "$CODEX_DB" "SELECT id, title FROM threads WHERE title = '' OR title IS NULL;"

# Check parent-child relationships
sqlite3 -header "$CODEX_DB" "SELECT * FROM thread_spawn_edges WHERE parent_thread_id = 'SESSION_ID';"

# Find archived sessions
sqlite3 "$CODEX_DB" "SELECT id, title FROM threads WHERE archived = 1 ORDER BY archived_at DESC;"

# Count threads per workspace
sqlite3 "$CODEX_DB" "SELECT cwd, COUNT(*) FROM threads WHERE archived = 0 GROUP BY cwd ORDER BY COUNT(*) DESC;"

# Repair: update a title
sqlite3 "$CODEX_DB" "UPDATE threads SET title = 'NEW_TITLE' WHERE id = 'SESSION_ID';"

# Repair: unarchive a session
sqlite3 "$CODEX_DB" "UPDATE threads SET archived = 0, archived_at = NULL WHERE id = 'SESSION_ID';"
```

**Database locking:** If `sqlite3` returns exit code 5, the database is locked (Codex is running). Quit the app before write operations.

**Read-only access while app is running:** Use `?immutable=1` URI mode: `sqlite3 "file:$CODEX_DB?immutable=1" "SELECT ..."`

## Session Index (session_index.jsonl)

`session_index.jsonl` is a secondary index. Each line is a JSON object:

```json
{"id":"UUID","thread_name":"Thread Name","updated_at":"2026-05-31T19:12:35.937Z"}
```

The app writes to this file but does **not** primarily read from it for sidebar display. A session present here but missing from `state_5.sqlite` will still be invisible. The `thread_name` is set via `thread/metadata/update` RPC and may differ from the `title` in SQLite.

**Sub-agent workers** are typically indexed in both SQLite and JSONL by the current version of Codex. Workers can be identified by `thread_source = 'subagent'` and a `source` field containing a JSON spawn object.

**How to identify workers vs parent sessions:** Workers have `thread_source: "subagent"` and a `source` field that is a JSON object with `parent_thread_id`, `agent_nickname`, and `agent_role`. Parent sessions have `thread_source: "user"` and `source: "vscode"` or `"cli"`.

**Safe editing:** Only modify `session_index.jsonl` or `state_5.sqlite` when the Codex app is not running, to avoid write races.

## Transcript JSONL Structure

Each session transcript is a sequence of JSON objects, one per line. Top-level fields:

```
{"timestamp": "ISO-8601", "type": "EVENT_TYPE", "payload": {...}}
```

### Event types

| `type` | Count (typical) | Purpose |
|--------|----------------|---------|
| `response_item` | ~70% | Raw API response items — messages, tool calls, tool outputs, reasoning |
| `event_msg` | ~25% | Semantic events — user messages, agent messages, task lifecycle, token counts |
| `session_meta` | 1–2 | Session header with ID, CWD, CLI version, model provider |
| `turn_context` | 1 per turn | Per-turn config: model, approval policy, sandbox, personality |

### Payload types (`payload.type`)

**Conversation flow:**

| Payload type | Parent event | Key fields |
|-------------|-------------|------------|
| `user_message` | `event_msg` | `.payload.message` (user's text) |
| `agent_message` | `event_msg` | `.payload.message` (agent's text) |
| `task_started` | `event_msg` | `.payload.turn_id`, `.payload.model_context_window` |
| `task_complete` | `event_msg` | `.payload.turn_id`, `.payload.duration_ms`, `.payload.last_agent_message` |
| `token_count` | `event_msg` | `.payload.info.total_token_usage` |

**API response items (`response_item`):**

| Payload type | Key fields |
|-------------|------------|
| `message` | `.payload.role`, `.payload.content` (string or array of content blocks) |
| `reasoning` | `.payload.summary` (reasoning summary text) |
| `function_call` | `.payload.name`, `.payload.arguments`, `.payload.call_id` |
| `function_call_output` | `.payload.call_id`, `.payload.output` |
| `custom_tool_call` | `.payload.name`, `.payload.arguments` |
| `custom_tool_call_output` | `.payload.output` |
| `patch_apply_end` | Patch application results |

**Session metadata (`session_meta`):**

| Field | Example |
|-------|---------|
| `payload.id` | Session UUID |
| `payload.cwd` | Working directory when session started |
| `payload.source` | `"vscode"`, `"cli"`, or JSON subagent object `{"subagent":{"thread_spawn":{...}}}` |
| `payload.thread_source` | `"user"`, `"subagent"`, or `"automation"` |
| `payload.cli_version` | e.g. `"0.135.0-alpha.1"` |
| `payload.model_provider` | e.g. `"openai"` |

### File naming convention

```
rollout-YYYY-MM-DDTHH-MM-SS-SESSION_ID.jsonl
```

The session ID embedded in the filename is the same as `payload.id` in the `session_meta` event.

## Troubleshooting Procedures

### 1. Phantom Session (conversation disappeared from sidebar)

**Symptom:** A conversation you had is no longer visible in the Codex sidebar, but you didn't delete it.

**Known causes:**
- Session missing from `state_5.sqlite` (primary cause — the sidebar reads from SQLite)
- Session present in SQLite but `archived = 1`
- Session has blank `title` in SQLite
- Session pushed out of the 50-thread sidebar page cap (`RECENT_CONVERSATIONS_PAGE_SIZE = 50`)
- Session was `inactive_thread_unsubscribed` and the app's in-memory state lost it

**Diagnosis:**

1. Find the session on disk:
   ```bash
   ls -la ~/.codex/sessions/$(date +%Y/%m/%d)/
   # Or search by keyword
   grep -rl 'KEYWORD' ~/.codex/sessions/
   ```

2. Check the SQLite database (the authoritative source):
   ```bash
   sqlite3 ~/.codex/state_5.sqlite \
     "SELECT id, title, archived, thread_source FROM threads WHERE id = 'SESSION_ID';"
   ```

3. Also check the JSONL index for completeness:
   ```bash
   grep 'SESSION_ID' ~/.codex/session_index.jsonl
   ```

4. Check the app logs for the session:
   ```bash
   grep 'SESSION_ID' ~/Library/Logs/com.openai.codex/$(date +%Y/%m/%d)/*.log
   ```
   Zero hits in the current log means the app's in-memory state doesn't include the session.

**Repair:**

1. Quit the Codex app completely (important — avoids write races and database locks).
2. Verify the app is not running: `pgrep -x Codex`
3. If the session is missing from SQLite, insert it. The simplest approach is to update the title or unarchive:
   ```bash
   # Unarchive
   sqlite3 ~/.codex/state_5.sqlite \
     "UPDATE threads SET archived = 0, archived_at = NULL WHERE id = 'SESSION_ID';"
   
   # Fix blank title
   sqlite3 ~/.codex/state_5.sqlite \
     "UPDATE threads SET title = 'DESCRIPTIVE NAME' WHERE id = 'SESSION_ID';"
   ```
4. If the session is entirely missing from SQLite, use `scripts/inspect-sqlite.py` to diagnose further.
5. Also add to `session_index.jsonl` as a fallback:
   ```bash
   echo '{"id":"SESSION_ID","thread_name":"DESCRIPTIVE NAME","updated_at":"TIMESTAMP"}' >> ~/.codex/session_index.jsonl
   ```
6. Reopen the Codex app.

**Automated detection:** Use the `scripts/detect-phantom-sessions.sh` script (checks both JSONL and SQLite).

**Sidebar 50-thread cap:** If the workspace has >50 threads, older ones may be hidden. The sidebar does not paginate automatically. Try pinning important threads or searching by name.

### 2. Corrupted or Incomplete Transcript

**Diagnosis:**

```bash
# Check each line is valid JSON
python3 -c "
import json, sys
for i, line in enumerate(open(sys.argv[1]), 1):
    try:
        json.loads(line)
    except json.JSONDecodeError as e:
        print(f'Line {i}: {e}')
" SESSION_FILE
```

Check whether the transcript ends with a `task_complete` event:

```bash
tail -1 SESSION_FILE | python3 -c "
import json, sys
obj = json.loads(sys.stdin.readline())
print(f'Last event: type={obj[\"type\"]} payload.type={obj.get(\"payload\",{}).get(\"type\",\"-\")}')
print(f'Timestamp: {obj[\"timestamp\"]}')
"
```

If the last event is not `task_complete`, the session was interrupted (app crash, network failure, user force-quit).

### 3. Session Not Starting / Immediate Failure

Check the app logs for the session's creation event and any errors:

```bash
# Find the log file that mentions the session
grep -l 'SESSION_ID' ~/Library/Logs/com.openai.codex/$(date +%Y/%m/%d)/*.log

# Check for errors around that session
grep 'SESSION_ID' LOG_FILE | grep -i 'error\|fail\|crash'
```

Common log patterns:
- `Conversation created conversationId=...` — session was created
- `thread/metadata/update` — thread name was set
- `inactive_thread_unsubscribed` — session went idle and was unsubscribed
- `browser use route window missing` — UI lost track of the session's webview

### 4. Recovering a Sub-Agent Worker Session

Sub-agent workers (delegated via Codex's sub-agent feature) create transcript files on disk but are deliberately excluded from `session_index.jsonl`. They are not phantom sessions — they are expected to be invisible. To recover one:

1. Identify the parent session's timestamp and CWD.
2. Find worker sessions from the same day with the same CWD:
   ```bash
   python3 ~/.agents/skills/troubleshoot-codex/scripts/session-summary.py ~/.codex/sessions/YYYY/MM/DD/*.jsonl | grep 'CWD_NAME'
   ```
3. Cluster by timestamp — workers will start shortly after the parent's delegation turn.
4. Use `extract-conversation.py` to read the worker's transcript.

To distinguish a true phantom session (bug) from an expected worker session (by design), check the transcript for human-authored user messages. A worker session typically has zero human user messages — its inputs come from the orchestrator, not from the sidebar.

### 5. Extracting Conversation Content Without the App

Use `scripts/extract-conversation.py` to produce a readable text summary:

```bash
python3 ~/.agents/skills/troubleshoot-codex/scripts/extract-conversation.py SESSION_FILE
```

Or with `jq`:

```bash
# All user messages
cat SESSION_FILE | jq -r 'select(.payload.type == "user_message") | .payload.message'

# All agent messages
cat SESSION_FILE | jq -r 'select(.payload.type == "agent_message") | .payload.message'

# Tool calls made
cat SESSION_FILE | jq -r 'select(.payload.type == "function_call") | "\(.payload.name): \(.payload.arguments[:200])"'

# Session metadata
cat SESSION_FILE | jq -r 'select(.type == "session_meta") | .payload | {id, cwd, source, cli_version}'
```

## Transcript Generation

When the user needs readable transcripts — either for a single session, a workspace archive, or to share — choose the right tool for the job.

### Tool selection

| Use case | Tool | Why |
|----------|------|----|
| Quick terminal read | `extract-conversation.py` | No install, plain text, piped to stdout |
| Deep read of one session | `codex-transcript-viewer` | Single-file HTML with sidebar nav, search, filtering |
| Batch archive of a project | `codex-transcripts` | Paginated multi-page HTML, gist publishing, handles many sessions |
| Tool-call timeline | `codex-timeline` | Visual timeline of tool invocations |

### Install

```bash
# codex-transcripts — registry install
uv tool install codex-transcripts

# codex-transcript-viewer — requires clone first
git clone https://github.com/masonc15/codex-transcript-viewer /tmp/codex-transcript-viewer
uv tool install /tmp/codex-transcript-viewer

# codex-timeline — part of claude-code-transcripts suite
# See https://github.com/simonw/codex-timeline
```

### Single session

```bash
# Rich viewer (search, filters, sidebar)
codex-transcript-viewer SESSION.jsonl output.html

# Paginated HTML
codex-transcripts json SESSION.jsonl -o output-dir
mkdir -p output-dir && codex-transcripts json SESSION.jsonl -o output-dir

# Plain text
python3 ~/.agents/skills/troubleshoot-codex/scripts/extract-conversation.py SESSION.jsonl
```

**Gotcha:** `codex-transcripts` with `--output-auto` requires the parent directory to exist. Use `-o` with a directory you've created, or create it first.

### Workspace archive (batch generation)

Use `scripts/generate-workspace-archive.py` to batch-generate HTML transcripts for all sessions in a workspace, with parent→child linking:

```bash
# Full archive with both tools and linking
python3 ~/.agents/skills/troubleshoot-codex/scripts/generate-workspace-archive.py \
  --workspace /path/to/project \
  --output ./conversations

# Just codex-transcript-viewer (rich single-file per session)
python3 ~/.agents/skills/troubleshoot-codex/scripts/generate-workspace-archive.py \
  --workspace /path/to/project \
  --output ./conversations \
  --tool codex-transcript-viewer

# Parents only, no subagents
python3 ~/.agents/skills/troubleshoot-codex/scripts/generate-workspace-archive.py \
  --workspace /path/to/project \
  --output ./conversations \
  --no-include-subagents
```

This produces a linked directory structure:

```
conversations/
├── index.html                          ← lists all parent sessions
├── parent-session-title/
│   ├── index.html                      ← parent transcript
│   └── agents/
│       ├── index.html                  ← lists all subagents for this parent
│       └── nickname-task-slug/
│           └── index.html              ← subagent transcript
```

### Sharing transcripts

```bash
# Publish a single session as a GitHub Gist
codex-transcripts json SESSION.jsonl -o /tmp/session
codex-transcripts local --gist

# Generate a shareable HTML file
codex-transcript-viewer SESSION.jsonl session.html
```

### Limitations

- Neither `codex-transcripts` nor `codex-transcript-viewer` natively supports parent→child linking. The `generate-workspace-archive.py` script adds this by generating index pages.
- `codex-transcripts` paginates at ~5 prompts per page. Very long sessions produce many pages.
- `codex-transcript-viewer` produces a single file which can be large for long sessions (100+ prompts → ~1MB).

## Quick Reference Commands

```bash
# --- SQLite (primary data source) ---

# Check if a session is in the database
sqlite3 ~/.codex/state_5.sqlite "SELECT id, title, archived FROM threads WHERE id = 'SESSION_ID';"

# List sessions for a workspace
sqlite3 ~/.codex/state_5.sqlite "SELECT id, substr(title,1,50), thread_source, datetime(updated_at, 'unixepoch') FROM threads WHERE cwd = 'WORKSPACE_PATH' AND archived = 0 ORDER BY updated_at DESC LIMIT 20;"

# Find sessions with blank titles
sqlite3 ~/.codex/state_5.sqlite "SELECT id, title FROM threads WHERE title = '' OR title IS NULL;"

# Find parent of a subagent
sqlite3 ~/.codex/state_5.sqlite "SELECT parent_thread_id FROM thread_spawn_edges WHERE child_thread_id = 'SESSION_ID';"

# Read-only query while app is running (avoids DB lock)
sqlite3 "file:$HOME/.codex/state_5.sqlite?immutable=1" "SELECT id, title FROM threads WHERE id = 'SESSION_ID';"

# --- session_index.jsonl (secondary index) ---

# List all indexed sessions
cat ~/.codex/session_index.jsonl | jq -r '"\(.updated_at[:10]) \(.id[:8]) \(.thread_name)"' | sort -r

# Find duplicate entries in the index
cat ~/.codex/session_index.jsonl | jq -r '.id' | sort | uniq -d

# --- Transcript files ---

# Count sessions per day
find ~/.codex/sessions -name '*.jsonl' | sed 's|.*/sessions/||' | cut -d/ -f1-3 | sort | uniq -c | sort -rn

# Find sessions by working directory
grep -rl '"cwd":".*terminusdb' ~/.codex/sessions/

# Session size summary (largest sessions first)
find ~/.codex/sessions -name '*.jsonl' -exec ls -l {} \; | awk '{print $5, $NF}' | sort -rn | head -20

# Find sessions mentioning a keyword in conversation content
grep -rl 'keyword' ~/.codex/sessions/ | head -20

# Get session metadata (CWD, version, source) from a transcript
cat FILE.jsonl | jq -r 'select(.type == "session_meta") | .payload | {id, cwd, source, cli_version, model_provider, thread_source}' | head -1

# Compare session metadata (useful for debugging visibility)
head -1 FILE.jsonl | jq '{id: .payload.id, cwd: .payload.cwd, source: .payload.source, thread_source: .payload.thread_source}'

# --- Safety checks ---

# Check if app is running before editing
pgrep -x Codex > /dev/null && echo "STOP: Codex is running" || echo "Safe to edit"

# Check app logs for a session (zero hits = app doesn't know about it)
grep 'SESSION_ID' ~/Library/Logs/com.openai.codex/$(date +%Y/%m/%d)/*.log
```

## Scripts

The `scripts/` directory in this skill contains:

| Script | Purpose |
|--------|--------|
| `inspect-sqlite.py` | Query `state_5.sqlite` for thread diagnostics: lookup, workspace listing, orphan detection, health checks, and repair |
| `detect-phantom-sessions.sh` | Compare transcript files on disk against both `session_index.jsonl` and `state_5.sqlite`; report phantoms and ghosts |
| `extract-conversation.py` | Parse a JSONL transcript into a readable text conversation (user/agent message pairs with timestamps) |
| `session-summary.py` | Print a one-line summary of a session: ID, CWD, thread source, duration, message count, last event |
| `generate-workspace-archive.py` | Batch-generate HTML transcripts for all sessions in a workspace, with parent→child linking and index pages |

Run them from the skill directory:

```bash
# Query SQLite for thread diagnostics
python3 ~/.agents/skills/troubleshoot-codex/scripts/inspect-sqlite.py lookup SESSION_ID
python3 ~/.agents/skills/troubleshoot-codex/scripts/inspect-sqlite.py workspace
python3 ~/.agents/skills/troubleshoot-codex/scripts/inspect-sqlite.py health
python3 ~/.agents/skills/troubleshoot-codex/scripts/inspect-sqlite.py orphans
python3 ~/.agents/skills/troubleshoot-codex/scripts/inspect-sqlite.py edges SESSION_ID

# Repair (quit Codex first!)
python3 ~/.agents/skills/troubleshoot-codex/scripts/inspect-sqlite.py repair SESSION_ID --title "New Title"
python3 ~/.agents/skills/troubleshoot-codex/scripts/inspect-sqlite.py repair SESSION_ID --unarchive

# Find all phantom sessions across all dates (checks both JSONL and SQLite)
bash ~/.agents/skills/troubleshoot-codex/scripts/detect-phantom-sessions.sh

# Extract readable conversation from a specific session
python3 ~/.agents/skills/troubleshoot-codex/scripts/extract-conversation.py ~/.codex/sessions/2026/05/31/rollout-*.jsonl

# Quick summary of sessions (now includes thread source)
python3 ~/.agents/skills/troubleshoot-codex/scripts/session-summary.py ~/.codex/sessions/2026/05/31/rollout-*.jsonl
```
