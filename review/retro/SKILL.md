---
name: retro
description: Reflect on recently completed or recently blocked work, identify what went well and what created friction, and turn the lesson into durable improvements such as repo rules, docs, templates, skills, or references. Use when the user asks for a retro, reflection, post-mortem, process improvement, or "what should we change after this work?".
---

# Retro

Run a concise operational retro after a work slice, bugfix, feature, refactor, or migration.

Focus on turning observed friction into the smallest durable system improvement that would have prevented it next time.

## Workflow

### 1. Reconstruct the work briefly

Capture:
- what the task was
- what was completed
- where time or confidence was lost

Keep this brief. The goal is not a narrative replay.

### 2. Separate outcomes from obstacles

Identify:
- what went well
- what blocked progress
- what was surprising

Prefer concrete blockers over vague feelings.

Good examples:
- ticket was underspecified
- live data drift appeared during migration
- exact syntax for a niche tool was unclear
- local reference material existed but was not operationalised

### 3. Classify the source of the friction

Choose the most likely layer:
- task shaping or ticket quality
- repo rule gap
- missing or weak how-to
- missing template or checklist
- missing or weak skill
- missing local reference access
- execution mistake that does not need a system change

If several apply, name the primary one and the secondary ones.

### 4. Ask what would have prevented it earlier

Prefer the earliest useful intervention.

Typical interventions:
- a stronger rule in `AGENTS.md`
- a maintained how-to note
- a reusable template in `00-templates/`
- an update to an existing skill
- a new skill only if the pattern is broader than one tool or one workflow
- explicit use of local docs or references

### 5. Decide where the fix belongs

Use this placement logic:

- `AGENTS.md`
  Use for always-on repo triggers and standing behaviour.

- Maintained notes in `docs/`
  Use for process definition, rationale, and teachable workflows.

- `00-templates/`
  Use for reusable output shapes, checklists, or ticket-shaping forms.

- Existing skill
  Use when the improvement belongs inside an already-established operational workflow.

- New skill
  Use only when the pattern is reusable across multiple future situations and benefits from a dedicated trigger.

### 6. Produce a compact result

Default output shape:

- What went well
- What caused friction
- Root cause
- What would have helped
- Smallest durable improvement
- Where that improvement should live
- Optional follow-on ticket or patch suggestion

## Heuristics

- Prefer system improvements over blame.
- Prefer one durable fix over five weak ones.
- Do not create a new skill if a rule, how-to, or template would solve the problem more simply.
- If the issue is a niche or fast-moving tool, explicitly ask whether local docs or references should be operationalised.
- If the issue surfaced during schema or migration work, check whether ticket shaping should have captured live drift earlier.

## Common Patterns

### Database work

Ask:
- was the ticket underspecified about live drift or migration shape?
- should live schema and sample rows have been checked earlier?
- should local database docs have been consulted before guessing syntax?

Likely outputs:
- stronger ticket-shaping guidance
- migration skill update
- explicit local-doc reference path

### Command-surface work

Ask:
- did the behaviour depend on an unstated policy?
- should a governance note or reference page have been updated earlier?

Likely outputs:
- policy note
- CLI reference update
- rule in `AGENTS.md`

### One-off mistakes

If the obstacle was only a transient execution error and would not reasonably recur, say so plainly and avoid inventing process overhead.
