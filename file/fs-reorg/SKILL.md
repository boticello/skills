---
name: fs-reorg
description: Execute a filesystem reorganisation from a declarative move plan. Copy files to new locations, verify integrity, trash originals, and clean up empty directories. Use when reorganising, restructuring, or relocating files across a project.
---

# Filesystem Reorganisation

Move files declaratively and safely: copy, verify, trash originals, clean up.

## When to Use

Use this skill when the user wants to reorganise files — restructuring a directory layout, moving documents between workspace and repo, splitting a flat directory into subdirectories, or any bulk file relocation where safety matters.

Do not use for single-file renames or moves. Use `mv` directly for those.

## Process

### 1. Create the move plan

Create a file called `moves.tsv` in the root of the reorganisation (the directory the script will run from). Format:

```
source	destination
path/to/original.md	new/location/original.md
another/file.py	src/module/file.py
```

Rules:

- Tab-separated, with a header row (`source\tdestination`).
- All paths are relative to the root directory the script runs from.
- Paths use forward slashes.
- Do not include overlapping moves where a file is both a source and a destination in the same plan. If you need that, split into two sequential runs.

Present the plan to the user for review before proceeding.

### 2. Run the script in dry-run mode

The script is located at the skill directory as `execute-moves.sh`. Run it with `--dry-run` to preview what will happen:

```bash
bash <skill-dir>/execute-moves.sh --dry-run
```

The dry run reports:
- Directories that will be created
- Files that will be copied
- Files that will be trashed
- Empty directories that will be removed

Review the output. Fix any issues in the plan before proceeding.

### 3. Run the script for real

```bash
bash <skill-dir>/execute-moves.sh
```

The script proceeds through five phases:

1. **Create directories** — `mkdir -p` for all destination parent directories.
2. **Copy files** — `cp` each source to its destination. Aborts if any source is missing.
3. **Verify** — compare SHA-256 checksums of every source/destination pair. Aborts and does not trash if any mismatch.
4. **Trash originals** — move source files to a timestamped directory under the trash root, preserving their relative path structure. Does not use `rm`.
5. **Clean up** — walk up from each trashed file's parent directory and remove empty directories bottom-up. Only removes directories that became empty as a result of the moves.

The script never deletes files. It moves originals to the trash root (default `~/Me/trash/`), organised into a timestamped subdirectory like `~/Me/trash/doc-reorg-20260528-083427/`. The exact trash path is printed during execution.

### 4. Verify the result

After the script completes, inspect the new layout to confirm it matches expectations:

```bash
find . -type f -name '*.md' | sort
```

Or whatever pattern is appropriate for the files moved.

### 5. Clean up

The `moves.tsv` file and any surrounding scaffolding can be removed or kept as a record of the reorganisation. The originals remain in the trash until the user decides to remove them.

## Options

| Flag | Purpose |
|---|---|
| `--dry-run` | Preview all phases without making changes |
| `--trash-dir <path>` | Override the trash root (default: `~/Me/trash`) |
| `--trash-subdir <name>` | Override the timestamped subdir; useful for merging into a date-folder convention (e.g. `--trash-subdir 2026-06-29`) |

## Troubleshooting

**"MISSING" errors in Phase 2**: A source path in the plan does not exist. Check for typos or paths that assume a different working directory. The script aborts before trashing anything.

**"MISMATCH" errors in Phase 3**: A copied file does not match its source by SHA-256. This should not happen in normal operation. The script aborts and does not trash originals. Investigate disk issues or filesystem problems.

**"CONFLICT" errors in Phase 2**: A destination file already exists. The script will not overwrite. Either remove the existing destination, or update the plan to avoid the conflict.

**Empty directories not cleaned up**: The cleanup phase only removes directories that are empty after moves. If a directory still contains files not listed in the plan, it is preserved.

**Phase 4 "succeeded" but nothing landed in the trash**: This is a path-resolution bug. The script computes `mv "$ROOT/$src" "$TRASH_DIR/$src"`. If both `$ROOT` and `$TRASH_DIR` are at the same depth (e.g. both directly under `~/Me/`), and `$src` starts with `../../`, both `full_src` and `trash_dest` resolve to the **same absolute path**. BSD `mv` treats `mv X X` as a successful no-op (exit 0), so `set -euo pipefail` doesn't trip. Fix: the current script (as of 2026-06-29) strips the leading `../` from `$src` when building the trash path, so `../../inbox/foo.pdf` becomes `inbox/foo.pdf` under the trash dir. If you're seeing this, upgrade to the latest version of the script. **Verify by computing `realpath` of both `full_src` and `trash_dest` before any real run.**

**Trash looks empty after a "successful" run**: Same as above. Check `trash/<subdir>/inbox/...` — the files may have moved there. But on macOS with the default `~/Me/trash/<subdir>/` layout, this means they didn't move at all. See the previous item.

## Known Limitations

- **Overlapping source/destination**: If file A is moved to path B, and file B is moved to path C, the copy of B happens after the copy of A — so B at that point is the original, not the newly-copied A. This works correctly because the script copies from source to destination before trashing anything. But do not rely on a destination from one row as a source in another row within the same run.
- **No undo**: There is no automatic undo. The originals are in the trash with their relative paths preserved. To undo manually, copy them back from the trash directory.
- **No directory moves**: The plan lists individual files. To move a directory, list every file within it.
