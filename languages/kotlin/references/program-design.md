# Kotlin program design

## Overview

> Typed primitives for every domain concept, a pure model that cannot hold
> nonsense, deliberate construction that records itself, and verification that
> re-derives the result independently — with effects at the edges.

The Kotlin programs this guide governs represent a domain: a fixed subject
area whose rules matter outside the code — a specification, a catalogue, a
business process. The program is the reference implementation of that subject
matter. When the code and the domain disagree, the program must make the
disagreement detectable.

Qualities, in priority order:

- **Conceptually clear** — the code reads like the domain's own description;
  a reader who knows the subject navigates the source by concept names.
- **Reliable** — deterministic, reproducible, auditable: the same inputs give
  the same outputs, and the program can account for how it produced them.
- **Robust** — invalid states are unrepresentable where possible, and failure
  is typed and diagnosable where it is a domain outcome.
- **Typed** — the type system carries domain distinctions, not storage shapes.

The design approach is domain-driven design, applied proportionately:

| DDD concept | Kotlin realisation |
| --- | --- |
| Ubiquitous language | names taken verbatim from the domain's glossary and documents; file headers cite the authoritative source |
| Value object | `@JvmInline value class` with a validating `init` block |
| Entity / aggregate | immutable data classes carrying invariants, built once and frozen |
| Domain service | pure predicates and calculations over the model |
| Specification | named, independently runnable checks |
| Anti-corruption / boundary | parse-once adapters, an interop facade, serialisation DTOs |
| Domain event / audit | a log of how each artefact came to exist |

Absent by design: repositories, containers, framework plumbing, and any
abstraction introduced for a pattern's sake rather than a felt need.

## A useful program shape

Convert external data into typed primitives once, at the boundary. Keep every
rule pure and re-derivable in the middle. Construct artefacts in recorded
stages. Verify the finished artefact against the rules again, from scratch.
Write files, call tools, and expose interop only at the edges.

```
Domain language (glossary, specification, correspondence — outside the code)
        ↓ codified once, in types
Domain primitives        value classes that cannot hold nonsense
        ↓
Domain model             immutable records carrying invariants
        ↓
Domain services          the rules as pure predicates and calculations
        ↓
The contract             every externally fixed bound as a typed constant
        ↓
Application pipeline     staged construction, each step recorded
        ↓
Infrastructure           solvers, export, interop — tools at the edges
        ↓
Verification and CLI     independent re-checking, reporting, entry point
```

Consequences of this shape:

- Most of the code is pure functions over typed values — exercisable from a
  REPL, pinnable by tests without fixtures or mocks.
- The shell is small enough to read in one sitting: parse arguments, run the
  pipeline, export artefacts, report.
- Construction is a recorded plan: each stage labels what it placed, and the
  verification report is the proof the plan was followed.

## Principles

Apply proportionally: a disposable spike needs typed primitives and little
else; a maintained tool adds the contract and tests; a system of record needs
everything here plus decision records and a cross-language facade.

### 1. Speak the domain's language in the code

Use the domain's own vocabulary verbatim — its nouns for types, its verbs for
functions — so a change in the domain maps onto an obvious change in the
code and a reviewer can check code against the specification line by line.

The strongest form turns a domain distinction into a type distinction. If the
domain says a rule depends only on a value while another depends on where the
value sits, model them as two sealed hierarchies with no shared supertype:
the compiler then refuses the crossed question. A sentence in the
specification becomes a class of impossible bugs.

Convention: each source file opens with a comment naming the domain concept
it embodies and the document that is authoritative for it.

### 2. Make invalid states unrepresentable

The workhorse is a value class with a validating constructor:

```kotlin
@JvmInline
value class Quantity(val value: Int) : Comparable<Quantity> {
    init { require(value in MIN..MAX) { "quantity must be $MIN..$MAX, got $value" } }
}
```

A `Quantity` can only be constructed in range, so every function taking one
is free of range checks — the check is paid once, at the type boundary. Give
each domain scalar this treatment. Let nullability carry domain facts the
same way: return `null` for the predecessor of a first element because the
absence is real, not exceptional.

Make closed sets sealed so `when` over them is exhaustive; adding a case
then makes the compiler list every dispatch that must be extended.

Classify failures:

- `require(...)` — invalid argument at a boundary; expected.
- `check(...)` — violated precondition in a verified hot path; a bug if it
  fires.
- `error(...)` — unreachable by construction; a bug if it fires.
- A sealed `Ok`/`Err` outcome with typed errors — where failure is a domain
  outcome the caller must branch on. Reserve exceptions for the shell and
  adapter edges.

Every check the types make unnecessary is a test you don't write and a
defect class that stops existing.

### 3. Codify the contract once, in types

Every number an external authority fixes becomes a named, typed constant in
one contract file, and every part of the program that obeys it reads that
constant. No magic numbers inside logic; never two files each carrying their
own copy of a bound.

The contract file carries provenance for each value: fixed by the
specification; a software choice with a recorded instance; or an open
decision, flagged with the question that owns it. The first and the second
look identical as bare literals — as documented constants they are
auditable, and re-rolling a recorded choice is visibly a different act from
changing a fixed bound.

One machine-checkable contract turns "is the implementation consistent with
the requirements?" into a review of one file, plus tests that pin the
constants against re-derived arithmetic.

### 4. Keep the domain pure; effects at the edges

Files, network, clocks, randomness, and interop live in adapters and the
entry point. The model and its services are deterministic functions of their
arguments. Randomness is not eliminated but injected and recorded: the
pipeline takes a seed, and each run writes its configuration — seed, rule
order, choices — alongside its outputs, so the artefact can be re-derived.

The payoffs are concrete: a REPL can sit over the compiled domain and answer
questions the pipeline never anticipated; tests need no fixtures or mocks —
assert the expected value and you are done; and any result can be reproduced
from the recorded configuration alone.

### 5. Recompute, don't store

Where a derivable quantity and a stored copy of it could coexist, derive it.
A stored copy is a second source of truth, and two sources drift. Stored
baselines are legitimate only as checks on the recomputation, never as inputs
to it.

When recomputation has a real cost, memoise the pure function and record the
cost and the measurement in a comment at the cache. A cache over a pure
function is safe because the function is pure; the comment lets the next
reader re-judge it.

### 6. Construct deliberately; verify independently

Keep the program that builds an artefact separate from the program that
checks it, even when they share a codebase: the verifier re-derives its
verdict from the artefact and the contract alone, without the builder's help.

- **Intent records.** Some construction facts are not observable in the
  finished artefact. The builder writes them into a record; the verifier
  re-checks every recorded claim against the artefact. The record is
  testimony, not evidence.
- **Audit logs.** Every construction step appends a row — order, target,
  value, stage — exported with the artefact, so questions about the artefact
  are answered by reading the log, not by re-running the pipeline.
- **Checks that bite.** Each verifier check must fail on an artefact that
  violates it, naming what and where. A check that passes vacuously is worse
  than no check.

Builder/verifier drift is the standing failure mode of this kind of program.
The two defences are structural: shared contract constants, so the two
cannot disagree about the rules, and independent re-derivation, so the
checker does not share the builder's blind spots.

### 7. Decide immutability by measurement, not ideology

Start immutable and pure. When profiling shows a real cost, localise a
measured escape rather than abandoning immutability: a mutable builder for
the construction phase, frozen once into the immutable value that crosses
every boundary; a cache over a hot pure function; arrays instead of lists in
a measured hot spot.

Record the measurement in a comment where the optimisation lives, so the
next reader knows it is still justified and can re-measure it.

### 8. Model choices and decisions as data

Separate what the domain fixes from what the software chose. Hold the choice
variables as named values with recorded instances; require a re-roll to
record its seed and candidate order. Write each run's configuration to an
artefact, not to tribal knowledge.

Architectural decisions get the same treatment one level up: a one-page
decision record — options considered, decision, what would change it —
committed beside the code it governs.

### 9. Guard the boundaries

Everything crossing into the program from another language or system passes
one narrow, named surface:

- **Parse once, at the edge.** Validation happens at construction of the
  typed primitive; everything downstream is check-free.
- **One interop facade.** Value classes name-mangle their JVM signatures,
  which foreign callers cannot reach. The facade gives exported functions
  stable `@JvmName`s and raw signatures that absorb boxing. It wraps existing
  domain functions and never reimplements them: one surface, no duplicated
  logic.
- **Serialisation is an adapter.** DTOs live at the boundary; the domain
  model is never shaped for the serialiser's convenience. Exports use
  deterministic field order — the artefact is a contract.

## Program structure

Projects are built with the Kotlin Toolchain (`kotlin init`, a checked-in
wrapper, declarative `module.yaml`) rather than Gradle. A domain program
keeps this shape:

```
kotlin/
├── kotlin, kotlin.bat        # pinned wrapper — the reproducible entry point
├── module.yaml               # product type, dependencies, main class
├── src/                      # one file per domain concept
│   ├── Primitives.kt         #   value classes, domain reads
│   ├── Model.kt              #   records, invariants, builder + freeze
│   ├── Rules.kt              #   domain services: the rules as predicates
│   ├── Contract.kt           #   typed constants + provenance
│   ├── Pipeline.kt           #   staged construction, step-labelled
│   ├── Verifier.kt           #   independent classification and checks
│   └── Main.kt               #   shell: parse, run, export, report
├── test/                     # kotlin.test suites, tiered by runtime
├── docs/                     # decision records
└── quality/                  # local plugin wiring ktlint/detekt/ktfmt
```

Rules of thumb:

- **A file is a concept, not a size unit.** Split when a file stops being
  about one thing, not when it crosses a line count.
- **The contract file precedes the pipeline.** Codify bounds before writing
  the stages that must obey them, and pin the codification with tests.
- **Construction steps label their output.** Whatever a stage places, it
  tags with a source string, so the audit log answers "what placed this?".
- **The verifier imports the model, not the pipeline.** If checking an
  artefact requires the builder's internals, the artefact is not
  self-describing enough.
- **Cross-language access goes through the facade**, if it exists at all.

### Idiom catalogue

- **Value class with validating `init`** — domain primitive; add
  `Comparable` and a display `toString`.
- **Private constructor + `operator fun invoke`** in the companion —
  factory-checked construction with natural call syntax.
- **Sealed hierarchy + exhaustive `when`** — closed sets; the compiler
  enumerates every site to update.
- **`data object` members** — singleton cases that print and compare well.
- **`data class` for records** — audit rows, results, views.
- **Extension functions for domain reads** — read as domain sentences; keep
  primitives free of kitchen-sink methods.
- **`Sequence` for domain enumerations** — lazy; no million-element lists
  materialised for one pass.
- **Typed outcome over exception** — sealed `Ok`/`Err` where failure is a
  domain outcome.
- **Builder → `freeze()`** — measured mutability for construction,
  immutability for consumption.

## Use of libraries

Prefer the standard library and the JDK platform: collections, `java.time`,
`java.net.http`, NIO. Add a dependency when it removes a recurring source of
complexity, provides an important safety boundary, or wraps genuinely hard
logic. Every dependency must be consumable by the build as plain
coordinates; if its standard workflow assumes a Gradle plugin, plan a local
plugin or choose a different library.

| Capability | Stay with stdlib/platform when… | Consider a library when… |
| -- | -- | -- |
| Testing | `kotlin.test` covers asserts and lifecycle | property-based testing for invariant-heavy domains; richer matchers when assertion messages do diagnostic work |
| Mocking | plain fakes — the domain is pure, so fakes are trivial | a seam cannot be faked cheaply; prefer restructuring the seam over mocking it |
| CLI parsing | flags and positionals parse in ten tested lines | subcommands, generated help, env/flag precedence — behind a thin pure parser you can test |
| JSON artefacts | hand-rolled deterministic writers for tiny fixed shapes | `kotlinx.serialization` once artefacts have structure; DTOs at the boundary, not on domain types |
| Dates and time | `java.time` | multiplatform code needs `kotlinx-datetime` |
| Immutability | `val` + read-only collections + `data class copy` | persistent structures shared across mutation-heavy paths — rare; measure first |
| Concurrency | sequential code | work is genuinely parallel and measurement shows it matters |
| Optimisation / feasibility | constructive heuristics | a constraint solver as a validation instrument — spike first, decide in a decision record |
| CSV / text export | a hand-rolled writer with deterministic field order | quoting/escaping rules dominate the writer's complexity |
| HTTP | `java.net.http.HttpClient` for simple calls | auth, retries, or middleware accumulate — behind an adapter |
| Logging | phased progress on stderr + a written report file | a long-lived service needs a logging facade |
| Persistence | none — artefacts are files | queries become first-class — behind a repository-shaped adapter |

### Dependency decision rules

Before adding a dependency, be able to answer:

1. What specific problem does it solve, and where did the code feel it?
2. Why is the stdlib/platform solution no longer clear?
3. Does it reduce total complexity after its concepts and setup are counted?
4. Can its behaviour be covered by focused tests?
5. Has current documentation been checked for deprecations and version
   changes?
6. Where is the reason recorded — a decision record for load-bearing
   dependencies, a comment in the build file otherwise?

Add one capability at a time, run the full check, and document the
operational effect. Prefer a focused library over a framework. Adopt a
dependency when it makes the program easier to read, safer to operate, or
cheaper to maintain — never merely shorter.

## The ratchet

Adopt these in the order they pay off, and start each new project one rung
above where the previous one ended:

1. **Typed primitives** — value classes for every domain scalar.
2. **The contract file** — externally fixed bounds as named constants with
   provenance, pinned by tests.
3. **Sealed sets** — closed distinctions as types the compiler checks.
4. **Pure domain** — deterministic core; seeded, recorded randomness; I/O at
   the edges.
5. **Independent verification** — a checker that re-derives the artefact
   against the contract.
6. **Audit and reproducibility** — construction logs and run configuration
   exported with the artefact.
7. **Tiered tests and quality wiring** — a fast dev loop, a full gate,
   lint/complexity/format checks green with documented thresholds.
8. **Cross-language access** — a REPL over the compiled domain, via the
   facade.
9. **Decision records** — one page per non-obvious choice, beside the code.

When a project finishes, note the next rung it exposed. When a principle in
this guide conflicts with what the code actually needed, correct the guide.

## Minimum standard

1. Every domain scalar is a value class that cannot hold an invalid value.
2. Every closed set is a sealed hierarchy dispatched exhaustively.
3. One contract file holds every externally fixed bound, with provenance.
4. The domain is pure; files, network, randomness, and interop live at the
   edges, and randomness is seeded and recorded.
5. Derivable quantities are recomputed — or memoised with a recorded
   measurement — never stored as a second source of truth.
6. Constructed artefacts are verified independently; intent records are
   re-verified, not trusted.
7. The artefact ships with an audit log and enough run configuration to be
   re-derived.
8. Tests are tiered: a fast loop with no heavy pipelines or network, and a
   full gate that exercises the real thing.
9. Lint, complexity, and format checks are green, with any threshold change
   or local exception justified in writing.
10. The README states purpose, contract, and commands; each non-obvious
    design choice has a decision record.

> For sequencing, environment setup, test strategy, and quality-check
> interpretation, use the Kotlin process skill (`SKILL.md` in this folder).
