#!/bin/bash
# List pending and recent results for a queue.
# Usage: queue-list.sh <queue>
set -euo pipefail

SHARED_ROOT="${SHARED_ROOT:-/shared}"
QUEUE="${1:-}"

if [ -z "$QUEUE" ]; then
  echo "Usage: $0 <queue>" >&2
  exit 1
fi

OUTBOX="$SHARED_ROOT/outbox/$QUEUE"
INBOX="$SHARED_ROOT/inbox/$QUEUE"

echo "=== Pending (outbox) ==="
if [ -d "$OUTBOX" ]; then
  find "$OUTBOX" -maxdepth 1 -name '*.json' -type f -printf "%T@ %f\n" 2>/dev/null |
    sort -rn | head -30 |
    awk '{ ts=$1; sub(/^[0-9.]+ /,""); cmd="date -d @"int(ts)" -Iseconds 2>/dev/null"; cmd | getline t; close(cmd); printf "  %s  %s\n", t, $0 }'
else
  echo "  (no outbox dir)"
fi
echo

echo "=== Completed (inbox) ==="
if [ -d "$INBOX" ]; then
  find "$INBOX" -maxdepth 2 -name 'result.json' -type f -printf "%T@ %h\n" 2>/dev/null |
    sort -rn | head -30 |
    awk '{ ts=$1; sub(/^[0-9.]+ /,""); n=split($0,p,"/"); uid=p[n]; cmd="date -d @"int(ts)" -Iseconds 2>/dev/null"; cmd | getline t; close(cmd); printf "  %s  %s\n", t, uid }'
else
  echo "  (no inbox dir)"
fi
