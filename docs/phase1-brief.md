# Phase 1 Brief — Note/Logging Successor + Interface Skill Stub

**Audience:** executing agent. **Reviewer/consolidator:** the supervisor
(the agent that produced `docs/skills-audit.md`). **Report back at each
checkpoint** — do not run to completion without review.

## Background you must read first

- `docs/skills-audit.md` — the facet framework, the me-CLI salvage triage
  table, and the "working assumption" for Phase 1. This brief extends that.
- The me-CLI is dead. Twelve skills still drive it; six are salvage
  candidates (`orientate`, `system-self-care`, `change-manage`,
  `feature-build`, `filing-process`, `jot-capture`). They cannot be
  rewritten until a live note/logging mechanism exists. That mechanism is
  Phase 1's deliverable.

## The actual state on the ground (verified 2026-06-30)

Do **not** assume the audit doc's "provisional markdown logs" framing is
the whole picture. Verified facts:

- `~/Me/kb` — ~27,900 files, ~13,500 `.md`. A dump of Obsidian + Logseq +
  NotePlan exports plus non-note junk (~1,350 `.py`/`.pyc`/`.dist-info` — a
  vendored package got dropped in). Mixed conventions: numbered folders
  (`50`, `32`, `34`, `60`), semantic folders (`journal/`, `40-work/`,
  `tickets/`, `noteplan-notes/`), loose top-level notes. **Not a vault with
  a schema; the "waiting to be organised" state.**
- `scratch log` wraps `jurn`, which is **SQLite-DB-backed** (not markdown).
  `jurn log -m <msg> -t <tag>` writes to a per-project local DB with tag
  hierarchies. Current logging is therefore database-backed, not the
  per-directory markdown the audit assumed.
- Per-directory `log/` folders also exist across `~/Me` (records/, inbox/,
  archive/, etc.) — a parallel, lower-tech convention.
- **No Obsidian CLI or MCP is installed.** `obsidian-cli`/`obs` not found;
  no obsidian MCP in the zcode config. "Standardise on Obsidian" is a
  future intention, not a present capability.

## Scope boundary — what is and is NOT this brief

**In scope (this brief):**
1. Recommend + install the Obsidian tooling (CLI + MCP).
2. Design the note/logging **interface contract** — the operations the
   salvage skills will call (create note, append log, search, link,
   query by tag/folder, etc.).
3. Create a **stub skill** (`tools/kb` or `tools/obsidian`) that declares
   that contract as a skill: frontmatter, trigger language, and the
   command surface — built toward, not yet fully wired.

**Out of scope (separate workstream, owner = the user):**
- Organising `~/Me/kb` into a real vault (consolidating Logseq/Obsidian/
  NotePlan, deciding folder/link schema, handling junk). That is a
  knowledge-management migration. This brief produces the *interface* the
  vault will expose; it does not migrate the vault.

The dependency: salvage rewrites (Phase 4) target the contract from (2)/(3).
The vault org runs in parallel and must honour the same contract.

## Deliverables

### D1 — Tooling recommendation (checkpoint: report back before installing)

Survey the realistic Obsidian CLI + MCP options. The user has said
"Obsidian, which has a cli and an mcp" — identify the specific projects,
their maturity, and their fit. Candidates to evaluate (non-exhaustive —
search):
- Obsidian MCP servers (e.g. `mcp-obsidian`, `obsidian-mcp` variants).
- CLIs (`obsidian-cli`, `obz`, vault-sync tools).

For each: install method, what operations it exposes, whether it needs the
Obsidian app running, active-maintenance signal, and any auth/setup
friction. **Report back with a recommendation and the one-line reason
before installing anything.** The user picks.

### D2 — Interface contract (checkpoint: report back before stubbing)

Define the operations the salvage skills need. Derive these from what the
six salvage skills actually do today (read their `me jot`/`me tk note`/
`me fs` usage). Likely surface, to confirm against the real skills:

- **Capture:** create a note (kind: note/reflection/observation/decision/
  design-brief/spec/progress); append to a log; quick-capture.
- **Retrieve:** list by kind/date/tag; full-text search; show one with
  links; semantic search (if the tool offers it).
- **Structure:** link notes; tag; folder placement; backlinks.
- **Orientation:** "what's recent / what's drifting" queries across notes
  (the `orientate`/`system-self-care` use case).

Output a table: operation → command/tool call → notes. **Report back with
the contract table for review before writing the stub.** The reviewer
checks it covers all six salvage skills' actual usage.

### D3 — Stub skill (after D1+D2 approved)

Create `tools/kb/SKILL.md` (or `tools/obsidian/` — your call, justify).
Must have:
- Sharp frontmatter + trigger language (learn from `br`/`lark-crm`/`zcode`
  — the best skills bake triggering in at authoring time; this is Phase 5's
  lesson applied early).
- The D2 contract as its command surface, marked as "target interface —
  vault + tooling wiring pending Phase 1 D1."
- Explicit non-overlap routing (like `filesearch`'s "what this skill is
  NOT" section): this is NOT ticketing (→ `br`), NOT file-finding (→
  `filesearch`), NOT orientation itself (→ the salvaged `orientate`).
- A status banner: "stub — contract declared, wiring pending."

Do **not** add it to `global-manifest.toml` yet. It's a contract artifact
until the tooling lands and the vault org progresses.

## Constraints

- **Report at each checkpoint.** Do not install tooling, write the
  contract, or ship the stub without the reviewer's go at the prior step.
- Match the repo's skill conventions (see `tools/skills-manage`, the README
  "Skill format" section, and existing `tools/` skills for voice/structure).
- If you find the six salvage skills need operations the candidate
  tooling can't expose, surface that as a finding — do not paper over it.

## Done looks like

D1 recommendation chosen + installed (if approved); D2 contract table
agreed; D3 stub skill committed with the contract, status-bannered, not yet
global. Phase 4 (salvage rewrites) then has a concrete target.

## Related

- `docs/skills-audit.md` — Phase 4 salvage table
- `skills-2gs` — Phase 2 (independent; runs in parallel)
- Open question for the user: does `jurn`'s SQLite logging get migrated
  into the Obsidian vault, or stay as a parallel structured-log tool?
  Flag this in D2; it affects the logging half of the contract.
