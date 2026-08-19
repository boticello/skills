---
name: bin-creator
description: Place, link, and scaffold CLI tools correctly — single-file tools author in ~/Me/OS/scripts/bin/, multi-file tools (deps, tests, own VCS) in ~/Me/OS/scripts/projects/<name>/ with a private remote; the ~/.local/bin PATH junction always receives a symlink with an absolute target to the tool's true entry point. Use whenever the user asks to create, add, write, place, relocate, or globally link a CLI script, command, or tool — or asks where a new tool should live. Prevents the "written directly to ~/.local/bin" mistake that loses source to a gitignored junction, and the gitignored-nested-repo-without-remote mistake that loses all backup.
triggers:
  - create CLI
  - new command
  - bin tool
  - write a script
  - standalone CLI
  - where should this tool live
  - symlink into PATH
  - move tool to scripts
---

# bin-creator — scaffold and place a CLI tool

Use this skill whenever the user asks to create a new CLI tool, command, or
"script" — or to place, link, or globally expose an existing one. It exists
to prevent two recurring mistakes: **authoring a script directly into
`~/.local/bin`** (which is a symlink to a gitignored directory), leaving the
source un-tracked and invisible to version control; and **gitignoring a
project repo inside `scripts/` without giving it its own remote**, leaving it
with no backup anywhere.

## The one rule

**`~/.local/bin` is a PATH junction, not a home. Author into a canonical
home, symlink out — the link always targets the tool's true entry point.**

```
~/Me/OS/scripts/bin/<tool>          ← single-file tools: author HERE
~/Me/OS/scripts/projects/<name>/    ← multi-file tools: project home (deps, tests, own VCS)
        │
        └─ symlink → ~/.local/bin/<tool>   ← the junction, on PATH
```

Never write a real script file into `~/.local/bin/`. That dir is
`~/Me/OS/dotfiles/bin` (symlinked), and its contents are gitignored except for
an explicit allowlist of repo-coupled scripts. A standalone tool written there
becomes invisible to version control — exactly the `scratch` bug.

## Procedure

### 1. Is the tool standalone or repo-coupled?

| If... | It goes in |
|---|---|
| Self-contained single file, works anywhere | `~/Me/OS/scripts/bin/` ← **this skill** |
| Multi-file tool: dependencies, tests, its own VCS | `~/Me/OS/scripts/projects/<name>/` ← **this skill**, see "Project tools" below |
| Derives a repo root from its own location (e.g. `DOTFILES_DIR`), orchestrates one repo's machinery | that repo's `bin/` root, **and** added to its `.gitignore` allowlist. Not this skill. |

If unsure, it's standalone. Repo-coupling is an explicit pattern (`resolve_script_path`/`dirname $0`/`File.expand_path(__dir__)` used to find a *repo's* config and orchestrate its machinery). Boundary case: a project binstub anchoring to its own project (`File.expand_path('../Gemfile', __dir__)`) is **not** repo-coupled — the project is the tool, not a repo being orchestrated.

### 2. Pick the language

| Language | Use when | Shebang |
|---|---|---|
| **Bash** | Glue: composing other commands, file moves, wrapping one tool. Trivial logic. | `#!/opt/homebrew/bin/bash` |
| **Ruby** | Anything with real logic, data structures, JSON/YAML parsing, multiple code paths. Your existing `scripts/bin` is mostly Ruby for this reason. | `#!/usr/bin/env ruby` |
| **Zsh** | Only when you specifically need zsh features (existing `ts-ruby-*` use it). Prefer Bash otherwise. | `#!/opt/homebrew/bin/zsh` (if installed) or `#!/usr/bin/env zsh` |

Default to **Ruby for logic, Bash for glue.**

**Shebang rule: use the absolute homebrew path for any shell script
you author.** This is the single most important line in the script. See
"Shebangs" below for why.

#### Shebangs — why absolute paths, not `env`

On macOS, `/bin/bash` is Apple-shipped bash **3.2** (the last GPLv2
version). It does not support `declare -A` (associative arrays),
`${var,,}` (lowercase parameter expansion), `read -d ''`, or other
bash 4+ features. Bash 5.3 is at `/opt/homebrew/bin/bash`.

Three patterns and their tradeoffs:

| Shebang | Pros | Cons |
|---|---|---|
| `#!/opt/homebrew/bin/bash` | **Recommended.** Hardcoded path, no PATH lookup, no `env` failure modes. Works regardless of how the caller resolves `bash`. | Hardcodes a path; if homebrew moves (e.g. to `/usr/local` on Intel Macs), the script breaks. |
| `#!/usr/bin/env bash` | Portable across systems. | Depends on the caller's PATH having a usable `bash` first. On macOS without `/etc/paths.d/homebrew` configured, `env` finds `/bin/bash` 3.2. |
| `#!/bin/bash` | Always works. | Always 3.2. New bash syntax will fail. |

For this user's environment: homebrew is at `/opt/homebrew`, modern
bash 5.3 is installed, and `/etc/paths.d/homebrew` is configured
(verified 2026-06-29). Use `#!/opt/homebrew/bin/bash` for new scripts
and the convention will Just Work.

If a script is genuinely meant to be portable to other macOS systems
without homebrew, use `#!/usr/bin/env bash` AND stick to bash 3.2
syntax. But that's a rare requirement.

**Do not add self-reexec guards** (the `if [ "${BASH_VERSINFO[0]}" -lt 4 ]; then exec /opt/homebrew/bin/bash "$0" "$@"; fi` pattern) to scripts. They work but obscure the shebang issue. Fix the shebang once, in one place; don't add run-time ceremony to every script.

### 3. Pick the name (kebab-case, no extension)

Three patterns by population (see `~/Me/OS/scripts/README.md` for the full table):

| Pattern | When | Example |
|---|---|---|
| `domain-verb` (family) | Multiple ops on one domain; type `domain-<tab>` to see siblings | `ts-ruby-calls`, `ts-ruby-symbols` |
| `verb-object` (standalone) | Single-purpose; imperative mood | `download-clipboard`, `rename-file-extensions` |
| `source-to-target` (converter) | Format transformation, reads left→right | `doc-to-md`, `rtf-to-md` |

Rules: kebab-case, no underscores, no extension (`.sh` allowed only for clarity).
A tool is a "family" only if it has siblings on the same domain — otherwise it's a standalone.

### 4. Create, make executable, symlink

```bash
TOOL=<name>
SCRIPTS_BIN=/Users/bear/Me/OS/scripts/bin
LOCAL_BIN=/Users/bear/.local/bin

# 1. Author source in the canonical home
$EDITOR "$SCRIPTS_BIN/$TOOL"        # write the script here

# 2. Make executable
chmod +x "$SCRIPTS_BIN/$TOOL"

# 3. Symlink into the PATH junction (target must be absolute)
ln -s "$SCRIPTS_BIN/$TOOL" "$LOCAL_BIN/$TOOL"

# 4. Verify it runs
"$TOOL" --help
```

The symlink target **must be absolute** (`/Users/bear/Me/OS/scripts/bin/<tool>`),
not `~/Me/scripts/...` — the latter path does not exist (an older layout) and
produced 21 dead symlinks across the bin surface historically.

### 5. Project tools

Multi-file tools (own Gemfile, test suite, git history) live in
`~/Me/OS/scripts/projects/<name>/` — not `bin/`. Three rules:

1. **Own VCS, private remote at creation.** The project is its own VCS home,
   gitignored from the scripts repo (see `checklist-converter`). The parent
   repo's remote does not back up gitignored projects, so before anything
   else: `gh repo create <name> --private --source . --push`. Small one-off
   utilities without their own VCS are tracked by the scripts repo directly
   instead (see `font-organizer`).
2. **Link the true entry point directly.** The junction symlink points at
   the project's runnable entry point — no intermediate link in
   `scripts/bin`:
   `ln -s /Users/bear/Me/OS/scripts/projects/<name>/bin/<tool> ~/.local/bin/<tool>`
3. **Anchor Bundler in the binstub** (Ruby projects) so the tool runs from
   any directory without `bundle exec`:

   ```ruby
   ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)
   require 'bundler/setup'
   ```

   Ruby's `__dir__` resolves symlinks, so the anchor holds through the
   junction link. Exemplar: `projects/hn-summary`.

### 6. Document it

Add a row to the relevant table in `~/Me/OS/scripts/README.md` (Family /
Standalone / Converters / Other; project tools go in the `projects/` list)
with the tool name, language, and one-line description.

## When NOT to use this skill

- **Fish functions** → `~/.config/fish/functions/`, not a bin tool.
- **App automations** (AppleScripts, Drafts actions) → `~/Me/OS/scripts/automations/`.
- **A repo's own executable surface** (repo-coupled scripts) → that repo's `bin/`, with an allowlist entry. See the repo's `bin/README.md`.
- **Installing a third-party tool** → use the package manager (brew/uv/cargo/mise). Don't hand-author what an installer owns.

## Common mistakes this skill prevents

1. Writing to `~/.local/bin/<tool>` directly → source lost to gitignore. **Author in `scripts/bin` or `scripts/projects/<name>/`.**
2. Symlink target `~/Me/scripts/bin/...` → dead link. **Use `/Users/bear/Me/OS/scripts/...`.**
3. Forgetting `chmod +x` → permission denied at runtime.
4. Wrong name pattern → unfindable, or collides with a family namespace.
5. Treating a repo-coupled script as standalone → it can't find its config siblings.
6. Project repo gitignored in `scripts/` without its own remote → no backup anywhere. **Private remote at creation.**
7. Junction link pointing at an intermediate link instead of the tool's true entry point → double indirection to debug. **Link directly to the entry point.**
