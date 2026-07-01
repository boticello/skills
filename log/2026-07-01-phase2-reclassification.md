# Phase 2: Global-Default Reclassification (skills-2gs)

**Date:** 2026-07-01
**Agent:** executing agent (bear)
**Ticket:** skills-2gs
**Commits:** `58b6835` (manifest edit), `2fe2c4c` (beads sync)

## Summary

Reclassified `global-manifest.toml` from 76 skills to **39 role-universal
skills**. 37 skills moved out of global default into project-add territory.
No skill directories deleted — all remain in-repo and available via a
project's `add`.

## What moved out (37 skills)

### Dead mechanism — me-CLI (13)
Phase 4 decides salvage-rewrite vs archive. Removed from global to stop
auto-triggering now.

- `change-manage`, `database-migration`, `feature-build`, `filing-process`,
  `jot-capture`, `location-manage`, `orientate`, `project-manage`,
  `remind-management`, `shopping-management`, `source-management`,
  `subscription-management`, `system-self-care`

### Domain-niche (14)
Specialist languages, domains, and tool integrations not present in most
sessions.

- **Languages:** `clojure`, `fsharp`, `nushell`, `ruby`
- **Domain:** `pharmaceutical-definition-creator`, `ruby-code-analysis`
- **Tools:** `troubleshoot-codex`, `logseq-markdown`, `csv-data-summarizer`,
  `last30days`, `nia`, `omnigraph`, `tapestry`, `total-recall`

### Experimental — go-slice unit (5)
Preserved as a unit, pending spin-off decision.

- `go-slice-implementer`, `go-slice-planner`, `go-slice-reviewer`,
  `slice-retro`, `slice-supervisor`

### WIP skeleton (1)
Self-flagged `status: tbc`, `maturity: skeleton`, dead `document-management`
dependency. Audit says "clearly archive regardless."

- `orchestration`

### Vendored library — tapestry deps (3)
Library components consumed by the tapestry orchestrator.

- `article-extractor`, `ship-learn-next`, `youtube-transcript`

### Vendored niche (1)
Railway-specific deployment context, gitignored vendor/ skill.

- `use-railway`

## What stayed in global (39 skills)

The role-universal core: agent-workflow scaffolding, VCS skills, review/debug
tools, documentation, project management utilities, and the two active
vendored integrations (lark-crm, almanac).

Full list in `global-manifest.toml`.

## Corrections to the Phase 2 brief

1. **`lark-crm` and `almanac` are not vendored.** They live in `personal/`
   and `tools/` respectively — authored, git-tracked. The brief incorrectly
   grouped them under "Vendored (gitignored)." They clearly stay global.

2. **`use-railway` is vendored** (in `vendor/`, gitignored). The brief listed
   it under "Clearly stay IN global" — corrected to domain-niche, moved out.

3. **Manifest comment was stale.** Header said "81 skills" — actual count was
   76 pre-edit. Fixed to "39 skills."

## Deploy

- `./deploy/skills-deploy deploy` — clean
- Both targets (`~/.agents/skills/`, `~/.codex/skills/`): 39 unchanged,
  37 removed per target, all backed up to `~/.local/state/skills-backups/`
- `codex-primary-runtime` allowlisted (untouched in `.codex/`)

## What this phase did NOT do

- No skill directories deleted
- No salvage rewrites (Phase 4)
- No trigger-quality changes (Phase 5)
- No coding-agent architecture decisions (Phase 3)

## Next

- **Phase 1** (Obsidian note/filing successor) — independent, gates Phase 4
- **Phase 3** (coding-agent architecture) — independent, may restructure the
  supervisor/orchestration/VCS cluster
- **Phase 4** (salvage rewrites) — blocked on Phase 1
- **Phase 5** (trigger-quality) — last; waits on all prior churn
