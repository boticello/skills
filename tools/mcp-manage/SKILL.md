---
name: mcp-manage
description: Add, edit, or deploy MCP servers across all agent harnesses from one canonical source. Use before hand-editing any harness's MCP config, or when adding a new MCP server.
---

# mcp-manage

Manage MCP server configuration across **all** agent harnesses from a single
canonical source. The cure for the "edit 2–4 config files by hand and they
drift" problem. Use this skill **before** hand-editing any harness's MCP
config, or when adding a new MCP server.

## The one fact that prevents most errors

**All MCP config is driven from one canonical store.** Hand-edit the store,
then deploy — never edit a live harness config's MCP section directly.

```
~/Me/repos/mcps/              ← AUTHORITATIVE (hand-edit here)
├── servers.toml              ← the canonical server model
├── harnesses.toml            ← per-harness adapter data (THE SIGNPOST)
├── allowlist.txt             ← live servers deploy leaves unmanaged
└── deploy/mcp-deploy         ← the deploy script
```

`harnesses.toml` is the **single signpost** for where each harness stores its
MCP config. If you ever have to grep or search to find a harness's config file,
that table is incomplete — fix it there, don't work around it.

## The harnesses (read this table first — never grep for config files)

| Harness | Config file | Format | Merge |
|---------|-------------|--------|-------|
| **codex** | `~/.codex/config.toml` | TOML (`[mcp_servers.X]` blocks) | span-replace (blocks) |
| **opencode** (CLI) | `~/.config/opencode/opencode.json` | JSON (`mcp` key) | overlay |
| **zcode** (desktop) | `~/.zcode/cli/config.json` | JSON (`mcp.servers` key) | overlay |
| **warp** | `~/.warp/.mcp.json` | JSON (`mcpServers` key) | replace |
| **zed** | `~/.config/zed/settings.json` | JSONC (`context_servers` key) | span-replace |

**codex ≠ opencode ≠ zcode.** Three different programs, three different files.
codex is the Codex CLI. opencode is the opencode CLI. **ZCode is the desktop
app** — it does NOT read opencode's config despite sharing the `$schema`. See
the `zcode` skill for why (the conflation is the single most common mistake).

## How to add a new MCP server

### 1. Decide the mechanism: wrapper or inline?

**Prefer a wrapper script** for any server that needs a secret. The wrapper
resolves the key from 1Password at spawn via `op-env`, so no secret is ever
inline in a config file. This is the only mechanism that works reliably across
*all* harnesses — especially ZCode (whose process env is empty unless launched
via op-env) and Codex (whose per-tool gating only works on local-process
servers).

Wrapper template (see `~/.local/bin/lark-mcp-wrapper.sh`, `mistral-ocr-wrapper.sh`):

```bash
#!/usr/bin/env bash
set -eu
export API_KEY="$(/Users/bear/.local/bin/op-env read op://AI-Keys/<item>/credential)"
exec <real-command-and-args>
```

For **remote MCP servers** (HTTP endpoints), use the parameterised
`~/.local/bin/mcp-remote-wrapper.sh`:

```bash
mcp-remote-wrapper.sh <endpoint-url> <op-reference> [auth-scheme]
# e.g. mcp-remote-wrapper.sh https://api.z.ai/api/mcp/zread/mcp op://AI-Keys/ai-zai/credential
```

It resolves the key from 1Password and proxies via `mcp-remote` over stdio.
This is how broken ZCode remote imports get fixed (see "Why ZCode remotes
break" below).

### 2. Add the canonical entry to `servers.toml`

```toml
[servers.my-server]
intent = "local"          # or "remote"
command = "/path/to/wrapper.sh"
args = []                 # or ["arg1", "arg2"]
harnesses = ["codex", "opencode", "zcode", "zed"]   # which harnesses get it
# env = { VAR = "{env:VAR_NAME}" }   # ONLY if not wrapper-based; {env:} is the only secret token
# startup = 45            # Codex-only startup_timeout_sec
```

Use `overrides.<harness>` when a harness needs a different mechanism (e.g.
Codex uses a local wrapper for a remote server to unlock per-tool gating):

```toml
[servers.my-server.overrides.codex]
intent = "local"
command = "/Users/bear/.codex/bin/some-wrapper.sh"
args = ["https://the-remote-url/mcp"]
url = "__clear"           # suppress fields the wrapper absorbs
auth = "__clear"
```

`__clear` removes a field the canonical server declares but the override
shouldn't carry.

### 3. Deploy + verify (ALL THREE STEPS — skipping any is the #1 mistake)

```bash
cd ~/Me/repos/mcps
./deploy/mcp-deploy list                                # confirm the server appears
./deploy/mcp-deploy deploy --harness <name> --dry-run   # 1. preview (no write)
./deploy/mcp-deploy deploy --harness <name>             # 2. WRITE to live (backs up)
./deploy/mcp-deploy deploy --harness <name> --dry-run   # 3. confirm no-op (idempotent)
```

**A clean dry-run is NOT verification.** It only proves the render is correct.
It does NOT mean the live config changed, and it does NOT mean the running app
sees the change. The three failure modes this catches:

1. **You dry-ran but never deployed.** The live config is unchanged. Always run
   the real `deploy` (step 2), then confirm with `--dry-run` again (step 3)
   which should report `unchanged`.
2. **The config is correct but the app hasn't reloaded it.** Desktop apps
   (ZCode, Zed) hold config in memory until restarted. After deploying to
   ZCode/Zed, **restart the app** and check its logs:
   - ZCode: `grep mcpServerNames ~/.zcode/v2/logs/$(date +%Y-%m-%d).log | tail -1`
     — your server must be in that list.
   - Zed: check Settings → Context Servers for green status.
3. **The server connects but tools don't surface.** ZCode does auto-tool-
   selection by context. Trigger the relevant skill or domain phrasing to
   surface tools. A connected server ≠ tools available to the agent.

**The strongest verification is a real tool call returning data** — not a
successful `initialize` handshake, not a green status light. Probe over stdio
independent of the app to confirm the wrapper resolves secrets and reaches the
server:

```bash
{ printf '%s\n' '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"probe","version":"0.1"}}}'; sleep 5;
  printf '%s\n' '{"jsonrpc":"2.0","method":"notifications/initialized"}'; sleep 5;
  printf '%s\n' '{"jsonrpc":"2.0","id":2,"method":"tools/list"}'; sleep 8; } | <wrapper-command>
```

Re-running `deploy` with no canonical change is a no-op. Every write backs up
to `~/.local/state/mcp-backups/<timestamp>/`.

### 4. Commit the canonical change

```bash
git add servers.toml harnesses.toml && git commit
```

## Why ZCode remotes break (and how this fixes them)

The zcode skill recommends importing via the UI. **In practice, UI imports from
Codex/opencode produce broken ZCode configs** — merged command arrays ZCode
can't parse, `{env:VAR}` that resolves empty (ZCode's process env is empty
unless launched via op-env), `enable`/`enabled` field conflicts. The broken
imports get disabled by hand as a workaround.

`mcp-deploy` fixes this by generating correct ZCode-native configs
programmatically: wrapper scripts instead of `{env:VAR}` remotes, clean field
shapes, no import artifacts. **This is not fighting ZCode's workflow — it's
the fix for a workflow that produces broken results.**

### The verified pattern for ZCode remote servers

Remote MCP servers (zread, web-reader, web-search-prime, context7) that work
fine as native `{type: "remote", url: ...}` in opencode/Codex **break in
ZCode** because ZCode's process env doesn't carry the `{env:VAR}` keys (unless
launched via op-env). The symptom: the server returns a non-JSON-RPC error
envelope (`{"code","msg","success"}`) and ZCode logs union-validation errors.

The fix (verified working in a live ZCode session): convert each to a **local
wrapper** using the parameterised `~/.local/bin/mcp-remote-wrapper.sh`, which
resolves the key from 1Password at spawn and proxies via `mcp-remote`:

```toml
[servers.my-remote.overrides.zcode]
intent = "local"
command = "/Users/bear/.local/bin/mcp-remote-wrapper.sh"
args = ["https://the-remote-url/mcp", "op://AI-Keys/the-item/credential"]
url = "__clear"
auth = "__clear"
startup = "__clear"
enabled = true
```

ZCode does support `command` + `args` (confirmed in its docs and verified by
tool calls returning data), so the parameterised form works — no need for
per-server wrapper scripts.

## Secret handling (the rules)

- Canonical stores **only** `{env:VAR_NAME}` tokens. Never a real key.
- Each harness renders to its native syntax: opencode/zcode keep `{env:VAR}`,
  Warp becomes `${VAR}`, Zed writes the bare var name (its GUI launch env
  supplies the value).
- For ZCode/Zed, **prefer wrappers** — `{env:VAR}` in those apps resolves from
  a process env that may be empty. The wrapper reads 1Password directly.
- Real values live in the shell env, populated from 1Password by the
  `op-service-account-env` launch agent (which renders `ai.env.tpl`).

## Per-tool approval gating (Codex-only)

Codex supports `[mcp_servers.X.tools.<tool>] approval_mode = "approve"` tables.
Express these canonically and they emit for Codex only:

```toml
[servers.my-server.gating.codex.tools]
tool_name_one = "approve"
tool_name_two = "approve"
```

## When to use this skill vs hand-editing

| Situation | Use this skill |
|-----------|---------------|
| Adding a new MCP server | ✅ always |
| Editing an existing server's config | ✅ edit `servers.toml`, redeploy |
| Adding a server to one more harness | ✅ add the harness to `harnesses = [...]` |
| Debugging a broken server in one harness | Check the `zcode`/`troubleshoot-codex` skills first; if it's a config-shape issue, fix it in canonical |
| Emergency one-off hotfix | Hand-edit the live file, then backport to `servers.toml` after |

## Reference

- Canonical store: `~/Me/repos/mcps/`
- Design rationale: `~/Me/repos/mcps/docs/design-rationale.md`
- Field-shape divergence (the 5 conversion breaks): `~/Me/repos/mcps/docs/field-shape-divergence.md`
- Deploy script: `~/Me/repos/mcps/deploy/mcp-deploy`
- Harness signpost: `~/Me/repos/mcps/harnesses.toml` (the table at the top of this skill mirrors it)
