---
name: alanpuzzle-clojure
description: >-
  Work with the alan-puzzle Clojure tooling — the REPL over the Kotlin domain
  model (pools, verdicts, the facade), the datalevin run index, E18 probes, and
  verifying generated books from Clojure. Use whenever the task involves
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
---

# alan-puzzle Clojure tooling

Operating rules for the Clojure layer over the Kotlin puzzle engine. The
reference tier is the repo itself: `deps.edn`, `kotlin/src/ClojureApi.kt`,
`clojure-src/src/alanpuzzle/repl.clj`, `clojure-src/src/alanpuzzle/run_index.clj`
(spike branch `feat/datalevin-spike`), `analysis/clojure-repl-retrospective.md`.
Read the retro once — it explains why these rules exist.

## REPL-first: the working method, not an optional extra

1. **Start the REPL before writing code.** Main tree: nREPL 7888 (clojure-mcp target;
   sandbox = repo root). Worktree/spike: `clojure -M:spike-server` (7889) plus an
   interactive `clojure -M:spike-nrepl` client, supervised via hub (send forms, read
   logs). If the tools cannot reach the code, fix the environment first — workarounds
   cost more than the fix and breed the bad habits.
2. **Every assumption becomes one form.** Never simulate Lisp mentally: threading
   (`some->` inserts threaded values FIRST — `(some-> x (f a))` is `(f x a)`), keyword
   namespaces (`:red/blue-first` — the slash makes `red` the namespace, `(name …)`
   returns only `blue-first`), seq-vs-map, laziness — this is where plausible-but-wrong
   reads live.
3. **Every computation has an oracle.** Name the referee before writing the form:
   `verification.txt` E18 tables (presented / descending-power / red-blue-first),
   `stage-deltas.csv`, `sheet-summary.csv`, `book.csv` hashes, the facade pools.
   Reconcile, don't trust. A number that matches an independent aggregate is done.
   Neither side of a reconciliation is privileged — validate the comparison harness
   itself before blaming either side: BSD `grep` treats unescaped parens as regex
   groups (use `grep -F` for literals), `grep -A n` context leaks into the next
   section, and for CSV extraction use `qsv` (`qsv select <col> f.csv | qsv frequency`),
   not awk field games.
4. **Grep the Kotlin before reimplementing semantics:** `Criteria.kt` (`allMath`,
   `presentedOrder`), `ConstructionChecks.kt` (the E18 order definitions),
   `Verifier.kt` (`classify`). Deriving from memory is how grid-dependent orders get
   hardcoded.

## Domain model surface

- `kotlin/src/ClojureApi.kt` — the only unmangled interop surface (`@JvmName`, raw-int
  signatures). Never reimplement domain logic; call the facade or the exported files.
- `repl.clj` helpers — cached `pools`, `pool`, `pool-set`, `member?`, `counts`,
  `verdict`, `overlap`, `eliminators`, `survivors-eliminated-by`. Use `pool-sets`
  (cached) rather than `pool-set` inside loops — rebuilding a 450k-element set per
  iteration is quadratic.
- Domain gates: `clojure-src/test/alanpuzzle/domain_gates_test.clj` (`just test-clj`).
  When Alan's rule set changes, update the derivation, the interactive `verify-pools`,
  and the gate tests in one change.

## E18 orders (exact definitions)

- **Presented**: `Criteria.kt` `presentedOrder` — fixed.
- **red/blue-first**: `[Red Blue Mint] + rest in presented order` — fixed
  (`ConstructionChecks.redBlueFirstOrder`).
- **descending-power**: COMPUTED PER RUN (`ConstructionChecks.descendingPowerOrder`):
  math rules ranked by pool size, positional rules by their independent elimination
  count in that book, ties by presented index. Never hardcode it.
- **First-in-order** for a cell = `(some (set eliminatedBy) order)` — the first
  eliminator IN the order, not the first in the `eliminatedBy` list. The wrong version
  survives whole-pipeline runs because it looks plausible.

## Datalevin 1.0.0 gotchas (the run index)

- `d/q` takes a DB, not a conn: `(d/q query (d/db conn) …)`.
- `d/fulltext-datoms` returns plain vectors `[e a v]` (use `(first …)` for the entity
  id); Datom records are a `deftype` — keyword access (`:e`) returns nil.
- `d/transact!` is synchronous; `d/transact` is the async variant.
- `create-conn` with `{}` schema on an existing DB is DESTRUCTIVE (observed entity
  loss). Always pass the full schema.
- Scale: ingest ≈5 s per 50,000-cell run; E18 reconcile (3 orders) ≈375 ms; pairwise
  diffs (21 pairs × 50k cells) ≈1 s; DB ≈224 MB with fulltext (index `run.log` only if
  size matters).
- Spike evidence and decisions: `spike/decision.md` on `feat/datalevin-spike`
  (worktree `../alan-puzzle-datalevin-spike`).

## CLI quirks

- `clojure -M` positionals are load-files, not main args; use `-M -m ns` to pass args,
  and note `--` arrives as a literal argument — tolerate a leading `--` in `-main`.
- clojure-mcp structural tools (`clojure_edit`, `clojure_edit_replace_sexp`,
  `paren_repair`) are sandboxed to the repo root: worktree files need a staged copy
  inside the repo, or the server's `:allowed-directories` extended.

## Related

- `analysis/clojure-repl-retrospective.md` — the narrative behind these rules.
- The `br` cheatsheet — ticket discipline; the run-database work is
  `puzzle-kotlin-bdcz.*`.
