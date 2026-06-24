---
name: zcode
description: >-
  How to configure and troubleshoot the ZCode desktop app — MCP servers, skills,
  config files, and the relationship between ZCode and the opencode CLI. Use
  whenever the task involves adding an MCP server to ZCode, wiring a tool into
  ZCode, debugging why a ZCode session can't see MCP tools or skills, or
  comparing ZCode to opencode/Codex/Zed. Trigger on: ZCode, zcode, "ZCode
  settings", "MCP in ZCode", "ZCode won't see my tools", "import MCP",
  .zcode/config.json, ~/.zcode.
---

# ZCode desktop app

ZCode is a desktop application (Electron) built on the opencode runtime, by
Z.AI. It is **not** the same thing as the `opencode` CLI, despite sharing the
same config schema (`https://opencode.ai/config.json`). Conflating the two is
the single most common and expensive mistake when configuring ZCode. This skill
exists because that conflation caused a multi-hour debugging session.

## The one fact that prevents most ZCode config errors

**ZCode (desktop app) and `opencode` (CLI) are different programs with different
config-loading behaviour, even though they share `$schema`.** Verify which one
you are configuring before touching any file.

| Program | What it is | How to verify it |
|---|---|---|
| **ZCode** | `/Applications/ZCode.app` (Electron desktop app) | Logs: `~/.zcode/v2/logs/<date>.log`. UI: Settings panel. |
| **opencode** | `/opt/homebrew/bin/opencode` (CLI binary) | `opencode mcp list` (reads `~/.config/opencode/opencode.json`) |

A green `opencode mcp list` result proves the **CLI** sees the server. It says
**nothing** about whether the **ZCode app** sees it. If a user reports "ZCode
can't see my tools," `opencode mcp list` is the wrong diagnostic — check the
app's logs and UI instead.

## MCP servers — import, don't hand-wire

### The intended path: import from another harness

ZCode's Settings → MCP Servers panel has an **Import** button (top-right). It
scans the MCP configs of other installed harnesses — **Codex CLI**
(`~/.codex/config.toml`) and **opencode** (`~/.config/opencode/opencode.json`)
— and lists their servers for one-click import into ZCode (User or Workspace
scope).

**This is the canonical way to add an MCP server to ZCode.** It mirrors how
other harnesses (e.g. Craft Agents) work: get the server working in one harness
first, then import.

The correct sequence for adding *any* new MCP server to ZCode:

1. Get it working in **Codex** or **opencode** first (those use plain config
   files you can edit and test directly).
2. Verify it there with a real tool call that returns data from the target
   system.
3. Open ZCode → Settings → MCP Servers → Import → select the server → choose
   scope (User for everywhere, Workspace for one project).
4. Restart ZCode and verify in a fresh session.

### Why hand-editing config files fails for ZCode

Do **not** try to add an MCP server to ZCode by editing these files — none of
them are how the app loads MCP:

- `~/.zcode/v2/config.json` — **providers only** (model providers, built-in
  app config). No `mcp` key is read from here. Adding one is silently ignored.
  (This is the trap that cost hours: it looks like the right file because it
  has the opencode `$schema`, but the app doesn't implement the `mcp` section.)
- `~/.config/opencode/opencode.json` — that's the **opencode CLI's** file. The
  ZCode app does not read it for MCP. (It *is* scanned by the Import button, so
  it's still worth keeping servers there.)
- `~/.zcode/v2/setting.json` — app settings (locale, recent projects), not MCP.

### Where imported/scoped servers actually live

When you import or add an MCP server via the UI, ZCode writes it to:

- **Workspace scope:** `<workspace>/.zcode/config.json`, shape:
  ```json
  { "mcp": { "servers": { "<name>": { "enabled": true, "command": "...", "args": [], "type": "stdio" } } } }
  ```
- **User scope:** app-managed state (not meant for hand-editing).

If you must hand-edit (e.g. scripting), the workspace file is the one that
works — but prefer the UI/import path unless you have a reason not to.

## Verifying an MCP server works in ZCode

Do **all** of these; each catches a different failure:

1. **Registered:** `~/.zcode/v2/logs/<date>.log` — search for `session/resume`
   lines. They include `"mcpServerCount": N, "mcpServerNames": ["..."]`. If
   your server name isn't in that list, ZCode didn't load it (wrong scope,
   wrong file, or it failed to parse).
2. **Connected:** the Settings → MCP Servers panel shows a green status. If it
   shows failed, the server process errored on boot.
3. **Tools surfaced:** this is the one that bites. ZCode does **auto-tool-
   selection** — it distributes MCP tools to agents *by context*, not all at
   once. A connected server with 19 registered tools may still expose **zero**
   tools to a given session if the context doesn't match. If the server is
   connected but tools don't appear, this auto-selection layer is the likely
   cause, not a connection failure. Trigger the relevant skill or phrase the
   task in terms that match the server's domain to surface the tools.

The probe recipe for the underlying server (independent of ZCode) — run over
stdio to the wrapper/command, non-interactive (macOS bash 3.2 has no `coproc`):

```bash
{ printf '%s\n' '<initialize json>'; sleep 5;
  printf '%s\n' '<notifications/initialized json>'; sleep 5;
  printf '%s\n' '<tools/list json>'; sleep 8; } | <mcp-command>
```

Delays matter — many MCP servers register tools asynchronously after
`initialize`. A zero-delay probe races and gets false "Method not found" errors.

## Skills — discovery paths

ZCode discovers skills (highest priority first):

1. `<project>/.zcode/skills/<name>/SKILL.md`
2. `<project>/.agents/skills/<name>/SKILL.md`
3. `~/.zcode/skills/<name>/SKILL.md`
4. `~/.agents/skills/<name>/SKILL.md`

If a skill isn't loading, check it's in one of these and the `name` in
frontmatter matches the directory name. Log warnings of the form
`file.stat FAIL ENOENT .../some/skill/SKILL.md` indicate ZCode is probing a
path that doesn't resolve — usually a stale reference, not necessarily fatal
(the skill may still load from another path).

## Documentation — get it before guessing

**Do not reverse-engineer ZCode behaviour from the app bundle (`app.asar`,
bundled `.cjs`) or infer it from the opencode CLI.** Both are slow and have
produced confidently-wrong answers. ZCode publishes docs; use them.

Canonical doc URLs (fetch these rather than guessing):
- MCP services (incl. import): `https://zcode.z.ai/en/docs/mcp-services`
- Skills: `https://zcode.z.ai/en/docs/skills`
- Config: `https://zcode.z.ai/en/docs/config`

If the docs have been Nia-indexed (see AGENTS.md Nia workflow), search the
index first. If not, fetch the relevant page directly. **Reading the docs is
always faster than reverse-engineering the binary** — a session spent grepping
`zcode.cjs` for config strings took longer than a single docs fetch would have.

## The meta-rule: verify the primary artifact

ZCode-specific config errors are a symptom of a general failure mode: trusting
a proxy signal (a green CLI check, a shared schema, a guide's example) instead
of the primary artifact. Before declaring any ZCode wiring step complete:

- **For "is the server configured":** the artifact is the ZCode app's own log
  (`mcpServerNames` on session/resume) or UI — not `opencode mcp list`.
- **For "is the server working":** a real tool call returning data from the
  target system — not a successful `initialize` handshake.
- **For "are tools available to the agent":** the agent actually calling the
  tool — not the server being connected (auto-tool-selection can hide connected
  servers).

If the only evidence is a proxy that answers a *different* question than the
one you need ("does the CLI see it?" when you need "does the app see it?"),
that is not verification — keep going.
