# Skills Scoping Rationale

This document explains **why** skills are deployed the way they are —
specifically, the decision about where the *global default manifest* lives
versus where *project manifests* live, and why they are not symmetric.

It exists because the reasoning is non-obvious and was worked through
carefully. The implementation should follow this; if you find yourself wanting
to change the design, read this first.

For the operational summary, see the [README](../README.md). This document is
about the *why*, not the *how*.

## The problem

Not every skill belongs in every context. A skill like `cbm` (codebase
intelligence) should be readily available in code projects but should not be a
global default that triggers in every session. Conversely, some skills are
genuinely universal and belong everywhere.

The deploy script needs a way to express: "deploy the universal set globally,
and let each project add or suppress skills as needed." The question is where
the *policy* for each scope lives.

## The two scopes

| Scope | Question it answers | Where the manifest lives |
|-------|---------------------|--------------------------|
| **Global default** | "What does the store ship by default, in the absence of any project preference?" | `repos/skills/global-manifest.toml` (in the canonical repo) |
| **Project** | "What does *this* project want, relative to the global default?" | `proj/.agents/skills-manifest.toml` (in the project) |

Both manifests are TOML. They differ in role but share the idea that a
manifest is *policy*, and policy lives at the scope it governs.

## Why the global manifest is in the repo, not in `~/.agents/`

This is the load-bearing decision. The argument runs:

1. **A project has an identity; `$HOME` does not.** A project is a single,
   self-contained, self-describing entity with one set of needs — so its
   manifest correctly lives inside it. `$HOME` is not a project. It is the
   *default scope* that applies when no project has spoken. A default is, by
   definition, a property of the *source of truth*, not of any particular
   destination.

2. **The global default should not differ across destinations.** If the
   global manifest lived in `~/.agents/skills-manifest.toml`, then `~/.codex`
   would need its own, and they would drift. The fan-out model — one source,
   many destinations — requires that the default be defined once and copied
   identically to all global targets. Putting it in the repo gives exactly one
   manifest that fans out to `.agents/skills/` and `.codex/skills/`
   identically.

3. **"What's universal" is a property of the skill set.** The decision of
   which skills ship by default is tightly coupled to the skills themselves —
   it changes when skills are added, removed, or mature. Versioning it with
   the skills (in the same repo, in the same commit) keeps that coupling
   honest. A drift between "the skills in the repo" and "what the repo says
   is universal" would be a real bug, and co-location makes it visible.

## Why project manifests are in the project, not in the repo

The mirror image of the above, and equally important:

If project manifests lived in `repos/skills/`, the canonical store would have
to know about every project on the machine. It would accumulate a growing pile
of project-specific files, each naming a project that might not even exist on
another machine. That inverts the dependency: the store should be dumb; the
projects should be opinionated. The canonical store's job is to *hold* skills;
a project's job is to *select* from them.

Putting the manifest in the project makes the project self-describing: it
declares its own needs, and the deploy script is stateless with respect to
projects. A fresh checkout of the repo knows nothing about projects; each
project carries its own preferences.

## Why one manifest per scope, fanned to all harness dirs

A scope (global or project) may have multiple harness destination directories
at that scope — e.g. both `.agents/skills/` and `.codex/skills/`. The resolved
skill set for a scope is computed **once** from that scope's manifest and
written identically to all harness dirs at that scope.

There is deliberately **no per-harness manifest**. If a project wanted
different skill sets in `.agents` vs `.codex`, that would be a sign the
project is actually two projects, not an affordance to be built. Per-harness
divergence is treated as an error condition, not a feature. (If a genuine
need emerges much later, it can be added as an explicit, separate mechanism —
never as the default.)

This preserves a clean mental model at every level:

- A manifest lives at one scope.
- It resolves to one set.
- That set fans out to every harness dir at that scope, identically.

## The manifest format

**Global manifest** (`repos/skills/global-manifest.toml`) — the default set:

```toml
# Skills deployed to global targets (~/.agents/skills, ~/.codex/skills)
# by default. Everything in canonical NOT listed here is available only
# via a project's `add`.
#
# Ship the mechanism first with all skills global; reclassify incrementally.
skills = [
    "almanac",
    "br",
    # ... the truly universal set, curated over time
]
```

**Project manifest** (`proj/.agents/skills-manifest.toml`) — layered on top:

```toml
# Layered on the global default for this project.
#   resolved = (global_default - exclude) + add

add = [
    "cbm",           # code intelligence — primary for this code project
    "use-railway",   # deployment context
]

exclude = [
    "shopping-management",  # irrelevant in a code project
]
```

The resolution is always:

```
resolved = (global_default - exclude) + add
```

`add` is **additive**, not replacement — the global set still applies; the
project layers on top. `exclude` is the surgical exception that prevents the
global set from having to be a shrinking lowest-common-denominator. Both are
needed: additive alone can't express "global minus this one"; without
`exclude`, global would have to become parsimonious as projects multiply and
each vetoes a different skill.

## Deploy behaviour

```
# Global: mirror global-manifest's set to ~/.agents/skills + ~/.codex/skills
skills-deploy deploy

# Project: resolve (global - exclude + add) and mirror to
# proj/.agents/skills (+ proj/.codex/skills if present)
skills-deploy deploy --dest ~/Me/code/some-project
```

Both are mirror operations: skills not in the resolved set are removed (with
backup), so destinations stay clean rather than accumulating drift over time.
The `--dest` flag is the only new surface; everything else is the same
mechanism, parameterised by destination.

## What this design deliberately does not do

- **No per-skill `global = false` frontmatter flag.** The "what's universal"
  decision is a single readable file (`global-manifest.toml`), not distributed
  across 78 SKILL.md files that must be grepped to audit. Centralized wins for
  reviewability and governance.
- **No per-harness manifests.** One manifest per scope, fanned identically.
- **No project manifests stored in `repos/skills/`.** The store stays dumb;
  projects are self-describing.

## Provenance

This design was worked through in conversation on 2026-06-24, after the
canonical-store model and deploy script were already in place. The starting
position was "project manifests live in the project"; the hard part was
deciding where the *global* manifest lives and why. The conclusion — global
manifest in the repo, project manifests in projects, one manifest per scope
fanned to all harness dirs — follows from the principle that **policy lives at
the scope it governs**, and `$HOME` is not a scope with preferences, it is the
absence of one.
