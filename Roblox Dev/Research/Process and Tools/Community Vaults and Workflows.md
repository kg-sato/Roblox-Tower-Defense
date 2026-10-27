---
date: 2026-10-27
tags: [research, process, llm, obsidian]
---
# Community Vaults and Workflows

How other people organise a game-dev knowledge base and work with LLMs, found 2026-10-27, and what we adopt. Related: [[Research/Index]], [[Home]], [[Research/Process and Tools/Workflow Tools and Skills|Workflow Tools and Skills]], [[Research/Process and Tools/Dev Process Playbook|Dev Process Playbook]], [[Feature Pipeline]].

Labels: **Fact** = read on the page. **Vendor claim** = the seller's own statement. **Inference** = our reading. **Unverified** = only seen in a search listing.

## Finding: there is no public "Roblox game vault" to copy
Searches for an Obsidian vault built for Roblox or any video-game design doc returned tabletop RPG and worldbuilding vaults (campaign, factions, locations, sessions) plus spam pages. **Fact:** the closest real patterns are the three below, none Roblox-specific. Our vault is already close to them.

## 1. The "LLM wiki" pattern (Karpathy)
Source: [Karpathy's gist](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) (read the first 100k of 136k characters; the rest is comments).
- **Fact:** three layers. Raw sources (immutable, the LLM never edits them), the wiki (LLM-owned markdown), and a schema file (`CLAUDE.md` or `AGENTS.md`) with the conventions.
- **Fact:** three operations. *Ingest* (read a source, write a summary page, update the index and related pages, append to the log; one source may touch 10 to 15 pages), *query* (search the wiki, answer with citations, file good answers back as pages), *lint* (find contradictions, stale claims, orphan pages, missing cross-references).
- **Fact:** `index.md` = categorised catalogue, one line per page, read first on every query. `log.md` = append-only, with a parseable prefix such as `## [date] ingest | Title`.
- **Fact:** tips: download images locally, use Obsidian graph view to spot orphans, Dataview for frontmatter queries, keep the wiki in git.
- **What we adopted today:** [[Research/Index]] is the index; [[Session Log]] is the log; `CLAUDE.md` is the schema; screenshots live in `Research/Reference Screens/`.
- **Not adopted yet (Inference):** a *lint* pass. Worth doing monthly: find notes that no other note links to, claims with no label, and notes older than a month that say "not verified".

## 2. claude-obsidian (a ready-made version of it)
Source: [AGENTS.md of claude-obsidian](https://gitcode.com/GitHub_Trending/cl/claude-obsidian/blob/main/AGENTS.md) (a mirror; the repo itself was not opened).
- **Fact:** layout is `.raw/` (immutable sources), `wiki/` (generated pages), `wiki/hot.md` (bounded recent context, "never a transcript"), `wiki/log.md` (operation history, newest first), `inbox/` (capture intake, never auto-deleted). Flat YAML frontmatter, `YYYY-MM-DD` dates, never fabricate quotes or page numbers.
- **Inference:** `hot.md` is the useful idea. Our [[Home]] now ends with a short "Recent sessions" block that does the same job, so a fresh session reads six lines instead of 40 KB.
- **Skip:** its transaction bundles and SHA-256 bookkeeping are heavy for a one-person vault.

## 3. RbxSync "harness" (the only Roblox-specific one)
Source: [RbxSync harness docs](https://docs.rbxsync.dev/harness-system).
- **Fact:** `.rbxsync/harness/` holds `game.yaml` (name, genre, audience, design goals, constraints), `features.yaml` (each feature has status `planned | in_progress | completed | blocked | cancelled`, priority, tags, dependencies, acceptance criteria) and `sessions/<id>.yaml` (goals, summary, **handoff notes**, timestamped entries, blockers). A fresh AI session calls "session start" to get the game, features and last five sessions back.
- **Fact:** the docs say to be specific in handoff notes and to end every session, even unfinished ones.
- **Inference, matches us:** [[Systems]] is our feature registry (it has status), [[Backlog]] our priorities, [[Session Log]] our session logs. What we lack are **acceptance criteria and dependencies per feature** and an explicit **handoff** line. Suggestion: add one `Handoff:` sentence to each Session Log line when work is left half done.

## 4. Whole "studio in a folder" setups
- **[Claude-Code-Game-Studios](https://github.com/Donchitos/Claude-Code-Game-Studios)** (Donchitos, MIT): a `.claude/` pack of subagents (design, programming, art, audio, QA), slash commands, hooks and doc templates, with Godot, Unity and Unreal variants and no Roblox variant. **Unverified:** listings disagree on counts (48 or 49 agents, 37 or 73 skills). **Inference:** too much machinery for a solo one-month game; the template list (GDD, sprint plan) is the only part worth reading.
- **[Ropilot](https://ropilot.ai/use-claude-in-roblox)** (a Studio plugin, free tier 500 "actions" a month): puts Claude, Codex or Cursor in Studio over MCP and playtests with screenshots. **Vendor claims** ("25K+ professionals", "most MCP setups can't see Studio") are unverified. **Inference:** we already have the official Studio MCP doing the same loop.

## 5. Studio MCP servers (what people connect LLMs with)
Listed in one search; only the first was opened.
- [roblox-mcp-pro](https://github.com/peerapolselanon/roblox-mcp-pro) (MIT, 29 tools): **Fact** from its README: `manage_sync` mirrors the live DataModel to local files and back (bidirectional, with a sourcemap), local broker on `127.0.0.1:3690`, optional `ROBLOX_MCP_TOKEN`. **Fact:** it auto-installs the Studio plugin and self-updates (pin the version if used). Maintenance unverified (2 stars, 211 commits, no dates shown).
- [boshyxd/robloxstudio-mcp](https://github.com/boshyxd/robloxstudio-mcp), [Roblox/studio-rust-mcp-server](https://github.com/Roblox/studio-rust-mcp-server) (the README says it stays available for reference, which hints that the built-in server replaced it), el4cteo/rbx-studio-mcp, Meganugger/roblox-studio-mcp. **Unverified:** only seen in listings.
- **Why it matters to us (Inference):** our biggest gap is that GameClient, MatchService, UltFX and others live only inside `Claude.rbxl`, so git cannot see them. A two-way mirror would close it. Our Studio MCP is the official one; adding a third-party server needs vetting under the user's standing rule (trustworthy source, pinned version). A cheaper route is the planned local export (script sources posted from Studio to a local file receiver).
- Rojo came up only as the usual way people sync files; no search result compared it with these servers. Our rule stays: no Rojo unless asked.

## Reading list (not read in full)
[useful-roblox-resources](https://github.com/Loominagit/useful-roblox-resources), JodeRBX/awesome-roblox, awesome-luau (npm packages), awesome-react-lua: directories of libraries and plugins; check the README of each before relying on it.

## Suggested next steps (not started)
1. Add `Handoff:` to Session Log lines when work is unfinished.
2. Add "Acceptance" and "Depends on" columns to [[Systems]] for systems still marked in progress.
3. Monthly vault lint (orphans, unlabeled claims, stale "not verified").
4. Decide: local script export vs a mirror server (see [[Backlog]] ideas).

## Not verified
Star counts, update dates and counts of agents in third-party repos; every Ropilot claim; whether roblox-mcp-pro's mirror handles edit conflicts (the README does not say).
