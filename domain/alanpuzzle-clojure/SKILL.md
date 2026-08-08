---
name: alanpuzzle-clojure
description: >-
  Work with the alan-puzzle Clojure tooling — the REPL over the Kotlin domain
  model (pools, verdicts, the facade), the datalevin run index, E18 probes,
  and verifying generated books from Clojure. Routes the tooling: clojure-lsp
  for symbols, nREPL eval for domain questions, structural-edit fallbacks,
  cbm for the code graph, ken for text search. Use whenever the task involves
  clojure in this repo, the nREPL, datalevin, the run index, or "probe the
  domain" questions. Leads with the REPL-first discipline: hypothesis → one
  form → oracle check.
triggers:
  - clojure
  - nrepl
  - datalevin
  - run-index
  - pools
  - verdict
  - facade
  - E18
  - repl
  - clojure-lsp
---

# alan-puzzle Clojure tooling

Operating rules for the Clojure layer over the Kotlin puzzle engine. The
reference tier is the repo itself: `deps.edn`, `kotlin/src/ClojureApi.kt`,
`clojure-src/src/alanpuzzle/{repl,run_index,nrepl_server}.clj`.

## Tool routing

| Job | Tool | Notes |
|---|---|---|
| Symbol ops: definition, references, rename, hover, file symbols | clojure-lsp via the `lsp` device | Lazily spawned — first request pays startup. Cross-file definition and references work (e.g. `user.clj` → `repl.clj`). |
| Domain questions, what-ifs, oracle checks | nREPL via `clojure_eval` | Helpers (`counts`, `verdict`, `pool`, `sample`, `overlap`, `verify-pools`, …) are in scope in `user`. |
| Structural edits (`.clj`/`.cljc`/`.edn`) | `clojure_edit` (top-level forms), `clojure_edit_replace_sexp`, `paren_repair` | Fallbacks only — try the built-in `edit` first. Project-scoped: paths outside the repo root are rejected; stage copies of such files inside the repo. |
| Classpath / dependency-jar inspection | `deps_list`, `deps_grep`, `deps_read` | Runs against the connected server's classpath. |
| Code graph: callers, callees, structure | cbm `query_graph` / `search_graph` | Index the repo first (`index_repository`) if it isn't; Clojure defns are `Function` nodes with `CALLS` edges — but resolution is name-level (noise like `apply`/`get`), so verify high-impact findings against source. Index removable via `delete_project`. |
| Semantic search over Clojure text | ken `search` (hybrid) | File-level snippets only. ken has **no Clojure extractor** — `outline`/`definition`/`callers` reject `.clj`; use it for discovery, not structure. |
| Exact strings, literals, config | `grep` / `glob` | Fallback for anything the above can't reach. |
| Cross code + docs exploration | Morph — unavailable | `401`; do not route here until auth is fixed. |

**nREPL ports.** Discover, never hardcode: the documented alias server runs
on the port fixed in `deps.edn` (`:nrepl` alias); clojure-mcp's default
connection follows `.nrepl-port`; anything else live shows up in
`list_nrepl_ports`. Servers, worktrees and ad-hoc ports come and go — treat
the current set as unknown until you look. When the classpath matters
(datalevin on it or not), pass `port` explicitly. Restart the server after
editing `user.clj`/`repl.clj` — stale servers carry stale helpers and
classpaths.

## REPL-first: the working method

1. **Start the REPL before writing code.** If the tools cannot reach the code,
   fix the environment first — workarounds cost more than the fix and breed
   the bad habits.
2. **Every assumption becomes one form.** Never simulate Lisp mentally:
   threading (`some->` inserts threaded values FIRST — `(some-> x (f a))` is
   `(f x a)`), keyword namespaces (`:red/blue-first` — the slash makes `red`
   the namespace, `(name …)` returns only `blue-first`), seq-vs-map, laziness —
   this is where plausible-but-wrong reads live.
3. **Every computation has an oracle.** Name the referee before writing the
   form: `verification.txt` E18 tables (presented / descending-power /
   red-blue-first), `stage-deltas.csv`, `sheet-summary.csv`, `book.csv`
   hashes, the facade pools. Reconcile, don't trust. Neither side of a
   reconciliation is privileged — validate the comparison harness itself
   before blaming either side: BSD `grep` treats unescaped parens as regex
   groups (use `grep -F` for literals), `grep -A n` context leaks into the
   next section, and for CSV extraction use `qsv`
   (`qsv select <col> f.csv | qsv frequency`), not awk field games.
4. **Grep the Kotlin before reimplementing semantics:** `Criteria.kt`
   (`allMath`, `presentedOrder`), `ConstructionChecks.kt` (the E18 order
   definitions), `Verifier.kt` (`classify`). Deriving from memory is how
   grid-dependent orders get hardcoded.

## Domain model surface

- `kotlin/src/ClojureApi.kt` — the only unmangled interop surface (`@JvmName`,
  raw-int signatures). Never reimplement domain logic; call the facade or the
  exported files.
- `repl.clj` helpers — cached `pools`, `pool`, `pool-set`, `member?`, `counts`,
  `verdict`, `overlap`, `eliminators`, `survivors-eliminated-by`. Use
  `pool-sets` (cached) rather than `pool-set` inside loops — rebuilding a
  450k-element set per iteration is quadratic.
- Domain gates: `clojure-src/test/alanpuzzle/domain_gates_test.clj`
  (`just test-clj`). When Alan's rule set changes, update the derivation, the
  interactive `verify-pools`, and the gate tests in one change.

## E18 orders (exact definitions)

- **Presented**: `Criteria.kt` `presentedOrder` — fixed.
- **red/blue-first**: `[Red Blue Mint] + rest in presented order` — fixed
  (`ConstructionChecks.redBlueFirstOrder`).
- **descending-power**: COMPUTED PER RUN
  (`ConstructionChecks.descendingPowerOrder`): math rules ranked by pool size,
  positional rules by their independent elimination count in that book, ties
  by presented index. Never hardcode it.
- **First-in-order** for a cell = `(some (set eliminatedBy) order)` — the
  first eliminator IN the order, not the first in the `eliminatedBy` list. The
  wrong version survives whole-pipeline runs because it looks plausible.

## Run index and datalevin

The run index lives in the main tree: `clojure-src/src/alanpuzzle/run_index.clj`,
store at `run-index/`, driven by `clojure -M:index -- rebuild|status|ingest`
(the `:index` alias; ingest is an alias of status). The gotchas below are
version-sensitive — the pinned datalevin version lives in `deps.edn`.

- `d/q` takes a DB, not a conn: `(d/q query (d/db conn) …)`.
- `d/fulltext-datoms` returns plain vectors `[e a v]` (use `(first …)` for the
  entity id); Datom records are a `deftype` — keyword access (`:e`) returns nil.
- `d/transact!` is synchronous; `d/transact` is the async variant.
- `create-conn` with `{}` schema on an existing DB is DESTRUCTIVE (observed
  entity loss). Always pass the full schema.

## CLI quirks

- `clojure -M` positionals are load-files, not main args; use `-M -m ns` to
  pass args, and note `--` arrives as a literal argument — tolerate a leading
  `--` in `-main`.
- clojure-mcp structural tools are sandboxed to the repo root: files outside
  it need a staged copy inside the repo, or the server's
  `:allowed-directories` extended.

## Gotchas

- `counts` is 0-arity (`(counts)`); `verdict` is 1-arity (`(verdict 300001)`).
- LSP servers spawn lazily — a first request may take a moment.
- Two nREPL servers can run in the same tree with different classpaths; check
  `.nrepl-port` / `list_nrepl_ports` before trusting the default connection.

## Related

- `analysis/clojure-repl-retrospective.md` — the narrative behind these rules.
- Project scope: deployed from `~/Me/repos/skills/domain/alanpuzzle-clojure/`,
  listed in `.agents/skills-manifest.toml`.
