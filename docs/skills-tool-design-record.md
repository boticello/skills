# Design record: reimplement `skills-deploy` as the `skills` manager

**Status:** decided 2026-08-18 · **Ticket:** [P-1291](https://linear.app/bear/issue/P-1291/design-reimplement-skills-deploy-in-ruby)
**Related:** P-1254 (Ruby script authoring standard) · P-1232 (deployment gate) · P-1221 (validation workflow) · P-1222 (repository operating model)
**Governing guides:** `languages/ruby/SKILL.md` (process) · `languages/ruby/ruby-program-design.md` (design)

---

## 0. What this decides

`deploy/skills-deploy` (bash, ~1,250 lines, no tests) is replaced by a Ruby
program named **`skills`**, living in this repo under `tooling/skills/`. The
tool is a
**skills manager**, not merely a deployer: it owns catalogue discovery,
curation (enable/disable), resolution, delivery to targets, health checking
(doctor), quality (lint), overlap detection, and vendoring. It exposes a
clean CLI/library surface that human operators, a future web UI, and a
session-provisioning "coach" agent can all call.

Implementation is a separate follow-up ticket. This record decides the design.

## 1. Verified facts (2026-08-18 evidence base)

**Usage.** Edit → deploy immediately, many times a day; preview-by-default
accepted. Skills are born in the wild (targets/projects) and gathered back.
Vendoring (fetch/update/SOURCES.toml) is actively used. Harnesses read
project-local skill dirs reliably. Only `~/Me/scratch` has a project manifest.

**Pains, in order.** (1) Competing triggers and agents not finding the right
skill — a *selection-quality* problem, not context bloat. (2) Illegible
manifest ceremony — a Zed session failed three times to produce "a table of
all skills and which are in the manifest". (3) Crash-on-drift: `set -e` plus
unguarded `canonical_source_for` aborted deploy/audit on the first dead
manifest entry (7 of 20 were dead; fixed 2026-08-18, see §9). (4) Depth-2
discovery misses `retro/` (SKILL.md at category root), `languages/go/go-slice/*`
and `project/product/alan-puzzle/*` (depth 3).

**Codex target semantics (live-probed, codex-cli 0.147.0).**
- Codex auto-discovers skills from **both** `~/.agents/skills` **and**
  `~/.codex/skills` (plus `.system` built-ins and plugin skills). A skill
  present in both directories is **listed twice** — duplicate competing
  triggers manufactured by the deploy tool itself.
- `[[skills.config]]` blocks in `~/.codex/config.toml` are **per-path disable
  switches** (`path = "…"` + `enabled = false`), not an enable list. All 34
  entries on this machine are disables; **22 of 34 point at deleted skills**.
  Disables are **path-keyed**: a switch for the `~/.agents` copy does not
  suppress the same skill discovered in `~/.codex/skills` — dual-dir
  deployment defeats the user's own disable intent.
- Probe method: `codex exec` skill-listing probes with `~/.codex/skills`
  renamed away (restored byte-identical afterwards). With the dir absent,
  disabled skills vanished entirely and non-disabled skills appeared exactly
  once — confirming the mechanism above.

**rsync provenance.** `/usr/bin/rsync` on this machine is **openrsync**
(protocol 29). It currently supports the flags the bash script uses
(`--itemize-changes`, `--out-format` verified empirically), but openrsync's
divergence from GNU rsync is a standing portability risk for shell-parsed
output.

**Four skill-reference surfaces, all hand-maintained, all rotting:**
1. `global-manifest.toml` — 7 dead entries (fixed 2026-08-18).
2. Project manifests (`.agents/skills-manifest.toml`) — one user.
3. Codex `~/.codex/config.toml` `[[skills.config]]` — 22/34 dead.
4. Agent profiles in `repos/agents` (`skills: [...]` frontmatter) —
   `build.md` → `verify`, `git-vcs` dead; `plan.md` → `discovery-architect`,
   `spike-planning` dead.

**Operating model (settled 2026-08-11).** Workflow (states, gates, authority)
is encoded as supervisor agents, state machines, scripts, commands, and
workflow *documents* — never skills. Roles (lead, supervisor, executor,
reviewer…) are **subagents**, canonical in `repos/agents`, each receiving a
default suite of functional skills plus task-specific ones. Skills are
functional capabilities, named by function/output (`grill-me`,
`write-design-doc`, `code-kotlin`); globality is judged by capability
portability and reuse, not workflow closure. Tools/scripts are direct
instruments. Skills are **capability injections and are dangerous if injected
incorrectly**: a bounded code-reviewer subagent that picks up a knowledge
skill like `brooks-lint` (verified example) does something other than its
assignment — this is the 2026-model overthinking problem, and it makes the
injection boundary the core design concern.

---

## 2. Decisions

### D1. Canonical discovery: recursive scan + configured ignores
**Decision.** The catalogue is every directory containing `SKILL.md` found by
a recursive walk of the repo root, excluding configured non-skill dirs and
`vendor/` (which is scanned separately as the vendored namespace). A skill's
identity is its directory name, which must equal its frontmatter `name`
(lint error otherwise). The first path segment is a **category** — human
organisation only; it carries no behavioural meaning and imposes no depth
limit. Non-skill dirs are declared in `tooling/skills/skills.toml` (`ignore = [...]`),
which replaces the hardcoded `NON_CATEGORY_DIRS`. The ignore list must cover
`tooling/` itself — the Ruby project's test fixtures will contain `SKILL.md`
files that must never register as catalogue entries.

**Rationale.** Depth-2 convention is the audit's blind-spot defect; recursive
scan makes layout free (category-root skills like `retro/`, 3-deep nesting).
`inbox/` is leaving the repo, so it needs no special case — but a general
escape hatch remains necessary for any non-skill material.

**Rejected.** Explicit canonical list (a registry — reintroduces the rot the
tree-is-state model exists to avoid). Keeping depth-2 (fails today's layout).

**Tree-is-state statement (ticket non-goal).** *Unchanged.* The repo tree
remains the only catalogue state. `tooling/skills/skills.toml` is tool configuration
(targets, ignores) — it contains **no per-skill entries** and cannot rot,
because it never references skills.

### D2. Language, layout, and project home
**Decision.** Ruby per P-1254 and the two repo guides. The Ruby project root
is **`tooling/skills/`** — a generic home for harness-management tooling:

```
tooling/
└── skills/            this tool (future siblings: an `mcp` manager, etc.)
    ├── bin/skills     shebang + require + exit, no logic
    ├── lib/skills/    catalog, resolve, plan, mirror, doctor, lint,
    │                  overlap, vendor, codex_config, cli
    ├── test/          one test_*.rb per subject (+ fixtures/)
    ├── Gemfile / .lock   committed
    ├── .ruby-version  pinned
    └── skills.toml    tool config: targets, ignores (D1, D4)
```

`tools/` was the preferred name but is **already a skill category**
(`tools/cheatsheets`, `tools/op-env-wrap-tool`, `tools/zcode`); `tooling/`
keeps catalogue and code separate. The existing bash script is retired once
characterization tests (§4, milestone 1) are green against the Ruby tool;
`deploy/` is removed at cutover. `tooling/skills/bin/skills` is the
entrypoint; a convenience `skills` on PATH is the operator's choice.

**Command-grammar congruence (review note).** `skills` is the first of a
family of harness-management CLIs. Keep the grammar congruent with siblings
as they appear (`mcp doctor` is the obvious future analogy): shared command
nouns where the concept matches (`list`, `doctor`, `enable`/`disable`),
preview-by-default with `--apply`, exit codes 0/1/2, `--json` for agents.
Don't invent per-tool vocabulary for shared concepts.

### D3. Deployment engine: pure Ruby
**Decision.** No rsync. Copy/compare/delete in Ruby: per-skill content
comparison (file set + SHA-256), structured plan, apply via copy-to-temp +
atomic rename per skill directory; removals move to
`${XDG_STATE_HOME:-~/.local/state}/skills-backups/<timestamp>/` exactly as
today. Real directories only — never symlinks (Codex symlink bug).

**Rationale.** The tool needs structured diffs for plan/apply anyway;
parsing rsync's `--itemize-changes` text from shell is the current fragility,
and `/usr/bin/rsync` is openrsync, whose flag/output divergence is a standing
risk. stdlib (`FileUtils`, `Digest`) is sufficient; one fewer external
dependency; deterministic, testable.

**Rejected.** Keep shelling to rsync (works today, but couples plan semantics
to an external tool's output format we don't control).

### D4. Targets: a configured list; `~/.codex/skills` retired
**Decision.** Targets are `[[target]]` blocks in `tooling/skills/skills.toml`
(name + path). The launch configuration has **one** target:
`~/.agents/skills` — the shared open-standard directory ZCode, Zed, Warp,
Memo, opencode, **and Codex** all read. `~/.codex/skills` is **retired as a
deploy target**; its currently-deployed managed copies are removed once
(backed up) during migration, leaving its other-managed content
(`.system`, `_shared`, `brooks-*`, `saggar-cli`, `codex-primary-runtime`)
untouched. Future harnesses (pi/omp read `~/.pi/skills`; junie, dirge, maki
pending) are added as `[[target]]` blocks — no code changes.

**Rationale.** Live-probed (§1): dual-dir deployment produces duplicate skill
listings in Codex and defeats path-keyed disable switches. The user's
requirement "no duplicates" decides it. Skill format is identical across
targets, so a target is just a destination path.

### D5. Codex `config.toml`: hygiene-managed, never intent-writing
**Decision.** The tool **reads** `[[skills.config]]` and **prunes dead-path
entries** (22 today) via a marker-delimited managed splice that leaves the
rest of the file byte-identical (validated by re-parsing after write). The
tool **never writes or removes disable/enable intent**: those switches are
Codex-local user state, keyed by path, owned by Codex's UI/commands. `doctor`
always reports the state of this file.

**Rationale.** Resolves the P-1291 discussion decision ("manage it as a
target") with the semantics the probe established: it is a disable list, not
a registry of what to load. Managing hygiene (dead-path rot) is the tool's
job; managing intent would fight Codex itself.

### D6. Error semantics: aggregate-report-then-fail
**Decision.** Every command collects **all** problems, reports them sorted by
severity, then exits. Exit codes: `0` clean · `1` findings/failures · `2`
usage errors. No command aborts on first failure; a dead manifest entry is a
report line, never a crash.

**Rationale.** The motivating crash (audit/deploy unusable for days) is
exactly what this forbids. Also the meta-lesson of 2026-08-18: managed
surfaces fail silently (agentsview's dead embeddings server was "the MCP
equivalent of my skills issues"); the tool must surface everything it knows
in one pass.

### D7. Subcommands: manager shape; audit folds into doctor; preview-by-default
**Decision.**

| Command | Effect |
|---|---|
| `skills list [--json]` | The legible table: every skill, home, global?, projects, suites, drift state. The Zed-session table, always one command away. |
| `skills enable/disable <name> [--global \| --project <dir>]` | Curation without hand-editing TOML. |
| `skills deploy [--project <dir>] [--apply]` | Plan/apply mirror per scope. **Preview by default; `--apply` executes.** |
| `skills doctor [--fix]` | Flagship. Resolves **all four reference surfaces** (§1), reports dead refs, drift, target state, Codex config rot; `--fix` prunes safe rot. |
| `skills gather <name> [--from <dir>]` | Adopt a wild-born skill into the catalogue (first-class per usage reality). |
| `skills fetch <repo> [--skill <name>]` / `skills update <name>` | Vendoring, ported (provenance in SOURCES.toml). `fetch --all` rehydrates vendor/ on a fresh machine. |
| `skills lint [--strict]` | Ported rules + new naming rule (D10). |
| `skills overlap [--scope global\|project\|suite <name>]` | Competing-trigger detection (D9). |

`audit` is absorbed into `doctor` (content drift is health). All
state-changing commands — including `enable`/`disable` editing manifests —
preview by default and apply with `--apply` (user decision; matches
ruby-program-design's destructive-op principle). Resolution stays
`(global_default − exclude) + add` for projects.

### D8. Scoping: global, project, and suite **validation**
**Decision.** Three scoping dimensions: **global** (`global-manifest.toml`,
target size 5–8 universal skills — curation eased by `enable/disable/list`);
**project** (per-project `.agents/skills-manifest.toml`, mechanism unchanged);
**per-agent-profile suites** — `repos/agents` keeps sole ownership of
profiles; `skills` **validates** their `skills: [...]` frontmatter against
the catalogue via `doctor` and `overlap --scope suite`, and never writes
across repos. The CLI is agent-operable (stable exit codes, `--json`); the
library is the surface the future coach/session-provisioning agent calls.
The tool stays **skills-only** — no MCP, docs, or subagent orchestration
(the prior over-ambitious unification stalled; not repeated).

**Rationale.** Roles-as-subagents with deliberate suites is the settled
model; the boundary keeps each repo authoritative for its own kind.

### D9. Overlap detection: lexical, per resolved set
**Decision.** Token-similarity (Jaccard over descriptions + frontmatter
triggers) between skills within one resolved scope (global set, a project's
set, or a suite). Pairs above threshold are reported with the shared terms,
advisory only. **No embeddings dependency** — deliberately, per the
dead-embedding-server lesson; a local model server is a surface that rots.

### D10. Lint: ported baseline + classification + naming rule
**Decision.** Port the existing 20+ rules verbatim as the baseline, then
classify: **blocking** = structural (missing SKILL.md, frontmatter name ≠ dir
name, duplicate names, dead manifest/profile references, references to
nonexistent files); **advisory** = length, trigger coverage, description
quality, global-deps-outside-manifest, overlap findings, and the **naming
rule** from the four-layer model (names describe functional activity/output;
workflow-shaped or role-shaped names are flagged — advisory at first,
intended to become blocking once the catalogue is clean).

### D11. Dependencies: minimal, boring
**Decision.** `toml-rb` (read + write TOML — four files now: manifests,
SOURCES.toml, skills.toml, Codex config parse), stdlib `OptionParser`
(subcommand dispatch is a case statement), stdlib `Minitest`, no HTTP gem
(`fetch` shells `git` as today), no CLI framework. **Manifest writes:** the
tool owns `global-manifest.toml` and project manifests and regenerates them
with a standard generated header (their comments are tool documentation, not
user prose). **Codex config writes:** marker-splice only (D5). Justification
for the single gem: the bash script's two hand-rolled TOML parsers were a
listed defect; correctness across four files beats regex.

**Config format (review note — Ruby DSL / JSON considered, TOML retained).**
A rake-style Ruby config (`skills.rb` DSL) and JSON were considered for the
tool's own files. Rejected: the tool **must** parse and splice Codex's TOML
regardless (D5), so a TOML library is a fixed dependency and TOML for our own
files costs nothing extra; JSON has no comments (manifest header comments are
load-bearing documentation); a Ruby DSL is config-as-code — flexible but
unvalidatable and ugly to *generate*, and `enable`/`disable` regenerate
manifests. Project manifests also live inside arbitrary other repos, so a
language-neutral, hand-editable, commentable format wins. TOML is all of
these and already the ecosystem standard for agent configuration.

### D12. Bootstrap
**Decision.** Committed `Gemfile`/`Gemfile.lock`/`.ruby-version`; `bin/skills`
wraps Bundler (installs user-space on first run if needed, per P-1254);
`skills fetch --all` rehydrates gitignored `vendor/` from `SOURCES.toml`.
README rewritten as part of implementation (current one is stale: dead
`docs/` links, pre-reorg counts).

---

## 3. What stays out

- **Workflow encoding** — supervisor agents, state machines, scripts,
  workflow documents (four-layer model). The repo is functional capabilities
  only; lint enforces the naming side of this.
- **Reference library** — acknowledged as a distinct resource kind
  (`cheatsheets` experiment and the `zcode`-skill question both point there:
  agents bypass the cheat CLI, and some "skills" are really reference docs).
  Out of v1; the catalogue model reserves a `kind` distinction so a later
  reference-library surface is not blocked.
- **Management web UI** — deferred; the CLI/library is the surface a later UI
  wraps (same decision path as the coach).
- **MCP/subagent/docs orchestration** — explicitly not this tool.

## 4. Migration

1. Characterization tests against the **current bash script's observable
   behaviour** first (resolution formula, mirror semantics, backups,
   allowlist, strip-excludes) — the Ruby skill's characterize-before-replace
   rule for legacy code.
2. Implement behind those tests; parity milestone: `deploy`, `lint`, `list`,
   `gather`, `fetch`, `update` match bash behaviour.
3. Cutover: add D4 target change (retire `~/.codex/skills` — one final
   mirror run backs up and removes managed copies there), prune Codex config
   dead entries (`doctor --fix`), fix `repos/agents` dead references
   (reported by doctor; fixed in that repo by its owner).
4. Delete the bash script; README + `skills-manage` skill text updated to the
   new commands.

## 5. Acceptance-criteria mapping (P-1291)

- Questions 1–7 → D1, D3/D4, D6, D7, D11, D12, D10 — each decided with
  rationale citing §1 evidence. ✔
- Question 8 (management UI) → D7 `list`/`enable`/`disable` as the CLI-first
  UI; web UI deferred (§3). ✔
- Tree-is-state statement → D1. ✔
- Follow-up implementation ticket → filed with this record as its spec. ✔

## 6. Decision history

- 2026-08-18 (discussion, pre-probe): "manage Codex config as a target" —
  **refined by probe evidence** to hygiene-management only (D5); "~/.codex
  target kept" — **overturned by probe evidence** (duplicate listings,
  defeated disable switches) to retirement (D4). Both refinements recorded
  here for review; everything else stands as discussed.
- 2026-08-18 (post-review amendments, same day):
  1. Project home `deploy/` → **`tooling/skills/`** — `deploy` read as
     anachronistic once the tool became a manager; `tools/` was the preferred
     generic name but is an existing skill category, so `tooling/` hosts the
     tool family (D2).
  2. **Command-grammar congruence** with sibling management CLIs (future
     `mcp doctor` analogy): shared nouns, preview-by-default, 0/1/2 exit
     codes, `--json` (D2).
  3. **TOML vs Ruby-native/JSON config** considered; TOML retained — Codex
     config is TOML regardless, comments are load-bearing, project manifests
     live in arbitrary repos, and manifests are machine-regenerated (D11).
  4. Discovery note added (D1): `tooling/` must be ignored so test-fixture
     `SKILL.md` files never enter the catalogue.
