---
name: code-intelligence
description: General orchestration layer for code search and code intelligence — which tool answers which kind of question. Sits above tool-specific skills (cbm, nia). Load this in any code project to pick the right tool: Ken for natural-language and symbols, cbm for structural/graph queries (Python+), ugrep for Boolean/multiline patterns, Morph for deep cross-cutting exploration, Nia for anything outside the local repo.
---

# Code Intelligence — Tool Orchestration

This skill is the **environment-wide** decision layer for "which code-intelligence
tool answers this question?" It sits *above* the tool-specific skills:

- **cbm skill** → detailed arg shapes, Cypher library, 7 gotchas, indexing workflow
- **nia skill** → external (packages, docs, web) search

Load this skill when the agent needs to search or understand code and the right
tool isn't obvious. For a tool's deep detail, load that tool's own skill.

## Principle

**Local and free first; MCP manifest is a scarce resource; paid tools sparingly.**

Each MCP tool the agent sees adds tool-selection cognitive load. Reach for the
cheapest tool that answers the question. Only escalate to a paid or heavier tool
when the cheap ones genuinely can't answer in 2–3 calls.

## Decision Flow

```
Agent needs to search/understand code
    │
    ├─ Natural-language / conceptual question?
    │   ("How does X work?", "Where is Y implemented?")
    │       └─> Ken `search` (model2vec + BM25 hybrid)
    │           Finds abstractions, not just implementations.
    │
    ├─ Exact / terse symbol lookup?
    │   ("Where is FastAgent defined?")
    │       └─> Ken `definition`  (1 call, no FQN needed)
    │
    ├─ Structural query?
    │   ("Find all classes", "Who calls generate()?",
    │    "What's the inheritance hierarchy?", "What code is dead?")
    │       └─> cbm (load cbm skill first)
    │           search_graph (label filter), trace_path (callers/callees),
    │           query_graph (Cypher). Python only — see Language Fit below.
    │
    ├─ Architecture overview?
    │   ("What are the main components and how do they cluster?")
    │       └─> cbm `get_architecture`
    │           Leiden community detection. ~17–60 KB response — reserve for
    │           genuine overview queries.
    │
    ├─ Git history / recent changes?
    │       └─> Ken `recently_changed`
    │           (cbm `detect_changes` is broken — see cbm skill gotchas.)
    │
    ├─ Deep cross-cutting, multi-file exploration?
    │   ("Trace every path from entry to database", "How do plugins register?")
    │       └─> Morph `codebase_search` (paid, sparingly)
    │           Sub-agent explores files autonomously. Best when Ken + cbm
    │           can't answer in 2–3 calls. One or two per session.
    │
    ├─ Raw text grep / advanced patterns?
    │       ├─ Simple string → built-in `grep` or cbm `search_code`
    │       └─ Boolean, multi-line, fuzzy, file-type → ugrep (`ug`)
    │
    └─ Anything outside the local repo?
        (third-party package source, framework docs, API references)
            └─> Nia skill (load it first; check existing sources before indexing)
```

## Quick Reference

| What you want | Primary tool | Fallback |
|---------------|--------------|----------|
| Natural-language / conceptual | Ken `search` | cbm `search_graph` (BM25; weaker) |
| Terse symbol lookup | Ken `definition` | cbm `get_code_snippet` (2 calls if ambiguous) |
| Callers (file-level) | Ken `callers` | cbm `trace_path` (Python only) |
| Callers (method-level, type-resolved) | cbm `trace_path` (Python only) | — |
| Outbound callees | cbm `trace_path` (Python only) | — (Ken has no callee tool) |
| Find path A→B through call graph | cbm `query_graph` (Cypher) | — |
| Find all classes / decorators / routes | cbm `search_graph(label=...)` | — |
| Dead-code analysis | cbm `query_graph` (Cypher) | — |
| Architecture overview | cbm `get_architecture` | — (unique) |
| Schema discovery | cbm `get_graph_schema` | — (unique) |
| Deep cross-cutting exploration | Morph `codebase_search` | — |
| Raw grep (simple) | built-in `grep` or cbm `search_code` | ugrep |
| Raw grep (Boolean/multiline/fuzzy) | ugrep | — |
| Recent git changes | Ken `recently_changed` | — (cbm `detect_changes` broken) |
| External packages / docs / web | Nia skill | — |

## Language Fit (read before relying on cbm structure)

cbm's structural tools (trace_path, Cypher CALLS queries) depend on tree-sitter
extraction, which is **language-specific**. Verify before relying on them:

| Language | Call graph | Recommendation |
|----------|-----------|----------------|
| **Python** | ✅ works (30K+ CALLS edges in tests) | Primary structural tool |
| **C** | ❌ 0 CALLS edges | Use Ken for structural; cbm search/architecture still usable |
| **Go, Rust, TS, Java, Kotlin, etc.** | Untested | Try cbm, then check `get_graph_schema` — confirm CALLS edge count > 0 before trusting call tracing |

**Before any structural query: index the project with cbm first**
(`index_repository`). Unlike Ken, cbm does not auto-index.

For the detailed gotchas, arg shapes, Cypher patterns, and indexing workflow,
**load the cbm skill**. This skill intentionally does not duplicate that detail —
it drifts when copied (the prior baked-into-AGENTS.md copy had already diverged).
