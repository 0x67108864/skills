#!/bin/bash
# Block until result is ready, or timeout.
# Usage: queue-wait.sh <queue> <uuid> [--timeout SECONDS] [--interval SECONDS]
set -euo pipefail

SHARED_ROOT="${SHARED_ROOT:-/shared}"
QUEUE="${1:-}"
UUID="${2:-}"
shift 2 || true

TIMEOUT=300
INTERVAL=2
while [ $# -gt 0 ]; do
  case "$1" in
    --timeout)  TIMEOUT="$2"; shift 2 ;;
    --interval) INTERVAL="$2"; shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

if [ -z "$QUEUE" ] || [ -z "$UUID" ]; then
  echo "Usage: $0 <queue> <uuid> [--timeout S] [--interval S]" >&2
  exit 1
fi

RESULT_DIR="$SHARED_ROOT/inbox/$QUEUE/$UUID"
RESULT_FILE="$RESULT_DIR/result.json"
DEADLINE=$(($(date +%s) + TIMEOUT))

while [ "$(date +%s)" -lt "$DEADLINE" ]; do
  if [ -f "$RESULT_FILE" ]; then
    # Verify the file is fully written by attempting to parse JSON
    if jq . "$RESULT_FILE" >/dev/null 2>&1; then
      exit 0
    fi
    sleep 0.5
    if jq . "$RESULT_FILE" >/dev/null 2>&1; then
      exit 0
    fi
  fi
  sleep "$INTERVAL"
done

echo "Timeout after ${TIMEOUT}s waiting for $RESULT_FILE" >&2
echo "Hint: check that the watcher is running and the SHARED_ROOT path is correct on both sides." >&2
exit 2
