# host-shared-task-queue

A SKILL.md-format Agent Skill for coordinating an AI agent with an external worker process via a shared filesystem directory. No broker, no auth setup, no public endpoints — just files in a folder both sides can see.

## Use cases

- WSL agent ↔ Windows host (Samba share)
- Local agent ↔ remote worker (SyncThing, NFS, Dropbox)
- Multi-machine coordination (each machine has its own queue under one shared root)
- Driving Windows-only tools (yt-dlp, browser automation, GUI apps) from a Linux agent

## Install

```
host-shared-task-queue/
├── SKILL.md
├── README.md
└── scripts/
    ├── queue-send.sh
    ├── queue-wait.sh
    ├── queue-recv.sh
    ├── queue-list.sh
    └── queue-purge.sh
```

Drop into your agent's skills folder. Set `SHARED_ROOT` env var to your shared directory.

## Use

```bash
# Submit a request
UUID=$(./scripts/queue-send.sh research '{"topic": "foo"}')

# Wait for result
./scripts/queue-wait.sh research "$UUID" --timeout 180

# Read result
./scripts/queue-recv.sh research "$UUID"
```

## License

MIT (see SKILL.md frontmatter).

## Author

canola_oil — https://0x67108864.github.io/
