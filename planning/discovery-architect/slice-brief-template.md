# Slice brief template

The slice brief bridges discovery and planning. It captures *why this slice exists* and *what boundaries it has*, so the planner can focus on *how to execute and verify it*.

## Rules

- One page or less.
- Every section answers "why this slice?" not "how do we build it?"
- No steps, gates, test matrices, function signatures, or package decomposition.
- Decisions that are already settled are stated as constraints; decisions left to the planner are in "open planning questions."
- If the brief feels like a plan, it has too much detail.

## Template

```markdown
# Slice brief: {ID} {title}

## Why this slice now

What happened that makes this the right next slice? What was the previous framing, and why did it change? One or two paragraphs — enough for the planner to understand the architectural context without reading the full discovery history.

## Discovery finding

What did you learn that changed the plan? Be specific: what assumption was invalidated, what capability was found, what spike proved what. This is the section the planner must not silently re-litigate.

## Decision status

Classify the architectural decisions shaping this slice:

### Decide now
Decisions that are closed. The planner must work within these.

### Provisional
Decisions made for forward motion but still revisable. The planner may refine these.

### Deferred
Decisions explicitly left for later slices. The planner must not scope them in.

### Out
Decisions that are not part of this system at all. The planner must not drift into them.

## What this slice proves

One structural claim about the codebase. Not a feature list — a claim about what the architecture will be able to do after this slice that it cannot do now.

## Planner constraints

Hard boundaries the planner must respect. Keep this short — only things that discovery has already closed.

## What to read

File paths with a reason for each, not summaries. The planner (and implementer) read the source; the brief does not re-explain it.

## What this slice does not do

Explicit scope exclusions. Primary defence against scope inflation.

## Open planning questions

Questions the planner should answer in the plan. These are the decisions that belong to planning, not discovery.
```

## Pipeline position

```
discovery architect → slice brief → planner → plan → implementer → code → reviewer → findings → retro
```

The brief is a separate document from the plan. It goes into `.pi/workspace/slice-brief.md` so the chain can reference it.
