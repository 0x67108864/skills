---
name: research-dispatcher
description: Route research queries across multiple public sources (Hacker News, Reddit, GitHub, web search) from a single declarative interface, with source-specific query optimization tips baked in. Use when the user wants to research a topic across multiple platforms, compare what different communities are saying, find OSS activity around a keyword, or systematically gather evidence before making a decision. Eliminates the need to remember each platform's query syntax, rate limits, and pitfalls.
license: MIT
compatibility: Requires curl, jq, and bash. Works with any agent runtime supporting agentskills.io. Reddit and HN access requires no auth; GitHub authenticated calls (5000/hr) need GITHUB_TOKEN env var, otherwise 60/hr unauthenticated.
metadata:
  author: canola_oil
  version: "0.1.0"
  homepage: "https://0x67108864.github.io/"
allowed-tools: Bash(curl:*) Bash(jq:*) Bash(./scripts/research:*) Read
---

# Research Dispatcher

Single-command research across HN, Reddit, GitHub, and web search. Each source has its own query syntax, rate limits, and "what to put in the search box" pitfalls. This skill encodes those once so the agent doesn't have to remember.

## When to use this skill

Activate when the user expresses any of:

- "Research X across HN, Reddit, GitHub"
- "What's the community saying about Y?"
- "Find me recent activity on Z"
- "Survey OSS projects related to W"
- "Compare what different platforms think of V"
- Any time multi-source synthesis would beat single-source search

Do *not* activate for:
- A single specific URL fetch (use `WebFetch` directly).
- Searches that require authentication beyond GitHub (e.g., LinkedIn, X/Twitter, internal Slack — those need different tools).

## Sources covered

| Source | Endpoint | Auth | Rate limit | Strength |
|---|---|---|---|---|
| Hacker News | `hn.algolia.com/api/v1/search` | none | 10K/hr | Tech news, deep technical discussion |
| Reddit | `reddit.com/r/<sub>/<sort>.json` | UA only | 60/min | Community sentiment, niche subreddits |
| GitHub Search | `api.github.com/search/repositories` | token recommended | 5000/hr (token) / 60/hr (anon) | OSS activity, code, issues |
| Brave Web Search | external (per-request) | API key | 2K/month free | General web, fresh content |

> Bluesky, YouTube, TikTok, X/Twitter and other "Route B"-style sources are *not* directly supported by this skill but can be wired up via a host queue (out of scope here).

## Procedure

### Default flow

1. **Parse user intent** to determine sources to hit. If the user says "broad survey", default to HN + Reddit + GitHub. If they say "what's trending in `<community>`", lean Reddit. If "recent OSS work on X", lean GitHub.
2. **Run the dispatcher** with one command:
   ```bash
   ./scripts/research.sh "<topic>" --sources hn,reddit,github
   ```
3. **Aggregate results** into a single Markdown summary, deduplicating identical URLs across sources.
4. **Surface signals**: top stories by score, recent commits, recurring themes.
5. **Recommend follow-up** sources or queries if the initial sweep was thin.

### Source-specific query tips (highlights)

See `references/SOURCES.md` for the full guide. Key tips:

- **HN**: spaces are AND. Use `&numericFilters=created_at_i>UNIX_TS` for date range. Topics like "AI safety" hit better than "AI regulation" on HN.
- **Reddit**: full-text search is weak; subreddit + `/hot.json` or `/top.json?t=week` gives better signal than `/search`. Always send a User-Agent header.
- **GitHub**: use qualifiers — `topic:llm stars:>200 pushed:>2026-04-01`. `topic:` is far stronger than free-text.
- **Brave**: `freshness=pm` for last month. Site-specific narrowing with `site:` operator. Watch the 2K/month free quota.

### Choosing sources

```
+-------------------+-------------------+-------------------+
|     User wants    | Primary sources   |   Skip            |
+-------------------+-------------------+-------------------+
| Tech trends       | HN, Reddit        | GitHub (too noisy)|
| OSS activity      | GitHub, HN        | Reddit            |
| Community vibes   | Reddit            | HN, GitHub        |
| Breaking news     | HN, Brave         | GitHub            |
| Niche topic       | Reddit, Brave     | HN (sparse)       |
+-------------------+-------------------+-------------------+
```

## Edge cases

- **Zero results**: surface the actual `query_sent` to each source so the user can see why. Suggest: shorter query, OR-joined synonyms, longer time window.
- **Rate-limited**: Reddit may return 429 with no User-Agent. The script always sends one, but if you see 429, wait 60s and retry.
- **GitHub anon hit 60/hr**: switch to authenticated mode by exporting `GITHUB_TOKEN` (a fine-grained PAT with `public_repo` is enough).
- **Brave quota exhausted**: skill should warn at 80% (1600/2000) and refuse at 100%. Fall back to other sources.
- **API JSON shape changes**: each parser is a few lines of `jq`. If a source breaks, update `scripts/research.sh` minimally.

## Output format

Return a single Markdown response with:

1. One-line query summary
2. Per-source bullet list of top 5 hits (title, score, URL, 1-line preview)
3. Cross-source themes (if any obvious overlap)
4. A "what's missing" note if a source returned 0 hits or was skipped

## Differentiation

- **Generic web search** (Brave, Google) misses community context. This skill brings HN/Reddit ranks into one view.
- **Single-source agents** (e.g. an HN-only summarizer) don't compare. This skill uses the *contrast* between sources as a signal.
- **Manual multi-tab research**: the goal of this skill is to replace 30 minutes of tab-switching with a single command.

## Limitations

- No paywall content, no logged-in views (e.g. private subreddits, X/Twitter feeds).
- No real-time / WebSocket subscriptions.
- Score interpretation is naive — high HN score doesn't mean correct, just popular.
- Reddit `/search` is genuinely poor; subreddit + sort is the workaround but requires knowing relevant subreddits.
