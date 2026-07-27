---
name: meeting-to-kb
description: >-
  Extract a meeting transcript into a structured Obsidian knowledge base:
  meeting record with rich annotation, entity stubs, decisions, questions,
  actions, tensions. Use whenever processing a meeting transcript, call notes,
  or recording an interview/handover/workshop/standup into the engagement KB.
  Parameterised by meeting type — a standup needs minimal extraction, a
  handover needs full extraction with tensions and entity backbone.
license: MIT
domain: knowledge-management
role: specialist
scope: operations
output-format: structured-notes
triggers:
  - meeting transcript
  - process this meeting
  - extract from transcript
  - meeting record
  - call notes
  - handover meeting
  - standup notes
  - workshop notes
---

# meeting-to-kb — meeting transcript → structured knowledge base

Codifies the pipeline for turning a meeting transcript into structured KB
content. Built and proven on the Cynozure engagement; generalisable to any
Obsidian KB that follows the same model.

**Read the engagement's `KB STRUCTURE.md` first** — it carries the schema
contract (entity types, naming, foreign keys). This skill carries the
*process*; the STRUCTURE doc carries the *rules*.

## The one rule

> Annotation lives in the **meeting record**, not the **transcript**. The
> transcript is a read-only source artefact. Never edit it; never add
> wiki-links to it. All extraction lands in the meeting record, which links
> *to* the transcript.

This keeps the graph clean: entities connect to a readable meeting note, not
to a transcript blob. Backlinks pile up on a structured note, not on an
uneditable source.

## Pipeline (always run in this order)

### 1. Read, don't annotate

Read the transcript end to end. Note transcription artifacts (consistent
mis-transcriptions like "Zenajor" for "Cynozure"; garbled acronyms like
"calendar toolkit" → Calandra). Flag them; do not fix them in the transcript
(that's the user's call).

### 2. Build the meeting record

Create or update `Meetings/<YYYY-MM-DD> - <Title>.md` from the meeting
template. Frontmatter: `type: meeting`, `date`, `meeting_type` (see below),
`attendees` (as `[[wiki-links]]`), `status`, `topics`.

Body sections (fill what the meeting warrants — see meeting-type table):

- **Source** — link to the transcript + any screen-share images.
- **Summary** — 2–4 sentences of what the meeting was about.
- **Attendees** — `[[wiki-linked]]`.
- **Context / background** — orientation given (handover/workshop only).
- **Decisions** — stated-as-true claims and decisions; spin significant ones into `Decisions/D-NNN` notes.
- **Phase / project status** — what's live, current, next (where reported).
- **Tensions / issues / risks** — underlying disagreements, delivery risks, leadership churn.
- **Entities mentioned** — wiki-linked, by group (people / orgs / systems / concepts).
- **Open questions raised** — spin each into `Questions/Q-NNN` and link.
- **Actions** — `[[Actions/A-NNN]]` links + inline `[ ]` items.
- **Notes** — anything else.

### 3. Extract entities → stub all, flag uncertain

For every named person, organisation, system, concept, data asset, project:

- **Stub all of them** — flat in `Entities/`, full canonical name as filename.
- **Flag uncertain ones** with `verified: false` + a `## Verification` checklist
  (unnamed people → stub by role e.g. `Clarus - Data Governance Lead`;
  surnames TBD; transcription artifacts).
- **Never commit a phantom.** If "Zenajor" is a mis-transcription of Cynozure,
  it's an alias on Cynozure, not its own stub. If "calendar toolkit" likely
  resolves to Calandra, stub Calandra with `verified: false` and a
  verification note explaining the inference — surface the question, don't
  hide it.
- Link each entity from the meeting record's Entities-mentioned section. Use
  a `?` marker after the link for `verified: false` stubs.

### 4. Spin out decisions and questions

- **Decisions** → `Decisions/D-NNN - <Topic>.md`. A decision is the topology;
  questions hang off it. If the meeting surfaces a central decision (like
  "reuse, adapt, fork or reject the US asset"), it becomes the spine that
  other questions reference via `decision: D-NNN`.
- **Questions** → `Questions/Q-NNN - <Topic>.md`. The filename is the *topic*
  (noun phrase); the actual question lives in the `question:` frontmatter
  field. Add `decision:` (FK), `category:` (controlled vocab), `impact`
  (orthogonal to priority).

### 5. Wire the graph

- Every entity, decision, question, action links back to the meeting record
  in its `## Evidence` section.
- The meeting record links out to every entity/decision/question/action.
- Use the obsidian CLI (`move`, `backlinks`, `orphans`) for graph operations,
  not bash grep — it understands the link graph natively.

### 6. Verify, then commit

Run `kb lint` (the engagement KB linter) — it aggregates all checks in one
command and exits non-zero on critical issues:

```
kb lint              # all checks; exit 1 on broken links / missing frontmatter
kb links             # broken-link report only (uses obsidian CLI under the hood)
kb orphans           # unreachable notes (filters attachments/templates/hub)
kb counts            # Q-sequence + required-frontmatter completeness
kb verify            # the verified:false queue, grouped by type
kb drift             # hub stated counts vs reality (catches stale hub text)
kb stale <regex>     # references to an old/renamed name (post-rename safety)
```

The lint delegates graph queries (links, orphans) to the `obsidian` CLI, which
is authoritative for Obsidian's link resolution — a regex parser can't replicate
alias/attachment/short-form rules. The Ruby layer adds the schema-aware checks
(frontmatter, FK, drift) the CLI doesn't know about.

If lint reports broken links:
- Aliased display links like `[[Kunal]]` are **broken** if the note is
  `Kunal Yadav.md` — aliases in frontmatter don't make `[[Kunal]]` resolve.
  Fix to `[[Kunal Yadav|Kunal]]` (target|display).
- Missing stubs → create them, or delink to plain text.
- Path-style links to files outside the vault (e.g. `[[reference/...]]`) →
  convert to plain text with the path in backticks.

Only commit once `kb lint` exits 0.

### 7. Pause, then interpret (paired skill)

Extraction is *what was said*. For substantive meetings (handover, steerco,
workshop, legal), follow with the paired skill **`kb-juice-squeeze`** —
*what it means*. That pass re-mines the source for under-extracted content,
reads the subtext, projects forward into risks and scope traps, forms/updates
working hypotheses, and advises on operating posture. It enriches four living
docs: stakeholder assessment, engagement operating notes, risk register,
hypotheses register.

Run them **separately, with a pause between**. Interpretation done in
extract-mode is worse — you're still inside the source, not above it. And
don't run the second pass on every meeting; standups and routine 1:1s don't
warrant it.

(If the four interpretive docs don't yet exist, the first run of
`kb-juice-squeeze` creates them; subsequent runs enrich.)

## Meeting-type table

The meeting type drives extraction depth. Set `meeting_type` in frontmatter;
fill sections accordingly.

| `meeting_type` | Summary | Context | Decisions | Phase | Tensions | Entities | Questions | Actions |
|---|---|---|---|---|---|---|---|---|
| `handover` | full | full | full | full | **full** | **full** | full | full |
| `workshop` | full | partial | full | partial | partial | full | full | partial |
| `steerco` | full | — | **full** | full | partial | partial | partial | partial |
| `1:1` | partial | — | partial | — | partial | partial | partial | full |
| `standup` | brief | — | — | brief | blockers only | — | — | full |
| `legal` | full | partial | full | — | partial | partial | **full** | partial |

Tensions are the highest-value extraction in handover and steerco meetings —
they surface the politics and delivery risk that don't appear in any other
artifact. Under-extract them in standups (just blockers).

## Anti-patterns

- **Annotating the transcript.** Annotation goes in the meeting record.
- **One Q-note per small question.** A Q-note earns its page when it has
  significant evidence, multiple stakeholders, or may become a formal
  assumption/decision. Otherwise it stays as a bullet in the meeting record's
  Open-questions section, or in `further-questions-backlog.md`.
- **Type-folders for entities.** All entities flat in `Entities/`, organised
  by `type:` frontmatter. No `People/`, `Organisations/` etc.
- **Question-fragment titles.** The filename is the *topic* (noun phrase), not
  the question. The question lives in `question:` frontmatter.
- **Manual link rewriting on rename.** Use `obsidian move` — it auto-rewrites
  backlinks. Bash-grep rewrites are slower and miss edge cases.

## Tooling

- **Obsidian CLI** (`obsidian <command>`): `move` (rename + backlink rewrite),
  `backlinks`, `orphans`, `deadends`, `links`, `create`, `file`.
- **Git** version-controls the KB folder; commit after each meeting
  extraction.
- **DEVONthink** indexes reference material; data-asset stubs carry a
  `dt_url:` field for the `x-devonthink-item://` URI.

## Related

- Engagement `KB STRUCTURE.md` — the schema contract. Read first.
- `skill-creator` — for authoring/iterating this skill.
- `skills-manage` — for where skills live and how they deploy.
