#!/bin/bash
# Algora bounty 観測スクリプト
# 2026-05-04 確立 (ws_selfserviceupdate)
#
# 使い方:
#   ./algora-watch.sh                  # open bounty 全件を JSON で取得
#   ./algora-watch.sh --summary         # 表形式サマリ
#   ./algora-watch.sh --filter <regex>  # title regex でフィルタ
#
# API: https://console.algora.io/api/trpc/bounty.list (tRPC, 認証不要)
# Public 確認済み: 2026-05-04

set -euo pipefail

API="https://console.algora.io/api/trpc/bounty.list"
UA="agentvm-research/1.0"
RAW=$(mktemp)
trap 'rm -f "$RAW"' EXIT

curl -fsSL -A "$UA" "$API" -o "$RAW"

case "${1:-}" in
  --summary)
    jq -r '.[0].result.data.json.items[] |
      "[\(.status)] $\((.reward.amount // 0)/100 | floor) \(.reward.currency // "USD")  \(.task.title // "(no title)")\n  org: \(.org.display_name // "(none)")  type: \(.type) kind: \(.kind)\n  url: \(.task.url // "")\n"' "$RAW"
    ;;
  --filter)
    REGEX="${2:-}"
    jq -r --arg r "$REGEX" '.[0].result.data.json.items[] |
      select((.task.title // "") | test($r; "i")) |
      "[\(.status)] $\((.reward.amount // 0)/100 | floor)  \(.task.title)\n  url: \(.task.url // "")\n"' "$RAW"
    ;;
  *)
    cat "$RAW"
    ;;
esac
