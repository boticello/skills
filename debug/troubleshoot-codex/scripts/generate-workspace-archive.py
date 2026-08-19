#!/usr/bin/env python3
"""Batch-generate HTML transcript archives for a Codex workspace.

Queries ~/.codex/state_5.sqlite (read-only) for sessions matching a workspace
path, then invokes codex-transcripts and/or codex-transcript-viewer to produce
browsable HTML with index pages and parent↔child linking.
"""

from __future__ import annotations

import argparse
import datetime
import re
import shutil
import sqlite3
import subprocess
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional

CODEX_DB = Path.home() / ".codex" / "state_5.sqlite"

CSS = """body{font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif;
max-width:960px;margin:2rem auto;padding:0 1rem;color:#1a1a1a;background:#fafafa}
a{color:#0066cc;text-decoration:none}a:hover{text-decoration:underline}
h1{border-bottom:2px solid #e0e0e0;padding-bottom:.5rem}
table{border-collapse:collapse;width:100%;margin:1rem 0}
th,td{text-align:left;padding:.5rem .75rem;border-bottom:1px solid #e0e0e0}
th{background:#f0f0f0;font-weight:600}tr:hover{background:#f5f5ff}
.meta{color:#666;font-size:.9em}.back{margin-bottom:1.5rem}"""

HTML_WRAP = (
    '<!DOCTYPE html><html lang="en"><head><meta charset="utf-8">'
    '<meta name="viewport" content="width=device-width,initial-scale=1">'
    "<title>{title}</title><style>{css}</style></head><body>\n{body}\n</body></html>"
)


@dataclass
class Session:
    id: str
    title: str
    cwd: str
    rollout_path: str
    thread_source: str
    agent_nickname: Optional[str] = None
    agent_role: Optional[str] = None
    updated_at: int = 0
    created_at: int = 0
    children: list["Session"] = field(default_factory=list)


# ── Helpers ──────────────────────────────────────────────────────────────


def slugify(text: str) -> str:
    t = text.lower().strip()
    t = re.sub(r"[^a-z0-9]+", "-", t)
    return re.sub(r"-+", "-", t).strip("-")


def make_slug(s: Session) -> str:
    title_part = slugify(s.title or "untitled")[:60]
    if s.thread_source == "subagent" and s.agent_nickname:
        return f"{slugify(s.agent_nickname)}-{title_part}"
    return title_part


def check_tool(name: str) -> str:
    if p := shutil.which(name):
        return p
    install = {
        "codex-transcripts": "uv tool install codex-transcripts",
        "codex-transcript-viewer": "git clone https://github.com/masonc15/codex-transcript-viewer"
        " && cd codex-transcript-viewer && uv tool install .",
    }
    print(
        f"ERROR: '{name}' not found on PATH.\n  Install: {install.get(name, '…')}",
        file=sys.stderr,
    )
    sys.exit(1)


def run_cmd(cmd: list[str], desc: str) -> bool:
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
        if r.returncode != 0:
            print(f"  WARN: {desc} failed (rc={r.returncode})", file=sys.stderr)
            for line in (r.stderr or "").strip().splitlines()[:3]:
                print(f"        {line}", file=sys.stderr)
            return False
        return True
    except (FileNotFoundError, subprocess.TimeoutExpired) as e:
        print(f"  WARN: {desc} – {e}", file=sys.stderr)
        return False


def write_html(path: Path, title: str, body: str) -> Path:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(HTML_WRAP.format(title=title, css=CSS, body=body), encoding="utf-8")
    return path


def ts(ts: int) -> str:
    return datetime.datetime.fromtimestamp(ts).strftime("%Y-%m-%d %H:%M") if ts else "—"


def html_table(headers: list[str], rows: list[str]) -> str:
    hdr = "".join(f"<th>{h}</th>" for h in headers)
    return f"<table><tr>{hdr}</tr>\n{''.join(rows)}</table>"


# ── SQLite ───────────────────────────────────────────────────────────────


def query_sessions(db_path: Path, workspace: str) -> list[Session]:
    uri = f"file:{db_path}?immutable=1"
    con = sqlite3.connect(uri, uri=True)
    con.row_factory = sqlite3.Row
    cur = con.cursor()
    cur.execute(
        "SELECT id, COALESCE(NULLIF(title,''),'Untitled') AS title,"
        " cwd, rollout_path, thread_source, agent_nickname, agent_role,"
        " updated_at, created_at FROM threads WHERE cwd = ? ORDER BY updated_at DESC",
        (workspace,),
    )
    sessions: dict[str, Session] = {}
    for r in cur.fetchall():
        s = Session(
            id=r["id"],
            title=r["title"],
            cwd=r["cwd"],
            rollout_path=r["rollout_path"] or "",
            thread_source=r["thread_source"] or "user",
            agent_nickname=r["agent_nickname"],
            agent_role=r["agent_role"],
            updated_at=r["updated_at"] or 0,
            created_at=r["created_at"] or 0,
        )
        sessions[s.id] = s
    if sessions:
        ph = ",".join("?" * len(sessions))
        cur.execute(
            f"SELECT parent_thread_id, child_thread_id "
            f"FROM thread_spawn_edges WHERE parent_thread_id IN ({ph})",
            tuple(sessions.keys()),
        )
        for r in cur.fetchall():
            p, c = (
                sessions.get(r["parent_thread_id"]),
                sessions.get(r["child_thread_id"]),
            )
            if p and c:
                p.children.append(c)
    con.close()
    return list(sessions.values())


# ── JSONL resolution ─────────────────────────────────────────────────────


def resolve_jsonl(s: Session) -> Optional[Path]:
    if s.rollout_path and Path(s.rollout_path).exists():
        return Path(s.rollout_path)
    sessions_dir = Path.home() / ".codex" / "sessions"
    if sessions_dir.exists():
        for f in sessions_dir.rglob("*.jsonl"):
            if s.id in f.name:
                return f
    return None


# ── Transcript generation ───────────────────────────────────────────────


def generate_ct(sessions: list[Session], output: Path, tool_bin: str) -> list[Path]:
    out: list[Path] = []
    for s in sessions:
        jsonl = resolve_jsonl(s)
        if not jsonl:
            print(f"  SKIP: no transcript for {s.id[:8]} ({s.title[:40]})")
            continue
        d = output / make_slug(s)
        d.mkdir(parents=True, exist_ok=True)
        if run_cmd([tool_bin, "json", str(jsonl), "-o", str(d)], f"ct: {s.title[:40]}"):
            out.append(d)
    return out


def generate_ctv(sessions: list[Session], output: Path, tool_bin: str) -> list[Path]:
    out: list[Path] = []
    for s in sessions:
        jsonl = resolve_jsonl(s)
        if not jsonl:
            print(f"  SKIP: no transcript for {s.id[:8]} ({s.title[:40]})")
            continue
        f = output / f"{make_slug(s)}.html"
        if (
            run_cmd([tool_bin, str(jsonl), str(f)], f"ctv: {s.title[:40]}")
            and f.exists()
        ):
            out.append(f)
    return out


# ── Index pages ──────────────────────────────────────────────────────────


def make_top_index(parents: list[Session], output: Path, fmt: str) -> Path:
    rows = []
    for p in parents:
        slug = make_slug(p)
        nc = len(p.children)
        note = f" ({nc} subagent{'s' if nc != 1 else ''})" if nc else ""
        href = f"{slug}/" if fmt != "ctv" else f"{slug}.html"
        rows.append(
            f'<tr><td><a href="{href}">{p.title}</a>{note}</td>'
            f'<td class="meta">{p.id[:12]}…</td><td class="meta">{ts(p.updated_at)}</td></tr>'
        )
    body = f"<h1>Codex Workspace Archive</h1>\n<p>Workspace: <code>{parents[0].cwd if parents else ''}</code></p>"
    body += f"\n<p>{len(parents)} session{'s' if len(parents) != 1 else ''}</p>"
    body += "\n" + html_table(["Title", "Session", "Updated"], rows)
    return write_html(output / "index.html", "Workspace Archive", body)


def make_agents_index(parent: Session, parent_dir: Path) -> Optional[Path]:
    if not parent.children:
        return None
    ad = parent_dir / "agents"
    ad.mkdir(parents=True, exist_ok=True)
    rows = []
    for c in sorted(parent.children, key=lambda x: x.created_at):
        slug = make_slug(c)
        rows.append(
            f'<tr><td><a href="{slug}/">{c.title}</a></td>'
            f"<td>{c.agent_nickname or 'agent'}</td><td>{c.agent_role or '—'}</td>"
            f'<td class="meta">{ts(c.created_at)}</td></tr>'
        )
    body = (
        f'<div class="back"><a href="../">← Back to {parent.title}</a></div>'
        f"\n<h1>Subagents for: {parent.title}</h1>"
        f"\n<p>{len(parent.children)} subagent session{'s' if len(parent.children) != 1 else ''}</p>"
        f"\n" + html_table(["Title", "Nickname", "Role", "Created"], rows)
    )
    return write_html(ad / "index.html", f"Subagents — {parent.title}", body)


def inject_link(parent_dir: Path, parent: Session) -> None:
    ad = parent_dir / "agents"
    if not ad.exists():
        return
    for html_file in (parent_dir / "index.html", *parent_dir.glob("*.html")):
        if not html_file.exists():
            continue
        try:
            content = html_file.read_text("utf-8")
        except Exception:
            continue
        n = len(parent.children)
        link = (
            f'<div style="margin:2rem 0;padding:1rem;background:#eef;border-radius:6px">'
            f'→ <a href="agents/">View {n} subagent session{"s" if n != 1 else ""}</a></div>\n'
        )
        if "</body>" in content:
            html_file.write_text(content.replace("</body>", f"{link}</body>"), "utf-8")


# ── Main ─────────────────────────────────────────────────────────────────


def main() -> None:
    ap = argparse.ArgumentParser(
        description="Batch-generate HTML transcript archives for a Codex workspace."
    )
    ap.add_argument("--workspace", required=True, help="CWD path to filter sessions by")
    ap.add_argument("--output", required=True, help="Output directory path")
    ap.add_argument(
        "--tool",
        choices=["codex-transcripts", "codex-transcript-viewer", "both"],
        default="codex-transcripts",
        help="Tool to use (default: codex-transcripts)",
    )
    ap.add_argument(
        "--include-subagents",
        action=argparse.BooleanOptionalAction,
        default=True,
        help="Also generate subagent sessions (default: true)",
    )
    ap.add_argument(
        "--link",
        action=argparse.BooleanOptionalAction,
        default=True,
        help="Generate index pages with parent↔child linking (default: true)",
    )
    args = ap.parse_args()

    if not CODEX_DB.exists():
        print(f"ERROR: database not found at {CODEX_DB}", file=sys.stderr)
        sys.exit(1)

    use_ct = args.tool in ("codex-transcripts", "both")
    use_ctv = args.tool in ("codex-transcript-viewer", "both")
    ct_bin = check_tool("codex-transcripts") if use_ct else ""
    ctv_bin = check_tool("codex-transcript-viewer") if use_ctv else ""

    output = Path(args.output)
    output.mkdir(parents=True, exist_ok=True)

    print(f"Querying sessions for workspace: {args.workspace}")
    all_sessions = query_sessions(CODEX_DB, args.workspace)
    parents = [s for s in all_sessions if s.thread_source == "user"]
    children = [s for s in all_sessions if s.thread_source == "subagent"]
    if not parents and not children:
        print("No sessions found for this workspace.")
        sys.exit(0)
    print(f"Found {len(parents)} parent(s), {len(children)} subagent(s)")

    to_gen = list(parents)
    if args.include_subagents:
        to_gen.extend(children)

    files: list[Path] = []

    if use_ct:
        print("\n→ Generating with codex-transcripts …")
        files.extend(generate_ct(to_gen, output, ct_bin))
        if args.link:
            for p in parents:
                d = output / make_slug(p)
                if d.is_dir():
                    make_agents_index(p, d)
                    inject_link(d, p)

    if use_ctv:
        print("\n→ Generating with codex-transcript-viewer …")
        ctv_out = (output / "transcript-viewer") if use_ct else output
        ctv_out.mkdir(parents=True, exist_ok=True)
        files.extend(generate_ctv(to_gen, ctv_out, ctv_bin))

    if args.link and parents:
        fmt = "ctv" if (use_ctv and not use_ct) else "ct"
        files.append(make_top_index(parents, output, fmt))

    # Summary
    print("\n" + "=" * 60 + "\nDone! Generated:")
    for f in sorted(files):
        rel = f.relative_to(output) if f.is_relative_to(output) else f
        sz = f.stat().st_size if f.exists() else 0
        print(f"  {rel}  ({sz:,} bytes)")
    total = sum(f.stat().st_size for f in files if f.exists())
    print(f"\n  {len(files)} file(s), {total:,} bytes total\n  Output: {output}")


if __name__ == "__main__":
    main()
