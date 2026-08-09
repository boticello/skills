---
name: stance-check
description: >-
  Use when an early-warning signal fires — you're accumulating without
  shipping, about to deliver a definitive answer to an open question,
  automating something with consequences, or otherwise working hard in a
  stance that may be wrong for the task's current phase. Not for trivial
  tasks. Forces a named stance check against a library of corrective
  postures. For the full posture definitions, read the library:
  ~/Me/scratch/extract-ideas/postures.md
---

# stance-check

Most agent errors are **stance errors**, not object errors. You're
working hard, but in the wrong mode for the phase the task is in.
The stance feels like "just working" from inside it — so the
correction has to come from outside the flow.

This skill is that outside disruption.

## When to fire

You (the agent) are in one of these states:

- **Expanding without shipping** — second abstraction layer, still
  no core feature shipped
- **About to close something prematurely** — definitive answer to
  a question that was actually an invitation to think
- **Automating with consequences** — about to make a decision for
  the user, or wire up automation that touches irreversible state
- **Repeating the same action** — re-read the same file / re-ran
  the same diagnostic, hoping for new information
- **Treating every decision as equal** — spending the same
  deliberation on a one-line config change as on an architectural
  commitment

These are early-warning signals, not the postures themselves. They
tell you a stance correction is needed; the library tells you which
one.

## The procedure

1. **Name the stance you're in** — one gerund phrase ("expanding",
   "concluding", "automating", "re-reading"). Not the stance you
   want to be in — the one you're actually in.
2. **Find its correction** in the table below.
3. **Apply both halves**: diagnose on the axis, then act on the
   same axis.

Step 1 is the whole game. Once you've named the stance, the
correction usually follows. Don't skip to step 3.

## The posture dispatch

| Signal / stance you're in | Diagnose with | Act with |
|---|---|---|
| Expanding, nothing shipping | `watch-the-scope-line` | `compress-on-purpose` |
| About to close an open question | (none — this is a single act) | `resist-closure` |
| Spending equal care on every decision | `weight-by-reversibility` | `decide-the-reversible-fast` |
| About to build general framework from one case | (none) | `defer-the-abstraction` |
| Deferral has gone on long, special cases accumulating | (none) | `commit-when-pain-exceeds-lockin` |
| About to automate something with consequences | `validate-as-dialogue` | `automate-the-reversible-spine` |
| Stuck re-reading the same thing | (none — this is a single act) | `alternate-modes` |
| Plan addresses what was said, nothing missing | (none) | `read-for-gaps` |

Entries marked "(none)" are postures without a diagnostic
half — they're corrections applied directly to the named stance.

## The library

For full posture definitions (object / move / product / corrects /
over-correction / complement / source), read:

```
~/Me/scratch/extract-ideas/postures.md
```

This skill is the **interface** — what fires in the moment. The
library is the **reference** — what you consult when the compressed
form here isn't enough. Don't duplicate the library into this skill;
it would drift and grow.

## Anti-pattern: applying a posture harder

Every posture has an **over-correction** — the failure mode of
applying it too aggressively. `compress-on-purpose` over-corrects
into premature shutdown of legitimate expansion. `resist-closure`
over-corrects into never committing when an answer is actually
wanted.

If you feel the urge to apply a posture *harder*, stop and check:
are you still correcting a real default, or are you now defending
the posture as a virtue? Postures are corrections, not virtues.
Applying any of them harder is not automatically better.

This is the reflexive check: the practice must apply to itself.

## When NOT to use this skill

- **Trivial tasks.** Naming your stance on a one-line fix is
  overhead, not wisdom.
- **Tasks with an obvious next step.** If the next action is clear
  and the work is progressing, don't interrupt it for a stance
  check.
- **When the user has just asked a direct question.** Don't make
  them wait while you "check your stance" — answer, then notice.

The skill earns its keep on long, ambiguous, or stalled work. On
short clear work it's noise.

## Complement: the `/stance` command

This skill has a manual counterpart: the `/stance` slash command
(`~/Me/repos/prompts/commands/stance.md`). They share the library
but do different jobs:

- **Skill** (this) tests **precision** — does the trigger fire at
  the right moment? Auto-loads, commits to a posture, applies the
  correction, done.
- **Command** (`/stance`) tests **recall** — does the library cover
  the stance space? User-initiated, can refuse to commit, surfaces
  no-match as a candidate posture for the library.

The skill closes (matches, corrects, done). The command can stay
open (no match → describe → candidate). They embody the two bookend
postures of the library operating on the library.
