---
name: oss-bounty-hunter
description: Discover, evaluate, and prioritize open-source coding bounties from Algora and similar platforms. Use when the user asks about paid open-source contribution opportunities, OSS bounties, monetizing GitHub work, or finding side income via code work. Filters bounties by tech stack, reward range, and reservation status, and surfaces the highest-fit candidates.
license: MIT
compatibility: Requires curl and jq. Works with Claude Code, Codex CLI, Cursor, Gemini CLI, and other agent runtimes that support the agentskills.io standard.
metadata:
  author: canola_oil
  version: "0.1.0"
  homepage: "https://0x67108864.github.io/"
allowed-tools: Bash(curl:*) Bash(jq:*) Read
---

# OSS Bounty Hunter

Surface paid open-source coding tasks (bounties) from public bounty platforms, filter for fit, and propose a shortlist the user can act on.

## When to use this skill

Activate when the user expresses any of:

- "I want to earn money working on open source"
- "Find me OSS bounties / paid issues / GitHub bounties"
- "What can I work on for cash this week"
- "Show me bounties matching my stack"
- "Side income through coding"
- Any reference to **Algora**, **Replit Bounties**, **Bountysource**, **Gitcoin bounties**, or **bounty platforms**

Do *not* activate for unrelated GitHub queries (issue triage, repo audit, etc.).

## Procedure

1. **Fetch the latest open bounties**:
   ```bash
   ./scripts/algora-watch.sh --summary
   ```
   This calls the Algora public tRPC endpoint and prints `[status] $reward title / org / type / kind / url` lines.

2. **Triage each bounty** for two disqualifiers:
   - **Reservation**: many bounties carry an `Reserved for SE interview` label or already have an `assignee` and a linked PR. These are effectively closed to community contributors. Skip them unless the user explicitly opts in.
   - **Out-of-scope tech**: the user's primary stack should appear in the linked GitHub issue (language, framework, or domain). When unknown, ask the user once for their stack.

3. **Score the survivors** on three axes (1–5 each, 5 is best):
   - **Reward density**: `reward / estimated hours of work`. Use the issue body length, file count touched, and "complexity" labels as a rough proxy.
   - **Stack fit**: how well the issue matches the user's known stack and prior PRs.
   - **Solvability signal**: whether the issue has a clear acceptance criterion, a recent comment from a maintainer, and no blocking dependencies.

4. **Present a shortlist** of the top 3–5 bounties as a Markdown table:
   | rank | reward | title | url | reserved? | score | one-line rationale |

5. **Recommend a starting point**: name the single best bounty for the user to take next, with a brief plan ("clone, look at file X, run test Y").

6. **Optional follow-ups**:
   - If asked, fetch the linked GitHub issue and extract acceptance criteria, file hints, and existing PRs.
   - If asked, draft a comment for the user to post on the issue claiming the bounty.

## Filter by reward range

If the user gives a minimum reward (e.g. "at least $200"), pipe through:
```bash
./scripts/algora-watch.sh --filter "." | awk '/\$[0-9]+/ {if (match($0, /\$([0-9]+)/, m) && m[1]+0 >= 200) print}'
```

## Edge cases

- **All bounties reserved**: report this fact explicitly. Do not pretend a reserved bounty is openly takeable. Suggest re-running later or trying alternative platforms.
- **Single org dominates** (e.g. one company has 9 of 10 bounties): mention this — it skews available work and may indicate a paid-interview pipeline rather than open community contribution.
- **API returns empty**: Algora's tRPC endpoint occasionally returns no data on errors. Show the raw response and ask the user to retry.
- **User has no GitHub auth set up**: discovering bounties does not require authentication, but solving them does. Mention that taking a bounty will require GitHub auth (`gh auth login` or equivalent).

## Tech stack heuristic (fallback)

If the user's stack is unknown and they don't answer:

- Treat **TypeScript**, **Python**, **Go**, **Rust** as default in-scope.
- Treat **C++**, **embedded**, **kernel**, **specialized cryptography** as out-of-scope unless the user opts in.

## Output format

Always return:

1. A one-line summary of the bounty market right now (e.g. "Algora has 10 open bounties totalling $9,080, but 8 are reserved for hiring; only 2 are openly takeable.").
2. The shortlist table (rank/reward/title/url/reserved/score/rationale).
3. The single recommended next step.
4. A note on what platforms were *not* checked (e.g. Replit Bounties not yet integrated) so the user knows the coverage.

Keep the entire response under 60 lines unless the user asks for full detail.

## Limitations

- Currently covers **Algora only**. Replit Bounties, Bountysource (status uncertain), and Gitcoin (crypto-only) are not yet integrated. Future versions may add them.
- The tRPC endpoint used is public but unofficial; if Algora changes it, this skill must be updated.
- Scoring is heuristic and depends on the agent's reasoning, not a fixed algorithm.
