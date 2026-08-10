---
name: execution-spine
description: >-
  Use when executing against a plan, brief, or scoped task. The executor's
  operating manual: verify the prior artifact, work atomically, report
  progress and deviations, produce the next artifact. Tool-agnostic and
  activity-type-agnostic — works for coding, audits, research, planning,
  and triage. Pairs with coordination-protocol (postures and transitions)
  and the VCS/tool skills (concrete commands).
---

# Execution Spine

The executor's operating manual. The manage-down posture (supervisor)
delegates work; the executor carries it out. This skill defines how.

## Roles in the pipeline

Three distinct roles, each producing a different artifact:

- **Supervisor** (manage-down posture): owns the phase. Delegates,
  integrates, verifies, reports. May hold all three roles in a
  single-agent session, or spawn separate executors and reviewers.
- **Executor**: carries out the work. Produces a **report** (what was
  done, evidence, what's next, deviations).
- **Reviewer**: checks the work against the brief. Produces a **review**
  (verdict, defects with severity, gates passed/failed).

The supervisor may author the final report by curating executor and
reviewer outputs, or the executor may author it directly. The rule is:
the report exists and reflects what actually happened.

## First move: verify the prior artifact

WHEN starting execution → verify the prior artifact exists and is
substantial enough to work from. A brief without scope, or a plan
without decomposition, is not an artifact — it's a placeholder.

*Failure mode (phantom brief):* Executor begins work against a brief
that was discussed but never written. → Demand the artifact. No
artifact, no advance. (From coordination-protocol, made operational here.)

## Execution loop

For each unit of work in the plan:

1. **Verify scope.** Confirm the unit is bounded and its acceptance
   criteria are clear. If not, report the ambiguity — don't improvise.
2. **Execute atomically.** One logical change per commit/step. Leave
   the system in a working state after each unit.
   *Failure mode (mega-commit):* Multiple unrelated changes bundled. →
   Split. Atomic commits are recoverable; bundles are not.
   Use the backend's explicit local-commit policy for the save-point; a local
   commit does not imply permission to merge, push, deploy, or publish.
3. **Verify the unit.** Run the verification approach from the plan
   (tests, build, lint, or equivalent for non-coding work). Record
   pass/fail.
   *Failure mode (skip verification):* Executor declares done without
   checking. → Verify before reporting; the plan's verification approach
   exists for this reason.
4. **Report progress.** After each stable unit, a progress note exists.
   This can be a ticket comment, a log entry, or a conversation message
   — whatever the session's artifact convention is.
   *Failure mode (silent progress):* Work happens but nothing is
   recorded. → Progress notes are not optional; they're the evidence
   trail.

   This is a process requirement, not automatic enforcement. A reviewer
   should not infer that a commit identifier or conversational summary is a
   report; if no tool checks the artefact, the supervisor must check it
   explicitly.

### Worked enforcement example

In the D3 evaluation, the executor committed work without producing the
required report and the reviewer accepted the commit identifier as a
substitute. The lesson is operational: a written gate is not the same as a
checked artefact. Require the report as its own object and verify it before
advancing the unit.

## Deviation handling

WHEN the plan is wrong (missing information, wrong assumption, blocked
dependency) → report the deviation and stop. Do not absorb it silently
and do not improvise a fix.

WHEN scope creeps during execution → report the creep as a deviation.
New requirements discovered mid-execution are real, but they belong in
a revised brief, not silently folded into the current phase.

*Failure mode (silent absorption):* Executor discovers the plan is
wrong, adapts silently, and delivers something different from what was
planned. → The deviation IS the report. Surface it.

## Completion

WHEN all units in the plan are executed and verified → produce the
executor's report: what was done, evidence, what's next, deviations.

WHEN the plan cannot be completed (blocked, wrong, incomplete) →
produce a report explaining why, with evidence, and a recommendation
(abort, revise brief, unblock dependency).

## VCS and tool references

Load these as needed — this skill does not duplicate their content:

- `jj-vcs` or `git-vcs`: safe VCS commands for the current repository.
  The tool choice is a runtime decision, not a skill-design decision.
- `jj-change-manage` or `git-change-manage`: change-boundary discipline.
- `br`: ticket and comment management for progress notes and reports.

WHEN a VCS operation is needed → load the appropriate tool skill and
follow its rules. Do not invent VCS commands from memory.
