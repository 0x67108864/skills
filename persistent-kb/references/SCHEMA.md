# persistent-kb schema

## Tables

```sql
CREATE TABLE entries (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  title       TEXT NOT NULL,
  kind        TEXT NOT NULL CHECK (kind IN ('lesson','reference','decision','incident','note','task-log','summary')),
  content     TEXT NOT NULL,
  superseded_by INTEGER REFERENCES entries(id) ON DELETE SET NULL,
  created_at  TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at  TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE tags (
  entry_id    INTEGER NOT NULL REFERENCES entries(id) ON DELETE CASCADE,
  tag         TEXT NOT NULL,
  PRIMARY KEY (entry_id, tag)
);

CREATE INDEX idx_tags_tag ON tags(tag);
CREATE INDEX idx_entries_kind ON entries(kind);

-- FTS5 virtual table for keyword search
CREATE VIRTUAL TABLE entries_fts USING fts5(
  title, content, content='entries', content_rowid='id', tokenize='porter unicode61'
);

-- triggers to keep FTS in sync
CREATE TRIGGER entries_ai AFTER INSERT ON entries BEGIN
  INSERT INTO entries_fts(rowid, title, content) VALUES (new.id, new.title, new.content);
END;
CREATE TRIGGER entries_au AFTER UPDATE ON entries BEGIN
  UPDATE entries_fts SET title = new.title, content = new.content WHERE rowid = new.id;
END;
CREATE TRIGGER entries_ad AFTER DELETE ON entries BEGIN
  DELETE FROM entries_fts WHERE rowid = old.id;
END;

-- relations between entries (prerequisite-of, contradicts, refines, etc.)
CREATE TABLE relations (
  src_id      INTEGER NOT NULL REFERENCES entries(id) ON DELETE CASCADE,
  dst_id      INTEGER NOT NULL REFERENCES entries(id) ON DELETE CASCADE,
  rel_type    TEXT NOT NULL,
  PRIMARY KEY (src_id, dst_id, rel_type)
);

-- optional: embeddings for vector search (skipped if no embedding tool configured)
CREATE TABLE embeddings (
  entry_id    INTEGER PRIMARY KEY REFERENCES entries(id) ON DELETE CASCADE,
  vec         BLOB NOT NULL,
  model       TEXT NOT NULL,
  created_at  TEXT NOT NULL DEFAULT (datetime('now'))
);
```

## Migration policy

- Schema version is stored in `PRAGMA user_version`.
- Every breaking change increments user_version and ships a migration script in `scripts/migrations/`.
- The CLI checks user_version on each invocation and refuses to run if migration is pending, telling the user how to apply it.

## Sizing

- Typical entry: 100-2000 bytes.
- 1,000 entries ≈ 1-2 MB on disk.
- 10,000 entries ≈ 10-20 MB.
- FTS index roughly doubles disk usage.

## Backup

- The DB is a single file. `cp` is sufficient for backup.
- For point-in-time consistency under writes, use `sqlite3 kb.sqlite ".backup <dest>"`.
