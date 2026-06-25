---
name: code-and-docs-search
description: General orchestration layer for finding information — which tool answers which kind of question, across code, docs, and cross-corpus. Sits above tool-specific skills (cbm, nia). Load this in any project to pick the right tool: Ken for code natural-language and symbols, cbm for code structural/graph queries (Python+), qmd for semantic search over docs/notes, Morph for cross-corpus (code+docs) deep exploration, ugrep for Boolean/multiline patterns, Nia for anything outside the local repo.
---

# Code Intelligence — Tool Orchestration

This skill is the **environment-wide** decision layer for "which tool answers
this question?" It covers code, docs, and cross-corpus search. It sits *above*
the tool-specific skills:

- **cbm skill** → safe cbm workflow, intra-tool choice, verification rules
- **cbm cheatsheet** → command shapes, Cypher snippets, option gotchas
- **nia skill** → external (packages, docs, web) search

Load this skill when the agent needs to find information and the right tool
isn't obvious. For a tool's deep detail, load that tool's own skill.

## Principle

**Match the corpus first; cheapest tool that answers; paid tools sparingly.**

The single most common routing error is asking the wrong corpus — running a
code tool against a docs question, or vice versa. Decide code vs docs vs both
*before* picking a tool. Then reach for the cheapest tool that answers, and
only escalate to a paid or heavier tool (Morph) when the cheap ones genuinely
can't answer in 2–3 calls.

## Decision Flow

**First fork: which corpus does the answer live in?** Code, docs, or both?

```
Agent needs to find information
    │
    ├─ ANSWER LIVES IN CODE ────────────────────────────────────────
    │
    ├─ Natural-language / conceptual question about code?
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
    │           search_graph (label filter), query_graph (Cypher) for
    │           callers/callees and path queries. Python only — see Language
    │           Fit below.
    │           NOTE: cbm `trace_path` returns empty in 0.8.1 (confirmed
    │           empirically). Prefer `query_graph` for callers/callees — e.g.
    │           MATCH (a)-[:CALLS]->(b {name:"fn"}) RETURN a.name.
    │
    ├─ Architecture overview of code?
    │   ("What are the main components and how do they cluster?")
    │       └─> cbm `get_architecture`
    │           Leiden community detection. ~17–60 KB response — reserve for
    │           genuine overview queries.
    │
    ├─ ANSWER LIVES IN DOCS / NOTES / KNOWLEDGE BASES ──────────────
    │
    ├─ Semantic question about design docs, plans, decisions, notes?
    │   ("What did we decide about X?", "How is Y meant to work per the design?")
    │       └─> qmd `query` (hybrid BM25 + vector + rerank, all local)
    │           Markdown/prose corpus only — NOT code. Index collections with
    │           `qmd collection add <path> --name X; qmd update; qmd embed`.
    │           Per-collection context (`qmd context add`) is cheap and helps.
    │           `qmd search` = BM25 only; `vsearch` = vector; `query` = best.
    │
    ├─ ANSWER SPANS CODE AND DOCS ──────────────────────────────────
    │
    ├─ Cross-cutting, end-to-end question?
    │   ("Trace auth from entry point through to the design rationale",
    │    "How do plugins register — code and the spec?")
    │       └─> Morph `codebase_search` (paid, ~30s)
    │           Sub-agent reads files autonomously across code AND docs — the
    │           only tool that spans both. Reserve for genuine cross-corpus
    │           questions; for single-corpus the specialised tool is faster
    │           and free. One or two per session.
    │
    ├─ EITHER CORPUS / UTILITY ─────────────────────────────────────
    │
    ├─ Git history / recent changes?
    │       └─> Ken `recently_changed`
    │           (cbm `detect_changes` is broken — see `cheat cbm`.)
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
| **CODE — conceptual** | Ken `search` | cbm `search_graph` (BM25; weaker) |
| **CODE — symbol lookup** | Ken `definition` | cbm `get_code_snippet` (2 calls if ambiguous) |
| **CODE — callers (file-level)** | Ken `callers` | cbm `query_graph` (Cypher CALLS) |
| **CODE — callers/callees (method-level)** | cbm `query_graph` (Cypher) | — |
| ⚠️ `trace_path` | **broken in cbm 0.8.1** (returns empty) | use `query_graph` instead |
| Find path A→B through call graph | cbm `query_graph` (Cypher) | — |
| Find all classes / decorators / routes | cbm `search_graph(label=...)` | — |
| Dead-code analysis | cbm `query_graph` (Cypher) | — |
| **CODE — architecture overview** | cbm `get_architecture` | — (unique) |
| Schema discovery | cbm `get_graph_schema` | — (unique) |
| **DOCS — semantic search over docs/notes** | qmd `query` | qmd `vsearch` (no rerank); `grep` (literal only) |
| **CROSS-CORPUS — code + docs together** | Morph `codebase_search` | — (unique; paid) |
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

For cbm operating discipline, **load the cbm skill**. For exact command shapes,
Cypher snippets, and option reminders, use `cheat cbm`. This skill intentionally
does not duplicate that detail because copied tool references drift.
