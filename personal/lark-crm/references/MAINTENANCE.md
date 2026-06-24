# Lark CRM — maintenance runbook

Operational guidance for **extending and maintaining** the Lark CRM integration
— adding it to a new harness, setting up Base automations, revisiting deferred
decisions. This is the reference a future agent session should read *before*
doing any of those tasks. It exists because the initial setup hit several
avoidable traps; each lesson below is paired with the exact check that prevents
a repeat.

For day-to-day CRM *operation* (creating records, moving stages), read
`SKILL.md` instead — this file is about the plumbing, not the data.

---

## The wrapper script and the no-ambient-token rule

The MCP server is `~/.local/bin/lark-mcp-wrapper.sh`. It resolves the Lark app
credentials from 1Password (`op://AI-Keys/ai-lark/{app_id,app_secret}`) at spawn
time via `op-env`, exports them as `APP_ID`/`APP_SECRET` env vars, and `exec`s
`npx -y @larksuiteoapi/lark-mcp mcp` with **no secret-bearing CLI flags**.

lark-mcp reads its config from env (`dist/utils/constants.js: OAPI_MCP_ENV_ARGS`):
`APP_ID`, `APP_SECRET`, `LARK_TOKEN_MODE`, `LARK_TOOLS`, `LARK_DOMAIN`. The `-a`/`-s`
CLI flags are overrides, not the only path.

### ⚠️ CRITICAL: pass secrets via env, never via `-s` flag

**The first version of this wrapper passed `APP_SECRET` as the `-s` CLI flag.
That leaked the secret into `ps`/`pgrep` output — world-readable to any process
on the machine.** CLI args are visible to all users via `ps aux`; env vars are
not (macOS restricts environ reads to the same user / root). Passing via env is
strictly safer. A future session reverted to flags because the `--help` text
implies flags are required — **they are not; `--help` is misleading**. Always
verify against the source (`dist/utils/constants.js`), not the help text. The
env-var form is load-bearing for the security model; do not "simplify" back to
flags.

The other wrappers in `bin/` (`morph-mcp-wrapper.sh`, `op-env`) export their
secret as an env var too — follow that pattern, not a flag pattern.

### ⚠️ The wrapper is NOT version-controlled

`bin/` is gitignored wholesale in the Dotfiles repo (so are `op-env` and ~60
other scripts). The wrapper is **machine-local only**. Implications:

- The SKILL.md and harness configs travel via jj; the wrapper does not.
- **Syncing to another host requires recreating `bin/lark-mcp-wrapper.sh`
  manually**, plus the 1Password items, plus `op-env`, plus Node ≥18.
- Do not "fix" this by un-ignoring `bin/` or adding a negation — the user
  deliberately keeps `bin/` local (confirmed decision). If a wrapper needs to be
  portable, relocate it to a tracked path and update all harness configs; do not
  assume un-tracking is wanted.

### Editing the wrapper

The dotfiles `bin/` is symlinked to `~/.local/bin`, so editing
`~/Me/OS/Dotfiles/bin/lark-mcp-wrapper.sh` updates `~/.local/bin/` live — no
extra symlink step. But **the Edit tool resets the executable bit** — after any
edit, run `chmod +x ~/Me/OS/Dotfiles/bin/lark-mcp-wrapper.sh` or the wrapper
fails with "Permission denied" (this bug bit the setup session).

---

## Adding the integration to a new harness

This is a mechanical, near-identical task every time. Do NOT treat it as fresh
exploration. The pattern:

1. **Find the harness's MCP config file.** One of:
   - **opencode CLI:** `~/.config/opencode/opencode.json` → `mcp` object
     (dotfiles-managed: `~/Me/OS/Dotfiles/config/opencode/opencode.json`).
     Shape: `{ "type": "local", "enabled": true, "command": ["/abs/path/to/wrapper.sh"] }`.
     Verify with `opencode mcp list`.
   - **ZCode (desktop app):** managed via **Settings → MCP Servers UI only**.
     Does NOT read a `mcp` block from `~/.zcode/v2/config.json` (providers only)
     or from `~/.config/opencode/opencode.json`. Easiest path: use the UI's
     **Import** feature, which scans the opencode.json and Codex config.toml.
     Workspace-scoped servers land in `<workspace>/.zcode/config.json`. (See
     "⚠️ ZCode ≠ opencode CLI" below — this was a three-iteration trap.)
   - **Codex:** `~/.codex/config.toml` → `[mcp_servers.NAME]` block (app-owned,
     NOT dotfiles-managed). Shape: `command = "..."`, `args = []`, plus per-tool
     `[mcp_servers.NAME.tools.<tool>]` approval blocks.
   - **Zed:** `~/.config/zed/settings.json` → `context_servers` object
     (dotfiles-managed). Shape: `{ "command": "...", "args": [], "env": {} }`.
2. **Point it at the same wrapper** — `~/.local/bin/lark-mcp-wrapper.sh`. No
   harness needs its own copy of the secret logic; that's the whole point of the
   wrapper.
3. **No `environment` block needed** — the wrapper resolves secrets itself.
   Harness configs that leak `{env:VAR}` interpolation are unnecessary here.
4. **Restart the harness.** MCP servers spawn at session start, not on config
   reload (Zed does reload settings, but spawns on assistant-session open).

### ⚠️ ZCode ≠ opencode CLI

The `opencode` CLI binary and the **ZCode desktop app are different programs**
with different config mechanisms, despite the same `$schema`. Conflating them
cost a full debugging session:
- `opencode mcp list` reads `~/.config/opencode/opencode.json` and reported
  `lark-crm ✓ connected` — but that proved *nothing* about the ZCode app.
- The ZCode app reads its MCP config from the Settings UI / `<workspace>/.zcode/config.json`,
  NOT from the opencode CLI's config. Editing `~/.zcode/v2/config.json` (adding
  a `mcp` block) is **silently ignored** — that file is providers-only.
- **Lesson:** for any "ZCode" task, confirm which program is meant. If it's the
  desktop app, verify via the app's own UI/logs (`~/.zcode/v2/logs/`), not via
  the `opencode` CLI. The logs show `mcpServerCount` / `mcpServerNames` in
  session/resume lines — that's the authoritative "is it registered?" signal.

### Verification (always do this, it's cheap)

After wiring, confirm the server actually registers tools — don't trust the
config alone. Send an MCP `initialize` + `tools/list` over stdio to the wrapper
and check bitable tools appear. A prior session declared success on config
alone and shipped a broken wrapper (`preset.bitable.default` → zero tools). The
live check caught it. See "lark-mcp gotchas" below for the probe shape.

---

## lark-mcp gotchas (verified against v0.5.1)

These cost real debugging time. None are documented in the upstream guide.

### 1. The preset name in the guide is wrong

`-t preset.bitable.default` registers **zero tools** (server returns
"Method not found" for `tools/list` — silently). The correct presets:
- `preset.base.default` — search/list/get/create/update (the CRUD core)
- `preset.base.batch` — adds batchCreate/batchUpdate
- Use `-t "preset.base.default,preset.base.batch"` for full CRM coverage.
- `preset.default` loads everything (18+ tools, too broad — avoid).
Canonical preset list:
https://github.com/larksuite/lark-openapi-mcp/blob/main/docs/reference/tool-presets/presets.md

### 2. Tool names are snake_case on the wire, not dotted

The registry names tools `bitable.v1.appTableRecord.search` (dotted) but the
**MCP client sees snake_case**: `bitable_v1_appTableRecord_search`. Harness
config and skill docs must use snake_case. The upstream guide uses dotted names
throughout — wrong.

### 3. Tool arguments use the Lark OpenAPI envelope, not a flat shape

The guide's `{"app_token":"...","table_id":"...","fields":{...}}` is wrong.
The real shape (from the tool's `inputSchema`):
```json
{
  "path": {"app_token": "...", "table_id": "..."},
  "params": {"page_size": 20, "page_token": "..."},
  "data": {"fields": {...}}          // for create/update
  // "data": {"filter": {...}, "sort": [...]}  // for search
}
```
`path` is **required** — omitting it gives a validation error, which is
actually a good sign (means the request reached Lark's schema validator, i.e.
auth worked).

### 4. A validation error = auth succeeded

If a tool call returns `{"code":..., "msg":"Invalid arguments..."}` or a JSON
schema error, **the whole chain works** (1Password → op-env → wrapper → tenant
token → API). The failure is purely the argument shape. Only a scope/permission
error means something upstream is broken.

### 5. MCP probe recipe (non-interactive, macOS bash 3.2 compatible)

macOS ships bash 3.2 (no `coproc`). Use a piped sequence with sleeps:
```bash
{ printf '%s\n' '<initialize json>'; sleep 4;
  printf '%s\n' '<notifications/initialized json>'; sleep 4;
  printf '%s\n' '<tools/list json>'; sleep 8; } | ~/.local/bin/lark-mcp-wrapper.sh
```
Delays matter — lark-mcp registers tools asynchronously after initialize. A
zero-delay probe races and gets "Method not found" even when tools load.

---

## Decision record: tenant token (no calendar)

**Decision:** operate under the Lark app tenant token (`--token-mode
tenant_access_token`). Full Base CRUD, never expires, no re-login.

**Cost:** no personal calendar access (interview/meeting events can't be created
via the API under this mode).

**Why this was chosen over user-token/OAuth:** the user-token path
(`--token-mode user_access_token --oauth` + a one-time `lark-mcp login` browser
flow) expires every ~2h. In a **headless stdio MCP server** spawned by
ZCode/Codex/Zed, there's no clean way to pop a browser mid-session when the
token expires. The `--oauth` flag's "auto request login on expiry" behaviour is
documented as Beta and its behaviour in an MCP (non-interactive) context is
unverified. Adopting it risks calendar calls silently failing mid-session.

**Do not re-litigate this without resolving the headless-refresh question first.**
A prior session started down the "let's enable calendar" path and had to be
parked because it would reverse this decision without addressing the expiry
problem. If revisiting: research whether (a) `--oauth` can do a non-interactive
refresh using a stored refresh_token, or (b) a cron job can refresh the token
out-of-band, before changing the wrapper.

The current wrapper is structured so the upgrade is a one-line flag change
(`--token-mode user_access_token --oauth`) plus `-t` adding
`preset.calendar.default` — but only *after* the expiry question is answered.

---

## Setting up Lark Base automations (meta-lesson)

Base automations are configured in the **Lark Base UI**, not via the agent or
MCP. The agent's only contribution is a walkthrough doc. The setup session's
walkthrough lives at
`/Users/bear/Me/workspace/professional/active/cv/crm/automations.md`.

### ⚠️ Don't transcribe a checklist uncritically

The upstream guide proposes 5 automations. A prior session was about to
transcribe all 5 before catching that:
- One (interview→calendar) requires the parked OAuth/user-token mode.
- Several send Lark messages, which only matters if the user actually lives in
  Lark as a messaging surface.

**Before writing an automations walkthrough, ask:** which of these fire into a
surface the user actually uses, and which depend on a deferred capability?
Default to proposing a subset, not the full list. The user had to intervene to
trigger this check — a future session should do it unprompted.

The general principle, applicable beyond automations: **when a guide or doc
provides a checklist, treat each item as a hypothesis to validate against the
user's actual workflow, not a spec to execute.** This is especially true for
notification/push automations, which have a high noise cost if mis-scoped.

---

## The "ask vs. explore" calibration

Two failure modes to avoid, both observed in the setup session:

1. **Over-exploring a known pattern.** Harness-wiring is mechanical. Once one
   harness is wired, adding another is a 3-step task (find config, add entry
   pointing at wrapper, verify). A session spent 4 tool calls "exploring" Zed's
   MCP format when the existing `morph`/`ken` entries in the same file already
   showed the shape. **When the answer is already visible in an adjacent config
   entry, stop exploring and copy the pattern.**

2. **Pursuing a reverse-decision without flagging it.** When the user says "do
   the deferred tasks," a deferred item may still be deferred for good reason.
   **Before acting on anything marked "deferred" or "limitations," re-state the
   cost that made it deferred and confirm it's now acceptable.** Don't assume
   "deferred" became "approved" by virtue of being mentioned.

The meta-point: a skill/runbook's "Limitations & deferred" section is a
decision record, not a backlog. Treat it as constraints to respect, not a TODO
list to burn down.
