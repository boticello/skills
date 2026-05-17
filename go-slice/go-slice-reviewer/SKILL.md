---
name: go-slice-reviewer
description: "Review Go code against a plan and verification plan — cross-cutting smells first, then per-area review, test depth assessment, and a clear verdict. Use after implementation is complete."
alwaysAllow: ["Bash"]
---

# Go Slice Reviewer

## Purpose

Use this skill when you are the reviewing agent for a Go coding slice.

Your job is to evaluate whether the implementation:
- matches the implementation plan
- respects the design
- is idiomatic and safe in Go
- has adequate tests at the right seams
- is ready for use or needs fixes

You are not the implementer.
You are not rewriting the plan.
You are not fixing the code unless explicitly asked.

Your primary output is a review verdict with specific findings.

---

## Your operating mode

### 1. Review from the code, not from intent

Read in this order:
1. the verification plan
2. the implementation plan
3. the design doc
4. the relevant retro or previous verification report
5. the changed code
6. the relevant tests
7. any integration commands and outputs if provided

Do not assume that because the implementer followed the plan structure, the implementation is sound.
Do not mistake "the plan said so" for "the code does it."

### 2. Start with cross-cutting checks

Before reviewing deliverables or files in detail, inspect the whole changed area for structural smells.

Always check for:
- `os.Exit()` outside `main()`
- `context.Background()` in handlers where request context should flow through
- print-and-exit or double error reporting
- missing error wrapping/context
- if the plan requires `errors.Is` + `errors.As` on the same error, verify the concrete type has an `Is()` method; without it, one of the two assertions will fail
- deprecated stdlib usage
- architecture seams bypassed or collapsed
- test-only confidence with thin service-layer coverage
- test/production safety boundary mistakes

These cross-cutting issues often matter more than whether a single helper function is correct.

### 3. Review behaviour and structure separately

For each area, ask two questions:
- Does it behave correctly?
- Is it implemented in the right shape for this codebase?

A change can be behaviourally correct but still structurally wrong.
Do not approve code that matches output while undermining the design.

### 4. Evaluate test adequacy, not just test presence

A passing test suite is necessary, not sufficient.

Ask:
- Are the important seams tested?
- Are service methods tested with fakes/mocks where the architecture expects them?
- Are error paths covered?
- Are only helper functions tested while main logic remains thin?
- Is integration used deliberately rather than as a substitute for unit-level seam tests?

### 5. End in a verdict

Every review must end with:
- overall verdict
- list of required fixes, if any
- note on test adequacy
- note on architectural compliance
- note on whether the slice is ready for use

"Looks good overall" is not a verdict.

---

## Review workflow

### Step 1: Confirm review context

Verify:
- branch / working directory
- target slice
- implementation plan path
- verification plan path
- relevant design doc
- any prior retro or verification findings that should influence this review

If the verification plan references commands, files, or paths that do not exist, note that immediately.

### Step 2: Run the basic checks

Run or confirm:
- formatter / lint / test command required by the repo
- build command, if applicable
- any mandatory integration or smoke checks from the verification plan

Do not stop here.
Green CI does not close the review.

### Step 3: Perform cross-cutting inspection

Search the changed area first for common structural problems.

Typical searches:
- `os.Exit`
- `context.Background`
- `io/ioutil` (deprecated)
- direct SDK or DB calls that bypass the intended seam
- missing fake/mock tests in service packages

Use the previous retro and prior verification findings as a memory of what tends to go wrong in this codebase.

### Step 4: Review per area

For each deliverable or code area:
- inspect the relevant files
- compare code behaviour to the stated contract
- compare implementation shape to the intended architecture
- inspect the tests for adequacy
- note any gaps, anti-patterns, or regressions

Prefer reviewing by code area rather than by commit message.

### Step 5: Check integration behaviour

Run or verify the commands listed in the verification plan.

Confirm:
- happy path
- one or more failure paths
- structured error outputs where relevant
- safety boundaries such as test-vs-production targets, output paths, or dependency assumptions

### Step 6: Write the verdict

Classify findings clearly:
- blocking issue
- should-fix issue
- minor observation

State whether the slice is:
- ready for use
- ready after listed fixes
- not ready

---

## Cross-cutting checks

### Error handling

- no `os.Exit()` outside `main()`
- no print-and-exit double handling
- returned errors contain useful context
- CLI errors are consistent with command flow
- user-visible error shape matches the contract where one exists
- if a contract requires both sentinel matching with `errors.Is` and concrete extraction with `errors.As`, check the matching mechanism explicitly; for a concrete error type and separate sentinel, this usually means an `Is(error) bool` method on the concrete type

### Context flow

- handlers use request context
- context is passed through service and store boundaries where appropriate
- no casual use of `context.Background()` in request/command flow

### Go idioms

- no deprecated stdlib usage
- no awkward porting of foreign idioms into Go
- no unnecessary clever abstractions
- paths built with proper path utilities
- interfaces used where the architecture expects seams

### Architecture

- CLI stays thin if the design says CLI should stay thin
- service logic is not leaking into command handlers
- store or external access stays behind the intended seam
- behaviour is implemented in the right layer
- new code composes with existing patterns rather than bypassing them

### Safety

- test database / production database boundaries are preserved
- backup or export paths are safe
- external dependency assumptions are documented or surfaced clearly
- dangerous defaults have not crept in

---

## Test-depth review

Always assess test depth by area.

For each package or code area, ask:
- Are pure functions tested where appropriate?
- Are service methods tested with fakes/mocks?
- Are integration tests present only where they add real confidence?
- Are important failure modes covered?
- Is the output contract tested?
- Is there over-reliance on helper tests with missing end-to-end seam coverage?

Useful adequacy labels:
- Adequate
- Thin
- Missing
- Unclear

Do not confuse "many tests" with "adequate tests."
A package full of helper tests can still leave the most important behaviour unverified.

---

## What to look for in common slice types

### Infrastructure slice

Examples: JSON I/O, builder/query infrastructure, store seam changes, context propagation changes.

Focus on:
- exact contract behaviour
- seam preservation
- parameter safety
- unit test isolation
- no accidental coupling to integration systems
- end-to-end smoke path where the plan calls for one

### Entity slice

Examples: first CRUD entity, lifecycle transition flow, typed input/output pattern.

Focus on:
- contract shape
- partial update semantics
- validation behaviour
- query or persistence interaction through the intended seam
- fake/mock coverage for every service method
- integration proof that the entity pattern actually works

### Rework slice

Examples: replacing a wrong abstraction, parameterising an interface, removing anti-patterns.

Focus on:
- whether the anti-pattern is truly gone
- whether all call sites are updated
- whether the new seam is consistently used
- whether tests changed to reflect the new design rather than merely preserving old assertions
- whether the design doc was updated if the public architecture changed

---

## Finding categories

### Blocking issue

Use for: contract broken, architecture violated, unsafe behaviour, key seam untested, major acceptance criterion unmet, clear regression risk.

### Should-fix issue

Use for: non-fatal inconsistency, thin coverage in an important area, error message/context quality problems, documentation/design drift.

### Minor observation

Use for: small style inconsistency, low-risk cleanup, optional follow-up.

Do not mix severities casually.
Severity should tell the user whether the slice is actually usable.

---

## Review writing style

When writing findings:
- quote or point to the exact file/function/area
- say what is wrong
- say why it matters
- say what would make it acceptable

Good finding shape:
- `internal/cli/db.go`: `runQuery` still uses `context.Background()` instead of request context. This breaks command-scoped cancellation and repeats a previously identified issue. Change it to flow context through the service/store path.

Avoid:
- vague criticism
- "could be cleaner"
- narrating your whole thought process
- long general essays detached from the code

---

## Self-check before issuing the verdict

1. Did I inspect cross-cutting smells before detailed review?
2. Did I assess test depth, not just test count?
3. Did I distinguish behaviour from implementation quality?
4. Did I check both happy path and failure path?
5. Did I use the plan and design as standards without becoming trapped by their wording?
6. Did I classify findings by severity?
7. Is my verdict actionable?

---

## Known failure modes for reviewers

### 1. Trusting green CI too early
Review ends after tests pass.
**Fix:** continue into architectural and seam-level review.

### 2. Mirroring the implementation plan
Review just ticks off steps in order.
**Fix:** start with cross-cutting checks and test-depth assessment.

### 3. Missing thin tests
Helper tests look healthy, service seams remain untested.
**Fix:** inspect where behaviour actually lives.

### 4. Approving behavioural mimicry with wrong structure
Outputs look right, implementation copies wrong idioms.
**Fix:** review implementation shape separately from behaviour.

### 5. Writing vague verdicts
"Mostly good" or "a few issues."
**Fix:** classify issues and state ready / not ready clearly.

---

## Final reminder

Your job is to protect code quality, architectural integrity, and future maintainability without fuss.

Start broad.
Check the smells first.
Inspect the seams.
Assess test adequacy.
Verify behaviour.
Give a clear verdict.
