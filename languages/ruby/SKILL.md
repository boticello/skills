---
name: ruby
description: Use when creating, repairing, refactoring, or reviewing Ruby scripts, CLIs, gems, or tests. Guides project discovery, Bundler and runtime setup, baseline syntax/tests/quality checks, characterization versus test-first development, proportionate fixture-backed coverage, interpretation of RuboCop and Reek as design signals, and safe CLI verification. Pair with the Ruby program design principles for design conventions.
---

# Ruby development process

This skill governs **what to do when** during Ruby work. Use the [Ruby program design](ruby-program-design.md) guide for architectural principles; use this skill for sequencing, test strategy, quality checks, and verification.

## Operating stance

Keep engineering proportional to the script’s risk and expected lifetime.

- Start with the smallest clear design that meets the actual contract.
- Treat linters, smell detectors, and coverage reports as evidence and design pressure, not as automatic instructions to contort code around a number.
- When a check reports something, classify it before changing anything:
  1. **Defect or safety risk** — fix the source code.
  2. **Useful design pressure** — refactor, or consciously accept the pressure at a documented edge.
  3. **Representation false positive** — configure the check narrowly or use a local, explained exception.
  4. **Policy mismatch** — change the project configuration and record why.
- Never silence a check broadly just to obtain a green run. A green suite is evidence, not proof that the behavior is fully covered.

## Workflow

Follow these stages in order. Keep the loop short for small changes, but do not skip discovery or baseline verification merely because the script is small.

### 1. Discover the project before editing

Read the local instructions and project artifacts that determine the workflow:

- `AGENTS.md` or equivalent repository guidance;
- `README.md` and usage examples;
- `Gemfile`, `Gemfile.lock`, `.ruby-version`, or other runtime declarations;
- `Rakefile` and existing test/quality configuration;
- the entrypoint and nearby tests;
- existing issue or task records when the project uses them.

Determine:

- the supported Ruby version;
- whether Bundler is required;
- the existing test framework and naming conventions;
- how RuboCop, Reek, coverage, and smoke checks are invoked;
- whether credentials are supplied through a project-specific runtime boundary;
- whether the command is read-only, writes files, or mutates a remote service.

Reuse the project’s existing conventions. Do not introduce RSpec, a new task runner, or a new framework merely because it is familiar.

### 2. Establish the environment

Use the project’s locked dependencies and runtime. Check the environment before changing code:

```bash
ruby --version
bundle check
```

If dependencies are missing, install them through the project’s normal Bundler workflow and preserve the lockfile. Use `bundle exec` for tests, linters, and project commands whenever the project requires it.

Do not load secrets into source files, fixtures, command output, or committed environment files. Preserve the project’s explicit secret boundary, such as an `op-env` wrapper, and keep ordinary tests network-free.

When planned work depends on an external credential, validate the key early with a read-only probe that prints status codes only, never values. Where a default depends on an external service — model, tier, endpoint — choose it based on measured realistic use.

When adding a gem, first establish the concrete problem it solves and why the
standard library or an existing dependency is no longer clear. Check current
documentation, add one capability at a time, update the lockfile, and verify
the operational effect.

For a locked external library, establish both contracts before coding:

1. Read the nearest local precedent for project-specific credentials, endpoints,
   and runtime conventions.
2. Inspect the lockfile and installed or vendored source for the exact methods,
   configuration defaults, and middleware that will run.
3. Read documentation matching the locked version when available. Current web
   documentation is context; it does not override the dependency in the lock.

### 3. Establish a baseline before editing

Run the narrowest useful baseline checks:

```bash
ruby -c path/to/changed_file.rb
bundle exec ruby -Itest path/to/test_file.rb
```

Then run the project’s configured quality task if one exists, for example:

```bash
rake quality
```

Record which failures predate the change. Distinguish parser failures, failing behavior tests, quality findings, missing dependencies, and missing credentials. Do not treat a pre-existing failure as evidence that the proposed change caused it.

For a reported bug, reproduce it before editing. For an existing script being refactored, capture representative behavior before rearranging the implementation.

### 4. Define the observable contract

Before choosing tests or abstractions, write down the behavior that matters:

- inputs and option combinations;
- outputs, files, records, or remote calls;
- stdout, stderr, and exit statuses;
- safe defaults and explicitly dangerous operations;
- authentication and failure behavior;
- the exact data crossing each remote boundary, including local identifiers,
  paths, and content that must not leave the machine;
- ordering, naming, idempotency, and rerun expectations;
- dry-run versus check versus apply semantics, where applicable.

Separate external effects from deterministic decisions where the boundary is real. Typical boundaries are:

```text
CLI parsing → use-case selection → API/filesystem adapters → normalized data → pure transformation
```

Do not split files merely because they are long. Split when a component has a distinct reason to change or can be tested independently.

For state-changing work, plan before applying:

```ruby
plan = runner.plan(options)
report(plan)
runner.apply(plan) unless options[:dry_run]
```

A dry run must use the real planning logic and must not write files, create directories, or call mutation endpoints.

### 5. Choose the test strategy deliberately

Use the strategy that matches the code’s history and the change’s intent.

#### Existing behavior or legacy code: characterize first

When the implementation already exists, write characterization tests before refactoring it. Capture the behavior that must not change, even if the current behavior may later be questioned. Then refactor behind those tests.

These tests are not a failure of test-driven development; they are the correct way to create a safety net around behavior that already exists.

#### New behavior or policy: test first

For a new option, selection rule, output contract, validation rule, pagination policy, or error behavior:

1. Write a failing test describing the observable scenario and expected result.
2. Implement the smallest change that makes it pass.
3. Refactor while keeping the test green.
4. Add boundary and failure cases when the policy is stable.

#### Pure refactoring: preserve first, then simplify

Run the existing tests before changing structure. Do not add speculative abstractions or tests that assert private implementation details. Add a test only when the refactor reveals an unprotected observable contract.

#### Exploratory one-off work

For a disposable experiment, a small implementation-first slice can be reasonable. Before promoting it into a maintained script, capture the contract, add proportionate tests, and establish the normal quality command.

### 6. Build proportionate coverage

Do not optimize for a universal percentage. Cover risks and contracts instead of every line or helper method.

For a small Ruby CLI, the normal baseline is:

| Area | Proportionate coverage |
| --- | --- |
| Pure transformation | One representative output plus meaningful empty, missing, or malformed input where relevant |
| Selection and validation | Each important policy branch and its invalid/error case |
| External adapter | Fixture-backed responses for pagination, missing fields, and important failures |
| Filesystem effects | A temporary-directory test for created or changed artifacts; rerun/idempotency if promised |
| CLI behavior | Help, safe defaults, important option combinations, stdout/stderr, and exit status |
| Destructive or remote behavior | Plan/dry-run behavior separately from apply; live tests gated and explicit |

Use behavior-oriented assertions. A rendered-document test may assert several sections when they are all part of one output contract; split it only when a failure would otherwise be hard to interpret.

Avoid:

- a test for every trivial private helper;
- tests that only prove a mock was called;
- broad mocks that reproduce the implementation instead of the external contract;
- network access or credentials in ordinary tests;
- adding a live end-to-end test when a deterministic fixture tests the same decision;
- adding tests solely to satisfy an arbitrary coverage percentage.

Prefer small fakes or fixture-backed adapters for the program's own boundaries.
If a constructor reads the environment and creates a network client, separate
those concerns so tests can inject a fake transport without requiring a
credential:

```ruby
Client.from_environment
Client.new(graphql_client: fake)
```

For a locked client library, do not reproduce its fluent or configuration API
in a fake. Construct the real locked client and replace only its terminal HTTP
transport. Assert the outgoing payload, attempt count, failure translation, and
declared outbound-data boundary. Verify any remaining fake's promise against
the installed dependency source before relying on it.

For GraphQL or other protocol clients, fixtures should exercise the adapter's real pagination and normalization logic. If the client library parses or validates queries, supply a local schema fixture so the offline suite still catches contract drift such as a mistyped field name. Stub the transport rather than the client library, route responses by operation, and record requests so cursor follow-ups can be asserted. Expect the library to transform what crosses the boundary — stringified variable keys, renamed operations; a hanging pagination test usually means the stubbed pages never terminate. Keep an optional live smoke test outside the default suite and run it through the project's explicit credential boundary.

### 7. Implement in small verified steps

For each behavior change:

1. change the test or contract first when using test-first development;
2. make the smallest source change;
3. run the focused test;
4. inspect the output and failure message;
5. refactor only after behavior is green.

Keep network calls, environment reads, timestamps, and file writes at the edges. Pass dependencies explicitly when that creates a genuine testing or composition seam; do not introduce a container or framework to avoid passing a small number of dependencies.

After a structural code change, run the project’s required Reek/RuboCop/tests before continuing. Do not let a formatting or smell pass become the design objective.

### 8. Interpret quality checks as design review

Run the project’s configured checks in their intended order. Then review the findings rather than applying automatic fixes blindly.

#### RuboCop

Use complexity thresholds as budgets for behavioral complexity. Keep them strict for control flow. If a method is mostly a declarative hash, array, or heredoc, prefer `CountAsOne` configuration over globally raising thresholds. If a schema projection remains above ABC because the metric counts fields as assignments, use meaningful extraction or a narrowly scoped suppression with a reason. Prefer the narrowest scope that covers the finding — a directive around a single method or signature, closed on the next line — over file-wide disables.

Always close local `rubocop:disable` directives. A missing `rubocop:enable` can hide unrelated offenses later in the file.

#### Reek

Keep detectors enabled when they expose a real design risk. Disable a detector only for a recurring, documented boundary pattern, such as nullable API data or deliberately small formatting helpers. Use the narrowest scope that fixes the finding: an inline directive on the affected method beats disabling the detector project-wide. Re-enable detectors that become useful as the design changes.

A class at the configured edge is valuable. Do not split a cohesive class merely to avoid a warning; either accept the documented edge or split when the responsibilities have genuinely diverged. Conversely, do not raise every threshold until the warning disappears.

#### Check conflicts

When tools disagree, choose the clearest project policy and configure it explicitly. For example, if one tool prefers a short conventional rescue variable and another prefers a descriptive name, set the preferred name rather than changing good code back and forth.

### 9. Exercise the command, not only its tests

Before declaring a CLI complete, run the real bundled command through safe paths:

- `--help`;
- no-argument or safe-default behavior;
- a fixture or temporary-directory export;
- invalid input and missing-credential behavior;
- dry-run behavior, if supported.

Check the command's own exit status — not one observed through a pipe or a later command — plus stdout, stderr, file layout, stable names, and the absence of secrets in output. Run a live remote operation only when the user’s explicit runtime credential boundary is available and the operation is safe and intended.

### 10. Finish the project-facing work

Before delivering:

- run the complete configured quality/test command;
- verify all affected callers, tests, and documentation;
- update README usage when command behavior or setup changed;
- record dependency or operational decisions where maintainers will need them;
- remove temporary fixtures, debug output, and scaffolding;
- report exactly what was exercised and what was not, especially live API paths.

## Completion checklist

A Ruby script or CLI is ready when:

- its purpose, inputs, effects, and exit behavior are explicit;
- the project’s runtime and Bundler environment are reproducible;
- ordinary tests require no network or secret;
- existing behavior is characterized before risky refactors;
- new behavior was developed test-first where that clarified the contract;
- tests cover the important normal, boundary, error, external, and side-effect paths proportionately;
- external services are behind small testable adapters;
- quality findings were classified and handled deliberately;
- quality thresholds and local exceptions have reasons;
- the actual command was smoke-tested through safe paths;
- the README and final evidence are truthful.
