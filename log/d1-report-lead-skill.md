# D1 Report — Entry-Posture Skill

**Ticket:** skills-skills-coding-arch-kva
**Deliverable:** D1 — the entry-posture skill
**Status:** Draft complete, awaiting reviewer approval before D2

---

## What was delivered

New skill: `agent-workflow/lead/SKILL.md` (~80 lines).

The "lead" skill captures the managing-up posture: user arrives with an
ambiguous goal or unease, agent works upward to reshape the ask, surface
blind spots, and converge on scope/outcome/acceptance criteria. The
convergent output is a written brief — the handoff artifact to the
manage-down posture.

## Naming resolution: "lead"

**Chosen:** `lead`
**Alternatives considered:** orchestrator, coach, shaper

Reasoning:

- **"supervisor"** is taken and means manage-down (polished, 60 lines,
  references delegation/verification/retirement). The contrast is
  deliberate: lead owns the *ask*, supervisor owns the *phase outcome*.
- **"orchestrator"** collides with the dead `orchestration` skill being
  archived, and implies coordination of known parts — wrong for the
  entry posture which discovers the parts.
- **"coach"** captures "working upward" but sounds informal for an agent
  posture and implies the user needs coaching.
- **"lead"** is short, pairs naturally with "supervisor," and becomes
  obvious once you see the lead/supervisor pair in the posture model.
  The supervisor skill's own framing ("the supervisor owns the phase
  outcome") creates the right contrast.

## New skill vs salvage of `orientate`

**Decision:** New skill. Do not salvage `orientate` for D1.

Reasoning:

- `orientate` is coupled to dead me-CLI tooling (`me tk`, `me proj`,
  `me jot`, `me search`). Its workflow, primary commands, and good
  patterns are all me-CLI-specific.
- The new skill must be tool-agnostic (the load-bearing principle).
- Phase 4 handles salvage rewrites of orientate. Creating a new
  entry-posture skill now and letting Phase 4 coordinate is cleaner
  than trying to salvage orientate mid-Phase-3.
- The *conceptual* value of orientate (cross-source pattern surfacing,
  "reduce ambiguity not list," orientation lenses) is captured in the
  lead skill's operating rules. The durable thinking survives even
  though the skill body is new.

**Coordination note for Phase 4:** When orientate is salvaged, it should
reference the lead skill as its posture owner. Orientate becomes the
tool-specific implementation of the lead posture for the
ticket/project/jot domain, the way `slice-supervisor` is the
tool-specific implementation of the supervisor posture for Go coding.

## How the lead skill relates to existing skills

| Existing skill | Relationship |
|---|---|
| `supervisor` | Complementary. Lead shapes; supervisor executes. Same pipeline, different postures. |
| `orientate` | Lead captures orientate's posture without its tooling. Phase 4 will reconnect them. |
| `discovery-architect` | Discovery-architect is a spine-stage skill (research/architect). Lead may invoke it during shaping. |
| `spike-planning` | Spike-planning is the planner. Lead produces the brief that feeds it. |
| `feature-handoff` | Superseded by the brief pattern (see D4). |

## Open questions — proposed resolutions

### Q1: Naming → "lead" (resolved above)

### Q2: New skill vs salvage → New skill (resolved above)

### Q3: Global-default vs library for orchestration protocol (D2)

**Proposed:** Global-default, kept short (40–60 lines). Reasoning:
the orchestration protocol is the ambient operating knowledge — postures,
transitions, artifact conventions. Every structured work session needs
it. Making it library means agents won't know the posture model unless
explicitly loaded, which defeats the purpose. The "keep it short"
constraint from the brief is the real safeguard against the
agent-workflow-quartet fate.

### Q4: Single-agent-posture-shift vs multi-agent-sub-spawn

**Proposed:** Support both. The protocol describes postures and
transitions; the execution model (same agent shifts posture vs sub-agents
spawned per stage) is a runtime decision. Don't force one model. The
lead skill already supports both (same agent can shift from lead to
supervisor; or a lead can spawn an executor sub-agent). The orchestration
protocol (D2) should state this explicitly.

## What I challenged in the brief

Nothing major. The brief's posture model, artifact conventions, and
rules-over-procedures approach are sound. The one thing I'll flag: the
brief says the entry posture "is a coach, project manager, and architect
combined." I think "coach" overstates the user-facing aspect — the lead
is more of a *scoping partner* than a coach. The skill reflects this
(more "shape the ask" than "develop the user's capability"). Minor
framing difference, not a substantive disagreement.

## Next step

Await reviewer approval of the lead skill and naming resolution. Then
proceed to D2 (orchestration protocol).
