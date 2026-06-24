---
name: "concept-boundary-test"
description: "Run a structured boundary test over a dense concept cluster, separating artefacts, families, functions, modes, conditions, products, and design problems without forcing final ontology too early."
alwaysAllow:
  - Bash
  - Read
  - Write
  - Edit
requiredSources:
  - system-files
---

# concept-boundary-test

Use this skill when a concept cluster in the Concept Garden or related modelling work feels dense, overlapping, or hard to reason about.

This skill is for **working the boundaries** among concepts, not for prematurely deciding schema or final ontology.

## Purpose

The goal is to turn a knot of related concepts into a clearer layered structure.

In practice, many difficult clusters turn out not to be a set of rival names for one thing, but a mix of different conceptual kinds, such as:
- concrete artefact
- artefact family
- process episode
- process product
- condition or signal
- review/support mode
- continuity function
- governing shift
- record mode
- architectural or design problem
- method or principle

The skill helps surface those differences explicitly.

## When to use it

Use this skill when:
- several concept notes are tightly linked and keep blurring together
- a family note feels too broad or baggy
- a boundary in the Concept Garden is becoming a live modelling question
- a cluster may contain more than one conceptual layer
- you need a disciplined note that sharpens distinctions before promotion, schema work, or method design

## Do not use it for

- simple definitional note-writing where no live boundary problem exists
- final schema design
- forcing every concept into a fixed ontological bucket too early
- replacing good examples with abstract theorising alone

## Inputs

A good boundary test starts with:
- 3–5 tightly related concept notes
- optionally 1–2 adjacent concepts for contrast
- at least one concrete example or originating case

## Workflow

1. **Name the cluster clearly.**
   - Example: governing family, continuity family, process/output family.

2. **List the core concepts.**
   - Usually 3–5 notes.
   - Add adjacent notes only if they help separate the cluster.

3. **State why the knot exists.**
   - What is currently confusing?
   - Why do these concepts feel close?
   - Why might they not be the same kind of thing?

4. **Apply the structured question set to each concept.**
   For each note, ask:
   1. What is the minimal thing that must be true for this concept to apply?
   2. What does it preserve, change, support, or generate that would otherwise be lost?
   3. Is it primarily an artefact, family, episode, product, condition, mode, function, or design problem?
   4. What evidence would let us recognise it in the wild or after the fact?
   5. What nearby concept is it most likely to be confused with?
   6. What would be lost if the system collapsed it into a simpler category?
   7. What does it most naturally require, generate, or point to next?

5. **Write a comparative read.**
   - Compare the concepts pairwise or by the most important fault lines.
   - Prefer explicit “X vs Y” sections over vague summary.

6. **Propose a provisional layered structure.**
   Ask whether the cluster actually contains several layers, for example:
   - artefact
   - family
   - function
   - mode
   - condition
   - design problem

7. **State what remains unresolved.**
   Do not pretend clarity where it has not yet been earned.

8. **Record the practical consequence for the garden.**
   - What changed?
   - Which notes are now cleaner?
   - What promotion or further testing becomes possible?

## Output pattern

Write a note named:
- `{{Concept Family}} Boundary Test`

Use the reusable template in:
- `/Users/bear/Me/00-system/00-templates/concept-boundary-test.md`

A good boundary-test note should contain:
- the concept cluster
- the structured question set
- one section per concept
- comparative read
- current best structure
- unresolved questions
- practical consequence for the garden

## Decision rules

- Prefer **layer separation** over premature subtype trees.
- Name what kind of thing each concept currently appears to be doing.
- Use concrete examples when possible.
- Preserve useful uncertainty.
- Do not mistake a record of something for the thing itself.
- Do not assume all concepts in a family are peers; some may stand at different conceptual levels.

## Seeded examples

See the current Concept Garden examples:
- `40-professional/40-notes/Concepts/Governing Family Boundary Test.md`
- `40-professional/40-notes/Concepts/Continuity Family Boundary Test.md`
- `40-professional/40-notes/Concepts/Process and Output Boundary Test.md`

## Good outcomes

A successful run of this skill usually produces one or more of:
- a cleaner family structure
- clearer distinction between artefact and function
- distinction between process and product
- distinction between governing shift and record of it
- better promotion decisions for concepts approaching topic/method/index status
- a stronger bridge from the Concept Garden into later modelling work

## Final reminder

The purpose of this skill is not to close the question too fast.
It is to make the shape of the question more intelligible.
