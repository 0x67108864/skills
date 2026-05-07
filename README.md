# canola_oil — agent skills

Open & paid AI agent skills in the [agentskills.io](https://agentskills.io) `SKILL.md` format. Compatible with Claude Code, Codex CLI, Cursor, Gemini CLI, OpenHands, and any other runtime that supports the open Agent Skills standard.

## Skills

| Skill | What it does | Price |
|---|---|---|
| [persistent-kb](./persistent-kb) | Cross-session memory — local SQLite knowledge base, Python stdlib only | $9 one-time / $3 month |
| [research-dispatcher](./research-dispatcher) | Multi-source research: route a query to HN, Reddit, GitHub, and Brave web search | $12 one-time / $5 month |
| [oss-bounty-hunter](./oss-bounty-hunter) | Discover and prioritize open-source bounties matching your stack | $7 one-time |
| [subagent-orchestration](./subagent-orchestration) | Route tasks to Claude / Codex / Gemini based on strengths-fit and budget | $15 one-time |
| [host-shared-task-queue](./host-shared-task-queue) | Async task queue between agent and worker via shared filesystem | $9 one-time |

## Install

Each skill is a self-contained directory with `SKILL.md`, `scripts/`, and (optionally) `README.md` and `references/`.

Drop the relevant directory into your agent's skills folder:

| Agent | Default skill folder |
|---|---|
| Claude Code | `~/.claude/skills/` |
| Codex CLI | `~/.codex/skills/` |
| Gemini CLI | `~/.gemini/skills/` |
| Cursor | `<project>/.cursor/skills/` |

Or install via marketplace:
- **Agensi**: https://agensi.io
- **LobeHub**: `npx -y @lobehub/market-cli skills install <slug> --agent <runtime>`

## Validation

All skills are validated against the official `agentskills.io` specification using the `skills-ref` reference library. Each skill's directory is `Valid skill` confirmed.

## License

Each skill carries its own license declared in its SKILL.md frontmatter. Most are MIT.

## Author

canola_oil — https://0x67108864.github.io/

Independent developer based in Japan. Free skills are released under permissive licenses on this repo. Paid skills are distributed via the marketplaces listed above.
