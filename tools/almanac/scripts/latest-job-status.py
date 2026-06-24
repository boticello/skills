#!/usr/bin/env python3
"""Show status of the latest Almanac background job.

Looks for .almanac/runs/*.json, picks the most recently modified one,
and prints its status, duration, cost, and created pages.

Usage:
    python3 latest-job-status.py                    # uses CWD
    python3 latest-job-status.py /path/to/repo      # explicit path
"""

import json
import sys
from pathlib import Path


def main():
    repo_root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path.cwd()
    runs_dir = repo_root / ".almanac" / "runs"

    if not runs_dir.is_dir():
        print(f"No .almanac/runs/ found at {repo_root}")
        sys.exit(1)

    run_files = sorted(runs_dir.glob("*.json"), key=lambda p: p.stat().st_mtime, reverse=True)

    if not run_files:
        print("No run files found")
        sys.exit(1)

    latest = run_files[0]
    d = json.loads(latest.read_text())

    print(f"Run: {d['id']}  Status: {d['status']}  Op: {d['operation']}")

    if "durationMs" in d:
        print(f"Duration: {d['durationMs'] / 1000:.0f}s")

    if "summary" in d:
        s = d["summary"]
        print(f"Created: {s.get('created', 0)}  Updated: {s.get('updated', 0)}  Cost: ${s.get('costUsd', 0):.2f}")

    if "pageChanges" in d:
        for p in d.get("pageChanges", {}).get("created", []):
            print(f"  + {p}")


if __name__ == "__main__":
    main()
