# Familiar texture maps (T123, T127, T128)
`tools/texture_maps.py` derives a 512 px map set for the 12 familiars from the baked 1024 px base colour and roughness maps (`Assets/3D/Familiars/textured/`, from `Blender/bake_familiar_textures.py`). Output in `Assets/3D/Familiars/maps/`: `<Name>_Color_512`, `_Roughness_512`, `_Normal_512`, `_Emissive_512`, four contact sheets per rig family (`<family>_<map>_sheet.png`) and `maps_report.json`.

## One emissive rule across the cast (T128)
A pixel glows when it is bright and saturated: `glow = smoothstep(0.80, 0.95, value) * smoothstep(0.30, 0.50, saturation)`, blurred 1 px, zero where the texture is unpainted. Result (share of painted texture that glows): Moth-Lantern 20.3%, Ember 16.9%, Star Drake 4.5%, Gargoyle 3.6%, Sentinel 0.45%, Ward 0.43%, Mirror Chorister 0.07%, Archivist 0.02%, Brass Hound 0.01%, Frostling 0.02%, Mourner 0%, Grey Veil Wraith 0%. The lantern and flame carriers glow most, as the lore asks; Gargoyle's 3.6% is its warm gold trim, which may not be wanted, and Ward's small lantern gets only 0.4%.
Use in Roblox: a SurfaceAppearance emissive mask (property name `EmissiveMaskContent` with `EmissiveStrength` and `EmissiveTint`, from memory of the Roblox docs: UNVERIFIED here) or, for the glowing recipes, the ember and starDust recipes in [[Material Library]].

## Normal maps (T127)
Tangent-space (OpenGL) normals from the high-pass of the colour luminance, strength 2.0. Painted edges and features become relief; nothing was sculpted, so this is an inferred relief. Mean slope strengths range from 1.08 (Ward) to 1.92 (Frostling), so Frostling and Moth-Lantern show the most relief and Ward the least. Whether it "adds silhouette detail" is UNVERIFIED: a normal map cannot change the silhouette; it only shades the surface.

## Family sheets (T123)
Rig families from [[Rig Template]]: biped (Ward, Archivist, Mourner, Mirror Chorister, Sentinel, Frostling), quadruped (Brass Hound, Gargoyle), flyer (Moth-Lantern, Star Drake), floater (Ember, Grey Veil Wraith). The sheets show each family's maps side by side for review. The models still use their own UV layouts, so the maps are NOT packed into shared atlases (that would need a UV re-layout of every model).

## Open
- Wire the 512 px maps into SurfaceAppearance on the imported meshes and look at them in Play (not done).
- Upload them as images (not done; see [[Upload Plan]]).
- The base colour is projected from the design sheets (first pass), so blotches and stray colours in the texture show up in every derived map.
