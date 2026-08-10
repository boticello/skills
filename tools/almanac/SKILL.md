---
name: almanac
description: Manage CodeAlmanac wikis — build, ingest, capture, garden, search, and monitor background jobs. Use when the user wants to create or maintain an Almanac wiki, ingest external documents, capture agent transcripts, or query wiki contents.
triggers:
  - almanac
  - CodeAlmanac
  - almanac wiki
  - ingest documents
  - garden wiki
---

# Almanac Wiki Management

You are managing a [CodeAlmanac](https://github.com/AlmanacCode/codealmanac) wiki — a living knowledge base for codebases, maintained by AI agents.

## Prerequisites

- `almanac` CLI installed globally (`npm install -g codealmanac`)
- An LLM provider configured: `almanac agents list` shows readiness
- Run from inside a git repo that has (or will have) a `.almanac/` directory

## Provider Setup

Almanac needs an LLM provider for write operations (`init`, `capture`, `ingest`, `garden`). Read-only commands (`search`, `show`, `list`, `health`, `tag`) don't need one.

Supported providers: `claude`, `codex`, `cursor`.

```bash
# Check provider status
almanac agents list

# Switch provider
almanac agents use claude

# Set model
almanac agents model claude claude-sonnet-4-6
```

Environment overrides (no config file needed):
- `ALMANAC_AGENT` — override default provider
- `ALMANAC_MODEL` — override default model

### Codex Config Parse Error (Known Issue)

If `~/.codex/config.toml` has a `[permissions.*.filesystem]` section with `glob_scan_max_depth` (integer) or `:workspace_roots` (colon-prefixed key), Almanac's Codex adapter fails:

```
failed to load configuration: ~/.codex/config.toml:76:2:
data did not match any variant of untagged enum FilesystemPermissionToml
```

**Fix:** Use Claude as provider instead. All write operations support `--using claude` to override, or set it globally with `almanac agents use claude`.

**No custom endpoint support.** Almanac does not support `base_url` config, OpenRouter, or other OpenAI-compatible proxies. Only native provider auth works.

## Core Workflow

### 1. Initialize a Wiki

```bash
almanac init --using claude --yes --background --json
```

Builds the initial wiki from the codebase. Takes 5-15 min depending on repo size. Cost: $1-3.

### 2. Ingest External Documents

```bash
almanac ingest ../design/ ../plans/ ../reports/ --yes --json
```

Reads files outside the repo, extracts knowledge, creates/updates wiki pages. Paths are relative to the repo root. Cost: $0.50-2 per batch.

### 3. Garden (Maintain)

```bash
almanac garden --yes --json
```

Cleans up, reconciles, and improves the wiki. Run periodically. Cost: $0.50-1.

## Capturing Codex Transcripts

Capturing knowledge from Codex sessions is the most complex operation. Here is what you need to know.

### Architecture

Codex uses a supervisor/subagent model. The supervisor thread contains the full conversation context. Subagent threads do individual tasks and report back. Supervisor threads have `thread_source: "user"` in their JSONL; subagents have `thread_source: "subagent"`.

Transcripts live at `~/.codex/sessions/YYYY/MM/DD/rollout-*.jsonl`.

### Why `capture sweep` Finds Zero Codex Sessions

`almanac capture sweep --apps codex` scans `~/.codex/sessions/` and maps each session's `cwd` to a registered wiki. Two things can cause 0 results:

1. **Codex config parse error** — the Codex adapter can't load `~/.codex/config.toml`, preventing any Codex-related discovery.
2. **cwd mismatch** — sessions may have `cwd` pointing to a parent workspace (e.g., `terminusdb-agent-interface/`) while the wiki is registered in a subdirectory (`sys-agent-terminusdb-python/`).

### Direct File Capture

Pass transcript files directly to bypass sweep discovery:

```bash
# Single session
almanac capture --app codex "/path/to/rollout-*.jsonl" --using claude --yes --json

# Multiple sessions
almanac capture --app codex file1.jsonl file2.jsonl --using claude --yes --json
```

### File Size Limitation

Claude's Read tool has a **256KB file size limit** and a **25,000 token limit per read**. Large transcript files (5MB+) cause problems:

- `almanac capture` tries to read the whole file, hits the limit, then reads in chunks. This is slow and expensive.
- `almanac ingest` on a transcript file behaves similarly — the agent reads chunks via `head`/`tail`/`jq` in Bash calls.

**Practical guidance:** Sessions under ~250KB work smoothly. For larger sessions, the agent will work but may burn significant tokens ($1-3 per large session) reading the file in pieces.

### Finding Codex Sessions for a Repo

Use the `find-codex-sessions.py` script from the skill's `scripts/` directory:

```bash
# Supervisor sessions only (default), sorted by size descending
python3 scripts/find-codex-sessions.py terminusdb

# Include subagent threads
python3 scripts/find-codex-sessions.py terminusdb --all

# Sort by date instead of size
python3 scripts/find-codex-sessions.py terminusdb --sort date
```

Replace `terminusdb` with a substring that identifies the workspace. The keyword match is case-insensitive against each session's `cwd`.

### Capture Strategy

1. **Ingest reports first.** If phase reports or design docs exist, ingest those first (`almanac ingest ../reports/`). They're concise and cheap.
2. **Capture supervisor threads second.** These have the richest context.
3. **Skip subagent threads.** They report to the supervisor; their unique content is usually already in reports.

## Monitoring Background Jobs

Write operations run as background jobs.

```bash
# List all jobs
almanac jobs list

# Stream live logs
almanac jobs attach <run-id>

# View run log
almanac jobs logs <run-id>

# Cancel a running job
almanac jobs cancel <run-id>
```

### Progress Check Scripts

Helper scripts live in the skill's `scripts/` directory. Run them from inside the repo (where `.almanac/` exists), or pass the repo path as an argument.

**Check latest job:**
```bash
python3 scripts/latest-job-status.py
python3 scripts/latest-job-status.py /path/to/repo
```

**Check all running jobs:**
```bash
python3 scripts/running-jobs.py
python3 scripts/running-jobs.py /path/to/repo
```

**Cost summary for all jobs:**
```bash
python3 scripts/job-cost-summary.py
python3 scripts/job-cost-summary.py /path/to/repo
```

## Querying the Wiki

### Search

```bash
almanac search "safety principles"
almanac search --topic architecture --topic decisions
almanac search --mentions src/transport.py
almanac search --since 1w
almanac search --summaries     # slugs + one-line summaries
almanac search --slugs          # just slugs
almanac search --json           # structured JSON
```

### Show Pages

```bash
almanac show <slug>             # full page
almanac show <slug> --body      # body only
almanac show <slug> --meta      # metadata only
almanac show <slug> --lead      # first paragraph
almanac show <slug> --backlinks # incoming links
almanac show <slug> --links     # outgoing links
almanac show <slug> --json      # structured JSON
```

### Topics

```bash
almanac topics list             # all topics with page counts
almanac topics show <slug>      # topic detail
almanac tag <page> t1 t2        # add topics to a page
almanac untag <page> <topic>    # remove a topic
almanac topics create <name>
almanac topics rename <old> <new>
almanac topics describe <slug> "description"
```

### Health Check

```bash
almanac health      # orphans, stale pages, broken links, etc.
almanac doctor      # full install + provider + wiki diagnostic
```

## Wiki Registry

Almanac tracks wikis in `~/.almanac/registry.json`.

```bash
almanac list --verbose          # list all registered wikis
almanac list --drop <name>      # remove a stale entry
```

## Setup & Automation

```bash
almanac setup --yes --agent claude   # full setup
almanac automation install           # install launchd jobs
almanac automation status            # check status
```

Automation schedules:
- Auto-capture every 5h (45m quiet window)
- Garden every 2d

## Local Wiki Viewer

```bash
almanac serve             # http://127.0.0.1:3927
almanac serve --port 8080
```

## Cost Reference

Typical costs with Claude (claude-sonnet-4-6):

| Operation | Cost | Duration |
|-----------|------|----------|
| `init` (build wiki, ~10 src dirs) | $1-3 | 10-15 min |
| `ingest` (3 design docs) | $1.50 | 5 min |
| `ingest` (25 plans + reports) | $1.15 | 5 min |
| `capture` (single small session) | $1 | 2 min |
| `capture` (large 12MB session) | $3-5+ | 15-30 min |
| `garden` | $0.50-1 | 5 min |

## Troubleshooting

### Codex config parse error
Use Claude: `almanac agents use claude`. See "Codex Config Parse Error" above.

### Stale registry entry
`almanac list --drop <name>`

### Corrupted index
`almanac reindex`

### Provider auth issues
```bash
almanac agents doctor
claude auth status
```

### Large transcript files
The Claude agent reads them in chunks (via `head`/`tail`/`jq`). It works but is slow and expensive. For sessions over 5MB, consider whether the knowledge is already captured in reports that can be ingested instead.

### Dead refs from external ingests
When ingesting files from outside the repo (e.g., `../design/`), pages may reference those source files as dead refs in `almanac health`. This is expected — the source files don't exist inside the repo.
