# Roblox Creator Store: free asset licence rules (T051)

Question: what rules apply to free Creator Store assets we might insert (project policy allows vetted free assets), and what must we check before using one?

**Not legal advice.** The Roblox Terms of Use page returned 403 and the Creator Hub pages contain no standard licence grant. This note records what the Hub says and what it does not. Re-read the Terms before shipping anything that depends on an asset's licence.

All Hub pages fetched 2026-10-28 (undated).

## Facts (sourced)
- The Creator Store covers 3D assets, visual effects, 2D assets, gameplay, plugins and audio. Distributable types: Model, Plugin, MeshPart, Decal, audio. Creators can acquire free assets or buy priced ones and reuse them across their projects. [Creator Hub, Creator Store](https://create.roblox.com/docs/production/creator-store)
- The Hub does not state a standard licence or "free to use in any experience". It says distributed assets must follow the Community Rules, Terms of Use and IP guidelines, and violations can lead to moderation of the asset and the account. [Creator Hub, Creator Store](https://create.roblox.com/docs/production/creator-store); [Creator Hub, Publishing to the Creator Store](https://create.roblox.com/docs/production/publishing/creator-store)
- Restricted image, mesh or decal assets need the owner's explicit permission to load in Studio or at runtime. Open Use assets can be accessed by anyone with the asset ID. Composite assets may include Open Use dependencies from others, not Restricted dependencies you did not upload. Asset Privacy is not DRM: it controls loading, not copying. Same pages.
- Resale: only models and plugins you own from an individual account can be sold; composite models with Restricted assets you did not create cannot be sold or distributed (audio and video on the Store are the exception). Same pages.
- Script restrictions on store assets: no remote asset loading (`require(assetId)`, `loadstring()`, `InsertService:LoadAsset()`, `AssetService:LoadAssetAsync()`, `ModuleScript.LinkedSource`), no obfuscated code, no engine-feature obscuring, no unnecessarily large scripts. Inserted assets may contain scripts, which can be disabled from the right-click menu. Report violating assets with Report Item. Same pages.
- Audio: a 30-day distribution limit of 100 for verified accounts and 10 for unverified; the first audio submission requires accepting legal agreements. The page does not mention a 10-second limit (a search summary of another page claims one for sound effects, unverified). Same pages.
- Distributors must have a verified account (age check or government ID; phone verification does not count). Same pages.
- Roblox runs human and automated moderation including DMCA handling (search summary of the Hub, not read in full).

## Not found
- Any standard licence text for using free assets in a published experience, attribution rules, or commercial-use scope; the Terms of Use page was unreadable (403).

## Rules for us (recommendations, not legal advice)
1. Before using a free asset: check the creator's verified status and the upload date and read every script in it; delete remote loading (`require(assetId)`, `loadstring`) and anything obfuscated. This matches the project rule to vet free assets.
2. Prefer assets whose creator is Roblox or a verified studio; log the asset id, creator and date checked in `VFX/ASSETS.md` (project rule).
3. Do not republish or resell inserted assets inside our own assets; keep them in our game only.
4. Avoid free audio unless the legal agreements and source are clear; prefer our own generated sound (we log ids).
5. For anything unclear, ask the user to read the Terms of Use, since the page was unavailable to me.
6. Do not rely on a search-result blog about licensing.

## Sources
| # | Source | Date | Note |
|---|---|---|---|
| 1 | https://create.roblox.com/docs/production/creator-store | fetched 2026-10-28 | read |
| 2 | https://create.roblox.com/docs/production/publishing/creator-store | fetched 2026-10-28 | read |
| 3 | https://create.roblox.com/docs/assets | fetched 2026-10-28 | read; no licence text |
| 4 | https://en.help.roblox.com/hc/en-us/articles/115004647846-Roblox-Terms-of-Use | n/a | 403; unread |
| 5 | https://create.roblox.com/docs/production/publishing/ip-guidelines | not visited | IP guidelines linked from the Hub |
