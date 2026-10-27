---
date: 2026-10-26
tags: [research, vfx, animation, tiktok, engagement]
---
# TikTok VFX Reference Study

Two parts: (A) the 11 TikToks the user supplied, now played to the end and their comments read, and (B) a search for high-quality Roblox animation, ranked by likes and saves. Related: [[Research/Video Reference Analysis|Video Reference Analysis]] (a different, older batch of stills), [[Research/Magical Roll Animation Playbook|Magical Roll Animation Playbook]], [[Research/Smooth Motion and Blur Playbook|Smooth Motion and Blur Playbook]], [[Research/Loading and Reveal Spec|Loading and Reveal Spec]].

**Method.** Built-in browser, signed-in TikTok session, 2026-10-26. Each clip ran in TikTok's single-video player (`tiktok.com/player/v1/<id>`, no feed autoplay) at 1x speed. A script logged the play position: every clip reached its end, with no backward jumps and no stalls, and wall time matched the clip length. Stills were taken every 2 to 5 s, plus paused seeks where I missed frames. Playback was **muted**, so no sound was judged. Comments were read from the comment panel, about 30 to 150 per clip plus up to 8 reply threads, sorted by likes. Engagement counts were read from each video page that day; they change over time.

**Labels.** *Seen* = what the frames show. *Creator* = the poster's caption or reply. *Commenter* = a viewer's claim, unverified. *Inference* = my reading.

## Key findings

1. **Readability beats spectacle.** The most-liked criticisms in the batch: "cant even tell whats happening", "too much camera work", "too much salt ruins a dish" (clips 1 and 2). Spectacle that does little damage gets mocked: "Allat just do deal 15 damage", 542 likes. For a tower-defense ability, the hit area and direction must read in the game camera; spectacle should match the actual effect. *(Commenter, repeated across clips)*
2. **Impact needs weight cues.** On the SFX clip (8), viewers said the hits "don't really feel that impactful" and "feel empty", and suggested impact frames and screen shake. *(Commenter)* Our new `AbilityFX` has no shake or hit-stop yet.
3. **Effects are built in phases** (seen in clips 1, 6, 7, 8, 11): calm or telegraph, then wind-up (a converging spiral or a darkened world), then a directional strike, then a burst, then an aftermath. Clip 6 ends on a **lasting scorch decal**, and clip 7 opens with a **ground warning ring** (concentric warm colours) before the hit.
4. **Tools named by creators** (creator replies): Roblox Studio with the **Forge** VFX plugin and **Moon Animator** (zukiii269, clip 6); "Moon animator or eclipse animator"; mesh VFX mixed with particle emitters; "the humanoid shouldnt move at all" during the animation (zukiii269, clip 7); "Moonanimator", self-taught over 4 years (ktb_tai). Nobody showed a Blender step. *(Creator)*
5. **AI-made claims had no process shown** (clips 3, 4, 5, 9). Comments pushed back ("so that's why they look so bad?", 2,193 likes) and asked about polygon counts and prompts; no creator answered with a workflow. Clip 5 is a slingshot *launch* game with a hex upgrade tree, not an obstacle course as the old notes said.
6. **Colour against the real map.** The best effects use one main colour plus white on a dark set (clips 1, 7, 10, 11). *Seen in our own test:* green effects disappeared on our grass map, so `AbilityFX` now defaults to violet.
7. **Saves track usefulness, likes track spectacle.** Saves divided by likes: effect showcases 14 to 31%, tutorial-style posts 47 to 75% (table below). The user asked to rank quality by saves: saves mostly measure "I'll use this later", which favours tutorials. For judging *animation quality*, compare likes and comments among showcases only.
8. **In a tower-defense gacha, viewers want summons skippable.** On the Anime OmniVerse summon cutscene, the top comment asked to skip summons (288 likes), and another complained about "10 minute long summon animations" when a pull takes millions of tries. The developer answered that secret units get their own custom cutscene. Our reveal already scales effort by rarity and is skippable, which matches.
9. **Timing has character, not just smoothness.** The top comment on ktb_tai (2,700 likes): "not too smooth, not too choppy". hovark's 172K-like post is a plain block dummy with hand-drawn 2D **smear frames** (a cartoon form of motion blur). *Inference:* keep our eased "smooth like motion blur" rule, but allow holds and snaps on key poses so motion doesn't feel floaty.
10. **Rare-pull cutscenes can be graphic design and story.** vicho._blox's "1 in 10,000,000" Sol's RNG cutscene (28.8K likes) uses flat colour cards, a spiral icon, a white pillar and a black screen asking "will you be my puppet? 1. Yes 2. No", rather than particles. Its comments debate the odds, not the visuals.

## Recommendations for our game (original adaptations, nothing copied)

| Idea | Player benefit | Where | Cost / risk | How to check |
|---|---|---|---|---|
| Add a 0.06 s hit-stop and a small camera shake (off with reduced motion) to `AbilityFX` impact and the ultimate | Hits feel heavy (finding 2) | Client, AbilityFX/GameClient | Tiny; shake must honour reduced motion | Audit timing; user feel test |
| Ground telegraph ring 0.3 s before a boss attack and a lane ability | Players read where it lands (findings 1, 3) | Boss attack, AbilityFX wind-up | 1 part | Screenshot at game camera |
| Short-lived scorch decal (2 to 3 s) after big hits | Readable aftermath, cheap | AbilityFX decay | 1 decal, fades | Leak check in audit |
| Keep routine reveals under 1 s with tap-to-skip; save cinematic time for Legendary+ | Matches what TD players ask for (finding 8) | RevealFX tiers (already close) | None | Already: Common 0.9 s |
| Smear-frame style speed shapes on fast pet attacks (2D sprite flash for 1 to 2 frames) | Snappy motion without per-frame blur cost | Pet attack clip | Needs sprite upload (user OK) | Stills plus user eye test |
| Ultimate-tier reveal option: flat graphic cards and one line of text ("Answer the call?"), in the Ink idea's style | Distinct, cheap, readable on phones | RevealFX Ultimate variant | Design time only | User review |

## Engagement table (high-quality Roblox animation search)

Searches: "roblox vfx", "roblox animation smooth", "roblox ui animation", "roblox hatch animation", "sols rng aura cutscene", "roblox tower defense summon animation". Candidate lists are in TikTok's own ranking order for this account, so they are not a neutral sample. Counts read 2026-10-26.

| Creator | Video | Length | Likes | Comments | Saves | Shares | Saves/likes | Kind | Watched |
|---|---|---|---|---|---|---|---|---|---|
| [hovark_](https://www.tiktok.com/@hovark_/video/7700941649391750418) | 2D smear test | 7.3 s | 172.2K | 2,121 | 38.5K | 7,036 | 22% | showcase | full |
| [mariigamesyt](https://www.tiktok.com/@mariigamesyt/video/7605696515025210654) | Moon Animator plugins | 75.9 s | 66.7K | 689 | 38.8K | 4,207 | 58% | tutorial | no |
| [ktb_tai](https://www.tiktok.com/@ktb_tai/video/7566840787204443414) | "Unfinished" | 14.1 s | 58.5K | 766 | 15.5K | 4,075 | 26% | showcase | full |
| [se28ss](https://www.tiktok.com/@se28ss/video/7694721973791853854) | animation | 140.8 s | 49.3K | 851 | 23.4K | 3,944 | 47% | showcase (long) | no |
| [vicho._blox](https://www.tiktok.com/@vicho._blox/video/7578547147340074247) | Sol's RNG 1-in-10M cutscene | 31.6 s | 28.8K | 494 | 6,343 | 4,106 | 22% | rare-pull cutscene | full |
| [hap1yzomby](https://www.tiktok.com/@hap1yzomby/video/7596261891266153749) | fan aura | 38.6 s | 22.4K | 776 | 4,259 | 2,821 | 19% | showcase | no |
| [dminer_rbx](https://www.tiktok.com/@dminer_rbx/video/7669149955197652242) | smooth button tutorial | 17.3 s | 13.8K | 204 | 10.3K | 1,875 | 75% | UI tutorial | full |
| [raoso_](https://www.tiktok.com/@raoso_/video/7632790901944864022) | cutscene concept | 14.0 s | 12.5K | 461 | 3,384 | 954 | 27% | showcase | no |
| [flayzikk1](https://www.tiktok.com/@flayzikk1/video/7675099189944044822) | animated UI tutorial | 17.1 s | 10.4K | 224 | 6,249 | 1,293 | 60% | UI tutorial | no |
| [aniomniverse](https://www.tiktok.com/@aniomniverse/video/7559663954348281106) | TD summon cutscene | 19.4 s | 7,421 | 143 | 1,003 | 382 | 14% | TD summon | full |

The 11 supplied clips, same measure: .6ix13 58.7K likes / 27%; jubydandev 45K / 21%; vysdev 19.1K / 21% and 14.4K / 20%; ropilot__ai 18.1K / 28%; Ironclad 8,663 / 28%; bbstudios4 6,567 / 54% (a how-to); sailent.sfx 5,760 / 31%; zukiii269 2,840 / 30%, 1,960 / 25%, 1,413 / 23%.

Hatch-animation posts from small developers mostly had fewer than 30 likes (search "roblox hatch animation"). *Inference:* hatch animations alone don't draw an audience; rarity context and character do.

The dminer_rbx button recipe (seen, low-res): TextButton + UIAspectRatioConstraint + UIScale + CanvasGroup + Click and Hover sounds; constants read as hover scale about 1.08, click scale about 0.9, hover time 0.15 s, click down about 0.06 s, Quad easing (digits partly illegible). Our `UIMotion` (hover 1.06, press 0.94) is in the same range.

## Coverage table (the 11 supplied clips)

| # | Source | Full playback | Caption / creator process | Comments / replies | Technical check | Note |
|---|---|---|---|---|---|---|
| 1 | vysdev 7690338692728147222 | completed (10.56 s of 10.53) | caption only | partial: 151 of 380, 6 threads | UNVERIFIED (no build info) | done |
| 2 | vysdev 7677375601623354627 | completed (11.96 / 11.9) | caption credits "Draco" for anim | partial: 36 of 245, 8 threads | UNVERIFIED | done |
| 3 | jubydandev 7699732993996344589 | completed (11.51 / 11.47) | claim only ("made with claude") | partial: 43 of 787 | UNVERIFIED: no prompts, tris or files | done |
| 4 | bbstudios4 7700685121522912542 | completed (48.66 / 48.6); stills 25-48 s missing | none | partial: 37 of 120 | font UNVERIFIED (too low-res) | done |
| 5 | .6ix13 7693982847895375137 | completed (43.26 / 43.2) | claim only ("30 minutes, single prompt") | partial: 35 of 1,557; 2 creator replies | UNVERIFIED | done |
| 6 | zukiii269 7691880206180584718 | completed (36.22 / 36.18) | creator: Studio + Forge + Moon Animator | partial: 30 of 66; 4 creator replies | creator-stated | done |
| 7 | zukiii269 7696050610008886541 | completed (30.56 / 30.51) | creator: mesh + particle mix, Moon/Eclipse | partial: 39 of 114; 10 creator replies | creator-stated | done |
| 8 | sailent.sfx 7680492931366554910 | completed (11.34 / 11.3), **muted** | caption: SFX commissions | partial: 31 of 106 | audio UNVERIFIED | done |
| 9 | ropilot__ai 7692448939223567649 | completed (18.15 / 18.1) | vendor claim | partial: 37 of 526 | UNVERIFIED | done |
| 10 | zukiii269 7691118650203442446 | completed (17.91 / 17.88) | creator replies (no process) | partial: 36 of 156 | UNVERIFIED | done |
| 11 | Ironclad 7687004405345897758 | completed (45.72 / 45.67) | creator: "I don't script", "pure vfx" | partial: 42 of 211 | UNVERIFIED | done |

**Fonts.** The only font-focused clip found is #4 (bbstudios4, "COMMANDS" panel): tall narrow display capitals for the title, small tracked capitals for labels. The game footage is about 240 px wide, so the typeface family is **not identified**. Don't pick a font from it; ask the user for the original or a sharper frame.

**3D modelling.** Only #3 shows models (a red armoured creature, a teal octopus, a steampunk mammoth with gears). No modelling steps, topology or triangle counts are shown, so this changes nothing in our Hunyuan3D, Blender and Studio pipeline.

## Corrections to the earlier summary

- #5 is a slingshot launch game with upgrades, a results card and a stats panel, not an obstacle course.
- #6 is mostly blue and white (a sky flash, a blue orb, cyan crystal spikes, a scorch decal at the end), not dark red and orange.
- #7 is a cyan wind/slash moveset with a warm ground telegraph ring, not "dark smoky on grey tiles" only.
- #2 is described now: black open, anime-styled caster, gold and violet blast, cut to black.
- The earlier "may run poorly on many devices" comment on #11 was not found again in this 42-comment sample.

## Gaps

- Playback was muted: no sound judged (it matters most for #8).
- Comments are a partial sample on every clip (TikTok loads them lazily); figures are the shown count versus the number read.
- Stills are every 2 to 5 s, so effect frames under about 0.5 s may be missed. #4 has no stills after 25 s.
- Five search results were only stat-checked, not watched (mariigamesyt, se28ss, hap1yzomby, raoso_, flayzikk1); dminer_rbx's comments were not read.
- TikTok ranks search results by its own algorithm for this account, so the table is not a neutral sample. YouTube, X and Reddit were not searched.
- Engagement counts are from 2026-10-26 and will drift.

## Appendix A: per-clip log (supplied 11)

### 1 vysdev 7690338692728147222
caption: "#vfx #roblox #robloxdeveloper #fyp #viral my vfx"; sound: original sound - mosurron (cover music per comment). 10.53 s, 1024x576 (landscape screen recording of Roblox Studio with "Recording Started" toast).
stats (2026-10-26): 19.1K likes, 380 comments, 4,017 saves, 2,035 shares. saves/likes 21%.
playback: player/v1, ended=true, wall 10.56 s, 0 back-jumps, 0 stalls. Muted (no audio assessment).
frames: 0:04 dark character silhouette cut against wall of green slash ribbons; ~0:06 radial green strand burst around character (white-hot core); ~0:08 green orb + spiral ring above dark ground, streak debris; ~0:09 jagged green spikes erupting from ground + lightning; end card. 0-4 s not captured.
comments: 151/380 read (6 reply threads). Top: "Average score VFX for any basketball game" 2046; "Allat just do deal 15 damage" 542; Rio "How I imagine AI to make me a fire cutscene" 412 (AI debate); "Claude CANNOT do this" 112; "the typa animation a 57ccu game has" 58; "too much camera work, but still peak" 38; "trieu: cant even tell whats happening" 9; "too much salt ruins a dish" 4; "only your pc run this"; plugin Qs (VFX Forge, qp2) - Gael_M: plugins only speed work, need design knowledge (19). No creator replies seen. Many hire/commission/tutorial requests.
### 2 vysdev 7677375601623354627
caption: "my vfx and anim by Draco I think". 11.9 s, 1024x576 Studio screen recording. stats: 14.4K likes, 245 comments, 2,894 saves, 1,397 shares (saves/likes 20%).
playback: ended=true, wall 11.96 s, 0 back, 0 stall. muted.
frames: 0-~2 s black (slow open / blackout); ~3 s close-up of an anime-styled caster (wide witch hat) with purple-red energy wash behind; ~5 s over-the-shoulder, gold/yellow beams and fire streaks; ~6.5 s low-angle, orange-red sky, violet lightning streaks radiating; ~8-10 s hard cut to black (holds 2+ s) ; end card. Structure: black -> character beat -> blast -> black.
comments: 36/245 read (8 reply threads). Top: "then theres games like mm2 that get 700k avg players for bum updates" 611; "WHO ARE YOU BRO" 280; reply "'Vfx slop' and it's a work of art" 118; "Claude analyze this video and make this in one shot" 49; "too much salt ruins the dish" 4; tool guesses (unverified): "forge vfx to animate mesh", "rovfx", Moon Animator, blender. No creator replies.
### 3 jubydandev 7699732993996344589
caption: "dropping update this weekend #roblox #game #gamedeveloper #fyp #viral"; overlay "all models made with claude btw"; sound credit on player: "...PER & SMAIL" (partly legible). 11.47 s, 576x1024 vertical, phone filming a monitor.
stats: 45K likes, 787 comments, 9,303 saves, 4,816 shares (saves/likes 21%).
playback: ended=true, wall 11.51 s, 0 back, 0 stall. Frames 0-6 s at 2 s steps, 7.3-10 s re-played for stills.
frames: 0-2 s monitor with a chat/code editor (text not legible at this size) and overlay; ~4 s same screen with small model thumbnails in the chat; ~6 s Studio viewport, red armoured creature (dark red plates, spikes) on white baseplate, more models in background; ~7.5 s teal stylised octopus with pale spots, gold eye ring, loose props (bone, branch) floating; ~8.5-10 s steampunk mammoth: brown shaggy body, ivory tusks, clock-tower howdah, gold gear ring halo and floating gears. Visual read: chunky stylised, part-assembled look, bright readable palettes, accessory-heavy silhouettes. NOT shown: prompts, file formats, triangle counts, rig/animation, in-game use.
comments: 43/787 read (8 threads). Top: "current Roblox trend of studs, rebirths/mutations/brain rot is so awful" 4,626; "so that's why they look so bad?" 2,193 (reply "they don't though" 650); "I hate games made with ai #boycott" 596; "token cost $200, hiring a modeller $50" 20; "Polygon count?" 10; "How do I make 3D models in Claude... he said he doesn't have the tools" 7; "What style do you even tell it?" 6; "They do look a bit generic compared to other games' models" 22. No creator replies. Workflow NOT explained by creator.
### 4 bbstudios4 7700685121522912542
caption: "#robloxdev #claude #robloxgame #robloxdeveloper #blender"; overlay "U rid ur Claude of slop ui"; sound "original sound - BRATTY" (partly legible). 48.6 s, 576x1024; a small Studio screen-recording inset in the middle of a blurred copy of itself.
stats: 6,567 likes, 120 comments, 3,533 saves, 674 shares (saves/likes 54%, highest of batch; tutorial-style).
playback: ended=true, wall 48.66 s, 0 back, 0 stall. Stills only for 0-~25 s (tool lag; end overlay blocked re-seek stills 26-46 s) -> frames 25-48 s UNVERIFIED.
frames: 0-4 s avatar on dark plaza with a white star-shaped ground burst, dusky purple/pink sky, foggy distance; ~6-25 s a dark "COMMANDS" panel over the blurred world: red circular emblem left of the title, small spaced caps subtitle under it (reads like "EXECUTE YOUR COMMAND", low-res), thin header row of tabs, then rows populate one by one (command name / argument columns / right-aligned values) on a near-black translucent panel, minimal borders. Typography: tall narrow display caps for the title, small tracked caps for labels. Family NOT identifiable at 576 px (inset ~240 px wide) -> font UNVERIFIED.
comments: 37/120 read (8 threads). Top: "Straight to the vault" 1,023; "Straight to obsidian" 477; "thanks gang straight to the vault" 258; "5 years of developing was for claude to mog my shi in minutes" 149. Workflow claims (commenters, unverified): reply by Ecstasy (47) - he puts screenshots of reference UI into an Obsidian vault as examples; chase (31) - download ~20 VFX TikToks, have Claude document them in Obsidian; CinematicFilms (30) - image references + refined prompt; "Is the trick to make the UI not so smooth and perfect, rectangular, almost unfinished?" 7; context6575: image refs cost more tokens, better results. No creator replies.
### 5 .6ix13 7693982847895375137
caption: "Took Claude 30 minutes go and make your game #robloxfyp #roblox #fyp #claude #developer"; overlays "A single prompt to Claude btw" / "Go and make that Roblox game". 43.2 s, 576x1024, Studio screen recording in a band with captions above/below. Correction to old notes: it is a slingshot LAUNCH game with upgrades, not an obstacle course.
stats: 58.7K likes, 1,557 comments, 15.8K saves, 14.4K shares (saves/likes 27%; shares/likes 25%, highest).
playback: ended=true, wall 43.26 s, 0 back, 0 stall. Stills ~0, ~9, ~14, ~19, ~24, ~30, ~35 s; 36-43 s not captured.
frames: 0-9 s slingshot Y-frame on a grass field with a blue/yellow launch pad, left HUD column of square buttons, top "Launch / Upgrade" pills; ~9-14 s a purple hex-grid upgrade tree (icons inside hexagons, connected; one selected hex shows a tooltip card) over the world, red button bottom; ~19 s launched runway view, distance counter top, currency counter bottom-left; ~24 s results card "Launch Complete! NICE LAUNCH! +1,036" with Retry (green) / Return (orange), stat icons; ~30 s dark transition; ~35 s "Stats" panel (Launches, Best Score, Best Distance, Best Combo, Destroyed) brown/wood frame with red X.
comments: 35/1,557 read (8 threads). Top: "not a single ui glitch its hard to believe" 12,600; "prompt writing is gonna be a job soon" 8,125; "expand the recommended section with ai slop instead of fun games" 2,540; "make a prompting tutorial" 81; "how to connect claude to roblox?" 44 -> reply "Roblox assistant and MCP connection" 30; "Did Claude design the whole UI or did you just wire it to figma?" 1 (unanswered). Creator replies: "Meta" (to "During a gold rush, sell the shovels"), "Sure bro" - no process detail. 30-min / single-prompt claim UNVERIFIED.
### 6 zukiii269 7691880206180584718
caption: "Feedback and suggestions are always appreciated :) #roblox #robloxdev #vfx"; overlay "One of my VERY VERY VERY old vfx". 36.18 s, 576x1024; Studio recording inset with blurred copy behind. Correction: mostly BLUE/WHITE, not red/orange as the old notes said.
stats: 1,413 likes, 66 comments, 322 saves, 93 shares (saves/likes 23%).
playback: ended=true, wall 36.22 s, 0 back, 0 stall. Stills every ~3-4 s.
frames: 0-3 s empty desert baseplate, blue sky (establishing calm); ~6 s character with dark aura near camera; ~9 s camera tilts up to a sky flash: white sun-burst with radial light shafts through clouds; ~12 s dark figure in foreground silhouetted against a swirling cloud vortex; ~15 s close shot of a white-hot energy orb wrapped in blue flame ribbons, black background (world darkened); ~18 s two characters, dark caster vs small opponent, grey smoke; ~21 s burst of tall cyan crystal/ice spikes erupting around a target; ~30 s white-blue explosion with lens-flare orbs and radial streaks; ~33 s aftermath: wide shot of the desert with a dark radial scorch/crack decal and a small debris pile where the blast was. Phases: calm -> wind-up in sky -> darkened charge -> eruption -> big impact -> lingering scar.
comments: 30/66 read (8 threads). Creator replies: "Roblox studio" (to "Blender or just roblox studio?"); "This specific one uses forge and moon animator plugin in roblox studio"; "I never said i quit"; "Not yet" (selling). Commenter (unverified): "uses Moon animator or eclipse animator ... vfx have scripts inside to show at the right time" 3. Others: price/hire requests, tutorial requests.
### 7 zukiii269 7696050610008886541
caption: "Feedbacks and suggestions are welcomed :) #robloxdev #roblox #vfx #jjk #fyp"; overlay "2nd vfx post on here". 30.51 s, 576x1024 inset recording.
stats: 1,960 likes, 114 comments, 496 saves, 129 shares (saves/likes 25%).
playback: ended=true, wall 30.56 s, 0 back, 0 stall. Stills ~0, 3, 6, 9-23 s every ~3 s. The move sequence appears to be shown twice (same shots repeat ~9-23 s).
frames: 0 s lone character on a dark grey tiled arena; ~3 s ground warning ring under the caster: concentric red->orange->yellow->green disc inside a dark ring with white spikes (telegraph); ~6 s close camera, a cyan blade/beam sweeping across with white wind ribbons; ~9 s over-the-shoulder of caster, opponent hit at left with crackling white-blue lightning, grey smoke trail on ground; ~12 s white wind/smoke burst at the target with two cyan beams crossing; ~15 s extreme close-up, cyan/white shards across a dark frame; repeat. Palette: one hero colour (cyan) + white + grey smoke on a dark set.
comments: 39/114 read (8 threads). Creator replies (technical): wind effects are "Mostly a mix of both" (particle emitters and meshes); "I dont animate the meshes thats all vfx" / "Yeah its mesh vfx"; animator: "Moon animator or eclipse animator plugin"; "the humanoid shouldnt move at all" during the animation (movement done separately); "6 digits in studio hours"; "Nope" (likely to "blender?"); "Comms are open". Commenters: "Whats the prompt" 10; "Better than Strongest Battlegrounds" 7; Russian thread: "too many effects isn't always good" vs "it's not too many here".
### 8 sailent.sfx 7680492931366554910
caption: "some recent sfx commissions more animations otw | #roblox #sfx #sound #sounddesign #audio"; sound "original sound - sailent.sfx". 11.3 s, 1024x576. Creator sells SOUND; the visuals are a commissioned client's (VFX author not named).
stats: 5,760 likes, 106 comments, 1,776 saves, 435 shares (saves/likes 31%).
playback: ended=true, wall 11.34 s, 0 back, 0 stall. MUTED in my session: the sound itself (the point of the clip) is NOT assessed -> audio UNVERIFIED.
frames: 0 s dark checker arena, a small pink-violet four-point star sparkles mid-air (charge); ~2 s it fires a thick violet-white beam toward camera with streaking parallel lines and sparkles; ~4 s beam end blooms into a white starburst inside a thin circular glyph ring, purple flare; ~6 s second effect (Studio view): an ember-glowing crater on grey ground under a dark storm cloud; ~8 s cloud thickens with blue-white crackle, rain streaks fall; ~10 s clearing, small blue orb remains.
comments: 31/106 read (8 threads). Top: "how exactly do you make sfx" 47; "I feel like it's ai but ik it isn't" 45; critique: "these don't really feel that impactful" 8; "It kinda feels empty when there's an impact" 6; "Add impact frames to the second one" 4; reply "missing screenshakes, the vfx and sfx are very good" 2; "was the beam particle emitter or beams?" 2 (unanswered). No creator replies.
### 9 ropilot__ai 7692448939223567649
caption: "This was made with Ropilots New ASTRA 6 model..."; overlay "Everything you see Ropilot Astra 6 Made". 18.1 s, 576x1024. Promotional account for a commercial AI plugin (vendor claim).
stats: 18.1K likes, 526 comments, 5,030 saves, 2,007 shares (saves/likes 28%).
playback: ended=true, wall 18.15 s, 0 back, 0 stall.
frames: 0 s dark avatar alone on a grey tiled baseplate; ~3 s a yellow/black block ring builds itself around the player on red ground (blocks pop in); ~6 s dark stone volcano island with orange lava channels and lava pools; ~9 s colourful voxel ruins (green-topped brick walls, cyan door) with a white light-burst spawn effect; ~12 s dark lava mountain again, lava stream; ~15 s grassy island with blue pool and teal crystal tower/statues. Each scene appears with a pop/spawn transition. Everything is blocky, part-built, bright flat colours: a scene-generation demo, not a game.
comments: 37/526 read (8 threads). Top: "for yall saying 'i will never play an ai game' you already did" 533; "whats the point if u can just connect gpt to roblox" 254; "Ropilot just connects your AI to roblox for an extra cost... codex can connect for no extra cost" 187 (commenter claim, unverified); reply (25): AI games always "in progress / tech demo / unfinished, buggy"; "the type of roblox dev in the trailers vs 'Buy nuke for 49 robux'" 31; "How did you do the light spawn effect?" (unanswered). No creator replies.
### 10 zukiii269 7691118650203442446
caption: "Open to suggestions and feedback :) #roblox #robloxdev #vfx"; overlay "First VFX post on here". 17.88 s, 576x1024 inset recording. Correction: palette is teal/cyan + black ink + white, plus a red-coated swordsman; not "green/teal swirls around a character in a cinematic camera" only.
stats: 2,840 likes, 156 comments, 860 saves, 283 shares (saves/likes 30%).
playback: ended=true, wall 17.91 s, 0 back, 0 stall.
frames: 0 s avatar beside an anime-styled companion (light-haired figure) on a dark street set; ~3 s extreme close-up: gold-engraved sword hilt, red sleeve, pale cyan hair streaming (cutscene framing); ~6 s black void, a cyan shard flies along a dark blue smear, small moon top-left; ~9 s spinning dark blocks in a teal warp tunnel (radial speed lines); ~12 s ink-wash landscape: grey misty mountains, black bamboo silhouettes, ink splashes falling from the top (Chinese ink-painting look); ~15 s white mist burst around the red-coated swordsman mid-slash, sword drawn horizontally. Structure: character beat -> abstract warp -> painted world -> strike.
comments: 36/156 read (8 threads). Top: "how do ppl learn vfx" 72; reply Muri (8): tutorials exist for slash/explosion/fire but "you need to know what properties do and shape the vfx"; "isnt that the wuthering waves ult" / "Is that quiyuan?" (reference source is a commercial game ult - inspiration only); solstice_0: "some black paint makes no sense and some of it is too delayed ... looks like random circles" (timing critique). Creator: "I dont care if it gets stolen, they're not the ones with skills"; sarcastic "'Opus 5 generate me a sword cutscene inspired by wuwa'".
### 11 skibidirizzler107 (Ironclad) 7687004405345897758
caption: "#fypシ゚viral #fyp #fypシ #robloxstudio #vfx"; overlays "Version 1:" "End result at end" "Version 2" "Version 3 next". 45.67 s, 576x1024 inset recording.
stats: 8,663 likes, 211 comments, 2,396 saves, 820 shares (saves/likes 28%).
playback: ended=true, wall 45.72 s, 0 back, 0 stall. Stills ~0-8, 13, 18, 23, 28, 33, 38, 42 s.
frames: V1 (0-8 s): black void, scattered violet points, small bright violet star in centre, thin streak lines - sparse. V2 (~13-23 s): same field denser: purple nebula haze, more stars, cross-shaped lens glints, faint constellation lines; a "GeForce Experience" overlay flashes over the recording at ~13 s (screen-recorder UI, not part of the effect). V3 (~28-45 s): palette shifts to deep blue; dense starfield; a speech-bubble/cloud-shaped soft vignette of stars appears; final: avatar at centre surrounded by sparkle crosses and long horizontal streaks, nebula glow behind. Iteration story: same concept, each version adds density, a glow layer, and a clear focal subject.
comments: 42/211 read (8 threads). Top: "genuinely one of the most beautiful vfx i've seen in a while" 430; "how much credits was this" 16; "galacticslop" 9; "is this open source or a tutorial?" 5; "Is vfx mostly trial and error? vfx forge and qwinkle particles 2 good plugins?" 1. Creator replies: "I don't script" (31), "It's pure vfx genius" (24), "No like 3" (to "how many hours? is that hard?"), "Idk should I open source it", "Lol noted". Commenter claim (unverified): Roblox cloud API can auto-upload assets from Blender. Earlier note's perf comment ("may run poorly on many devices") not re-found in this 42-comment sample.

## Appendix B: search log

### TikTok search candidates (2026-10-26, logged-in session, ranking is TikTok's; number = likes shown on card)
### q="roblox vfx"
hovark_ 7700941649391750418 Top liked 171.8K "first time trying to add 2D effects" #robloxanimation
uksd._ 7596320329467825429 Top liked 31.6K sci-fi sound design (by @friwght)
vinallac 7679845239653289246 Top liked 13.7K "HOW TO DO VFX coming soon"
pr0_devv 7679364442194234646 13.4K "How do bezier curves work in Roblox Studio | make VFX"
vi_zi_ll 7670895303536446728 8,478 "Full release coming mid-August"
sine_studios 7655745859048508692 8,030 Sine VFX plugin promo
syuaey_ 7698042240324717846 7,534 #eclipsefighter
blovica 7690294293059161357 5,743 ult cutscene commission
brookz34 7606418616149462286 2,336 great sword slam vfx+script
### q="roblox animation smooth"
mariigamesyt 7605696515025210654 Top liked 66.7K "moon animator plugins that'll save your life" (tutorial)
ktb_tai 7566840787204443414 58.5K "Unfinished" #robloxanimation #anime
se28ss 7694721973791853854 49.3K #robloxanimation
onyxchaser 7617661696873663758 28.3K "problems with animating" moon animator
vizz_xd 7601965447138905357 26.7K compilation (credits others)
dminer_rbx 7669149955197652242 13.8K "How to make Smooth Button Animation" (UI tutorial)
### q="roblox ui animation"
lihfolk 7690631802628705550 Top liked 16.9K (AI 3D generation tutorial teaser)
palm_dev 7684777669875027231 11.4K UI Q&A
flayzikk1 7675099189944044822 Top liked 10.4K "How to make animated UI in Roblox studio"
dev5s_ 7697376018989878541 7,595 #claude game
uglyydev 7694650082246937878 6,393 best plugins (ui designer)
smudger13030 7699123611696860418 2,802 "Want to make UI like this"
gfxcomet 7695567752261586206 1,325 "reactive particle system for my roblox ui"
### q="roblox hatch animation"  (low engagement niche)
realkurai 7698579868493073677 1,102 "Tap Simulator Reborn's Rarest Secret Hatch Animation"
conebone01 7690617690209226016 341; elemty_ma 325; rest < 30 likes (many devs posting their own hatch animations get little reach)
### q="sols rng aura cutscene"
vicho._blox 7578547147340074247 Top liked 28.8K "Illusionary 1 in 10,000,000 cutscene" (rare-pull cutscene)
hap1yzomby 7596261891266153749 Top liked 22.4K "Nullscapes aura" fan animation
raoso_ 7632790901944864022 Top liked 12.5K "Sol's RNG cutscene concept - Heartbeat"
metalsoni_c 7624552558266223892 9,280 gameplay
r4dd__ 7600883174092164374 4,672; aioia.eggy 7657059171325562133 4,167; uop0_0 7697946095967571207 4,125
### q="roblox tower defense summon animation"
aniomniverse 7559663954348281106 7,421 "Summon Effect cutscene" #towerdefense
not_m1nh 7698425967663942945 6,797 Anime Frontlines
aceywaycerblx 7700336656850767117 2,046; cute_girlv2 1,984; dieareass 7575615908421356818 1,152 UTD summon & evolve cutscene sneak

### Engagement table (read on each video page 2026-10-26)
| handle | id | dur s | likes | comments | saves | shares | saves/likes | kind |
| hovark_ | 7700941649391750418 | 7.3 | 172.2K | 2,121 | 38.5K | 7,036 | 22% | showcase (2D smear frames) |
| ktb_tai | 7566840787204443414 | 14.2 | 58.5K | 766 | 15.5K | 4,075 | 26% | showcase anim |
| mariigamesyt | 7605696515025210654 | 75.9 | 66.7K | 689 | 38.8K | 4,207 | 58% | tutorial (Moon Animator plugins) |
| se28ss | 7694721973791853854 | 140.8 | 49.3K | 851 | 23.4K | 3,944 | 47% | long animation (unwatched) |
| vicho._blox | 7578547147340074247 | 31.8 | 28.8K | 494 | 6,343 | 4,106 | 22% | rare-aura cutscene (Sol's RNG) |
| hap1yzomby | 7596261891266153749 | 38.6 | 22.4K | 776 | 4,259 | 2,821 | 19% | fan aura animation |
| dminer_rbx | 7669149955197652242 | 17.4 | 13.8K | 204 | 10.3K | 1,875 | 75% | UI tutorial (smooth button) |
| raoso_ | 7632790901944864022 | 14.0 | 12.5K | 461 | 3,384 | 954 | 27% | cutscene concept |
| flayzikk1 | 7675099189944044822 | 17.1 | 10.4K | 224 | 6,249 | 1,293 | 60% | UI tutorial |
| aniomniverse | 7559663954348281106 | 19.6 | 7,421 | 143 | 1,003 | 382 | 14% | TD summon cutscene |

### hovark_ 7700941649391750418 - WATCHED full (ended=true, wall 7.34 s) + seek stills 2.2/3.6/5.0/6.3
caption "This is the first time I'm trying to add 2D effects, and so far it's not going very well :/"; overlay "First 2D VFX Test".
frames: plain white R6 block dummy on default baseplate; exaggerated cartoony run/kick/punch with big squash, stretched limbs; white hand-drawn 2D SMEAR shapes trail the limbs on fast frames (e.g. a jagged white smear off the leg at 2.2 s); punch at 5.0 s ends in a white 2D cloud puff; at 6.3 s split screen "(after export)" shows the smear decal broken/misaligned.
comments 36/2,121: "I've always been wondering how people do that effect" 5,187; "Sell this as an animation pack" 2,610 -> "it's animated in a game, can't get effects on animation packs" 342; "plugin called phase animator allows it" 460 (commenter, unverified); aslegger: R6 bundle using hidden body parts as decals to recreate smear frames 221 (unverified); "Blur slop" 12.
lesson: personality and readable exaggeration on a plain dummy beat spectacle; smear frames = 2D motion blur.
### ktb_tai 7566840787204443414 - WATCHED full (ended=true, wall 14.28 s, 0 back/stall) + seek stills 1.5/4.9/8.0/10.8/13.9
caption "Unfinished #robloxanimation #anime"; landscape 1024x576. Stills cropped to the centre third (zoom region), so edges unseen.
frames: 1.5 s white-haired figure close, black hand-drawn ink tendrils and a spiked circular sigil overlaid (2D linework on 3D); ~4.9 s white spiky 2D crescent silhouette over an empty blue grid city; ~8 s tall vertical light pillar with a rainbow edge, white smoke arcs on the ground; ~10.8 s empty grid street (pause/hold beat); ~13.9 s dark frame with thin light rays (end).
comments 37/766: "unique animation style, not too smooth, not too choppy" 2,700; "a new competitor for the most useless flips (really cool animation though)" 118; "Boss cutscene things" 64; "kitzu level animation" 10. Creator: "Moonanimator", "4 years", "started when I was 16", "YouTube mostly but self taught", "There's levels to this".
lesson: the most-liked praise is about TIMING CHARACTER (holds and snaps mixed with smooth arcs), not raw smoothness.
### vicho._blox 7578547147340074247 - WATCHED full (ended=true, wall 31.78 s) + seek stills 2/7.6/12.5/17.2/22.5/28.6 (landscape)
caption "Illusionary 1 in 10.000.000 [The Perfect Puppet] cutscene | Sol's RNG"; music credited by a commenter as a track by "The Weirdos" (unverified).
frames: 2 s flat graphic: bold blue 8-point star with a white heart cut-out on pale grey, blue border frame; 7.6 s solid saturated blue field with a small white spiral tile, Japanese subtitle at the bottom ("今何時ですか?" = "what time is it?"); 12.5 s white vertical pillar on saturated blue; 17.2 s black; 22.5 s black screen, small serif text "will you be my puppet?" with choices "1. Yes / 2. No"; 28.6 s desaturated grey game world, player with a violet-white aura on a slab, collection UI panels at both sides.
comments 36/494: about RARITY not visuals - "its 10m and u need to get it raw with 1 luck" 1,340; "10M vs 2.5B" 1,156; "what a waste" 531; "It doesn't compare to Equinox" 372; "All of this for a game where you click one button and do nothing" 37.
lesson: a rare-pull cutscene can be graphic design + story beats (flat colour cards, a question to the player) rather than particles; viewers judge it against the odds and other auras.
### aniomniverse 7559663954348281106 - WATCHED full (ended=true, wall 19.56 s) + seek stills 1.5/5.5/9.5/13/17.7
caption "Summon Effect cutscene #roblox #towerdefense"; overlay "Summon Cutscene" in a pixel font. Inset landscape recording in a vertical frame.
frames: 1.5 s dark blue-violet room, faint light; 5.5 s golden light floods in, figure silhouetted in yellow-white glow, beam streaks; 9.5-13 s near-whiteout warm parchment-gold screen with a soft bright core (long hold); 17.7 s game logo card "ANIME OMNIVERSE" (purple chrome lettering, horns).
comments 31/143: "Allat just us to skip summon" 288 -> dev "We will remove skip specifically just for you" 225; "games telling you to summon 3 million times but have 10 minute long summon animations" 23; "we always skip that part" 20; "lag tower defense" 4. Dev replies: "if you pull a secret unit there will be a custom cutscene for that specific unit".
lesson: in a TD gacha the AUDIENCE ASKS FOR SKIP on routine summons; spend cutscene time only on rare pulls. Long whiteout holds read as filler.
