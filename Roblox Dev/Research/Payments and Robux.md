# Payments and Robux

Researched 2026-10-24 from the official pages [Developer products](https://create.roblox.com/docs/production/monetization/developer-products) and [Game passes](https://create.roblox.com/docs/production/monetization/game-passes). The ProcessReceipt reference page and Studio purchase-testing docs were NOT read; do that before coding. Related: [[Competitors and Policy]], [[Game Design Doc]], [[Systems]], [[Merge Tower Defense Playbook]]

## Two products, two uses
| | Game pass | Developer product |
|---|---|---|
| Bought | once per player | repeatedly |
| Use here | 2x Coins, Auto-Roll, Extra slots | Premium pets (each pet is a fixed-price product), gem packs |
| Created in | Creator Hub > Monetization > Passes | Creator Hub > Monetization > Developer Products |
| Server check | `UserOwnsGamePassAsync` on join, in `pcall` | `MarketplaceService.ProcessReceipt` |
| Prompt | `PromptGamePassPurchase` (client) | `PromptProductPurchase` (client) |

The user creates the pass or product in Creator Hub (account action) and gives us the IDs. We never create them.

## Rules from the official pages
- **ProcessReceipt:** exactly one server Script sets it. It must validate the player/product, grant, and only then return `PurchaseGranted`. Return `NotProcessedYet` if the player left or granting failed (Roblox retries when the player rejoins). Wrap in `pcall` so an error never grants half an item.
- **Do not trust `PromptProductPurchaseFinished`** to grant anything; it does not confirm the purchase.
- **Roblox does not keep a per-player purchase history.** To avoid double-granting, we must store handled `PurchaseId`s ourselves in the player profile. (Idempotency detail is not on the pages I read: confirm against the ProcessReceipt reference.)
- Show prices via `GetProductInfo` and prompt from a LocalScript so price optimization shows the player their own price.
- Passes are not granted automatically; the server grants the benefit itself.
- Promoted passes need a price above 49 and below 801 Robux (as stated on the page).
- Randomized rewards must follow the paid-random-item policy ([[Competitors and Policy]]). Our design keeps premium pets deterministic.
- Cross-game pass/product sales ended May 30, 2026 per the pages. We don't depend on them.

## Why payments wait for saving
A purchase must survive a rejoin. Returning `PurchaseGranted` before the grant is saved can lose what the player paid for. So order of work: ProfileStore (with session lock) -> profile schema with `purchases` (handled PurchaseIds) and `ownedPets` -> ProcessReceipt that adds the pet and saves -> only then show a real Buy button. Until then the Shop is not built; we don't ship a button that takes Robux for something we can't persist.

## Planned products (prices are the user's decision)
| Item | Type | Effect |
|---|---|---|
| Premium Pet A, B (cheap, better quality) | Developer product each | Grants that pet, tier 1, fixed price, no randomness |
| 2x Coins | Game pass | Coin rewards doubled |
| Auto-Roll | Game pass | Auto-roll toggle (free players still roll by tapping) |
| Gem pack (optional) | Developer product | Fixed gems, deterministic; just currency for rolls. NOTE: gems buy random rolls, so this makes rolls "paid" and triggers the paid-random-item rules. Do not ship until the full policy is read and odds/PolicyService handling exist |

## Server design
1. `Products` config: id, kind, grant. IDs start at 0 = "not set up", and the UI shows those items disabled.
2. `PurchaseService` (server): sets `ProcessReceipt`, looks up the player's profile, checks `profile.purchases[receipt.PurchaseId]`, applies the grant, records the id, saves, then returns `PurchaseGranted`.
3. `GamepassService`: on join, `UserOwnsGamePassAsync` for each pass id in `pcall`; also listen to `PromptGamePassPurchaseFinished` on the server to grant immediately.
4. Client only sends "I want to open the prompt for product X"; the server never accepts "I bought X" from the client.
5. Test with a Studio test purchase and by killing the server between prompt and grant.
