# Tool Evaluation Quick Reference

The user's dotfiles repo contains 10 example evaluations at `dotfiles/EVAL-*.md`.
These define the expected format and depth. This card summarizes the reusable
framework distilled from those evaluations.

## The Five Phases

1. **Research** — fetch README, GitHub tree, source files. Determine architecture,
   MCP tools, languages, search model, install method.
2. **Compare** — map against Ken, colgrep, ugrep, built-in grep. 8-12 row table.
3. **Filter** — strip features irrelevant to the user's actual repos and stack.
4. **Judge** — pick a verdict. No hedging.
5. **Write** — `EVAL-<name>.md` with 7 required sections.

## Verdict Ladder (most → least recommended)

| Verdict | Signal |
|---------|--------|
| **Install** | Clear win. No overlap. Low manifest impact. |
| **Swap** | Strict superset of something already installed. |
| **Evaluate** | Promising but needs empirical testing. |
| **Conditional** | Value depends on repo type or project phase. |
| **Pass** | Overlaps without being better. Irrelevant. Too heavy. |
| **Pass/watch** | Has potential but missing a key feature. Revisit criteria attached. |

## The User's Stack (Quick Reference)

Canonical source: https://gist.github.com/boticello/7c7d11db966444a76a5fb133e1d51f43

- **Primary**: Zed agent. MCP via `context_servers` in `settings.json`.
- **Active MCP**: Ken (8 tools), Morph (codebase_search). codebase-memory-mcp (14 tools, recommended for Python).
- **Built-in**: grep, find_path, read_file, terminal.
- **Primary repo**: Dotfiles — ~96 files, shell + markdown. No struct. tree-sitter.
- **Code repos**: Python, Go, TypeScript, Rust — struct. tree-sitter available.
- **Install**: mise (node, bun, python) + Homebrew. Priority: Bun > mise npm > Homebrew > uv > Cargo.
- **VCS**: Jujutsu (jj). `.gitignore` files exist.

## Decision Principles (Compressed)

1. Category mismatch = feature (orthogonal tools don't compete).
2. MCP tool count = cost (each tool adds cognitive load).
3. CLI (0 MCP) < MCP server (N MCP).
4. Same search model as Ken = need another differentiator.
5. Language support must match actual repos.
6. Agent-native design (auto instructions) > manual AGENTS.md.

## Filter Checklist (Apply in Order)

1. Works on dotfiles (shell + markdown)?
2. Works on code projects (Python, Go, TS, Rust)?
3. MCP tool count: ≤3 great, 3-8 ok, >8 flag.
4. Overlaps with Ken's tools? Flag the ambiguity count.
5. Connects to Zed? MCP → context_servers. CLI → terminal. Plugin → requires that agent.
6. Install tier: Homebrew best, Cargo from git worst.

## Required Evaluation Sections

1. Summary (one paragraph + bold headline)
2. What It Is (architecture + MCP tools table + install)
3. Comparison (8-12 row table, bold wins)
4. The Unique Sell (3-6 subsections)
5. Where It Falls Short (3-6 subsections)
6. Filtered for Actual Use (two-column table)
7. Verdict (bold word + reasoning + revisit criteria + watch items)
