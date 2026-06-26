---
name: "system-self-care"
description: "Run deliberate maintenance passes over the governance memory system to reduce drift, improve layer boundaries, and produce durable follow-up actions."
alwaysAllow:
  - Bash
requiredSources:
  - system-files
exclude_tools:
  - claude_code
  - codex
  - opencode
  - pi

---

# system-self-care

Use this skill when the job is to tend the governance memory system itself rather than to orientate the user or mutate one isolated object.

## Relationship To Orientation And Audit

This is the maintenance and tending skill.

Use `system-self-care` when the question is:
- is the system lean, clean, coherent, and still trustworthy?
- where is drift accumulating in notes, tickets, skills, jots, micro-docs, or operating guidance?
- what needs to be clarified, consolidated, promoted, revised, or retired?

Use the [`br`](tools/br) issue tracker's audit surface (`br ready`, `br blocked`, `br stale`, `br lint`) when the job is narrower ticket diagnosis and backlog hygiene.

Use [`orientate`](/Users/bear/Me/00-system/agents/skills/orientate/SKILL.md) when the job is broader orientation across several source types in service of `What? So what? Now what?`.

## Primary commands and surfaces

- `me tk list`
- `me tk show`
- `me search`
- `me jot list`
- `me jot show`
- `rg`
- `fd`

Common source areas:
- `~/Me/00-system/areas/`
- `~/Me/00-system/tools/cli/docs/micro/`
- maintained governance notes
- relevant tickets and projects
- related skill definitions
- recent reflections and design notes

## Purpose

This skill supports the recurring practice of keeping the governance memory system coherent, current, legible, appropriately externalised, and able to evolve without unmanaged drift.

It is not casual tidying.

It is a deliberate maintenance pass over the system of:
- notes
- tickets
- jots
- skills
- micro-docs
- automations and capability ideas

## Start

1. Define the scope of the self-care pass.
2. Decide whether the pass is light, standard, or deep.
3. Gather the authority map for the relevant governance area.
4. Walk the map selectively rather than trying to read everything.
5. Create or identify a ticket when the pass itself is part of tracked governance work.

## Work

Inspect the system for:
- drift
- overlap
- omission
- obsolescence
- weak layer boundaries
- insufficient cross-linking
- useful guidance still trapped in chat or local session context

Check at least these lenses where relevant:
- coverage
- drift and contradiction
- boundary quality
- corpus shape
- rule quality
- obsolescence

Questions to ask:
- what practices are still only in chat?
- what repeated behaviour still lacks durable guidance?
- what belongs in a different layer?
- what should be revised, merged, split, promoted, or retired?
- what now deserves a ticket, maintained note, skill, automation, or `me` capability?

## End

1. Produce a system self-care report.
2. Produce an action bundle when follow-up work is needed.
3. Externalise important findings into tickets, note revisions, jots, micro-docs, or direct improvements.
4. Prefer individual real-action tickets over one omnibus ticket unless coordination genuinely requires a parent ticket.
5. Record anchors to the source material that informed the findings.

## Decision rules

- Treat the corpus as one operating model, not as disconnected files.
- Prefer deliberate refinement over reactive proliferation.
- Preserve readability as well as correctness.
- Favour promoting repeated useful patterns into durable guidance.
- Do not create new artefacts unless a distinct new note, ticket, skill, automation, or capability is genuinely warranted.
- If the real need is user situating rather than system tending, widen into [`orientate`](/Users/bear/Me/00-system/agents/skills/orientate/SKILL.md) instead of forcing orientation into self-care.
- If the real need is narrower ticket diagnosis, use the [`br`](tools/br) audit commands (`br ready`, `br stale`, `br lint`) rather than a full self-care pass.

## Good patterns

```bash
me tk list --path 00-system --status open
me search "skills architecture"
me jot list -k reflection -n 20
rg -n "authority map|context bundle|self-care|orientation" ~/Me/00-system/areas
fd . ~/Me/Me/00-system/tools/cli/docs/micro
```

## Output pattern

A good self-care output should include:
- scope reviewed
- pass depth (`light`, `standard`, or `deep`)
- source sets walked
- key findings grouped by category
- overall judgement on system health
- action bundle
- durable artefacts created, updated, or recommended
