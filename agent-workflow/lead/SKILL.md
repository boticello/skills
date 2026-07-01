---
name: lead
description: >-
  Use when the user arrives with an ambiguous goal, problem, or unease —
  before work is scoped, decomposed, or committed to. The agent works
  upward: reshapes the ask, surfaces blind spots, and converges on
  scope/outcome/acceptance criteria. Activity-type-agnostic — works for
  coding, audits, research, planning, and any structured knowledge work.
  Skip when the user hands you a brief, plan, or well-defined task;
  those go to supervisor or the relevant execution skill.
---

# Lead

The entry posture for structured knowledge work. The user has a problem
or a goal but not yet a directive. The agent's job is to shape the
unclear into the actionable — then hand off to execution.

## When to load

- User arrives without a clear brief, plan, or scoped task.
- The ask is vague, exploratory, or spans multiple possible activities.
- The user says "I need to…" or "what should we do about…" or "I've been
  thinking about…" without a defined next step.

**Do not load** when the user hands you a brief, plan, ticket, or scoped
task. Those go to the manage-down posture (supervisor) or directly to an
execution skill.

## Operating rules

1. **Shape, don't list.** Ask questions that reframe the problem and
   expose what the user hasn't considered. Reduce ambiguity, don't
   produce a long menu of possibilities.
   *Failure mode (list reflex):* Agent produces a laundry list of options
   without recommending one. → Always recommend; the user can override.

2. **Don't assume the activity type.** The work might be coding, an
   audit, research synthesis, planning, or something else. Detect the
   type during shaping; don't bake a coding frame into a non-coding ask.
   *Failure mode (coding default):* Agent frames everything as
   implement/test/review. → Name the activity type explicitly before
   proposing a structure.

3. **Land on a brief.** The convergent output is a brief: scope,
   checkpoints, done-criteria, what's out of scope. This is the handoff
   artifact to the manage-down posture or directly to an executor.
   *Failure mode (drift without artifact):* Good conversation but no
   written brief; the shaped understanding lives only in context. → If
   the work is substantial enough to execute, the brief must be written.

4. **Stop shaping when the ask is clear.** If the user arrives with
   scope, outcome, and acceptance criteria already defined, skip to
   writing or confirming the brief. Don't perform discovery theater.

5. **Don't implement.** When the shaping reveals that work should happen,
   write the brief and transition. Don't start doing the work.
   *Failure mode (descent):* Agent catches itself implementing instead of
   bounding. → Stop, write a ticket/task, return to posture. (The
   transformers incident: the supervisor descended into native-dependency
   debugging instead of bounding a ticket.)

## The transition

The lead posture owns the front of the pipeline:

    clarify → research → architect → plan → [handoff]

The manage-down posture (supervisor) owns the back:

    [handoff] → execute → review → consolidate

The transition point is the written brief. Same agent may hold both
postures; the transition is the conscious decision to stop shaping and
start managing.

## Failure modes

| Symptom | Rule violated | Response |
|---------|--------------|----------|
| Agent produces options without recommending | Rule 1 (shape, don't list) | Recommend one; state why |
| Everything framed as coding | Rule 2 (don't assume type) | Name the activity type explicitly |
| Good conversation, no brief | Rule 3 (land on a brief) | Write the brief before proceeding |
| Agent starts implementing during shaping | Rule 5 (don't implement) | Stop, write ticket, return to posture |
| Scope creeps silently during execution | Posture boundary | Executor reports creep as deviation |

## Worked example

The skills-audit session that produced this architecture:

- **User arrives:** "I need to do a proper audit… what do you suggest?"
- **Lead shapes:** Reframes as a facet-based assessment. Identifies five
  orthogonal facets. Scopes to ~77 skills. Defines phases (0–5) with
  dependency ordering. Produces a brief with checkpoints.
- **Transition:** Brief written, execution begins under manage-down
  posture. The lead posture is no longer needed.

The shaping was improvised that session. This skill makes it deliberate.
