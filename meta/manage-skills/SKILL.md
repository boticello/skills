---
name: manage-skills
description: >-
  How agent skills are organized, authored, and deployed across harnesses, plus
  the editorial judgment for writing a good skill. Use whenever creating,
  editing, gathering, fetching, reviewing, restructuring, or trimming a skill;
  when judging whether a skill is too long, under-triggering, or mixing
  reference with technique; when an agent needs to know where skills live or
  why not to edit them in place; or when questions arise about the skills
  manager, manifests, scoping (global vs project), or vendor provenance. Load
  before scaffolding a new skill, reviewing a skill's quality, or touching any
  ~/.agents/skills or ~/.codex/skills directory. ALSO load alongside the
  skill-creator plugin skill — it overrides skill-creator's "where skills live"
  guidance for this machine's canonical-store model.
triggers:
  - skill
  - skills
  - SKILL.md
  - manage-skills
  - skill-creator
  - global-manifest
  - skills deploy
  - skills doctor
  - .agents/skills
  - .codex/skills
---

# manage-skills

**Before editing any `SKILL.md` or anything under `.agents/skills/` /
`.codex/skills/`, this skill must be loaded.** Skill edits are skills-system
operations; doing them without this model in context is how work gets
destroyed (target edits mirrored away) and how bad skills get written.

## Policy: one canonical store

Skills are authored in `~/Me/repos/skills/` (git) and deployed to targets.
**Never hand-create or edit skills in `~/.agents/skills/` or
`~/.codex/skills/`** — they are generated mirrors, overwritten by the next
`skills deploy`. A skill in a target but not in canonical is drift: gather it,
don't edit it.

The repo directory tree *is* the state — no registries, no lockfiles, no
symlinks in the deploy path (Codex silently fails to load symlinked skill
dirs). Rerunning deploy with no changes is a no-op.

Layout: authored skills live at `<category>/<skill-name>/` (any category that
fits; `personal/` is the catch-all; discovery is a recursive scan). Third-party
skills fetched by `skills fetch` land in `vendor/` (gitignored) with
provenance in `SOURCES.toml` — skills with `UNKNOWN` provenance need upstream
verified before trusting. Design rationale for all of this:
`docs/skills-tool-design-record.md` in the repo.

### Conflict with skill-creator

The `skill-creator` plugin skill says to create skills directly in
`~/.agents/skills/`. **On this machine that is wrong** — the canonical store
exists and overwrites will happen. When both are loaded, this skill wins on
where skills live and how they deploy; use skill-creator only for authoring
craft (intent capture, drafting, test prompts).

## The manager

```bash
~/Me/repos/skills/bin/skills <command> [options]
```

Works from any directory (paths resolve from the script's own location, and
it re-execs under the pinned Ruby via mise if needed).

Every state-changing command **previews by default**; `--apply` writes — read
the preview, apply deliberately. Exit codes: 0 clean, 1 findings, 2 usage.
For command syntax and options, run `skills --help`.

Key semantics the preview won't tell you:

- `deploy` is a **mirror**: target entries not in the resolved set are removed
  (backed up to `~/.local/state/skills-backups/`, never deleted). Entries in
  `allowlist.txt` are never removed.
- `doctor` is the all-surface health check (manifests, Codex `[[skills.config]]`,
  agent-profile suites, drift). `--fix --apply` prunes only provably-safe rot;
  it never writes enable/disable intent.
- `lint [--strict]` is the repository-wide quality check. Validator scope:
  `references/validation.md` in this skill's folder.

## Procedures

**Create or edit a skill**
1. Write `~/Me/repos/skills/<category>/<name>/SKILL.md`. Frontmatter `name`
   must equal the directory name; auxiliary files deploy alongside as
   whole-folder copies.
2. Enable globally (mandatory — a skill never enabled silently never deploys):
   `skills enable <name> --global --apply`, then confirm with `skills list`.
3. `skills deploy --apply`; read the preview for expected add/remove actions.
4. Commit in canonical — the skill AND the manifest change.

**Gather a stray** (skill in target, not in canonical): `skills gather <name>`
auto-detects configured targets; `--from <dir>` overrides; `--category` picks
the home. Then `skills deploy --apply` to re-clean the mirror.

**Fetch third-party**: `skills fetch owner/repo --list` to inspect, then
`skills fetch owner/repo [--skill name] --apply`. `skills fetch --all --apply`
rehydrates vendor/ at recorded commits; `skills update <name>` follows upstream
HEAD.

## Scoping

- **Global** (`global-manifest.toml`, in canonical): the small (5–8 skill)
  universal set shipped to home targets. Curated via
  `skills enable/disable <name> --global --apply`.
- **Project** (`<project>/.agents/skills-manifest.toml`): layers on top with
  `add`/`exclude` lists. Resolution is always `(global − exclude) + add`.
  Projects are self-describing; canonical stays dumb about them.

One manifest per scope, fanned identically to all targets. No per-harness
manifests.

## Skill quality

`skill-creator` covers the authoring loop. This is the editorial judgment.

**A skill is technique, not reference.** It carries judgment and operating
rules — the gotchas that cause a *wrong action*, decision rules, workflow
order. Command syntax, flag tables, and schemas belong in the tool's `--help`,
a sibling `references/` file, or a cheatsheet (see `cheatsheets` skill). If a
skill grows past ~150 lines, the cut almost always lands on reference content
that has a better home.

**Length.** Tool-operating skills: 60–100 lines. Judgment/procedure skills:
100–180. Past ~200, look for reference to offload or two concerns that should
be two skills. Slightly too short beats slightly too long.

**Triggers.** A skill that doesn't fire is dead weight. Write `description`
as an imperative naming the phrasings a user actually says ("Use whenever the
user mentions X, Y, or asks to Z"); add a literal `triggers:` list when the
description alone might miss a common surface form. Test mentally: would it
load on the request you're handling?

**Progressive disclosure.** Description always in context, body on trigger,
`references/` on demand. Push deep detail down and point at it from the body.

**Before deploying, confirm:** the description would fire on a realistic
request; reference content lives outside the body; no inline ticket refs
(`bd-xxx`) — state the guidance instead; length within target or consciously
excepted.

## Related

- `cheatsheets` skill — the sibling reference tier; tool skills pair with one.
- `skills --help` — command syntax and options.
- `docs/skills-tool-design-record.md`, `README.md`, `references/validation.md`
  (canonical repo) — design record, overview, validator scope.
