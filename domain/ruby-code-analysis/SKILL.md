---
name: ruby-code-analysis
description: >
  Analyse, lint, refactor, or review Ruby source files using tree-sitter
  structural queries, Solargraph LSP, RuboCop linting, and Ruby idiomatic
  conventions. Invoke when working with .rb files and the task involves
  understanding structure, finding issues, refactoring, or writing/reviewing
  Ruby code.
---

## Overview

Four layers:
- **tree-sitter** via `ts-ruby.sh` — understand structure with syntax-aware structural analysis 
- **Solargraph LSP** — cross-file analysis of definitions, references, diagnostics
- **RuboCop** — surface offences with idiomatic linting and auto-correction
- **Ruby conventions** — apply idioms and design rules that static analysis alone won't enforce


1. `symbols` — orient: get every method/class/constant with exact line numbers
2. `calls` — trace: find every call site for a method across files
3. `errors` — validate: confirm no parse errors before refactoring
4. Only reach for `grep` if tree-sitter doesn't cover the query


## Workflow
- Always use tree-sitter before grep
- Always run from the project root: `cd ~/Me/00-system/tools/cli`

### 1. Map the unfamiliar file structure

```bash
ts-ruby.sh symbols <file.rb>
```

Captures: `@symbol.class`, `@symbol.module`, `@symbol.method`,
`@symbol.singleton_method`, `@symbol.constant`.

Use this output to orient all subsequent work. Never assume class or method
names — always confirm from the symbol map.

### 2. Check for parse errors

```bash
ts-ruby.sh errors <file.rb>
```

If `@syntax.error` or `@syntax.missing` captures appear, report them and
stop. Do not attempt refactoring on a file with parse errors.

### 3. LSP semantic analysis (as needed)

For cross-file navigation, type information, and diagnostics:

```bash
lsp-ruby.sh symbols <file.rb>
lsp-ruby.sh definition <file.rb> <line> <col>
lsp-ruby.sh references <file.rb> <line> <col>
lsp-ruby.sh diagnostics <file.rb>
```

**Important:** Run from the project root so Solargraph can find
`.solargraph.yml`. Line and column numbers are 0-indexed.

| Operation | Use case |
|---|---|
| `symbols` | Full document symbol list with kinds (class, method, constant, etc.) |
| `definition` | Go to definition — find where a method/class is defined |
| `references` | Find all usages across the codebase |
| `diagnostics` | RuboCop warnings and errors via LSP |

### 4. Lint with RuboCop

```bash
rubocop --format json <file.rb>
```

Use `--format json` so offences can be parsed programmatically.
For auto-correctable offences: `rubocop -A <file.rb>`.
Never run `-A` without confirming with the user first — it silently
modifies files.

### 5. Targeted structural queries (as needed)

| Goal | Query |
|---|---|
| Trace what a method calls | `calls` |
| Understand inheritance | `classes` |
| Find mixins (include/extend/prepend) | `modules` |
| Find all blocks / DSL callbacks | `blocks` |
| Map file dependencies | `requires` |

```bash
ts-ruby.sh <query_name> <file.rb>
```

### 6. Cross-file analysis

Use the batch scripts for cross-file queries. These accept multiple files
and produce TSV output suitable for piping through `column`, `sort`, or `uniq`.

**Find duplicated methods across files:**
```bash
ts-ruby-duplication lib/me/commands/*.rb
```
Output: `method_name  count  file1  file2  ...` sorted by count descending.
Use this to identify extraction candidates for shared modules.

**Trace a method's call sites across files:**
```bash
ts-ruby-calls <method_name> <file> [<file>...]
```
Output: `file  line  receiver  method`. Deduplicates receiver+method pairs
at the same line. Use this to find all callers before renaming or extracting.

**Map which files include which modules:**
```bash
ts-ruby-includes <file> [<file>...]
```
Output: `file  kind  module_name` (kind = include/extend/prepend).
Use this to understand the mixin dependency graph.

**Aggregate symbols across files:**
```bash
ts-ruby-symbols -k method <file> [<file>...]
```
Output: `file  line  kind  name`. Filter by kind with `-k`.
Use this to compare class structures or count methods per file.

**Cross-file definition/references (requires Solargraph):**
```bash
lsp-ruby.sh references <file.rb> <line> <col>
```

---

## Tree-sitter Queries

The `ts-ruby.sh` dispatcher calls `tree-sitter query ~/.forge/ts-queries/ruby/<name>.scm`.
Output lists captures as `@capture_name row col "text"` — parse on the
`@capture_name` prefix since multi-capture queries interleave results.

| Query file | Captures produced | Batch script |
|---|---|---|
| `symbols.scm` | `@symbol.method`, `@symbol.singleton_method`, `@symbol.class`, `@symbol.module`, `@symbol.constant` | `ts-ruby-symbols` |
| `errors.scm` | `@syntax.error`, `@syntax.missing` | `ts-ruby.sh errors` |
| `calls.scm` | `@call.receiver`, `@call.method` | `ts-ruby-calls` |
| `classes.scm` | `@class.name`, `@class.superclass` | — |
| `modules.scm` | `@mixin.type`, `@mixin.name` | `ts-ruby-includes` |
| `blocks.scm` | `@block.caller`, `@block.params`, `@lambda.params` | — |
| `requires.scm` | `@require.type`, `@require.path` | — |

Batch scripts (`ts-ruby-symbols`, `ts-ruby-calls`, `ts-ruby-includes`,
`ts-ruby-duplication`) are on PATH and accept multiple files.
They produce clean TSV output using `gawk` for parsing.

---

## Solargraph LSP

Solargraph provides deep semantic analysis that tree-sitter cannot:
- **Go to definition** — navigate to where a method/class is defined
- **Find references** — locate all usages across the codebase
- **Diagnostics** — real-time linting via LSP push notifications
- **Document symbols** — semantic symbol list with kinds

### Architecture

The LSP client is implemented in Python (`lsp-ruby.py`) because LSP requires
bidirectional JSON-RPC communication over stdin/stdout, which pure bash cannot
reliably handle. The Python script:
1. Spawns `solargraph stdio` as a subprocess
2. Performs the LSP handshake (initialize → initialized)
3. Opens the document (textDocument/didOpen)
4. Sends the request and reads the response
5. Exits cleanly

### Usage

```bash

# Document symbols (kinds: class, method, constant, etc.)
lsp-ruby.sh symbols lib/me/cli.rb

# Go to definition (0-indexed line/col)
lsp-ruby.sh definition lib/me/cli.rb 59 6

# Find all references
lsp-ruby.sh references lib/me/cli.rb 59 6

# Diagnostics (rubocop warnings/errors)
lsp-ruby.sh diagnostics lib/me/cli.rb
```

### Output format

**symbols:**
```
class                 CLI                                       line:1
method                run                                       line:59
constant              USAGE                                     line:2
```

**definition/references:**
```
lib/me/cli.rb:59:6
```

**diagnostics:**
```
info      line:0   Missing frozen string literal comment.
info      line:59  Cyclomatic complexity for `run` is too high. [25/7]
```

### Gotchas

- **Run from project root** — Solargraph uses `$(pwd)` as `rootUri` to find
  `.solargraph.yml` and understand the gem context.
- **Line numbers are 0-indexed** — subtract 1 from editor line numbers.
- **Cold start is slow** (~2–4 seconds) while Solargraph indexes gems.
- **Empty results are normal** — files with only `require_relative` statements
  have no symbols to report.
- **`bundle exec` is conditional** — only used if solargraph is in the Gemfile.

---

## Key Rules

### Ruby Idioms

**Truthiness**
- Never write `if x == true` or `if x == nil`. Use `if x` and `if x.nil?`.
- `unless` is valid for simple single conditions only — never `unless x && y`.
- `unless` with `else` is always wrong — convert to `if/else`.

**Strings**
- Prefer single-quoted strings unless interpolation or escape sequences are needed.
- Use `<<~HEREDOC` for multi-line strings.
- Add `# frozen_string_literal: true` at the top of every new file.

**Symbols vs strings**
- Hash keys should be symbols unless the key comes from external input:
  `{ name: 'Alice' }` not `{ 'name' => 'Alice' }`.

**Blocks**
- Use `{}` for single-line blocks, `do...end` for multi-line.
- Prefer `map`, `select`, `reject`, `find`, `each_with_object` over manual
  array building with loops.
- Use `&method(:foo)` to pass a method reference instead of a wrapper block.

**Guard clauses**
- Return early rather than nesting. A method's main logic should sit at one
  indent level, not wrapped in `if valid?`.

**Nil safety**
- Use `&.` instead of `x && x.foo` or ActiveSupport's `x.try(:foo)`.

**Naming**
- Boolean methods use `?` suffix: `valid?`, `active?` — not `is_valid`, `check_active`.
- `!` suffix is for methods that mutate in place or raise on failure: `save!`, `map!`.

**Class design (Sandi Metz rules — treat as strong defaults)**
- Classes ≤ 100 lines.
- Methods ≤ 5 lines.
- Methods accept ≤ 4 parameters; use keyword args or a value object beyond that.

---

### Testing (RSpec)

When reviewing or writing specs:

- Top-level describe is always `RSpec.describe ClassName`, not bare `describe`.
- Class methods described as `.method_name`; instance methods as `#method_name`.
- Use `context` for branching scenarios: `context "when user is admin"`.
- Use `let` / `let!` over instance variables in `before` blocks.
- One expectation per example unless using `aggregate_failures`.
- Avoid `allow_any_instance_of` — it signals a design smell; refactor instead.
- FactoryBot factories over fixtures; keep factories minimal and use `trait` for variants.

---

## Gotchas

- `rubocop --format json` exits with code 1 even when all offences are
  auto-correctable. A non-zero exit is not a hard failure.
- `rubocop -A` silently modifies files. Always warn the user before running
  it; never chain it with a subsequent `read` expecting the original content.
- Singleton methods (`def self.foo`) are separate tree-sitter nodes from
  instance methods — distinguish them by `@symbol.singleton_method` vs
  `@symbol.method` in query output, not by text inspection.
- String interpolation in the Ruby grammar is a `string` node containing
  `interpolation` children — do not treat the full node text as a literal
  string value when a capture includes it.
- Solargraph LSP responses may take 2–4 seconds on cold start while indexing.
- Solargraph requires running from the project root to find `.solargraph.yml`.

---

## References

Load these only if deeper detail is needed for a specific task:

- RuboCop configuration: https://docs.rubocop.org/rubocop/latest/configuration.html
- Ruby style guide: https://rubystyle.guide
- BetterSpecs (RSpec): https://www.betterspecs.org
- tree-sitter query syntax: https://tree-sitter.github.io/tree-sitter/using-parsers/queries/1-syntax.html
- Solargraph guide: https://solargraph.org/guides/language-server
