# Skills Audit (2026-06-30)

A facet-based assessment of the canonical skill set. Produced to drive
reclassification (`skills-2gs`), quality control / triggering
(`skills-2lm`), and the retirement / salvage decisions after the me-CLI
ticket cluster was removed (commit `7cd33c1`; preserved on branch
`archive/me-cli`).

This is an **assessment of the landscape** to inform decisions, not a
prescription. The user makes the calls; this document surfaces the
structure so those calls are well-grounded.

> **Status.** Assessed against ~77 skills (post me-CLI retirement).
> **Phase 0 complete** (commit following this audit): retired `code-debug`,
> `plan`, `documentation-writing`; fixed isolated defects in `ruby`,
> `nushell`, `pharmaceutical-definition-creator`, `ruby-code-analysis`,
> `system-self-care`; `clojure` trim deferred to its own ticket. The
> `filesearch` skill (added independently during the audit window) is a
> well-built, sharp-triggered skill and folds into the active set without
> changes. Current canonical count: 73 tracked skills.

---

## Why facets, not clusters

An earlier draft grouped skills into semantic clusters ("me-cli cluster",
"corruption cluster", "thin stubs"). That mixed two different axes — *what
a skill is* (its role) and *what's wrong with it* (the treatment it needs) —
and produced bad triage. A skill can be in the "me-cli cluster" yet hold a
durable role-framework worth salvaging, or sit in the "corruption cluster"
while being a live, needed skill with one bad code block.

The facets below are **orthogonal**: each skill is located independently on
each, and the treatment is derived from the combination, never assumed from
membership of a group.

---

## The five facets

| Facet | Asks | Values |
|-------|------|--------|
| **1. Role** | Is the *job* still needed, regardless of how it's done? | needed-universal / needed-niche / not-currently / none |
| **2. Mechanism** | Is the thing it drives alive? | live / dead-but-replaceable / dead-orphaned / pure-guidance |
| **3. Craft** | How well built? | crisp / solid / verbose / thin / corrupt × finished / WIP / superseded |
| **4. Differentiation** | Does it collide with a sibling at trigger time? | unique / overlaps / duplicate |
| **5. Trigger reach** | How is it actually reached? | auto / manual / invisible |

The reframe that matters: **role ≠ mechanism.** A dead mechanism does not
imply a dead role. `orientate` drives a dead CLI but encodes a
drift-detection framework that is role-universal. Splitting the facets is
what stops good detail being discarded with a dead backend.

---

## The treatment palette

"Retire" is underspecified. These are the eight distinct end-states, each
selected by a facet signature:

| # | Treatment | Means | Selecting signature |
|---|-----------|-------|---------------------|
| 1 | **Keep-global** | active in global default, auto-loadable | role universal + mechanism live + craft good |
| 2 | **Project-scope** | in repo, out of global default; added per-project | role needed but niche (a language / domain / tool) |
| 3 | **Library / on-demand** | in repo, not global, not auto-triggered; manual `@` | role real, low-frequency, clearly bounded |
| 4 | **Fix** | edit in place | role + mechanism sound; craft defect only |
| 5 | **Salvage-rewrite** | extract durable framework, rewrite against a live mechanism; old archived | role needed + valuable detail, mechanism dead |
| 6 | **Archive** | remove from manifest + repo; recoverable via git history / archive branch | role not needed now / no successor / superseded |
| 7 | **Spin-off** | coherent experimental cluster preserved as a unit, out of the active set | a self-contained experiment worth keeping together |
| 8 | **Delete** | remove; no unique value | true duplicate, zero salvageable detail |

Salvage-rewrite (#5) is the home for conceptually/functionally valuable
skills whose backend has died.

---

## The me-CLI set, probed through the salvage lens

"me-CLI is stale" does **not** collapse to "archive all 13." Splitting role
from mechanism resolves the set into ~6 salvage candidates and ~6 archives.

### Working assumption (Phase 1 successor)

Tickets → `br` is settled. **Notes / filing** are not yet on a single live
mechanism. Working assumption, recorded 2026-06-30:

- Current provisional mechanism: markdown files in a per-directory `log/`,
  slightly formalised in the scratch folder via a custom `scratch log`
  command wrapping the `jurn` CLI. Serviceable but already awkward.
- Long-term direction: `~/Me/kb` — the unorganised Obsidian + Logseq corpus
  to be standardised on **Obsidian** (has a CLI and an MCP). Expected end
  state: a note-taking / logging interface (custom CLI or skill guidance on
  Obsidian use) living under `~/Me/kb`, with connected notes.

This is a close next step after the skills tidy. Salvage rewrites in Phase 4
target "Obsidian-backed notes/logs" rather than staying blocked.

### Triage

| Skill | Role (needed?) | Mechanism | Durable detail worth keeping | → Treatment |
|-------|----------------|-----------|------------------------------|-------------|
| `orientate` | **Yes** — situating / drift-detection is universal | me tk/proj/jot/search (dead) | orientation lenses, "reduce ambiguity not list," cross-source pattern surfacing | **Salvage-rewrite** → drive `br` + Obsidian successor |
| `system-self-care` | **Yes** — governance-memory tending | me tk/jot (dead) **+ rg/fd (live)** | the rg/fd corpus-tending is already mechanism-independent; only read-sources need repointing | **Salvage-rewrite** (low effort — half-live already) |
| `change-manage` | **Yes** — jj change-boundary discipline | **jj (live)** + me tk.note (dead) | "jj is not git" mental model, three change-states | **Salvage** (strip the `me tk note` coupling; mostly live) — *but* overlaps `jj-change-manage`; see coding-agent architecture ticket |
| `feature-build` | Role yes; **body is me-CLI-specific** | me tk/jot + SurQL (dead) | **reflection-cycle-at-slice-boundaries** is portable and hard-won | **Salvage the reflection cycle** into the coding cluster; archive the me-CLI body. (Functionally the same skill as the already-deleted `me-feature-build`.) |
| `filing-process` | Conditional | me fs (dead) | F-R01–F-R29 rules framework + domain-sensitivity table (real value, *if* filing is still a practice) | **Salvage candidate** pending Obsidian successor |
| `jot-capture` | Yes — notes are taken somehow | me jot (dead) | kind-selection rules (note / reflection / observation / decision …) | **Salvage** pending Obsidian successor |
| `remind-management` | Self-declared **provisional**, awaits a model not built | me tk + legacy remind | little — it's a placeholder | **Archive** until the reminder model exists |
| `project-manage` | personal-data CRUD | me proj (dead, no successor evident) | thin | **Archive** |
| `location-manage` | personal-data CRUD | me location (dead) | thin | **Archive** |
| `shopping-management` | personal-data CRUD | me shop (dead) | thin | **Archive** |
| `source-management` | personal-data CRUD | me source (dead) | thin | **Archive** |
| `subscription-management` | personal-data CRUD | me sub (dead) | thin | **Archive** |

### Gating note

The salvage candidates that drove `me jot` / `me fs` (orientate,
system-self-care, jot-capture, filing-process) **cannot be cleanly rewritten
until the Obsidian successor exists.** That gates Phase 4. Direction is
settled enough that Phase 4 is "blocked on a close next step," not
indefinitely blocked.

---

## The coding-agent ecosystem — bound, not resolved here

These skills are densely interdependent and the open questions are
structural, not mechanical. They warrant a dedicated ticket
("coding-agent skill architecture"). The sub-facets that ticket must
resolve:

1. **Orchestration layering** — `supervisor` (generic, polished) vs
   `slice-supervisor` (operational, Go-coupled, spawns `pi/glm-5.1`) vs
   `orchestration` (self-flagged skeleton, dead `document-management`
   dependency). Is generic ↔ specific a deliberate two-layer design, or
   drift? (`orchestration` is clearly archive regardless.)
2. **VCS duplication** — the "when git, when jj; can tooling separate from
   process?" question. Six skills tangle process with tooling:
   `git-change-manage` + `jj-change-manage` + `change-manage`(jj) +
   `git-vcs` + `jj-vcs` + `agent-vcs-workflow-with-jj`. This is the heart of
   the matter and is a real architecture decision, not a cleanup.
3. **Planning / handoff consolidation** — `plan` (superseded, malformed) /
   `spike-planning` (rich) / `feature-handoff` (thin, superseded) /
   `discovery-architect` / `write-design-doc`. Durable spine is fairly clear
   (spike-planning + discovery-architect + write-design-doc) but the seams
   need deliberate design.
4. **The agent-workflow quartet** — `agent-commit-workflow`,
   `agent-implementation-strategy`, `agent-task-boundaries`,
   `agent-vcs-workflow-with-jj`. All four carry `disable-model-invocation`
   + empty descriptions, and overlap heavily on the "atomic commits +
   jj-agent functions + conservative repo cleanup" mandate. Consolidation
   candidate, but only *after* the VCS question is settled.

These are coupled — fixing orchestration in isolation will collide with the
VCS decision. They belong under one ticket.

---

## True duplicates (unambiguous retire-one decisions)

| Pair | Evidence | Recommendation |
|------|----------|----------------|
| `code-debug` ≡ `root-cause-debugger` | **Byte-for-byte identical** except the `name:` field. Same description, same 8-step workflow. | Retire one. `root-cause-debugger` is the clearer name. |
| `documentation-writer` vs `documentation-writing` | Same Diataxis framework; `writing` is a 60-line distillation, `writer` is the full version. Same trigger surface. | Merge into `documentation-writer` (the richer body); fold `writing`'s "defer to update-docs" note in. |
| `plan` vs `spike-planning` | `spike-planning` de facto supersedes `plan` (richer templates, verification plan). `plan` is thin AND has malformed frontmatter. | Retire `plan`. |

---

## Isolated defects (fix in place, role + mechanism otherwise sound)

| Skill | Defect |
|-------|--------|
| `languages/ruby` | Corrupted code block — `class EmailValidator` jumps mid-line into an unrelated `FRAUD_THRESHOLD` transaction class. Real garbage. |
| `languages/nushell` | Section headers 3–13 lost their `##` markdown → render as plain text. |
| `languages/clojure` | ~1100 lines, ~60% redundant (same CSV example reworked ~6×). Trim candidate. |
| `plan` | Malformed frontmatter — orphaned `- opencode` / `- craft_agents` list items with no key. (Moot if retired per above.) |
| `pharmaceutical-definition-creator` | References table says `references/chisholm.md` but the file is a sibling (`chisholm.md`); no `references/` dir. |
| `ruby-code-analysis` | Hardcoded personal path `~/Me/00-system/tools/cli` in workflow. |
| `system-self-care` | Typo `~/Me/Me/00-system/...` in an example. |

These share a *treatment* (fix the markup / path) but have nothing in common
semantically — ruby (needed, active), nushell (niche, dormant), pharma
(library-only) go to different end-states.

---

## The go-slice experiment — preserve as a unit

`go-slice-planner` / `-implementer` / `-reviewer` + `slice-retro` form a
cohesive plan → implement → review → retro loop, orchestrated by
`slice-supervisor` (spawns `pi/glm-5.1` agents). This was an experiment;
not needed active, but worth **preserved as a unit** (spin-off to a separate
repo, or a clearly-bounded library set out of the global default).

Note: `slice-retro` is role-generic, not Go-specific, and overlaps the
standalone `retro` skill. If the experiment is preserved, consider whether
its generic retro content belongs up in `retro` instead.

---

## The systemic trigger problem (`skills-2lm`)

Description-driven auto-loading is broken across the set. This is the
deepest issue for the goal of "triggered at the right time."

- **4 language skills** (`clojure`, `fsharp`, `nushell`, `ruby`) have
  `disable-model-invocation: true` + **empty descriptions** → they can
  *never* auto-load; only manually `@`-invocable.
- **The 4 agent-workflow skills** — same: disabled + empty description.
- **Only 3 skills have real explicit `triggers:` lists**: `br`, `lark-crm`,
  `zcode`. (These also happen to be among the highest-quality.)
- Many skills have no `triggers:` and vague one-line descriptions, so at
  trigger time they're indistinguishable from siblings (e.g., the 7 me-data
  skills, the 3 doc skills).

The pattern: **the best skills have sharp trigger language baked in at
authoring time; the weakest have none.** This is why trigger-quality work is
Phase 5 (last) — retrofitting it onto a set still being restructured would
mean doing it twice.

---

## Phases (dependency-ordered)

| Phase | Name | Gates / depends on |
|-------|------|--------------------|
| **0** | **Unblocked mechanics** — delete duplicates, fix isolated defects | nothing |
| **1** | **Note / filing successor** — confirm Obsidian interface direction | gates Phase 4 |
| **2** | **Scoping pass (`skills-2gs`)** — move niche skills out of global default | nothing (mechanical once principle accepted) |
| **3** | **Coding-agent architecture ticket** — bound as above; its own focused effort | nothing, but don't rush |
| **4** | **Salvage rewrites** — orientate / system-self-care / change-manage + extract feature-build reflection cycle | blocked on Phase 1 |
| **5** | **Trigger-quality pass (`skills-2lm`)** — descriptions + `triggers:` across the stable set | last; wasted effort while set churns |

Phase 5 is intentionally last: sharp triggering should be baked in at
authoring time (as the best skills already show), not retrofitted onto a
moving target.
