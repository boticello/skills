#!/usr/bin/env python3
"""Inspect and repair the Codex Desktop state_5.sqlite database.

Subcommands: lookup, workspace, orphans, health, repair, edges.
"""

import argparse
import glob
import os
import re
import sqlite3
import subprocess
import sys
from datetime import datetime, timezone

DB_PATH = os.path.expanduser("~/.codex/state_5.sqlite")
SESSIONS_DIR = os.path.expanduser("~/.codex/sessions")

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _db(readonly=True):
    """Open the SQLite database. Use WAL immutable mode for reads."""
    uri = f"file:{DB_PATH}?immutable=1" if readonly else DB_PATH
    con = sqlite3.connect(uri, uri=readonly)
    con.row_factory = sqlite3.Row
    return con


def _ts(epoch):
    """Convert unix epoch (seconds or ms) to ISO-8601 local string."""
    if epoch is None:
        return "—"
    # heuristic: values > 1e12 are milliseconds
    if epoch > 1e12:
        epoch = epoch / 1000
    return datetime.fromtimestamp(epoch, tz=timezone.utc).strftime(
        "%Y-%m-%d %H:%M:%S UTC"
    )


def _short(id_str):
    return id_str[:8] if id_str else "—"


def _trunc(s, n=50):
    return (s[: n - 1] + "…") if s and len(s) > n else (s or "")


def _codex_running():
    try:
        r = subprocess.run(["pgrep", "-x", "Codex"], capture_output=True, text=True)
        return r.returncode == 0
    except FileNotFoundError:
        r = subprocess.run(["ps", "-eo", "comm="], capture_output=True, text=True)
        return "Codex" in r.stdout.splitlines()


# ---------------------------------------------------------------------------
# Subcommands
# ---------------------------------------------------------------------------


def cmd_lookup(args):
    con = _db(readonly=True)
    row = con.execute(
        "SELECT * FROM threads WHERE id = ?", (args.session_id,)
    ).fetchone()
    con.close()
    if not row:
        print(f"No thread found with id {args.session_id!r}", file=sys.stderr)
        sys.exit(1)
    for key in row.keys():
        val = row[key]
        if key in (
            "created_at",
            "updated_at",
            "archived_at",
            "created_at_ms",
            "updated_at_ms",
        ):
            val = f"{val}  ({_ts(val)})"
        print(f"  {key:22s} {val}")


def cmd_workspace(args):
    cwd = os.path.abspath(args.path or os.getcwd())
    con = _db(readonly=True)
    rows = con.execute(
        "SELECT id, title, thread_source, archived, updated_at FROM threads"
        " WHERE cwd = ? ORDER BY updated_at DESC",
        (cwd,),
    ).fetchall()
    con.close()
    if not rows:
        print(f"No threads for workspace: {cwd}", file=sys.stderr)
        return
    for r in rows:
        print(
            f"{_short(r['id'])}  {_trunc(r['title']):50s}  {r['thread_source'] or '—':12s}  "
            f"{'A' if r['archived'] else ' '}  {_ts(r['updated_at'])}"
        )


def cmd_orphans(args):
    """Find transcript files whose session ID is absent from the threads table."""
    pattern = re.compile(r"rollout-\d{4}-\d{2}-\d{2}T\d{2}-\d{2}-\d{2}-(.+)\.jsonl$")
    disk_ids = set()
    for path in glob.glob(os.path.join(SESSIONS_DIR, "**", "*.jsonl"), recursive=True):
        m = pattern.match(os.path.basename(path))
        if m:
            disk_ids.add(m.group(1))
    if not disk_ids:
        print("No session files found on disk.", file=sys.stderr)
        return
    con = _db(readonly=True)
    db_ids = {r[0] for r in con.execute("SELECT id FROM threads")}
    con.close()
    orphans = sorted(disk_ids - db_ids)
    if not orphans:
        print("No orphans found.")
        return
    for sid in orphans:
        print(sid)


def cmd_health(args):
    con = _db(readonly=True)
    total = con.execute("SELECT count(*) FROM threads").fetchone()[0]
    blank_title = con.execute(
        "SELECT count(*) FROM threads WHERE title = '' OR title IS NULL"
    ).fetchone()[0]
    no_source = con.execute(
        "SELECT count(*) FROM threads WHERE thread_source IS NULL OR thread_source = ''"
    ).fetchone()[0]
    archived = con.execute(
        "SELECT count(*) FROM threads WHERE archived = 1"
    ).fetchone()[0]
    dups = con.execute(
        "SELECT id, count(*) c FROM threads GROUP BY id HAVING c > 1"
    ).fetchall()
    con.close()
    print(f"Total threads:              {total}")
    print(f"Blank titles:               {blank_title}")
    print(f"Missing thread_source:      {no_source}")
    print(f"Archived:                   {archived}")
    print(f"Duplicate IDs:              {len(dups)}")
    if dups:
        for d in dups:
            print(f"  ⚠  {d['id']} appears {d['c']} times")


def _require_codex_stopped():
    if _codex_running():
        print(
            "Error: Codex Desktop appears to be running. Quit it first.",
            file=sys.stderr,
        )
        sys.exit(2)


def cmd_repair(args):
    _require_codex_stopped()
    con = _db(readonly=False)
    try:
        if args.title:
            con.execute(
                "UPDATE threads SET title = ? WHERE id = ?",
                (args.title, args.session_id),
            )
            if con.total_changes == 0:
                print(f"No thread found with id {args.session_id!r}", file=sys.stderr)
                sys.exit(1)
            print(f"Title updated for {_short(args.session_id)}.")
        if args.unarchive:
            con.execute(
                "UPDATE threads SET archived = 0, archived_at = NULL WHERE id = ?",
                (args.session_id,),
            )
            if con.total_changes == 0:
                print(f"No thread found with id {args.session_id!r}", file=sys.stderr)
                sys.exit(1)
            print(f"Unarchived {_short(args.session_id)}.")
        con.commit()
    except sqlite3.OperationalError as e:
        if "database is locked" in str(e).lower():
            print("Database is locked. Is Codex still running?", file=sys.stderr)
            sys.exit(5)
        raise
    finally:
        con.close()


def cmd_edges(args):
    con = _db(readonly=True)
    sid = args.session_id
    children = con.execute(
        "SELECT child_thread_id, status FROM thread_spawn_edges WHERE parent_thread_id = ?",
        (sid,),
    ).fetchall()
    parents = con.execute(
        "SELECT parent_thread_id, status FROM thread_spawn_edges WHERE child_thread_id = ?",
        (sid,),
    ).fetchall()
    con.close()
    if parents:
        print("Parents:")
        for p in parents:
            print(f"  {_short(p[0])}  status={p[1] or '—'}")
    if children:
        print("Children:")
        for c in children:
            print(f"  {_short(c[0])}  status={c[1] or '—'}")
    if not parents and not children:
        print(f"No spawn edges for {_short(sid)}.")


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------


def main():
    parser = argparse.ArgumentParser(description="Inspect Codex state_5.sqlite")
    sub = parser.add_subparsers(dest="command")

    p = sub.add_parser("lookup", help="Show full details of a thread")
    p.add_argument("session_id")

    p = sub.add_parser("workspace", help="List threads for a workspace path")
    p.add_argument("path", nargs="?", default=None)

    sub.add_parser("orphans", help="Find phantom sessions on disk")

    sub.add_parser("health", help="Database health summary")

    p = sub.add_parser("repair", help="Repair a thread")
    p.add_argument("session_id")
    p.add_argument("--title", help="New title")
    p.add_argument("--unarchive", action="store_true", help="Unarchive the session")

    p = sub.add_parser("edges", help="Show spawn edges for a session")
    p.add_argument("session_id")

    args = parser.parse_args()
    if not args.command:
        parser.print_help()
        sys.exit(0)

    dispatch = {
        "lookup": cmd_lookup,
        "workspace": cmd_workspace,
        "orphans": cmd_orphans,
        "health": cmd_health,
        "repair": cmd_repair,
        "edges": cmd_edges,
    }
    dispatch[args.command](args)


if __name__ == "__main__":
    main()
