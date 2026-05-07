#!/usr/bin/env python3
"""kb - persistent-kb single-file CLI. Python 3.10+ stdlib only.

Subcommands: init, add, search, show, list, tag
DB location: $KB_DB or ~/.persistent-kb/kb.sqlite
"""

from __future__ import annotations

import argparse
import os
import sqlite3
import sys
import textwrap
from pathlib import Path

DB_PATH = Path(os.environ.get("KB_DB", Path.home() / ".persistent-kb" / "kb.sqlite"))
SCHEMA_VERSION = 1

VALID_KINDS = ("lesson", "reference", "decision", "incident", "note", "task-log", "summary")

SCHEMA_SQL = """
PRAGMA user_version = 1;

CREATE TABLE entries (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  kind TEXT NOT NULL CHECK (kind IN ('lesson','reference','decision','incident','note','task-log','summary')),
  content TEXT NOT NULL,
  superseded_by INTEGER REFERENCES entries(id) ON DELETE SET NULL,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE TABLE tags (
  entry_id INTEGER NOT NULL REFERENCES entries(id) ON DELETE CASCADE,
  tag TEXT NOT NULL,
  PRIMARY KEY (entry_id, tag)
);
CREATE INDEX idx_tags_tag ON tags(tag);
CREATE INDEX idx_entries_kind ON entries(kind);

CREATE VIRTUAL TABLE entries_fts USING fts5(
  title, content, content='entries', content_rowid='id', tokenize='porter unicode61'
);
CREATE TRIGGER entries_ai AFTER INSERT ON entries BEGIN
  INSERT INTO entries_fts(rowid, title, content) VALUES (new.id, new.title, new.content);
END;
CREATE TRIGGER entries_au AFTER UPDATE ON entries BEGIN
  UPDATE entries_fts SET title = new.title, content = new.content WHERE rowid = new.id;
END;
CREATE TRIGGER entries_ad AFTER DELETE ON entries BEGIN
  DELETE FROM entries_fts WHERE rowid = old.id;
END;

CREATE TABLE relations (
  src_id INTEGER NOT NULL REFERENCES entries(id) ON DELETE CASCADE,
  dst_id INTEGER NOT NULL REFERENCES entries(id) ON DELETE CASCADE,
  rel_type TEXT NOT NULL,
  PRIMARY KEY (src_id, dst_id, rel_type)
);
"""


def open_db(create_if_missing: bool = False) -> sqlite3.Connection:
    if not DB_PATH.exists():
        if not create_if_missing:
            sys.exit(f"Error: database not found at {DB_PATH}. Run `kb init` first.")
        DB_PATH.parent.mkdir(parents=True, exist_ok=True)
        conn = sqlite3.connect(DB_PATH)
        conn.executescript(SCHEMA_SQL)
        conn.commit()
        return conn
    conn = sqlite3.connect(DB_PATH)
    conn.execute("PRAGMA foreign_keys = ON;")
    version = conn.execute("PRAGMA user_version;").fetchone()[0]
    if version != SCHEMA_VERSION:
        sys.exit(f"Error: schema version mismatch (db={version}, expected={SCHEMA_VERSION}). Migration needed.")
    return conn


def cmd_init(args: argparse.Namespace) -> int:
    if DB_PATH.exists():
        print(f"Database already exists at {DB_PATH}. No changes made.")
        return 0
    open_db(create_if_missing=True)
    print(f"Initialized at {DB_PATH}")
    return 0


def cmd_add(args: argparse.Namespace) -> int:
    content = sys.stdin.read()
    if not content.strip():
        print("Error: stdin content is empty", file=sys.stderr)
        return 1
    if args.kind not in VALID_KINDS:
        print(f"Error: kind must be one of {VALID_KINDS}", file=sys.stderr)
        return 1
    conn = open_db(create_if_missing=True)
    cur = conn.execute(
        "INSERT INTO entries(title, kind, content) VALUES (?, ?, ?)",
        (args.title, args.kind, content),
    )
    eid = cur.lastrowid
    if args.tags:
        for tag in args.tags.split(","):
            tag = tag.strip()
            if tag:
                conn.execute(
                    "INSERT OR IGNORE INTO tags(entry_id, tag) VALUES (?, ?)",
                    (eid, tag),
                )
    conn.commit()
    print(f"Added entry {eid}: {args.title}")
    return 0


def cmd_search(args: argparse.Namespace) -> int:
    conn = open_db()
    sql = ["SELECT e.id, e.kind, e.title, substr(e.content, 1, 200), e.created_at"]
    sql.append("FROM entries_fts f JOIN entries e ON e.id = f.rowid")
    where = ["entries_fts MATCH ?"]
    params: list[object] = [args.query]
    if args.tag:
        sql.append("JOIN tags t ON t.entry_id = e.id AND t.tag = ?")
        params.insert(0, args.tag)
    if args.kind:
        where.append("e.kind = ?")
        params.append(args.kind)
    sql.append("WHERE " + " AND ".join(where))
    sql.append("ORDER BY rank")
    sql.append(f"LIMIT {int(args.top)}")
    rows = conn.execute(" ".join(sql), params).fetchall()
    if not rows:
        print(f"(no matches for '{args.query}')")
        return 0
    for eid, kind, title, preview, created in rows:
        print(f"[{eid}] ({kind}) {title}    @ {created[:10]}")
        cleaned = " ".join(preview.split())
        print(f"    {cleaned[:150]}{'...' if len(cleaned) > 150 else ''}")
        print()
    return 0


def cmd_show(args: argparse.Namespace) -> int:
    conn = open_db()
    row = conn.execute(
        "SELECT id, title, kind, content, superseded_by, created_at, updated_at FROM entries WHERE id = ?",
        (args.id,),
    ).fetchone()
    if not row:
        print(f"Error: entry {args.id} not found", file=sys.stderr)
        return 3
    eid, title, kind, content, superseded, created, updated = row
    tags = [t for (t,) in conn.execute("SELECT tag FROM tags WHERE entry_id = ? ORDER BY tag", (eid,))]
    relations = [
        f"{rt} -> {dst}"
        for rt, dst in conn.execute(
            "SELECT rel_type, dst_id FROM relations WHERE src_id = ? ORDER BY rel_type", (eid,)
        )
    ]
    print(f"=== Entry {eid} ===")
    print(f"Title:      {title}")
    print(f"Kind:       {kind}")
    print(f"Tags:       {', '.join(tags) if tags else '(none)'}")
    print(f"Created:    {created}")
    print(f"Updated:    {updated}")
    if superseded:
        print(f"Superseded by: {superseded}")
    if relations:
        print(f"Relations:  {'; '.join(relations)}")
    print()
    print("--- Content ---")
    print(content)
    return 0


def cmd_list(args: argparse.Namespace) -> int:
    conn = open_db()
    sql = ["SELECT e.id, e.kind, e.title, e.created_at FROM entries e"]
    where = ["1=1"]
    params: list[object] = []
    if args.tag:
        sql.append("JOIN tags t ON t.entry_id = e.id AND t.tag = ?")
        params.append(args.tag)
    if args.kind:
        where.append("e.kind = ?")
        params.append(args.kind)
    if args.since:
        where.append("date(e.created_at) >= date(?)")
        params.append(args.since)
    sql.append("WHERE " + " AND ".join(where))
    sql.append("ORDER BY e.created_at DESC")
    sql.append(f"LIMIT {int(args.limit)}")
    rows = conn.execute(" ".join(sql), params).fetchall()
    for eid, kind, title, created in rows:
        title_short = (title[:60] + "...") if len(title) > 60 else title
        print(f"[{eid:>4}] ({kind:<10}) {created[:10]}  {title_short}")
    if not rows:
        print("(no entries)")
    return 0


def cmd_tag(args: argparse.Namespace) -> int:
    conn = open_db()
    exists = conn.execute("SELECT 1 FROM entries WHERE id = ?", (args.id,)).fetchone()
    if not exists:
        print(f"Error: entry {args.id} not found", file=sys.stderr)
        return 3
    if args.add:
        for tag in args.add.split(","):
            tag = tag.strip()
            if tag:
                conn.execute("INSERT OR IGNORE INTO tags(entry_id, tag) VALUES (?, ?)", (args.id, tag))
                print(f"+ {tag}")
    if args.remove:
        for tag in args.remove.split(","):
            tag = tag.strip()
            if tag:
                conn.execute("DELETE FROM tags WHERE entry_id = ? AND tag = ?", (args.id, tag))
                print(f"- {tag}")
    conn.commit()
    tags = [t for (t,) in conn.execute("SELECT tag FROM tags WHERE entry_id = ? ORDER BY tag", (args.id,))]
    print(f"Now: {', '.join(tags) if tags else '(none)'}")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(
        prog="kb",
        description="persistent-kb: local SQLite-backed knowledge base for cross-session agent memory.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=textwrap.dedent(
            """\
            Examples:
              kb init
              echo "fact content" | kb add --title "T" --kind lesson --tags "topic1,topic2"
              kb search "query terms" --top 5
              kb show 42
              kb list --kind lesson --limit 20
              kb tag 42 --add new-tag --remove old-tag

            Database location: $KB_DB or ~/.persistent-kb/kb.sqlite
            """
        ),
    )
    sub = parser.add_subparsers(dest="cmd", required=True)

    sub.add_parser("init", help="initialize the database").set_defaults(func=cmd_init)

    p_add = sub.add_parser("add", help="add a new entry (content from stdin)")
    p_add.add_argument("--title", required=True)
    p_add.add_argument("--kind", default="note", choices=VALID_KINDS)
    p_add.add_argument("--tags", default="", help="comma-separated tag list")
    p_add.set_defaults(func=cmd_add)

    p_search = sub.add_parser("search", help="full-text search via FTS5")
    p_search.add_argument("query")
    p_search.add_argument("--top", type=int, default=10)
    p_search.add_argument("--kind", choices=VALID_KINDS)
    p_search.add_argument("--tag")
    p_search.set_defaults(func=cmd_search)

    p_show = sub.add_parser("show", help="show one entry's full content")
    p_show.add_argument("id", type=int)
    p_show.set_defaults(func=cmd_show)

    p_list = sub.add_parser("list", help="list entries with optional filters")
    p_list.add_argument("--kind", choices=VALID_KINDS)
    p_list.add_argument("--tag")
    p_list.add_argument("--since", help="YYYY-MM-DD")
    p_list.add_argument("--limit", type=int, default=20)
    p_list.set_defaults(func=cmd_list)

    p_tag = sub.add_parser("tag", help="add/remove tags on an entry")
    p_tag.add_argument("id", type=int)
    p_tag.add_argument("--add", help="comma-separated tags to add")
    p_tag.add_argument("--remove", help="comma-separated tags to remove")
    p_tag.set_defaults(func=cmd_tag)

    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
