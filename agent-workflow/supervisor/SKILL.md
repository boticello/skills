---
name: supervisor
description: Use when a scoped phase of structured work needs a single coordinator — research, design, planning, execution, review, integration, reporting, or handoff. The supervisor chooses the needed work pattern, delegates directly where useful, and owns every transition between them.
---

# Supervisor

Use this skill to run a bounded phase with clear ownership. The supervisor owns
the phase outcome: choose the work pattern, delegate only where useful,
integrate results, verify the state, report honestly, and retire before
context becomes a liability.

## Operating Loop

1. Establish the current state: objective, phase boundary, repo/workspace locations, dirty state, active workers, live services, previous reports, and unresolved risks.
2. Shape the next coherent unit: scope, non-goals, acceptance criteria, risks,
   decision owner and the evidence that will prove it is done.
3. Choose the work pattern; do not apply an implementation template to every
   kind of work:
   - **Research/diagnosis:** frame the question, source the evidence, state the
     conclusion and residual uncertainty. It may end here.
   - **Design:** compare viable approaches, make trade-offs explicit, and
     obtain the required decision before committing the architecture.
   - **Planning:** turn an accepted brief/design into bounded slices, risks,
     dependencies and verification gates.
   - **Execution:** make the approved, bounded change using the relevant
     execution and VCS discipline.
   - **Review:** independently compare the result with the brief/design and
     evidence; review is not the implementer's completion summary.
4. Decide delivery mode: work directly when tightly coupled or small;
   delegate only bounded, independently reviewable work; run research before
   design or execution when material facts are uncertain.
5. Integrate deliberately: inspect outputs and diffs, reconcile conflicting
   findings, keep repo/workspace/live state separate, and avoid accepting work
   by summary alone.
6. Verify and review before advancing. Accepted output is not automatically
   readiness for the next phase: record unresolved trade-offs, decisions or
   evidence gaps before rewriting the brief or starting new execution.
7. Report what changed or was learned, evidence, residual risks, state, and
   the recommended next action. Retire when context is stale or the phase
   boundary is clean enough for a new supervisor.

The supervisor owns the phase handoff prompt. Do not delegate the handoff
prompt itself. Workers may contribute research, implementation, review, or
report inputs, but the retiring supervisor must compose the final handoff so
the next turn mode and deliverable are explicit.

## Coordination boundary

The supervisor is the sole coordinator. A specialist may perform its assigned
operation and report evidence, but must not dispatch another specialist or
advance ticket/phase state on the supervisor's behalf. For example, the
supervisor instructs the tracker specialist and Git specialist separately,
then decides what happens next. This keeps authority, sequencing and failure
handling visible in one place.

## Related Skills

Load related skills as needed rather than duplicating their instructions here:

- `lead`: use before supervision when the user has not yet supplied a usable brief.
- `code-and-docs-search` and relevant domain skills: use for research or diagnosis.
- `write-design-doc`: use when the work needs a technical design, trade-off analysis, or architecture proposal.
- `spike-planning`: use when an accepted design needs an implementation and verification plan.
- `execution-spine`: use for an executor carrying out a scoped unit.
- `verify` and, where relevant, `code-review`: use for verification and independent review.
- project tracker skills: use for tracker operations only; the supervisor owns lifecycle decisions.
- `retro`: use at a phase boundary only when a process lesson should become durable guidance.
- `git-change-manage`, `git-vcs`, `jj-change-manage`, or `jj-vcs`: use according to the repository's VCS workflow before changing durable state.

## Progressive References

Read only the reference needed for the current supervision problem:

- `references/phase-lifecycle.md`: phase shaping, acceptance criteria, reports, verification gates, and how to classify trial findings.
- `references/delegation-and-workers.md`: delegation decisions, worker prompt boundaries, black-box trials, and worker lifecycle hygiene.
- `references/retirement-and-handoff.md`: when a supervisor should retire, how to announce it, and how to write the handoff prompt.

## Hard Rules

- Keep repo state, workspace artefacts, live database state, and worker state explicit and separate.
- Give each worker a bounded objective, authority, excluded areas, required evidence and stop condition. Do not make workers coordinate each other.
- After delegating a write set, do not edit that write set locally until the worker is complete, cancelled, or explicitly reassigned.
- Before claiming a worker limitation, check whether the relevant delegation or thread-management tool actually exists in the current session.
- Do not use unrelated worker systems to infer Codex subagent state. If the available subagent tool cannot spawn or list workers, report that exact limitation.
- Do not let trial accidents become product rules. Classify each finding as product behaviour, documentation/help, environment/tooling, API uncertainty, or process issue.
- Prefer small phases that produce verified value. Avoid both tiny churn phases and overloaded phases whose integration risk is larger than their value.
- When tests shell repo-relative scripts or files, run verification from the repo root that those tests expect, and record that cwd explicitly in the phase report.
- At phase boundaries, stabilise commits where appropriate and write a report or handoff that a new supervisor can use without reconstructing the whole thread.
- Announce the need for supervisor retirement before context decay causes incorrect assumptions, then prepare a handoff prompt.
