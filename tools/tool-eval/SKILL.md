---
name: tool-eval
description: Evaluate a third-party developer tool (code search, MCP server, CLI, grep alternative, etc.) against the user's existing stack. Produce a structured comparison, a filtered-for-actual-use assessment, and a clear adopt/pass/watch verdict with reconsideration criteria.
---

# Tool Evaluation Skill

Evaluate a software tool and produce a structured recommendation. This skill
encodes the methodology used to evaluate 10+ tools (code search engines, MCP
servers, grep alternatives, knowledge-base search tools) for a specific user
stack.

## When to Use

Activate when the user asks you to evaluate, assess, or compare a tool —
especially when they provide a GitHub URL. The user's typical framing: "assess
this tool", "compare against my existing stack", "should I install this?"

## The User's Stack (Context You Must Apply)

Every evaluation must account for the user's specific environment. The canonical
stack definition is stored at:

**https://gist.github.com/boticello/7c7d11db966444a76a5fb133e1d51f43**

Fetch it with:
```bash
gh gist view 7c7d11db966444a76a5fb133e1d51f43 --raw --filename STACK.md
```

Key points (full details in the gist):
- **Editor/Agent**: Zed with agent panel. MCP via `context_servers` in `settings.json`.
- **Active MCP**: Ken (8 tools), codebase-memory-mcp (14 tools, recommended for Python), Morph (codebase_search).
- **Built-in tools**: grep, find_path, read_file, terminal.
- **Primary repo**: Dotfiles (~96 files, shell + markdown). No structural tree-sitter.
- **Code repos**: Python, Go, TypeScript, Rust — tree-sitter available.
- **Package management**: mise + Homebrew. Install priority: Bun > mise npm > Homebrew > uv > Cargo.
- **VCS**: Jujutsu (jj). `.gitignore` files exist.
- **Tool selection**: Prefer local/free. MCP manifest is a scarce resource. cbm replaces Ken for structural queries on Python repos.
- **Key docs**: `RECOMMENDED-CODE-STACK.md` for install order and manifest impact.

## Evaluation Activities

The evaluation has five distinct phases. Complete all of them.

### Phase 1: Research

Gather sufficient information to understand the tool's architecture, features,
and integration model. Use multiple sources — never rely on the README alone.

**Research toolkit (in order):**

1. **fetch** the README — always first. Fastest path to feature list and install
   instructions.
2. **GitHub API tree** — `fetch https://api.github.com/repos/<owner>/<repo>/git/trees/main?recursive=1`.
   Reveals architecture (monorepo crates, plugin manifests, MCP server entry points)
   without reading source.
3. **github_codebase_search** — for deep understanding of MCP tools, architecture,
   unique features. Note: Morph can fail with 500s on some repos. Have a fallback.
4. **Targeted source fetches** — when steps 2-3 reveal key files, fetch them
   directly: `https://raw.githubusercontent.com/<owner>/<repo>/main/<path>`.
5. **Nia sources check** — `~/.agents/skills/nia/scripts/nia.sh sources` to see
   if the repo is already indexed. If yes, search it directly rather than
   re-fetching.

**What you must determine before Phase 2:**

- [ ] Architecture: MCP server, CLI tool, Claude Code plugin, library, daemon?
- [ ] MCP tools: exact count, names, purpose of each
- [ ] Integration model: how does it connect to Zed? `context_servers` config? CLI via `terminal`? Plugin system?
- [ ] Languages supported: which tree-sitter grammars? Text/config formats?
- [ ] Search model: semantic (embeddings), lexical (BM25/FTS5), regex only, hybrid?
- [ ] Model/download requirements: any models to download? Size?
- [ ] Install method: Homebrew formula? npm? Cargo? Which tier in the user's priority list?
- [ ] Agent instructions: auto-delivered (MCP initialize) or manual (AGENTS.md)?
- [ ] Published benchmarks or quality claims

### Phase 2: Comparison

Map the tool against every relevant tool in the user's existing or considered
stack. Build a comparison table.

**Standard comparison dimensions:**

| Dimension | Why it matters |
|-----------|---------------|
| Architecture (CLI vs MCP vs daemon vs plugin) | Determines integration path and per-call overhead |
| MCP tool count | Tool manifest is a scarce resource — each tool adds cognitive load |
| Search model and quality | BM25+vector > FTS5 text > regex only |
| Language support | Must cover the user's actual repos (shell, markdown, Python, Go, TS, Rust) |
| Structural navigation (definition, callers, references) | Ken currently provides this; does the new tool overlap or complement? |
| Literal/regex search | Currently provided by built-in grep; does the tool replace or supplement? |
| Model/download footprint | User is sensitive to large downloads (rejected QMD for ~2GB) |
| Agent-native design | Auto-delivered instructions reduce AGENTS.md maintenance |
| Install method | Must fit the user's mise/Homebrew priority list |
| `recently_changed` equivalent | Ken has this and it's used regularly; losing it is a regression |

**Always include these tools in comparisons:** Ken, codebase-memory-mcp, ugrep,
and the built-in grep. Include colgrep, FFF, CodeGraph, Continuum, codesearch,
CocoIndex, Understand-Anything, QMD, or Zread only when they share a category.

### Phase 3: Filtering

Remove features irrelevant to the user's actual context. This is the most
important phase — it distinguishes a generic review from a useful recommendation.

**Apply these filters in order:**

1. **Repo filter**: Does the tool work on the dotfiles repo (shell + markdown)?
   If structural tools need tree-sitter grammars the repo doesn't have, those
   tools are dead weight for dotfiles. Note this explicitly.

2. **Code-project filter**: If the tool is weak for dotfiles but strong for
   Python/Go/TS/Rust projects, separate the assessment: "for dotfiles: X; for
   code projects: Y."

3. **MCP manifest filter**: Count the tools. If >8, flag as "large manifest
   impact." If the tool overlaps with Ken's tools, flag the ambiguity.

4. **Integration filter**: Can it connect to Zed? MCP server → `context_servers`.
   CLI → `terminal`. Claude Code plugin → requires Claude Code (likely pass if
   user doesn't use it daily).

5. **Install filter**: Does it fit the user's priority list? Homebrew formula
   is best. Cargo from git is worst. Note which tier.

**Output a table:** "Filtered for Actual Use" — list each capability, whether it
works for the user's repos, and whether it's already covered by an existing tool.

### Phase 4: Judgment

Make a clear recommendation. Avoid hedging. The user needs a decision, not a
list of pros and cons.

**Verdict categories:**

| Verdict | Meaning | When to use |
|---------|---------|------------|
| **Install** | Add to the stack now | Clear win, no overlap, low manifest impact |
| **Swap** | Replace an existing tool | Strict superset of something already installed |
| **Evaluate** | Install and test, decide later | Promising but needs empirical validation |
| **Conditional** | Install only if condition met | Value depends on repo type or project phase |
| **Pass** | Don't install | Overlaps with existing tools without being better, or irrelevant to user's needs |
| **Pass/watch** | Don't install now, revisit later | Has potential but missing a key feature |

**Decision principles (from 10+ evaluations):**

1. **Category mismatch is a feature, not a bug.** Tools that occupy a different
   slot (visual dashboard, knowledge-base search, pattern matching) don't compete
   with Ken/colgrep and are easier to adopt. The best additions are orthogonal.

2. **MCP tool count is a cost.** Each tool in the manifest adds cognitive load
   on the agent's tool selection. A tool with 3 MCP tools that replaces grep+
   find_path is better than one with 10 tools that partially overlaps with Ken.

3. **CLI tools (0 MCP impact) are cheaper than MCP servers.** colgrep and ugrep
   add zero manifest tools because they're invoked via `terminal`. Prefer this
   pattern when possible.

4. **Same search model as Ken = no reason to switch.** If a tool uses model2vec
   (same as Ken), it needs another differentiator (more languages, cross-agent
   memory, framework awareness) to justify adoption.

5. **Language support must match the user's actual repos.** A tool with 22
   languages but no shell/markdown support is less useful for the dotfiles repo
   than a tool with 5 languages that includes shell.

6. **Agent-native design reduces ongoing maintenance.** Auto-delivered
   instructions (MCP initialize) beat manual AGENTS.md updates.

**Every verdict must include:**
- **Revisit criteria**: specific conditions that would change the recommendation
  (e.g., "if it adds shell tree-sitter support", "if Ken stagnates")
- **Watch items**: signals to monitor (star growth, release frequency, community)

### Phase 5: Writing

Produce the evaluation file. Standard filename: `EVAL-<tool-name>.md`. Place it
in the dotfiles repo root.

**Required sections (in order):**

```markdown
# Evaluation: ToolName (owner/repo)

Evaluated YYYY-MM-DD against [list relevant existing tools].

## Summary

One paragraph. Architecture, key numbers (MCP tools, languages, model size),
license. Bold headline with the verdict in one sentence.

## What It Is

ASCII architecture diagram if complex. List of MCP tools with purpose column.
Install command.

## Comparison

Table with 8-12 rows. Include Ken, colgrep, ugrep, and the built-in grep at
minimum. Bold the cells where the evaluated tool wins.

## The Unique Sell

3-6 subsections. Each: what it does that nobody else does, why it matters for
this user. Be specific — "faster than grep" is not a unique sell.

## Where It Falls Short

3-6 subsections. Each: a concrete limitation. "Only 5 languages — no shell,
no markdown. Dotfiles repo gets nothing from structural tools."

## Filtered for Actual Use

Two-column table: "What you'd actually use" | "Already covered by?".
Separate dotfiles and code-projects if the answer differs.

## Verdict

Bold verdict word. 2-3 sentences of reasoning. Revisit criteria as bullet
list. Watch items as bullet list.
```

**Writing rules:**
- No hedging in the verdict. "Could be useful" → pick a lane.
- Every comparison row must have a clear winner for the user's context.
- "Filtered for Actual Use" must be honest — if 10 of 13 tools are dead weight
  for the user's primary repo, say so.
- Include a "Tooling Feedback" section at the end if the research process
  exposed limitations in the evaluation toolchain (Morph failures, Nia gaps).
- Reference the existing evaluation files as examples. The user has `EVAL-*.md`
  files in the dotfiles repo that demonstrate the expected format and depth.

## Supporting Files

- `examples/` — this skill's directory can contain reference evaluations.
  The user's dotfiles repo has 10 `EVAL-*.md` files that serve as the primary
  examples. Point the agent at those rather than duplicating them here.
