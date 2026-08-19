# Ruby program design

## Overview

> Keep the Ruby command small, conventional, and readable; put external effects at the edges, and make the core deterministic.

### A useful program shape

Normalise external data once at the adapter boundary. Preserve the distinction between missing, null, empty, and invalid values when the downstream behaviour depends on it. Add contextual errors at the boundary rather than scattering protocol-specific checks through the renderer.

```
CLI parsing
    ↓
Use-case orchestration
    ↓
API/filesystem adapters
    ↓
Normalised data
    ↓
Pure transformation/rendering
    ↓
Plan
    ↓
Apply
```

### A conventional layout

```text
bin/<name>        executable entry point: shebang, require, exit — no logic
lib/<name>.rb     the module: adapters, orchestration, transformation, CLI
test/             one test_*.rb per subject, with fixtures/ and support/ as they earn their place
data/             local reference inputs; track only what belongs in the repository
output/           generated artifacts — gitignored, never committed
```

Name the output directory for the domain when a natural noun exists (`export/` for an exporter, `build/` for a compiler). Whatever the name, keep reference data and generated artifacts in separate directories so version control treats them differently. Pin the runtime with `.ruby-version` and keep development-only gems in a `:development` group.

## Principles

**Apply these principles proportionally**:

Derive the structure from the tool's contract not from a sibling project's shape: an exemplar demonstrates what is possible not what the script requires.

* Disposable one-off: keep the code simple; add only the safety needed for its inputs and effects.
* Maintained read-only utility: establish boundaries, deterministic output, tests, and a README.
* File-writing or remote-mutating tool: require planning, dry-run/apply separation, idempotency, and explicit recovery behaviour.

### 1. Give the script one clear job

Define its inputs, outputs, side effects, and exit statuses. Avoid hidden behaviour. Bulk operations, mutations, overwrites, and deletions should require explicit flags.

### 2. Separate concerns by reason to change

Use clear boundaries such as:

* `Client` — talks to an API;
* `Exporter` or `Runner` — decides what work to perform;
* `Renderer` — transforms data into output;
* `Writer` — handles filesystem effects;
* CLI code — parses options and reports results.

Do not split files merely because they are long. Split when a component can be tested or changed independently.

### 3. Keep external effects at the edges

Use a functional core and imperative shell. Network calls, environment variables, timestamps, and file writes should not be scattered through rendering or business logic.

Build environment-reading clients through a small factory (`Client.from_environment`) so the plain constructor accepts an injected transport and tests need no credentials.

### 4. Plan before applying

Any state-changing operation should have a planning phase and an application phase.

```
plan = runner.plan(...)
report(plan)
runner.apply(plan) unless options[:dry_run]
```

A dry run should use the real planning logic. It may read APIs and inspect files, but it must not write files, create directories, or call mutation endpoints.

Report actions such as:

```
Would create 2 files
Would update 3 files
Would leave 14 files unchanged
Would delete 0 files
```

For destructive or remote operations, make preview the default and require `--apply`. Keep `--dry-run` distinct from `--check`: a dry run previews work, while a check can return failure when drift or pending changes are found.

### 5. Make rerunning safe

Prefer idempotent behaviour:

* stable ordering;
* deterministic filenames;
* predictable output directories;
* unchanged files recognised as unchanged;
* atomic writes through temporary files and rename;
* deletion or pruning disabled unless explicitly requested.

### 6. Treat external services as unreliable

Handle timeouts, pagination, missing fields, authentication failures, and useful contextual errors. Retry only operations that are safe to repeat.

### 7. Keep dependencies deliberately boring

Prefer the standard library where adequate, a small number of focused gems, conventional Ruby syntax, and a committed `Gemfile.lock`. Avoid clever metaprogramming that makes maintenance harder.

### 8. Test transformations and safety

The normal test suite should not require a network connection. Test:

* option validation;
* representative rendered output;
* empty and missing data;
* pagination;
* filename edge cases;
* API failures;
* fixture-backed exports;
* dry runs that leave a temporary directory unchanged.

Golden-file tests are particularly useful for Markdown and YAML output.

### 9. Define failure atomicity

Decide whether partial output is acceptable, whether work should be staged and renamed into place, and whether a rerun resumes or rebuilds from scratch.

### 10. Treat quality checks as design signals

Run RuboCop and address findings deliberately; keep the configured baseline green unless a documented, narrowly scoped exception represents the better design.

### 11. Make the command pleasant to operate

Provide:

* `--help`;
* a useful success summary;
* concise errors on stderr;
* meaningful exit statuses, with usage errors distinct from runtime failures;
* optional `--verbose` or `--debug`;
* no secrets in logs;
* an explicit runtime secret boundary.

### 12. Document the behaviour

The README should include installation, safe and complete examples, output structure, authentication, mutation warnings, dry-run behaviour, and test commands.

## Choosing Ruby dependencies

Use the standard library and plain Ruby by default. Add a non-stdlib gem when it removes a recurring source of complexity, provides an important safety boundary, or establishes an existing project convention.

Hanakai’s Dry ecosystem is best treated as a menu of focused gems, not a framework to adopt wholesale. Its documented strengths—explicitness, composability, framework independence, and testability—fit these scripts well, provided each gem earns its place.

| Capability | Stay with stdlib or plain Ruby when… | Consider another tool when… |
| -- | -- | -- |
| HTTP | There is one simple request with no shared policy. | The client needs authentication, timeouts, retries, JSON handling, middleware, instrumentation, or interchangeable adapters. Use the project-standard Faraday consistently. Faraday’s main value is its common interface and middleware/adapter model. |
| Protocol-specific API | The endpoint is simple enough to call and parse directly. | The protocol has substantial semantics, such as GraphQL schemas, pagination, OAuth, or a cloud-provider API. Use a focused client such as Graphlient or an official SDK, behind a small local adapter. |
| CLI | The tool has one command and a modest number of options. Use `OptionParser`. | The tool has subcommands, reusable command objects, aliases, or complex help output. Consider `dry-cli`, which is designed for command registration, arguments, options, and subcommands. |
| Input validation | A few explicit guards make the rules obvious. | Inputs are nested, untrusted, reused across commands, or subject to cross-field rules. Consider `dry-schema` or `dry-validation`. |
| Data modelling | Hashes, `Struct`, or `Data` objects remain easy to understand. | Many fields are optional or nested, data crosses several boundaries, or invariants need to be enforced. Consider `dry-types` or `dry-struct`. |
| Workflow and errors | Exceptions and ordinary return values clearly express failure. | A workflow has several expected failure points and needs typed results or short-circuiting. Consider `dry-operation` or `dry-monads`; `dry-operation` models steps returning `Success` or `Failure`. |
| Dependency composition | Constructors and explicit dependency passing are sufficient. | The application has many components, providers, or replaceable implementations. Consider `dry-system` or `dry-auto-inject`, but do not introduce a container merely to avoid passing three dependencies. |
| Persistence | Files, JSON, YAML, CSV, or a small local format are adequate. | A datastore becomes a first-class part of the application, with queries, repositories, mappings, and controlled writes. Consider ROM. ROM is a persistence toolkit, not a general-purpose repository-pattern requirement. |
| Logging | `puts`, `warn`, and a concise summary are enough. | Logs need structured fields, multiple destinations, filtering, or integration with monitoring. Consider `dry-logger` or a similarly focused logging tool. |
| Retries | A single `rescue`/`retry` loop with a fixed count is clear. | Exponential backoff, jitter, or per-exception retry policies are needed. Use `retriable` (simple DSL, randomized exponential backoff, works for API *and* filesystem calls) or if already using Faraday, `faraday-retry` middleware handles HTTP-specific cases like `Retry-After` headers automatically. Don't add both — pick one layer. |
| HTTP test fixtures | A hand-written stub adapter at the client library's transport hook covers parsing, validation, and response unwrapping without new dependencies. |  `--dry-run` and the test suite need to replay real recorded HTTP traffic without network access. `VCR` records real interactions to cassettes and replays them deterministically; pair it with `WebMock` so any unstubbed request fails loudly instead of hitting the network. |
| CLI polish | `OptionParser` plus `puts`/`warn` covers help text, options, and summaries. | Richer terminal UX — coloured diffs for plan output, progress bars for pagination, formatted tables for a "would update N files" summary, interactive prompts for `--apply` confirmation. Use individual components from the TTY toolkit — `tty-prompt`, `tty-table`, `tty-progressbar`, `tty-command`, `pastel`. |

### Dependency decision rules

Before adding a gem, the agent should be able to answer:

1. What specific problem does this gem solve?
2. Why is the standard-library solution no longer clear?
3. Will the gem reduce total complexity after its concepts and setup are included?
4. Is it compatible with the project’s existing dependencies and Ruby version?
5. Can its behaviour be covered by focused tests?
6. Has the current documentation been checked for deprecations and version changes?
7. Has the reason for the dependency been recorded in the README or Gemfile comment where useful?

Prefer one focused gem over a broad framework. Add one capability at a time, update the lockfile, run the tests, and document the operational effect. Do not use an unfamiliar gem merely because it produces shorter code. Use it when it makes the script easier to read, safer to operate, or cheaper to maintain.

## Minimum standard

 1. One clearly stated purpose.
 2. Explicit CLI options and safe defaults.
 3. A separate pure transformation layer.
 4. External I/O behind small adapters.
 5. A plan/apply split for state-changing work.
 6. A truthful `--dry-run` mode when the command changes state.
 7. Deterministic, repeatable output.
 8. No network access in ordinary tests.
 9. Pinned runtime and dependencies.
10. Secrets supplied only at runtime.
11. A README with copyable commands.

> For the development workflow, baseline checks, test strategy, and characterisation / test-first decisions, use the Ruby process skill.
