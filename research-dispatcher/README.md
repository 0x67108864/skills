# research-dispatcher

A SKILL.md-format Agent Skill that routes a single research query across HN, Reddit, GitHub, and Brave Web Search, with source-specific query optimization baked in.

## Install

Drop the `research-dispatcher/` directory into your agent's skills folder:

- Claude Code: `~/.claude/skills/`
- Codex CLI: `~/.codex/skills/`
- Cursor: `.cursor/skills/`

## Use

Invoke with:

- "Research <topic> across HN, Reddit, GitHub"
- "What's the community saying about <X>?"
- "Survey recent OSS work on <Y>"

The skill picks sources based on intent, runs queries with appropriate syntax, deduplicates by URL, and returns a Markdown summary.

## Optional configuration

- `GITHUB_TOKEN`: increases GitHub rate limit from 60/hr to 5000/hr
- `BRAVE_API_KEY`: enables Brave Web Search (otherwise skipped)

## Compatibility

Works on any agentskills.io-compatible runtime. Requires `curl`, `jq`, `python3`, and `bash`.

## License

MIT (see SKILL.md frontmatter).

## Author

canola_oil — https://0x67108864.github.io/
