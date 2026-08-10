---
name: op-env-wrap-tool
description: Wire a freshly-installed tool that consumes a 1Password-backed API key into the op-env secret-bearing wrapper pattern. Use when a user says "wrap X with op-env", "configure a new tool with a 1Password key", "I just installed X and need its API key wired up", or otherwise needs a new tool's secret key injected via op-env exec. Triggers on the combination of a new tool install + a 1Password-backed credential; not for tools that don't consume secrets, and not for the "I have a key in 1Password but no tool" case.
triggers:
  - op-env
  - wrap with secrets
  - 1Password API key
  - secret-bearing wrapper
  - inject an API key
---

# op-env-wrap-tool

Wire a tool that consumes a 1Password-backed API key into the dotfiles' no-ambient-token secret-injection pattern. End state: the user types `<tool> ...` from any shell and it runs through `op-env exec` with the right `op://` reference resolved and the SA token stripped.

The wrapper pattern is the same shape used for `claude`, `zed`, `litellm-proxy-wrapper`, and `ocr`. This skill is the workflow that produces another one of those wrappers.

## When to use

Trigger when ALL of the following are true:

- A tool has just been (or is about to be) installed that reads an API key from the environment.
- That key lives (or should live) in the `AI-Keys` 1Password vault.
- The user wants the key injected via `op-env`, not ambient in the shell.

Do not use this skill for:

- Tools that don't read API keys (skip — `bin-creator` may still apply for placement).
- Tools that read API keys from a config file rather than the environment (route through a config-file wrapper instead — see `op-env` cheatsheet's `auth.command` pattern for Codex providers).
- Adding a new `op://` reference to the template when no wrapper is needed yet (just edit `ai.env.tpl` and `op-env`'s alias block).

## The sequence

### 1. Confirm the 1Password item exists and resolve

The vault is `AI-Keys`, the service account is `ai`, and the field is `credential` (per `config/op/ai.env.tpl` header). Verify the item resolves:

```bash
op-env read op://AI-Keys/<item-name>/credential | head -c 8
op-env warm
```

If `op-env read` times out or prints nothing, the item is missing or the field is wrong. Fix that first; do not start writing the wrapper.

### 2. Add the op:// reference to the env template

Edit `~/Me/OS/Dotfiles/config/op/ai.env.tpl` and add a line:

```
<ENV_VAR_NAME>=op://AI-Keys/<item-name>/credential
```

Use a single existing convention from the template (`UPPER_SNAKE_CASE`). If the tool reads multiple keys (e.g. `OPENAI_API_KEY` + `OPENAI_ORG_ID`), add one line per reference. For multi-field items, reference each field separately (`credential`, `app_id`, `app_secret`, etc.).

If the item has a different name in the vault than the env var, name the line by the env var the tool actually reads. The alias logic in `op-env` is what bridges vault-item names to env var names — see step 3.

### 3. Decide whether op-env needs an alias

`op-env exec` already auto-aliases two known cases in `Dotfiles/bin/op-env` (search for `print_aliases` and the inline `if [[ -n "${Z_AI_API_KEY:-}" ... ]]` block in `exec_with_loaded_env`):

- `Z_AI_API_KEY` → `ZAI_API_KEY` (e.g. for tools that read `ZAI_API_KEY` directly)
- `GITHUB_TOKEN` → `GH_TOKEN` + `COPILOT_GITHUB_TOKEN`

If the tool reads an env var that is ALREADY in the template under a slightly different name, and the alias is one of the above patterns, no `op-env` change is needed. If the tool reads a different env var name (e.g. `ANTHROPIC_AUTH_TOKEN` is already in the template, but the tool reads `OCR_LLM_TOKEN`), add the alias to `op-env`'s `exec_with_loaded_env` block. The pattern:

```bash
if [[ -n "${Z_AI_API_KEY:-}" && -z "${OCR_LLM_TOKEN:-}" ]]; then
    export OCR_LLM_TOKEN="$Z_AI_API_KEY"
fi
```

When you edit `op-env`, also add the matching alias in `print_aliases` if you want `op-env print` to surface it (otherwise it stays invisible until the next `exec`).

### 4. Decide bin placement

Two populations (full taxonomy in `Dotfiles/bin/README.md`):

| If... | The wrapper goes in... | Why |
|---|---|---|
| Wraps a package-managed binary at a fixed path (e.g. `/opt/homebrew/bin/<tool>`) AND the wrapper needs to be on PATH for the user to type just `<tool>` | `Dotfiles/bin/<tool>` (allowlisted) | `~/.local/bin` is a symlink to `Dotfiles/bin/`, so the file appears on PATH automatically. Adding a symlink here creates a self-referencing link — don't. |
| Wraps a tool whose real binary is itself in `~/Me/OS/scripts/bin/` (standalone) | `~/Me/OS/scripts/bin/<tool>` (no symlink, but the path math may need adjustment) | The file already lives at the PATH junction. |
| Has no PATH conflict and is self-contained | `~/Me/OS/scripts/bin/<tool>` then symlink to `~/.local/bin/<tool>` (load `bin-creator`) | Standalone-authored tool, no repo-coupling. |

The OCR case is the first row — a fixed-path npm binary whose wrapper is just a thin `op-env exec` shim. Use that as the template.

### 5. Author the wrapper

Bash, shebang `#!/usr/bin/env bash`, `set -euo pipefail`. The minimum useful wrapper looks like this (the `ocr` wrapper, lightly abridged):

```bash
#!/usr/bin/env bash

set -euo pipefail

# Wraps the npm-installed `<tool>` through op-env so the <provider> API key
# from 1Password is injected as <ENV_VAR_NAME>.

resolve_script_path() {
    local source_path="${BASH_SOURCE[0]}"
    while [[ -L "$source_path" ]]; do
        local source_dir
        source_dir="$(cd "$(dirname "$source_path")" && pwd)"
        source_path="$(readlink "$source_path")"
        [[ "$source_path" == /* ]] || source_path="$source_dir/$source_path"
    done
    cd "$(dirname "$source_path")" && pwd -P
}

SCRIPT_DIR="$(resolve_script_path)"

# Find the real binary, skipping this wrapper.
real_tool=""
while IFS= read -r candidate; do
    if [[ ! "$candidate" -ef "${BASH_SOURCE[0]}" ]]; then
        real_tool="$candidate"
        break
    fi
done < <(PATH="$(echo "$PATH" | tr ':' '\n' | grep -v "^${SCRIPT_DIR}$" | tr '\n' ':')" command -v <tool> 2>/dev/null || true)

# Fallback to known Homebrew location.
if [[ -z "$real_tool" && -x /opt/homebrew/bin/<tool> ]]; then
    real_tool="/opt/homebrew/bin/<tool>"
fi

if [[ -z "$real_tool" ]]; then
    echo "<tool>: cannot find the real binary (not this wrapper)." >&2
    echo "<tool>: install with: <install command>" >&2
    exit 1
fi

ENV_LOADER="${HOME}/.local/bin/op-env"

if [[ ! -x "$ENV_LOADER" ]]; then
    echo "<tool>: op-env not found at $ENV_LOADER" >&2
    exit 1
fi

exec "$ENV_LOADER" exec "$real_tool" "$@"
```

The `resolve_script_path` + PATH-strip dance is mandatory when the wrapper has the same name as the binary it wraps. Without it, `command -v <tool>` returns the wrapper and the wrapper execs itself. The `claude` wrapper has the same pattern — copy it.

If the tool needs non-secret static config alongside the secret (e.g. `OCR_LLM_URL=https://api.z.ai/api/anthropic`), wrap the `exec` in a `bash -c` preamble that exports those values, the same way `zed` does:

```bash
exec "$ENV_LOADER" exec bash -c '
    export STATIC_VAR="static value"
    exec "$1" "${@:2}"
' bash "$real_tool" "$@"
```

If the tool has a config-file format instead of env vars, skip the wrapper and use a `bash -c` preamble that writes a runtime config file (the `zed` SurrealDB env-file pattern). Only do this if the tool's first call has to read the config from disk.

### 6. Allowlist, document, and verify

Three documentation touchpoints, in this order:

1. **Allowlist the file** so it's tracked: add `!bin/<tool>` to the `--- allowlist: repo-coupled authored scripts ---` block in `Dotfiles/.gitignore`. The allowlist sits between the `bin/*` ignore line and the `config/karabiner/assets/` line.
2. **Add to the repo-coupled population list** in `Dotfiles/bin/README.md` (the `**Repo-coupled (tracked in this repo):**` line).
3. **Add to the intentional secret-bearing wrappers list** in `Dotfiles/config/op/README.md` (the bulleted list under "Intentional secret-bearing wrappers").

Then smoke-test the wrapper:

```bash
# 1. The wrapper finds the real binary, not itself
Dotfiles/bin/<tool> --help

# 2. The template resolves the key (value will be concealed)
op-env print | grep <ENV_VAR_NAME>

# 3. End-to-end: the wrapper actually runs through op-env exec
Dotfiles/bin/<tool> <some-readonly-subcommand>
```

If the user has the `cheat` CLI installed, consider whether this tool earns a sheet. The cheatsheet skill rule applies: only if there's something `tool --help` cannot express (routing, gotchas, sort keys). For most wrapper-only setups the answer is no.

### 7. Commit

`Dotfiles` uses `jj`, not `git`. Load the `jj-vcs` skill. The change is usually a single linear commit:

```bash
cd ~/Me/OS/Dotfiles
jj describe -m "Wrap <tool> through op-env with <provider> API key"
jj new  # leave the working copy clean
```

If the change also edited `bin/op-env` or `ai.env.tpl`, those are part of the same logical change and stay in the same commit.

## Anti-patterns to flag in review

If you see any of these in a new wrapper, push back before committing:

- The wrapper sets the API key inline (e.g. `export FOO_API_KEY="sk-..."`). Keys never appear in version-controlled files.
- The wrapper calls `op` directly instead of going through `op-env`. `op-env` is the only sanctioned secret-injection path; going around it loses the SA-token-stripping step.
- The wrapper does not strip itself from `PATH` before re-resolving, and the wrapper has the same name as the wrapped binary. It will exec itself in an infinite loop.
- The wrapper's allowlist entry is missing. The file is untracked, invisible to `jj status`, and lost on the next `Dotfiles` redeploy.
- A new `op://` reference is added to `ai.env.tpl` but no env-var alias is added to `op-env` for the tool's expected env var name. The tool will see no key and fail with a confusing auth error.

## Related

- `Dotfiles/bin/op-env` — the canonical secret-injection wrapper. The alias block in `exec_with_loaded_env` is where you add new mappings.
- `Dotfiles/config/op/ai.env.tpl` — the source-of-truth template. New `op://` references live here.
- `Dotfiles/config/op/README.md` — the secrets model, design rationale, and intentional-wrappers list.
- `Dotfiles/config/op/how-to-add-new-key.md` — adding a key without a wrapper (template + Codex auth.command).
- `Dotfiles/bin/README.md` — the three populations of `~/.local/bin/` and the placement rules.
- `bin-creator` skill — for standalone authored tools that don't need a wrapper.
- `cheatsheets` skill — if a `cheat` sheet for the wrapped tool also belongs in the cheatsheets repo.
- `op-env` cheatsheet — the consumer view of the same pattern (what the user runs).
- `jj-vcs` skill — the commit step at the end of this sequence.
