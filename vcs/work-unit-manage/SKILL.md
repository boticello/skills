---
name: work-unit-manage
description: Manage a coherent unit of work across start, work, and end phases, and choose the correct backend-specific workflow before changing durable state.
triggers:
  - work unit
  - start a work unit
  - finish a work unit
  - durable workstream
  - change boundary
---

# work-unit-manage

Use this skill when work is about to begin, continue, or finish inside a version-controlled codebase or other durable workstream and the first question is not "what command do I run?" but "what is the correct unit of work here?"

## Purpose

This is the shared lifecycle skill above any one VCS backend.

It helps the agent:
- identify the intended work unit
- decide whether current state should be continued or replaced
- keep the work coherent while it is in progress
- close the work unit cleanly

## Relationship To Backend-Specific Skills

Use this skill for the abstract lifecycle.

Then choose the concrete backend workflow:
- `jj-vcs` + `jj-change-manage`
- `git-vcs` + `git-change-manage`

If the surrounding system adds more meaning, such as ticket linkage, review gates, or deployment workflow, layer that guidance on top.

## Work-Unit Lifecycle

### Start

- inspect current durable state before editing
- clarify the requested outcome and scope
- decide whether the current work unit already represents that work
- if not, switch or create a new work unit before making changes

### Work

- keep changes coherent around one intent
- avoid widening the unit with unrelated fixes or discoveries
- capture important linkage and decisions while context is fresh
- split follow-up work into separate units when needed

### End

- ensure the durable state reflects what was actually done
- after acceptance evidence passes, record a local save-point using the
  selected backend's commit/change policy
- treat merge, remote synchronisation, deployment, and publication as separate
  external gates requiring their own approval
- identify whether follow-up work should become a separate unit
- leave enough context for resumption, handoff, or review

## Decision Rules

- Prefer one coherent work unit per intent.
- If the current state reflects completed work or unrelated work, do not edit it casually.
- If a discovery matters but is out of scope, capture it separately instead of folding it into the current unit.
- Choose the backend-specific workflow that matches the repo and harness, not only personal habit.
- When ecosystem assumptions and personal conceptual clarity differ, make that tradeoff explicit.

## Activation Cues

Reach for this skill when:
- implementation work is about to begin
- the agent is unsure whether to continue existing state or start fresh
- the session is crossing from design into execution
- the agent is about to conclude a slice of work and needs to close it cleanly

## Output Pattern

When reporting, say:
- how you classified the current work unit
- whether you are continuing, switching, or creating
- which backend-specific workflow you are using
- what follow-up work units or tickets should exist next
