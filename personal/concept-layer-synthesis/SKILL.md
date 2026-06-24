---
name: "concept-layer-synthesis"
description: "Run a higher-order synthesis over a developed Concept Garden, identify recurring conceptual layer-types, and extract any newly generated schema-language concepts into discrete garden notes."
alwaysAllow:
  - Bash
  - Read
  - Write
  - Edit
requiredSources:
  - system-files
---

# concept-layer-synthesis

Use this skill when the Concept Garden has matured beyond isolated note creation and family clustering, and is ready for a higher-order synthesis pass.

## Purpose

This skill identifies the **recurring conceptual layer-types** across the garden and turns the resulting schema language into durable notes when needed.

Its key contribution is not just summary. It does three things:
1. synthesises the current garden at a higher level
2. identifies the recurring conceptual layers in play
3. performs an extraction pass for any newly generated higher-order concepts that should now exist as pages in the garden

## When to use it

Use this skill when:
- the garden has several seeded concepts already
- at least one or two dense families have been boundary-tested
- the same kinds of conceptual distinctions are recurring across families
- you need to move from local clarification to a more general modelling read
- the garden is generating its own schema language, not just domain concepts

## Do not use it for

- first-pass concept harvesting
- simple family clustering
- a cluster that still needs local boundary-testing first
- final schema design or database modelling

## Inputs

A good higher-order synthesis usually builds on:
- the main garden index
- the garden map note
- the boundaries note
- one or more boundary-test notes
- the seeded concept notes themselves

## Workflow

1. **Read the current garden shape.**
   Review the index, map, boundaries, and relevant boundary-test notes.

2. **Ask what kinds of conceptual layers keep recurring.**
   Look for repeated roles such as:
   - artefact
   - artefact family
   - process episode
   - process product
   - condition or signal
   - review mode
   - governing shift
   - record mode
   - information mode
   - continuity function
   - architectural or design problem
   - design principle
   - inquiry pattern

3. **Write the higher-order synthesis note.**
   Use the template in:
   - `/Users/bear/Me/00-system/00-templates/conceptual-layer-synthesis.md`

   A good synthesis note should include:
   - why the note exists
   - the main result
   - the recurring layer-types
   - the distribution of current concepts by layer
   - why this matters
   - strongest general pattern so far
   - implications for later modelling
   - concepts nearing promotion
   - open questions

4. **Do an explicit extraction pass.**
   After writing the synthesis, ask:
   - did this synthesis generate new schema-language concepts?
   - are any of the layer terms currently only implicit in the synthesis note?
   - should those terms now exist as discrete concept pages in the garden?

5. **Create or update concept pages when needed.**
   If the synthesis generated new higher-order concepts, create notes for them rather than leaving them trapped in the synthesis text.

6. **Link the garden back together.**
   - update the garden index
   - update the synthesis note with wikilinks to any newly created schema-language notes
   - update related notes if needed

7. **Record the reflective yield.**
   Capture the pass in the local journal or memory layer if the surrounding workspace requires it.

## Decision rules

- Do not leave the garden's own schema language only implicit in one note.
- If a higher-order term is doing real work, consider giving it its own page.
- Prefer light schema-language notes in the garden before promoting them into heavier topic/index/method forms.
- Do not force the garden into a final ontology too early.
- The purpose is to improve intelligibility, not to over-formalise.

## Output pattern

A successful run usually produces:
- one higher-order synthesis note
- several new or updated schema-language concept notes
- index updates linking the garden's domain concepts to its schema language

## Seeded example

See the current example set in the professional vault:
- `40-professional/40-notes/Concepts/Conceptual Layer Synthesis.md`
- plus the linked schema-language notes such as:
  - `Conceptual Layer.md`
  - `Process Product.md`
  - `Artefact Family.md`
  - `Inquiry Pattern.md`

## Good outcomes

A successful run of this skill usually yields one or more of:
- a cleaner higher-order understanding of the garden
- explicit schema-language vocabulary inside the garden itself
- clearer promotion decisions for stabilising concepts
- a stronger bridge from the garden into later modelling work

## Final reminder

Do not stop at summary.
If the synthesis generates new language that the garden now depends on, harvest it into the garden.
