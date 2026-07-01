---
name: feature-handoff
description: Use when delegating implementation work to a build or deep subagent.
metadata:
  status: deprecated
  superseded-by: spike-planning
  note: >
    Feature-handoff's content (atomic task, expected outcome, verification
    command, pattern references, constraints, preflight review) is fully
    covered by spike-planning's step 6 (handoff preamble) and its final
    heuristic ("put the handoff in the plan, not in a separate document").
---

# Feature Handoff

When delegating implementation, the handoff prompt must include:

- the atomic task
- expected outcome
- verification command
- pattern references
- constraints
- a mandatory preflight review

If the delegated agent finds blocking ambiguity, it should stop and ask precise questions before implementing.
