#!/usr/bin/env python3
"""Show cost summary for all Almanac background jobs.

Outputs a tab-separated table: cost, status, operation, pages created, run ID.

Usage:
    python3 job-cost-summary.py                    # uses CWD
    python3 job-cost-summary.py /path/to/repo      # explicit path
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

    rows = []
    total_cost = 0.0

    for run_file in runs_dir.glob("*.json"):
        try:
            d = json.loads(run_file.read_text())
        except (json.JSONDecodeError, OSError):
            continue
        if "id" not in d:
            continue
        s = d.get("summary", {})
        cost = s.get("costUsd", 0)
        total_cost += cost
        op = d.get("operation", "?")
        st = d.get("status", "?")
        pages = len(d.get("pageChanges", {}).get("created", []))
        rows.append((cost, st, op, pages, d["id"]))

    # Sort by cost descending
    rows.sort(key=lambda r: r[0], reverse=True)

    print(f"{'COST':>7}\t{'STATUS':<12}\t{'OP':<10}\t{'PAGES':>6}\tRUN ID")
    for cost, st, op, pages, run_id in rows:
        print(f"${cost:>5.2f}\t{st:<12}\t{op:<10}\t+{pages}pg\t{run_id}")

    print(f"\nTotal: ${total_cost:.2f} across {len(rows)} job(s)")


if __name__ == "__main__":
    main()
