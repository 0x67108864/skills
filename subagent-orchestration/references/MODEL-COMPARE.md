# Model comparison reference

Updated periodically. Last revised: 2026-05-05.

## Strengths matrix

| Capability | Claude (Opus 4.x) | Codex (GPT-5.x) | Gemini (3.x) |
|---|---|---|---|
| Long-form reasoning | ★★★ | ★★ | ★★ |
| Code editing precision (large repos) | ★★★ | ★★ | ★ |
| Web search (built-in) | ★ | ★★★ | ★★ |
| Context window | ~1M (with extension) | 200K | 1M+ |
| Multimodal (image/video/audio) | ★ (image only) | ★★ | ★★★ |
| Cost per 1M tokens (input, approx) | $$$ | $$ | $ |
| Refusal sensitivity | medium-high | low-medium | medium |
| JSON / structured output | ★★ | ★★★ | ★★ |
| Code review depth | ★★★ | ★★ | ★★ |
| Math / reasoning chains | ★★★ | ★★★ | ★★ |
| Speed (latency) | ★★ | ★★★ | ★★★ |

## Picking a model: cheat sheet

| Task | First choice | Fallback |
|---|---|---|
| PR review | Claude | Codex |
| Summarize a 500-page PDF | Gemini | Claude (with context extension) |
| "What happened this week in X" | Codex (web search) | Brave + any |
| Refactor a 5000-LOC file | Claude | Codex |
| Image OCR / image analysis | Gemini | Codex |
| Quick reformatting / type conversion | Gemini (cheap) | any |
| Sensitive code (auth, crypto) | Claude | careful manual review |
| Generate test cases | Codex | Claude |
| Translate between languages | Codex | Gemini |
| Brainstorm 20 alternatives | Codex | Gemini |

## Cost optimization

Rough rule of thumb at 2026-05:
- **Input** cost: Gemini < Codex < Claude
- **Output** cost: similar trend
- For pure summarization or rewording: prefer Gemini.
- For careful editing where re-runs are expensive: Claude (one-shot quality higher).
- For broad exploration (many short turns): Codex.

## CLI flags reference (used by `scripts/orch.sh`)

- **claude**: `claude --print --output-format text "<prompt>"` (non-interactive, plain text out).
- **codex**: `codex exec "<prompt>"` (non-interactive subcommand).
- **gemini**: `gemini -p "<prompt>"` (non-interactive headless mode).

When CLIs change flags, update both `scripts/orch.sh` and this file.
