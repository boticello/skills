---
name: kb-juice-squeeze
description: >-
  The interpretive second-pass over an engagement knowledge base: re-mine the
  source for what was under-extracted, read the subtext, project forward into
  risks and scope traps, form or update working hypotheses, and advise the
  consultant on posture. Enriches four living docs (stakeholder assessment,
  engagement operating notes, risk register, hypotheses register). Use after
  meeting-to-kb has run on a substantive meeting (handover, steerco,
  workshop); not every meeting warrants it (standups don't). Distinct from
  meeting-to-kb: that's *what was said*, this is *what it means*.
license: MIT
domain: knowledge-management
role: specialist
scope: operations
output-format: structured-notes
triggers:
  - juice squeeze
  - squeeze the juice
  - interpret this meeting
  - what's the subtext
  - what does this mean for the engagement
  - deep read
  - second pass
  - read between the lines
---

# kb-juice-squeeze — interpretation pass over an engagement KB

The second-pass analytical skill, paired with [[meeting-to-kb]]. Extraction
runs first ("what was said?"); this runs after ("what does it mean?"). The two
are deliberately separate skills because they require different cognitive
modes — close-reading the source vs stepping back and reading across what was
extracted.

**Read the engagement's `KB STRUCTURE.md` and the four interpretive docs
first.** This skill carries the *process*; those carry the *state*.

## When to run

- After `meeting-to-kb` has run on a substantive meeting: handover, steerco,
  workshop, legal. These have enough texture to interpret.
- **Not** after every meeting. Standups and routine 1:1s don't warrant it —
  the extraction record stands on its own.
- Run with a deliberate pause after extraction. Interpretation done in
  extract-mode is worse — you're still inside the source, not above it.

## The five moves

Every pass runs all five. They produce different updates to the four docs.

### 1. Re-mine the source — "what did I under-extract?"

Go back to the source (transcript, doc) and look for what `meeting-to-kb`
under-weighted. The extraction pass optimises for completeness of *named*
content; this pass looks for *implicit* content:

- **Emotional register** — what is the speaker signalling? (Cynicism,
  protectiveness, frustration, alliance.)
- **Numbers dropped in passing** — metrics that may be the real success
  criterion in disguise. (The "25-day reimbursement" is a classic — likely
  *the* business KPI hiding in plain sight.)
- **Future-state mentions** — phrases like "eventually", "future state",
  "down the line" that imply a much higher bar than the current scope.
- **Scale and diversity implied** — deployment surface, user counts, data
  volumes that shape what "good" must mean.
- **Acquisitions, stakes, dependencies** — M&A facts that are also IP/dependency
  facts underneath.

Output: anything found enriches the meeting record's *Notes* section or
becomes a new Question/Entity. Often nothing new — that's fine.

### 2. Read the subtext — "what is this *really* saying?"

For each significant claim or tension in the meeting record, ask: *what would
this look like if it were political rather than literal?*

- A "disagreement about whether X has anything concrete" may be
  positioning against an acquisition, scope-defense, or relationship-protection.
- A "firing" may be isolated or a signal of broader exposure.
- A "paused workstream" may explain a downstream gap (the data governance is
  nascent *because* the strategy work that would have built it is suspended).
- "I'll send you the names" may be deflection or may be genuine — track which.

Be careful here. Subtext reading can drift into paranoia. The discipline:
*entertain the political reading, don't assert it.* Hypothesise, flag
evidence for and against, don't state as fact.

Output: enriches [[Hypotheses register]] (the political-read entries) and
[[Risk register]] (where the subtext implies something could go wrong).

### 3. Project forward — "so what does this mean for the engagement?"

Step back from the meeting and ask what it implies for *your* work:

- **Scope traps** — what will you be pulled into despite D-002? What's the
  framing that will be used ("we need X for launch")?
- **Independence risks** — what timeline or crisis threatens to absorb your
  deliverable into someone else's quality problem?
- **Decision-vacuum exposure** — where are decisions being made by default
  that will become *your* decisions if they fail?
- **Boundary disputes** — where are scope boundaries unspoken that should be
  written?
- **Visibility/self-protection** — where are you exposed as the new arrival?

Output: enriches [[Engagement operating notes]] (the operating posture these
imply) and [[Risk register]] (the specific risks they surface).

### 4. Form/update hypotheses — "what should I track as I learn more?"

The hypotheses register ([[Hypotheses register]]) is the working-state layer.
On each pass:

- **Add** hypotheses the meeting seeded. Statement + confidence + evidence
  for/against + *confidence-changer* (what would meaningfully move it).
- **Update** existing hypotheses with new evidence; note the date alongside
  the new confidence.
- **Retire** hypotheses that have merged into a Decision (resolved) or been
  explicitly rejected (move to a Retired section with reasoning).

The distinction from questions: a *question* is something you ask one person
and they answer. A *hypothesis* is something no one will give you the answer
to — you assemble evidence and judge. The Bitwerx-has/hasn't disagreement is
the canonical hypothesis; you can't resolve it by asking, only by
investigating.

**Anchoring discipline:** when forming a hypothesis that points at the
conclusion of a Decision (e.g. "adapt is the right answer"), set the initial
confidence *below 0.5* to avoid anchoring on your own first instinct. The
number is a forcing function for honesty.

Output: enriches [[Hypotheses register]].

### 5. Advise — "what would the wise consultant say?"

The most valuable move, and the one most likely to be skipped because it's
the least structured. Step fully back and ask: *if I were advising myself
on this engagement, what would I say?*

Reach for the consultancycraft layer:

- **Sponsorship and political position** — do you have a champion? Where's
  the power?
- **Honest-broker positions** — where will your finding be politically
  consequential either way? How do you defend it? (Method, not conclusion.)
- **The single most important thing** — what's the load-bearing fact in this
  meeting, the one that changes everything else? (The fired director was
  that, in the Gerd meeting.)
- **What to do first** — the next concrete action the interpretation implies.
- **What to watch for** — early-warning signals that the read is right or
  wrong.

Speak directly here. This is the one place in the KB where the voice is
explicitly advisory, not factual. The four docs are the *artefact* of this
move; the move itself is the *thinking*.

Output: enriches [[Engagement operating notes]] (the posture, the
watch-fors) and [[Risk register]] (the explicitly political risks).

## Anti-patterns

- **Doing extraction again.** That was the first pass. If you find yourself
  listing named entities or restating what was said, you're in the wrong
  mode. Step back.
- **Asserting subtext as fact.** "Engineering is lying" is a claim;
  "engineering's position may be political — see H-002" is interpretation.
  The KB can be shared; write what you can defend.
- **Skipping the advise move** because it's the least structured. That's
  where the highest-value content lives.
- **Anchoring hypotheses on your first instinct.** Set conclusion-pointing
  hypotheses below 0.5 until evidence justifies raising them.
- **Running on every meeting.** Standups don't warrant it. The skill
  triggers on substantive meetings; resist the urge to over-apply.
- **Treating confidence numbers as measurements.** They're subjective
  estimates forcing honesty about how sure you are. Their value is tracking
  drift, not precision.

## The four docs (living state)

| Doc | Carries | Enriched by moves |
|---|---|---|
| [[Stakeholder assessment]] | stance, influence, approach per person | 2, 3, 5 |
| [[Engagement operating notes]] | posture, scope discipline, watch-fors | 3, 5 |
| [[Risk register]] | accumulated risks with severity/owner/mitigation | 2, 3 |
| [[Hypotheses register]] | working hypotheses with confidence + changers | 2, 4 |

All four are `status: living` and dated (`last-enriched`). Each pass's
contribution is a *delta* — not a new doc per meeting. Preserve prior
content; add to it; update confidences and severities with date noted.

## Verification

`kb lint` covers the structural integrity (links resolve, frontmatter
complete). Interpretation has no equivalent — the discipline is internal:

- Did I check anchoring on conclusion-pointing hypotheses?
- Did I distinguish subtext-reads (hypothesise) from subtext-claims (assert)?
- Did I do the advise move, or stop at risks?
- Did I run all five moves, or skip one because it was hard?

Commit when the four docs are updated and `kb lint` is clean (noting the
existing `kb` perf caveat — see br ticket if applicable).

## Related

- Engagement `KB STRUCTURE.md` — schema contract.
- [[meeting-to-kb]] — the paired extraction skill. Run that first.
- `kb` CLI — structural lint, used in verification.
