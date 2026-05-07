#!/bin/bash
# Remove old completed entries from inbox.
# Usage: queue-purge.sh <queue> [--older-than 7d]
set -euo pipefail

SHARED_ROOT="${SHARED_ROOT:-/shared}"
QUEUE="${1:-}"
shift || true

OLDER_THAN="7"  # days
while [ $# -gt 0 ]; do
  case "$1" in
    --older-than)
      v="$2"
      OLDER_THAN="${v%[dD]}"
      shift 2
      ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

if [ -z "$QUEUE" ]; then
  echo "Usage: $0 <queue> [--older-than Nd]" >&2
  exit 1
fi

INBOX="$SHARED_ROOT/inbox/$QUEUE"
if [ ! -d "$INBOX" ]; then
  echo "(no inbox dir for queue $QUEUE)" >&2
  exit 0
fi

BEFORE=$(find "$INBOX" -maxdepth 1 -mindepth 1 -type d | wc -l)
find "$INBOX" -maxdepth 1 -mindepth 1 -type d -mtime "+${OLDER_THAN}" -print0 |
  while IFS= read -r -d '' d; do
    rm -rf "$d"
    echo "Removed: $(basename "$d")"
  done
AFTER=$(find "$INBOX" -maxdepth 1 -mindepth 1 -type d | wc -l)

echo "Purged $((BEFORE - AFTER)) entries older than ${OLDER_THAN} days. ${AFTER} remaining."
