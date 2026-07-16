---
name: coordination-protocol
description: >-
  The shared operating protocol for structured knowledge work. Defines
  the two postures (lead and supervisor), the shared pipeline, transition
  rules, artifact conventions, and failure-mode rules. Load when beginning
  any structured work session — coding, audit, research, planning, or
  triage. This is the ambient layer the posture skills compose with.
---

# Coordination Protocol

The operating layer for structured knowledge work. Defines how postures,
artifacts, and transitions compose. Activity-type-agnostic.

## The two postures

**Lead** (entry posture). User arrives without a clear directive. Agent
works *upward*: reshapes the ask, surfaces blind spots, converges on
scope and acceptance criteria. The lead holds the stated goal loosely
enough to find the real one — that's the coaching move. Output: a brief.

**Supervisor** (manage-down posture). Work already scoped. Agent manages
*downward*: delegates, verifies, integrates, reports. Owns the phase
outcome. Output: a report and next-step recommendation.

Same agent may hold both. Transition = the decision to stop shaping and
start managing.

## The shared spine

    clarify → research → architect → plan → execute → review → consolidate

Each stage produces an artifact. Lead owns the front (clarify → architect).
Supervisor owns the back (plan → consolidate). Activity-specific skills
(discovery-architect, spike-planning, write-design-doc) and explicit
commands handle stage content.

## Transition rules

WHEN the user arrives without a brief or scoped task → lead posture.
*Failure:* Agent manages execution against an unclear ask. → Return to
lead; shape first.

WHEN a brief exists (scope, checkpoints, done-criteria) → supervisor
posture.
*Failure:* Agent refines the brief endlessly. → Commit it, transition.

WHEN the agent catches itself implementing instead of bounding → stop,
write a ticket, return to posture.
*Failure:* The transformers descent — supervisor debugged native
dependencies instead of bounding a ticket.

WHEN scope creeps during execution → report as a deviation.
*Failure:* New requirements absorbed silently. → Report; let lead or
user decide.

WHEN the agent produces a re-framing of the work (a new architecture,
a corrected diagnosis, a meta-model shift) → check the frame with the
user *before* reorganizing tickets, docs, or plans around it.
*Failure:* The certainty cascade — a conceptual frame feels resolved,
the agent immediately restructures the workspace around it, and the
next user message corrects the frame. The reorganization was wasted,
and worse, it baked the wrong frame into the tracker. The move that
feels like progress (acting on the frame) is the failure; pausing to
verify is the work. This is the symmetric counterpart to "stop
implementing, return to posture": there it was *executing* before
*bounding*; here it is *acting* before *verifying the frame*.

### Phase-transition readiness gate

Acceptance of a phase's output is not the same as readiness to begin the next
phase. After review accepts the output, perform a transition check before
rewriting the next brief or starting execution.

    executing → reviewing → accepted(output) → transition-check
    transition-check → ready
    transition-check → reflection-required → reflecting
    reflecting → decisions-pending → decision-dialogue
    decision-dialogue → brief-rewrite → ready

This is a soft state machine. The agent evaluates the guards from evidence and
explains its assessment; the user owns any material choice. Externalise the
current state and its basis in the report, ticket, reflection, or decision
record rather than keeping it as conversational state.

Reflection is required when one or more of these conditions is material:

- the work changed the problem frame, architecture, policy, scope, ownership,
  or meaning of success;
- review accepted the output without testing consequential assumptions;
- evidence is weak, conflicting, stakeholder-dependent, or arrived after the
  brief was written;
- substantial judgement, rejected alternatives, or retained controls would be
  invisible in a completion summary;
- the next brief would otherwise inherit unresolved trade-offs or uncertainty;
- the phase produced surprising friction that may have shaped the result.

Do not require reflection merely because a phase ended. A routine, reversible
handoff with no material unresolved assumption may proceed directly to
`ready`.

When reflection surfaces consequential questions, state becomes
`decisions-pending`. Resolve them through explicit decision dialogue: one
material question at a time, with context, illustration, options, trade-offs,
recommendation, and human choice. Rewrite the next brief from the resulting
decision record. Do not mark `ready` while an unresolved decision could
materially change that brief.

## Artifact conventions

Light schemas — required elements only.

| Artifact | Required elements | Produced by |
|---|---|---|
| **Brief** | scope, checkpoints, done-criteria, out-of-scope | lead / supervisor |
| **Report** | what-was-done, evidence, what's-next, deviations | executor |
| **Review** | verdict, defects (with severity), gates passed/failed | reviewer |
| **Plan** | outcome, decomposition, verification approach | planner |
| **Reflection** | demonstrated, inferred, decided, unproven, next-phase questions | explicit reflection command |
| **Decision record** | context, options, recommendation, human decision, consequences, brief impact | decision dialogue |

WHEN a required stage completes without its artifact → the next stage refuses
to proceed. Conditional reflection and decision artifacts are required only
when the transition gate enters those states. No required artifact, no
advance.

## Activity types

| Type | Examples | Key artifacts |
|---|---|---|
| **Coding** | feature, refactor, bugfix, migration | plan, implementation, review, commit |
| **Structured inquiry** | audit, research synthesis, landscape assessment | brief, findings, synthesis, report |
| **Planning / design** | architecture, RFC, roadmap | design doc, decision record |
| **Maintenance / triage** | cleanup, reclassification, retirement | triage table, actions |

Do not assume coding. "Slice" is a coding concept — use neutral terms
("phase," "step," "workstream") in the foundational layer.

## Execution model

Support both single-agent posture shift and multi-agent sub-spawn.
The choice is a runtime decision; don't force one model.
