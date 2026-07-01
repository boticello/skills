# Phase 1: Note/Filing Successor + Interface Skill Stub

**Date:** 2026-07-01
**Agent:** executing agent
**Ticket:** skills-skills-phase1-2s7
**Brief:** `docs/phase1-brief.md`

## Summary

Delivered the Phase 1 brief: Obsidian tooling installed and provisioned as
MCP servers across all harnesses, interface contract defined from the six
salvage skills' actual usage, and a stub skill (`tools/kb`) committed with
two Base schemas, templates, and routing. Phase 4 (salvage rewrites) now
has a concrete target.

## D1 — Tooling recommendation + install

**Recommended and installed:**

- **mcpvault** (`@bitbonsai/mcpvault` v0.12.1) — standalone MCP server,
  filesystem-based, 14 tools (CRUD + search + frontmatter + tags). No
  Obsidian app dependency. 1.5k stars, 134 releases, CVE checked (path
  traversal fixed in 0.11.4, we're on 0.12.1).
- **obsidian-hybrid-search** v0.13.16 — semantic + fulltext + graph search
  CLI/MCP. BM25 + vector embeddings + fuzzy title + wikilinks + backlinks.
  509 commits, 134 releases.

**Rejected:** obsidian-mcp (stale npm), mcp-obsidian (stale npm),
obsidian-export (read-only), obsidian-vault-cli (experimental), all
app-dependent options (adds operational fragility).

**MCP provisioning correction:** Initial install was `npm install -g` only
— binaries on `$PATH` but no harness registered. Corrected per `mcp-manage`
workflow: added both to `~/Me/repos/mcps/servers.toml`, deployed to all 5
harnesses (zcode, opencode, warp, codex, zed), verified idempotent, probed
both over stdio with real data calls. Ticket `mcps-p1g` (closed).

## D2 — Interface contract

Derived from reading all six salvage skills' SKILL.md files. Three distinct
write surfaces identified:

- `me jot` → generic durable notes (5 of 6 skills)
- `me tk note` → ticket-attached progress notes (2 of 6)
- `me fs log` → structured filing audit trail (1 of 6)

**Contract:** 4 operation groups (Capture, Retrieve, Structure, Ticketing)
mapped to mcpvault tools + `br` commands. Two separate Base schemas for
structurally different data models:

1. **General log** (`04-notes/log/log.base`) — `kind`, `date`, `ticket`,
   `domain`, `tags`. Replaces `me jot list` and `jurn` queries.
2. **Filing audit** (`04-notes/log/filing.base`) — `source_path`,
   `destination_path`, `rule`, `rationale`, `batch_id`, `count`. Replaces
   `me fs log list`.

**Decision:** `jurn` SQLite logging retired; logging becomes Obsidian Base
convention. Filing audit is a separate Base (different data model).

**Gap flagged:** `filing-process` uses structured `me fs log` fields that
mcpvault has no native concept for. Mapped to frontmatter convention; the
skill must write correctly.

## D3 — Stub skill

Created `tools/kb/`:

```
tools/kb/
├── SKILL.md                       (236 lines)
└── templates/
    ├── note.md                    (general note)
    ├── log-entry.md               (log entry with ticket + domain)
    └── filing-entry.md            (filing audit with source/dest/rule)
```

**SKILL.md contents:** Rich frontmatter (br/lark-crm convention), status
banner ("stub — contract declared, wiring pending"), NOT section (6
delegations: br, filesearch, orientate, system-self-care, filing-process,
mcp-manage), two Base schemas with field tables, templates, 4 operation
groups mapped to tool calls, folder routing by kind, tooling config
(mcpvault MCP + hybrid-search CLI), references.

**Not added to `global-manifest.toml`** — per the brief. Contract artifact
until vault org progresses.

## What this phase did NOT do

- No vault organisation (out of scope, user's workstream)
- No salvage rewrites (Phase 4)
- No trigger-quality changes (Phase 5)
- No coding-agent architecture decisions (Phase 3)

## Related kb br tickets

Checked the 6 open kb tickets. **`kb-schema-v34`** (Establish kb vault
schema) is partially addressed — the logging schema and Base structure are
defined, but the broader vault schema (folder hierarchy, domain routing,
the 40/ triage) remains open. The other 5 tickets (folder40, codex-skills,
loose-notes, empty-jd, noteplan) are untouched — they're vault-org work,
not Phase 1 scope.

## Commits / changes

- `tools/kb/SKILL.md` — new (stub skill)
- `tools/kb/templates/*.md` — new (3 templates)
- `~/Me/repos/mcps/servers.toml` — mcpvault + obsidian-hybrid-search added
- All 5 harness configs — deployed via `mcp-deploy`
- `mcps-p1g` — opened and closed

## Next

- **Phase 2** (scoping pass) — independent, already done (`skills-2gs`)
- **Phase 3** (coding-agent architecture) — independent
- **Phase 4** (salvage rewrites) — **unblocked**. Target: `tools/kb` contract.
  Rewrite `jot-capture`, `orientate`, `system-self-care`, `change-manage`,
  `feature-build`, `filing-process` against mcpvault + br.
- **Phase 5** (trigger-quality) — last
