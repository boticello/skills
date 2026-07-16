---
name: skills-manage
description: >-
  How agent skills are organized, authored, and deployed across harnesses. Use
  whenever creating, editing, gathering, fetching, reviewing, restructuring, or
  trimming a skill; when an agent needs to know where skills live or why not to
  edit them in place; or when questions arise about the deploy script,
  manifests, scoping (global vs project), or vendor provenance. Load before
  scaffolding a new skill or touching any ~/.agents/skills or ~/.codex/skills
  directory. ALSO load alongside the skill-creator plugin skill — it overrides
  skill-creator's "where skills live" guidance for this machine's
  canonical-store model.
---

# skills-manage

This skill documents the system that manages agent skills. It is itself a
deployed skill — a skill that describes the system that deploys it.

Load this when working with skills at all: creating, editing, fetching,
deploying, or reconciling drift. The single most important rule is below.

## The one rule

**Skills are authored in `~/Me/repos/skills/` and deployed to targets. Never
hand-create or edit skills in `~/.agents/skills/` or `~/.codex/skills/` — those
are generated targets that get overwritten on the next deploy.**

If you find yourself wanting to create a skill in a target directory, stop.
Create it in the canonical store instead, then deploy. If a skill already
exists in a target but not canonically, that's drift — gather it (see below).

## Conflict with the `skill-creator` plugin skill

The vendored `skill-creator` plugin skill (from `zcode-plugins-official`)
advises creating skills directly in `~/.agents/skills/` — the discovery
directory. **On this machine, that is wrong.** It is written for the generic
ZCode case where no canonical store exists and overwrites will never happen.
Here, the canonical store does exist and overwrites *will* happen on the next
`skills-deploy`.

**When both skills are loaded, this skill's model wins on where skills live
and how they deploy.** Use `skill-creator` for its authoring guidance (intent
capture, drafting, test prompts, iteration) but ignore its "Where skills live"
section. Specifically:

- `skill-creator` says: *"Default to creating new skills under
  `.agents/skills/`"* → **ignore this**. Create under
  `~/Me/repos/skills/<category>/<name>/` instead.
- `skill-creator` does not mention `global-manifest.toml` → **you must add
  the new skill name to `~/Me/repos/skills/global-manifest.toml`** or it will
  not deploy globally (skills-deploy skips unlisted skills).
- `skill-creator`'s deploy step is absent → use `skills-deploy deploy`, not
  file creation in a discovery dir.

This is the load-bearing detail. A skill created correctly in canonical but
missing from `global-manifest.toml` silently fails to deploy — no error, just
absence. Always check the manifest.

## The model

```
~/Me/repos/skills/              ← AUTHORITATIVE (git). Hand-edit only here.
├── <category>/<skill>/         ← authored skills (tracked → GitHub)
├── vendor/<skill>/             ← third-party skills (gitignored → local only)
├── global-manifest.toml        ← default set shipped globally
├── SOURCES.toml                ← provenance for vendor/ (url + commit)
├── allowlist.txt               ← target entries deploy must never remove
├── docs/scoping-rationale.md   ← why global vs project manifests live where they do
└── deploy/skills-deploy        ← the deploy script
```

Targets (generated — never hand-edit):
- `~/.agents/skills/` — ZCode, Zed, Warp, Memo, opencode-CLI
- `~/.codex/skills/`  — Codex (its `.system/` built-ins and plugin symlinks are skipped)

**No registries, no lockfiles, no symlinks in the deploy path.** The repo
directory tree *is* the state. Re-running deploy with no changes is a no-op.
This is deliberate — previous attempts (skillkit, skillfish) maintained
registries that drifted from reality.

For the full reasoning behind every design choice (why the global manifest
lives in the repo not in `~/.agents/`, why project manifests live in projects,
why no per-harness manifests, why copies not symlinks), read
`docs/scoping-rationale.md` in the canonical store.

## Authoring workflow

1. Create or edit the skill under a category dir in `~/Me/repos/skills/`:

   ```
   repos/skills/<category>/<skill-name>/SKILL.md
   ```

   Categories include: `agent-workflow`, `analysis`, `debug`, `domain`,
   `go-slice`, `knowledge-management`, `languages`, `personal`, `planning`,
   `review`, `tools`, `vcs`. Pick the best fit; `personal/` is the catch-all
   for personal/workflow skills.

2. The skill folder must contain a `SKILL.md` with frontmatter:

   ```yaml
   ---
   name: skill-name
   description: What this skill does and when to use it
   ---

   # Skill Name

   Instructions for the agent...
   ```

3. Auxiliary files (scripts, references, templates) live alongside `SKILL.md`
   in the same folder — they deploy with the skill as whole-folder copies.

4. **Add the skill to `global-manifest.toml`** — this is mandatory. A skill
   that exists in canonical but is missing from the manifest will NOT deploy
   globally (skills-deploy silently skips it). This is the most common
   creation-time mistake:

   ```toml
   # global-manifest.toml — add the name in alphabetical order
   skills = [
       # ...
       "mcp-manage",    # <-- add here
       # ...
   ]
   ```

5. Deploy:

   ```bash
   cd ~/Me/repos/skills
   ./deploy/skills-deploy deploy --dry-run   # preview — confirm the new skill shows as "added"
   ./deploy/skills-deploy deploy             # copy to targets
   ```

6. Commit in the canonical repo (both the skill AND the manifest change).

**Never edit targets directly.** They are mirrors of canonical. Any change
made in `~/.agents/skills/` or `~/.codex/skills/` will be overwritten on the
next deploy.

## Deploy commands

```bash
# Global: mirror global-manifest.toml's set to home dirs
./deploy/skills-deploy deploy

# Project: resolve (global - exclude) + add and mirror to a project
./deploy/skills-deploy deploy --dest ~/Me/code/some-project

# Preview either without writing
./deploy/skills-deploy deploy --dry-run
./deploy/skills-deploy deploy --dest <project> --dry-run

# List canonical skills, targets, and allowlist
./deploy/skills-deploy list
```

Deploy is a **mirror** operation: skills in the target but not in the resolved
set are removed (backed up to `~/.local/state/skills-backups/`, never deleted).
This keeps targets clean — they don't accumulate drift.

## Scoping: global vs project

Not every skill belongs in every context. Two scopes, each governed by a
manifest:

- **Global default** (`repos/skills/global-manifest.toml`) — the universal set
  shipped to home dirs. Lives in the canonical repo because "what's universal"
  is a property of the skill set and must fan out identically to all targets.
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

One manifest per scope, fanned identically to all harness dirs at that scope.
No per-harness manifests. See `docs/scoping-rationale.md` for the why.

## Gathering strays (the drift cure)

When a skill exists in a target but not in canonical — e.g. another agent
created it in `~/.agents/skills/` without knowing the system — adopt it:

```bash
./deploy/skills-deploy gather <name>                       # auto-detect source
./deploy/skills-deploy gather <name> --from codex          # specify source
./deploy/skills-deploy gather <name> --category tools      # specify category
```

This copies the skill from the target into canonical. Run `deploy` afterward
to make the target a clean mirror.

To gather all detected strays in one pass:
```bash
./deploy/skills-deploy reconcile            # gather all, then redeploy
./deploy/skills-deploy reconcile --dry-run  # list strays first
```

**Reconcile handles orphan drift only** (skills in targets not in canonical).
It does NOT detect content drift (canonical skill edited in a target but
differently) — that needs deliberate review.

## Fetching third-party skills

```bash
./deploy/skills-deploy fetch owner/repo                 # single-skill repo
./deploy/skills-deploy fetch owner/repo --skill name    # pick one from multi-skill
./deploy/skills-deploy fetch owner/repo --list          # see what's inside
```

Fetched skills land in `vendor/` (gitignored, not pushed) with provenance
recorded in `SOURCES.toml` (url + commit). On a fresh machine, re-fetch each
vendored skill from `SOURCES.toml`, then deploy.

Vendored skills deploy alongside authored ones — no distinction at the target.
Skills with `UNKNOWN` provenance in `SOURCES.toml` need their upstream
verified (see br ticket `skills-kn9`).

## The global default set

`global-manifest.toml` lists which canonical skills ship by default. **It is
currently a baseline listing all skills** — reclassification to a curated
universal core is deferred (br ticket `skills-2gs`). Until then, everything
deploys globally exactly as before scoping existed.

To change what's global, edit `global-manifest.toml` directly. Skills not
listed there become available only via a project's `add`.

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
`cbm` cheatsheet." `br` follows the same pattern. Both the skill and its
cheatsheet cross-reference each other.

When a tool already has a cheatsheet and a skill, check that both point at
each other (the skill's Related section → cheatsheet; the cheatsheet's See
Also → skill). When trimming an over-long tool skill, the cheatsheet is
usually where the cut command reference should land.

## Common mistakes

- **Creating a skill in `~/.agents/skills/` or `~/.codex/skills/`.** It will be
  overwritten on next deploy. Create in canonical, then deploy.
- **Forgetting to add the skill to `global-manifest.toml`.** The skill exists
  in canonical but never deploys — silently. No error, just absence. Always
  add the name to the manifest at creation time.
- **Following `skill-creator`'s "Where skills live" guidance.** That plugin
  skill is written for the generic case (no canonical store) and points at
  `~/.agents/skills/`. See the "Conflict with skill-creator" section above.
- **Editing a deployed skill in place.** Same — overwritten. Edit canonical.
- **Using symlinks to share skills across targets.** Codex has a known bug
  where symlinked skill dirs silently fail to load. Deploy copies real dirs.
- **Forgetting to commit after authoring.** Canonical is git-tracked; if it's
  not committed, it's not reproducible.
- **Expecting a registry/lockfile.** There isn't one. The directory tree is
  the state. `git log` is your provenance for authored skills; `SOURCES.toml`
  is your provenance for vendored ones.

## Related

- `cheatsheets` skill — the sibling reference tier. Tool skills pair with
  cheatsheets; see "Skill ↔ cheatsheet pairing" above.
- `docs/scoping-rationale.md` (in canonical) — full design rationale
- `README.md` (in canonical) — the user-facing overview
- `allowlist.txt` (in canonical) — target entries never removed (`.system`,
  `brooks-*` plugin symlinks, `codex-primary-runtime`)
- br workspace (`.beads/`) — tracks follow-up work on this system
