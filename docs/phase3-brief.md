# Phase 3 Brief — Knowledge-work orchestration + coding-agent architecture

**Audience:** executing agent. **Reviewer/consolidator:** supervisor.
**Report back at each checkpoint.** This is the hardest phase. It is
foundational: the decisions here shape how all structured work is done,
not just coding.

## Read first

- `docs/skills-audit.md` — facet framework; the coding-agent cluster (C)
  and orchestration trio (B) analysis.
- `docs/phase1-brief.md`, `docs/phase2-brief.md` — the brief/report/review
  cycle that this phase generalises. The artifacts produced there are the
  worked examples of the protocol.
- `tools/br/SKILL.md` — report-placement convention (reports of work belong
  on tickets; standalone docs for reports about work).

## The load-bearing principle: do not assume the work is coding

Most agent-skill work tacitly assumes coding. Terms like "slice,"
"implement," "review," "commit," "verify" carry coding assumptions. **This
phase must not build the foundational orchestration layer on those terms.**
Non-coding structured knowledge work — audits, research synthesis,
planning, documentation, analysis — is equally in scope, and a foundation
baked on coding assumptions will be subtly wrong for it.

The skills-audit session that produced this brief is itself the example: it
was high-value structured knowledge work with no code involved, and it
would have been poorly served by a slice/execute/review framing. The
artifacts (brief, report, review) carried the structure that "tests" and
"build gates" carry in coding.

**Consequence:** separate the *common substrate* (the orchestration
protocol — postures, transitions, artifact conventions, rules) from the
*activity-specific layer* (how you execute a coding slice vs an audit vs a
research synthesis). The substrate is activity-type-agnostic; the execution
content plugs in per type.

## The posture model

Two "supervisor" postures were conflated in the existing skills. Separate
them:

### The entry posture (unnamed in the current set — the real gap)

The user arrives *without* a clear directive — they have a problem, an
unease, a goal — and the agent works **upward**: shapes the ask, grasps the
deeper issue, surfaces what isn't being covered yet, and lands on
scope/outcome/acceptance criteria. This is the posture of a coach, project
manager, and architect combined. It is an intelligent conversational
posture, not a management one.

This is the highest-value gap in the skill set. It is what the
skills-audit session opened with ("I need to do a proper audit… what do you
suggest?") and it was improvised. Parts of it live in `orientate` and
`discovery-architect`, but neither owns it. **Phase 3 must name and capture
this posture.**

Open naming question: "lead" / "orchestrator" / "coach" / other. Do not
bake a name in prematurely; it often becomes obvious during drafting.

### The manage-down posture (`slice-supervisor` is the specialised instance)

Process already determined, work already decomposed, orchestrating
executors against a known shape. Much less vagueness — this is real
supervision. `slice-supervisor` is a *coding-specific, multi-agent*
instance of this. The general posture is prescriptive management.

"Supervisor" fits this posture. Keep it here; do not let it bleed upward.

### The shared spine

Both postures sit above a common pipeline: **clarify → research →
architect → plan → execute → review → consolidate.** Each stage has an
artifact (ask/brief, findings, design, plan, deliverable, review,
writeback). The postures differ in *where they engage* — the entry posture
owns the front of the pipeline (clarify through architect, maybe plan); the
manage-down posture owns the back (plan through consolidate). Same agent
may move between postures; the transition is the conscious decision.

## Activity types — the pluggable layer

The execution stage differs by activity type. Do not assume coding.

| Activity type | Examples | Structure available | Key artifacts |
|---|---|---|---|
| **Coding** | feature, refactor, bugfix, migration | High: slices, tests, review checklists, build/verify gates, VCS conventions | plan, implementation, review, commit |
| **Structured inquiry** | audit, research synthesis, landscape assessment | Lower: process supplied deliberately; artifacts carry the weight | brief, findings, synthesis, report |
| **Planning / design** | architecture, RFC, roadmap | Medium: design frameworks (Diataxis for docs, etc.) | design doc, decision record |
| **Maintenance / triage** | cleanup, reclassification, retirement | Low–medium: checklists, rules | triage table, actions |

The orchestration substrate must work for all four. The execution
*content* (how to slice code, how to structure an audit) is the pluggable
per-type layer.

**"Slice" is a coding concept.** It may be effective in coding contexts and
meaningless elsewhere. Do not put it in the foundational layer. If a
foundational concept is needed for "a bounded unit of execution," use a
neutral term (the audit used "phase"; a plan might call it a "step" or
"workstream") and let coding layer "slice" on top.

## Artifact-driven workflow

The session's brief → report → review cycle worked. Generalise it.

**Principle:** structure the data given to each agent and expected from
each agent, so input/process/output is clear and controllable.

**Light schemas, not heavy ones.** Each artifact *type* has a small
required-elements list and is otherwise freeform:

| Artifact | Required elements | Owner |
|---|---|---|
| **Brief** | scope, checkpoints, done-criteria, what's out of scope | entry/manage-down posture |
| **Report** | what-was-done, evidence, what's-next, deviations | executor |
| **Review** | verdict, defects (with severity), gates passed/failed | reviewer |
| **Plan** | outcome, decomposition, verification approach | planner |

Resist tight schemas — they make every brief feel like form-filling and
break when work doesn't fit. A convention documented in the orchestration
skill, not enforced by tooling.

## Rules over procedures

Models are improving; procedural directives age badly. Encode the
small-friction decisions (when to log/report/retro/suggest, when to
delegate, when to bound) as **business rules** ("WHEN a stable unit
completes, a progress note exists"), not procedures ("step 7: write a
note").

**Critical caveat:** rules fail silently when incomplete. A procedure that's
wrong produces wrong output predictably (easy to spot); a rule that
doesn't fire produces *no* output. Therefore rules must explicitly cover
**failure modes**, not just the happy path. Source these from real
incidents:

- *When the agent catches itself implementing instead of bounding* → stop,
  write a ticket, return to posture. (The transformers incident during
  Phase 1 is the worked example — the supervisor descended into
  native-dependency debugging instead of bounding a ticket.)
- *When a checkpoint is skipped* → the next stage refuses to proceed
  without the prior artifact.
- *When scope creeps during execution* → executor reports the creep as a
  deviation, does not absorb it silently.

Collect more failure-mode rules as they surface.

## Existing skills — disposition

| Skill | Disposition | Why |
|---|---|---|
| `supervisor` (agent-workflow) | **Candidate for the entry-posture skill**, or trim to general manage-down | Polished, generic, real references. Decide which posture it owns. |
| `slice-supervisor` (personal) | **Spin off / library** with go-slice quartet | Coding-specific, multi-agent. Not the general model. Preserve as a unit. |
| `orchestration` (planning) | **Archive** | Self-flagged skeleton, dead `document-management` dependency. |
| `discovery-architect` | **Keep** — research/architect stage | Sound; part of the spine. |
| `spike-planning` | **Keep** — the real planner | Trim `feature-handoff` into it. |
| `write-design-doc` | **Keep** — architect stage | Sound. |
| `feature-handoff` | **Fold into spike-planning** | Thin, superseded by the brief pattern. |
| `agent-commit-workflow`, `agent-implementation-strategy`, `agent-task-boundaries`, `agent-vcs-workflow-with-jj` | **Separate process from tooling** | The Cluster C tangle. Process content → the orchestration/execution skills; jj-agent tooling → `jj-vcs`/`jj-change-manage`. |
| `verify` | **Finish** (add real commands) or fold into review | Thin, generic. |
| `retro` | **Keep** — consolidate stage | Sound. |

## The git/jj question — a sub-issue, not a blocker

The user uses both git and jj. The "when git, when jj; can tooling separate
from process?" question is real but is a sub-issue of the broader
"separate process from tooling" principle. Resolve it inside Phase 3 but
don't let it block the posture/artifact/rules work. Short version: process
skills are VCS-agnostic and call a VCS-tooling skill (`jj-vcs` or
`git-vcs`) for the concrete commands; the tool choice is a runtime
decision, not a skill-design decision.

## Deliverables

### D1 — The entry-posture skill (checkpoint: report back before D2)

Name and capture the managing-up posture. This is the highest-value gap.
Draft it against the skills-audit session as the worked example (user
arrives with "I need to do an audit," agent shapes it into facets/phases/
briefs). Must be activity-type-agnostic — work for coding and non-coding.
Resolve the naming question during drafting.

### D2 — The orchestration-protocol skill (checkpoint before D3)

One short skill holding: the posture model (entry + manage-down + shared
spine), the transition rules, the artifact conventions (required-elements
tables above), and the failure-mode rules. Business-rules framed. This is
the glue the other skills compose with. Keep it short — it's loaded
often, and long documents get ignored (the agent-workflow quartet's fate).

### D3 — Execution spine + tooling separation (checkpoint before D4)

A tool-agnostic "execute against a plan" skill (works for coding and
non-coding), with the VCS/br/tool skills as references it calls. Strip
process content out of the tooling skills. This is where Cluster C
resolves.

### D4 — Trim and confirm (final)

Fold `feature-handoff` → `spike-planning`. Archive `orchestration`. Finish
or fold `verify`. Confirm `discovery-architect`, `write-design-doc`,
`retro` as the spine stages. Spin off or library the slice-supervisor +
go-slice unit.

## Out of scope

- Vault organisation (kb tracker, `kb-schema-v34` and friends).
- Salvage rewrites of me-CLI skills (Phase 4, blocked on Phase 1).
- Trigger-quality pass (Phase 5, last).
- Implementation as a Burr/Theodisia state machine or Zenflow multi-agent
  scaffolding. The protocols are captured as skills + artifact references
  first; reach for external machinery only if the lightweight version
  proves insufficient. The "models improving" trend cuts against rigid
  machinery.

## Open questions (flag, don't block)

1. Naming of the entry posture (lead / orchestrator / coach / other).
2. Whether the entry posture is a *new* skill or a salvage of `orientate`
   (Phase 4 rewrites orientate anyway — coordination needed).
3. Whether the orchestration-protocol skill is global-default (ambient) or
   library (opt-in). Instinct: global, kept short. But it competes for
   trigger space.
4. Single-agent-posture-shift vs multi-agent-sub-spawn — the protocol
   should support both (same agent moves through postures; or sub-agents
   spawned per stage). Don't force one model.
