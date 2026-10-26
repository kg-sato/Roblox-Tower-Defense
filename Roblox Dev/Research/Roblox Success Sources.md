# Roblox Success Sources

Researched 2026-10-24. Only official Roblox docs and the DevForum were read in full. Third-party tools are marked as such. Search results from blogs and PDF mirrors were mostly spam and are **not** listed.

Related: [[Game Design Doc]], [[Systems]], [[Backlog]], [[Analytics/Analytics Log|Analytics Log]]

## 1. What decides success: discovery and retention

Source: [Discovery](https://create.roblox.com/docs/production/promotion/discovery) and the DevForum post [Boost Your Discovery by Building Games People Want to Play](https://devforum.roblox.com/t/boost-your-discovery-by-building-games-people-want-to-play/4779042).

Signals Home recommendations use, most important first:
- **Play-through rate**: how often people play after seeing your game.
- **First-play bounce rate** (bad): players leaving in under 60 s, and in 61 to 180 s.
- **Play days per user**: returning on Day 1, Days 2-7, Days 8-28.
- **Playtime per user**: capped at 60 min per user per day.
- Then: co-play days with friends, qualified sessions, spend days, Robux per user.

What to do about it:
- Fix retention before monetization. First session must be clear and low-friction. Core loop must be satisfying. Give reasons to return (goals, progression, friends, new content).
- A **custom thumbnail** is required to be eligible for Home impressions. Default thumbnails are not.
- Accurate, original title and thumbnail. No monetary rewards in the title. No copies of existing games.
- Per the DevForum post, recommendations now weigh long-term retention and monetization (rolled out the week of 2026-08-20). Expect metric swings while it settles.
- Benchmarks on the dashboard are for comparison only and do not affect the algorithm.
- Track it in **Creator Analytics > Acquisition > Home Recommendations**. Copy weekly numbers into [[Analytics/Analytics Log|Analytics Log]].

Linked pages worth reading next:
- [Retention](https://create.roblox.com/docs/production/analytics/retention), [Engagement](https://create.roblox.com/docs/production/analytics/engagement), [Monetization](https://create.roblox.com/docs/production/analytics/monetization), [Acquisition](https://create.roblox.com/docs/production/analytics/acquisition) analytics
- [Thumbnails](https://create.roblox.com/docs/production/publishing/thumbnails)
- [Experience Events](https://create.roblox.com/docs/production/promotion/experience-events)
- [Experience Notifications](https://create.roblox.com/docs/cloud/guides/experience-notifications)
- [Discovery FAQ](https://create.roblox.com/docs/discovery-faq)
- [Ads Manager](https://create.roblox.com/docs/production/promotion/ads-manager#sponsored-experiences)

## 2. Learning Luau and Studio

- [Scripting overview](https://create.roblox.com/docs/scripting): start here. Use `local` for variables. Read [Script Types and Locations](https://create.roblox.com/docs/scripting/locations) early: a script in the wrong place silently doesn't run.
- [Build your first experience](https://create.roblox.com/docs/tutorials/first-experience) and [Introduction to coding](https://create.roblox.com/docs/tutorials/curriculums/coding)
- [Coding fundamentals](https://create.roblox.com/docs/tutorials/fundamentals/coding-1/coding-fundamentals) and [Basic gameplay tutorial](https://create.roblox.com/docs/tutorials/use-case-tutorials/scripting/basic-scripting/intro-to-scripting)
- [Luau reference](https://create.roblox.com/docs/luau) and [Luau vs Lua 5.1 compatibility](https://luau.org/compatibility)
- [Engine API reference](https://create.roblox.com/docs/reference/engine)
- [Sample projects](https://create.roblox.com/docs/samples)
- Docs index for AI tools: [llms.txt](https://create.roblox.com/docs/llms.txt). Every docs page also has a `.md` version (add `.md` to the URL).

## 3. Security (matches the rules in [[Systems]])

Source: [Security tactics](https://create.roblox.com/docs/scripting/security/security-tactics).
- Never trust the client. Exploiters control local state and can fire any RemoteEvent with any arguments at any rate. The server is the source of truth.
- Keep logic and data in ServerScriptService, not ReplicatedStorage or Workspace.
- For every feature ask: how could this be abused, what is the worst input, what if it's called very fast?
- Read next: [Network ownership and physics exploits](https://create.roblox.com/docs/scripting/security/network-ownership), [Access control](https://create.roblox.com/docs/scripting/security/access-control).

## 4. Monetization (after retention is working)

Source: [Monetization foundations](https://create.roblox.com/docs/production/game-design/monetization-foundations).
- Every item needs a clear purpose and an accurate description. Items are durable or consumable, and enhancement or expression.
- Shop should match the game's UI, show each item's value, and rotate stock.
- Season pass: free and premium tracks, rewards tied to the core loop, timeframes that fit session length.
- Read next: [Season pass design](https://create.roblox.com/docs/production/game-design/season-pass-design), [Quest design](https://create.roblox.com/docs/production/game-design/introduction-to-quest-design), [Passes](https://create.roblox.com/docs/production/monetization/passes), [Subscriptions](https://create.roblox.com/docs/production/monetization/subscriptions).
- Place offers at natural progression moments. Keep it fair and transparent.

## 5. AI and tooling

Official, built into Studio: [Studio MCP server](https://create.roblox.com/docs/studio/mcp).
- Enable in Assistant: `...` > Manage MCP Servers > Enable Studio as MCP server. Quick connect lists Claude Code and Claude Desktop. Restart Studio and the client, then look for the green indicator.
- Tools cover scripts, data model, running Luau in Edit/Client/Server, playtesting with console and screenshots, simulated input, and docs lookup. Use `list_roblox_studios` and `studio_id` if several Studio windows are open.
- Only connect clients you trust, since they can read and change your places.

Optional file-based workflow (not maintained by Roblox): [External tools](https://create.roblox.com/docs/projects/external-tools).
- Easiest: [Script Sync](https://create.roblox.com/docs/scripting/sync) for editing scripts externally with git.
- Fuller: [Rojo](https://rojo.space/docs/v7/) with [Rokit](https://github.com/rojo-rbx/rokit); packages with [Wally](https://wally.run/); lint with [selene](https://github.com/Kampfkarren/selene); format with [StyLua](https://github.com/JohnnyMorganz/StyLua); editor support via [luau-lsp](https://github.com/JohnnyMorganz/luau-lsp).
- Not needed for a one-month solo plan. Revisit if the project grows.

Third-party, unverified by me: a community MCP server (`robloxstudio-mcp` by boshyxd) shows up in directories. Prefer the official one above.

## 6. Obsidian plugins installed in this vault

Installed 2026-10-24 from the GitHub release assets, checked against the release file sizes:
- [Omnisearch](https://github.com/scambier/obsidian-omnisearch) 1.32.0: ranked, typo-tolerant search across notes. Needs Obsidian 1.13.3 or newer. Indexing PDFs and images needs the Text Extractor plugin (installed below).
- [Style Settings](https://github.com/community-archive/obsidian-style-settings) 1.0.9: lets themes and snippets expose settings in one pane. This is the archived community copy. Its manifest ID matches the original, `obsidian-style-settings`.

- [Text Extractor](https://github.com/scambier/obsidian-text-extractor) 0.7.0: companion that reads text from PDFs and images (OCR) so Omnisearch can find it. Needs Obsidian 1.4.16 or newer.

To activate: Obsidian > Settings > Community plugins > turn off Restricted mode, then reload the vault.

## Gaps
- Not yet read: the analytics pages, Standout Games, Premium Payouts rates, performance/optimization docs, DataStore docs, and a vetted ProfileStore source. Worth a second pass.
- Free YouTube or course recommendations: search results were unreliable, so I listed none.
