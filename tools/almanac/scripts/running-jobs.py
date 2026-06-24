#!/usr/bin/env python3
"""Show all running or queued Almanac background jobs.

Usage:
    python3 running-jobs.py                    # uses CWD
    python3 running-jobs.py /path/to/repo      # explicit path
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

    found = False
    for run_file in runs_dir.glob("*.json"):
        try:
            d = json.loads(run_file.read_text())
        except (json.JSONDecodeError, OSError):
            continue
        if "id" not in d:
            continue
        if d.get("status") in ("running", "queued"):
            print(f"{d['id']}: {d['status']} ({d['operation']})")
            found = True

    if not found:
        print("No running or queued jobs.")


if __name__ == "__main__":
    main()
