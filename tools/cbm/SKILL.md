---
name: cbm
description: Use codebase-memory-mcp for structural code queries — call tracing, Cypher graph queries, dead-code analysis, architecture overviews, and schema discovery. Load this skill before using any cbm tool. Covers all 14 tools, 7 confirmed gotchas in v0.8.1, Cypher patterns, and language-specific guidance (Python works, C does not).
---

# codebase-memory-mcp — Agent Usage Guide

This skill encodes everything learned from empirical evaluation of cbm 0.8.1
against a 1,346-file Python codebase (fast-agent) and a 1,304-file C codebase
(codebase-memory-mcp itself). See `dotfiles/RECOMMENDED-CODE-STACK.md` for the
full stack context.

## When to Use cbm (vs. Ken vs. Morph)

cbm is for **structural** questions. Ken is for **natural-language** questions.
Morph is for **deep cross-cutting exploration** when both fail.

```
Question type                              → Tool
─────────────────────────────────────────────────────
"How does X work?" (conceptual)            → Ken search
"Where is X defined?" (terse lookup)       → Ken definition
"Who calls X?" (method-level, type-resolved) → cbm trace_path (Python only)
"What does X call?" (outbound callees)     → cbm trace_path (Python only)
"Find all classes / decorators / routes"   → cbm search_graph(label=...)
"What's the inheritance hierarchy?"        → cbm query_graph (Cypher)
"What code is dead?" (no callers)          → cbm query_graph (Cypher)
"What are the main architectural modules?" → cbm get_architecture
"What nodes/edges are available?"          → cbm get_graph_schema
"Trace every path from entry to DB"        → Morph codebase_search
"Find all lines matching a pattern"        → ugrep or cbm search_code
"Recent git changes?"                      → Ken recently_changed
```

**Before querying anything: index the project first.** Unlike Ken, cbm does not
auto-index. Call `index_repository(repo_path="/absolute/path", mode="full")`.

## Quick Reference

| What you want | cbm tool | Key args | Fallback |
|---------------|----------|----------|----------|
| Index a project | `index_repository` | `repo_path`, `mode` ("full"/"moderate"/"fast") | — |
| List indexed projects | `list_projects` | none | — |
| Check index status | `index_status` | `project` | — |
| Search by name/pattern | `search_graph` | `query` (BM25) or `name_pattern` (regex), `label`, `file_pattern` | Ken `search` |
| Trace callers/callees | `trace_path` | `function_name` (bare), `direction` ("inbound"/"outbound"/"both"), `depth` | Ken `callers` |
| Find path A→B | `query_graph` | `query` (Cypher) | — |
| Read symbol source | `get_code_snippet` | `qualified_name` (full FQN or suffix) | Ken `definition` |
| Architecture overview | `get_architecture` | `project`, optional `aspects` | — |
| Graph schema | `get_graph_schema` | `project` | — |
| Text grep in indexed files | `search_code` | `pattern`, `regex` (default false!), `path_filter` (regex) | ugrep |
| Git diff impact | `detect_changes` | `project`, `since` | **Broken in 0.8.1 — use Ken `recently_changed`** |
| ADR management | `manage_adr` | `project`, `mode` ("get"/"update"/"sections") | — |
| Runtime trace ingestion | `ingest_traces` | `traces` (array) | — |
| Delete a project | `delete_project` | `project` | — |

## Critical Usage Notes

### 1. Project Identifier

`project` is an auto-derived dash-form name from the filesystem path.
`list_projects` returns it (e.g. `Users-bear-Me-scratch-cbm-eval-fast-agent`).
**Never guess.** Call `list_projects` first if unsure.

### 2. Index Before Querying

cbm does NOT auto-index. On first opening a project:

```
1. index_repository(repo_path="/absolute/path", mode="full")
2. list_projects  → note the project name
3. get_graph_schema(project="...")  → verify CALLS edge count > 0
```

Indexing modes: `full` (all files + similarity/semantic edges), `moderate`
(filtered files + similarity/semantic), `fast` (filtered files, no similarity).
All modes run type-aware LSP call/usage resolution. Default to `full`.

### 3. get_code_snippet — Two-Step When Ambiguous

The arg is `qualified_name` (full FQN). Suffix matching works for unique symbols.
Bare names return 2+ candidates when ambiguous.

**Reliable pattern:**
```
1. search_graph(query="FastAgent", label="Class")   → find the FQN
2. get_code_snippet(qualified_name="...FastAgent")  → read the source
```

For terse lookup, prefer Ken's `definition` (1 call, 67 bytes, no FQN needed).

### 4. trace_path — Bare Function Name Only

`trace_path(function_name="X", direction="inbound"|"outbound"|"both")`.

**"Bare" means no class prefix and no module path.**
- `function_name="cbm_pipeline_run"` ✓
- `function_name="FastAgent.__init__"` ✗ (returns "function not found")

For methods: use the bare method name if unique, or Cypher.
`__init__` alone returns all `__init__` methods — too broad.

`trace_path(target_name="Y", depth=N)` returns a **BFS neighborhood, not a
connecting path.** For real path-finding between symbols, use `query_graph`.

### 5. search_graph — Three Independent Modes

- `query="..."` — BM25 full-text (default). Works for identifier/docstring matches.
  CamelCase tokens are split: `updateCloudClient` → matches `update`, `cloud`, `client`.
- `name_pattern=".*regex.*"` — regex on symbol name. **Ignored if `query` is also set.**
- `semantic_query=["kw1","kw2"]` — **broken in 0.8.1.** Use Ken `search` instead.
- `label="Class"|"Function"|"Method"|"Decorator"|"Route"|"Variable"|...` — filter by node type.
- `file_pattern="*.py"` — glob on file path.
- `min_degree=N` — structural importance filter. `min_degree=5` for "hot functions."
- `exclude_entry_points=true`, `include_connected=true` — both useful.
- `limit` (default 200), `offset` — pagination. Response carries `total` and `has_more`.

Results are boosted: Functions/Methods +10, Routes +8, Classes/Interfaces +5.
Noise labels (File/Folder/Module/Variable) are filtered out.

### 6. search_code — Graph-Augmented Grep

Returns the *containing function* per match with structural metadata.

- **`regex` defaults to `false`.** `|`, `(`, `)` are matched *literally* unless
  `regex: true` is passed. cbm warns for `|` but not for `(` or `)`.
- **`path_filter` is a regex**, not a glob. Use `\\.py$`, not `*.py`.
- **`mode`**: `compact` (default, signatures only — token efficient), `full`
  (with source), `files` (paths only).
- **`limit` defaults to 10.** Response carries `total_grep_matches` (raw grep hit
  count) and `total_results` (deduplicated function count). If they differ, you're
  being truncated — raise `limit` or narrow with `path_filter`.

### 7. query_graph — Cypher Specifics

Cypher keywords are **case-sensitive — use UPPERCASE.**
`MATCH`, `WHERE`, `RETURN`, `ENDS WITH`, `CONTAINS`, `NOT EXISTS`, `LIMIT`.

- **Use `qualified_name` for partial matches:**
  `WHERE m.qualified_name ENDS WITH ".FastAgent.__init__"` works.
  `WHERE m.name = "Agent.run"` does not.
- **`n.label` is a string property, not a Cypher label matcher.**
  Use `MATCH (n:Function)`, not `WHERE n.label = "Function"`.
- **`NOT EXISTS { ()-[:CALLS]->(f) }`** is the correct pattern for "no callers."
- **`MATCH (f)-[:IMPORTS]->(m:Module)` is a no-op** — IMPORTS edges use a
  different orientation. Check `get_graph_schema` first.
- **`UNION` / `UNION ALL` supported.** `WITH … WHERE` supported.
- **No `MERGE`, `CREATE`, `DELETE`** — read-only subset.

### 8. get_architecture — Large Response

Returns Leiden communities (clusters over the call/import graph), node/edge counts,
languages, packages, entry points, routes, hotspots, and a file tree. Response is
~17 KB on a midsize Python repo, up to 60 KB on larger repos. Reserve for genuine
"give me the architectural overview" queries.

## Cypher Pattern Library

Copy-paste templates for common structural questions.

### Dead code (functions with no callers, excluding tests and entry points)

```cypher
MATCH (f:Function)
WHERE f.is_test = false AND f.is_entry_point = false
AND NOT EXISTS { ()-[:CALLS]->(f) }
RETURN f.qualified_name, f.file_path
LIMIT 20
```

### Inheritance hierarchy

```cypher
MATCH (c:Class)-[:INHERITS]->(parent:Class)
RETURN c.name AS child, parent.name AS parent
```

### Complexity hot-spots (methods with high complexity, ranked)

```cypher
MATCH (m:Method)-[r:CALLS]->(other)
WHERE m.complexity >= 5
RETURN m.qualified_name, m.complexity, count(r) AS calls_out
ORDER BY m.complexity DESC
LIMIT 10
```

### Callees of a specific method

```cypher
MATCH (a:Method)-[r:CALLS]->(b)
WHERE a.qualified_name ENDS WITH ".FastAgent.__init__"
RETURN a.qualified_name, b.qualified_name, r.confidence
LIMIT 20
```

### Functions in a specific file

```cypher
MATCH (f:Function)
WHERE f.file_path CONTAINS "mcp.py"
RETURN f.name, f.start_line, f.end_line
ORDER BY f.start_line
```

### Count by label

```cypher
MATCH (n) RETURN labels(n) AS label, count(n) AS cnt ORDER BY cnt DESC
```

### Most-called functions (highest in-degree)

```cypher
MATCH (f:Function)
WHERE f.in_degree > 0
RETURN f.qualified_name, f.in_degree
ORDER BY f.in_degree DESC
LIMIT 20
```

### Find path between two functions (BFS through CALLS)

```cypher
MATCH path = (start:Function)-[:CALLS*1..5]->(end:Function)
WHERE start.name = 'send' AND end.name = 'generate_impl'
RETURN [n in nodes(path) | n.name] AS call_chain
LIMIT 5
```

## Gotchas (0.8.1)

Bugs and sharp edges confirmed in empirical evaluation. The agent must know these
to avoid wasting time on broken features.

1. **`semantic_query` is broken.** `search_graph(semantic_query=...)` returns
   garbage (string literals, negative cosine scores in [-0.04, +0.006]). Use
   Ken `search` for natural-language. Use cbm `search_graph(query=...)` for BM25.

2. **`detect_changes` returns empty** for repos with recent commits. Use Ken
   `recently_changed` instead.

3. **`trace_path(target_name=X)` is a BFS neighborhood, not a path-finder.**
   For real path-finding between symbols, use `query_graph` with Cypher.

4. **Class-level `lines`/`complexity`/`out_degree` are zero.** Method-level data
   is correct. Query methods directly; don't trust class-level rollups.

5. **No `is_async` property** on Function/Method nodes. Counting async functions
   requires `search_code(pattern="async def", regex=true)`.

6. **cbm indexing is language-specific.** Python works (30K+ CALLS edges). C does
   not (0 CALLS edges). Before relying on `trace_path` or Cypher CALLS queries,
   check `get_graph_schema` for the CALLS edge count.

7. **The cbm UI is a separate download.** `--ui=true` on the standard binary
   returns "this binary was built without the embedded UI, so the HTTP server
   will not start." The `codebase-memory-mcp-ui` release asset is not
   auto-installed by `curl | bash`.

## Language-Specific Guidance

| Language | CALLS edges | trace_path | Cypher CALLS queries | Recommendation |
|----------|------------|------------|---------------------|----------------|
| **Python** | ✅ 30K+ | ✅ Works | ✅ Works | Primary structural tool |
| **C** | ❌ 0 | ❌ Returns empty | ❌ No edges | Use Ken for structural. cbm's architecture/search_code still work. |
| **Go, Rust, TS, Java, Kotlin** | Untested | Untested | Untested | Try cbm. Verify with `get_graph_schema` — check CALLS edge count > 0 before relying on call tracing. |

## Indexing Workflow

For a new project:

```
1. index_repository(repo_path="/absolute/path", mode="full")
   → records nodes, edges, and indexing time
2. list_projects
   → note the auto-derived project name (dash-form, e.g. "Users-bear-Me-proj")
3. get_graph_schema(project="...")
   → check CALLS edge count. If 0, call tracing won't work for this language.
   → note available node labels and edge types for Cypher queries.
4. (optional, large repos) get_architecture(project="...")
   → ~17-60 KB. Leiden communities, hotspots, entry points.
```

For subsequent sessions: `index_status(project="...")` to check freshness.
cbm's filesystem watcher handles incremental updates automatically after the
initial index. No need to re-index unless you change the codebase substantially.
