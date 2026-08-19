# Kotlin program design

## Overview

> Keep the domain model authoritative, explicit, and independent of delivery mechanisms; put uncertainty, I/O, model-provider calls, persistence, and language interop at well-defined boundaries.

A Kotlin program should model the domain directly. The core is not merely a transformation pipeline: it is the place where vocabulary, invariants, state transitions, and policy are made explicit. Application services coordinate the model with external capabilities. Infrastructure and interfaces adapt the model to databases, files, HTTP, terminals, model providers, and other languages.

A useful program shape:

```text
Interface: CLI / HTTP / UI / Ruby-JRuby facade
    ↓
Application use cases
    ↓
Ports: repository / clock / random / model provider / publisher
    ↓
Domain model and rules
    ↓
Adapters: files / database / API / terminal / LLM provider
```

Dependencies point inward. The domain must not import Ktor, JDBC, an LLM SDK, a persistence library, or JRuby-specific concerns.

## Principles

Apply these principles proportionally:

- **Exploratory model:** keep the code simple; make the central vocabulary and invariants explicit, but do not add architecture ceremony.
- **Maintained domain library or service:** establish boundaries, deterministic tests, quality checks, compatibility rules, and a README.
- **Long-running, state-changing, or agentic system:** require explicit state and transition semantics, recovery behaviour, auditability, policy boundaries, and safe cancellation.

### 1. State the domain purpose first

Define the problem in domain language before choosing framework or persistence technology. Establish a small glossary and use the same terms in conversation, types, functions, tests, logs, and documentation.

Avoid names that describe only implementation mechanics when a domain term exists. `ReviewDecision`, `ExtractionCandidate`, and `ToolPermission` communicate more than `Result`, `Item`, and `Config`.

### 2. Make invalid states difficult to represent

Prefer small domain types over unconstrained primitives when values have distinct meanings or constraints:

```kotlin
@JvmInline
value class TaskId private constructor(val value: String) {
    companion object {
        fun parse(raw: String): TaskId =
            if (raw.isNotBlank()) TaskId(raw) else error("Task id must not be blank")
    }
}
```

Use factory functions or constructors that establish validity. Do not rely on every caller remembering to validate the same rule.

### 3. Model rules as behaviour

A domain object should own its invariants and state changes. A use case coordinates the domain object with repositories, clocks, providers, and policies; it should not become the place where core rules live.

Prefer methods such as:

```kotlin
fun accept(command: AcceptProposal): Review
fun reject(reason: RejectionReason): Review
```

over external procedures that inspect and mutate domain data.

### 4. Use immutable values and explicit transitions by default

Prefer `val`, `data class`, and functions that return a new state or an explicit outcome. Mutation is acceptable when it makes an aggregate's consistency clearer, but it should be encapsulated rather than exposed.

Use sealed types for closed sets of states, commands, and outcomes:

```kotlin
sealed interface ReviewOutcome {
    data object Accepted : ReviewOutcome
    data class Rejected(val reason: RejectionReason) : ReviewOutcome
    data class NeedsEvidence(val missing: List<EvidenceRequirement>) : ReviewOutcome
}
```

This makes callers handle every meaningful alternative.

### 5. Distinguish expected outcomes from unexpected failures

Model expected domain outcomes explicitly. Reserve exceptions for violated invariants, unavailable infrastructure, programmer error, and genuinely exceptional technical conditions.

Kotlin exceptions are unchecked, so public contracts must make expected failure cases visible. An operation such as “approve proposal” should normally return a domain outcome rather than throwing for an expected policy rejection. A provider timeout, malformed persisted record, or impossible state may be an exception.

### 6. Keep the domain core deterministic

Domain code should not secretly read the environment, inspect the wall clock, generate IDs, call an API, write files, or contact a model provider. Pass those capabilities through application services and ports when they are required.

A deterministic core is easier to test, replay, explain, and call from other languages.

### 7. Separate domain, application, infrastructure, and interface by reason to change

A practical structure for a maintained system is:

```text
feature/
  domain/          # entities, value objects, policies, domain events
  application/     # use cases, ports, transaction and policy boundaries
  infrastructure/  # HTTP, database, filesystem, LLM/provider adapters
  interface/       # CLI, REST, messaging, Ruby/JRuby facade
```

Do not split files merely because they are long. Do not create four packages for every small model. Introduce a seam when a component has a distinct reason to change or can be tested independently.

Package by feature or bounded context before packaging by technical layer. Once a feature has several components, technical subpackages can clarify dependency direction.

### 8. Define ports from the domain's needs

Ports express what the application needs, not what a vendor SDK happens to expose:

```kotlin
interface Clock {
    fun now(): Instant
}

interface ProposalRepository {
    fun load(id: ProposalId): Proposal?
    fun save(proposal: Proposal)
}

interface ModelProposalSource {
    suspend fun propose(command: ProposalRequest): ModelProposal
}
```

Adapters implement ports. Domain code and use cases should not know whether a port is backed by Postgres, files, Jena, an HTTP service, or an LLM provider.

Constructor injection is the default. Introduce a dependency-injection framework only when composition is genuinely repetitive or runtime wiring needs it.

### 9. Keep use cases thin but explicit

An application service should make the operational sequence visible: load, decide, validate policy, persist, publish, and return an outcome. It should not conceal domain rules in coordination code.

It also owns the transaction boundary. Domain objects protect invariants; application services commit or roll back the coordinated change.

### 10. Model agentic work as proposal, policy, decision, execution

For agentic systems, distinguish:

- **Domain facts:** approved tasks, accepted decisions, recorded provenance, blocked work.
- **Probabilistic proposals:** LLM-produced plans, extractions, classifications, or tool requests.
- **Policy:** permissions, budgets, model selection, allowed tools, retry limits, and human-approval requirements.
- **Technical execution:** provider calls, tool invocation, persistence, queues, telemetry.

Only validated proposals become domain commands or facts. A model proposing `deleteAll()` is not a fact, an instruction to obey, or a reason to bypass policy.

Preserve enough boundary metadata to explain behaviour: provider/model identity, prompt-template version, request correlation ID, policy decision, tool calls, and validation outcome. Redact secrets and sensitive content according to the project's retention policy.

### 11. Make long-running work recoverable

If work can outlive a process, define:

- states and legal transitions;
- idempotency keys or equivalent duplicate protection;
- timeout and retry ownership;
- cancellation semantics;
- restart and reconciliation behaviour;
- whether replay, compensation, or manual intervention is required.

A state machine should make invalid transitions impossible or visibly rejected. Do not infer state from a scattered collection of booleans and timestamps when a named state is clearer.

### 12. Treat concurrency as an application concern

Domain decisions should normally be synchronous and deterministic. Use `suspend` on ports or use cases only where the operation may actually suspend.

Use structured concurrency: child work belongs to a parent scope, and cancellation and failure propagate predictably. Avoid detached `GlobalScope` work in application code.

Define dispatcher ownership at the boundary. Do not let a domain object choose an I/O dispatcher or launch background work.

### 13. Treat external services as unreliable

Adapters should handle timeouts, pagination, partial responses, malformed fields, authentication failures, rate limits, and useful contextual errors. Retry only operations that are safe to repeat, and make retry policy explicit.

Translate technical failures at the adapter boundary. Do not let HTTP status codes, SQL exceptions, or provider-specific error types leak through domain vocabulary.

### 14. Make rerunning safe

Prefer:

- stable ordering;
- deterministic names and identifiers where appropriate;
- idempotent application operations;
- unchanged work recognised as unchanged;
- explicit overwrite, deletion, pruning, or reset modes;
- durable state that supports restart.

For operations with external effects, plan before applying where that distinction is meaningful. A preview must use the real planning and validation logic and must not mutate files, records, remote services, or provider state.

### 15. Treat interoperability as a boundary

Ruby or JRuby should consume a deliberate JVM-facing boundary, not the entire internal object graph.

A good facade is:

- small and stable;
- explicit about inputs, outputs, and errors;
- based on ordinary JVM-visible types where practical;
- free of `suspend`, `Flow`, Kotlin function types, overload-heavy calls, and internal sealed hierarchies where those create avoidable friction;
- versioned and covered by integration tests against compiled artefacts.

Use snapshots or transport objects for inspection. Do not expose mutable internals merely to make scripting convenient.

### 16. Define compatibility and evolution

Decide how these change safely:

- public Kotlin APIs;
- persisted records and domain-event schemas;
- configuration formats;
- workflow state;
- Ruby/JRuby-facing facades;
- exported files and external contracts.

Migrations are domain change, not merely database mechanics. Record compatibility expectations and deprecate deliberately.

### 17. Keep dependencies deliberately boring

Prefer the Kotlin standard library, explicit constructors, and a small number of focused libraries. Add a dependency when it removes recurring complexity, provides an important safety boundary, or establishes an existing project convention.

Before adding a library, answer:

1. What specific problem does it solve?
2. Why is the standard-library or plain-Kotlin solution no longer clear?
3. Does it reduce total complexity after concepts and setup are included?
4. Is it compatible with the project's Kotlin/JVM versions and existing dependencies?
5. Can its behaviour be covered by focused tests?
6. Has the current documentation been checked for deprecations and version changes?
7. Is the reason recorded where maintainers will find it?

Prefer one focused library over a broad framework. Add one capability at a time and verify the operational effect.

### 18. Make quality checks design signals

Use the compiler, formatter, static analysis, architecture tests, and tests as evidence. Do not contort the model to satisfy a metric, and do not silence a finding broadly to obtain a green run.

Architecture checks should enforce the intended dependency direction: for example, domain code must not import HTTP, persistence, coroutine-dispatcher, model-provider, or JRuby implementation types.

### 19. Make the system observable without exposing secrets

Use structured operational events with correlation IDs where the system is long-running or agentic. Distinguish:

- audit records that explain a domain or policy decision;
- operational logs used to diagnose behaviour;
- debug traces that may be more detailed and more sensitive.

Do not put secrets, credentials, private prompts, or sensitive payloads into ordinary logs by default. Define redaction and retention at the boundary.

### 20. Document behaviour and decisions

A README should explain:

- the domain purpose and vocabulary;
- supported states and transitions;
- setup and runtime requirements;
- safe and complete examples;
- external effects and required credentials;
- test and quality commands;
- compatibility and migration expectations;
- agentic policy, where applicable;
- the Ruby/JRuby-facing facade, where applicable.

Record consequential decisions in short ADRs, especially: modelling boundaries, persistence semantics, agent policy, interoperability facades, dependency additions, and deviations from normal quality rules.

## Minimum standard

1. One clearly stated domain purpose and vocabulary.
2. Domain invariants enforced by the model.
3. A deterministic, framework-free core.
4. External I/O and uncertainty behind small adapters.
5. Expected outcomes modelled explicitly.
6. Application services own coordination and transactions.
7. Agent proposals validated before becoming domain facts.
8. Long-running work has explicit state, cancellation, and recovery semantics.
9. Ordinary tests require no network, provider credential, or live service.
10. Quality and architecture checks protect intended boundaries.
11. Ruby/JRuby access goes through a deliberate compiled facade.
12. Secrets supplied only at runtime and excluded from logs.
13. Compatibility rules for public APIs, persisted state, and facades.
14. A README with truthful examples and verification commands.

> For the development workflow, baseline checks, test strategy, quality interpretation, and verification, use the Kotlin process skill.
