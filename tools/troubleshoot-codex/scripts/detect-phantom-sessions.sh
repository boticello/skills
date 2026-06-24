#!/usr/bin/env bash
# detect-phantom-sessions.sh
# Compare session transcript files on disk against session_index.jsonl
# AND state_5.sqlite (the source the Codex sidebar actually reads from).
#
# Reports three categories of anomalies:
#   1. JSONL phantoms  — on disk but NOT in session_index.jsonl
#   2. SQLite phantoms — on disk but NOT in state_5.sqlite
#   3. SQLite ghosts   — in session_index.jsonl but NOT in state_5.sqlite
#                        (indexed but invisible to the app sidebar)
set -euo pipefail

CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
SESSIONS_DIR="$CODEX_HOME/sessions"
INDEX_FILE="$CODEX_HOME/session_index.jsonl"
SQLITE_DB="$CODEX_HOME/state_5.sqlite"

# ── Helpers ──────────────────────────────────────────────────────────────

cleanup_files=()

cleanup() {
    if [ ${#cleanup_files[@]} -gt 0 ]; then
        rm -f "${cleanup_files[@]}"
    fi
}
trap cleanup EXIT

make_temp() {
    local f
    f=$(mktemp)
    cleanup_files+=("$f")
    echo "$f"
}

# Extract UUID session IDs from transcript filenames on disk
extract_disk_ids() {
    find "$SESSIONS_DIR" -name '*.jsonl' -exec basename {} \; | \
        grep -oE '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' | \
        sort -u
}

# Print a detail table for a list of session IDs
print_detail_table() {
    local ids="$1"
    if [ -z "$ids" ]; then
        echo "  (none)"
        return
    fi

    printf "  %-40s  %-6s  %-8s  %s\n" "SESSION_ID" "LINES" "SIZE_KB" "LAST_TIMESTAMP"
    echo "  -----------------------------------------------------------------------------------"

    for sid in $ids; do
        local files
        files=$(find "$SESSIONS_DIR" -name "*${sid}*.jsonl")
        for f in $files; do
            local lines size_kb last_ts cwd
            lines=$(wc -l < "$f" | tr -d ' ')
            size_kb=$(( $(stat -f%z "$f" 2>/dev/null || stat -c%s "$f" 2>/dev/null) / 1024 ))
            last_ts=$(tail -1 "$f" | python3 -c "
import json, sys
try:
    obj = json.loads(sys.stdin.readline())
    print(obj.get('timestamp', '?'))
except: print('?')
" 2>/dev/null)
            cwd=$(head -5 "$f" | python3 -c "
import json, sys
for line in sys.stdin:
    try:
        obj = json.loads(line)
        if obj.get('type') == 'session_meta':
            print(obj['payload'].get('cwd', '?'))
            break
    except: pass
" 2>/dev/null)
            printf "  %-40s  %-6s  %-8s  %s\n" "$sid" "$lines" "$size_kb" "$last_ts"
            echo "    CWD: $cwd"
        done
    done
}

# ── Pre-flight checks ───────────────────────────────────────────────────

if [ ! -d "$SESSIONS_DIR" ]; then
    echo "ERROR: sessions directory not found at $SESSIONS_DIR"
    exit 1
fi

disk_ids_file=$(make_temp)
extract_disk_ids > "$disk_ids_file"
disk_count=$(wc -l < "$disk_ids_file" | tr -d ' ')

if [ "$disk_count" -eq 0 ]; then
    echo "No session files found on disk. Nothing to check."
    exit 0
fi

issues_found=0

# ════════════════════════════════════════════════════════════════════════
# SECTION 1: JSONL-based phantom detection (disk vs session_index.jsonl)
# ════════════════════════════════════════════════════════════════════════

echo "================================================================"
echo " Section 1: JSONL Phantoms (disk vs session_index.jsonl)"
echo "================================================================"
echo ""

if [ ! -f "$INDEX_FILE" ]; then
    echo "WARN: session_index.jsonl not found at $INDEX_FILE"
    echo "      Skipping JSONL phantom check."
    jsonl_available=false
else
    jsonl_available=true
    indexed_ids_file=$(make_temp)
    grep -o '"id":"[^"]*"' "$INDEX_FILE" | sed 's/"id":"//;s/"//' | sort -u > "$indexed_ids_file"
    indexed_count=$(wc -l < "$indexed_ids_file" | tr -d ' ')

    echo "Indexed in session_index.jsonl: $indexed_count"
    echo "Sessions on disk:               $disk_count"

    jsonl_phantoms=$(comm -23 "$disk_ids_file" "$indexed_ids_file" || true)
    jsonl_phantom_count=$(echo "$jsonl_phantoms" | grep -c . || true)

    echo "JSONL phantom sessions:          $jsonl_phantom_count"
    echo ""

    if [ "$jsonl_phantom_count" -eq 0 ]; then
        echo "  ✓ No JSONL phantoms found."
    else
        issues_found=1
        echo "  Sessions on disk but NOT in session_index.jsonl:"
        echo ""
        print_detail_table "$jsonl_phantoms"
        echo ""
        echo "  To repair: quit Codex, then append each missing entry to session_index.jsonl:"
        echo "    echo '{\"id\":\"SESSION_ID\",\"thread_name\":\"DESCRIPTIVE NAME\",\"updated_at\":\"TIMESTAMP\"}' >> $INDEX_FILE"
    fi
fi

echo ""

# ════════════════════════════════════════════════════════════════════════
# SECTION 2: SQLite-based phantom detection (disk vs state_5.sqlite)
# ════════════════════════════════════════════════════════════════════════

echo "================================================================"
echo " Section 2: SQLite Phantoms (disk vs state_5.sqlite)"
echo "================================================================"
echo ""

sqlite_available=false

if ! command -v sqlite3 &>/dev/null; then
    echo "WARN: sqlite3 command not found. Skipping SQLite checks."
    echo "      Install sqlite3 to enable this check."
else
    if [ ! -f "$SQLITE_DB" ]; then
        echo "WARN: state_5.sqlite not found at $SQLITE_DB"
        echo "      Skipping SQLite phantom check."
    else
        sqlite_ids_file=$(make_temp)
        if ! sqlite3 "$SQLITE_DB" "SELECT id FROM threads WHERE archived = 0;" > "$sqlite_ids_file" 2>/dev/null; then
            sqlite_exit=$?
            echo "WARN: sqlite3 query failed (exit code $sqlite_exit)."
            if [ "$sqlite_exit" -eq 5 ]; then
                echo "      The database is locked — is Codex currently running?"
                echo "      Try quitting Codex and re-running this script."
            fi
            echo "      Skipping SQLite phantom check."
        else
            sqlite_available=true
            # SQLite IDs may not be bare UUIDs; normalise
            sort -u "$sqlite_ids_file" > "$sqlite_ids_file.tmp" && mv "$sqlite_ids_file.tmp" "$sqlite_ids_file"
            sqlite_count=$(wc -l < "$sqlite_ids_file" | tr -d ' ')

            echo "Indexed in state_5.sqlite:  $sqlite_count"
            echo "Sessions on disk:           $disk_count"

            sqlite_phantoms=$(comm -23 "$disk_ids_file" "$sqlite_ids_file" || true)
            sqlite_phantom_count=$(echo "$sqlite_phantoms" | grep -c . || true)

            echo "SQLite phantom sessions:    $sqlite_phantom_count"
            echo ""

            if [ "$sqlite_phantom_count" -eq 0 ]; then
                echo "  ✓ No SQLite phantoms found."
            else
                issues_found=1
                echo "  Sessions on disk but NOT in state_5.sqlite:"
                echo ""
                print_detail_table "$sqlite_phantoms"
                echo ""
                echo "  To repair: these sessions exist on disk but the Codex sidebar"
                echo "  won't show them. They may need to be re-imported through the app."
            fi
        fi
    fi
fi

echo ""

# ════════════════════════════════════════════════════════════════════════
# SECTION 3: SQLite ghosts (in session_index.jsonl but NOT in sqlite)
# ════════════════════════════════════════════════════════════════════════

echo "================================================================"
echo " Section 3: SQLite Ghosts (in JSONL index but not in SQLite)"
echo "================================================================"
echo ""

if [ "$jsonl_available" = true ] && [ "$sqlite_available" = true ]; then
    sqlite_ghosts=$(comm -23 "$indexed_ids_file" "$sqlite_ids_file" || true)
    sqlite_ghost_count=$(echo "$sqlite_ghosts" | grep -c . || true)

    echo "In session_index.jsonl only: $sqlite_ghost_count"
    echo ""

    if [ "$sqlite_ghost_count" -eq 0 ]; then
        echo "  ✓ No SQLite ghosts found."
    else
        issues_found=1
        echo "  Sessions in session_index.jsonl but NOT in state_5.sqlite"
        echo "  (these appear indexed but are invisible to the Codex sidebar):"
        echo ""

        for sid in $sqlite_ghosts; do
            echo "  - $sid"
        done

        echo ""
        echo "  These sessions may show up in some internal lists but will NOT"
        echo "  appear in the app sidebar. The likely cause is a migration or"
        echo "  sync failure between the JSONL index and the SQLite database."
    fi
else
    echo "  Skipped (requires both session_index.jsonl and state_5.sqlite to be available)."
fi

echo ""

# ════════════════════════════════════════════════════════════════════════
# Summary
# ════════════════════════════════════════════════════════════════════════

echo "================================================================"
echo " Summary"
echo "================================================================"
echo "  Sessions on disk: $disk_count"
if [ "$jsonl_available" = true ]; then
    echo "  JSONL phantoms:   $jsonl_phantom_count"
fi
if [ "$sqlite_available" = true ]; then
    echo "  SQLite phantoms:  $sqlite_phantom_count"
fi
if [ "$jsonl_available" = true ] && [ "$sqlite_available" = true ]; then
    echo "  SQLite ghosts:    $sqlite_ghost_count"
fi
echo "================================================================"

exit $issues_found
