---
name: slice-retro
description: "Extract learning from a slice or spike that improves future work — per-role reflections, pattern extraction, and encoded changes to skills, templates, and orchestration rules."
alwaysAllow: ["Bash"]
---

# Slice Retro

## Purpose

Use this skill after a slice, spike, or significant work session to extract learning that improves future work.

The goal is not to summarise what happened.
The goal is to identify what should be preserved, changed, clarified, or encoded.

A good retro improves:
- future planning
- future implementation
- future review
- orchestration choices
- model routing
- templates, skills, and checklists

---

## Core principle

Every retro should end with reusable change.

If the retro produces only observations and no encoded improvements, it is incomplete.

---

## What to look for

Extract learning in five areas:

1. **Product / architecture**
   - What did we learn about the system itself?
   - Did the work change our understanding of the target design?
   - Did any assumptions about the domain prove false?

2. **Planning**
   - Was the slice well-formed?
   - Were the gates meaningful?
   - Was the plan over- or under-specified?
   - Were non-goals clear?
   - Were test expectations visible enough?

3. **Implementation**
   - What made execution smooth?
   - What caused churn, confusion, or rework?
   - What assumptions broke at code level?
   - Which useful local patterns emerged?

4. **Review**
   - Did review catch the right things?
   - Did it happen at the right point?
   - Were the findings mostly structural, behavioural, or test-related?
   - What should become a standing review rule?

5. **Orchestration**
   - Were the right roles used?
   - Were the UI choices appropriate?
   - Was the handoff sufficient?
   - Were model choices suitable?
   - Did phase transitions happen at the right time?

---

## Inputs

Use as many of these as are available:
- design doc
- architecture-discovery notes
- implementation plan
- handoff
- verification plan
- review report
- code diff or commit summary
- role-specific reflections
- user observations

Do not rely only on memory of the session if documents exist.

---

## Role-reflection pattern

When possible, collect short reflections from each participant role.

### Architecture-discovery reflection
- What was the real question?
- What was hard to frame?
- What was decided now vs deferred?
- What should have been clarified earlier?

### Planner reflection
- What did the plan get right?
- What did it miss?
- What was overspecified?
- What was underspecified?
- What should change in the planning template or skill?

### Implementer reflection
- What parts were smooth?
- What parts caused confusion or churn?
- Which assumptions were wrong?
- What context was missing?
- What local coding patterns proved useful?

### Reviewer reflection
- What findings mattered most?
- What was difficult to verify?
- What should become a standard cross-cutting check?
- What test-depth gaps recurred?

### Supervisor reflection
- Was the role sequence right?
- Were handoffs adequate?
- Were model/UI choices right?
- What transition happened too early or too late?

---

## Synthesis method

When writing the final retro:

### 1. Start with what happened
Briefly state:
- what was attempted
- what was delivered
- whether the slice basically succeeded

Keep this short.

### 2. Extract what worked
Focus on patterns worth preserving.

Good examples:
- strong slice boundaries
- effective gates
- good source references
- role separation that reduced confusion
- a model choice that fit the role unusually well

### 3. Extract what went wrong
Focus on causes, not blame.

Good categories:
- framing problem
- planning gap
- implementation drift
- review blind spot
- orchestration problem
- model mismatch

### 4. Convert observations into changes
For each important issue, state:
- what should change
- where it should be encoded
- who owns that change

Encoding targets:
- role skill
- plan template
- verification template
- handoff template
- orchestration note
- model-routing policy
- design note

### 5. Recommend the next adjustment
End with the smallest set of changes that will improve the next slice most.

Do not produce a huge improvement programme if two or three changes would capture most of the value.

---

## Output structure

Use this structure by default:

```
# Retro: <slice or session>

## What happened
Short factual recap.

## What worked
3–6 bullets.

## What caused friction
3–6 bullets.

## Per-role learning
### Discovery
### Planning
### Implementation
### Review
### Orchestration

## Changes to encode
A table with:
- issue
- change
- where to encode it
- priority

## Next-slice adjustments
The minimum set of changes to apply immediately.
```

---

## Tone

Be candid but calm.
Prefer diagnosis over judgement.
Prefer mechanism over vague impressions.
Prefer small actionable improvements over broad commentary.

---

## Failure modes

### 1. Mere summary
A narrative of what happened with no changes derived.
**Fix:** require "where to encode" for important findings.

### 2. Blame-focused reflection
Assigning failure to an agent rather than a process, context, or decision.
**Fix:** ask what setup, brief, or assumption produced the behaviour.

### 3. Too much generic advice
"Communicate better," "test more," "plan carefully."
**Fix:** translate every major point into a concrete change in a skill, template, checklist, or workflow rule.

### 4. No per-role extraction
All learning collapses into a single undifferentiated narrative.
**Fix:** ask what each role uniquely saw.

### 5. No follow-through
Same issue appears in later slices.
**Fix:** add explicit encoding targets and apply them before the next slice starts.

---

## Final reminder

A retro is only valuable if it changes future behaviour.

Extract the learning.
Encode the change.
Keep the next slice better than the last one.
