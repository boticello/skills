---
name: kotlin
description: Use when creating, repairing, refactoring, reviewing, or verifying Kotlin domain models, libraries, services, workflow engines, agentic components, or JVM facades. Guides project discovery, Kotlin Toolchain setup, baseline build/test/quality checks, characterization versus test-first development, proportionate domain and boundary coverage, interpretation of ktlint and detekt as design signals, architecture-boundary checks, agentic verification, and JRuby-facing smoke tests. Pair with the Kotlin program design principles for design conventions.
---

# Kotlin development process

This skill governs **what to do when** during Kotlin work. Use the Kotlin program design guide for architectural principles; use this skill for sequencing, test strategy, quality checks, and verification.

The normal context is a domain model with behaviour, potentially used by agentic workflows or accessed through Ruby/JRuby. Keep the process proportional: a small model does not need enterprise ceremony, but every change needs a truthful verification loop.

## Operating stance

Keep engineering proportional to the domain's risk and expected lifetime.

- Start with the smallest explicit model that protects the actual invariants.
- Treat compiler warnings, tests, ktlint, detekt, architecture checks, and smoke tests as evidence and design pressure, not as automatic instructions.
- When a check reports something, classify it before changing anything:
  1. **Defect or safety risk** — fix the source code.
  2. **Useful design pressure** — refactor, or consciously accept the pressure at a documented boundary.
  3. **False positive** — configure the check narrowly or use a local, explained exception.
  4. **Policy mismatch** — change the project configuration and record why.
- Never silence a check broadly just to obtain a green run. A green suite is evidence, not proof that the domain contract is fully covered.
- Prefer direct, reproducible commands that a human or coding agent can run and report.

## Workflow

Follow these stages in order. Keep the loop short for small changes, but do not skip discovery or baseline verification merely because the model is small.

### 1. Discover the project before editing

Read the local instructions and project artifacts that determine the workflow:

- `AGENTS.md` or equivalent repository guidance;
- `README.md`, examples, ADRs, and domain glossary;
- Kotlin Toolchain project files and plugin configuration;
- Kotlin/JVM version declarations;
- existing test, ktlint, detekt, architecture-check, and coverage configuration;
- the domain model and nearby tests;
- application services, ports, adapters, and public facades;
- existing issue or task records when the project uses them.

Determine:

- the supported Kotlin and JVM versions;
- whether the project uses the Kotlin Toolchain, another build, or both;
- how build, test, check, formatting, and static analysis are invoked;
- whether the change affects domain, application, infrastructure, interface, or Ruby/JRuby-facing code;
- whether the system is read-only, state-changing, long-running, or agent-invoking;
- whether credentials, model providers, network access, or live services are involved.

Reuse the project's existing conventions. Do not introduce Gradle, Maven, a new test framework, a DI container, or a workflow framework merely because it is familiar.

### 2. Establish the environment

Use the project's declared toolchain and dependency versions. Check the environment before changing code:

```bash
kotlin --version
kotlin build
```

If the project defines a narrower setup or bootstrap command, use that first. Preserve the project's existing build and dependency model.

Do not load secrets into source files, fixtures, command output, or committed environment files. Preserve the project's explicit secret boundary. Ordinary tests must not require network access, provider credentials, or live services.

When adding a dependency, first establish the concrete problem it solves and why the standard library or an existing dependency is no longer clear. Check current documentation, add one capability at a time, and verify the operational effect.

#### Consult local and authoritative documentation before guessing

Use the sources in this order:

1. project code, tests, README, ADRs, and glossary for project-specific behaviour;
2. compiler diagnostics and generated API for local type and signature questions;
3. installed dependency source and documentation for dependency behaviour;
4. current official Kotlin, Kotlin Toolchain, library, or provider documentation when local documentation is absent or insufficient.

Do not use documentation for a different Kotlin or JVM version to settle a compatibility question without checking the project's declared versions.

### 3. Establish a baseline before editing

Run the narrowest useful baseline checks:

```bash
kotlin build
kotlin test
```

Then run the project's configured quality command if one exists, for example:

```bash
kotlin check
```

If `kotlin check` does not yet aggregate the project's quality gates, run the configured gates directly, commonly:

```bash
ktlint
detekt
```

Record which failures predate the change. Distinguish compilation failures, failing behaviour tests, formatting findings, static-analysis findings, architecture violations, missing dependencies, and missing credentials. Do not treat a pre-existing failure as evidence that the proposed change caused it.

For a reported bug, reproduce it before editing. For an existing model being refactored, capture representative behaviour before rearranging the implementation.

### 4. Define the observable contract

Before choosing tests or abstractions, write down the behaviour that matters:

- domain states and legal transitions;
- commands, outcomes, and rejection reasons;
- invariants and consistency boundaries;
- inputs, outputs, and validation rules;
- external effects and ports;
- ordering, idempotency, and rerun expectations;
- timeout, retry, cancellation, and recovery behaviour;
- agent permissions, budgets, tools, and policy decisions;
- Ruby/JRuby-facing construction, calls, and output shape.

Separate external effects from deterministic decisions where the boundary is real. A typical boundary is:

```text
interface → application use case → domain decision → ports/adapters
```

Do not split files merely because they are long. Split when a component has a distinct reason to change or can be tested independently.

### 5. Choose the test strategy deliberately

Use the strategy that matches the code's history and the change's intent.

#### Existing behaviour or legacy code: characterize first

When the implementation already exists, write characterization tests before refactoring it. Capture the behaviour that must not change, even if the current behaviour may later be questioned. Then refactor behind those tests.

These tests are not a failure of test-driven development; they are the correct way to create a safety net around behaviour that already exists.

#### New domain rule or policy: test first

For a new invariant, state transition, validation rule, policy decision, recovery rule, or facade contract:

1. Write a failing test describing the observable scenario and expected result.
2. Implement the smallest change that makes it pass.
3. Refactor while keeping the test green.
4. Add boundary and failure cases when the policy is stable.

#### Pure refactoring: preserve first, then simplify

Run the existing tests before changing structure. Do not add speculative abstractions or tests that assert private implementation details. Add a test only when the refactor reveals an unprotected observable contract.

#### Exploratory work

For a disposable experiment, a small implementation-first slice can be reasonable. Before promoting it into a maintained model or service, capture the contract, add proportionate tests, and establish the normal quality command.

### 6. Build proportionate coverage

Do not optimize for a universal percentage. Cover risks and contracts instead of every line or helper method.

The normal baseline is:

| Area | Proportionate coverage |
| --- | --- |
| Domain model | Invariants, legal and illegal transitions, representative and boundary cases |
| Application use case | Coordination, policy decisions, expected failures, transaction and cancellation semantics |
| Infrastructure adapter | Fixture-backed protocol, persistence, provider, pagination, malformed-data, and failure behaviour |
| Agentic boundary | Validation of model output, policy enforcement, audit metadata, unsafe-tool rejection |
| Long-running work | Restart, replay, timeout, retry, cancellation, and reconciliation behaviour |
| Ruby/JRuby facade | JVM-visible construction, simple calls, stable outputs, and representative JRuby integration |
| Interface | Safe defaults, important option combinations, output shape, and error reporting |

Use behaviour-oriented assertions. A domain test may assert several fields when they are all part of one state transition; split it only when a failure would otherwise be hard to interpret.

Avoid:

- a test for every trivial private helper;
- tests that only prove a mock was called;
- broad mocks that reproduce the implementation instead of the external contract;
- network access, model-provider credentials, or live services in ordinary tests;
- adding a live end-to-end test when a deterministic fixture tests the same decision;
- adding tests solely to satisfy an arbitrary coverage percentage.

Prefer small fakes or fixture-backed adapters over long mock setups. If a use case needs a clock, ID generator, random source, repository, or model provider, inject it so tests can control the boundary.

For agentic boundaries, test that unvalidated model output cannot become a domain fact, that forbidden tools are rejected, and that policy decisions are recorded.

For property-based or invariant testing, generate valid and invalid command sequences and assert that every resulting state satisfies the model's invariants, including after rejected commands, retries, or replay.

### 7. Implement in small verified steps

For each behaviour change:

1. Change the test or contract first when using test-first development.
2. Make the smallest source change.
3. Run the focused test.
4. Inspect compiler and test diagnostics.
5. Refactor only after behaviour is green.
6. Run the relevant quality checks before continuing.

Keep network calls, environment reads, timestamps, randomness, persistence, and provider calls at the edges. Pass dependencies explicitly when that creates a genuine testing or composition seam; do not introduce a container or framework to avoid passing a small number of dependencies.

After a structural code change, run the project's required formatting, build, tests, static analysis, and architecture checks before continuing. Do not let a formatting or smell pass become the design objective.

### 8. Interpret quality checks as design review

Run the project's configured checks in their intended order. Then review the findings rather than applying automatic fixes blindly.

#### ktlint

Use ktlint for formatting and local style consistency. It is normally safe to run the formatter for mechanical repair:

```bash
ktlint --format
```

Do not treat formatting as a substitute for design review. If a rule repeatedly fights an intentional project style, configure the project policy explicitly rather than changing code back and forth.

#### detekt

Use detekt for Kotlin-specific static analysis and code smells. Treat findings as design pressure:

- complexity findings may indicate a policy or transition that needs a clearer model;
- exception findings may indicate that expected outcomes are being modelled as technical failures;
- coroutine findings may indicate unstructured concurrency or hidden asynchrony;
- naming and documentation findings may indicate that the domain vocabulary is not yet settled.

Keep detectors enabled when they expose a real design risk. Suppress narrowly, with a reason, only for a recurring documented boundary pattern. Do not raise thresholds until warnings disappear.

#### Compiler warnings

Treat warnings as part of the project's evidence. Do not leave new warnings unexamined. If the project has a warnings-as-errors policy, preserve it.

#### Architecture checks

Architecture checks enforce dependency direction and forbidden imports. A failure usually means one of three things:

- domain code has acquired an infrastructure concern;
- an adapter or interface is reaching around the application boundary;
- the intended architecture is unclear and needs an explicit decision.

Fix the boundary or record the architectural decision; do not merely weaken the check.

#### Check conflicts

When tools disagree, choose the clearest project policy and configure it explicitly. Prefer a stable, documented convention over alternating code to satisfy different tools.

### 9. Exercise the system, not only its tests

Before declaring work complete, run the real compiled artefact through safe paths appropriate to the system:

- a representative domain scenario;
- invalid input and expected rejection behaviour;
- a fixture-backed adapter path;
- a dry-run or preview path, if supported;
- a safe state-changing path in a temporary or disposable environment;
- restart or recovery behaviour for long-running work;
- agent-policy rejection for an unsafe proposal;
- Ruby/JRuby smoke tests when the facade changed.

Check output shape, exit or response behaviour where relevant, persisted state, stable names, correlation/audit metadata, and the absence of secrets in output. Run a live provider or remote operation only when the user's explicit runtime credential boundary is available and the operation is safe and intended.

### 10. Finish the project-facing work

Before delivering:

- run the complete configured build/test/quality command;
- verify all affected callers, tests, facades, and documentation;
- update README usage when behaviour or setup changed;
- record dependency, architectural, policy, or operational decisions where maintainers will need them;
- remove temporary fixtures, debug output, and scaffolding;
- report exactly what was exercised and what was not, especially live provider, remote, and JRuby paths.

## Completion checklist

A Kotlin change is ready when:

- its domain purpose, vocabulary, states, transitions, and effects are explicit;
- the project's Kotlin/JVM toolchain environment is reproducible;
- ordinary tests require no network, provider credential, or live service;
- existing behaviour is characterized before risky refactors;
- new domain behaviour was developed test-first where that clarified the contract;
- tests cover the important normal, boundary, error, external, recovery, and side-effect paths proportionately;
- external services and model providers are behind small testable ports;
- agentic proposals are validated and policy-checked before becoming domain facts;
- formatting, compiler, tests, detekt, and architecture checks were run;
- quality findings were classified and handled deliberately;
- the Ruby/JRuby-facing facade was exercised when affected;
- the actual compiled system was smoke-tested through safe paths;
- the README and final evidence are truthful.
