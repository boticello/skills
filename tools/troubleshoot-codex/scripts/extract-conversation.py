#!/usr/bin/env python3
"""Extract a readable text conversation from a Codex Desktop JSONL session transcript."""

import json
import os
import sys
from datetime import datetime, timezone


def format_ts(ts_str: str) -> str:
    """Format ISO timestamp for display."""
    try:
        dt = datetime.fromisoformat(ts_str.replace("Z", "+00:00"))
        return dt.strftime("%H:%M:%S")
    except (ValueError, AttributeError):
        return ts_str[:19]


def extract_text(content) -> str:
    """Extract plain text from content field (may be string or list of blocks)."""
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        parts = []
        for block in content:
            if isinstance(block, dict) and block.get("type") == "text":
                parts.append(block.get("text", ""))
        return "\n".join(parts)
    return str(content)


def main():
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <session.jsonl> [--full]", file=sys.stderr)
        print(
            f"       --full  Show tool calls and reasoning, not just messages",
            file=sys.stderr,
        )
        sys.exit(1)

    filepath = sys.argv[1]
    show_full = "--full" in sys.argv

    if not os.path.exists(filepath):
        print(f"ERROR: File not found: {filepath}", file=sys.stderr)
        sys.exit(1)

    session_id = None
    cwd = None
    turn_count = 0

    with open(filepath) as f:
        lines = f.readlines()

    for line in lines:
        try:
            obj = json.loads(line)
        except json.JSONDecodeError:
            continue

        event_type = obj.get("type", "")
        payload = obj.get("payload", {})
        ts = format_ts(obj.get("timestamp", ""))

        # Session metadata
        if event_type == "session_meta" and not session_id:
            session_id = payload.get("id", "?")
            cwd = payload.get("cwd", "?")
            source = payload.get("source", "?")
            version = payload.get("cli_version", "?")
            print(f"{'=' * 70}")
            print(f"Session:  {session_id}")
            print(f"CWD:      {cwd}")
            print(f"Source:   {source}  (cli {version})")
            print(f"{'=' * 70}")
            print()
            continue

        # Turn start
        if event_type == "event_msg" and payload.get("type") == "task_started":
            turn_count += 1
            if show_full:
                print(f"--- Turn {turn_count} @ {ts} ---")
            continue

        # User messages
        if event_type == "event_msg" and payload.get("type") == "user_message":
            msg = payload.get("message", "").strip()
            if msg:
                print(f"[{ts}] USER:")
                # Indent for readability
                for mline in msg.split("\n")[:50]:
                    print(f"  {mline}")
                if msg.count("\n") > 50:
                    print(f"  ... ({msg.count(chr(10)) - 50} more lines)")
                print()
            continue

        # Agent messages
        if event_type == "event_msg" and payload.get("type") == "agent_message":
            msg = payload.get("message", "").strip()
            if msg:
                print(f"[{ts}] AGENT:")
                for mline in msg.split("\n")[:50]:
                    print(f"  {mline}")
                if msg.count("\n") > 50:
                    print(f"  ... ({msg.count(chr(10)) - 50} more lines)")
                print()
            continue

        # Task complete
        if event_type == "event_msg" and payload.get("type") == "task_complete":
            duration_s = payload.get("duration_ms", 0) / 1000
            print(f"[{ts}] TURN COMPLETE ({duration_s:.1f}s)")
            print()
            continue

        # Full mode: tool calls
        if show_full and event_type == "response_item":
            pt = payload.get("type", "")
            if pt == "function_call":
                name = payload.get("name", "?")
                args = payload.get("arguments", "")
                if isinstance(args, str) and len(args) > 200:
                    args = args[:200] + "..."
                print(f"[{ts}] TOOL: {name}")
                if args:
                    for aline in str(args).split("\n")[:5]:
                        print(f"  {aline}")
                print()
            elif pt == "reasoning":
                summary = payload.get("summary", [])
                if isinstance(summary, list):
                    summary = " ".join(
                        s.get("text", "") if isinstance(s, dict) else str(s)
                        for s in summary
                    )
                if summary:
                    print(f"[{ts}] THINKING: {str(summary)[:200]}")
                    print()

    print(f"--- End of transcript ({len(lines)} lines, {turn_count} turns) ---")


if __name__ == "__main__":
    main()
