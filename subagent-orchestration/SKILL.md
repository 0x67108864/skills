---
name: subagent-orchestration
description: Route a coding or research task to the most cost-effective subagent — Claude, Codex (ChatGPT), or Gemini — based on the task's strengths-fit and current rate-limit status. Use when the user wants to delegate part of a workflow to a different model, run the same query across multiple models for cross-check, optimize spend by sending lightweight tasks to cheaper models, or break free from a single agent's blind spots. Assumes the user has CLI access to at least two of `claude`, `codex`, and `gemini`.
license: MIT
compatibility: Requires at least one of `codex`, `gemini`, or `claude` CLIs in PATH. Multi-agent routing requires all three. Tested with Codex CLI v0.x and Gemini CLI v0.x.
metadata:
  author: canola_oil
  version: "0.1.0"
  homepage: "https://0x67108864.github.io/"
allowed-tools: Bash(codex:*) Bash(gemini:*) Bash(claude:*) Read
---

# Subagent Orchestration

Delegate a task to a different model than the one currently driving the session, then return the result to the caller.

## When to use this skill

Activate when the user expresses any of:

- "Send this to Codex / Gemini / Claude as a second opinion"
- "Run this query across all three and compare"
- "Use a cheaper model for this part"
- "I'm rate-limited on Claude — use Gemini for now"
- "Spawn a subagent for this side task"
- Any reference to **multi-model**, **second opinion**, **subagent**, or **cost optimization across models**

Do *not* activate when:
- The user has only one agent CLI installed.
- The task requires interactive multi-turn (subagent runs are non-interactive).

## Model strengths reference

| Model | Strengths | Avoid for |
|---|---|---|
| **Claude (Opus / Sonnet / Haiku)** | Long-form reasoning, safety-conscious tasks, careful code editing, structured analysis | Tasks requiring fresh web data without explicit web search tool |
| **Codex (GPT-4.x / 5.x)** | Web search integration, broad multilingual, fast turnarounds | Subtle code edits in large repos (over-confident on local context) |
| **Gemini (1.5 / 2 / 3)** | Very large context windows (1M+), multimodal (images, video), low cost per token | Complex multi-step coding (less precise diffs) |

## Routing rules

The skill picks a model based on task signals:

```
+-----------------------------+----------+
| Signal                      |  Model   |
+-----------------------------+----------+
| "research", "what's new"    | Codex    |
| "summarize this 500-page"   | Gemini   |
| "review this PR carefully"  | Claude   |
| "describe this image"       | Gemini   |
| "second opinion on plan X"  | round-robin (caller's preferred order) |
+-----------------------------+----------+
```

Override: user can say "force gemini" / "use codex" — explicit always wins.

## Procedure

### Single-model delegation

```bash
./scripts/orch.sh --model gemini --prompt "Summarize the attached file in 5 bullets" --file ./report.pdf
./scripts/orch.sh --model codex --prompt "What's the latest on the OpenAI API rate-limit changes?"
```

### Cross-check (run on all three)

```bash
./scripts/orch.sh --crosscheck --prompt "Is this SQL injection-safe? <code>"
```

Returns a 3-column table: each model's answer side-by-side.

### Cost-aware routing

```bash
./scripts/orch.sh --auto --prompt "Reformat this CSV" --budget low
```

`--budget low` prefers Gemini, `--budget high` prefers Claude Opus. Default is `--budget medium`.

## Edge cases

- **CLI not installed**: detect at startup, list available models, pick from those. If none available, return an explicit error with install hints.
- **Rate-limited**: if a model returns a 429-equivalent, try the next preferred model. Cache the rate-limit state for 5 minutes to avoid retrying.
- **Token cap exceeded**: if a long prompt would blow the context window of one model, automatically route to the largest-context model (Gemini for >200K tokens).
- **Same prompt, different formats**: each CLI has its own arg syntax. The skill normalizes these into one interface.
- **Cost-tracking**: write a one-line audit log to `~/.cache/subagent-orch/log.jsonl` per call (timestamp, model, approximate token count if available).

## Output format

Single-model: print the model's response verbatim, prefixed with `[<model>]:` on the first line.

Crosscheck: a Markdown table with columns `claude | codex | gemini`, each cell showing the response (truncated to 80 chars if very long, with a note about the truncation).

## Differentiation

- **Claude Code's Agent tool** can spawn sub-Claudes but not other vendors. This skill bridges across vendors.
- **OpenRouter / LiteLLM** route at the API layer; this skill routes at the **CLI layer**, using each vendor's official CLI which handles auth, billing, and rate limits transparently.
- **Manual model-switching** by the user is annoying; this skill automates it based on task type.

## Limitations

- Auth is per-CLI (each model needs its own login on the host).
- No streaming aggregation — calls are blocking.
- The "auto" routing rule is heuristic, not learned; user is encouraged to override when wrong.
- Token counting is approximate (each CLI exposes different metrics).
