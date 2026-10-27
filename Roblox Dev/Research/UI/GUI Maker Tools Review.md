# GUI Maker Tools Review

Researched 2026-10-25. Question: what are RobloxGUIMaker, ForgeGUI and similar tools, and is there an **open-source** option we can use with the Obsidian vault? Related: [[UI Design Playbook]], [[Screenshot Analysis]], [[Low-End Device Playbook]], [[Animation Kit Review]], [[Systems]] (UI row)

## Short answer
- **RobloxGUIMaker and ForgeGUI are not open source.** I found no open-source repo for either. Both are commercial web tools.
- **There is no open-source "visual GUI maker" for Roblox that I could find** (a browser editor that places UI and exports it). What does exist as open source (MIT) are **Figma-to-Roblox converters**, which need Figma for the design step.
- **Best fit for our setup:** use **Obsidian's open-source Excalidraw plugin** as the design surface (sketch the screen in the vault), and let **Claude build the real UI in Studio** through the Studio MCP connection we already have, following open-source rules for responsive UI (the MIT `figma-to-roblox-ui` skill). Nothing in that chain is a paid tool.

## The tools

| Tool | What it is | Open source? | Cost | Notes |
|---|---|---|---|---|
| **Roblox GUI Maker** (various listings) | Browser builder: place UI visually or generate with AI, export Luau (plus JSON or a ZIP) | **No.** AlternativeTo lists it as proprietary, freemium | One listing says $9.99/month | A Studio companion plugin is described as "in development", so exports are pasted in by hand. Not affiliated with Roblox |
| **ForgeGUI / Forge UI** | AI web tool for Roblox thumbnails and GUI **assets** (images) from prompts | **No** (nothing public found) | Listings show a "Studio" plan at $49.90/month with credits | Produces images, not a working UI tree. I found no Studio plugin. Pricing is from directory pages, not verified on the vendor site |
| **GuiForge** (different tool, similar name) | Browser editor that exports Luau (LocalScript or modules), React-Lua (beta), `.rbxmx` (beta); has a Figma import plugin | **Unclear.** The forum post says free, does not state a license | Free, registration needed | Output is code you keep. Preview won't match the game exactly |
| **figrbx** (thynomex) | Figma plugin + local bridge + Studio plugin that rebuild a Figma frame as native UI | **Yes, MIT** | Free | Local only; images upload to your own Roblox account. Position/size in Scale, corners, fills, gradients, strokes, text, images. Not supported: auto-layout reflow, constraints, shadows, blur. Very new: 1 star, 7 commits |
| **FigmaToRoblox** (UiUyHerrera) | Similar, six-letter code. Adds 81 "layer name tags" for buttons, tabs, hover effects, scrolling, text inputs, purchase prompts | **Yes, MIT** | Free | Windows setup wizard; local server on port 7777; optional Open Cloud key (keep it secret). Very new: 0 stars, 5 commits. Skips inner shadows and blur |
| **figma-to-roblox-ui** (xtrair) | A **Claude skill** (rules and a validator), not an app. Scale-only sizing, centered anchors, scaled strokes and corners, images for complex art | **Yes, MIT** | Free | Written for Figma MCP + Studio MCP. Whether it works without Figma is not documented |
| **figma-to-roblox-ui** (EgoMoose) | Older converter | Yes | Free | **Archived** in Sept 2024. Skip |
| **Excalidraw plugin for Obsidian** (zsviczian) | Sketch and wireframe inside the vault; embed drawings in notes; auto-export PNG or SVG | **Yes, AGPL-3.0** | Free | Active (release 2.29.0 on 2026-10-12). Works offline by default |
| tsquare (Obsidian) | Text-based wireframes in notes | Not verified | Free | Version 0.1.1, few downloads. Too early to rely on |

## Why not just install a converter?
- They all start from **Figma**, a separate closed-source design app we do not use. That is an extra tool, account, and file format to keep in sync.
- The two open-source converters are **weeks old with almost no users**, so there is little track record. Running them means a local Node server and (optionally) an Open Cloud key. We already decided not to add API keys without your OK.
- **We already have a builder**: Claude writes UI directly into Studio and screenshots it (that is how our current HUD was made). What was missing was a **place to design it first** and **rules that keep it responsive**.

## Recommended setup (all open source, all local)
1. **Design in Obsidian with Excalidraw.** One drawing per screen (HUD, shop, crate reveal, settings), phone-shaped frame, boxes for buttons and labels, notes for states. Save next to the screen's note (for example in `UI/`).
2. **Auto-export PNG** (a frontmatter setting in the plugin) so each drawing also exists as an image Claude can read.
3. **Claude builds it in Studio** from the drawing plus the written spec, then screenshots the result for comparison. Same loop as the animation and reveal work.
4. **Adopt the xtrair rules** as our own UI rules (MIT licence, credit the author): Scale-only sizing (Offset 0), centered AnchorPoint unless an edge is justified, UICorner and UIStroke in Scale, `TextScaled` with a size constraint, images only for complex art, then a quick validator pass. These match the official guidance already in [[UI Design Playbook]] and [[Low-End Device Playbook]].
5. **Keep the Figma route as optional**, only if you decide to design in Figma. Then figrbx or FigmaToRoblox could be added.

## What I did and did not do
- Done: research and this note.
- **Installed 2026-10-25 (with your OK):** the Excalidraw plugin, release **2.29.0**, downloaded from GitHub (`main.js` 5,061,540 bytes, `manifest.json` 470, `styles.css` 353,360, matching the release listing), enabled in `community-plugins.json`, with `data.json` set to auto-export PNG (scale 2, drawings in `UI/Drawings/`). Not yet opened in Obsidian: reload the vault and check Settings > Excalidraw > Embed & export. Original instructions were: download from GitHub release **2.29.0** of `zsviczian/obsidian-excalidraw-plugin` (files `main.js` about 5.1 MB, `manifest.json`, `styles.css` about 0.35 MB, about 5.4 MB total), put them in `.obsidian/plugins/obsidian-excalidraw-plugin/`, and add the plugin to `community-plugins.json`. Obsidian must have Restricted mode off (it already needs that for our other plugins).
- Not tested: any converter, any exporter, or how well Claude reads Excalidraw PNGs for exact layout. Expect rough layout, not pixel-perfect.
- Not read: the Excalidraw plugin's frame and template docs in detail, tsquare's licence, ForgeGUI's own site.

## Licences to respect
- Excalidraw plugin: **AGPL-3.0**. Fine for personal use in our vault; do not copy its code into the game.
- figrbx, FigmaToRoblox, xtrair skill: **MIT**. Keep their copyright notice if we copy their code or rules; credit the authors.
- GuiForge: licence unknown. Do not copy.
- Exported art or drawings we make ourselves are ours.

## Gaps
- No open-source browser GUI editor with Roblox export found. If one exists, searches did not surface it (the search tool is weak on GitHub).
- Pricing and feature claims for RobloxGUIMaker and ForgeGUI come from directory listings and a forum post, not from the vendors.
