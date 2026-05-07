#!/bin/bash
# Research dispatcher: query HN / Reddit / GitHub / Brave with one command.
# Usage:
#   ./research.sh "<query>" --sources hn,reddit,github [--limit N] [--since-days N]
set -euo pipefail

UA="research-dispatcher/0.1"
QUERY=""
SOURCES="hn,reddit,github"
LIMIT=10
SINCE_DAYS=30

while [ $# -gt 0 ]; do
  case "$1" in
    --sources)    SOURCES="$2"; shift 2 ;;
    --limit)      LIMIT="$2"; shift 2 ;;
    --since-days) SINCE_DAYS="$2"; shift 2 ;;
    -*)           echo "Unknown arg: $1" >&2; exit 1 ;;
    *)            QUERY="$1"; shift ;;
  esac
done

if [ -z "$QUERY" ]; then
  echo "Usage: $0 '<query>' [--sources hn,reddit,github,brave] [--limit N] [--since-days N]" >&2
  exit 1
fi

UNIX_SINCE=$(($(date +%s) - SINCE_DAYS * 86400))
ENC_QUERY=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$QUERY")

query_hn() {
  echo "## Hacker News"
  # URL-encode the > in numericFilters (Algolia rejects raw >)
  curl -s "https://hn.algolia.com/api/v1/search?query=${ENC_QUERY}&tags=story&hitsPerPage=${LIMIT}&numericFilters=created_at_i%3E${UNIX_SINCE}" |
    jq -r ".hits[] | \"- [\(.points // 0)pts|\(.num_comments // 0)c] \(.title // \"\") <\(.url // \"https://news.ycombinator.com/item?id=\(.objectID)\")>\""
  echo
}

query_reddit() {
  echo "## Reddit"
  # Cross-sub search via reddit.com/search.json
  curl -sA "$UA" "https://www.reddit.com/search.json?q=${ENC_QUERY}&limit=${LIMIT}&sort=relevance&t=month" |
    jq -r ".data.children[]?.data | \"- [\(.score)pts|\(.num_comments)c] r/\(.subreddit) — \(.title) <\(.url)>\""
  echo
}

query_github() {
  echo "## GitHub"
  AUTH=()
  [ -n "${GITHUB_TOKEN:-}" ] && AUTH=(-H "Authorization: Bearer $GITHUB_TOKEN")
  PUSHED=$(date -d "@$UNIX_SINCE" +%Y-%m-%d 2>/dev/null || date -r "$UNIX_SINCE" +%Y-%m-%d)
  # URL-encode the > in pushed: qualifier (GitHub accepts raw > but URL-encoded is safer)
  curl -s "${AUTH[@]}" "https://api.github.com/search/repositories?q=${ENC_QUERY}+pushed:%3E${PUSHED}&sort=updated&per_page=${LIMIT}" |
    jq -r ".items[]? | \"- [⭐\(.stargazers_count)] \(.full_name) — \(.description // \"\") <\(.html_url)>\""
  echo
}

query_brave() {
  echo "## Brave Web Search"
  if [ -z "${BRAVE_API_KEY:-}" ]; then
    echo "(skipped: BRAVE_API_KEY not set)"
    return
  fi
  curl -s -H "X-Subscription-Token: $BRAVE_API_KEY" \
    "https://api.search.brave.com/res/v1/web/search?q=${ENC_QUERY}&count=${LIMIT}&freshness=pm" |
    jq -r ".web.results[]? | \"- \(.title) <\(.url)>\n  \(.description // \"\")\""
  echo
}

echo "# Research: $QUERY"
echo "(window: last ${SINCE_DAYS} days)"
echo

IFS=',' read -ra SRC_ARR <<< "$SOURCES"
for s in "${SRC_ARR[@]}"; do
  case "$s" in
    hn|hackernews) query_hn ;;
    reddit)        query_reddit ;;
    github|gh)     query_github ;;
    brave)         query_brave ;;
    *)             echo "## $s\n(unknown source)" ;;
  esac
done
