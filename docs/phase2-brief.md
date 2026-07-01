# Phase 2 Brief — Global-Default Reclassification (skills-2gs)

**Audience:** executing agent. **Reviewer/consolidator:** the supervisor
(the agent that produced `docs/skills-audit.md`). **Report back at each
checkpoint.**

## Background you must read first

- `docs/skills-audit.md` — the facet framework, the treatment palette
  (esp. Keep-global #1 vs Project-scope #2 vs Library/on-demand #3), and
  the trigger-quality problem (Phase 5 / Cluster G).
- `docs/scoping-rationale.md` — the *why* of global vs project scoping, and
  the resolution rule `resolved = (global_default - exclude) + add`.
- `README.md` — deploy mechanics and the scoping examples.

## The goal

Move skills that don't belong in every session out of `global-manifest.toml`,
so the global default stops being a lowest-common-denominator that triggers
irrelevant skills. Per the scoping rationale: niche skills stay in the repo
(Project-scope or Library/on-demand), available via a project's `add`, but
not shipped to every session by default.

This is **Phase 2 of 5**. It is independent of Phase 1 (note successor) and
Phase 3 (coding-agent architecture). It does **not** retire or rewrite any
skill — it only changes which scope each is deployed at.

## The baseline (verified 2026-07-01)

`global-manifest.toml` currently lists **76 skills** (post Phase-0). Of
those, **12 still drive the dead me-CLI** and are Phase 4 salvage/archive
candidates — they must not stay in global regardless, but their *disposition*
(salvage vs archive) is Phase 4's call, not this phase's. Here they are
neither salvaged nor archived; this phase only **removes them from global**
and leaves them in-repo pending Phase 4.

## Reclassification criteria (the rule)

A skill belongs in global default only if it is **role-universal** — the job
is needed in (nearly) every session regardless of project. Apply these
tests; move out of global if any is true:

1. **Dead mechanism** — drives a system that no longer exists (the me-CLI
   skills). Move out of global; disposition handled in Phase 4.
2. **Domain-niche** — serves a specific domain/language/tool not present in
   most sessions (a language, a business domain, a specialist tool). Belongs
   in Library/on-demand or Project-scope.
3. **Experimental / not-active** — a self-contained experiment worth keeping
   but not currently in use (the go-slice quartet + slice-supervisor).
   Library/on-demand, pending a spin-off decision.
4. **Tangle-pending** — entangled in an unresolved architecture decision
   owned by Phase 3 (the coding-agent cluster). Leave in-repo; this phase
   does not resolve the tangle, but may move clearly-peripheral members out
   of global if unambiguous.

Everything else stays global.

## Proposed triage (checkpoint: report back before editing)

Apply the criteria to the 76-skill baseline. Suggested buckets — **the
reviewer must approve before you edit the manifest.**

### Move OUT of global (dead mechanism — Phase 4 dispositions them later)
- `change-manage`, `feature-build`, `filing-process`, `jot-capture`,
  `location-manage`, `orientate`, `project-manage`, `remind-management`,
  `shopping-management`, `source-management`, `subscription-management`,
  `system-self-care`

  All 12 drive the dead me-CLI. Removing from global stops them
  auto-triggering now; Phase 4 decides salvage-rewrite vs archive. They
  stay in-repo (tracked), just not deployed globally.

### Move OUT of global (domain-niche → Library/on-demand)
- **Languages:** `clojure`, `fsharp`, `nushell`, `ruby` — only relevant when
  working in that language. (Note: all four also have empty descriptions +
  `disable-model-invocation`, so they never auto-trigger anyway — removing
  from global formalises that.)
- **Domain:** `pharmaceutical-definition-creator`, `ruby-code-analysis` —
  specialist, low-frequency.
- **Tools (specialist):** `troubleshoot-codex` (Codex-specific repair),
  `database-migration` (SurrealDB/me-cli-specific — also partly dead-mechanism;
  flag this), `logseq-markdown` (Logseq-specific; vault is moving to
  Obsidian).

### Move OUT of global (experimental → Library/on-demand, pending spin-off)
- `go-slice-implementer`, `go-slice-planner`, `go-slice-reviewer`,
  `slice-retro`, `slice-supervisor` — the go-slice experiment. Per the
  audit: preserve as a unit, not active.

### Leave IN global (role-universal) — but flag for Phase 3
- The coding-agent cluster (`supervisor`, `orchestration`, `discovery-architect`,
  `feature-handoff`, `spike-planning`, `write-design-doc`, the four
  `agent-*` workflow skills, the `*-change-manage`/`*-vcs` skills). Phase 3
  may restructure these, but they're not niche — leave global unless Phase 3
  says otherwise. Exception: **`orchestration` is a self-flagged WIP
  skeleton with a dead dependency** — candidate to move out regardless. Flag
  it; let the reviewer decide.

### Clearly stay IN global
- `br`, `filesearch`, `file-introspection`, `code-and-docs-search`, `cbm`,
  `cheatsheets`, `bin-creator`, `fs-reorg`, `code-review`,
  `root-cause-debugger`, `typst`, `skills-manage`, `tool-eval`, `zcode`,
  `op-env-wrap-tool`, `retro`, `verify`, `update-docs`, `wrap`,
  `documentation-writer`, `mcp-manage`, `work-unit-manage`, `use-railway`.

### Vendored (gitignored — review separately)
- `article-extractor`, `csv-data-summarizer`, `last30days`, `nia`,
  `omnigraph`, `ship-learn-next`, `tapestry`, `total-recall`,
  `youtube-transcript`, `almanac`, `lark-crm`. These are third-party.
  `lark-crm` and `almanac` are clearly live+used; the rest — check whether
  each is actively used or library-only. Report findings; don't assume.

## Deliverables

### D1 — Confirm/amend the triage (checkpoint)

Read each skill's SKILL.md you're unsure about. Amend the buckets above with
evidence. **Report back the final bucketing for approval before editing
anything.** Specifically resolve:
- `database-migration` — is it dead-mechanism (me-cli) or partly live?
- `orchestration` — move out or leave for Phase 3?
- Each vendored skill — actively used or library-only?

### D2 — Edit `global-manifest.toml` (after D1 approved)

Remove the agreed-out skills from the `skills = [...]` array. **Do not
delete any skill directories** — they stay in-repo, just out of global
default. Update the manifest comment if it references a count.

### D3 — Documentation + deploy
- Update `README.md` "What's here" count + any category rows if the
  categorisation implies changes (probably not — categories stay; only
  scoping changes).
- Add a one-line note to `README.md` scoping section clarifying that skills
  not in global-manifest are still in the repo and available via a
  project's `add`, if such a note doesn't already exist (it likely does —
  check).
- Run `./deploy/skills-deploy deploy --dry-run` and report the summary.
  Expect many `remove (would back up + delete)` lines on global targets —
  that's correct, they back up.
- After reviewer approves the dry-run: deploy, commit, report.

## Constraints

- **Report at D1 and before D2-edits and before D3-deploy.** Three
  checkpoints minimum.
- **No skill directories deleted.** This phase changes scoping only.
- **No salvage rewrites.** The 12 me-CLI skills get removed from global but
  their bodies are untouched — Phase 4 rewrites or archives them.
- Match existing manifest formatting (4-space indent, quoted, alphabetical
  within the array).

## Done looks like

`global-manifest.toml` contains only role-universal skills; niche/dead/
experimental skills remain in-repo, available via project `add`; deploy
clean; commit lands with a clear message. The global trigger surface is
noticeably quieter.

## Related

- `docs/skills-audit.md` — Phases 0–5, treatment palette
- `skills-2gs` — this work's ticket
- `docs/phase1-brief.md` — parallel phase (independent)
- `docs/phase3-brief.md` — not yet written (coding-agent architecture)
