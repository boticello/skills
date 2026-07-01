# Phase 3 handoff — to the executing agent

**Ticket:** `skills-skills-coding-arch-kva`
**Brief:** [`docs/phase3-brief.md`](phase3-brief.md) — read this first, in full.
**Reviewer:** the supervisor (the agent that produced the audit + brief).
**You:** executing agent, fresh context.

## Why a separate executor

The reviewer wrote the brief. To preserve spec/implementation separation, a
different agent (you) executes it. This is deliberate — if the same agent
designs the test and takes it, defects in the design become invisible.

**Your license and duty:** read the brief critically. Where you disagree
with it, say so and propose a change *before* implementing — don't silently
work around a brief you think is wrong. The reviewer would rather debate
the brief at D1 than inherit a skill built on an unchallenged assumption.

## What to trust vs reconstruct

**Trust (don't re-derive):**
- The facet framework and audit findings in `docs/skills-audit.md`.
- The load-bearing principle (don't assume coding) — this was shaped
  directly with the user; treat it as a real constraint, not a suggestion.
- The posture model (entry/manage-down/spine) and the "slice is coding-
  specific, keep it out of the foundation" rule.
- The disposition table for existing skills.

**Reconstruct from source (don't trust the brief's summary alone):**
- Read each existing skill the brief dispositions (`supervisor`,
  `slice-supervisor`, `orchestration`, `discovery-architect`,
  `spike-planning`, `feature-handoff`, the agent-workflow quartet, `verify`,
  `retro`). Form your own view before acting on the brief's.
- The incidents the failure-mode rules derive from (transformers descent,
  report-placement inconsistency) — read the Phase 1 review comment on
  `skills-skills-phase1-2s7` and the Phase 1/2 reports in `log/` to
  understand them, don't just take the brief's one-line summaries.

## How to run it

Four deliverables, **each a checkpoint**. Report back after each; do not
proceed to the next without the reviewer's go.

- **D1 — entry-posture skill** (the managing-up role). Report back with the
  draft skill + your resolution of the naming question + your reasoning.
  This is the highest-value deliverable; expect the most back-and-forth.
- **D2 — orchestration-protocol skill** (postures, transitions, artifact
  conventions, failure-mode rules). Report back before D3.
- **D3 — execution spine + tooling separation** (tool-agnostic execute-
  against-a-plan skill; strip process from tooling skills). Report back
  before D4.
- **D4 — trim and confirm** (fold feature-handoff → spike-planning; archive
  orchestration; finish/fold verify; confirm the spine). Final.

## Review contract

- You report by attaching a comment to the ticket (`br comments add --file`)
  — **not** a `log/` file. Per the convention now recorded in
  `tools/br/SKILL.md`: reports of work on a ticket belong on the ticket.
- The reviewer replies on the ticket with approve / changes-required /
  questions.
- If you hit something that needs a user decision (one of the brief's open
  questions, or a new one), **flag it as a question for the user** in your
  report — do not resolve it by guessing. The reviewer will route it.

## Constraints (from the brief, restated so they're not missed)

- Activity-type-agnostic foundation. If you find yourself writing a skill
  that assumes code, stop and generalize. The worked example for non-coding
  is the skills-audit session itself.
- Rules over procedures — but every rule must have a failure-mode partner
  (what happens when the rule doesn't fire).
- Light artifact schemas (required-elements), not tight forms.
- Keep the orchestration-protocol skill (D2) **short**. Long frequently-
  loaded documents get ignored — the agent-workflow quartet's fate.
- Don't reach for Burr/Theodisia/Zenflow. Skills + artifact references
  first. Flag if you genuinely think machinery is needed; don't just add it.

## Open questions you inherit (resolve or escalate)

1. Naming the entry posture (lead/orchestrator/coach/other).
2. New skill vs salvage of `orientate` for D1 (Phase 4 rewrites orientate —
   coordinate).
3. Global-default vs library for D2.
4. Single-agent-posture-shift vs multi-agent-sub-spawn — support both.

For each: propose a resolution in your first relevant report, with
reasoning. The reviewer/user confirms.

## Where things are

- Repo: `/Users/bear/Me/repos/skills`
- Brief: `docs/phase3-brief.md`
- Audit: `docs/skills-audit.md`
- Ticket: `skills-skills-coding-arch-kva` (this brief + this handoff are
  attached as comments)
- Existing skills under: `agent-workflow/`, `personal/`, `planning/`,
  `vcs/`, `review/`
