---
name: execution-spine
description: >-
  Use when executing against a plan, brief, or scoped task. The executor's
  operating manual: verify the prior artifact, work atomically, report
  progress and deviations, produce the next artifact. Tool-agnostic and
  activity-type-agnostic — works for coding, audits, research, planning,
  and triage. Pairs with supervisor (coordination) and the VCS/tool skills
  (concrete commands).
---

# Execution Spine

The executor's operating manual. The supervisor delegates work; the executor
carries it out. This skill defines how.

## Roles in the pipeline

Three distinct roles, each producing a different artifact:

- **Supervisor:** owns the phase, delegates, integrates, verifies and reports.
  It may hold all three roles in a single-agent session.
- **Executor:** carries out scoped work and produces a **report**: what was
  done, evidence, what is next, and deviations.
- **Reviewer:** checks the work independently against the brief or design and
  produces a **review**: verdict, defects with severity, and gates passed or
  failed.

The supervisor may author the final report by curating executor and reviewer
outputs. The report must exist and reflect what actually happened.

## First move: verify the prior artifact

When starting execution, verify the prior artifact exists and is substantial
enough to work from. A brief without scope, or a plan without decomposition,
is a placeholder rather than an artifact.

*Failure mode (phantom brief):* an executor begins work against a brief that
was discussed but never written. Demand the artifact; no artifact, no advance.

## Execution loop

For each unit of work in the plan:

1. **Verify scope.** Confirm the unit is bounded and its acceptance criteria
   are clear. If not, report the ambiguity; do not improvise.
2. **Execute atomically.** One logical change per commit or stable step. Leave
   the system in a working state after each unit. A local commit does not imply
   permission to merge, push, deploy or publish.
3. **Verify the unit.** Run the verification approach from the plan — tests,
   build, lint, source checks, or the equivalent for non-coding work — and
   record pass or fail.
4. **Report progress.** After each stable unit, record what happened, evidence
   and deviations in the session's agreed durable location. A commit or brief
   conversational summary is not a substitute for a report.

## Deviation handling

When the plan is wrong, information is missing, an assumption fails, or a
dependency blocks the work, report the deviation and stop. Do not absorb it
silently or improvise a different result. New requirements discovered during
execution belong in a revised brief or a follow-up work unit.

## Completion

When all planned units are executed and verified, produce the executor's
report: what was done, evidence, what is next and deviations. When the work
cannot complete, report why with evidence and recommend whether to revise,
unblock or stop.

## VCS and tool references

Load these as needed; this skill does not duplicate their content:

- `jj-vcs` or `git-vcs`: safe VCS commands for the current repository.
- `jj-change-manage` or `git-change-manage`: change-boundary discipline.
- the project's tracker skill: ticket/comments for progress evidence.

When a VCS operation is needed, load the appropriate tool skill and follow its
rules; do not invent commands from memory.
