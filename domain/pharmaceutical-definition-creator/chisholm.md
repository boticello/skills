# Chisholm Method — Reference Material

## Well-Formed Definition Checklist (22 items)

Apply after drafting. Score each item pass/fail.
Threshold: 15/22 for Draft status; 22/22 for Approved status.

### Conceptual Integrity
- [ ] **Real not nominal** — defines the concept itself, not just the word
- [ ] **Complete** — covers all essential aspects without gaps
- [ ] **Entity vs concept** — entity instances lack definitions; concepts require them
- [ ] **Term applicability** — definition genuinely applies to the stated term
- [ ] **Disambiguates equivocal terms** — resolves ambiguity when term has multiple meanings

### Coverage and Boundaries
- [ ] **Covers the concept** — addresses full conceptual scope
- [ ] **Doesn't exceed concept** — includes nothing beyond the concept's boundaries
- [ ] **Not unnecessarily obscure** — appropriate complexity for the audience
- [ ] **Positive not negative** — states what something IS rather than isn't (where possible)

### Structural Quality
- [ ] **No embedded definitions** — does not define multiple terms simultaneously
- [ ] **Not tautological** — does not define the term using itself
- [ ] **No circular reasoning** — definition chain terminates in understood primitives
- [ ] **Not an enumeration** — does not merely list instances (unless ostensive type)
- [ ] **Avoids unexplained synonyms/near-synonyms** — related terms are defined elsewhere

### Language and Tone
- [ ] **Not self-congratulatory** — no promotional or self-aggrandising language
- [ ] **Not persuasive** — objective and factual, not argumentative
- [ ] **No emotive language** — neutral, professional tone throughout
- [ ] **Explicit ambiguity** — known ambiguities surfaced, not hidden
- [ ] **Managed repetition** — necessary reinforcement without redundancy

### Audience Suitability
- [ ] **Creator-friendly** — clear for those who maintain the definition repository
- [ ] **User-friendly** — accessible to those who consult definitions during work
- [ ] **Practitioner-friendly** — meaningful to those doing hands-on work with the concept

---

## Critique Template (expanded)

```
## STRENGTHS
[What aspects of this definition work well? E.g. clear essence, good standards
grounding, appropriate definition type selection, suitable audience register.]

## WEAKNESSES & GAPS
[What is missing or unclear? E.g. insufficient context for a specific audience,
ambiguity around a specific aspect, missing relationship to a related concept.]

## CHECKLIST FAILURES
[Which checklist items failed and why?]
- Item: [criterion]
  Problem: [specific issue]
  Recommendation: [how to fix]

## ADDITIONAL INFORMATION NEEDED

### Questions for SMEs
1. [Specific question about concept boundaries or lifecycle]
2. [Question about regulatory/standards applicability]
3. [Question about relationships to other concepts]
4. [Question about operational usage]
5. [Question about known variations or exceptions]

### Data/Documentation to Obtain
- [Regulatory guidance documents]
- [Standard operating procedures]
- [Related concept definitions]
- [Usage examples from actual work products]

## REVISION RECOMMENDATIONS
1. [First revision needed]
2. [Second revision needed]
3. [Third revision needed]

## APPROVAL READINESS
Status: [Not Ready | Needs Minor Revision | Ready for Review | Ready for Approval]
Rationale: [Brief explanation]
```

---

## Worked Example 1 — Business Concept (Essential Definition)

**TERM:** Critical Quality Attribute (CQA)
**OBJECT TYPE:** Business Concept
**DOMAIN:** Manufacturing/Quality

**Summary Definition:**
A critical quality attribute is a physical, chemical, biological, or microbiological
property or characteristic of a drug substance or drug product that must be within an
appropriate limit, range, or distribution to ensure the desired product quality. CQAs
are directly linked to patient safety and product efficacy.

**Full Description:**
CQAs represent the measurable properties of pharmaceutical products that, if not
adequately controlled, could directly impact patient safety, therapeutic efficacy, or
regulatory acceptability. These attributes are identified through quality risk management
processes during pharmaceutical development and form the foundation of the control
strategy for commercial manufacturing. CQAs must be monitored through the product
lifecycle and are typically derived from the Quality Target Product Profile (QTPP).

**Synonyms:** CQA, Product Critical Attribute, Critical Attribute

**Homonyms:** Quality Attribute (broader term including non-critical attributes)

**Context:** Applies globally across pharmaceutical development and manufacturing.
Relevant throughout the product lifecycle from development through commercial
manufacturing. Used primarily in QbD initiatives, process development, validation,
and routine manufacturing control.

**Scope:**
Includes: dissolution rate, assay, impurity levels, particle size distribution,
sterility, endotoxin levels, potency, content uniformity
Excludes: process parameters (even if critical), in-process measurements not related
to final product quality, appearance attributes not linked to safety/efficacy

**Purpose:** Ensures systematic identification and control of product attributes most
crucial to patient safety. Enables risk-based pharmaceutical development strategies.
Provides clear focus for analytical method development, specification setting, and
manufacturing process control.

**Standards Used:**
- ICH Q8(R2) Pharmaceutical Development: CQA identification
- ICH Q9 Quality Risk Management: risk assessment methods for CQA identification
- ICH Q11 Development and Manufacture of Drug Substances

**Known Issues:** Disagreement sometimes exists between Development and Manufacturing
on which attributes qualify as "critical." Legacy products may lack formal CQA
designation.

**Source:** Global Quality, based on ICH Q8(R2). Last reviewed: 2024-09-15. Version 2.1

Stipulated Definition? NO
Legal/Regulatory Definition? YES — ICH Q8(R2), adopted by FDA and EMA.

**Accuracy:**
- Confidence Level: High
- Validation Status: Approved
- Approver: Global Head of Quality Systems

---
**Critique:**
STRENGTHS: Essential type correctly applied; strong regulatory grounding; clear Scope.
WEAKNESSES: Could note relationship to Critical Process Parameters more explicitly.
CHECKLIST FAILURES: None.
QUESTIONS FOR SMEs:
1. Are there product-type variations in CQA identification (small molecule vs biologic)?
2. How does the organisation handle borderline risk assessment cases?
APPROVAL READINESS: Ready for Approval.

---

## Worked Example 2 — Database Column (Ostensive Definition)

**TERM:** SUBMISSION_TYPE_CODE
**OBJECT TYPE:** Database Column
**DOMAIN:** Regulatory Affairs

**Summary Definition:**
A coded value identifying the regulatory submission category according to the ICH M4
Common Technical Document classification scheme.

**Full Description:**
This column stores standardised codes representing the type of regulatory submission
being made to health authorities. Values are constrained to the SUBMISSION_TYPE
reference table and determine downstream workflow routing and document requirements.

**Synonyms:** Submission Type, Regulatory Submission Category Code

**Context:** Global Regulatory Information Management System (GRIMS). Applies to all
submissions to FDA, EMA, PMDA, and other health authorities.

**Scope:**
Includes: all submission types listed in ICH M4 hierarchy and regional variants
(NDA, ANDA, BLA, IND, MAA, CTA, etc.)
Excludes: internal project codes, submission status values, document type codes

**Standards Used:** ICH M4 Common Technical Document; FDA ESG guidance; EMA submission
categories guidance.

**Known Issues:** Regional taxonomy variations require mapping logic. Some combination
products require manual SME categorisation.

Stipulated Definition? NO
Legal/Regulatory Definition? YES — submission types are defined by regulatory authorities.

**Example Values (Ostensive):**
- NDA: New Drug Application (FDA)
- ANDA: Abbreviated New Drug Application (FDA)
- BLA: Biologics License Application (FDA)
- MAA: Marketing Authorisation Application (EMA)
- CTA: Clinical Trial Application (EMA)
- IND: Investigational New Drug Application (FDA)
- IMPD: Investigational Medicinal Product Dossier (EMA)

**Accuracy:** Confidence Level: High. Validation Status: Approved.

---
**Critique:**
STRENGTHS: Ostensive type appropriate for enumerated reference data; good regulatory grounding.
WEAKNESSES: Data type and length constraints not specified; governance for adding codes not documented.
QUESTIONS FOR SMEs:
1. What is the technical data type and maximum length?
2. Who has authority to add codes to the reference table?
APPROVAL READINESS: Needs Minor Revision.

---

## Worked Example 3 — Business Concept (Distinctive Definition)

**TERM:** Stability-Indicating Method
**OBJECT TYPE:** Business Concept
**DOMAIN:** Analytical Development / Quality Control

**Summary Definition:**
A stability-indicating analytical method is a validated test procedure capable of
detecting and quantifying changes in the chemical, physical, or microbiological
properties of a drug substance or drug product resulting from degradation, distinguishing
the parent compound from degradation products, impurities, and excipients.

**Full Description:**
Stability-indicating methods specifically differentiate between the active pharmaceutical
ingredient and its degradation products, enabling assessment of drug product stability
over time. These methods must demonstrate selectivity, specificity, and the ability to
resolve all relevant degradation products from the parent compound. Unlike general
analytical methods, stability-indicating methods are subjected to forced degradation
studies during validation to prove their capability.

**Synonyms:** SIM, Stability Indicating Assay, Stability Indicating Test Method

**Homonyms:** Stability Study (the study protocol using these methods, not the method itself)

**Scope:**
Includes: HPLC methods demonstrating degradation product resolution; dissolution
methods showing degradation-related release changes; microbiological methods detecting
organism viability changes
Excludes: identity tests (not quantitative); general purity methods not validated
against forced degradation; methods that cannot distinguish parent from degradants

**Standards Used:**
- ICH Q1A(R2) Stability Testing: defines stability study requirements
- ICH Q2(R1) Validation of Analytical Procedures
- FDA Guidance: Analytical Procedures and Methods Validation (2015)

Stipulated Definition? NO
Legal/Regulatory Definition? PARTIALLY — ICH Q1A(R2) requires these methods but
does not provide an explicit definition; this definition synthesises regulatory
expectations from multiple sources.

**Accuracy:** Confidence Level: High. Validation Status: Approved.

---
**Critique:**
STRENGTHS: Distinctive type correctly highlights key differentiator from general methods.
WEAKNESSES: Examples are HPLC-heavy; does not address how stability-indicating status
is formally documented in the organisation.
QUESTIONS FOR SMEs:
1. What is the formal process for designating a method as "stability-indicating"?
2. How do we handle situations where forced degradation produces no significant degradants?
APPROVAL READINESS: Ready for Approval.
