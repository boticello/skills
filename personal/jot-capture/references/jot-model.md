# Jot conceptual model

> Migrated from `~/Me/OS/agents/guidance/document-management/jot-model.md` on
> 2026-07-02. The canonical operational skill is the parent `SKILL.md`; this
> file is the conceptual reference.

## Purpose

This note records the intended conceptual model for `me jot`.

`jot` is not a note-taking app in miniature. It is a compact durable-record mechanism within the wider `me` system.

## Core definition

A `jot` is a small durable record whose **semantic type** is carried by `kind`, and whose **situational role** is carried by links, tags, and context.

This distinction is important.

- `kind` answers: *what sort of record is this?*
- links/tags/context answer: *what is it for, and what is it about?*

## Generic container, not many special containers

`jot` should remain a generic documented-information container.

The system should resist proliferating many top-level capture mechanisms for every conversational or workflow need. In most cases the right move is:
- use a small number of jot kinds
- use links and tags to express role and context

## Current kinds

Current working kinds are:
- `note`
- `observation`
- `reflection`
- `idea`
- `decision`
- `progress`
- `design-brief`
- `spec`

## Structural reality

In the current `me` system, a ticket note is structurally a linked jot.
`me tk note` creates a jot record whose `parent` is the ticket.

So the distinction between:
- ticket note
- linked jot
- ticket-linked design note

is usually **not** a difference in storage structure.
It is mainly a difference in semantic role.

This matters because workflow language can make these look like different object types when they are actually different uses of the same underlying record form.

## Recommended interpretation

### Semantic kind
A **kind** should answer:
- what sort of record this is in epistemic or informational terms
- what the record is *made of*, not merely what workflow step it participates in

Examples:
- `observation` — something noticed
- `reflection` — interpretation, learning, retrospective sense-making
- `idea` — possible direction or possibility
- `decision` — something chosen and worth preserving
- `progress` — a durable update about ongoing work
- `note` — generic fallback where stronger distinction is unnecessary

### Situational role
A **role** should answer:
- what the record is for in a workflow or workstream
- how it functions in relation to a ticket, project, session, or process

Examples of roles:
- plan
- release-note
- handoff
- FAQ / Q&A
- session-summary
- lesson

Roles are usually carried by:
- ticket/project linkage
- tags
- content structure / headings
- surrounding workflow context

### Design-oriented kinds under review
`design-brief` and `spec` currently exist as kinds, but they are somewhat less stable conceptually than the core epistemic kinds.

They remain usable, but the system should treat them as **under review rather than unquestioned ontological categories**.
In particular:
- `design-brief` may overlap with what is sometimes being called a plan
- `spec` may remain justified when the content is genuinely more formal and behavioural

The current working rule is:
- prefer the compact kind system
- avoid creating `plan` as a new kind by default
- treat plan primarily as a workflow role unless and until a stronger semantic distinction is established

## What should usually be tags or roles, not kinds

Examples:
- `handoff`
- `session-summary`
- `bootstrap`
- `review`
- `lesson`
- `release-note`
- `plan`

These are generally not distinct knowledge types. They are better represented by:
- ticket/project linkage
- tags
- surrounding work context
- or content inside the jot itself

The ticket 186 stress-test work adds an important qualification: in some cases the challenge is not classification but modelling. A handoff, for example, is not difficult to classify — it is a handoff. The harder question is what structural support it needs: links, anchors, relations, extracted references, and other "bones" that make it retrievable and connective without forcing it into a new jot kind.

## Plan pattern

A plan should usually be treated as a **ticket-note role**, not a separate jot kind.

The authoritative durable record for an approved plan should live in the database as content, not merely as a pointer to a session file.
In practice this means:
- the plan is attached to the ticket as a ticket-linked note
- the note should be clearly labelled in content or tags as a plan artefact
- session plan files may still exist for approval workflow, but they are not the authoritative memory layer

A compact implementation plan will usually fit as:
- a ticket-linked note
- often `kind: note` or `kind: progress`, depending on how plan-like versus update-like the content is
- tagged or structured as `plan` when useful

`design-brief` should only be preferred when the content is genuinely about concise design framing rather than simply an approved implementation plan.

## Release-note pattern

A release note should be treated as a **jot role**, not a separate jot kind.

The default representation should usually be:
- `kind: progress`
- linked to the relevant ticket anchor
- optionally linked or tagged for the relevant project or subsystem
- tagged with `release-note` plus area tags such as `me-cli`, `fs`, `feature`, `bugfix`, or `refactor`

This keeps the jot model compact while still making shipped changes easy to retrieve and review.

## FAQ / Q&A pattern

A FAQ or reusable Q&A entry should also be treated as a **jot role**, not a separate jot kind.

The default representation should usually be:
- `kind: note`
- linked to the relevant ticket or project when the answer belongs to a work cluster
- tagged with `faq` and/or `qa` plus relevant topic tags

This pattern is useful when the content is not primarily reflection or progress, but a reusable answer to an operational, conceptual, or workflow question.

If the answer becomes standing guidance for the system as a whole, it should usually be promoted into a maintained note in `00-system/docs` rather than remaining only as a jot.

## Linking guidance

Link a jot to a ticket or project when:
- it records intent for tracked work
- it records progress on tracked work
- it captures a decision affecting tracked work
- it is intended to help future handoff or audit

Use standalone jots when the record is broadly useful beyond a single workstream.

## Handoff use

A good handoff bundle often includes linked jots of several kinds:
- observation
- reflection
- decision
- progress

This gives future sessions both:
- the task state
- the thinking state

## Design principle

Keep the jot typology:
- small
- orthogonal
- durable
- useful in retrieval

The system should prefer a stable model plus good linking/tagging over a large and fragile type taxonomy.
