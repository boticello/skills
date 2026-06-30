#!/opt/homebrew/bin/bash
# execute-moves.sh — declarative filesystem reorganisation
#
# Reads a tab-separated move plan (moves.tsv) and executes it safely:
#   1. Create destination directories.
#   2. Copy files (abort on missing source or existing destination).
#   3. Verify SHA-256 checksums.
#   4. Trash originals to a timestamped directory (never rm).
#   5. Clean up empty source directories bottom-up.
#
# Usage:
#   bash execute-moves.sh [--dry-run] [--trash-dir <path>]
#
# Move plan format (moves.tsv):
#   source<TAB>destination
#   path/from/a.md<TAB>path/to/a.md
#
# The first row is treated as a header and skipped.
# All paths are relative to the working directory.

set -euo pipefail

# --- defaults and argument parsing ---

ROOT="$(cd "$(dirname "$0")" && pwd)"
MOVES="$ROOT/moves.tsv"
TRASH_DEFAULT="$HOME/Me/trash"
DRY_RUN=false
TRASH_DIR_OVERRIDE=""
TRASH_SUBDIR_OVERRIDE=""  # when set, skip the doc-reorg-<timestamp> subdir and use this name instead

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)              DRY_RUN=true; shift ;;
    --trash-dir)            TRASH_DIR_OVERRIDE="$2"; shift 2 ;;
    --trash-subdir)         TRASH_SUBDIR_OVERRIDE="$2"; shift 2 ;;
    -h|--help)
      echo "Usage: bash execute-moves.sh [--dry-run] [--trash-dir <path>] [--trash-subdir <name>]"
      echo ""
      echo "Reads moves.tsv from the script's directory."
      echo "Default trash root: $TRASH_DEFAULT"
      echo "Default trash subdir: doc-reorg-<timestamp> (e.g. doc-reorg-20260528-083427)"
      echo "  Use --trash-subdir to override (e.g. --trash-subdir 2026-06-29 to merge into a date folder)"
      exit 0
      ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

TRASH_ROOT="${TRASH_DIR_OVERRIDE:-$TRASH_DEFAULT}"

if [[ ! -f "$MOVES" ]]; then
  echo "ERROR: $MOVES not found"
  exit 1
fi

# --- load move plan ---

declare -a SOURCES=()
declare -a DESTS=()
while IFS=$'\t' read -r src dst; do
  [[ "$src" == "source" ]] && continue
  [[ -z "$src" || -z "$dst" ]] && continue
  SOURCES+=("$src")
  DESTS+=("$dst")
done < "$MOVES"

TOTAL=${#SOURCES[@]}
if [[ $TOTAL -eq 0 ]]; then
  echo "No moves found in $MOVES"
  exit 0
fi

echo "=== $TOTAL moves to process ==="

# --- phase 1: create destination directories ---

echo ""
echo "--- Phase 1: creating destination directories ---"
declare -A SEEN_DIRS=()
for dst in "${DESTS[@]}"; do
  dir="$(dirname "$dst")"
  if [[ -n "${SEEN_DIRS[$dir]:-}" ]]; then continue; fi
  SEEN_DIRS["$dir"]=1
  full="$ROOT/$dir"
  if [[ -d "$full" ]]; then
    echo "  exists: $dir/"
  else
    if $DRY_RUN; then
      echo "  [dry-run] mkdir -p $dir/"
    else
      mkdir -p "$full"
      echo "  created: $dir/"
    fi
  fi
done

# --- phase 2: copy files ---

echo ""
echo "--- Phase 2: copying files ---"
FAILED=0
for i in "${!SOURCES[@]}"; do
  src="${SOURCES[$i]}"
  dst="${DESTS[$i]}"
  full_src="$ROOT/$src"
  full_dst="$ROOT/$dst"

  if [[ ! -f "$full_src" ]]; then
    echo "  MISSING: $src"
    FAILED=$((FAILED + 1))
    continue
  fi

  if [[ -f "$full_dst" ]]; then
    # Same path → trash-only operation. Skip the copy (the file is
    # already at the destination by definition). The Phase 4 mv will
    # move the source to the trash dir.
    if [[ "$(realpath "$full_src" 2>/dev/null)" == "$(realpath "$full_dst" 2>/dev/null)" ]]; then
      if $DRY_RUN; then
        echo "  [dry-run] (no-op, source==dest) $src"
      else
        echo "  (no-op, source==dest) $src"
      fi
    else
      echo "  CONFLICT: $dst already exists"
      FAILED=$((FAILED + 1))
    fi
    continue
  fi

  if $DRY_RUN; then
    echo "  [dry-run] cp $src -> $dst"
  else
    cp "$full_src" "$full_dst"
    echo "  copied: $src -> $dst"
  fi
done

if [[ $FAILED -gt 0 ]]; then
  echo ""
  echo "ERROR: $FAILED source problems. Aborting before verify phase."
  exit 1
fi

# --- phase 3: verify checksums ---

echo ""
echo "--- Phase 3: verifying checksums ---"
VERIFY_FAILED=0
for i in "${!SOURCES[@]}"; do
  src="${SOURCES[$i]}"
  dst="${DESTS[$i]}"
  full_src="$ROOT/$src"
  full_dst="$ROOT/$dst"

  if $DRY_RUN; then
    echo "  [dry-run] verify $dst"
    continue
  fi

  src_hash=$(shasum -a 256 "$full_src" | awk '{print $1}')
  dst_hash=$(shasum -a 256 "$full_dst" | awk '{print $1}')

  if [[ "$src_hash" != "$dst_hash" ]]; then
    echo "  MISMATCH: $src != $dst"
    echo "    source: $src_hash"
    echo "    dest:   $dst_hash"
    VERIFY_FAILED=$((VERIFY_FAILED + 1))
  else
    echo "  ok: $dst"
  fi
done

if [[ $VERIFY_FAILED -gt 0 ]]; then
  echo ""
  echo "ERROR: $VERIFY_FAILED verification failures. NOT trashing originals."
  exit 1
fi

# --- phase 4: trash originals ---

echo ""
echo "--- Phase 4: trashing originals ---"
if [[ -n "$TRASH_SUBDIR_OVERRIDE" ]]; then
  TRASH_DIR="$TRASH_ROOT/$TRASH_SUBDIR_OVERRIDE"
else
  TRASH_TS="$(date +%Y%m%d-%H%M%S)"
  TRASH_DIR="$TRASH_ROOT/doc-reorg-$TRASH_TS"
fi

if $DRY_RUN; then
  echo "  [dry-run] trash dir: $TRASH_DIR"
else
  mkdir -p "$TRASH_DIR"
  echo "  trash dir: $TRASH_DIR"
fi

# collect source parent directories for cleanup later
declare -A CLEANUP_DIRS=()

for i in "${!SOURCES[@]}"; do
  src="${SOURCES[$i]}"
  full_src="$ROOT/$src"

  # record parent dirs for cleanup
  parent="$(dirname "$src")"
  while [[ "$parent" != "." && "$parent" != "/" ]]; do
    CLEANUP_DIRS["$parent"]=1
    parent="$(dirname "$parent")"
  done

  if $DRY_RUN; then
    echo "  [dry-run] trash $src"
    continue
  fi

  # Build trash path. If $src starts with "../.." (the staging-dir layout
  # convention), strip those components and rebase under $TRASH_DIR. This
  # avoids the bug where $ROOT/$src and $TRASH_DIR/$src resolve to the
  # same absolute path (when $TRASH_DIR is at the same depth as $ROOT).
  # See the 2026-06-29 Klick & Sketch incident for context.
  trash_subpath="$src"
  while [[ "$trash_subpath" == ../* ]]; do
    trash_subpath="${trash_subpath#../}"
  done
  trash_dest="$TRASH_DIR/$trash_subpath"
  trash_dest_dir="$(dirname "$trash_dest")"
  mkdir -p "$trash_dest_dir"
  mv "$full_src" "$trash_dest"
  echo "  trashed: $src"
done

# --- phase 5: clean up empty source directories ---

echo ""
echo "--- Phase 5: cleaning empty directories ---"

# sort deepest first so we remove children before parents
SORTED_DIRS=($(printf '%s\n' "${!CLEANUP_DIRS[@]}" | awk -F/ '{print NF, $0}' | sort -rn | cut -d' ' -f2-))

for dir in "${SORTED_DIRS[@]}"; do
  full="$ROOT/$dir"
  if [[ -d "$full" ]] && [[ -z "$(ls -A "$full" 2>/dev/null)" ]]; then
    if $DRY_RUN; then
      echo "  [dry-run] rmdir $dir/ (empty)"
    else
      rmdir "$full"
      echo "  rmdir: $dir/ (empty)"
    fi
  fi
done

# --- summary ---

echo ""
if $DRY_RUN; then
  echo "=== Dry run complete. $TOTAL moves planned. No changes made. ==="
else
  echo "=== Done. $TOTAL moves completed. ==="
  echo "    originals at: $TRASH_DIR"
  if [[ -n "$TRASH_SUBDIR_OVERRIDE" ]]; then
    echo "    (merged into date-folder convention; no separate doc-reorg-<timestamp> subdir)"
  fi
fi
