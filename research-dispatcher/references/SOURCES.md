# Source-by-source query guide

## Hacker News (Algolia)

Endpoint: `https://hn.algolia.com/api/v1/search`

Best for: tech news, dev culture, "Show HN" launches, deep technical discussion.

Query syntax:
- Spaces between terms = AND.
- `tags=story` to filter to story posts (skip comments).
- `tags=story,front_page` to limit to front-page stories.
- `numericFilters=created_at_i>UNIX_TS` for date filtering (UNIX timestamp).
- Surround a phrase in quotes (URL-encoded `%22`) for exact match.

Pitfalls:
- "AI regulation" → low signal. Try "AI safety" or "AI governance" — HN's lexicon.
- "tariff", "export controls" — sparse; better on Brave.
- Pagination: `&page=N`, max ~10 pages.

Example:
```
curl -s "https://hn.algolia.com/api/v1/search?query=mcp+server&tags=story&hitsPerPage=20"
```

## Reddit

Endpoint: `https://www.reddit.com/r/<sub>/<sort>.json`

Best for: community sentiment, niche subreddits, real-time vibes.

Query patterns:
- `r/<sub>/hot.json?limit=25` — current hot.
- `r/<sub>/top.json?t=week&limit=25` — top of week (also `day`, `month`, `year`).
- `r/<sub>/new.json` — chronological.
- Cross-sub search: `https://reddit.com/search.json?q=<terms>` — works but signal is weak.

Pitfalls:
- 403/429 if no User-Agent. Always send one.
- Score doesn't equal quality — viral memes outrank thoughtful posts.
- Some subs are private or quarantined; handle 403 gracefully.

Subreddits worth knowing:
- Tech: `r/programming`, `r/MachineLearning`, `r/LocalLLaMA`, `r/SaaS`, `r/indiehackers`
- AI agents: `r/ClaudeAI`, `r/ClaudeCode`, `r/ChatGPTPro`, `r/AI_Agents`, `r/AgentsOfAI`
- Side hustle: `r/sidehustle`, `r/freelance`, `r/passive_income`

## GitHub Search

Endpoint: `https://api.github.com/search/repositories`, `/search/issues`, `/search/code`.

Best for: OSS activity, language trends, finding maintained projects.

Query syntax:
- `topic:<topic>` — strongest filter.
- `language:typescript stars:>200 pushed:>2026-04-01` — multiple qualifiers.
- `archived:false` — exclude dead repos.
- Sort: `sort=updated`, `sort=stars`.

Pitfalls:
- Anonymous: 60 req/hr. Use `Authorization: Bearer <PAT>` for 5000/hr.
- Free-text without qualifiers returns noise.
- `pushed:` is more current than `created:` for "active" detection.

Example:
```
curl -s -H "Authorization: Bearer $GITHUB_TOKEN" \
  "https://api.github.com/search/repositories?q=topic:agent-skills+pushed:>2026-04-01&sort=updated&per_page=20"
```

## Brave Web Search

Endpoint: external API (requires API key + per-request budget).

Best for: general web, fresh non-tech content, geographic/language filtering.

Query patterns:
- `freshness=pm` (past month), `pw` (past week), `pd` (past day).
- `site:reuters.com` to narrow.
- `country=jp` for Japan-localized.

Pitfalls:
- 2K/month free quota — easy to burn through.
- Max 20 results per request.
- No semantic matching — keyword-driven.

Quota policy:
- Warn user at 80% (1600 calls).
- Hard refuse at 100%.
- Track usage in `~/.cache/research-dispatcher/brave-quota.json`.

## Skipped sources (out of scope)

- **Bluesky**: needs API access via separate watcher (not built into this skill).
- **YouTube / TikTok**: needs platform-specific tooling (yt-dlp, scraper services).
- **X/Twitter**: requires logged-in session; skip.
- **LinkedIn**: scraping forbidden; skip.
- **Specialized**: arXiv, Polymarket, Stack Overflow — possible additions but not in v0.1.

## Adding a new source (future)

1. Add an entry to the source table in `SKILL.md`.
2. Implement a parser function in `scripts/research.sh` named `query_<source>()`.
3. Document tips here.
4. Bump the skill version in `SKILL.md` frontmatter.
