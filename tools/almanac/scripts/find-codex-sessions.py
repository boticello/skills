#!/usr/bin/env python3
"""Find Codex transcript sessions matching a workspace keyword.

Scans ~/.codex/sessions/ for JSONL files whose cwd contains the given keyword.
By default shows only supervisor (user) threads. Use --all to include subagents.

Usage:
    python3 find-codex-sessions.py terminusdb
    python3 find-codex-sessions.py terminusdb --all
    python3 find-codex-sessions.py terminusdb --sort date   # default
    python3 find-codex-sessions.py terminusdb --sort size
"""

import argparse
import json
import os
import sys
from pathlib import Path


def scan_sessions(keyword: str, include_subagents: bool = False) -> list[dict]:
    sessions_dir = Path.home() / ".codex" / "sessions"
    if not sessions_dir.is_dir():
        print(f"Error: {sessions_dir} not found", file=sys.stderr)
        sys.exit(1)

    results = []
    for jsonl_path in sessions_dir.rglob("*.jsonl"):
        try:
            with open(jsonl_path) as fh:
                for i, line in enumerate(fh):
                    if i > 20:
                        break
                    try:
                        d = json.loads(line.strip())
                        p = d.get("payload", {})
                        cwd = p.get("cwd", "")
                        ts = p.get("thread_source", "none")
                        # Only process session_meta entries with cwd
                        if not cwd:
                            continue
                    except (json.JSONDecodeError, AttributeError):
                        continue

                    if keyword.lower() not in cwd.lower():
                        break

                    # Filter by thread type
                    if ts == "subagent" and not include_subagents:
                        break
                    if ts not in ("user", "subagent"):
                        break

                    size_kb = jsonl_path.stat().st_size / 1024
                    basename = jsonl_path.name
                    date = basename[8:18] if len(basename) > 18 else "unknown"

                    results.append(
                        {
                            "date": date,
                            "source": ts,
                            "size_kb": size_kb,
                            "path": str(jsonl_path),
                        }
                    )
                    break
        except OSError:
            continue

    return results


def main():
    parser = argparse.ArgumentParser(
        description="Find Codex transcript sessions matching a workspace keyword."
    )
    parser.add_argument(
        "keyword",
        help="Substring to match against session cwd (case-insensitive)",
    )
    parser.add_argument(
        "--all",
        action="store_true",
        help="Include subagent threads (default: supervisor only)",
    )
    parser.add_argument(
        "--sort",
        choices=["date", "size"],
        default="size",
        help="Sort order (default: size, largest first)",
    )
    args = parser.parse_args()

    results = scan_sessions(args.keyword, include_subagents=args.all)

    if args.sort == "size":
        results.sort(key=lambda r: r["size_kb"], reverse=True)
    else:
        results.sort(key=lambda r: r["date"])

    if not results:
        print(f"No sessions found matching '{args.keyword}'")
        return

    print(f"{'SIZE':>8}\t{'TYPE':<10}\t{'DATE':<12}\tPATH")
    for r in results:
        print(f"{r['size_kb']:>7.0f}K\t{r['source']:<10}\t{r['date']:<12}\t{r['path']}")

    print(f"\n{len(results)} session(s) total")


if __name__ == "__main__":
    main()
