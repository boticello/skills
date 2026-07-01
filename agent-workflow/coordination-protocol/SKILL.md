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
(discovery-architect, spike-planning, write-design-doc, retro) handle
stage content.

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

## Artifact conventions

Light schemas — required elements only.

| Artifact | Required elements | Produced by |
|---|---|---|
| **Brief** | scope, checkpoints, done-criteria, out-of-scope | lead / supervisor |
| **Report** | what-was-done, evidence, what's-next, deviations | executor |
| **Review** | verdict, defects (with severity), gates passed/failed | reviewer |
| **Plan** | outcome, decomposition, verification approach | planner |

WHEN a stage completes without its artifact → the next stage refuses to
proceed. No artifact, no advance.

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
