# Kimi master prompt (paste this into Kimi once, at the start of an art session)

Why this exists: Kimi is our image generator. A consistent style across dozens of icons only happens if every
image is requested with the same style rules, so this prompt carries them. Claude cannot operate Kimi's window,
so the hand-off is a folder: Kimi's images end up in `UI Kit/art/inbox/`, then Claude processes them.

## Paste this

> You are the art generator for a Roblox mobile game UI. I will give you a list of items. For EACH item make ONE image.
>
> **Style (identical for every image):** glossy 3D cartoon mobile-game icon, like a polished Roblox or casual-game
> item icon. Thick dark navy outline (#121220) all around the subject. Bright saturated candy colours. Smooth
> gradient shading with a clear soft white highlight on the upper left and a darker lower edge. Chunky simple shapes
> that stay readable at 64 px. Light direction from the upper left. NO text, NO letters, NO numbers, NO watermark,
> NO cast shadow on the ground, NO frame or border around the picture.
>
> **Background:** one flat solid colour, exactly **#FF00FF (pure magenta)**, covering the whole canvas, with NO
> gradient, NO vignette, NO floor. The subject must not contain magenta.
>
> **Composition:** the subject is centred, fills about 80% of the canvas, nothing cut off at the edges.
> **Size:** square, 1024 x 1024, PNG.
>
> **File names:** save each image with the exact file name I give (for example `icon_egg.png`) into this folder:
> `C:\Users\kgsat\Documents\Roblox\UI Kit\art\inbox\`
> If you cannot save files there yourself, tell me and I will download them and move them.
>
> After each batch, list the file names you produced and anything you were unsure about. Do not invent extra items.

## Then paste a batch

Use the batch files in this folder, for example `BATCH-1-ICONS.md`. Each line has the exact file name and a
description. Ask Kimi for 4 to 6 items at a time; long batches drift in style.

## If Kimi has its own Blender or Roblox Studio connection
- Do not let Kimi change `Claude.rbxl` or upload anything to Roblox. Uploads happen only after the owner approves a list of files.
- Blender is welcome for rendered icons (a Blender script is also in `UI Kit/art/blender/`), but the output still goes to `inbox/` as magenta-background or transparent PNG.
- Roblox Studio is only needed to look at results; Claude loads art into Studio.

## After Kimi is done
Tell Claude "inbox ready". Claude runs `python "UI Kit/art/ingest_art.py"` (keys out the magenta, trims, resizes,
names the sprite), rebuilds `UIArt.luau`, syncs Studio and shows the result. Files that come out wrong are listed with the reason.

## Fixing common problems
| Problem | What to tell Kimi |
|---|---|
| Background not flat magenta (gradient, shadow) | "Redo with a perfectly flat #FF00FF background, no shadow, no gradient." |
| Subject has no outline | "Redo with a thick dark navy outline around the whole subject." |
| Style differs from the previous icon | Paste the Style block again and attach one good icon as the reference: "match this style exactly". |
| Text or numbers appeared | "Redo with no text of any kind." |
| Cropped at the edge | "Redo smaller, with a wide margin on all sides." |
