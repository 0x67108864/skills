# oss-bounty-hunter

A SKILL.md-format Agent Skill that discovers, evaluates, and prioritizes open-source coding bounties for AI coding agents (Claude Code, Codex CLI, Cursor, Gemini CLI, etc.).

## Install

Drop the `oss-bounty-hunter/` directory into your agent's skills folder. Locations vary by client:

- **Claude Code**: `~/.claude/skills/` or project-local `.claude/skills/`
- **Codex CLI**: `~/.codex/skills/`
- **Cursor**: per-project `.cursor/skills/`
- See your agent's docs for other clients.

## Use

Invoke with any of:

- "Find me OSS bounties this week"
- "What paid GitHub issues match my stack?"
- "Show open Algora bounties"
- "I want to earn from open source"

The skill will fetch live bounty data, filter out reserved/assigned bounties, score the rest by reward density, stack fit, and solvability, and present a shortlist with a recommended next step.

## What it covers

Currently:
- ✅ Algora (public tRPC endpoint)

Planned:
- 🔲 Replit Bounties
- 🔲 GitHub Sponsors-funded issues
- 🔲 Bountycaster (if API stabilizes)

## Compatibility

Requires `curl` and `jq` on the host machine. Works on any agent runtime supporting the agentskills.io SKILL.md format.

## License

MIT (see SKILL.md frontmatter).

## Author

canola_oil — https://0x67108864.github.io/
