---
name: pharmaceutical-definition-creator
description: >
  Create precise, well-formed definitions for pharmaceutical terms, data
  objects, and business concepts using either the Chisholm methodology
  (governance/data-object focus, multi-section document) or the Intralign
  methodology (grammatical/rule-based, operational glossary focus). Use when
  a user asks for a definition or glossary entry in a pharmaceutical or
  life-sciences context.
---

## Overview

This skill produces structured pharmaceutical definitions using one of two expert
methodologies. **Chisholm** (after Malcolm Chisholm) produces a governance document
with named sections, a definition type taxonomy, and a self-critique cycle — suited
for data dictionaries, formal review, and regulatory submissions. **Intralign**
produces a grammatically precise, rule-based definition built sentence by sentence —
suited for operational glossaries and cross-functional alignment.

Both methods require context before drafting. Never produce a definition without it.

---

## Method Selection

| Signal | Method |
|---|---|
| User explicitly names a method | Use that method |
| Object type is Table, Column, Entity Attribute, Interface File, Reference Data | Chisholm |
| User needs governance metadata (review dates, approval status, standards citations) | Chisholm |
| User needs a clean self-contained grammatical definition for a glossary | Intralign |
| Pure operational/scientific term with no data-object context | Intralign |
| Ambiguous | Ask |

**When ambiguous, ask:** *"Should I use the Chisholm approach (multi-section governance
document with metadata) or the Intralign approach (precise grammatical rule-based
definition)?"*

---

## Pre-Flight: Gather Context (Both Methods)

Do not draft until you have all of the following. If missing, ask before proceeding.

**Required:**
- **Term Name** — exact spelling as it will appear in the glossary
- **Object Type** — one of: Business Concept | Database Table | Database Column |
  Entity Type | Entity Attribute | Application Screen/Label | Interface File |
  Reference Data
- **Domain** — pharmaceutical subdomain, not just "pharma" (e.g., Clinical Trials,
  Manufacturing/GxP, Pharmacovigilance, Regulatory Affairs, Quality Control,
  Supply Chain, Drug Substance, Drug Product, Commercial Operations)
- **Primary Use Case** — how the term is used operationally

**Strongly recommended (ask if not provided):**
- **Target Audience** — who reads this (data stewards, QA engineers, regulatory scientists, business analysts)
- **Known Ambiguities** — conflicting interpretations across teams (R&D vs Manufacturing
  vs Regulatory vs Commercial)
- **Regulatory/Standards Alignment** — relevant standards (ICH, CDISC, IDMP, ISO 11238,
  HL7 FHIR, etc.)
- **Lifecycle Boundaries** — when does something *become* this thing, and when does it
  *cease* to be this thing?
- **Key Exclusions** — what this term is explicitly NOT

---

## Workflow: Chisholm Method

Load `chisholm.md` — it contains the full 22-item quality checklist,
critique template, and three worked examples.

- [ ] Step 1: Pre-flight context complete
- [ ] Step 2: Select definition type(s) — see table below
- [ ] Step 3: Draft using the Chisholm output template
- [ ] Step 4: Apply the 22-item well-formed definition checklist (15/22 minimum for
  draft; 22/22 for approval-ready)
- [ ] Step 5: Produce the self-critique (mandatory — not optional polish)
- [ ] Step 6: State approval readiness and outstanding SME questions

### Definition Type Selection

Multiple types are permitted; apply all that fit.

| Type | Use when |
|---|---|
| Essential | Core concept; the definition explains its inherent nature |
| Distinctive | Must be differentiated from a closely related concept |
| Causal | *Why* the concept exists is crucial to correct use |
| Accidental | Involves arbitrary or context-dependent criteria or thresholds |
| Ostensive | Finite, stable set of values; best explained by enumeration |
| Stipulative | Bounded technical or integration context with precise scope |
| Legislative | Authoritative external definition must be cited verbatim |

---

## Workflow: Intralign Method

Load `intralign.md` — it contains full grammar rules, business rule
type examples, ambiguity checklist, and five worked examples.

- [ ] Step 1: Pre-flight context complete
- [ ] Step 2: Identify the most specific appropriate classification class for Part 2
- [ ] Step 3: Draft Part 1 (naming), Part 2 (classification rule), Part 3 (business rules)
  in order
- [ ] Step 4: Run the ambiguity elimination checklist before finalising
- [ ] Step 5: Format using the Intralign output template

---

## Key Rules: Chisholm

- **Real, not nominal.** Define the concept, not the word. Wrong: *"Batch is the term
  used for a quantity..."* Right: *"A batch is a defined quantity of material..."*
- **No tautology.** Do not use the term being defined within its own definition.
- **Scope must be explicit.** Every definition needs an Includes / Excludes split.
- **Positive before negative.** State what the concept IS; add exclusions only when
  confusion risk is high.
- **Critique is mandatory.** A definition without a self-critique is incomplete — it
  is the mechanism that surfaces SME questions and drives the approval cycle.
- **Accuracy metadata is mandatory.** Confidence level, validation status, and dates
  must be populated on every definition, even if values are "Pending" or "TBD".
- **No embedded definitions.** Do not define two terms simultaneously within one entry.

---

## Key Rules: Intralign

- **Term is always the grammatical subject.** Every sentence begins with the full term
  name. Never invert. Wrong: *"A substance that... is the API."*
  Right: *"Active Pharmaceutical Ingredient is a substance that..."*
- **Classification class must be pre-defined or universally understood.** Valid classes:
  substance, process, document, material, equipment, role, event, data element,
  organisational unit, analytical method, quality attribute. Do not classify under a
  class that is itself undefined in the glossary.
- **Modal verbs carry precise meaning:**
  - `must` = absolute requirement (regulatory, GxP, safety-critical)
  - `should` = strong recommendation or good practice
  - `may` = optional or discretionary
- **No CRUD verbs.** Never use create, read, update, or delete.
- **No process-oriented language.** Definitions describe states and constraints, not
  workflows. Wrong: *"Drug Substance goes through..."* Right: *"Drug Substance undergoes..."*
- **One idea per sentence.** Break compound relationships into separate business rules.
  Never chain with "and which" or "and must also."
- **No circular classification.** The term must not appear as the object in its own
  Part 2 classification rule.

### Business Rule Types (Intralign)

Use the minimum set that fully characterises the term.

| Rule Type | Describes | Verb pattern |
|---|---|---|
| Functional | What the term DOES or its PURPOSE | provides, controls, monitors, evaluates |
| Consequential | IMPACT or outcome when this term applies | results in, triggers, requires |
| Formula | CALCULATIONS or mathematical relationships | is calculated as, is expressed as |
| Conditional | WHEN or UNDER WHAT CONDITIONS something applies | is required when, applies if |
| Characteristic | Inherent ATTRIBUTES or properties | must be identified by, must include |
| Compositional | What the term CONTAINS or CONSISTS OF | comprises, contains, consists of |

---

## Output Format: Chisholm

```
TERM: [Exact term or concept name]
OBJECT TYPE: [from pre-flight]
DOMAIN: [pharmaceutical subdomain]

---

### Summary Definition
[1–3 sentences. Real definition. Appropriate definition type(s) applied.
Audience-accessible language.]

---

### Full Description
[3–6 sentences. Core characteristics, function in pharma operations,
key relationships, boundaries.]

---

### Synonyms
[Abbreviations, alternates, legacy terms.
Format: "Term A, Term B (context), Term C [deprecated]"
Omit section if none.]

### Homonyms
[Terms that look similar but carry a different meaning.
Omit section if none.]

---

### Context
[Organisational scope (global/regional/site/function).
System/process scope (which systems or workflows use this).
Temporal scope (lifecycle phase, if applicable).]

---

### Scope
Includes: [what is covered]
Excludes: [what is explicitly not covered]
Edge cases: [borderline situations, if relevant]

---

### Purpose
[Why this concept exists. Business objectives. Regulatory or compliance rationale.]

---

### Standards Used
[Standard Name (Code/Version): relevant section or principle.
Omit section if no standards apply.]

---

### Known Issues
[Ambiguities, conflicting interpretations, implementation difficulties.
Omit section if none.]

---

### Source
[SME or department. Regulatory reference if applicable.
Date of last review. Version number.]

---

Stipulated Definition? [YES / NO — if YES, explain bounded context]
Legal/Regulatory Definition? [YES / NO — if YES, cite regulation and section]

---

### Accuracy
- Confidence Level: [High / Medium / Low]
- Last Validated: [Date or "Pending"]
- Next Review Date: [Date or "TBD"]
- Validation Status: [Draft | Under Review | Approved | Needs Revision]
- Approver/Reviewer: [Name/Role or "TBD"]

---

## Definition Critique

### Strengths
[What works well]

### Weaknesses & Gaps
[What is missing or unclear]

### Checklist Failures
[Which criteria failed, and why]

### Questions for SMEs
1. [Question about concept boundaries or lifecycle]
2. [Question about regulatory/standards applicability]
3. [Question about cross-functional usage or exceptions]

### Approval Readiness
Status: [Not Ready | Needs Minor Revision | Ready for Review | Ready for Approval]
Rationale: [one sentence]
```

---

## Output Format: Intralign

```
**[Term Name]** (Abbreviation: [if applicable])
Synonyms: [if applicable]
Regulatory Alignment: [standard and version, if applicable]

[Term] is a [class] that [essential differentiating characteristic].

[Term] [must/should/may] [functional rule].

[Term] [must/should/may] [characteristic or compositional rule].

[Term] [must/should/may] [additional rules as needed — one per line].

[Exclusion statement if needed: "[Term] is distinguished from [X] by [criterion]."]
```

Plain prose sentences only — no bullet points. Each rule on its own line.

---

## Gotchas

- **Lifecycle boundaries are almost always missing from first drafts.** Even experienced
  SMEs overlook them. Always ask: *"When does something become this thing, and when
  does it cease to be this thing?"*
- **"Pharmaceutical" is not a domain.** Insist on the subdomain — the same term
  (e.g., "Batch") means different things in Manufacturing vs Clinical vs QC contexts.
- **Intralign rules are sentences, not bullets.** Newcomers format them as a bulleted
  list. Do not. Each rule is a complete declarative sentence beginning with the term name.
- **Chisholm's Scope section is not just a description.** It must have an explicit
  Includes list and an explicit Excludes list. A Scope section that is only prose fails
  the checklist.
- **Definition types are not mutually exclusive.** A term like "Critical Quality
  Attribute" can be Essential + Distinctive + Legislative simultaneously. Apply all
  that fit rather than forcing one.
- **The Chisholm critique is not optional.** Skipping it produces a definition that
  looks complete but hasn't been stress-tested. Always include it, even for drafts.
- **Intralign's classification class must itself be unambiguous.** If classifying as
  "a process," that implies a pharmaceutical process with known meaning. If the class
  is itself unfamiliar to the audience, choose a more specific or more common class.

---

## References

| File | Load when |
|---|---|
| `chisholm.md` | Using Chisholm method — contains full 22-item checklist and three worked examples |
| `intralign.md` | Using Intralign method — contains full grammar rules, ambiguity checklist, and five worked examples |
