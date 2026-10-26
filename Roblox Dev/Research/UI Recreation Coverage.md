# UI Recreation Coverage

Written 2026-10-25. The user asked to recreate every UI in the screenshots 1 to 1 (gameplay can be redesigned later). This note lists what exists and what does not, so we build in a clear order. Related: [[UI Art Pipeline]], [[UI Generator Method]], [[Screenshot Analysis]], [[Skill Tree, Effects and Characters]], `UI Kit/README.md`

## Honest scope
- The screenshots are in `Roblox Dev/Research/` (about 70 files). The UI Kit (`ReplicatedStorage.UIKit`, 12 screens) already recreates some of them; the rest are not built.
- **"1 to 1" by eye is not possible to prove.** We can match layout, hierarchy, colours and component types and compare screenshots side by side; exact pixels, fonts and the games' hand-made art will differ. Art comes from our pipeline (Blender icons, ComfyUI, Kimi), not from the games.
- The game's own HUD (`GameClient`) does not use the UI Kit yet. Porting means rewriting that script's UI parts on top of the kit; the match logic stays.
- The reference games' screens are private design references only; we do not copy their art or names.

## Built in the UI Kit (checked by screenshot in earlier sessions; see `UI Kit/README.md`)
PetHud, Shop, WelcomeBack, DailyTasks, Settings, TutorialHud, CollectionLog, AuraRoll, UpgradeHex, Inventory, Rebirth, Loading.

## Skill tree: where it stands
The in-game Skill Tree now shows blank "?" hexes around the frontier and hides deeper ones (screenshot checked 2026-10-25). The kit's `UpgradeHex` screen is the closer copy of [[fruit-hex-upgrade-tree.png]]; the game's tree still has its own styling (dark nodes, gold cost badges) rather than the reference's pixel look, orange "Open" nodes and level numerals.

## Built 2026-10-25 (UIScreens2 module, `UI Kit/luau/UIScreens2.luau`, installed as `ReplicatedStorage.UIKit.UIScreens2`)
- **LobbyHud** (from [[duel-lobby-hud-daily-tasks-nav-bar.png]]): key counter, Daily Tasks panel with progress bars and rewards, To Duels button, leaderboard list, Play button, 7-item nav bar with badges and two red call-out bubbles. Passes the validator (Scale only). Render: `UI Kit Renders/LobbyHud.jpg`.
- **BattlePass** (from [[duel-battle-pass-track.png]]): level block, tooltip, progress bar, prev/next arrows, free and premium reward rows (7 columns), level tabs, two bundle cards with strike-through prices, close button. Passes the validator. Render: `UI Kit Renders/BattlePass.jpg`.
- **CrateClaim** (from [[duel-welcome-back-crate-claim.png]]): welcome banner, chest with a count, pulsing Claim button. Render `CrateClaim.jpg`.
- **UnitView** (from [[duel-weapon-view-level-up.png]], shown for a pet): collection panel with a red Dismiss button, pet list with a selected row and a badge, big model stand-in on a glow disc, bottom action row (Leave, Skin, Aura, Charm, Evolve), name block, level bar with "Level up now!" and a key-cost button, reward line, three action rows, red lock tab. Render `UnitView.jpg`.
- **ModeSelect** (from [[duel-mode-select-tiles.png]]): five mode tiles (one selected with a white border), a locked "Ranked" tile with a level requirement, a limited-time strip with six reward chips, two big banners, red close. Render `ModeSelect.jpg`.
- **EventShop** (from [[duel-event-shop-candy.png]]): two currency pills, event banner, locked-earning strip, "Spend" grid of 8 items with green/orange price tags, limited bundle with four slots and a LIMITED tag. Render `EventShop.jpg`. Seen once; not re-captured after the build.
- **PassShop** (from [[pet-shop-gamepasses.png]]): tab strip with Passes selected, Gamepasses header, Hatching section with a wide bundle card (included list, best-deal ribbon, struck-through price) and six pass cards with tag line, description and price buttons, plus the top of a Pets section. First capture had cards overflowing the panel; fixed and re-captured. Render `PassShop.jpg`.
- **Profile** (from [[card-profile.png]], pixel theme): name and chips, VIEW/EDIT toggle, TABLE frame, BEST HIT box, LIFETIME tiles, CUSTOMIZE tabs and cards, wide Collection Log button. Customize cards were clipped by the button in the first capture; adjusted and re-captured (cards now fit, small). Render `Profile.jpg`.
- **FirstDraw** (from [[card-first-draw-tutorial.png]], pixel theme): centre deck with a pulsing tap ring and an orange pointer, NEXT note, one ability square, Book and Settings buttons with labels (labels were off-screen at first; moved and re-captured). The pointer is a text glyph and looks like a zigzag, not the reference's arrow. Render `FirstDraw.jpg`.
- Three small position tweaks after the screenshots (x1 under the chest, lock tab clear of the list, chip labels clear of the banners) were validated but not re-screenshotted.
- How they differ from the references: sprite and emoji icons stand in for the games' 3D art; the backdrop is a flat gradient instead of the blurred game world; arrows are text; leaderboard has no device icons; nothing is wired to game data, claims or purchases; no phone-size or touch test; no motion beyond the kit's stagger and pulse. Checked by screenshot only (editor-size viewport).

## Not built yet, by source image (suggested order)
Priority is what our game needs first (meta menus around the loop), then the rest.
| Order | Screen | Source images |
|---|---|---|
| 1 | (built) Lobby/home HUD with nav bar and daily tasks | [[duel-lobby-hud-daily-tasks-nav-bar.png]] |
| 2 | (built) Battle pass track | [[duel-battle-pass-track.png]] |
| 3 | (built) Crate / welcome-back claim | [[duel-welcome-back-crate-claim.png]] |
| 4 | (built) Unit view with level-up | [[duel-weapon-view-level-up.png]] |
| 5 | (built) Mode select tiles | [[duel-mode-select-tiles.png]] |
| 6 | (built) Event shop | [[duel-event-shop-candy.png]] |
| 7 | (built) Pass shop | [[pet-shop-gamepasses.png]], [[idle-shop-tokens-passes.png]] |
| 8 | Trade menu | [[pet-trade-menu.png]] (trading is excluded from launch; build later or skip) |
| 9 | (built) Profile and first-draw tutorial | [[card-profile.png]], [[card-first-draw-tutorial.png]] |
| 10 | Unlock toast and chevrons, island portals | [[pet-hud-unlock-toast-chevrons.png]], [[pet-island-portals.png]] |
| 11 | Equip-best inventory, tutorial steps | [[fruit-inventory-equip-best.png]], [[fruit-tutorial-1-pull-lever.png]], [[fruit-tutorial-4-grab-coins.png]] |
| 12 | Fishing family (depth meter, minigame, catch, upgrades, portals) | `fishing-*.png` (7 files); only if we make a similar mini-game |
| 13 | Free-reward popup, base arrow | [[egg-free-reward-popup.png]], [[egg-your-base-arrow.png]] |
| 14 | Idle columns | [[idle-main-loop-columns.png]] |
| 15 | Aura viewer list | [[aura-view-hades-summoning-circle.png]] (effects images are VFX, not UI) |
| 16 | Settings variants | [[duel-settings-audio.png]], [[duel-settings-crosshair.png]] |
| 17 | Loading with flash warning | [[card-loading-screen-flash-warning.png]] (Loading screen exists; warning card to check) |

## Method per screen (from the workflow)
Reference image -> `/make-ui` skill using the UI Kit -> validator (Scale-only) -> Play and screenshot -> side-by-side comparison with the reference -> fix -> the user reviews. Anything needing art goes through the art pipeline first. Nothing is uploaded to Roblox without the user's OK.

## Open decisions for the user
- Which screens first (the suggested order above is mine).
- Whether the game's HUD should switch to the UI Kit look (pixel/candy themes) or keep its current dark-panel style.

## Built 2026-10-25 (batch 3)
- **NowPlaying** (Sols RNG style popup, bottom right): live from MusicFX.TrackStarted, slides out after 7 s, progress bar from TimePosition. Installed as StarterPlayerScripts.NowPlayingClient. Display only, no pause.
- **UnlockToast**, **EquipBest**, **FreeReward**: built and re-screenshotted after layout fixes (UI Kit Renders/UnlockToast.jpg, FreeReward.jpg). FreeReward tasks are in-game ones (no like/favourite tasks; Roblox rule unverified). FreeReward's last task tile sits slightly past the panel edge.
- Still not built: island portals, tutorial steps 1/4, idle columns, aura viewer, settings variants, loading warning, trade, fishing.

## Lobby HUD redesign (2026-10-26)
- LobbyHud now follows Sols ([[sols-roll-result-crowned-1-in-20000.png]]): menu column, 3 counters (gem cyan, key violet, coin gold), leaderboard with avatar icons and rarity-coloured names, Auto / Roll / Quick, item bar. S.LobbyHud(K, parent, {phone=bool, backdrop=bool}); auto phone when the viewport is under 1000 px wide (K.isPhone()).
- Phone: menu is a top row beside Roblox's own buttons, counters beneath it, leaderboard shows 5 rows, item bar and hints dropped; Roll cluster bottom-centre between the thumbstick (bottom-left) and jump button (bottom-right). Emulated at 812x375 with ghost zones for those controls; all interactive elements 45 px or more except none left under 44.
- Chevrons: K.chevrons(parent, {x,y,w,h,count,dir}), sprite icon_chevron, ripples tail to head, still when reduced motion is on. Used in UnlockToast, pointing at the egg.
- Not done: real phone or touch test (emulated only), wiring to game data (blocked on ProfileStore and the redesign's economy), the in-match HUD in GameClient is unchanged.

## Fonts (2026-10-26)
Tested 14 Roblox fonts side by side (UI Kit Renders/FontTest.jpg). Chosen: **Fondamento** headings and buttons, **Titillium Web** body text and numbers, **Grenze Gotisch** only for big display titles (banners, game title). Rejected: Sarpanch (its 'a' reads as 'o' at small sizes), Merriweather (too bookish; digits look old-style), Creepster. In UITheme.Sols as font, titleFont, numberFont, displayFont; GameClient STYLE uses the same.
