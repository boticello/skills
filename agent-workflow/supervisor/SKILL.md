---
name: supervisor
description: Use when a phase of work is already scoped and needs execution management — delegation, subagent coordination, verification, integration, reporting, and phase handoff. Trigger when the user asks to supervise, manage a phase, delegate work, coordinate executors, or run a bounded engineering effort with clear ownership.
---

# Supervisor

Use this skill to run a bounded phase of engineering work with clear ownership. The supervisor owns the phase outcome: plan the work, delegate only where useful, integrate results, verify the system state, report honestly, and retire before context becomes a liability.

## Operating Loop

1. Establish the current state: objective, phase boundary, repo/workspace locations, dirty state, active workers, live services, previous reports, and unresolved risks.
2. Shape the phase: define the next coherent slice, acceptance criteria, non-goals, likely risks, and what evidence will prove the phase is done.
3. Decide execution mode:
   - Do the work directly when the task is tightly coupled, urgent, small, or blocked by unavailable workers.
   - Delegate when work is bounded, parallelisable, independently reviewable, or benefits from a fresh perspective.
   - Run recon before implementation when the design surface is unclear.
   - For split or extraction work, prefer this order unless there is a specific blocker: runtime boundary, then namespace/ownership boundary, then packaging boundary, then contract or behaviour changes.
4. Integrate deliberately: inspect worker outputs, reconcile conflicting findings, review diffs, keep repo and workspace artefacts separate, and avoid accepting implementation by summary alone.
5. Verify before declaring progress: run relevant tests, smoke live paths where appropriate, check docs/help output when UX changed, and record skipped or deferred checks.
6. Report the phase result: what changed, what was verified, what remains uncertain, current repo/workspace status, and the recommended next slice.
7. Retire when context is stale or the phase boundary is clean enough for a better supervisor handoff.

The supervisor owns the phase handoff prompt. Do not delegate the handoff
prompt itself. Workers may contribute recon, implementation, review, or report
inputs, but the retiring supervisor must compose the final handoff so the next
turn mode and deliverable are explicit.

## Related Skills

Load related skills as needed rather than duplicating their instructions here:

- `feature-handoff`: mandatory when delegating implementation or documentation edits to subagents; it is the source of truth for delegated write ownership, access mode, worker prompts, manifests, integration, and live-state ledgers. Use it for recon, review, or black-box trials when those tasks may lead to implementation handoff.
- `plan`: use when a phase needs a written implementation plan before execution.
- `write-design-doc`: use when the work needs a technical design, trade-off analysis, or architecture proposal.
- `verify`: use before merge, promotion, release, or handoff.
- `retro`: use at phase boundaries when process lessons should become durable guidance.
- `git-change-manage`, `git-vcs`, `jj-change-manage`, `jj-vcs`, or `work-unit-manage`: use according to the repository's VCS workflow before changing durable state.

## Progressive References

Read only the reference needed for the current supervision problem:

- `references/phase-lifecycle.md`: phase shaping, acceptance criteria, reports, verification gates, and how to classify trial findings.
- `references/delegation-and-workers.md`: delegation decisions, worker model selection, prompt boundaries, black-box trials, and worker lifecycle hygiene.
- `references/retirement-and-handoff.md`: when a supervisor should retire, how to announce it, and how to write the handoff prompt.

## Hard Rules

- Keep repo state, workspace artefacts, live database state, and worker state explicit and separate.
- Before delegating any worker that may edit files, load `feature-handoff` and follow its implementation-delegation protocol.
- After delegating a write set, do not edit that write set locally until the worker is complete, cancelled, or explicitly reassigned.
- Before claiming a worker limitation, check whether the relevant delegation or thread-management tool actually exists in the current session.
- Do not use unrelated worker systems to infer Codex subagent state. If the available subagent tool cannot spawn or list workers, report that exact limitation.
- Do not let trial accidents become product rules. Classify each finding as product behaviour, documentation/help, environment/tooling, API uncertainty, or process issue.
- Prefer small phases that produce verified value. Avoid both tiny churn phases and overloaded phases whose integration risk is larger than their value.
- When tests shell repo-relative scripts or files, run verification from the repo root that those tests expect, and record that cwd explicitly in the phase report.
- At phase boundaries, stabilise commits where appropriate and write a report or handoff that a new supervisor can use without reconstructing the whole thread.
- Announce the need for supervisor retirement before context decay causes incorrect assumptions, then prepare a handoff prompt.
