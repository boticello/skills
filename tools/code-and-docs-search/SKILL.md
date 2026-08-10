---
name: code-and-docs-search
description: >-
  Use whenever an agent must find code, understand an implementation, inspect
  Git history, recover a decision, search documentation, or choose between
  Ken, sem, cbm, qmd, Morph, ugrep, Backlog, AgentsView, and external search.
  Routes each question to the right corpus and the cheapest trustworthy tool.
triggers:
  - search code
  - code search
  - where is this implemented
  - how does this work
  - git history
  - what changed
  - who changed
  - what did we decide
  - search docs
  - tickets
  - br
  - backlog
  - sem
  - Ken
  - cbm
  - qmd
---

# Code and documentation search

This is the decision layer above the tool-specific skills. Its job is to ask
the right question of the right corpus, not to reproduce every tool's command
reference.

## Ask these questions first

1. **Where does the answer live?** Current code, Git history, prose/docs,
   tickets, prior agent sessions, an external corpus, or several together?
2. **What shape is the question?** Conceptual discovery, exact symbol,
   dependency/architecture, change/ownership/impact, or literal pattern?
3. **Is relevance enough, or must recall be exhaustive?** Exploration can use
   ranked retrieval; refactors, renames, policy checks and audits need an
   exact/exhaustive pass.
4. **What is authoritative and fresh?** Check index state where it matters,
   then verify conclusions against source, raw Git, or the maintained record.

## Routing table

| Question | Start with | Value and boundary |
|---|---|---|
| Where is a code concept implemented now? | Ken `search` | Hybrid semantic + lexical ranking; finds abstractions and synonyms, but is not exhaustive. |
| Where is a named symbol or its file-level use? | Ken `definition`, `callers`, `references`, `outline` | Fast tree-sitter-grade lookup; name-resolved, not compiler/type-resolved. |
| How did an entity evolve, who owns it, or what does a change affect? | `sem log`, `blame`, `diff`, `impact`, `context` | Entity-aware history, semantic diffs, dependants and affected tests; use raw Git as final authority. |
| What changed very recently? | Ken `recently_changed` | Cheap chronological/path-filtered snapshot; use `sem` for serious history analysis. |
| What calls what, where are cycles, or what are the architectural clusters? | cbm graph tools | Arbitrary multi-hop and architecture queries; load the `cbm` skill first and verify language coverage. |
| Where does an exact pattern occur everywhere? | `rg`/ugrep (`ug`) | Exhaustive literal, Boolean, multiline, fuzzy and file-type search; preferred for safe refactors and policy audits. |
| What do requirements, correspondence or design notes say? | qmd `query` | Local hybrid search over prose/Markdown; not a code index. |
| Which ticket owns this, or what rationale was recorded there? | The project's tracker (`br` in this repository; Backlog in the alan-puzzle project) | Commitment and ownership record; follow the owning project's tracker workflow rather than treating a search result as current truth. |
| What happened in an earlier agent session? | AgentsView recall/content search | Searches conversation and tool evidence; corroborate against maintained records. |
| How do code and design documents connect end to end? | Morph `codebase_search` | Cross-corpus exploration; slower/paid, so reserve for genuine code+docs questions. |
| How does an external package or API work? | Nia/external primary-source search, when configured | Outside-repository corpus; load the relevant external-search skill first. |

When a compiler/LSP query surface is available, prefer it for type-resolved
references, hierarchy, diagnostics and rename safety. Ken, sem and tree-sitter
graphs do not replace compiler semantics.

## Operating sequence

1. Pick the corpus and question shape using the four questions above.
2. Use the cheapest specialised tool that can answer it.
3. If two or three focused calls do not resolve it, escalate: Ken → cbm for
   relationships; qmd/Ken → Morph for cross-corpus; ranked search → ugrep for
   completeness.
4. Read the returned source or maintained record. Search results are leads,
   not evidence by themselves.
5. Before changing code, add an exhaustive exact or type-aware pass when a
   missed reference could make the change unsafe.
6. For historical claims, prefer `sem`'s entity perspective, then confirm the
   decisive patch/commit with raw Git when exactness matters.

## Tool-specific guardrails

### Ken

- Primary for natural-language current-code discovery and terse symbol lookup.
- Check `status` if index freshness or language coverage is material.
- Use `find_related` after a good result to locate similar implementations.
- Do not treat ranked results as exhaustive.

### sem

- Primary for semantic diffs, entity evolution, entity-level blame, impact,
  affected tests, hotspots and co-change patterns.
- `sem diff --no-cosmetics` is the cleanest first view of a noisy change;
  verbose targeted diffs recover exact entity content.
- `sem log <entity> --file <path>` disambiguates same-named entities.
- `sem impact` is a focused dependency/test-impact answer; use cbm when the
  question needs arbitrary graph traversal or architectural clustering.
- Entity extraction is structural, not type-resolved. Git remains the record
  of the exact patch.

### cbm

- Index the repository before structural queries and load the `cbm` skill.
- Check graph schema and CALLS-edge coverage before trusting a language.
- In cbm 0.8.1, `trace_path` can return empty; prefer Cypher `query_graph`
  for caller/callee and path queries.

### qmd and Morph

- Use qmd `query` for docs; `search` is lexical-only and `vsearch` omits the
  reranker.
- Use Morph only when the answer genuinely spans code and prose or cheaper
  specialised tools have failed in a few calls.

### Exact search

- Use `rg` for ordinary exhaustive literals and ugrep for Boolean, multiline,
  fuzzy, archive or file-type-aware queries.
- Cross-language runtime boundaries—subprocesses, generated artefacts,
  reflection and JVM interop—often escape static indexes. Verify these seams
  from entry points, configuration and runtime evidence.

## Related

- `cbm` skill and `cheat cbm` — graph workflow and command shapes
- `nia` skill — external packages, documentation and web corpora
- `process/command-recipes.md` in projects that maintain local invocation notes
