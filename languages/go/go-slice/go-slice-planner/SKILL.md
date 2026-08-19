---
name: go-slice-planner
description: "Write implementation plans and verification plans for Go coding slices. Defines slice shape, contracts, gates, and test depth expectations. Use when a slice boundary is clear enough to plan."
alwaysAllow: ["Bash"]
---

# Go Slice Planner

## Purpose

Use this skill when you are asked to produce planning documents for a Go coding slice or spike.

Your job is to produce documents that help other agents do good work with structure, context, and clear verification, without writing the code for them.

This skill covers:
- implementation plans
- verification plans
- the relationship between the two

It does **not** cover:
- writing the implementation itself
- writing handoff documents for the implementer
- doing the code review itself

---

## Core idea

A good plan gives the implementer:
- a clear slice of work
- the source material to read
- behavioural contracts to satisfy
- gates to stop drift
- enough freedom to think

A good verification plan gives the reviewer:
- the key cross-cutting smells to inspect first
- the code areas to examine
- test depth expectations
- integration checks
- a way to reach a clear verdict

The implementation plan is for the implementer.
The verification plan is for the reviewer.

They should be written together, but they are **not** mirrors of each other.

---

## Planning principles

### 1. One slice proves one coherent thing

A slice should prove one architectural or behavioural point.

Good:
- "JSON I/O contract works end-to-end"
- "First entity pattern works with typed input, service layer, and CLI wiring"
- "Query builder can express the needed structure safely"

Bad:
- "Add three entities, refactor the builder, update the schema, and improve UX"

If "What this proves" grows beyond about 3–4 items, the slice is probably too large.

### 2. Point to source truth

Do not replace source reading with plan prose.

Prefer:
- file paths
- required reading lists
- one short note on why each source matters

Avoid:
- long summaries of existing files
- re-explaining the whole design inside the plan

When behaviour must match an existing implementation, point to the source file that defines it.

### 3. Specify contracts, not code

Define:
- inputs
- outputs
- behavioural rules
- success criteria

Do **not** define:
- detailed function signatures unless already fixed public contract
- implementation pseudo-code
- large code blocks
- exact test assertion bodies

The planner must guide the implementer, not pre-empt them.

### 4. Use gates and commit boundaries

Each meaningful step should end with a gate.

A gate should be something the implementer can actually check:
- `go test ./...` green
- specific tests pass
- a command produces a defined result
- a documented acceptance criterion is visibly satisfied

Prefer short, strong gates over long prose.

### 5. Test depth must be explicit

"Tests pass" is not enough.

For each meaningful area, state minimum expected test depth:
- pure function tests
- fake/mock seam tests
- integration tests where appropriate

This matters especially for service-layer behaviour and testable seams (storage interfaces, command executors, service boundaries).

If the plan does not specify ordering for a collection field, tests should use set comparison, not index access. If ordering matters, pin it explicitly in the plan.

### 6. Include a review stage

An implementation plan should include a review stage before declaring the slice done.

The review stage should look for:
- `os.Exit` outside `main()`
- `context.Background()` in handlers where request context should be used
- print-and-exit instead of returning errors
- missing error wrapping/context
- thin tests
- deprecated stdlib usage
- architecture drift from the design

### 7. Separate behaviour from implementation copying

If replacing code from another language or system, match:
- output
- flags
- input precedence
- data shape
- behavioural semantics

Do **not** copy:
- foreign exit patterns
- foreign string-building habits
- implementation idioms that are wrong in Go

### 8. Use explicit non-goals

Every plan should say what it does **not** do.

This prevents scope creep and helps the implementer avoid "while I'm here" behaviour.

---

## Writing an implementation plan

### Goal

Produce a plan that allows an implementer to work in a disciplined way while still reasoning from the codebase and source files.

### Structure

Use the plan template in this skill's `templates/` directory.

The plan should typically contain:
- title
- what this proves
- prerequisites / required reading
- deliverables or steps
- per-step gates
- acceptance criteria
- what this does not do

### What to include

#### What this proves
Keep this short and structural.

#### Required reading
List exact files and one short reason for each.

Good:
- `[design doc path]` — target architecture
- `[Go skill path]` — local Go idioms and done criteria
- `[seam file path]` — existing storage seam

#### Deliverables / steps
For each step or deliverable, define:
- contract (input, output, behaviour)
- relevant source files to read
- gate

Where possible, define contracts using:
- JSON examples
- command examples
- field shape examples
- behavioural bullet points

#### Acceptance criteria
Use a table. Each criterion should have a verification method.

#### Previous-slice input status
Include a short table for prior artefacts the planner was asked to read. Record whether each previous retro or verification finding was read, absent, or not applicable, and what lesson was applied.

#### Gate reproducibility
Include a standing gate reproducibility section. For each required gate, state the command, expected runner, and evidence the implementer should capture so review can verify the claim even if a reviewer cannot rerun commands.

#### Error-type deliverables
When the plan requires both `errors.Is(err, Sentinel)` and `errors.As(err, *Concrete)`, state the mechanism: a custom `Is(error) bool` method on the concrete type that matches the sentinel. Do not leave this for the implementer to discover.

#### Non-goals
List explicit exclusions.

### What not to include

- long pseudo-code blocks
- near-complete Go functions
- test bodies with assertions written out in detail
- large architecture digressions
- a step that is really just "do everything else"

### Good implementation-plan checks

Before finalising, ask:
1. Am I writing a plan, or secretly writing the implementation?
2. Does the implementer still need to read the source files?
3. Is each step small enough to gate and commit cleanly?
4. Are the acceptance criteria actually checkable?
5. Have I stated enough test depth?
6. Have I included a review stage?
7. Have I kept scope tight?

---

## Writing a verification plan

### Goal

Produce a plan that helps a reviewer evaluate the implementation after coding is complete.

This is a **review** document, not an implementation transcript.

### Structure

Use the verification-plan template in this skill's `templates/` directory.

### The most important rule

Do **not** mirror the implementation plan step-for-step unless that is genuinely the clearest review structure.

The reviewer's job is different from the implementer's.

### What to include

#### Cross-cutting checks first
Put the highest-value smells first, before per-deliverable review.

Typical cross-cutting checks:
- no `os.Exit` outside `main()`
- no `context.Background()` in handlers where request context should flow through
- no print-and-exit dual handling
- errors include context
- deprecated stdlib not used
- external dependency assumptions documented
- production/test safety boundaries maintained
- architecture seams still respected

Seed these checks from the previous retro and previous verification findings.

#### Per-area review
For each area, tell the reviewer:
- which files to inspect
- what contract or behaviour to check
- what tests should exist
- what specific gaps would count as thin coverage

#### Test depth assessment
Include a table with target adequacy by package or area.

Useful columns:
- package/area
- pure function tests
- fake/mock seam tests
- integration tests
- assessment/expectation

#### Integration verification
Use concrete commands with expected results.

#### Verdict
End with a verdict section:
- implementation matches the plan or not
- tests are adequate or not
- cross-cutting smells present or not
- ready for use / needs fixes
- list of fix categories

### What not to include

- implementation pseudo-code
- a reworded version of the implementation plan
- giant checkbox forests that can be ticked without reading code
- only happy-path checks
- vague statements like "verify tests are good"

---

## Workflow for the planner

When asked to produce both documents:

1. Read the design doc and relevant source files.
2. Read the previous retro and any prior verification reports.
3. Draft the implementation plan first.
4. Check the implementation plan for overspecification.
5. Draft the verification plan second.
6. Ensure the verification plan tests the implementation plan's claims without merely copying its structure.
7. Check both for consistency:
   - every important claim in the implementation plan is verifiable
   - the verification plan has independent reviewer value
   - test depth expectations are visible in both

---

## Known failure modes to avoid

### Overspecified plan
Symptoms: long code blocks, exact function signatures everywhere, test assertions written for the implementer.
Why bad: removes room for reasoning, encourages transcription.

### Underspecified plan
Symptoms: "implement X", "tests pass", no source reading, no review stage.
Why bad: implementer guesses, thin tests pass unnoticed.

### Mirrored verification plan
Symptoms: same structure as the implementation plan, every step copied into review checkboxes.
Why bad: reviewer can tick without really reviewing, cross-cutting smells get buried.

### Behaviour/implementation confusion
Symptoms: "match [old system]" interpreted as "implement like [old system]".
Why bad: behaviourally compatible but structurally wrong.

---

## Output style

- be concise
- prefer bullets and tables to long prose
- keep headings plain and functional
- use examples only where they define a contract
- keep sections tight
- make every line earn its place

---

## Final reminder

Your role is not to remove all ambiguity.

Your role is to remove the **wrong** ambiguity:
- unclear scope
- missing sources
- vague done criteria
- invisible test expectations
- absent review criteria

Leave the **right** ambiguity in place:
- implementation judgement
- code shape within the architectural contract
- how the implementer reasons from the source material
