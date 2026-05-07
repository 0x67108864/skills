---
name: host-shared-task-queue
description: Asynchronous task queue between an AI agent and an external process (another machine, a Windows host, a long-running worker) using a shared filesystem directory as the transport. Use when the user needs the agent to delegate work that the agent itself cannot do — running a Windows-only tool, controlling a browser session that lives on the host, fetching data via a service the host has API keys for, or any pattern where a watcher process on the other side processes requests from the agent. Implements an inbox/outbox/result-bus convention safe for cross-machine, cross-OS use.
license: MIT
compatibility: Requires bash 4+, jq, uuidgen (or Python 3 fallback), and `find`. The shared directory must be writable by the agent and readable by the watcher (e.g., Samba share, SyncThing, Dropbox, NFS, or local cross-account folder).
metadata:
  author: canola_oil
  version: "0.1.0"
  homepage: "https://0x67108864.github.io/"
allowed-tools: Bash(./scripts/queue-*:*) Read Write
---

# Host-Shared Task Queue

A simple, robust pattern for the agent and an external worker to communicate via a shared filesystem directory.

## When to use this skill

Activate when the user expresses any of:

- "Have the host run X for me and report back"
- "I need to call a Windows-only tool from this Linux agent"
- "Send this query to the watcher / worker / browser host"
- "Use the shared folder to coordinate"
- Any reference to **inbox**, **outbox**, **watcher**, **shared folder transport**, **cross-machine queue**

Do *not* activate for:
- Direct API calls (use `WebFetch` or a dedicated MCP server).
- Synchronous IPC (use a normal subprocess invocation).
- Pure local file operations (use Read/Write/Bash directly).

## Convention overview

```
SHARED_ROOT/
├── outbox/<queue>/<uuid>.json    # agent → worker (request)
└── inbox/<queue>/<uuid>/         # worker → agent (result)
    ├── result.json
    └── (any auxiliary files)
```

- Agent writes a request as a single JSON file under `outbox/<queue>/<uuid>.json`.
- A watcher on the other side picks it up, processes it, and writes the result under `inbox/<queue>/<uuid>/`.
- Agent polls `inbox/<queue>/<uuid>/result.json` for completion.

This is intentionally low-tech: no broker, no message bus, no auth setup beyond filesystem ACLs. Failures are visible in the filesystem.

## Core operations

| Command | Purpose |
|---|---|
| `queue-send.sh <queue> <payload-json>` | Submit a request, returns the UUID |
| `queue-wait.sh <queue> <uuid> [--timeout 300]` | Block until result arrives or timeout |
| `queue-recv.sh <queue> <uuid>` | Read the result JSON (assumes it's ready) |
| `queue-list.sh <queue>` | Show pending requests and recent results |
| `queue-purge.sh <queue> [--older-than 7d]` | Remove old completed entries |

## Procedure

### Submit a request

```bash
./scripts/queue-send.sh research '{"topic": "foo", "sources": ["hn", "reddit"]}' > uuid.txt
```

### Wait for the result

```bash
UUID=$(cat uuid.txt)
./scripts/queue-wait.sh research "$UUID" --timeout 180
./scripts/queue-recv.sh research "$UUID"  # prints result.json
```

### Without polling (one-shot, sleeps internally)

```bash
./scripts/queue-send.sh research '<payload>' | xargs -I{} ./scripts/queue-wait.sh research {} --timeout 180
```

## Configuration

Set `SHARED_ROOT` env var (default `/shared`) to point at the shared directory. The shared root must contain `outbox/` and `inbox/` subdirectories pre-created with appropriate write permissions.

Example for SyncThing:
```bash
export SHARED_ROOT="$HOME/Sync/agent-bus"
```

Example for Samba mount on Linux:
```bash
export SHARED_ROOT="/mnt/host-share"
```

## Edge cases

- **Watcher offline**: requests pile up in `outbox/`. After timeout, surface this fact to the user. Suggest checking the watcher's status.
- **Partial result file**: if `result.json` is being written when the agent reads, JSON parse may fail. The script retries once after 500ms.
- **UUID collision**: extremely unlikely (uuid4) but the script appends an extra random suffix on collision detection.
- **Permission denied**: report the exact path that failed. Common cause: shared folder mounted read-only or wrong user.
- **Disk full on shared**: requests fail to write. The script falls back to printing the payload to stderr so the user can copy-paste manually.
- **No `uuidgen`**: falls back to `python3 -c "import uuid; print(uuid.uuid4())"`.
- **Cross-OS line endings**: result.json may contain CRLF if Windows watcher wrote it. Scripts strip CRLF before parsing.

## Output discipline

- `queue-send`: prints the UUID on stdout, nothing else. Errors to stderr.
- `queue-wait`: prints nothing on success (just exit 0). On timeout, exits with code 2 and prints a brief diagnosis.
- `queue-recv`: prints the result JSON pretty-printed. Exits 3 if not yet ready.
- `queue-list`: tabular summary, max 30 rows.

## Differentiation

- **MCP**: requires both ends to speak MCP. This skill works with any process that can read/write files, including legacy Windows tools, shell scripts, or native apps.
- **Message brokers** (RabbitMQ, Redis): heavy infrastructure. This skill needs zero deployment.
- **HTTP webhooks**: require the watcher to expose a public endpoint. This skill works behind NAT or on private networks.
- **Direct subprocess**: fails when the worker lives on a different machine or different user account.

## Limitations

- Latency floor ≈ filesystem polling interval (default 1 second on the watcher side, configurable).
- No ordering guarantees beyond filesystem timestamps (UUIDs are random).
- No built-in retry on the watcher side — that's the watcher's responsibility.
- Not suitable for high-throughput streams (use a real broker instead).
- Filesystem ACLs are the only access control; treat the shared folder as a trust boundary.
