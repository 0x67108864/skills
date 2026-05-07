---
name: persistent-kb
description: Maintain a local SQLite-backed knowledge base for cross-session agent memory. Save discovered facts, lessons, and references with tags and full-text search, then retrieve them in future sessions to avoid re-discovering the same information. Use when the user wants the agent to remember facts beyond the current chat (decisions, project context, prior research, lessons learned), reduce redundant work across sessions, or build a personal knowledge base. Unlike cloud memory services, this skill stores everything locally in a single SQLite file.
license: MIT
compatibility: Requires Python 3.10+ stdlib only (no sqlite3 CLI, no third-party packages, no network access). Tested on Linux and macOS.
metadata:
  author: canola_oil
  version: "0.2.0"
  homepage: "https://0x67108864.github.io/"
allowed-tools: Bash(./scripts/kb.py:*) Read Write
---

# Persistent KB

Cross-session knowledge base for AI agents. A single Python file (`scripts/kb.py`) operating on a single SQLite file. Survives context compaction, session restarts, and machine reboots. No installation step beyond Python 3.10+.

## When to use this skill

Activate when the user expresses any of:

- "Remember this for next time"
- "What did we figure out last week about X?"
- "Don't make me re-explain this every session"
- "Save this lesson / fact / reference"
- "Build me a knowledge base I can search later"
- Any reference to **memory**, **persistent context**, **cross-session recall**, or **avoiding repeat work**

Do *not* activate for ephemeral one-shot questions (no need to persist), or when the user already has a different memory system (e.g. Letta, mem0) actively in use.

## Core operations

The skill exposes 6 subcommands via a single CLI `scripts/kb.py`:

| Command | Purpose |
|---|---|
| `kb.py init` | Create the database (idempotent) |
| `kb.py add` | Insert a new entry (content from stdin) with title, kind, tags |
| `kb.py search <query>` | Full-text search over entries (FTS5) |
| `kb.py show <id>` | Print one entry's full content + metadata |
| `kb.py list` | Filter by kind / tag / date and list summaries |
| `kb.py tag <id>` | Add or remove tags on an existing entry |

All commands operate on the same database (default `~/.persistent-kb/kb.sqlite`, override via `KB_DB`).

## Procedure

### First use in a session

1. Initialize if needed (idempotent):
   ```bash
   ./scripts/kb.py init
   ```
2. Read the recently saved index:
   ```bash
   ./scripts/kb.py list --limit 10
   ```
3. Mention to the user: "I have N saved facts in your KB. Want me to surface relevant ones for the current task?"

### Saving a fact

When the user says "remember this" or you encounter a non-obvious finding:

```bash
echo "<fact content>" | ./scripts/kb.py add \
  --title "Short title" \
  --kind lesson \
  --tags "discovered,topic1,topic2"
```

Recommended `kind` values:
- `lesson` — insight from doing work
- `reference` — external info worth keeping
- `decision` — resolved choice
- `incident` — failure or issue to avoid repeating
- `note` — everything else
- `task-log` — record of completed work
- `summary` — periodic roll-up

### Recalling

When the user asks about something or starts a related task:

```bash
./scripts/kb.py search "topic keywords" --top 5
```

Then `./scripts/kb.py show <id>` for any promising hit.

### Avoiding duplicates

Before saving, run a search with the title's main keywords. If a near-match exists, **update or supersede** the old entry instead of creating a duplicate.

## Schema

See `references/SCHEMA.md` for the full DDL. Summary:

- `entries` — primary table (id, title, kind, content, timestamps, optional `superseded_by`)
- `tags` — many-to-many between entries and tag strings
- `entries_fts` — FTS5 virtual table for keyword search
- `relations` — typed links between entries

The schema lives in `scripts/kb.py` and is created on first `init`.

## Edge cases

- **Database locked**: SQLite single-writer. If a long-running task holds the lock, retry once with 100ms backoff. If it persists, surface the lock holder PID and ask the user.
- **Conflicting facts** (new info contradicts old entry): mark the old entry as `superseded_by=<new_id>` rather than deleting. Keep history.
- **Sensitive content** (API keys, passwords, PII): refuse to save. Tell the user to use a secret manager instead.
- **Content > 100KB**: warn user, split into chunks or save a reference to an external file.
- **No matches found in search**: explicitly say so. Do not fabricate or pad with adjacent topics.

## Output discipline

- Search results: max 5 entries per response, oldest first within score band.
- Show: entire entry + tags + relations.
- Add: 1-line confirmation with the new entry ID.
- List: max 20 rows, default sort by created_at desc.

## Differentiation vs other memory systems

- **Letta** / **mem0** / **OpenAI memory**: cloud-hosted. This skill is **local-only**, no API key, no network.
- Anthropic's **session-report**: in-session only, cleared on new session. This skill **persists across sessions**.
- **CLAUDE.md / project memory files**: human-curated and small. This skill scales to thousands of entries with FTS5 ranking.

## Limitations

- Single-user, single-machine. Not designed for team collaboration (export/import is a future feature).
- FTS5-only search; semantic similarity (vector embeddings) is on the v0.3 roadmap.
- No time-decay scoring — all entries treated equally regardless of age (relevance is purely FTS rank).
- Schema migrations: v0.2 ships a single schema version; future bumps will provide migration scripts.
