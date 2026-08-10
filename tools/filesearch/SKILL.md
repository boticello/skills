---
name: filesearch
description: Find files anywhere in ~/Me/ — pick the right tool (mdfind, find, pdftotext, codesearch) for the question. Also covers the canonical home of every common material type. Use this skill whenever the user asks "where is X", "find me the file for Y", or "what folder holds Z". Load it before doing any non-trivial file-finding in the user's filesystem.
triggers:
  - find a file
  - where is the file
  - locate a document
  - search the filesystem
  - what folder holds
alwaysAllow:
  - Bash
requiredSources:
  - system-files
---

# File Search in `~/Me/`

You are looking for a file. The right tool depends on **what kind of
question** you're asking and **what's already indexed**. This skill
gives you the decision tree, the mdfind cheat sheet, and a map of
`~/Me/` so you don't have to walk the tree.

> **One-line rule:** if the answer is "I need to find a file by name or
> content in `~/Me/`", `mdfind` is almost always the right starting
> point. It is pre-installed, indexes the whole home, runs in under a
> second, and works from any shell (unlike fish functions like `mdn`).
>
> For a deeper orientation, see the map at
> `~/Me/workspace/system/reference/me-map.md`.

## Decision tree

```
What kind of question is this?
│
├── "Where is the file CALLED X?" / "Find a file with NAME in the name"
│       → mdfind -name "*X*"     (filename match, Spotlight)
│       → mdfind -name X.pdf     (exact filename)
│
├── "What document talks about TOPIC?" / "Find a file whose CONTENT mentions X"
│       → mdfind 'kMDItemTextContent == "X"'            (exact substring)
│       → mdfind 'kMDItemTextContent == "X"c'           (case-insensitive)
│       → mdfind 'kMDItemTextContent == "*X*"c'         (substring, case-insensitive)
│
├── "Find a file of a certain TYPE / KIND" (image, pdf, audio, video)
│       → mdfind 'kMDItemContentType == "public.pdf"'
│       → mdfind 'kMDItemContentType == "public.image"'
│
├── "Find a file modified in a date range"
│       → mdfind 'kMDItemFSContentChangeDate >= $time.today(-7)'
│       → mdfind 'kMDItemFSContentChangeDate > 2026-06-01'
│
├── "Where is X scoped to a SUBFOLDER?"
│       → mdfind -onlyin ~/Me/records 'kMDItemTextContent == "monzo"c'
│
├── "Search content inside PDFs that Spotlight does not index"
│   (older scans, OCR-poor PDFs, encrypted PDFs)
│       → find <path> -name "*.pdf" -exec pdftotext {} - \; | grep -i <term>
│       → use mdfind first; fall back to this if mdfind returns nothing
│
├── "Search for a function or class inside CODE"
│       → codesearch search "<natural language query>" --path <repo>
│       → see the `code-and-docs-search` skill for the full decision tree
│
├── "Search the SECOND-BRAIN / knowledge base"
│       → mdfind -onlyin ~/Me/kb 'kMDItemTextContent == "<topic>"c'
│       → see the `code-and-docs-search` skill for qmd / nia
│
└── "I genuinely have no idea where this could be"
        → start with the map: cat ~/Me/workspace/system/reference/me-map.md
        → mdfind with a broad content query
        → if still nothing, fall back to `find ~ -iname "*<term>*"`
```

## The `mdfind` cheat sheet

`mdfind` is Spotlight's CLI. It is **already indexing `~/Me/`** and is
fast. Treat it as the default. It does not need to be set up.

### Name search

```bash
# find anything with "monzo" in the filename
mdfind -name "monzo"

# restrict to a folder
mdfind -onlyin ~/Me/records -name "*.pdf"

# exact name
mdfind -name "CERTIFICATE.pdf"
```

### Content search (PDFs, docx, txt, etc. — Spotlight indexes text content)

```bash
# any file whose indexed text contains the word "monzo"
mdfind 'kMDItemTextContent == "monzo"'

# case-insensitive substring
mdfind 'kMDItemTextContent == "monzo"c'
mdfind 'kMDItemTextContent == "*monzo*"c'

# search only inside ~/Me/records
mdfind -onlyin ~/Me/records 'kMDItemTextContent == "lazybrain"c'
```

### By kind / type

```bash
# all PDFs in ~/Me
mdfind -onlyin ~/Me -name "*.pdf"

# all images
mdfind -onlyin ~/Me 'kMDItemContentType == "public.image"'

# all markdown
mdfind -onlyin ~/Me -name "*.md"
```

### By date

```bash
# files modified in the last 7 days
mdfind 'kMDItemFSContentChangeDate >= $time.today(-7)'

# files modified since 1 June 2026
mdfind 'kMDItemFSContentChangeDate > 2026-06-01'
```

### By tag / label

```bash
# files tagged "red" in Finder
mdfind 'kMDItemFSLabel = 7'
# (label IDs: 0=none, 1=grey, 2=green, 3=purple, 4=blue, 5=yellow, 6=red, 7=orange)
```

### Useful flags

| Flag | Effect |
|---|---|
| `-onlyin <path>` | Restrict search to a directory |
| `-name <pattern>` | Match filename (glob) |
| `-count` | Print only the number of matches |
| `-literal` | Treat query as literal text, not a Spotlight predicate |
| `-0` | Null-terminate output (for `xargs -0`) |

## Falling back: `find` + `pdftotext`

Spotlight doesn't index everything. Use this when:
- The file is a scanned PDF with no OCR.
- The file is in `~/Library/` (Spotlight skips parts of the Library).
- The file is in a `.git/` or `node_modules/` (excluded by default).
- `mdfind` returns nothing and you know the file is there.

```bash
# search for "monzo" inside all PDFs in a directory
find ~/Me/records/banking -name "*.pdf" -not -path "*/node_modules/*" \
  -exec sh -c 'pdftotext "$1" - 2>/dev/null | grep -l -i "monzo" >/dev/null && echo "$1"' _ {} \;
```

(Slow but reliable. Always check `mdfind` first.)

## Anti-patterns

- **Don't use fish functions from non-fish shells.** `mdn.fish` is a
  filename-only search, and fish functions are not loaded by zsh. From a
  tool call, use `mdfind -name ...` directly.
- **Don't `find ~` for a broad search.** It is slow, and Spotlight
  already has the answer. Use `mdfind` first.
- **Don't walk the tree when `me-map.md` answers the question.** The map
  lives at `~/Me/workspace/system/reference/me-map.md` and lists the
  canonical home of every common material type.
- **Don't trust the inbox as a record.** Material in `~/Me/inbox/` is
  awaiting triage. If you find it there, flag it and suggest moving to
  the canonical home (see the map).
- **Don't open every file to check whether it matches.** Use Spotlight
  predicates (case-insensitive content search) or `pdftotext | grep`
  pipelines, which scale to thousands of files.

## Quick reference: the canonical homes (one-line each)

| Material | Canonical home |
|---|---|
| Personal identity (passport, driving licence) | `~/Me/records/identity/` |
| Personal bank statements (Monzo, Halifax, HSBC, Triodos) | `~/Me/records/banking/<bank>/` |
| Personal tax / self-assessment | `~/Me/records/tax/` |
| Lazybrain Ltd company record (key facts, bank, contracts) | `~/Me/records/lazybrain-ltd/` |
| Lazybrain Ltd client compliance packs | `~/Me/records/lazybrain-ltd/Compliance/` |
| UK company / finance / legal reusable reference | `~/Me/reference/finance/`, `~/Me/reference/legal-and-contracts/` |
| Knowledge-base notes (second brain) | `~/Me/kb/` |
| Authored CLI tools | `~/Me/OS/scripts/bin/` (symlinked to `~/.local/bin/`) |
| Authored skills | `~/Me/repos/skills/<category>/<skill>/` (deployed to `~/.agents/skills/`) |
| Inbox (incoming, never a long-term home) | `~/Me/inbox/` |
| Long-term archive | `~/Me/archive/` and `~/Me/Archive/` (read-mostly) |

For the full map, see `~/Me/workspace/system/reference/me-map.md`.

## What this skill is NOT

- **Code search** — use `codesearch` directly, and load the
  `code-and-docs-search` skill for the routing decision.
- **Knowledge-base semantic search** — load `code-and-docs-search` for
  the qmd / nia tools.
- **Filing decisions** — load `filing-process` if the user wants to
  actually *file* something rather than find it.
- **Orientation across tickets / projects / jots** — load `orientate`.

## Workflow when the user asks "find X"

1. Identify the canonical home of X from the map or the cheat sheet.
2. Try `mdfind -onlyin <home> -name "*X*"` first.
3. If filename match fails, try `mdfind -onlyin <home> 'kMDItemTextContent == "*X*"c'`.
4. If both fail and the home is wrong, broaden to `mdfind -onlyin ~/Me ...`.
5. If `mdfind` is empty or the file is unindexed, fall back to
   `find <path> -name "*.pdf" -exec pdftotext {} - \; | grep -i X`.
6. If you found it in `~/Me/inbox/`, flag that it should be triaged to
   the canonical home.
