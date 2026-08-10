# Skills source-of-truth and target boundaries

Status: proposed working model, recorded 2026-08-10 — not yet adopted

## Plain-English model

Edit the master copy of a skill in this repository. Review and commit the
approved change, then generate copies for the agent applications that are
managed by this repository. Other local skill folders may be project-specific,
plugin-managed or experimental; they are inventoried here, not silently
absorbed into the master set.

The measurements below are current evidence. The ownership rules and release
sequence are proposals until the relevant policy decisions are made and
recorded in the skills and tickets.

This document distinguishes the places where skills are authored from the
places where harnesses discover or cache them. “In sync” means content agrees
with the authoritative source for a managed target; it does not mean that
every local harness store must contain every canonical skill.

## Stores and ownership

| Store | Location | Owner | Synchronisation rule |
|---|---|---|---|
| Canonical authored skills | `/Users/bear/Me/repos/skills/<category>/<skill>/` | this Git repository | The only place authored skills are edited. |
| Canonical vendored skills | `/Users/bear/Me/repos/skills/vendor/<skill>/` | this repository plus upstream provenance | Gitignored local copies; `SOURCES.toml` records upstream URL and commit. |
| Global selection | `global-manifest.toml` | this repository | Names the skills deployed by default; it is a selection, not a second copy. |
| Global mirrors | `~/.agents/skills/`, `~/.codex/skills/` | `deploy/skills-deploy` | Generated copies of the resolved global set. Audit before deploy; never hand-edit. |
| Project selection | `<project>/.agents/skills-manifest.toml` | the project | Resolves `(global - exclude) + add` for that project. |
| Project mirrors | `<project>/.agents/skills/`, `<project>/.codex/skills/` | `deploy/skills-deploy` | Generated from the project selection; project-local skills remain project-scoped. |
| Pi skill links | `~/.pi/agent/skills/` | pi configuration | Currently a small set of symlinks, partly pointing at other harness stores; not a canonical copy. |
| omp managed skills | `~/.omp/agent/managed-skills/` | omp | Separate harness-local store; report and classify, but do not silently gather or deploy. |
| opencode skills | `~/.opencode/skills/` | opencode | Separate harness-local store; report and classify, but do not silently gather or deploy. |
| Plugin caches and built-ins | Codex/Zcode plugin and `.system` locations | the owning harness/plugin | Allowlisted or plugin-managed; outside this repository’s deploy contract. |

Vendored entries are retained copies, not the upstream source itself. A
verified `SOURCES.toml` entry records where to re-fetch one, which upstream
commit was inspected, and (when needed) the skill's path within that checkout;
an `UNKNOWN` entry is not yet reproducible and remains a provenance work item.

## Current measured snapshot

At the time of this record:

- 78 authored canonical skills and 21 vendored skill copies are present.
- `global-manifest.toml` selects 19 skills.
- The two managed global mirrors contain the same 19 names.
- Both managed mirrors contain the same 19 names and agree with each other.
  The current canonical worktree has undeployed changes in 18 of those managed
  skills: `almanac`, `backlog`, `bin-creator`, `br`, `cbm`, `cheatsheets`,
  `code-and-docs-search`, `file-introspection`, `filesearch`,
  `git-change-manage`, `git-vcs`, `jj-change-manage`, `jj-vcs`, `mcp-manage`,
  `op-env-wrap-tool`, `root-cause-debugger`, `skills-manage` and `zcode`.
  `work-unit-manage` is also edited locally, but is not in the global manifest
  and therefore is not in either managed mirror. No target-only divergence was
  found.
- Pi has three visible links: `find-skills`, `nia`, and `omnigraph`; these are
  not an independent canonical copy.
- omp has six managed skills with no name collision in the canonical tree:
  `alan-puzzle-b2-publish`, `alanpuzzle-rule-change-pipeline`,
  `b2-auth-debugging`, `clojure-oneshot-domain-timing`,
  `omp-mcp-remote-auth-fix`, and `verify-kotlin-branch-in-worktree`.
- opencode has three local skills: `logseq-markdown`,
  `open-knowledge-discovery`, and `open-knowledge-write-skill`.
- `article-extractor` provenance is now verified and pinned in `SOURCES.toml`.
  Three vendor entries remain unresolved there: `logseq-markdown`,
  `total-recall` and `use-railway`. `tapestry` is pinned to its historical
  upstream commit and path; the refresh command supports that pin with
  `--ref`.

## Provisional local-store dispositions

These are proposed dispositions for review, not synchronisation actions. No
local copy has been moved, deleted or promoted.

| Local skill | Proposed disposition | Reason |
|---|---|---|
| `alan-puzzle-b2-publish` | retain omp/project-local | Alan Puzzle publishing workflow. |
| `alanpuzzle-rule-change-pipeline` | retain omp/project-local | Alan Puzzle domain and release sequence. |
| `b2-auth-debugging` | retain omp/project-local | B2 credential troubleshooting for that project. |
| `clojure-oneshot-domain-timing` | retain omp/project-local | Alan Puzzle and one-shot performance experiment. |
| `omp-mcp-remote-auth-fix` | retain omp-local | omp/opencode integration troubleshooting, not a general skill. |
| `verify-kotlin-branch-in-worktree` | retain omp/project-local | Kotlin worktree verification procedure. |
| `logseq-markdown` | retain opencode-local duplicate | Byte-identical to the canonical vendored copy; provenance remains tracked by `skills-kn9`. |
| `open-knowledge-discovery` | retain opencode-local for now | New opencode-specific material; promote only after an independent review. |
| `open-knowledge-write-skill` | retain opencode-local for now | New opencode-specific authoring workflow; not yet a global skill candidate. |

The user should confirm or amend these dispositions before any gather, retire or
promotion operation.

There is also a dependency-closure question: several of the 19 globally
deployed skills name skills that are not in the global manifest or either
managed mirror. The clearest cases are `br` referring to
`coordination-protocol`, `execution-spine` and `supervisor`, and the Git/JJ
adapters referring to `work-unit-manage`. Other optional references include
`verify`, `ticket`, `feature-handoff` and `nia`. These may be intentional
project/on-demand references, but the final operating model must say whether
active global skills may rely on unavailable helpers or whether a minimum
operating spine is global.

## Proposed operational rules

1. Edit authored material only in the canonical repository.
2. Use `deploy/skills-deploy audit` to compare resolved managed targets by
   name and content. A clean `reconcile --dry-run` is insufficient because
   reconcile detects orphan names, not content drift.
3. Use `deploy` only after the canonical change is reviewed and committed.
4. Treat omp, opencode and pi-local material as inventory items until each has
   an explicit disposition: promote to canonical, retain as project-local,
   retain as vendor material, or retire.
5. Never delete a local skill merely because it is outside the canonical
   deploy set; record the disposition first and use recoverable operations.
6. Keep plugin-managed and built-in harness entries outside the canonical
   mirror comparison unless an explicit integration is designed.

## Proposed release sequence

With the local-commit policy adopted, review the canonical diff → run
`deploy/skills-deploy lint` and
`deploy/skills-deploy audit` → run focused checks → commit the coherent
canonical change and tracker record → run
`deploy/skills-deploy deploy --dry-run` → deploy the approved mirrors → rerun
the audit. Pushing the Git branch is a separate decision.
