# subagent-orchestration

A SKILL.md-format Agent Skill that **routes a task to the right LLM** — Claude, Codex (ChatGPT), or Gemini — based on the task's strengths-fit, your budget, and current rate-limit status.

## Why this skill exists

Each major model has different strengths: Claude for careful code review, Codex for web-aware research, Gemini for million-token contexts and multimodal. Single-model agents miss the chance to delegate. This skill bridges across vendor CLIs from one entry point.

## What it does

- **Single-model dispatch**: send a prompt to a specific model.
- **Cross-check**: run the same prompt across all three and present a side-by-side table.
- **Auto-routing**: pick a model based on prompt content and budget hints.
- **Fallback**: if a model is unavailable or rate-limited, try the next preferred.
- **Audit log**: each call logged to `~/.cache/subagent-orch/log.jsonl`.

## When to use this skill

The agent should activate when the user says any of:

- "Send this to Codex / Gemini / Claude as a second opinion"
- "Run this across all three and compare"
- "Use a cheaper model for this part"
- "I'm rate-limited on Claude — use Gemini for now"
- "Spawn a subagent for this side task"

## Compatibility

- Bash 4+, with at least one of `claude`, `codex`, `gemini` CLIs in PATH.
- Cross-check and auto-routing work best with all three CLIs available.
- Each CLI handles its own auth — log in to each before using.

## Install

Drop the `subagent-orchestration/` directory into your agent's skills folder.

CLI install hints:
- **Claude Code**: https://claude.com/claude-code
- **Codex CLI**: https://developers.openai.com/codex
- **Gemini CLI**: https://geminicli.com

## Quickstart

```bash
# Single-model
./scripts/orch.sh --model gemini --prompt "Summarize the attached file"

# Cross-check
./scripts/orch.sh --crosscheck --prompt "Is this SQL injection-safe? <code>"

# Cost-aware auto-route
./scripts/orch.sh --auto --budget low --prompt "Reformat this CSV"
```

## Routing rules (default)

| Prompt content signal | Model picked |
|---|---|
| "summarize", "long", "huge" | Gemini (large context) |
| "what's new", "latest", "search" | Codex (web-aware) |
| "review", "audit", "carefully" | Claude (precision) |
| Default | Claude → Codex → Gemini (preference order) |

Override with explicit `--model` always wins.

## Roadmap

- v0.2: per-call token / cost estimation in the audit log.
- v0.3: streaming aggregation for cross-check (currently blocking).
- v0.4: learned routing based on user feedback.

## License

MIT (see SKILL.md frontmatter).

## Author

canola_oil — https://0x67108864.github.io/
