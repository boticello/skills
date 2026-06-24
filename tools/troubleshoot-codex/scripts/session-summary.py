#!/usr/bin/env python3
"""Print a one-line summary of a Codex Desktop JSONL session transcript."""

import json
import os
import sys
from datetime import datetime


def main():
    if len(sys.argv) < 2:
        print(
            f"Usage: {sys.argv[0]} <session.jsonl> [session.jsonl ...]",
            file=sys.stderr,
        )
        sys.exit(1)

    for filepath in sys.argv[1:]:
        if not os.path.exists(filepath):
            print(f"NOT FOUND: {filepath}")
            continue

        session_id = "?"
        cwd = "?"
        thread_source = "?"
        source_str = "?"
        start_ts = None
        end_ts = None
        user_msgs = 0
        agent_msgs = 0
        tool_calls = 0
        ended_cleanly = False

        with open(filepath) as f:
            lines = f.readlines()

        for line in lines:
            try:
                obj = json.loads(line)
            except json.JSONDecodeError:
                continue

            ts = obj.get("timestamp", "")
            event_type = obj.get("type", "")
            payload = obj.get("payload", {})
            ptype = payload.get("type", "")

            if event_type == "session_meta" and session_id == "?":
                session_id = payload.get("id", "?")[:8]
                cwd = payload.get("cwd", "?")
                thread_source = payload.get("thread_source", "?")

            # Extract source from any event that carries it
            if source_str == "?" and "source" in payload:
                src = payload["source"]
                if isinstance(src, dict) and "subagent" in src:
                    sub = src["subagent"].get("thread_spawn", {})
                    nickname = sub.get("agent_nickname", "?")
                    role = sub.get("agent_role", "?")
                    source_str = f"sub:{nickname}/{role}"
                elif isinstance(src, str):
                    source_str = src
                else:
                    source_str = str(src)

            if event_type == "event_msg":
                if ptype == "user_message":
                    user_msgs += 1
                elif ptype == "agent_message":
                    agent_msgs += 1
                elif ptype == "task_started":
                    start_ts = ts if not start_ts else start_ts
                elif ptype == "task_complete":
                    end_ts = ts
                    ended_cleanly = True

            if event_type == "response_item" and ptype == "function_call":
                tool_calls += 1

        duration = ""
        if start_ts and end_ts:
            try:
                s = datetime.fromisoformat(start_ts.replace("Z", "+00:00"))
                e = datetime.fromisoformat(end_ts.replace("Z", "+00:00"))
                delta = (e - s).total_seconds()
                if delta > 3600:
                    duration = f"{delta / 3600:.1f}h"
                elif delta > 60:
                    duration = f"{delta / 60:.0f}m"
                else:
                    duration = f"{delta:.0f}s"
            except ValueError:
                duration = "?"

        size_kb = os.path.getsize(filepath) // 1024
        status = "OK" if ended_cleanly else "INTERRUPTED"
        date = (
            filepath.split("/sessions/")[-1][:10] if "/sessions/" in filepath else "?"
        )

        src_label = f"{thread_source}/{source_str}"

        print(
            f"{date}  {session_id}  {cwd.split('/')[-1][:30]:<30}  "
            f"{src_label:<25}  "
            f"u:{user_msgs} a:{agent_msgs} t:{tool_calls}  "
            f"{duration:>6}  {size_kb:>5}KB  {status}"
        )


if __name__ == "__main__":
    main()
