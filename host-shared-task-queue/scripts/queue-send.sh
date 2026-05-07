#!/bin/bash
# Submit a request to the shared queue. Prints the UUID.
# Usage: queue-send.sh <queue-name> <json-payload>
set -euo pipefail

SHARED_ROOT="${SHARED_ROOT:-/shared}"
QUEUE="${1:-}"
PAYLOAD="${2:-}"

if [ -z "$QUEUE" ] || [ -z "$PAYLOAD" ]; then
  echo "Usage: $0 <queue-name> <json-payload>" >&2
  exit 1
fi

# Validate JSON
echo "$PAYLOAD" | jq . >/dev/null 2>&1 || { echo "Error: payload is not valid JSON" >&2; exit 1; }

OUTBOX="$SHARED_ROOT/outbox/$QUEUE"
mkdir -p "$OUTBOX" 2>/dev/null || { echo "Error: cannot create $OUTBOX (permission?)" >&2; exit 4; }

UUID="$(uuidgen 2>/dev/null || python3 -c 'import uuid; print(uuid.uuid4())')"
TARGET="$OUTBOX/$UUID.json"

# Avoid (very unlikely) collision
while [ -e "$TARGET" ]; do
  UUID="$UUID-$(printf '%04x' $RANDOM)"
  TARGET="$OUTBOX/$UUID.json"
done

# Inject request_id into payload, write atomically via temp + rename
TMP="$(mktemp "$OUTBOX/.$UUID.XXXXXX")"
echo "$PAYLOAD" | jq --arg id "$UUID" '. + {request_id: $id}' > "$TMP" || {
  rm -f "$TMP"
  echo "Error: failed to write payload" >&2
  echo "Payload was: $PAYLOAD" >&2
  exit 5
}
mv "$TMP" "$TARGET"

echo "$UUID"
