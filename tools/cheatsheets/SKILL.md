---
name: cheatsheets
description: Create, update, and maintain CLI cheatsheets for the `cheat` CLI following the canonical template and style guide. Use when the user asks to author, edit, lint, or manage .cheat files in ~/Me/repos/cheatsheets/personal/.
---

# Cheatsheet Authoring Skill

You maintain CLI cheatsheets stored in `~/Me/repos/cheatsheets/personal/`. This skill defines the template, style guide, and workflow for all cheatsheet operations.

## Important: cheat v5 File Naming

`cheat` v5 reads files by their exact filename — **no file extension** is used or recognized. A file named `op-env.cheat` will NOT be found by `cheat op-env`. The sheet file must be named exactly as the topic: `op-env`, `git-branches`, etc. The `.cheat` extension from the original guide is incorrect for cheat v5.1. Leave `TEMPLATE.cheat` with its extension since it is not loaded as a sheet.

## File Locations

| What | Path |
|---|---|
| Repo root | `~/Me/repos/cheatsheets/` |
| Personal sheets (read/write) | `~/Me/repos/cheatsheets/personal/` |
| Canonical template | `~/Me/repos/cheatsheets/TEMPLATE.cheat` |
| Config | `~/.config/cheat/conf.yml` |

## Canonical Template

Every cheatsheet must follow this structure exactly. Do not add or rename sections. Omit empty sections entirely — never leave a section with nothing in it.

```markdown
---
syntax: markdown
tags: [ <primary-tag>, <secondary-tag> ]
---

# <Topic>: Cheatsheet

## Overview
One-paragraph summary — what this tool/concept is for and when to reach for it.

## Common Tasks

- **<Task name>**: brief description
  ```<lang>
  <command or code>
  ```

- **<Task name>**: brief description
  ```<lang>
  <command or code>
  ```

## Patterns

- **<Pattern name>**: one-line description
  ```<lang>
  <example>
  ```

## Flags & Options

| Flag / Option | Default | Description |
|---|---|---|
| `<flag>` | `<default>` | What it does |

## Gotchas

- <Concrete warning — specific, not generic>
- <Edge case or common mistake>

## See Also

- `<related-topic>` — why it's related
- <URL> — what's there
```

## Style Guide

### Tone and Register

- Write for an experienced engineer who needs a concise reminder, not a tutorial.
- No introductions, no conclusions, no "in this cheatsheet we will cover…".
- Every sentence either states a fact, names a pattern, or flags a risk.

### Length and Density

- One file, one topic. Prefer narrow scope: `surrealdb-schema`, not `surrealdb`.
- Target 50–130 lines per file. If a file exceeds 150 rows, split it.
- No bullet point may exceed two lines. If an explanation needs more, it belongs in a link under **See Also**.

### Code Blocks

- Always specify the language tag on fenced blocks: ` ```bash `, ` ```sql `, ` ```toml `, etc.
- Commands must be runnable as shown. No pseudo-syntax like `<YOUR_VALUE_HERE>` — use realistic placeholders: `ns my_namespace`, `db my_db`.
- Prefer the shortest correct invocation. Show flags only when they change behaviour meaningfully.

### Naming Conventions

File names follow `<tool>[-<subtopic>]` — lowercase, hyphen-separated, **no file extension**.

Examples: `git-branches`, `surrealdb-schema`, `jq-streams`, `rust-async`.

### Front Matter

Every file must begin with valid YAML front matter:

```yaml
---
syntax: markdown
tags: [ <primary-tag>, <secondary-tag> ]
---
```

Use 1–3 tags. The first tag should match the tool name (`surreal`, `git`, `jq`). Secondary tags add context (`schema`, `query`, `async`).

### What to Omit

- Do not include man-page level documentation. The reader can run `man`.
- Do not list every flag. Only flags the reader is likely to forget or mis-use.
- Do not explain what a tool is in more than 3 sentences in **Overview**.
- Do not use headers inside **Common Tasks** or **Patterns** — only bold list labels.

## Scope and Layering

Cheatsheets occupy one layer in a three-tier knowledge model. Pick the right tier before writing — most failed sheets are scope mistakes, not style mistakes.

| Tier | Purpose | Trigger | Owner |
|---|---|---|---|
| `--help` / man | Reference: every flag, every subcommand | "What flags does `session list` take?" | The tool |
| `cheat <topic>` | Routing + non-obvious behaviour: intent→command, gotchas `--help` can't express | "I want to find a session by content — which command, and the catch" | This repo |
| Skill | Procedure + judgment: workflows, decision criteria, conventions | "How do I add a parser to AgentsView?" or "when does a topic warrant a sheet?" | `~/.agents/skills/` |

**A cheatsheet earns its place by adding something `--help` cannot.** That's usually one of: intent→command routing, sort/filter keys the help lists but doesn't prioritise, the one SQL query that surfaces what the CLI under-surfaces, or a gotcha that only manifests at runtime. If a draft is just a reorganised `--help`, it belongs nowhere.

### When NOT to write a sheet

- The tool's `--help` is short and clear and there are no non-obvious behaviours. A `cheat cheat` would duplicate `cheat --help`.
- The content is procedure ("how to author a sheet") or judgment ("when to split a topic"). That's the skill's job. A `cheat cheatsheet` would drift from the skill within weeks.
- The topic is "everything about X." Split instead (see below).

### When to split a topic into multiple sheets

Split when one audience's content is noise to another. The test: would a reader of sheet A have to skip past half of it to find what they need? If yes, split.

The canonical split for a non-trivial tool:

| Sheet | Audience | Content |
|---|---|---|
| `<tool>` | Day-to-day users | Common tasks, routing, sort keys, user-facing gotchas |
| `<tool>-install` | Set-up / ops | Install methods, config files, env vars, deployment topologies |
| `<tool>-dev` | Contributors / integrators | Internals, build flags, schema, extension points, dev-only gotchas |

Cross-reference the siblings in each sheet's **See Also** so a reader landing on the wrong one can hop. A split done right means each sheet stays under 130 lines without squeezing.

Signs you should split:

- One sheet exceeds ~130 lines and a third of it is irrelevant to most readers.
- A gotcha applies only to contributors, not users (e.g. `-tags fts5` build flag).
- The same flag means different things to installers vs users vs devs.

Signs you should NOT split:

- The topic is narrow enough that one 80-line sheet covers it (e.g. `op-env`).
- The "subtopics" are really just sections of one task, not distinct audiences.

### Authoring mechanics

- **Write files directly** (`Write` tool to `~/Me/repos/cheatsheets/personal/<name>`), don't shell out to `cheat -e`. The skill workflow permits direct writes; `cheat -e` opens one sheet at a time in an editor and blocks on a human.
- **Always verify by reading through `cheat`** after writing: `cheat <name>` must succeed. The write mechanism doesn't matter; the read-via-`cheat` check is what proves the sheet is discoverable.
- **For coordinated multi-sheet work** (a new tool covering plain/`-install`/`-dev`), write all sheets in one pass with See Also cross-references, then verify all three resolve. Serial `cheat -e` rounds make cross-references drift.
- **Commit each sheet** with a focused message: `cheat: add <topic>` or `cheat: add <topic> (plain/-install/-dev)`.

## Workflow

### System Prompt (set once per session or agent)

```
You maintain CLI cheatsheets stored in ~/Me/repos/cheatsheets/personal/.
Rules:
- Follow the template and style guide in the cheatsheets skill exactly.
- Output only the cheatsheet file content — no preamble, no explanation.
- Use the canonical six sections: Overview, Common Tasks, Patterns, Flags & Options, Gotchas, See Also.
- Omit empty sections entirely.
- Every code block must have a language tag.
- Target 50–130 lines. Split topics before exceeding 150 lines.
- File name: <tool>[-<subtopic>], lowercase, hyphenated, no extension.
- Never rename or add sections.
```

## Research Before Writing

Before generating or writing a cheatsheet, gather source material:

1. **Check the tool's built-in help**: `tool --help`, `tool --version`, `tool -h`.
2. **Check the tool's docs site for an `/llms.txt`**: `https://<docs-site>/llms.txt` provides the most LLM-friendly condensed reference. If it exists, use it as primary source material.
3. **Check the tool's docs site**: Browse key pages (usage, configuration, gotchas).
4. **Check for wrapper scripts on this system**: Does the tool have a wrapper in `~/.local/bin/` that modifies its behavior (e.g., injects secrets via `op-env`)?
5. **Check for cross-references**: If this tool depends on another tool already documented (e.g. `llm` depends on `op-env` for secrets), add a cross-reference in **See Also**.

### Creating a New Sheet

1. Gather source material (see Research Before Writing above).
2. Generate the cheatsheet content using the system prompt, or write it directly from research if the LLM CLI is unavailable.
3. Write the file to `~/Me/repos/cheatsheets/personal/<tool>[-<subtopic>]` (no file extension).
4. The user can review with `cheat <topic>`.
5. Commit with `cd ~/Me/repos/cheatsheets && git add personal/<file> && git commit -m "cheat: add <topic>"`.

### Updating an Existing Sheet

1. Read the existing file from `~/Me/repos/cheatsheets/personal/`.
2. Modify the content following the template and style guide. Preserve all existing content and the same structure unless the user specifies otherwise.
3. The user can diff before accepting.

### Linting a Sheet (Periodic Maintenance)

Rewrite a sheet to conform exactly to the style guide: max 130 lines, no empty sections, every code block language-tagged, no explanatory prose over 2 lines per bullet, no introductions or conclusions. Preserve all technical content.

## Verification

After creating or editing a sheet, validate:
- Does it start with valid YAML front matter (`---` delimited)?
- Are there exactly the six canonical sections (some may be omitted)?
- Are all code blocks language-tagged?
- Is the file between 50–130 lines (or valid if shorter/longer)?
- Are tags present and appropriate (1–3 tags, first matches tool name)?

## Related

- `skills-manage` skill — how skills are organized, authored, and deployed.
  Cheatsheets are the sibling reference tier: a tool-operating skill points
  at its cheatsheet for command shapes (see `skills-manage` → "Skill ↔
  cheatsheet pairing"). When a tool has both, cross-reference them in both
  directions (the sheet's See Also → skill; the skill's Related → sheet).
- Cheatsheets live in their own canonical repo (`~/Me/repos/cheatsheets/`),
  separate from skills (`~/Me/repos/skills/`), but a sheet that documents a
  paired skill deploys alongside it. Skill edits land in `~/Me/repos/skills/`;
  sheet edits land here.
