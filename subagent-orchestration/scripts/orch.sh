#!/bin/bash
# Subagent orchestrator: delegate a prompt to claude / codex / gemini.
# Usage:
#   ./orch.sh --model codex --prompt "..."
#   ./orch.sh --crosscheck --prompt "..."
#   ./orch.sh --auto --budget low --prompt "..."
set -euo pipefail

MODEL=""
PROMPT=""
FILE=""
CROSSCHECK=0
AUTO=0
BUDGET="medium"

while [ $# -gt 0 ]; do
  case "$1" in
    --model)      MODEL="$2"; shift 2 ;;
    --prompt)     PROMPT="$2"; shift 2 ;;
    --file)       FILE="$2"; shift 2 ;;
    --crosscheck) CROSSCHECK=1; shift ;;
    --auto)       AUTO=1; shift ;;
    --budget)     BUDGET="$2"; shift 2 ;;
    *)            echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

if [ -z "$PROMPT" ]; then
  echo "Error: --prompt required" >&2
  exit 1
fi

# Detect available CLIs
HAVE_CLAUDE=0; command -v claude  >/dev/null 2>&1 && HAVE_CLAUDE=1
HAVE_CODEX=0;  command -v codex   >/dev/null 2>&1 && HAVE_CODEX=1
HAVE_GEMINI=0; command -v gemini  >/dev/null 2>&1 && HAVE_GEMINI=1

if [ "$((HAVE_CLAUDE + HAVE_CODEX + HAVE_GEMINI))" -eq 0 ]; then
  echo "Error: no agent CLIs found. Install at least one of: claude, codex, gemini." >&2
  exit 2
fi

# Auto-routing rules
if [ "$AUTO" -eq 1 ] && [ -z "$MODEL" ]; then
  case "$BUDGET" in
    low)
      [ "$HAVE_GEMINI" -eq 1 ] && MODEL=gemini || MODEL=codex
      ;;
    high)
      [ "$HAVE_CLAUDE" -eq 1 ] && MODEL=claude || MODEL=codex
      ;;
    *)
      # medium — pick by prompt content heuristic
      lower=$(echo "$PROMPT" | tr '[:upper:]' '[:lower:]')
      if echo "$lower" | grep -qE 'summari[sz]e|long|500.page|huge|large file'; then
        [ "$HAVE_GEMINI" -eq 1 ] && MODEL=gemini || MODEL=claude
      elif echo "$lower" | grep -qE "what.s new|latest|2026|recent news|search"; then
        [ "$HAVE_CODEX" -eq 1 ] && MODEL=codex || MODEL=gemini
      elif echo "$lower" | grep -qE 'review|audit|safe|carefull?y|pr review'; then
        [ "$HAVE_CLAUDE" -eq 1 ] && MODEL=claude || MODEL=codex
      else
        # default: prefer claude > codex > gemini
        [ "$HAVE_CLAUDE" -eq 1 ] && MODEL=claude || ([ "$HAVE_CODEX" -eq 1 ] && MODEL=codex || MODEL=gemini)
      fi
      ;;
  esac
fi

# Single-model dispatch
run_model() {
  local m="$1"
  case "$m" in
    claude)
      if [ "$HAVE_CLAUDE" -eq 0 ]; then echo "[claude] not installed"; return; fi
      echo "[claude]:"
      claude --print --output-format text "$PROMPT" 2>&1 | sed 's/^/  /'
      ;;
    codex)
      if [ "$HAVE_CODEX" -eq 0 ]; then echo "[codex] not installed"; return; fi
      echo "[codex]:"
      codex exec "$PROMPT" 2>&1 | sed 's/^/  /'
      ;;
    gemini)
      if [ "$HAVE_GEMINI" -eq 0 ]; then echo "[gemini] not installed"; return; fi
      echo "[gemini]:"
      gemini -p "$PROMPT" 2>&1 | sed 's/^/  /'
      ;;
    *)
      echo "Unknown model: $m" >&2; return 1
      ;;
  esac
}

# Audit log helper
log_call() {
  local m="$1"
  mkdir -p "$HOME/.cache/subagent-orch"
  printf '{"ts":"%s","model":"%s","prompt_len":%d}\n' \
    "$(date -Iseconds)" "$m" "${#PROMPT}" >> "$HOME/.cache/subagent-orch/log.jsonl"
}

if [ "$CROSSCHECK" -eq 1 ]; then
  for m in claude codex gemini; do
    log_call "$m"
    run_model "$m"
    echo
  done
else
  if [ -z "$MODEL" ]; then
    echo "Error: --model required (or use --auto / --crosscheck)" >&2
    exit 1
  fi
  log_call "$MODEL"
  run_model "$MODEL"
fi
