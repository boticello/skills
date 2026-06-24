# skills

The single source of truth for AI agent skills. Hand-edit here; `skills-deploy`
copies to each harness target directory. No registries, no lockfiles, no
symlinks in the deploy path — the directory tree *is* the state.

```
~/Me/repos/skills/          ← AUTHORITATIVE (this repo, git-tracked)
├── <category>/<skill>/     ← authored skills (tracked → GitHub)
├── vendor/<skill>/         ← third-party skills (gitignored → local only)
├── SOURCES.toml            ← provenance for vendor/ (url + commit)
├── allowlist.txt           ← target entries deploy must never remove
└── deploy/skills-deploy    ← the deploy script
```

## Workflow

Edit a skill, then deploy:

```bash
# Copy canonical → all harness targets (idempotent; skips unchanged)
./deploy/skills-deploy deploy

# Preview what would change without writing
./deploy/skills-deploy deploy --dry-run
```

Targets (never hand-edit — these are generated):
- `~/.agents/skills/` — ZCode, Zed, Warp, Memo, opencode-CLI
- `~/.codex/skills/`  — Codex (`.system/` built-ins and plugin symlinks skipped)

Re-running `deploy` with no changes touches nothing.

## Add a third-party skill

```bash
# Fetch via git with provenance recorded in SOURCES.toml
./deploy/skills-deploy fetch owner/repo                 # single-skill repo
./deploy/skills-deploy fetch owner/repo --skill name    # pick one from multi-skill
./deploy/skills-deploy fetch owner/repo --list          # see what's inside

# Then deploy to fan it out
./deploy/skills-deploy deploy
```

Vendored skills live in `vendor/` (gitignored), so they deploy locally but
aren't pushed to GitHub. `SOURCES.toml` (tracked) records each one's URL and
commit so they're reproducible on a fresh machine:

```bash
# On a new machine: re-fetch each vendored skill from SOURCES.toml, then deploy.
```

## Adopt a stray skill already in a target

If a skill exists in a harness target but not here yet:

```bash
./deploy/skills-deploy gather <name>                       # auto-detect source
./deploy/skills-deploy gather <name> --from codex          # specify source
./deploy/skills-deploy gather <name> --category tools      # specify category
```

This copies the skill from the target into the canonical store. Run `deploy`
afterward to make the target a clean mirror.

## What's here

80 skills across 13 categories:

| Category | Skills |
|----------|--------|
| **agent-workflow** | agent-commit-workflow, agent-implementation-strategy, agent-task-boundaries, agent-vcs-workflow-with-jj, supervisor |
| **analysis** | file-introspection |
| **debug** | code-debug, root-cause-debugger |
| **domain** | pharmaceutical-definition-creator, ruby-code-analysis |
| **go-slice** | go-slice-implementer, go-slice-planner, go-slice-reviewer, slice-retro |
| **knowledge-management** | documentation-writing, documentation-writer, typst |
| **languages** | clojure, fsharp, nushell, ruby |
| **personal** | change-manage, concept-boundary-test, concept-layer-synthesis, feature-build, filing-process, jot-capture, lark-crm, location-manage, me-feature-build, orientate, project-manage, shopping-management, slice-supervisor, source-management, subscription-management, system-self-care, ticket-audit, ticket-find, ticket-management, zcode |
| **planning** | discovery-architect, feature-handoff, orchestration, plan, spike-planning, ticket-closedown, update-docs, wrap, write-design-doc |
| **review** | code-review, remind-management, retro, verify |
| **tools** | almanac, br, cbm, cheatsheets, database-migration, fs-reorg, tool-eval, troubleshoot-codex |
| **vcs** | git-change-manage, git-vcs, jj-change-manage, jj-vcs, work-unit-manage |
| **vendor/** (gitignored) | article-extractor, csv-data-summarizer, last30days, logseq-markdown, nia, omnigraph, ship-learn-next, tapestry, total-recall, use-railway, youtube-transcript |

## Skill format

Every skill is a directory containing a `SKILL.md` with standardised frontmatter:

```yaml
---
name: skill-name
description: What this skill does
---

# Skill Name

Instructions for the agent...
```

All target harnesses read this identical format — only the parent directory
differs, so `deploy` is a flat copy with no translation.

## Craft Agents (manual — out of automation)

Craft Agents is pull-based and workspace-scoped, not repo-local auto-loaded.
Skills are `@mention`-ed into conversations and managed via the Craft desktop
UI. It cannot be driven by the deploy script.

To use a skill in Craft, copy its folder manually from `originals/` or
`vendor/` into the relevant Craft workspace via the UI. This is a one-way,
manual step — Craft is intentionally a bootstrap/export surface, not a deploy
target.

## Design notes

- **No registry to rot.** The repo directory tree is the only state. Previous
  attempts (skillkit, skillfish) maintained lockfiles that drifted from
  reality. This script has no state of its own.
- **Copies, not symlinks.** Codex has a known bug where symlinked skill dirs
  silently fail to load. Deploy always writes real directories.
- **Backups, not deletions.** Skills removed from a target during mirror
  cleanup are moved to `~/.local/state/skills-backups/<timestamp>/`, never
  destroyed.
- **Scoped to skills only.** This deliberately does not sync MCP config, rules,
  providers, profiles, or hooks. Those are separate concerns (a prior,
  over-ambitious attempt to unify everything stalled under that scope).

## License

Apache 2.0 (for the authored/original skills). Vendored skills retain their
upstream licenses — see `SOURCES.toml` for each one's origin.
