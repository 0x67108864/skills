#!/bin/bash
# Print the result JSON for a completed request.
# Usage: queue-recv.sh <queue> <uuid>
set -euo pipefail

SHARED_ROOT="${SHARED_ROOT:-/shared}"
QUEUE="${1:-}"
UUID="${2:-}"

if [ -z "$QUEUE" ] || [ -z "$UUID" ]; then
  echo "Usage: $0 <queue> <uuid>" >&2
  exit 1
fi

RESULT_FILE="$SHARED_ROOT/inbox/$QUEUE/$UUID/result.json"
if [ ! -f "$RESULT_FILE" ]; then
  echo "Result not ready: $RESULT_FILE" >&2
  exit 3
fi

# Strip CRLF if Windows watcher wrote it
tr -d '\r' < "$RESULT_FILE" | jq .
