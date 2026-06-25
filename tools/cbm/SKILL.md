---
name: cbm
description: Use after the code-and-docs-search router has selected codebase-memory-mcp. Defines the minimal safe cbm workflow, tool-specific operating rules, and verification checks; use the `cbm` cheatsheet for command shapes, Cypher snippets, and option gotchas.
---

# codebase-memory-mcp

Use this skill after the `code-and-docs-search` router has selected
codebase-memory-mcp. It is not the cross-tool routing layer. Its job is to keep
cbm usage correct once cbm is already the chosen tool.

For exact command shapes, Cypher snippets, and option reminders, consult the
`cbm` cheatsheet.

## Scope

cbm is useful for structural questions once the repository has been indexed:
callers, callees, inheritance, symbol relationships, graph schema, dead-code
candidates, architecture summaries, and graph-aware text search.

If the question is really about choosing between cbm, semantic search, grep,
Nia, Morph, or another tool, stop and load `code-and-docs-search` instead.

## Required Workflow

1. Index first for a new repository with `index_repository` using the absolute
   repo path. Default to a full index unless the repository is too large for the
   current task.
2. Call `list_projects` and use the returned project identifier. Never guess the
   dash-form project name.
3. Call `get_graph_schema` before relying on structural results. Check that the
   relevant node labels and edge types exist, especially `CALLS`.
4. Start with the narrowest cbm tool that answers the question.
5. Verify the result against source when the answer will drive an edit, design
   decision, or review finding.

## Intra-tool Choice

- `search_graph`: find classes, functions, methods, decorators, routes, or
  variables by name/BM25 query and optional label.
- `get_code_snippet`: read a known symbol once you have a qualified name.
- `query_graph`: answer relationship questions that require Cypher —
  callers/callees, real path-finding, and dead-code checks. **This is the
  working tool for structural queries.**
- ⚠️ `trace_path`: **broken in cbm 0.8.1** (returns empty for caller lookups,
  confirmed empirically). Use `query_graph` with a Cypher CALLS query instead,
  e.g. `MATCH (a)-[:CALLS]->(b {name:"fn"}) RETURN a.name`.
- `get_graph_schema`: inspect available labels/edges before complex Cypher or
  before trusting call tracing in a language.
- `get_architecture`: request only when a large architecture summary is worth
  the token cost.
- `search_code`: use when graph context around text matches is valuable; use
  normal text search for ordinary grep work.

## Guardrails

- Treat cbm as an index, not the source of truth. If the result is surprising or
  high-impact, read the file directly.
- For methods, prefer discovery then qualified-name inspection. Bare method
  tracing can be ambiguous for names like `__init__`, `run`, or `handle`.
- For languages other than Python, assume call tracing is unproven until the
  schema confirms useful call edges.
- Keep cbm calls bounded. If two or three targeted cbm calls do not answer the
  question, switch back to the `code-and-docs-search` router.
- Do not paste long Cypher libraries into the conversation. Use the `cbm`
  cheatsheet for reusable query patterns.

## Related

- `code-and-docs-search` skill: top-level choice of search/intelligence tool.
- `nia` skill: external repositories, packages, docs, and web sources.
- `cbm` cheatsheet: command shapes, Cypher examples, and option gotchas.
