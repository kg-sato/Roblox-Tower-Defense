"""Dark-fantasy ("Sols" vibe) icon descriptions used by comfy_generate.py --style sols.
Rules learned from test batches: literal orientation words (FLUX has no negative prompt), one object, no rings or
circles that enclose empty background, nothing standing under the object, thin dark outline."""

SOLS = {
    "icon_shop": "a small iron-wheeled merchant cart seen from the front, carved dark wood sides heaped with gold coins and gems, two round wheels, standing straight",
    "icon_index": "a thick closed grimoire seen from the front, standing upright, midnight blue leather cover, gold corner plates, a glowing violet star-shaped rune on the cover, ornate metal clasp",
    "icon_trade": "two chunky curved arrows, one gold and one cyan, chasing each other around a glowing star, the arrows touch the star, no outer ring",
    "icon_rebirth": "two curved arrows chasing each other around a glowing violet star, the arrows and the star touch each other, engraved silver arrows, no outer ring, no circle",
    "icon_pickaxe": "a dark steel pickaxe seen from the front, the wooden handle pointing straight down and the double-sided pick head horizontal on top, a small cyan gem on the head",
    "icon_shoe": "a pair-less armoured leather boot seen from the side, toe pointing right, small silver wing on the ankle, brass buckles, glowing rune on the sole",
    "icon_dragon": "a fierce green dragon head seen from the front, two curved golden horns, glowing amber eyes, scaled brow, symmetrical",
    "icon_garlic": "a single garlic bulb standing upright, pale cream skin with violet veins, a faint green magical glow at the tip, tiny rune carved on the front",
    "icon_apple": "a single glossy blood-red apple standing upright with one dark green leaf, a thin gold vein pattern on the skin, floating, nothing under it",
    "icon_stopwatch": "an antique brass pocket stopwatch seen from the front, upright, ornate engraved rim, white face with roman numerals, a red hand, glowing cyan crystal on top",
    "icon_candy": "a wrapped sweet seen from the front, horizontal, deep crimson and gold swirl, twisted wrapper ends left and right, tiny glowing sparkles",
    "icon_wrench": "a heavy iron wrench standing straight vertical, open jaw at the top, engraved runes along the shaft, one glowing cyan rune",
    "icon_gold_bar": "a single polished gold ingot seen from the front, a crown stamp on the face, faint warm glow",
    "icon_grapes": "a hanging bunch of dark violet grapes pointing straight down, glowing magenta highlights, one dark green leaf at the top",
    "icon_melon": "a wedge of watermelon seen from the front, point facing down, deep red flesh with black seeds, thick dark green rind, tiny gold glints",
    "icon_player": "a hooded adventurer bust seen from the front, dark cloak, glowing white eyes under the hood, silver clasp at the neck",
    "icon_flag": "a checkered war banner on a short iron pole standing perfectly straight and vertical, flag hanging flat to the right, black and gold squares, a spear tip on top",
    "icon_sword": "one single straight sword standing perfectly vertical with the blade pointing straight up, silver blade with a glowing cyan groove, golden cross guard, wrapped blue grip, jewelled pommel",
    "icon_shield": "a round-top heater shield seen from the front, deep navy face, gold rim, a glowing silver star emblem in the middle, studs along the edge",
    "icon_skull": "a human skull seen from the front, bone white with cracks, glowing violet eye sockets, a small iron crown fragment on top",
    "icon_rod": "a short thick fishing rod standing straight vertical, dark wood handle with gold rings, a big engraved brass reel, a glowing cyan lure hanging from the tip",
    "icon_bag": "a leather adventurer satchel seen from the front, upright, brass buckle, two straps, a glowing rune on the flap",
    "icon_clover": "a four-leaf clover seen from the front, emerald leaves with gold veins, short straight stem, soft green glow",
    "icon_hook": "a silver fishing hook hanging straight down from a small ring at the top, a barbed curve at the bottom, engraved runes on the shank",
    "icon_bell": "an ornate golden bell seen from the front, hanging straight, engraved runes, a glowing amber clapper",
    "icon_fish": "a fantasy fish seen from the side facing right, deep blue scales edged with gold, flowing fins, glowing cyan eye",
    "icon_wave": "a single curling ocean wave seen from the side, deep navy water with silver-white foam crest, carved like a stone relief",
}

SOLS.update({
    # rerolls: shorter and chunkier so they fill the icon square
    "icon_rebirth": "a glowing violet phoenix feather standing upright inside a short flame, engraved gold quill, symmetrical, compact",
    "icon_trade": "two ornate gold hands clasping each other seen from the front, forming a compact round shape, a small cyan gem between them",
    "icon_wave": "a single curling ocean wave carved as a compact square stone relief, deep navy water and silver-white foam crest, solid filled background inside the carving, no holes",
    "icon_wrench": "a short thick iron spanner standing upright with a large round open jaw at the top, wide shaft, engraved glowing cyan rune, compact",
    "icon_gold_bar": "a single polished gold ingot seen from the front, a crown stamp on the face and no letters, faint warm glow, the ingot floats and nothing is under it",
    "icon_melon": "a whole watermelon slice shaped like a half circle, flat cut side facing the viewer, pointed bottom, red flesh with black seeds, thick green rind, no egg shape",
    "icon_sword": "one short broad sword with a wide golden cross guard, blade pointing straight up, the whole sword short and chunky, silver blade with a glowing cyan groove",
    "icon_hook": "a big thick silver fishing hook hanging straight down from a large ring, wide curve and barb at the bottom, chunky, engraved runes",
    "icon_rod": "a short thick fishing rod standing straight vertical with a very large brass reel, dark wood handle, glowing cyan lure, compact and chunky",
    "icon_pickaxe": "a chunky dark steel pickaxe seen from the front, short wooden handle pointing straight down, wide curved double pick head on top with a cyan gem, compact",
    "icon_flag": "a short wide checkered war banner hanging flat from a horizontal bar on a short upright iron pole, black and gold squares, compact and chunky",
    # sprites that were still glossy 3D or flat vector
    "icon_chest": "a locked treasure chest seen from the front, dark iron-banded wood, gold trim, glowing violet keyhole, lid closed",
    "icon_coin": "a single thick gold coin seen from the front, engraved crown emblem, ridged edge, tiny glints",
    "icon_crown": "an ornate gold crown seen from the front, three points, red and violet jewels, engraved band",
    "icon_crystal": "a tall glowing violet crystal cluster standing upright, three crystals, faceted, magical glow inside",
    "icon_egg": "a mystical dragon egg standing upright, dark scaled shell with gold veins, a glowing cyan crack of light",
    "icon_gear": "a heavy iron cogwheel seen from the front, engraved runes on the teeth, a glowing cyan centre",
    "icon_gem": "a large cut sapphire gem seen from the front, deep blue facets, gold claws holding it, inner glow",
    "icon_gift": "a wrapped gift box seen from the front, midnight blue with gold ribbon and bow, a glowing violet seal",
    "icon_key": "an ornate antique gold key standing upright, bow at the top, a glowing cyan gem in the bow, engraved shaft",
    "icon_lock": "a closed heavy iron padlock seen from the front, gold trim, glowing violet keyhole",
    "icon_paw": "a beast paw print as a carved gold seal seen from the front, four toe pads and one large pad, engraved border",
    "icon_potion": "a round glass potion flask standing upright, glowing violet liquid, cork stopper, gold band on the neck",
    "icon_shard": "a single jagged glowing cyan crystal shard standing upright, faceted, bright inner glow",
    "icon_star": "a five-pointed gold star seen from the front, faceted like a cut jewel, bright inner glow",
    "icon_trophy": "an ornate gold chalice trophy seen from the front, two handles, a red gem on the cup, engraved base",
    "icon_bolt": "a jagged lightning bolt standing upright, glowing cyan with a white core, crackling edges",
    "icon_heart": "a crimson heart seen from the front, gold filigree frame around its edge, glowing inner light",
})

SOLS.update({
    "icon_weapons": "a sword and a pickaxe crossed in an X shape, symmetrical, both heads at the top, silver blade with a cyan groove and a dark steel pick head with a cyan gem, compact emblem filling a square",
    "icon_key": "a short chunky antique gold key lying horizontal, pointing right, huge ornate round bow on the left with a glowing cyan gem, wide toothed bit, compact and bold",
})

SOLS.update({
    "icon_check": "a bold check mark carved from a single glowing emerald, gold edge trim, seen from the front, thick and chunky, compact, filling a square",
})
