---
name: feature-handoff
description: Use when delegating implementation work to a build or deep subagent.
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
