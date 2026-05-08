# persistent-kb

A SKILL.md-format Agent Skill that gives any AI coding agent a **persistent, searchable knowledge base** stored locally in a single SQLite file. Survives session restarts, context compaction, and machine reboots.

> 💡 **Looking for the MCP server version?** Same functionality, exposed as 5 MCP tools (`kb_add`, `kb_search`, `kb_show`, `kb_list`, `kb_tag`). Works with any MCP-capable runtime: [`canola-persistent-kb-mcp`](https://pypi.org/project/canola-persistent-kb-mcp/) — `pip install canola-persistent-kb-mcp`. Source: https://github.com/0x67108864/persistent-kb-mcp

## Why this skill exists

AI coding agents lose everything between sessions. Lessons learned, decisions taken, project context — all gone the moment the chat ends. This skill saves that knowledge to disk so the next session starts from where the last one left off.

## What it does

| Verb | What it does |
|---|---|
| `kb.py init` | Create the database (idempotent) |
| `kb.py add` | Save a fact / lesson / decision (content from stdin) |
| `kb.py search` | Full-text search via SQLite FTS5 |
| `kb.py show <id>` | Retrieve a specific entry |
| `kb.py list` | Browse by kind, tag, or date |
| `kb.py tag <id>` | Manage tags on an entry |

Storage is `~/.persistent-kb/kb.sqlite` by default, or `$KB_DB` to override.

## When to use this skill

The agent should activate this skill when the user says any of:

- "Remember this for next time"
- "What did we figure out last week about X?"
- "Don't make me re-explain my project setup every session"
- "Save this lesson"
- Any reference to **persistent memory**, **cross-session recall**, **avoiding repeat work**

## Compatibility

- **Python 3.10+ stdlib only.** No third-party packages.
- No `sqlite3` CLI required (uses Python's built-in module).
- No network access at runtime.
- Tested on Linux and macOS. Should work on Windows (untested).

## Install

Drop the `persistent-kb/` directory into your agent's skills folder:

| Agent | Path |
|---|---|
| Claude Code | `~/.claude/skills/persistent-kb/` |
| Codex CLI | `~/.codex/skills/persistent-kb/` |
| Gemini CLI | `~/.gemini/skills/persistent-kb/` |
| Cursor | `<project>/.cursor/skills/persistent-kb/` |
| Other | per the agent's docs |

## Quickstart

```bash
# initialize
./scripts/kb.py init

# save a fact
echo "Stripe Connect needs the platform to be onboarded first; account holder applies via OAuth." | \
  ./scripts/kb.py add --title "Stripe Connect onboarding order" --kind lesson --tags "stripe,connect,onboarding"

# search later
./scripts/kb.py search "stripe onboarding"
```

## Configuration

| Env var | Default | Purpose |
|---|---|---|
| `KB_DB` | `~/.persistent-kb/kb.sqlite` | DB file location |

## Why not Letta / mem0 / OpenAI memory?

| Concern | This skill | Cloud memory |
|---|---|---|
| Network required | ❌ | ✅ |
| API key required | ❌ | ✅ |
| Data leaves your machine | ❌ | ✅ |
| Vendor lock-in | None (SQLite) | Service-specific |
| Cost | Free | Per-token / per-call |

Use this when local-first matters. Use cloud memory when you actually want cross-device sync.

## Roadmap

- v0.3: optional vector embedding for semantic search (currently FTS5-only).
- v0.4: export/import for cross-machine sync.
- v0.5: time-decay scoring for relevance.

## License

MIT (see SKILL.md frontmatter).

## Author

canola_oil — https://0x67108864.github.io/
