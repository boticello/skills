# skills

The authoritative catalogue for agent skills. A skill is a directory containing
`SKILL.md`; the repository tree is the catalogue. `tooling/skills` provides the
Ruby manager that validates the catalogue and mirrors the selected skills into
agent harnesses. It never makes symlinks in a managed target.

```
~/Me/repos/skills/          ← AUTHORITATIVE (this repo, git-tracked)
├── <category>/<skill>/     authored skills
├── vendor/<skill>/         locally vendored third-party skills
├── SOURCES.toml            vendor provenance (URL, commit, optional path)
├── global-manifest.toml    curated global selection
├── allowlist.txt           target entries a mirror must leave alone
└── tooling/skills/         Ruby manager, tests, and configuration
```

## Manager

Run the manager from the repository root:

```bash
tooling/skills/bin/skills list
tooling/skills/bin/skills lint
tooling/skills/bin/skills doctor
tooling/skills/bin/skills deploy                 # preview only
tooling/skills/bin/skills deploy --apply         # make the planned changes
```

The configured launch target is `~/.agents/skills`. It is shared by ZCode,
Zed, Warp, Memo, opencode and Codex. `~/.codex/skills` is not a future deploy
target; migration removes only the managed copies there, with backups, and
leaves non-managed content alone.

All state-changing commands preview by default. Add `--apply` to write.
Commands return `0` when clean, `1` for reported problems, and `2` for usage
errors. Every command accepts `--json` for agent consumption. On first use the
entrypoint installs missing locked gems with Bundler, then restarts itself.

Run the complete network-free test suite from the Ruby project:

```bash
cd tooling/skills
bundle check
bundle exec ruby -Ilib -Itest -e 'Dir["test/test_*.rb"].sort.each { |file| require_relative file }'
```

### Curate and deploy

`global-manifest.toml` is a curated global set, not a registry of every skill
in this repository.

```bash
# Show every discovered skill, its home, global selection and target drift.
tooling/skills/bin/skills list

# Preview then change the global manifest.
tooling/skills/bin/skills enable skill-name
tooling/skills/bin/skills enable skill-name --apply
tooling/skills/bin/skills disable skill-name --apply

# Project resolution is (global - exclude) + add.
tooling/skills/bin/skills deploy --project ~/Me/code/myproject
tooling/skills/bin/skills deploy --project ~/Me/code/myproject --apply
```

A project manifest lives at `<project>/.agents/skills-manifest.toml`:

```toml
add = ["project-only-skill"]
exclude = ["global-skill-not-needed-here"]
```

Add parent directories containing managed projects to `project_roots` in
`tooling/skills/skills.toml`. `list` and `doctor` recursively discover project
manifests beneath those roots; `--project PATH` checks an explicit project.

Mirror removals are moved to `${XDG_STATE_HOME:-~/.local/state}/skills-backups/<timestamp>/`;
allowlisted entries and target symlinks are left untouched. Managed copies omit
`.DS_Store`, `.skillkit.json`, `.skillfish.json`, and `.git`.

## Add a third-party skill

```bash
tooling/skills/bin/skills fetch owner/repository --list
tooling/skills/bin/skills fetch owner/repository --skill skill-name
tooling/skills/bin/skills fetch owner/repository --skill skill-name --apply
tooling/skills/bin/skills update skill-name --apply
tooling/skills/bin/skills fetch --all --apply
```

Vendored skills live in `vendor/` (gitignored), so they deploy locally but
aren't pushed to GitHub. `SOURCES.toml` (tracked) records each one's URL and
commit so they're reproducible on a fresh machine:

```bash
# Rehydrate local vendor copies from tracked provenance.
tooling/skills/bin/skills fetch --all --apply
```

## Adopt a stray skill already in a target

If a skill exists in a harness target but not here yet, the manager
auto-detects it in configured targets:

```bash
tooling/skills/bin/skills gather stray-skill
tooling/skills/bin/skills gather stray-skill --apply
```

Use `--from <target-root-or-skill-dir>` when the source is elsewhere:

```bash
tooling/skills/bin/skills gather stray-skill --from /path/to/skills
```

This copies the skill from the target into the canonical store. Run `deploy`
afterward to make the target a clean mirror.

## Skill format

Every skill is a directory containing `SKILL.md` with frontmatter:

```yaml
---
name: skill-name
description: A concise functional description.
triggers:
  - when this capability is needed
---
```

The directory name and frontmatter `name` must agree. `lint` checks duplicate
names, dead references, dead manifest/profile entries and basic selection
quality. Use `overlap` to review competing trigger language. The authoritative
operating model is in the [design record](docs/skills-tool-design-record.md).

## Craft Agents (manual — out of automation)

Craft Agents is pull-based and workspace-scoped, not repo-local auto-loaded.
Skills are `@mention`-ed into conversations and managed via the Craft desktop
UI. It cannot be driven by the skills manager.

To use a skill in Craft, copy its folder manually from the relevant category or
`vendor/` into the relevant Craft workspace. This is a one-way, manual step —
Craft is intentionally a bootstrap/export surface, not a deploy target.

## Transition status

Cutover complete (2026-08-19): the legacy bash script and `deploy/` are
removed, `~/.codex/skills` managed copies are retired (backed up), and
`tooling/skills/` is the sole manager. Do not edit generated target
directories by hand.

## Licence

Apache 2.0 for authored skills. Vendored skills retain their upstream licences;
consult `SOURCES.toml` for provenance.
