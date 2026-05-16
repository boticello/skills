---
name: orchestration
description: >
  WIP/TBC. Use when the agent is coordinating work across tickets, documents,
  subagents, tools, or shifting conversation boundaries. This skill is a
  skeleton for orchestrator posture, work-boundary detection, delegation,
  oracle handling, and capture decisions.
metadata:
  short-description: WIP orchestrator protocol
  status: tbc
  maturity: skeleton
  related-tickets:
    - 300
    - 596
    - 601
---

# Orchestration

This skill is a **WIP skeleton**.

It exists to hold the emerging orchestrator protocol while the system learns
how to coordinate tickets, documents, subagents, decisions, and follow-up work.

Use it cautiously. Prefer explicit user direction over inventing policy where a
section is marked TBC.

## Role

The orchestrator reports to the user.

Its job is to:

- notice when the shape of the work changes
- keep tickets, documents, and decisions aligned
- decide when to act directly and when to delegate
- brief subagents with clear scope and ownership
- review returned work before treating it as complete
- capture durable outcomes in the right system surface

TBC: exact relationship to future dedicated builder, explorer, researcher, and
oracle protocol skills.

## First Moves

1. Identify the user's immediate request.
2. Check whether the work belongs to an existing ticket, document, or known
   system thread.
3. If the request has become durable work, apply
   [Work Boundary Detection](#work-boundary-detection).
4. If ticket operations are needed, use
   [ticket-management](../ticket-management/SKILL.md).
5. If document/content operations are needed, use the future
   `document-management` skill. Until that exists, follow local documentation
   rules and state provisional placement decisions.

## Work Boundary Detection

Watch for the point where a conversation stops being only a question and
becomes work that should leave a durable trail.

Common triggers:

- the user asks for strategy, architecture, governance, or system design
- the answer creates or changes maintained artefacts
- the discussion produces follow-up workstreams
- a new capability gap is identified
- the topic expands into a neighbouring system area
- durable decisions or assumptions are made
- multiple tasks need to be sequenced or split
- a document, glossary entry, ticket, or implementation change is implied

When a boundary is detected:

1. State the boundary briefly.
2. Decide whether the next durable action is a ticket, document, jot, decision,
   or immediate implementation.
3. If the user has instructed the action, proceed using the relevant management
   skill.
4. If the action is ambiguous or changes the user's operating model, ask before
   creating or moving durable artefacts.
5. Link child work to the parent ticket when the conversation has become an
   umbrella or programme of work.

Example phrasing:

> This has become a new system work thread. I can create an umbrella issue and
> child tasks, then keep the current implementation changes separate.

Do not ask every time a small follow-up appears. Use judgement. The trigger is
durable system consequence, not mere conversational branching.

## Delegation

TBC.

Initial stance:

- delegate bounded sidecar work when it can run independently
- keep user-facing judgement, ticket creation, and architecture decisions with
  the orchestrator unless the user explicitly delegates them
- require subagents to report what was missing from the handoff
- review subagent output before recording it as complete

## Oracle Handling

TBC.

Initial stance:

- capture oracle output before acting on it
- share the substance with the user before making architectural changes
- record session identifiers and decision context when available

## Capture Surfaces

Use the right durable surface:

- ticket description: scope, context, acceptance criteria
- ticket note: concise progress, decision, design brief, or closeout event
- jot: durable observation or decision that is not only ticket-local
- maintained document: policy, strategy, explanation, reference, how-to, or
  glossary content
- working folder: live plans, drafts, handoffs, and closeout material

TBC: final routing should move to `document-management` once that skill exists.
