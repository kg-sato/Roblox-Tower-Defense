# Rarity Silhouettes (T099)

Rule from [[Character Bible Rules]]: rarity changes the **outline**, not only the colour. Status: concept kit drawn by code overnight 2026-10-29; look and fit are UNVERIFIED until the user views the sheets. Not built into the 3D models yet.

## The kit (each rarity adds to the one below)
| Rarity | Outline change | Tint |
|---|---|---|
| Common | The base figure only. Simplest outline of the cast. | none |
| Rare | + a **halo ring** behind the head (one attached feature, reaches above the head). | blue `#4D8FD6` |
| Epic | Rare + **two floating shards** at chest height (the outline gains two separate pieces and about doubles in width). | purple `#9B5DE5` |
| Legendary | Epic + a **fan of 5 spikes** behind the head and **4 orbiting shards** (six floating pieces; outline about 2.4 to 4.8 times the base width). | gold `#F2B632` |

All kit shapes sit **behind** the figure, so the base silhouette is always a subset of the variant and the face stays clear. The tint is a secondary cue; the shape alone must tell the rarity (read the black silhouette row of each sheet).

## Results (`tools/rarity_silhouettes.py`, 12 familiars)
Silhouette overlap with the base (IoU): Rare 0.73 to 0.89, Epic 0.53 to 0.74, Legendary 0.30 to 0.54, so each step moves the outline, where a colour-only change would score 1.00. Floating shards 0 / 0 / 2 / 6. Report: `Overnight/evidence/T099_report.txt`. Sheets: `Assets/Characters/Rarity/<Name>_rarity.png` (colour row over silhouette row), `_rarity_sheet.png`, `_silhouette_sheet.png`.

## Open decisions for the user
1. In the cast each familiar has **one** rarity (4 Common, 4 Rare, 2 Epic, 2 Legendary), so the kit is a visual language: a Rare, Epic or Legendary familiar ships with its kit built into the 3D model (a later modelling step), or the kit is added as a rarity aura effect in game. Which?
2. Legendary at about 3 times the base width may be too large for a tower-defence tile; the spike length and orbit distance can be cut.
3. Merge tiers (T100) add body features per tier; the kit must not clash with those.
