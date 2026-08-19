# Clojure program design

## Overview

> Build programs out of values, pure functions, and explicit data; keep state, time, and effects visible and at the edges; let the REPL be the place where design is discovered.

A useful program shape:

```text
Source data / external systems / Kotlin domain model
    ↓
Boundary validation (schema)
    ↓
Plain data transformations (pure functions over maps/vectors)
    ↓
Dataflow composition (runs, pipelines, orchestration)
    ↓
Effects at the edges (I/O, Java interop, state transitions)
    ↓
Run model as EDN (inspectable, persistable, diffable)
```

## Principles

Apply these principles proportionally:

- **Exploratory REPL work:** keep it in a scratch namespace or `comment` form; capture anything worth keeping as a named function.
- **Maintained orchestration or inspection tooling:** establish boundaries, schema validation at edges, tests, and a README.
- **Dataflow or agentic orchestration:** require explicit run models, deterministic replay, idempotency, and schema-validated state transitions.

### 1. Data first, functions second, macros last

The primary artefact is data. Model the problem as maps, vectors, sets, and namespaced keywords before reaching for protocols, records, multimethods, or macros.

- Use plain maps with namespaced keywords (`:run/status`, `:puzzle/seed`) for domain data. Namespaced keywords are the schema.
- Use functions for behaviour. A function over data is simpler than a method on an object.
- Use macros only when they provide a genuine syntactic or compile-time capability that functions cannot. Never use a macro to avoid passing an argument.
- Prefer `defrecord` or protocols only when you need type-based dispatch or Java interop—not as a default modelling tool.

The test: can you `prn` the intermediate state and understand it? If not, the design has hidden the data.

### 2. Values, not places

State is a value at a point in time, not a place that mutates. Prefer:

- immutable data structures everywhere;
- explicit state transitions as functions: `(f old-value) → new-value`;
- a single atom (or a small number of them) for genuinely mutable coordination state;
- `swap!` with pure functions, never side-effecting functions.

Avoid scattering atoms through namespaces. If you need more than two or three atoms in a namespace, the state model probably wants to be a single map in one atom, or reified as an explicit run model passed through the dataflow.

### 3. Simple over easy

Simplicity is about absence of interleaving, not about familiarity or brevity.

- Do not complect state with behaviour, data with schema, or orchestration with effect.
- A map of functions is simpler than a protocol with one implementation.
- A vector of steps is simpler than a state machine library until the transitions genuinely need guards, actions, and formal semantics.
- EDN configuration is simpler than a DSL until the DSL's abstraction pays for itself.

Choose the construct that keeps things unbraided, not the one that feels most powerful or most familiar from other languages.

### 4. Accrete, relax, remove—in that order

Design for growth by accretion (adding new keys, new functions, new namespaces) rather than by breaking change.

- New optional keys are safe. Removing or renaming keys is a breaking change.
- Relax input requirements rather than tightening them; tighten output guarantees rather than relaxing them.
- When removal is necessary, do it explicitly and version the boundary.
- This applies to EDN schemas, run models, function arities, and interop surfaces alike.

### 5. Schema at the boundaries, freedom in the middle

Clojure's power is that data flows freely through pure functions. Its discipline is that data entering and leaving the system is validated.

- Validate at system edges: reading EDN from disk, receiving data from an external API, crossing a Java interop boundary, accepting agent-produced output.
- Use Malli (or spec) for boundary schemas. Keep schemas as data, colocated with the namespace that owns the concept.
- Do not schema-check every intermediate value inside a pure pipeline. Trust the functions you've tested.
- When a schema fails, report the failure with the data's context, not just the spec error. A human or agent must be able to see what arrived and why it was rejected.

### 6. The REPL is a design tool, not a crutch

REPL-driven development is the primary mode of work. It is how you explore, compose, and verify. It is not a substitute for written code.

- Evaluate forms from source files, never type significant code directly into the REPL prompt.
- Use `comment` forms (Rich Comments) to capture exploratory expressions alongside the code they explore. These are living documentation and replayable experiments.
- When an exploration produces something load-bearing, extract it into a named function with a docstring and, if warranted, a test.
- A REPL session that produced a result you care about should leave behind code, not just scrollback.
- Keep the REPL environment clean: reload namespaces explicitly, avoid stale var bindings, and restart when state becomes confusing rather than debugging phantom behaviour.

### 7. Functions are the unit of composition

Build dataflow by composing functions, not by building frameworks.

- A pipeline is `(-> data (step-1 config) (step-2 config) (step-3 config))` until it genuinely needs conditional branching, parallel execution, or resumability.
- When pipelines need structure, represent the pipeline itself as data: a vector of steps, each a map with a function, its config, and its schema. Then interpretation is a fold over that data.
- Transducers are for when you've measured a performance problem or need to compose transformations independently of their context. Do not reach for them by default.
- Keep each step small enough to evaluate and inspect independently in the REPL.

### 8. Explicit run models for orchestration

When Clojure orchestrates a process—whether an instrument run, an agent workflow, or a data pipeline—the run itself should be a first-class value.

- A run is a map: `{:run/id … :run/status … :run/steps […] :run/result …}`.
- Runs are EDN: serialisable, diffable, inspectable, persistable.
- Step transitions are pure functions over the run value.
- Effects (I/O, API calls, Java interop) happen at the boundary of each step, driven by the step's data, not buried inside it.
- A completed run model is the audit trail. It should answer "what happened, in what order, with what inputs and outputs?" without requiring logs.

### 9. Java interop is a boundary, not a style

Clojure runs on the JVM and interops cleanly with Java and Kotlin. That interop should be deliberate.

- Wrap Java/Kotlin calls in small Clojure functions with clear names and docstrings.
- Convert Java objects to Clojure data at the boundary where practical; do not let Java object graphs leak deep into Clojure pipelines.
- When calling a Kotlin domain model, go through its designed facade. Treat the facade as an external API, not as a transparent window into Kotlin internals.
- Reflection warnings are errors in waiting. Set `*warn-on-reflection*` and fix what it reports.

### 10. Namespaces are the architecture

Namespaces are Clojure's modules. Organise them by concept, not by technical layer.

- `my-app.run`, `my-app.schema`, `my-app.pipeline` are better than `my-app.models`, `my-app.utils`, `my-app.helpers`.
- A namespace should have a clear purpose stated in its docstring.
- Keep `require` declarations clean: no unused requires, no cyclic dependencies, explicit aliases.
- `clj-kondo` should report a clean namespace graph.

### 11. Effects are explicit and at the edges

Side effects are necessary and should be visible.

- I/O, network calls, Java interop mutations, and state transitions belong in functions whose names or namespaces signal their nature: `load-run!`, `save-result!`, `call-provider!`.
- Pure transformation functions should not call `println`, read environment variables, or touch the filesystem.
- When a function needs configuration, pass it as an argument. Do not read env vars or system properties inside pipeline steps.
- If a function both decides and does, split it: decide first (pure), then do (effectful).

### 12. Agent-driven REPL work needs guardrails

When an agent manipulates the REPL, the same discipline applies, plus:

- The agent evaluates forms from source files or explicit input, never improvises in the REPL prompt.
- The agent's exploratory work goes into `comment` forms or a scratch namespace, not into production namespaces.
- Schema validation runs on any data the agent produces before it enters the system.
- The agent reports what it evaluated and what the result was, not just "it worked."
- REPL state is reset between independent tasks to avoid contamination.

### 13. Keep dependencies deliberately boring

Prefer the Clojure standard library and a small number of focused libraries. The Clojure ecosystem rewards restraint.

Before adding a library, answer:

1. What specific problem does it solve?
2. Why is the standard-library or plain-data solution no longer clear?
3. Does it reduce total complexity after its concepts and setup are included?
4. Is it compatible with the project's Clojure/JVM versions and existing dependencies?
5. Can its behaviour be covered by focused tests or REPL evaluation?
6. Has the current documentation been checked for deprecations and version changes?
7. Is the reason recorded where maintainers will find it?

Prefer one focused library over a framework. Add one capability at a time and verify the operational effect.

### 14. Test what matters, explore the rest

Clojure's test culture is pragmatic: the REPL is the first line of verification, tests are the durable record.

- Test boundary schemas, pure pipeline transformations, run-model transitions, and interop wrappers.
- Use `clojure.test` (or Kaocha for runner convenience) for durable tests.
- Use REPL evaluation and `comment` forms for exploration that doesn't need permanence.
- Property-based testing (test.check) is a natural fit for data-driven Clojure: generate EDN values, run them through pipelines, assert invariants.
- Do not write tests that merely reproduce the implementation. Test the contract.


## Choosing Clojure dependencies

Use the standard library and plain data by default. Add a library when it removes a recurring source of complexity, provides an important safety boundary, or establishes an existing project convention. The Clojure ecosystem rewards restraint: most capabilities below have an honest stdlib answer, and the library should have to win.

Keep alias discipline alongside dependency discipline: inspection and debugging tools belong in a `:dev` alias, test tooling in `:test`, and structural-editing tools on the tooling classpath only. None of these belong in runtime dependencies.

| Capability | Stay with stdlib or plain Clojure when… | Consider another tool when… |
| --- | --- | --- |
| Data inspection | `prn`, `clojure.pprint`, and `tap>` answer the question. | Values are large, nested, or repeatedly explored. Use Portal from a `:dev` alias; add FlowStorm when you need recorded execution timelines rather than value snapshots. Both are dev-only; `tap>` calls must not leak into production namespaces. |
| Schema and validation | A few explicit predicate checks, or a function returning error data, make the rules obvious. | Schemas are nested, reused across boundaries, shared with agents, or should drive generative tests. Use Malli—schemas as data, works in babashka, generates test.check-compatible values. One schema library per project. |
| Java/Kotlin interop | Direct interop plus type hints is clear; `bean` covers shallow REPL inspection of an unfamiliar object. | You need recursive conversion of bean-shaped objects into Clojure data at a boundary. Use `clojure.java.data`; keep conversion at the edge and note that non-bean Kotlin classes need a facade that exposes convertible shapes. |
| Pipelines and dataflow | Threading macros, sequence functions, or a vector of step maps folded by a function express the flow. | There are genuine concurrent producer/consumer flows with backpressure. Use core.async deliberately; treat Missionary as an architecture decision, not a library swap. |
| Run orchestration | An EDN run model, pure transition functions, and an atom cover the states. | Transitions genuinely need guards and formal semantics (a state machine library), or you are building a long-lived service with lifecycle (Integrant or Component)—not for ordinary run orchestration. |
| Testing | `clojure.test` with a simple runner alias is adequate. | Suites need watch mode, filtering, and reporting (Kaocha), or invariants deserve generated inputs (test.check, with Malli generators so schemas and property tests share one source of truth). |
| Linting and formatting | clj-kondo is always the baseline—it lints Clojure and EDN, including run-model fixtures. Editor-integrated formatting is enough for a solo project. | Conventions must be enforced consistently in CI or across contributors. Configure cljfmt or zprint explicitly rather than relying on editor defaults. |
| Serialisation | EDN via `pr-str` / `clojure.edn/read-string` round-trips within Clojure. | Data crosses to non-Clojure consumers or JSON transport. Use Transit for Clojure-adjacent transport; a JSON library only at genuine JSON boundaries. Never use `clojure.core/read-string` on untrusted input. |
| HTTP | One simple call via `java.net.http` interop with no shared policy. | The client needs authentication, retries, middleware, or consistent error handling. Use a thin JDK-client wrapper such as hato rather than a large HTTP framework. |
| Scripting and tasks | `clojure -M` / `-X` entry points are fast enough. | JVM startup is unacceptable or you want project task running. Use babashka; keep one runtime per artefact rather than splitting logic across bb and JVM Clojure. |
| Structural editing | Hand-editing text is sufficient. | Agents or tooling must edit code or EDN structurally. Use rewrite-clj / rewrite-edn on the tooling classpath only, never as a runtime dependency. |

Before adding any of these, answer the seven questions in principle 13. Prefer one focused library over a framework. Add one capability at a time, verify the operational effect in the REPL, and record the reason where maintainers will find it.


## Minimum standard

1. Data modelled as plain maps/vectors with namespaced keywords.
2. Schema validation at every system boundary.
3. Pure functions for transformation; effects at explicit edges.
4. State transitions as functions over values.
5. Run models as EDN, inspectable and persistable.
6. REPL evaluation from source files, not the prompt.
7. Exploratory work captured in `comment` forms or extracted into named functions.
8. Java/Kotlin interop wrapped in small named functions at boundaries.
9. `clj-kondo` clean.
10. Ordinary tests require no network or live services.
11. A README with setup, REPL entry point, and verification commands.

> For the development workflow, REPL discipline, baseline checks, test strategy, and agent-REPL interaction rules, use the Clojure process skill.
