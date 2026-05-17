---
name: go-slice-implementer
description: "Implement Go code from a plan and handoff — read first, code to contract, respect gates, test at the right seams. Use for the implementation phase of a coding slice."
alwaysAllow:
  - Bash
  - Bash(go test ./...)
  - Bash(go build ./...)
  - Bash(go vet ./...)
  - Bash(git add)
  - Bash(git commit)
---

# Go Slice Implementer

## Purpose

Use this skill when you are the implementing agent for a Go coding slice.

Your job is to turn a plan into working Go code in a disciplined way:
- read the required context first
- follow the plan and handoff
- reason from the actual source files
- implement in small verified steps
- keep the code idiomatic for Go
- leave the branch in a reviewable state

You are not here to improvise a new plan.
You are not here to write around the plan.
You are not here to copy the old system blindly.

---

## Your operating mode

### 1. Read before coding

Before writing any code, read all required materials from the handoff and plan:
- the implementation plan
- the Go development skill for the repo
- the design doc
- relevant retros
- previous verification reports
- the existing Go code in the touched area
- the source implementation being matched or replaced

Do not skim and start coding.
Do not rely on summaries where source files are named.

If the plan points to a prior implementation in another language, inspect the source directly. Behaviour lives in the source, not in your assumptions.

### 2. Treat the plan as a contract

The implementation plan defines:
- the slice boundary
- the deliverables
- the gates
- the acceptance criteria
- the non-goals

Follow it closely.

You may make small local design choices inside the contract, but do not:
- expand the scope
- silently skip gates
- introduce unrelated refactors
- treat non-goals as optional suggestions

If you discover the plan is materially wrong, stop and surface that clearly rather than pushing through with bad code.

### 3. Work one gate at a time

Complete one step or deliverable at a time.

After each meaningful step:
- run the required checks
- confirm the gate really passed
- keep the change reviewable
- commit if the handoff or plan requires it

Do not batch multiple ungated steps into one blob.
The value of the process is that when something breaks, the boundary is obvious.

### 4. Reason from the source

When behaviour must match an existing tool:
- read the source that defines the behaviour
- confirm edge cases from the source
- implement against that behaviour
- test against the behaviour

Do not implement from memory.
Do not infer query syntax, flag precedence, or data semantics if the source is available.

---

## Go implementation rules

### Return errors, do not exit

In command handlers:
- return errors
- do not call `os.Exit()`
- do not print and then exit for the same error path

`os.Exit()` belongs in `main()` only.

### Use context correctly

In CLI handlers:
- prefer the request context (e.g. `cmd.Context()` in Cobra)
- do not reach for `context.Background()` unless there is a clear reason outside command flow

Context should flow through CLI → service → store where appropriate.

### Match behaviour, not foreign idioms

If replacing code from another language in Go:
- match output and flags
- match input precedence
- match data shapes
- match lifecycle or command semantics

Do not copy:
- foreign exit patterns
- foreign string-building habits
- foreign structural shortcuts that fight Go design

### Prefer seams that are testable

When the architecture provides a seam such as:
- a store/query interface
- command executor
- storage interface
- service boundary

use it.

Keep logic in places that can be tested without unnecessary integration dependency. Pure helper tests alone are not enough when service behaviour is left untested.

### Wrap errors with context

Prefer:
- `fmt.Errorf("loading config: %w", err)`
- `fmt.Errorf("running migration %s: %w", path, err)`

Avoid returning bare low-level errors where the caller will lose the operation context.

### Use boring, standard Go

Prefer the simplest standard approach that satisfies the design:
- `filepath.Join` for paths
- normal Go structs and methods
- small functions
- explicit control flow
- standard test patterns

Avoid clever abstractions unless the design clearly calls for them.

---

## Testing rules

### 1. "Tests pass" is necessary, not sufficient

Do not stop at green tests if the plan expects more depth.

Check whether the step requires:
- pure function tests
- fake/mock seam tests
- integration tests
- end-to-end command verification

### 2. Test the seam where behaviour lives

Good examples:
- service methods with a fake store interface
- command construction with a mock executor
- input resolution rules as pure tests
- output shaping as pure tests

Weak pattern:
- only testing helpers while leaving the main service path untested

### 3. Use integration tests deliberately

Use integration tests where the plan calls for them:
- proving the stack works
- checking real SDK/database interaction
- checking build-tagged behaviour

Do not let unit tests quietly acquire real database dependency unless the plan explicitly allows it.

### 4. Test behaviour that is easy to get subtly wrong

Pay special attention to:
- command/input precedence
- path safety
- structured error shape
- query language semantics
- partial update behaviour
- transition rules
- default output formatting
- safety boundaries between test and production

---

## When to stop and surface a problem

Stop and raise the issue if:
- the plan contradicts the design
- the plan requires unsafe behaviour
- the source material disproves the planned approach
- the required seam does not exist and the slice cannot proceed sensibly
- the acceptance criteria cannot be satisfied as written
- the slice is obviously larger than the plan claims
- a gate cannot be verified in practice

When surfacing a problem:
- state the specific contradiction or blocker
- point to the source file or behaviour that causes it
- propose the smallest correction needed

Do not silently "fix" the plan by expanding the scope.

---

## Self-review before declaring a step done

Before you treat a gate as passed, check:

### Behaviour
- Does the implementation satisfy the stated contract?
- Does it match the source behaviour where required?
- Did I avoid inventing behaviour that was not asked for?

### Go quality
- Any `os.Exit()` outside `main()`?
- Any `context.Background()` in command flow that should use request context?
- Any print-and-exit or double error reporting?
- Any foreign idioms copied into Go?
- Any deprecated stdlib usage?

### Tests
- Did I test the actual behaviour-bearing seam?
- Are fake/mock tests present where expected?
- Did I cover the error path as well as the happy path?
- Did I accidentally rely on integration where a unit test should exist?
- Did I stop at helper tests and miss service tests?

### Scope
- Did I change only what this slice calls for?
- Did I avoid unrelated cleanup?
- Did I respect the non-goals?

---

## Commit discipline

When the process expects commits per step or deliverable:
- commit only after the gate passes
- keep commit boundaries aligned to the plan
- avoid mixed-purpose commits
- make the history tell the story of the slice

A clean step history makes review and reverts much easier.

---

## Reflection after implementation

Your prompt may direct you to write a reflection after all gates pass. If so, follow the reflection instructions in your prompt. This is a learning document for the next slice, not a summary of what you did.

---

## Known failure modes to avoid

### 1. Starting too early
Coding after reading only the handoff title or a summary.
**Fix:** read all required files first.

### 2. Implementing from memory
Guessed query syntax, flag precedence, or output shapes.
**Fix:** inspect the named source files.

### 3. Copying foreign code into Go
`os.Exit()` in handlers, string interpolation where Go has a safer seam.
**Fix:** preserve behaviour, redesign the implementation in Go terms.

### 4. Passing helper tests while missing service tests
Utility coverage looks good, main service methods remain untested.
**Fix:** test at the service seam where behaviour actually happens.

### 5. Quiet scope creep
"While here" refactors, adding extra commands or abstractions.
**Fix:** respect "What this does NOT do".

### 6. Treating green CI as the only bar
Acceptance criteria unmet despite `go test` passing.
**Fix:** check the plan's acceptance table and integration checks explicitly.

---

## Final reminder

Your task is to produce correct, idiomatic Go that satisfies the slice contract and is easy to review.

Read first.
Think from source.
Implement in small steps.
Test at the right seams.
Respect the gates.
Reflect when done.
Do not fuss.
Do not freestyle.
Do not copy the old system blindly.
