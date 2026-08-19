---
name: clojure
description: Use when creating, repairing, refactoring, reviewing, or exploring Clojure code, EDN data models, dataflow pipelines, REPL-driven workflows, or Clojure orchestration of JVM systems. Guides project discovery, deps.edn and REPL setup, baseline lint/test/evaluation checks, characterization versus REPL-first development, proportionate schema and pipeline coverage, interpretation of clj-kondo as design signals, Java/Kotlin interop verification, and agent-REPL interaction discipline. Pair with the Clojure program design principles for design conventions.
---

# Clojure development process

This skill governs **what to do when** during Clojure work. Use the Clojure program design guide for architectural principles; use this skill for sequencing, REPL discipline, test strategy, quality checks, and verification.

The normal context is inspection, orchestration, reflection, and dataflow—often composing or exploring systems implemented in other JVM languages. The REPL is the primary working environment. Keep the process proportional: a scratch exploration does not need a test suite, but anything promoted to a maintained namespace needs a truthful verification loop.

## Operating stance

Keep engineering proportional to the work's risk and expected lifetime.

- Start with data and the smallest set of functions that transform it.
- Treat clj-kondo findings, test failures, reflection warnings, and unexpected REPL results as evidence and design pressure, not as automatic instructions.
- When a check reports something, classify it before changing anything:
  1. **Defect or safety risk** — fix the source code.
  2. **Useful design pressure** — refactor, or consciously accept the pressure at a documented boundary.
  3. **False positive** — configure the check narrowly or use a local, explained exception.
  4. **Policy mismatch** — change the project configuration and record why.
- Never silence a check broadly just to obtain a green run. A clean lint pass is evidence, not proof that the dataflow is correct.
- The REPL is the first line of verification; tests are the durable record. Both matter; neither replaces the other.

## Workflow

Follow these stages in order. Keep the loop short for small explorations, but do not skip discovery or baseline verification merely because the change is small.

### 1. Discover the project before editing

Read the local instructions and project artifacts that determine the workflow:

- `AGENTS.md` or equivalent repository guidance;
- `README.md`, examples, and any existing `comment` forms that document exploration;
- `deps.edn` (aliases, dependencies, paths) or the project's build configuration;
- existing schema definitions (Malli, spec) and EDN fixtures;
- the namespaces near the intended change and their tests;
- existing issue or task records when the project uses them.

Determine:

- the supported Clojure and JVM versions;
- how the REPL is started (which alias, which port, which middleware);
- how tests, linting, and formatting are invoked;
- whether the work is exploration, orchestration, interop, or pipeline construction;
- whether the change touches boundary schemas, run models, or interop wrappers;
- whether an agent will be driving the REPL, and through which connection.

Reuse the project's existing conventions. Do not introduce a new build tool, test runner, or schema library merely because it is familiar.

### 2. Establish the environment

Use the project's declared dependencies and runtime. Check the environment before changing code:

```bash
clojure -M -e "(println (clojure-version))"
```

Start the REPL through the project's normal alias. If the project defines a dev or test alias, use it:

```bash
clojure -M:dev
```

Verify the REPL is healthy before editing: require the main namespace, evaluate a known form, and confirm the expected result. If the REPL has been running for a long time or through prior failed experiments, restart it rather than debugging stale state.

Do not load secrets into source files, fixtures, or committed EDN. Ordinary tests must not require network access, provider credentials, or live services.

When adding a library, first establish the concrete problem it solves and why the standard library or an existing dependency is no longer clear. Check current documentation, add one capability at a time, and verify the operational effect in the REPL before writing code that depends on it.

#### Consult local and authoritative documentation before guessing

Use the sources in this order:

1. project code, tests, README, and `comment` forms for project-specific behaviour;
2. the REPL itself: `(doc f)`, `(source f)`, `(apropos "pattern")`, `(dir some.ns)`;
3. installed library source for dependency behaviour;
4. current official Clojure, library, or JVM documentation when local sources are insufficient.

The REPL is the fastest and most version-accurate reference. Prefer it over web searches for API questions about code already on the classpath.

### 3. Establish a baseline before editing

Run the narrowest useful baseline checks:

```bash
clj-kondo --lint src test
clojure -M:test
```

Then verify the REPL baseline:

```clojure
(require '[my-app.core :as core] :reload)
;; evaluate a known-good form and confirm the expected result
```

Record which failures predate the change. Distinguish lint findings, failing tests, reflection warnings, namespace load errors, and REPL state confusion. Do not treat a pre-existing failure as evidence that the proposed change caused it.

For a reported bug, reproduce it in the REPL before editing. For an existing pipeline being refactored, capture representative intermediate values before rearranging the implementation.

### 4. Define the data contract

Before choosing tests or abstractions, write down the data that matters:

- the shape of input data (as a schema or an example);
- the shape of output data;
- the intermediate shapes at each pipeline step;
- which keys are required and which are optional;
- the run model's states and legal transitions, if orchestrating;
- the interop boundary: which Java/Kotlin types enter, and what Clojure data they become;
- the effects: what is read, written, called, or mutated.

Separate external effects from deterministic transformations where the boundary is real. A typical boundary is:

```text
load/validate → pure pipeline steps → run-model transitions → effects at edges
```

Do not split namespaces merely because they are long. Split when a namespace has a distinct concept or can be tested independently.

### 5. Choose the development strategy deliberately

Use the strategy that matches the code's history and the change's intent.

#### Exploration: REPL first

For understanding data, exploring a Kotlin model's behaviour, or composing a new pipeline:

1. Evaluate forms in a `comment` block or scratch namespace.
2. Capture intermediate values with `def` inside the comment for inspection.
3. When the exploration produces something load-bearing, extract it into a named function with a docstring.
4. Add a test if the behaviour is a contract, not just an observation.

#### Existing behaviour or legacy code: characterize first

When the implementation already exists, write characterization tests (or REPL-captured examples) before refactoring it. Capture the behaviour that must not change. Then refactor behind that safety net.

#### New pipeline step or schema: test first

For a new validation rule, transformation step, run-model transition, or interop wrapper:

1. Write a failing test describing the input data and expected output.
2. Implement the smallest function that makes it pass.
3. Verify in the REPL with additional examples.
4. Add boundary and failure cases when the contract is stable.

#### Pure refactoring: preserve first, then simplify

Run the existing tests before changing structure. Do not add speculative abstractions. Add a test only when the refactor reveals an unprotected contract.

### 6. Build proportionate coverage

Do not optimize for a universal percentage. Cover risks and contracts instead of every function.

The normal baseline is:

| Area | Proportionate coverage |
| --- | --- |
| Boundary schema | Valid input accepted, each important invalid shape rejected with useful errors |
| Pure pipeline step | Representative transformation plus meaningful empty, missing, or malformed input |
| Run model | Legal transitions, illegal transitions rejected, and serialisation round-trip through EDN |
| Interop wrapper | Fixture-backed Java/Kotlin objects converted to expected Clojure data; failure behaviour |
| Orchestration | A complete run through fixture data; restart/replay if promised |
| Agent-produced data | Schema validation rejects malformed or unsafe output before it enters the system |

Use data-oriented assertions. Compare expected and actual EDN values directly; avoid asserting implementation details.

Avoid:

- a test for every trivial function;
- tests that only prove a function was called;
- network access or credentials in ordinary tests;
- adding tests solely to satisfy an arbitrary coverage percentage.

Property-based testing (test.check) is a natural fit: generate EDN values matching the schema, run them through pipelines, assert invariants hold for all generated inputs.

### 7. Implement in small verified steps

For each behaviour change:

1. Change the test or schema first when using test-first development.
2. Make the smallest source change.
3. Evaluate the changed forms in the REPL.
4. Inspect the result—compare actual data against expected data.
5. Refactor only after behaviour is verified.
6. Run lint and tests before continuing.

Keep effects at the edges. Pass configuration as arguments. Do not read environment variables or system properties inside pipeline steps.

After a structural change, run clj-kondo and the project's tests before continuing. Do not let a lint pass become the design objective.

### 8. Interpret quality checks as design review

Run the project's configured checks in their intended order. Then review the findings rather than applying automatic fixes blindly.

#### clj-kondo

clj-kondo is static analysis: it catches errors without executing code. Treat its findings as design pressure:

- unused bindings and namespaces may indicate dead code or an abandoned exploration;
- arity errors and unresolved symbols are defects;
- reflection warnings indicate interop boundaries that need type hints or wrapper functions;
- redundant expressions may indicate a pipeline step that has lost its purpose.

Keep linters enabled when they expose real risks. Suppress narrowly, with a reason, only for a documented boundary pattern. Do not disable checks globally to silence noise.

#### Reflection warnings

Set `*warn-on-reflection*` during development. Every warning is either a performance problem or an interop boundary that needs a type hint. Fix them or document why they are accepted.

#### REPL state hygiene

If the REPL behaves unexpectedly:

1. Reload the namespace explicitly: `(require 'my.ns :reload)`.
2. Check for stale `def` bindings from earlier experiments.
3. If confusion persists, restart the REPL. Do not debug phantom behaviour caused by stale state.

#### Check conflicts

When tools disagree (e.g., clj-kondo's preferred style versus the project's existing convention), choose the clearest project policy and configure it explicitly. Prefer a stable, documented convention over alternating code to satisfy different tools.

### 9. Exercise the system, not only its tests

Before declaring work complete, run the real system through safe paths appropriate to the work:

- a representative pipeline run through fixture data;
- schema validation with both valid and invalid input;
- a complete orchestrated run with an inspectable EDN run model;
- Java/Kotlin interop calls through the designed facade;
- agent-produced data validated and rejected where unsafe;
- serialisation round-trip: write the run model as EDN, read it back, compare.

Check output shape, run-model completeness, and the absence of secrets in output. Run a live remote operation only when the user's explicit runtime credential boundary is available and the operation is safe and intended.

### 10. Finish the project-facing work

Before delivering:

- run the complete configured lint/test command;
- verify all affected namespaces, tests, schemas, and documentation;
- extract any load-bearing REPL explorations into named functions or tests;
- clean up scratch namespaces and stale `def` bindings;
- update README usage when behaviour or setup changed;
- record dependency, schema, or operational decisions where maintainers will need them;
- report exactly what was evaluated and what was not, especially live interop and remote paths.

## Completion checklist

A Clojure change is ready when:

- the data contract (schemas, shapes, required/optional keys) is explicit;
- the project's Clojure/JVM environment is reproducible;
- ordinary tests require no network, credentials, or live services;
- existing behaviour is characterized before risky refactors;
- new pipeline steps and schemas were developed test-first where that clarified the contract;
- tests cover the important normal, boundary, error, interop, and orchestration paths proportionately;
- external systems are behind small named wrapper functions;
- run models are EDN, inspectable, and serialisable;
- exploratory work was captured in `comment` forms or extracted into named functions;
- clj-kondo and tests pass;
- quality findings were classified and handled deliberately;
- the REPL environment is clean (no stale bindings, no scratch state in production namespaces);
- the README and final evidence are truthful.
