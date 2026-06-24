---
name: write-design-doc
description: Use when producing a technical design document, RFC, architecture proposal, implementation design, system design, or design review for non-trivial engineering work, especially when the work spans multiple components, has multiple possible approaches, needs explicit trade-offs, involves rollout/migration risk, or will guide implementation by humans or subagents. Prefer this over general documentation-writing for engineering design docs.
---

# Write Design Doc

Produce a clear, self-contained technical design document that a reasonably technical but non-expert reader can understand.

Use this skill to make engineering decisions explicit: what is being built, why, what alternatives were considered, what risks remain, and how the work should roll out.

## Core Rules

- Make trade-offs and rationale explicit.
- Keep the main document concise; move deep detail to appendices.
- Do not re-litigate basic background the target audience already knows.
- Do not include function-level implementation minutiae unless central to the design.
- Use British English when repo or user instructions require it.
- If the user provides notes, requirements, or partial designs, normalise them into the design-doc structure.
- Ask only for missing information that materially changes the design; otherwise make conservative assumptions and mark them.

## Required Metadata

Every design document must start with:

- Title
- Author(s)
- Reviewer(s)
- Created date
- Last updated date
- Status, such as Draft, In review, Approved, or Superseded
- Target audience
- Related docs, tickets, PRDs, issues, or previous designs

## Standard Structure

Use this structure unless the user explicitly requests another format:

1. Summary
2. Context / Background
3. Goals and Non-goals
4. Requirements and Constraints
5. Proposed Design
6. Alternatives Considered
7. Risks and Open Questions
8. Rollout and Migration Plan
9. Testing, Observability, and Operations
10. Appendix, optional

## Section Guidance

### Summary

Write 1-3 short paragraphs.

Explain:

- the problem
- the proposed solution
- expected impact
- who is affected
- why now

The summary should be useful to someone skimming the document in under a minute.

### Context / Background

Describe:

- current state
- relevant architecture or data flow
- pain points or gaps
- assumptions
- prior decisions or related systems

Include enough context that a competent engineer from another team can follow the problem.

### Goals and Non-goals

Goals should be observable or testable.

Non-goals should constrain scope and prevent accidental expansion.

### Requirements and Constraints

Keep this terse but specific.

Cover:

- functional requirements
- non-functional requirements
- technical, organisational, regulatory, or legacy constraints

This section should drive the proposed design.

### Proposed Design

This is the core of the document.

Include:

- high-level architecture
- main components and responsibilities
- key APIs or interfaces at the necessary level of detail
- data model and storage choices when relevant
- scalability and performance considerations
- reliability and failure modes
- security, privacy, or compliance implications
- observability
- backwards compatibility and migration concerns

Use diagrams when they clarify component relationships or flows. Mermaid is acceptable for text-native diagrams.

### Alternatives Considered

Include realistic alternatives that were seriously considered.

For each alternative, state:

- brief description
- pros
- cons
- why it was not chosen

This section should show why the chosen design is acceptable, not perfect.

### Risks and Open Questions

List meaningful risks and unresolved questions.

For each risk, include:

- likelihood
- impact
- mitigation, if known

Open questions should guide review discussions and future revisions.

### Rollout and Migration Plan

Describe:

- phases
- feature flags, canaries, or shadowing if relevant
- data, traffic, or user migration
- rollback strategy
- dependencies on other teams or systems

### Testing, Observability, and Operations

Cover:

- unit, integration, end-to-end, and load tests where relevant
- key metrics, logs, traces, dashboards, and alerts
- runbook considerations
- routine tasks and incident procedures

### Appendix

Use appendices for:

- detailed calculations
- expanded API sketches
- benchmark data
- extended diagrams
- raw evidence or references

The main document should be understandable without the appendix.

## Interaction Pattern

When the user asks for a design doc:

1. Clarify scope only if the system type, main goal, or constraints are materially unclear.
2. If the task is large or review-heavy, draft an outline first and ask for confirmation.
3. If enough source material exists, produce the document directly.
4. Keep the structure stable while incorporating feedback.
5. Finalise by removing conversational scaffolding, TODOs, and unresolved placeholders except intentional open questions.

## Minimal Template

```markdown
# <Title>

- Author:
- Reviewers:
- Created:
- Last updated:
- Status:
- Target audience:
- Related docs:

## 1. Summary

## 2. Context / Background

## 3. Goals and Non-goals

## 4. Requirements and Constraints

## 5. Proposed Design

### 5.1 High-level Architecture

### 5.2 Components

### 5.3 Data Model and Storage

### 5.4 Key Design Considerations

## 6. Alternatives Considered

## 7. Risks and Open Questions

## 8. Rollout and Migration Plan

## 9. Testing, Observability, and Operations

## 10. Appendix
```
