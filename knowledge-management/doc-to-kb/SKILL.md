---
name: doc-to-kb
description: >-
  Extract a document (deck, PDF, SOW, charter, working paper) into a structured
  Obsidian knowledge base. The document analogue of meeting-to-kb. Produces a
  document note with provenance, summary, evidence-state-tagged claims, and
  extracted entities/decisions/questions. Promotes only durable content into
  the graph; the source stays untouched. Use whenever processing a substantive
  document cited by a Question or Decision — not for bulk doc registration
  (junk stays in DEVONthink). Pairs with kb-juice-squeeze (which gains a
  document reconciliation mode) the same way meeting-to-kb pairs with it.
license: MIT
domain: knowledge-management
role: specialist
scope: operations
output-format: structured-notes
triggers:
  - process this document
  - extract from deck
  - extract from pdf
  - document note
  - read this deck into the kb
  - reconcile document
  - doc to kb
---

# doc-to-kb — document → structured knowledge base

The document analogue of [[meeting-to-kb]]. Meetings get extracted because
they're current — what someone said today is a fact. Documents get extracted
because they're cited — and almost always need reconciling against current
state, because documents age.

**Read the engagement's `KB STRUCTURE.md` first.** This skill carries the
process; that carries the schema contract.

## The one rule

> One document = one source note + structured extraction + selective
> promotion. The source file stays untouched. Only durable entities,
> decisions, and questions get promoted into the graph.

## When to run

The as-needed policy from `KB STRUCTURE.md`: a document earns a KB record
when **first cited by a Question or Decision**. Junk stays in DEVONthink.
Bulk registration is the wrong shape — most documents in `reference/` will
never be cited and shouldn't get stubs.

Documents that do warrant extraction:

- A data asset's source deck or charter (e.g. the Bitwerx presentation)
- An architecture contract cited by Q-009 (which 2025 outputs remain
  authoritative)
- A SOW or commercial reference (cited by Q-008 deliverable shape)
- A governance/RACI doc cited by Q-010 (decision rights)
- Anything a Question or Decision links to that doesn't yet have a record

## Pipeline

### 1. Read with provenance, don't annotate the source

Read the document end to end. The source file stays untouched — same rule as
transcripts. Capture:

- **Provenance**: file path, author (if stated), date (embedded date, not
  filesystem mtime), format, slide/page count.
- **Document role**: `deliverable-summary` / `architecture` / `strategy` /
  `governance` / `commercial` / `charter` / `working-paper` / `data-catalogue`.
- **Temporal status**: `current` / `historical` / `superseded` / `unknown`.
- **Authority**: `proposed` / `approved` / `implemented` / `unverified`.

### 2. Create the document note

Path: `Documents/<source_date or version> - <Title>.md` (use the document's
own date, not today's). The note is the *processed hub*; the source is
linked, never duplicated.

**Schema is enforced by [Fileclass](https://mdelobelle.github.io/fileclass/).**
The `Document` fileClass at `_fileclasses/Document.md` is the canonical
specification — typed frontmatter fields, controlled vocabularies as Select
dropdowns, FK constraints as File/MultiFile. The fileClass auto-binds by path
(`filesPaths: [Documents]`), so any note created in `Documents/` inherits the
schema and gets validated in-editor. Use `Templates/Document.md` for the
skeleton body sections (below the frontmatter); use the fileClass for the
frontmatter itself. Validate with `fileclass validate --fileclass Document`.

This skill teaches the *process*; the fileClass and `KB STRUCTURE.md` together
are the canonical schema.

If a delegation brief exists for this document, it points at the same
templates — schema stays in one place.

### 3. Extract — what the document says

Body sections:

- **## Summary** — 2–4 sentences on what this document is and why it matters.
- **## Source** — link to the file (plain path in backticks; do *not* use a
  wiki-link to a file outside the vault — see [[meeting-to-kb]] citation rules).
- **## Claims (with evidence state)** — the load-bearing section. Each
  significant claim gets its own bullet, tagged with an evidence state.
- **## Entities mentioned** — wiki-linked, by group (people / orgs / systems /
  concepts / data assets), same pattern as meeting records. New stubs created
  as needed (see step 5).
- **## Decisions stated** — promote significant ones to `Decisions/D-NNN`.
- **## Open questions raised** — promote to `Questions/Q-NNN`.
- **## Reconciliation** — filled in step 4 / by `kb-juice-squeeze`.

### 4. The evidence-state vocabulary (per claim)

This is the document-specific insight that doesn't apply to meetings. Each
extracted claim carries one of:

| State | Meaning |
|---|---|
| `historical-intent` | the document states an intention, plan, or target — not a fact about reality |
| `proposed` | a design or decision put forward for approval |
| `approved` | the document records that something was signed off |
| `implemented` | the document asserts this is now built/adopted (still unverified unless checked) |
| `current-unverified` | believed current but not yet checked against the live platform |
| `current-verified` | checked against current state and confirmed |

Why this matters: it operationalises the "treat 2025 material as hypothesis"
decision ([[D-003 - Treat 2025 material as hypothesis]]). Instead of a single
stance on the whole document, each claim gets its own state. A Base query for
`historical-intent` claims about the architecture surfaces everything you
need to validate; a query for `current-verified` surfaces what's safe to rely
on. Most claims in a 2025 deck start as `historical-intent` or `proposed` and
get promoted only after reconciliation.

**Convention:** tag inline at the end of each bullet —
`... the target architecture uses Calandra. _(historical-intent)_`

### 5. Promote into the graph

For each durable entity / decision / question in the document:

- **Entity already stubbed** → link to it from the document note's Entities
  section; add the document to the stub's `## Evidence`.
- **Entity not yet stubbed** → create the stub (same rules as `meeting-to-kb`:
  stub all, flag uncertain, never commit phantoms), then link.
- **Decision** → `Decisions/D-NNN - <Topic>.md`, status `proposed` (most
  document-derived decisions start proposed, not adopted — the document
  *proposed* them, time may have *adopted* or *superseded* them).
- **Question** → `Questions/Q-NNN - <Topic>.md`, particularly revalidation
  questions ("was this output actually produced?", "is this standard still
  governing?"). These are document-extraction's signature contribution.

**Promotion discipline:** not every named thing becomes a stub. The test is
the same as for meetings — *does this earn a page?* Significant content,
multiple stakeholders, or may become a formal decision. Catalogue entries in
a 12-output deck don't get 12 stubs; they're rows in an output-map section
within the document note.

### 6. Reconcile (paired skill: kb-juice-squeeze)

This is where documents diverge from meetings. A meeting is current by
definition; a document is a hypothesis to test. Reconciliation is the act of
testing each claim against current state — and is a mode of `kb-juice-squeeze`,
not part of extraction. Run them separately, with a pause between.

Reconciliation moves (covered in `kb-juice-squeeze`):

- For each `historical-intent` or `proposed` claim, ask: was this implemented?
  Promote to `current-verified` or leave as historical.
- For each named system/standard, ask: is it still governing? Generate a
  revalidation question if unknown.
- For each stated decision-right or approver, ask: does this still hold?
  (The 2025 RACI may have died with the fired director.)
- For each derived assumption, ask: does the current engagement inherit this
  unverified? Flag as a risk if so.

`kb-juice-squeeze` (extended for documents) handles this. Don't run extraction
and reconciliation in one pass — extraction wants close reading;
reconciliation wants stepping back and comparing across the KB.

### 7. Verify and commit

`kb lint` for structural integrity. Then commit. Note: a document extraction
is rarely "done" after one pass — claims start as `historical-intent` and get
promoted through reconciliation over the engagement.

## Document-type variations

Different document roles warrant different extraction depth:

| Document role | Summary | Claims | Entities | Decisions | Questions | Output map? |
|---|---|---|---|---|---|---|
| `architecture` | full | full (evidence-state heavy) | full | full | full revalidation | often (catalogues) |
| `governance` / RACI | full | full | people-heavy | full | decision-rights | no |
| `commercial` / SOW | full | partial (scope clauses) | orgs-heavy | partial | deliverable-shape | no |
| `strategy` | full | partial | partial | promote few | promote few | no |
| `charter` | full | partial | partial | partial | partial | no |
| `data-catalogue` | brief | full (per-asset) | data-asset-heavy | few | version/authority | yes (the catalogue itself) |
| `working-paper` | partial | partial | partial | few | promote as needed | no |

The "output map" technique is for **catalogue-type documents** — a deck whose
purpose is to enumerate a set of artefacts/outputs. For those, an inline table
(Deck content → Interpretation → KB treatment) is the right shape, *for that
document*. It's a technique, not the universal pattern.

## Anti-patterns

- **One note per slide / per section.** Floods the KB. One document = one
  document note; promote only durable content.
- **Bulk registration.** Most docs in `reference/` never get cited; leave them
  in DEVONthink. As-needed, cited docs only.
- **Treating the document as a fact base.** A 2025 architecture deck is a set
  of hypotheses about intended state. Evidence-state every claim.
- **Skipping reconciliation.** Extraction without reconciliation leaves
  `historical-intent` claims sitting as if they were facts. The value is in
  the testing, not the listing.
- **Duplicating content.** The document note links to the source; it doesn't
  reproduce it. Quote sparingly, summarise liberally.
- **`[[wiki-link]]` to a file outside the vault.** Use plain text with the
  path in backticks (e.g. `reference/Supporting Documentation/...pptx`).
- **Doc-level `status` with the 6 evidence values.** Conflicts with the
  existing status fields. Evidence state is per-claim in the body, not a
  frontmatter field.

## Tooling

- **PPTX**: extract text via `unzip -q <deck> -d <tmp>` then read
  `ppt/slides/slide*.xml`. Greppable; preserves slide numbers for citation.
- **PDF**: `pdftotext -layout` for text; `pdftotext -f <n> -l <n>` for a page.
- **DOCX**: `pandoc -f docx -t markdown` or `unzip` + `word/document.xml`.
- **XLSX (data-catalogue)**: open in Excel/Numbers, or use `mistral-ocr-mcp`
  for tabular structure.
- **`kb lint`**: structural verification.
- **`obsidian` CLI**: graph operations.

## Related

- Engagement `KB STRUCTURE.md` — schema contract.
- [[meeting-to-kb]] — the meeting analogue. Same source-vs-processed
  separation; different temporal handling (meetings are current; documents
  are hypotheses).
- [[kb-juice-squeeze]] — paired second pass. Gains a `source_type: document`
  reconciliation mode for documents.
- `kb` CLI — structural lint.
