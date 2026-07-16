# D2 Report — Orchestration Protocol Skill

**Ticket:** skills-skills-coding-arch-kva
**Deliverable:** D2 — the orchestration-protocol skill
**Status:** Draft complete, awaiting reviewer approval before D3

---

## What was delivered

New skill: `agent-workflow/coordination-protocol/SKILL.md` (87 lines).

The coordination protocol is the ambient operating layer for structured
knowledge work. It defines:

- The two postures (lead and supervisor) with the coaching framing from
  the D1 review pushback
- The shared spine (clarify → research → architect → plan → execute →
  review → consolidate)
- Transition rules with failure-mode partners (4 rules, each sourced
  from a real incident or structural failure)
- Artifact conventions (light schemas: brief, report, review, plan)
- Activity types (coding, structured inquiry, planning/design,
  maintenance/triage)
- Execution model (support both posture-shift and sub-spawn)

## Naming: "coordination-protocol"

Chosen over "orchestration" to avoid confusion with the dead
`orchestration` skill being archived in D4. "Protocol" signals this is
the operating layer, not a skill that does coordination work.

## The "coach" framing (from D1 review pushback)

The reviewer's pushback: the lead posture's highest-value behavior is
coaching — holding the stated goal loosely enough to find the real one.
"Scoping partner" undersells this. Incorporated into the lead posture
description:

> "The lead holds the stated goal loosely enough to find the real one —
> that's the coaching move."

This is a sentence, not a section — the skill's rules do the coaching
work regardless of what we call it.

## What I challenged in the brief

Nothing. The brief's D2 spec (postures, transitions, artifacts, failure
modes, rules-framed, short) is sound and I built directly against it.
The one judgment call was the "coordination-protocol" name over
"orchestration" — flagged here so the reviewer can override if they
prefer "orchestration" despite the dead-skill collision.

## How this relates to existing skills

| Skill | Relationship to coordination-protocol |
|---|---|
| `lead` | One of the two postures defined by the protocol |
| `supervisor` | The other posture defined by the protocol |
| `discovery-architect` | Stage-specific skill (research/architect stage) |
| `spike-planning` | Stage-specific skill (plan stage) |
| `write-design-doc` | Stage-specific skill (architect stage) |
| `retro` | Stage-specific skill (consolidate stage) |
| `orchestration` (planning) | Dead skeleton; archive in D4 |

## Open questions — resolved

All four open questions from the brief are now resolved:

1. **Naming:** "lead" (D1, approved).
2. **New vs salvage:** New skill; Phase 4 reconnects orientate (D1, approved).
3. **Global vs library:** Global-default. Both `lead` and
   `coordination-protocol` should be in `global-manifest.toml`.
4. **Posture-shift vs sub-spawn:** Support both, runtime decision (D2,
   stated in the execution model section).

## Next step

Await reviewer approval. Then proceed to D3 (execution spine + tooling
separation).
