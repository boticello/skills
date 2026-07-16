# D3 Report — Execution Spine + Tooling Separation

**Ticket:** skills-skills-coding-arch-kva
**Deliverable:** D3 — execution spine + tooling separation
**Status:** Complete, awaiting reviewer approval before D4

---

## What was delivered

### 1. Execution-spine skill (new)

`agent-workflow/execution-spine/SKILL.md` (99 lines).

The executor's operating manual. Tool-agnostic and activity-type-agnostic.
Covers:

- **Roles in the pipeline** (addresses D2 Note 2): supervisor, executor,
  reviewer — each producing a distinct artifact. The supervisor may hold
  all three roles in a single-agent session, or spawn separate agents.
  The supervisor may author the final report by curating executor and
  reviewer outputs.
- **First move: verify the prior artifact** (addresses D2 Note 1): the
  "no artifact, no advance" rule from coordination-protocol is made
  operational — the executor's first action is to verify the prior
  artifact exists and is substantial. A brief without scope is not an
  artifact.
- **Execution loop**: verify scope → execute atomically → verify unit →
  report progress. Each step has a failure-mode partner.
- **Deviation handling**: report, don't absorb. Silent absorption is the
  failure mode.
- **VCS/tool references**: delegates to jj-vcs/git-vcs and br for
  concrete commands. Does not duplicate their content.

### 2. jj-vcs updated (tooling content absorbed)

`vcs/jj-vcs/SKILL.md` — added:
- **Agent Wrapper Functions** section: the jj-agent-* function catalog
  (12 functions) extracted from agent-commit-workflow and
  agent-vcs-workflow-with-jj
- **Recovery Patterns** section: four recovery approaches using safe
  commands (resolves the jj-split conflict — uses sequential commits,
  not `jj split`)
- **Related Skills**: added execution-spine reference

### 3. Quartet marked deprecated

All four agent-workflow skills now carry `metadata.status: deprecated`
with `superseded-by` pointing to their replacements:

| Deprecated skill | Replaced by |
|---|---|
| `agent-commit-workflow` | execution-spine (process) + jj-vcs (tooling) |
| `agent-implementation-strategy` | execution-spine |
| `agent-task-boundaries` | execution-spine |
| `agent-vcs-workflow-with-jj` | jj-vcs (functions) + jj-change-manage (patterns) + execution-spine (process) |

The skills are retained (not archived) until D4 confirms the migration
is complete. D4 will remove them from global-manifest.toml and archive
them.

## jj-split conflict — resolved

jj-vcs says "Never use `jj split`" (line 42). The quartet recommended
`jj split -i` for recovery. Resolution: the jj-vcs prohibition stands.
The new recovery patterns in jj-vcs use sequential `jj commit <paths>`
instead, which is safer and consistent with the existing core rules.

## What I challenged in the brief

Nothing. The D3 spec (tool-agnostic execution spine, strip process from
tooling) is sound and I built directly against it. The one judgment call
was keeping the quartet as deprecated rather than archiving immediately —
D4 is the archival checkpoint, and premature removal risks losing content
that wasn't fully absorbed.

## Open questions

All four open questions from the brief are resolved (D1–D3). No new
questions.

## Next step

Await reviewer approval. Then proceed to D4 (trim and confirm: fold
feature-handoff → spike-planning, archive orchestration, remove quartet
from manifest, confirm the spine).
