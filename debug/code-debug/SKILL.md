---
name: code-debug
description: >
  Investigate a persistent, hard-to-understand code bug using systematic
  root cause analysis. Use when a bug resists obvious fixes or repeated
  attempts have failed to resolve it.
---

## Overview

This skill drives a disciplined, evidence-first investigation of stubborn
code bugs. It generates competing hypotheses, actively falsifies them, and
drills to a verified root cause before any fix is proposed. The goal is
forward momentum — never repeating a failed approach, never assuming.

## Prerequisites

Before beginning, collect and state:
- The symptom (what happens vs. what is expected)
- Reproduction conditions (always / intermittent / environment-specific)
- What has already been tried and why it did not resolve the issue
- Any recent changes to code, dependencies, config, or infrastructure

If any of these are missing, ask for the single most important one before
proceeding.

## Workflow

- [ ] Step 1: **Restate the problem.** Confirm your understanding of the
  symptoms, scope, and reproduction conditions. Surface any ambiguities.

- [ ] Step 2: **Classify the bug type.** Identify which situation applies
  and apply the corresponding lens (see Key Rules below):
  - Intermittent / non-deterministic
  - Environment-specific ("works on my machine")
  - Race condition / concurrency
  - Regression (worked before, now broken)
  - Symptoms repeat despite attempted fixes

- [ ] Step 3: **Generate hypotheses.** Produce at least 4 competing
  theories. Do not anchor on the first plausible explanation. Each
  hypothesis must include:
  - Supporting evidence (what observations are consistent with it)
  - Contradicting evidence (what observations would rule it out)
  - A falsification test (a specific thing to check or run)

- [ ] Step 4: **Run change analysis.** Ask: what changed before or around
  the time this started? Scope: code, environment, dependencies, config,
  data shape, infrastructure, external services.

- [ ] Step 5: **Apply 5 Whys** to the leading hypothesis. Ask "why does
  that happen?" at least 5 levels deep. Stop only when you reach a cause
  with no further causal parent.

- [ ] Step 6: **Propose diagnostic steps.** List specific actions to
  gather evidence (logs, tests, probes, assertions). Do not propose fixes.

- [ ] Step 7: **State open questions.** Identify what information is still
  missing that would unlock the investigation.

- [ ] Step 8: **Verify root cause before fixing.** Only propose a fix once
  a hypothesis is confirmed by evidence. Clearly state: "Root cause
  confirmed: [X] because [evidence]."

## Key Rules

**Never repeat a failed approach.** If a strategy has been tried, state
why it failed to resolve the issue, then move to a genuinely different
angle.

**Demand evidence before concluding.** A hypothesis is not a conclusion.
Every candidate root cause must be testable and tested.

**Think laterally.** Explore causes outside the obvious layer:
timing/race conditions, caching, serialisation, encoding, locale,
floating-point precision, library version mismatches, platform-specific
behaviour, upstream data corruption, environment variable differences.

**Do not suggest a fix prematurely.** If the root cause is unconfirmed,
say so explicitly and propose the next diagnostic step instead.

**If information is missing, ask once.** Identify the single most
important missing piece of evidence and ask for it. Do not ask multiple
questions at once.

## Situation-Specific Lenses

Apply the relevant lens in Step 2 by adding these constraints to your
hypothesis generation:

**Intermittent bug**
Treat intermittency as a primary clue. Generate hypotheses specifically
about why the bug would *sometimes not occur* — timing windows, queue
depths, cache warm/cold states, thread scheduling, external service
latency.

**Works on my machine / environment-specific**
Enumerate every environmental difference between the working and failing
environments: OS, runtime version, env vars, file paths, locale, timezone,
available memory, network, secrets/config values.

**Race condition / concurrency**
Explicitly consider timing-dependent and non-deterministic causes: shared
mutable state, lock ordering, async callback ordering, event loop
starvation, thread pool exhaustion.

**Regression (previously worked)**
Focus change analysis on the diff between the last known-good state and
now. Check dependency bumps, config drift, schema changes, and data
migration side-effects before examining code changes.

## Output Format

Structure every response as follows:

```
## Problem Restatement
[Confirmed understanding of symptoms and scope]

## Bug Classification
[Which situation type; which lens applied]

## Hypotheses
### Hypothesis 1: [Name]
- Supporting evidence:
- Contradicting evidence:
- Falsification test:

[Repeat for each hypothesis — minimum 4]

## Change Analysis
[What changed before/around the time this started]

## 5 Whys (leading hypothesis)
- Why 1:
- Why 2:
- Why 3:
- Why 4:
- Why 5:

## Diagnostic Steps
[Specific commands, log queries, or tests to run — no fixes yet]

## Open Questions
[What information is still missing]
```

Do not produce a "Fix" section until root cause is confirmed with evidence.

## Gotchas

- The most common failure mode is confirming the *first* plausible
  hypothesis too early. Force at least 4 hypotheses before assessing
  likelihood.
- Intermittent bugs almost always have a timing or state-dependency cause.
  Never classify intermittency as "random" — treat it as a clue.
- "Works on my machine" bugs are almost never about the code logic itself.
  Start with environment, not code.
- Proposed fixes that reduce symptom frequency without eliminating them
  are not root cause fixes — they are noise suppression. Flag this
  explicitly.
- Do not conflate "the bug appeared after change X" with "change X caused
  the bug." Correlation requires verification.
