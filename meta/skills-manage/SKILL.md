---
name: skills-manage
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
  guidance for this machine's canonical-store model, and adds the quality
  guidance skill-creator lacks.
triggers:
  - skill
  - skills
  - SKILL.md
  - skills-manage
  - skill-creator
  - global-manifest
  - skills deploy
  - skills doctor
  - .agents/skills
  - .codex/skills
---

# skills-manage

This skill documents the system that manages agent skills. It is itself a
deployed skill — a skill that describes the system that deploys it.

**Before editing any `SKILL.md` — yours, someone else's, or this one — this
skill must be loaded.** Editing a skill is a skills-system operation, not a
content task. Reaching for the Edit tool on a SKILL.md without the canonical-
store model and the quality guidance below in context is how work gets
destroyed (target edits mirrored away by the next deploy) and how bad skills
get written (no trigger check, reference bloat, no length discipline). If you
are about to touch a `.agents/skills/` or `.codex/skills/` path, or any
`SKILL.md`, and this skill isn't loaded, stop and load it first.

## The one rule

**Skills are authored in `~/Me/repos/skills/` and deployed to targets. Never
hand-create or edit skills in `~/.agents/skills/` or `~/.codex/skills/` — those
are generated targets that get overwritten by the next `skills deploy`.**

If you find yourself wanting to create a skill in a target directory, stop.
Create it in the canonical store instead, then deploy. If a skill already
exists in a target but not canonically, that's drift — gather it (see below).

## Conflict with the `skill-creator` plugin skill

The vendored `skill-creator` plugin skill (from `zcode-plugins-official`)
advises creating skills directly in `~/.agents/skills/` — the discovery
directory. **On this machine, that is wrong.** It is written for the generic
ZCode case where no canonical store exists and overwrites will never happen.
Here, the canonical store does exist and overwrites *will* happen on the next
`skills deploy`.

**When both skills are loaded, this skill's model wins on where skills live
and how they deploy.** Use `skill-creator` for its authoring guidance (intent
capture, drafting, test prompts, iteration) but ignore its "Where skills live"
section. Specifically:

- `skill-creator` says: *"Default to creating new skills under
  `.agents/skills/`"* → **ignore this**. Create under
  `~/Me/repos/skills/<category>/<name>/` instead.
- `skill-creator` does not mention global scoping → **you must enable the new
  skill globally** (`skills enable <name> --global --apply`) or it will not
  deploy to home targets.
- `skill-creator`'s deploy step is absent → use `skills deploy --apply`, not
  file creation in a discovery dir.

A skill created correctly in canonical but never enabled globally silently
stays out of home targets — no error, just absence. `skills list` shows each
skill's global state; check it after enabling.

## The model

```
~/Me/repos/skills/                  ← AUTHORITATIVE (git). Hand-edit only here.
├── <category>/<skill>/             ← authored skills (tracked → GitHub)
├── vendor/<skill>/                 ← third-party skills (gitignored → local only)
├── global-manifest.toml            ← default set shipped globally
├── SOURCES.toml                    ← provenance for vendor/ (url + commit)
├── allowlist.txt                   ← target entries deploy must never remove
├── docs/skills-tool-design-record.md  ← design decisions for the manager
└── tooling/skills/                 ← the `skills` manager (Ruby)
    ├── bin/skills                  ← entrypoint
    └── skills.toml                 ← tool config: targets, ignores
```

Target (generated — never hand-edit): `~/.agents/skills/` — the shared
open-standard directory ZCode, Zed, Warp, Memo, opencode, **and Codex** all
read. `~/.codex/skills/` was retired as a deploy target (2026-08-19): Codex
auto-discovers both dirs, so dual-dir deployment manufactured duplicate skill
listings and defeated its per-path disable switches. It still exists with its
own other-managed content (`.system`, `_shared`, `brooks-*`,
`codex-primary-runtime`, `saggar-cli`) — never hand-edit there either.

**No registries, no lockfiles, no symlinks in the deploy path.** The repo
directory tree *is* the state. Re-running deploy with no changes is a no-op.
This is deliberate — previous attempts (skillkit, skillfish) maintained
registries that drifted from reality.

For the full reasoning behind every design choice, read
`docs/skills-tool-design-record.md` in the canonical store.

## Running the manager

mise provides the pinned Ruby (4.0.2). The reliable incantation:

```bash
cd ~/Me/repos/skills/tooling/skills
mise exec -- bundle exec ruby bin/skills <command> [options]
```

Every state-changing command **previews by default**; pass `--apply` to
write. Exit codes: `0` clean, `1` findings, `2` usage error.

## Authoring workflow

1. Create or edit the skill under a category dir in `~/Me/repos/skills/`:

   ```
   repos/skills/<category>/<skill-name>/SKILL.md
   ```

   Categories include: `analysis`, `code`, `database`, `debug`, `file`,
   `languages`, `mcp`, `meta`, `personal`, `planning`, `project`,
   `requirements`, `retro`, `tools`, `writing`. Pick the best fit;
   `personal/` is the catch-all for personal/workflow skills. Any depth is
   fine — discovery is a recursive scan; the first path segment is category
   organisation only.

2. The skill folder must contain a `SKILL.md` with frontmatter:

   ```yaml
   ---
   name: skill-name
   description: What this skill does and when to use it
   ---

   # Skill Name

   Instructions for the agent...
   ```

   The frontmatter `name` must equal the directory name (lint error
   otherwise).

3. Auxiliary files (scripts, references, templates) live alongside `SKILL.md`
   in the same folder — they deploy with the skill as whole-folder copies.

4. **Enable the skill globally** — mandatory for it to reach home targets:

   ```bash
   mise exec -- bundle exec ruby bin/skills enable <name> --global          # preview
   mise exec -- bundle exec ruby bin/skills enable <name> --global --apply  # writes the manifest
   ```

   This is the most common creation-time mistake: the skill exists in
   canonical but is never enabled, so it never deploys — silently.

5. Deploy:

   ```bash
   mise exec -- bundle exec ruby bin/skills deploy           # preview — confirm "add" actions
   mise exec -- bundle exec ruby bin/skills deploy --apply   # mirror to targets
   ```

6. Commit in the canonical repo (both the skill AND the manifest change).

### Validation

`skills doctor` is the health check — it resolves all four skill-reference
surfaces (global manifest, project manifests, Codex `[[skills.config]]`,
agent-profile suites), reports dead references, drift, and target state, and
exits non-zero on findings. `skills lint [--strict]` is the repository-wide
quality check. For the validator's scope and compatibility notes, read
`references/validation.md`.

**Never edit targets directly.** They are mirrors of canonical. Any change
made in `~/.agents/skills/` will be overwritten on the next deploy.

## Skill quality (guidance, not a gate)

`skill-creator` covers the authoring loop (intent capture, drafting, test
prompts, iteration). This section carries the editorial judgment that decides
whether a skill is *good* — the kind of judgment that's easy to miss when
authoring and that prevents the common failure modes (over-long skills, under-
triggering, reference bloat). Apply it when creating or revising a skill.

**Skill = technique; reference material lives elsewhere.** A skill carries
judgment and operating rules — the gotchas that cause a *wrong action*, the
decision rules, the workflow order. Commands, flag tables, schemas, and
man-page-grade detail do not belong in the skill body; they go in a sibling
`references/` file or a `cheat <tool>` sheet (see "Skill ↔ cheatsheet pairing").
If a skill is growing past ~150 lines, the cut almost always lands on reference
content that has a better home. The `br` skill is the exemplar: ~100 lines of
operating rules, with an imperative pointer to its cheatsheet for command
shapes.

**Length.** Tool-operating skills: 60–100 lines. Procedure/judgment skills:
100–180. Past ~200, look hard for reference content to offload or for two
concerns that should be two skills. A skill that's slightly too short is
always better than one that's slightly too long — same principle as the
cheatsheets skill's 80% rule.

**Trigger quality.** A skill that doesn't fire is dead weight. Two levers:
1. Write the `description` as an imperative that names the natural-language
   phrasings a user actually says ("Use whenever the user mentions X, Y, or
   asks to Z"), not as a dry capability statement. Models under-trigger on
   vague descriptions.
2. Add an explicit `triggers:` list (a YAML list of literal tokens) when the
   description alone might miss a common surface form. `br`, `lark-crm`, and
   `cheatsheets` all use this belt-and-suspenders pattern.
Test the trigger mentally: would the skill load on the request you're trying
to handle? The `cheatsheets` skill historically failed this — it didn't fire
on "edit the cheatsheet" because its description buried the trigger noun.

**Progressive disclosure.** Metadata (name + description) is always in context;
the body loads on trigger; `references/` files load on demand. Keep the
description short; push deep domain detail into `references/` and point at it
from the body ("before any write, read `references/foo.md`").

**Before you deploy, confirm:**
- The `description` would actually fire on a realistic user request (not just
  describe the skill's capability).
- Reference-grade content (full command lists, flag tables, schemas) lives in
  a cheatsheet or `references/`, not the body — unless it's the one piece of
  reference that has no other home.
- No inline ticket references (`bd-xxx`) in the body — tickets close and leave
  dangling pointers. State the guidance inline instead.
- Length is within the targets above, or there's a conscious reason it isn't.

## Manager commands

```bash
skills list [--json]                    # every skill: home, global?, projects, suites, drift
skills enable <name> --global           # curate the global set (preview; --apply writes)
skills disable <name> --global
skills deploy [--project <dir>]         # mirror resolved set to target(s) (preview; --apply)
skills doctor [--fix] [--apply]         # all-surface health check; --fix --apply prunes safe rot
skills overlap [--scope global|project|suite <name>]   # competing-trigger detection
```

Deploy is a **mirror** operation: skills in the target but not in the resolved
set are removed (backed up to `~/.local/state/skills-backups/`, never deleted).
This keeps targets clean — they don't accumulate drift.

`skills doctor` never writes without `--apply`. Even with it, the tool only
prunes provably-safe rot (e.g. Codex `[[skills.config]]` entries whose paths no
longer exist); it never writes enable/disable intent — those switches are
Codex-local user state.

## Scoping: global vs project

Not every skill belongs in every context. Two scopes, each governed by a
manifest:

- **Global default** (`repos/skills/global-manifest.toml`) — the universal set
  shipped to home targets. Lives in the canonical repo because "what's
  universal" is a property of the skill set and must fan out identically to
  all targets. Curated via `skills enable/disable --global`; the global set
  is kept small (5–8 universal skills).
- **Project** (`<project>/.agents/skills-manifest.toml`) — layers on top with
  `add` and `exclude`. Lives in the project because projects are
  self-describing; the canonical store stays dumb about projects.

Resolution is always `(global_default - exclude) + add` — additive by default,
with surgical exclusions so the global set needn't shrink as projects multiply.

Project manifest format:
```toml
add = ["cbm"]                          # global skills to add for this project
exclude = ["shopping-management"]      # global skills to suppress here
```

One manifest per scope, fanned identically to all targets at that scope. No
per-harness manifests. See `docs/skills-tool-design-record.md` for the why.

## Gathering strays (the drift cure)

When a skill exists in a target but not in canonical — e.g. another agent
created it in `~/.agents/skills/` without knowing the system — adopt it:

```bash
skills gather <name>                              # auto-detect configured target
skills gather <name> --apply                      # copy into canonical
skills gather <name> --from ~/.agents/skills      # explicit target root
skills gather <name> --from <dir> --category tools
```

The manager auto-detects the source in configured targets; `--from` accepts
either a target root or the skill directory itself. Run
`skills deploy --apply` afterward to make the target a clean mirror.
`skills doctor` reports strays it notices in the configured target.

## Fetching third-party skills

```bash
skills fetch owner/repo --list          # see what's inside
skills fetch owner/repo [--skill name]  # fetch (preview; --apply writes)
skills fetch --all --apply              # rehydrate vendor/ at recorded commits
skills update <name>                    # follow upstream HEAD (preview; --apply writes)
```

Fetched skills land in `vendor/` (gitignored, not pushed) with provenance
recorded in `SOURCES.toml` (url + commit). Vendored skills deploy alongside
authored ones — no distinction at the target. Skills with `UNKNOWN` provenance
in `SOURCES.toml` need their upstream verified before trusting them — resolve
the url + commit and update `SOURCES.toml`.

## The global default set

`global-manifest.toml` lists the curated set of skills that ship globally by
default. Niche, experimental, and vendored skills remain in canonical but are
not listed — they're available only via a project's `add`. This keeps the
global payload lean as the canonical set grows.

To change what's global, use `skills enable/disable <name> --global --apply`
(the manager regenerates the manifest). Skills not listed there become
available only via a project's `add`.

## Skill ↔ cheatsheet pairing

A tool-operating skill (one whose job is "use tool X correctly") should
**delegate command shapes to its cheatsheet** and carry only the operating
rules an agent needs mid-task — the gotchas that cause a *wrong action*, not
just a forgotten flag. The cheatsheet is the reference home (commands, flags,
JSON shapes, sort keys); the skill loads the mental model into context when
triggered.

This keeps tool skills short (60–90 lines) and avoids duplicating command
syntax in two places that drift apart. The skill's description should
self-route: "for command shapes, use the `<tool>` cheatsheet."

**Exemplar:** `cbm` (72 lines) — its body carries scope, required-workflow
order, and guardrails only; it says "for exact command shapes... consult the
`cbm` cheat sheet." `br` follows the same pattern. Both the skill and its
cheatsheet cross-reference each other.

When a tool already has a cheatsheet and a skill, check that both point at
each other (the skill's Related section → cheatsheet; the cheatsheet's See
Also → skill). When trimming an over-long tool skill, the cheatsheet is
usually where the cut command reference should land.

## Common mistakes

- **Creating a skill in `~/.agents/skills/` or `~/.codex/skills/`.** It will
  be overwritten on next deploy. Create in canonical, then deploy.
- **Forgetting to enable the skill globally.** The skill exists in canonical
  but never deploys — silently. No error, just absence. Enable at creation
  time and confirm with `skills list`.
- **Following `skill-creator`'s "Where skills live" guidance.** That plugin
  skill is written for the generic case (no canonical store) and points at
  `~/.agents/skills/`. See the "Conflict with skill-creator" section above.
- **Editing a deployed skill in place.** Same — overwritten. Edit canonical.
- **Using symlinks to share skills across targets.** Codex has a known bug
  where symlinked skill dirs silently fail to load. Deploy copies real dirs.
- **Expecting a registry/lockfile.** There isn't one. The directory tree is
  the state. `git log` is your provenance for authored skills; `SOURCES.toml`
  is your provenance for vendored ones.
- **Passing `--apply` casually.** Every state-changing command previews by
  default; read the preview. `--apply` is a deliberate confirmation.

## Related

- `cheatsheets` skill — the sibling reference tier. Tool skills pair with
  cheatsheets; see "Skill ↔ cheatsheet pairing" above.
- `docs/skills-tool-design-record.md` (in canonical) — design decisions for
  the manager (discovery, targets, Codex config, error semantics).
- `README.md` (in canonical) — the user-facing overview.
- `allowlist.txt` (in canonical) — target entries never removed (`.system`,
  `brooks-*` plugin symlinks, `codex-primary-runtime`).
- `tooling/skills/` (in canonical) — the manager's source and tests.
