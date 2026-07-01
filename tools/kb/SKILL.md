---
name: kb
description: >-
  Interface to the Obsidian knowledge base at ~/Me/kb. Use when creating notes,
  appending to logs, searching the vault, tagging, linking, or querying filing
  history. Backed by mcpvault (MCP) and obsidian-hybrid-search (CLI). Logging
  uses Obsidian Bases for structured cross-cutting queries.
  Trigger on: kb, note, log, jot, capture, knowledge base, vault, obsidian,
  "create note", "log entry", "filing log", "search notes", "search vault"
license: MIT
domain: knowledge-management
role: specialist
scope: operations
output-format: tool-calls
triggers:
  - kb
  - note
  - log
  - jot
  - capture
  - knowledge base
  - vault
  - obsidian
  - "create note"
  - "log entry"
  - "filing log"
  - "search notes"
  - "search vault"
---

<!-- TOC: Status | What this skill is NOT | Vault layout | Base schemas |
     Templates | Operations | Folder routing | Tooling | References -->

# kb — Obsidian Knowledge Base Interface

> **Status: tooling wired, contract declared, vault schema in progress.**
> The schemas and operations below are the target interface. The vault
> organisation at ~/Me/kb is in progress (see br issues `kb-schema-v34`
> and friends). Tooling is installed and wired (`mcpvault` MCP server,
> `obsidian-hybrid-search` CLI + MCP via LM Studio embeddings). The
> salvage skills (Phase 4) will target this contract.

## What this skill is NOT

| This is NOT… | Use instead |
|---|---|
| Ticketing / issue tracking | `br` — `br create`, `br list`, `br close`, `br dep` |
| File-finding across the filesystem | `filesearch` — where is a file on disk? |
| Orientation / drift-detection | `orientate` (salvage) — what's drifting across sources? |
| System governance / corpus tending | `system-self-care` (salvage) — rg/fd inspection + action bundles |
| Filing decisions (which folder?) | `filing-process` (salvage) — domain-sensitive routing rules |
| CLI / MCP tooling management | `mcp-manage` — adding, removing, configuring MCP servers |

This skill provides the **interface** those skills call. It does not
replace their domain logic.

## Vault layout

> **Target layout.** The `04-notes/` structure below is the intended schema,
> not the current state. The vault at `~/Me/kb` is being organised (see br
> issues `kb-schema-v34` and friends — the schema epic gates the folder
> creation). Operations below assume these folders exist; create them on
> first write if missing, or wait for the schema epic.

```
~/Me/kb/
├── 04-notes/
│   ├── note/          ← durable notes (kind: note)
│   ├── reflection/    ← reflections (kind: reflection)
│   ├── observation/   ← observations (kind: observation)
│   ├── decision/      ← decisions (kind: decision)
│   ├── design-brief/  ← design briefs (kind: design-brief)
│   ├── spec/          ← specifications (kind: spec)
│   ├── progress/      ← progress notes (kind: progress)
│   ├── log/           ← daily log entries + filing audit trail
│   │   ├── log.base        ← general log Base (see schema below)
│   │   └── filing.base     ← filing audit Base (see schema below)
│   └── templates/     ← note and log templates
├── 40-work/           ← domain: work
├── 50-business/       ← domain: business
├── 60-creative/       ← domain: creative
├── 70-research/       ← domain: research
└── ...
```

Notes land in `04-notes/{kind}/` by default. Domain folders (`40-work/`,
etc.) are for domain-specific material. The Base files in `04-notes/log/`
provide cross-cutting queries across all log entries regardless of folder.

## Base schemas

### General log (`04-notes/log/log.base`)

Queryable table over all log entries. Each entry is a markdown file in
`04-notes/log/` with this frontmatter:

| Field | Type | Required | Description |
|---|---|---|---|
| `date` | date | yes | ISO 8601 (`YYYY-MM-DD`) |
| `kind` | select | yes | `progress` / `reflection` / `observation` / `decision` / `design-brief` / `spec` |
| `ticket` | text | no | `br` issue ID (e.g. `kb-schema-v34`) |
| `domain` | select | no | `work` / `business` / `creative` / `research` / `system` |
| `tags` | list | no | Freeform tags |

The Base file filters by kind, date range, ticket, domain, and tags.
This replaces `me jot list` and `jurn` queries.

### Filing audit (`04-notes/log/filing.base`)

Queryable table over filing decisions. Each entry is a markdown file in
`04-notes/log/` with `kind: filing` and these additional fields:

> **Disambiguation from the general log Base.** Both Bases query
> `04-notes/log/`, and both key on `kind`. They are kept disjoint by the
> **additional required fields** a filing entry carries (`source_path`,
> `destination_path`, `rule`, `rationale`) — a writer creating a filing
> entry must populate all four; a general log entry must not. The filing
> Base filters on these fields; the general log Base excludes `kind: filing`.
> Do not rely on `kind` alone to tell them apart — rely on the presence of
> the filing fields.

| Field | Type | Required | Description |
|---|---|---|---|
| `date` | date | yes | ISO 8601 |
| `kind` | fixed | yes | Always `filing` |
| `source_path` | text | yes | Original location |
| `destination_path` | text | yes | New location |
| `rule` | text | yes | Filing rule applied (e.g. `F-R07`) |
| `rationale` | text | yes | Why this move |
| `batch_id` | text | no | For bulk operations |
| `count` | number | no | Files moved in batch |
| `tags` | list | no | Freeform tags |

The filing Base filters by source, destination, rule, date, and batch.
This replaces `me fs log list`.

## Templates

Template files live in `tools/kb/templates/` (this skill's directory).
To use a template, copy it and replace `{{placeholders}}`:

- **`note.md`** — general note (date, kind, tags, title, body)
- **`log-entry.md`** — log entry (adds ticket, domain)
- **`filing-entry.md`** — filing audit entry (source, destination, rule, rationale, batch, count)

When creating notes via mcpvault `write_note`, use the template as the
body and populate frontmatter fields directly.

## Operations

### Capture — create / write

| Operation | Tool call | Notes |
|---|---|---|
| Create note | mcpvault `write_note` | Path: `04-notes/{kind}/{slug}.md`. Use `note.md` template. |
| Create log entry | mcpvault `write_note` | Path: `04-notes/log/{date}-{slug}.md`. Use `log-entry.md` template. |
| Append to existing log | mcpvault `patch_note` (mode: `append`) | Append content to an existing log file. |
| Create filing entry | mcpvault `write_note` | Path: `04-notes/log/{date}-filing-{slug}.md`. Use `filing-entry.md` template. |
| Quick capture | mcpvault `write_note` | Single atomic write. Default kind: `note`. |

### Retrieve — search / read

| Operation | Tool call | Notes |
|---|---|---|
| Full-text search | mcpvault `search_notes` | BM25 relevance-ranked. |
| Semantic search | obsidian-hybrid-search `search --mode semantic` | For drift-detection, cross-source queries. |
| List by kind | mcpvault `list_directory` on `04-notes/{kind}/` | Or query the general log Base. |
| List by date | mcpvault `list_directory` on `04-notes/log/` | Sorted by filename (ISO date prefix). |
| Show one note | mcpvault `read_note` | Returns content + frontmatter. |
| Read several notes | mcpvault `read_multiple_notes` | Batch full reads — cheaper than N × `read_note`. |
| Note metadata only | mcpvault `get_notes_info` | Frontmatter + size + dates; no body. Cheap for orientation scans. |
| Frontmatter only | mcpvault `get_frontmatter` | Single note's frontmatter. Cheapest read. |
| Backlinks | obsidian-hybrid-search `--related --direction backlinks` | Who links to this note? |
| Query filing history | mcpvault `search_notes` on `04-notes/log/` with frontmatter filter | Or use the filing Base. |
| **Orientation — vault overview** | mcpvault `get_vault_stats` | Counts, recent activity, totals — for drift-detection and "what's changed" passes (the orientate/system-self-care use case). |
| **Orientation — all tags** | mcpvault `list_all_tags` | Tag inventory across the vault — surface clusters, find underused tags. |

### Structure — link / tag / move

| Operation | Tool call | Notes |
|---|---|---|
| Link notes | mcpvault `patch_note` (append `[[target]]`) | Wikilink syntax. |
| Tag | mcpvault `manage_tags` or `update_frontmatter` | Add to frontmatter `tags:` array. |
| Move to domain folder | mcpvault `move_note` | After kind/domain decided. |
| Update frontmatter | mcpvault `update_frontmatter` | Patch specific fields without touching body. |

### Ticketing — via `br`

Always resolve the actor at runtime: `ACTOR="${BR_ACTOR:-assistant}"` and
pass `--actor "$ACTOR"`. See `tools/br` for the full reference.

| Operation | Tool call | Notes |
|---|---|---|
| List issues | `br list --json` | Filter by `--status`, `-l/--label` (singular). |
| Show issue | `br show <id> --json` | Returns contract, notes, deps in one call. |
| Create issue | `br create --actor "$ACTOR" "title" --json` | With `-l/--label`, `-p/--priority`, `--slug`. |
| Comment on issue | `br comments add --actor "$ACTOR" <id> --message "text"` | Or `--file <path>` for backtick-rich text. Cross-link: note's `ticket` field ↔ br issue. |
| Close issue | `br close --actor "$ACTOR" <id> --reason "done"` | `--reason`, not `--comment`. |
| Dependencies | `br dep add <child> <parent>` | child depends on parent (parent blocks child). Positional IDs, no `--blocked-by` flag. |

## Folder routing

When creating a note, choose the folder by **kind**:

| Kind | Folder | When |
|---|---|---|
| `note` | `04-notes/note/` | General durable note |
| `reflection` | `04-notes/reflection/` | Thinking, analysis, lessons |
| `observation` | `04-notes/observation/` | Something noticed |
| `decision` | `04-notes/decision/` | A choice made and why |
| `design-brief` | `04-notes/design-brief/` | Design intent |
| `spec` | `04-notes/spec/` | Specification |
| `progress` | `04-notes/progress/` | Work-in-progress note |
| `log` | `04-notes/log/` | Time-stamped log entry |
| `filing` | `04-notes/log/` | Filing audit entry (kind: filing) |

Domain-specific material goes to `40-work/`, `50-business/`, etc. — but
only when the note is inherently domain-bound. Most notes live in
`04-notes/` and gain domain through frontmatter, not folder placement.

## Tooling

| Tool | Type | What it does |
|---|---|---|
| `mcpvault` | MCP server | CRUD + search + frontmatter + tags on the vault. 14 tools. |
| `obsidian-hybrid-search` | CLI + MCP | Semantic + fulltext + graph search. Used for drift-detection and backlinks. |
| `~/.lmstudio/bin/lms` | CLI | LM Studio model management — load/unload models, check server status. |
| `br` | CLI | Issue tracking. Ticketing operations go here, not through the vault. |

### MCP servers (canonical config: `~/Me/repos/mcps/servers.toml`)

Two MCP servers back this skill. Both are local, no secrets, no wrapper.
Deploy to all harnesses via `mcp-deploy deploy --harness <name>`.

**mcpvault** — vault CRUD + search (14 tools):

```toml
[servers.mcpvault]
command = "npx"
args = ["@bitbonsai/mcpvault@latest", "/Users/bear/Me/kb"]
```

**obsidian-hybrid-search** — semantic + fulltext + graph search:

```toml
[servers.obsidian-hybrid-search]
command = ".../obsidian-hybrid-search"
args = ["mcp", "--db", "/Users/bear/Me/kb/.obsidian-hybrid-search.db"]
env = { OBSIDIAN_VAULT_PATH = "/Users/bear/Me/kb", OPENAI_BASE_URL = "http://localhost:1234/v1", OPENAI_EMBEDDING_MODEL = "text-embedding-nomic-embed-text-v1.5" }
```

Embeddings use **LM Studio** (local, OpenAI-compatible API at
`localhost:1234`). The model `text-embedding-nomic-embed-text-v1.5` must
be loaded in LM Studio for indexing and search to work.

### Hybrid search CLI usage

```bash
# Index files (scoped — don't index the whole vault at once)
cd ~/Me/kb
obsidian-hybrid-search reindex "path/to/note.md"

# Search
obsidian-hybrid-search search "query"                          # hybrid (default)
obsidian-hybrid-search search "query" --mode semantic          # semantic only
obsidian-hybrid-search search --path "note.md" --related       # backlinks

# Status
obsidian-hybrid-search status
```

The DB at `.obsidian-hybrid-search.db` was created with `embedding_dim:
768` to match the nomic model. If the embedding model changes, delete
the DB and reindex (dimension mismatch errors mean the DB was created
with a different model).

### LM Studio management (`~/.lmstudio/bin/lms`)

The embedding model must be loaded in LM Studio before indexing or
search. Use `lms` to manage this without the GUI:

```bash
~/.lmstudio/bin/lms ps              # what's loaded in memory
~/.lmstudio/bin/lms ls              # what's available on disk
~/.lmstudio/bin/lms load text-embedding-nomic-embed-text-v1.5
~/.lmstudio/bin/lms unload text-embedding-nomic-embed-text-v1.5
~/.lmstudio/bin/lms server status   # is the API server running?
```

## References

- `docs/phase1-brief.md` — the brief that produced this skill
- `docs/skills-audit.md` — facet framework, salvage triage table
- `tools/br/SKILL.md` — ticketing interface (this skill delegates to br)
- `tools/filesearch/SKILL.md` — file-finding (this skill is NOT file-finding)
- `tools/skills-manage/SKILL.md` — skill store conventions
