#!/bin/bash
# Generates 3 portrait variants for each roster character with ComfyUI (FLUX schnell). Run from the project root.
# Output: UI Kit/art/comfy_out/char_<name>_s<seed>.png ; picks are copied by hand into Roblox Dev/Assets/Characters/.
cd "$(dirname "$0")/../.."
STYLE="chibi character portrait, full body, cute glossy 3D cartoon mobile game character, humanoid or magical creature, simple readable silhouette, thick dark navy outline, bright saturated colours, soft white highlight on the upper left"
gen() { python "UI Kit/art/comfy_generate.py" "char_$1" --prompt "$2, $STYLE" --variants 3 --seed "$3" 2>&1 | grep -E "seed|Error|error"; }
gen pip "a tiny living ember flame spirit with a round smiling face, two small arms and a little spark on its head, warm orange and yellow" 11
gen moss "a tiny forest pixie girl with big translucent leaf wings, a red mushroom-cap hat and a cheerful smile, green and cream" 21
gen lumo "a small purple imp with little horns and a long tail carrying a glowing lantern, mischievous grin, purple and teal" 31
gen rook "a young apprentice wizard kid in an oversized pointed blue hat and robe holding a thick glowing spellbook, wide eyes, blue and white" 41
gen vesper "a young storm witch with an indigo hat streaked with a yellow lightning bolt and a staff topped by a small thundercloud, confident smirk, indigo and yellow" 51
gen aurel "a chibi star knight in shining white and gold armour with a star-shaped shield and a plumed helmet, noble pose, white gold and sky blue" 61
gen mirelle "an elderly moon sage with a long silver beard, a crescent moon staff and a small owl on her shoulder, deep blue starry robe, gentle wise smile" 71
gen solenne "a radiant dawn archmage woman with a floating golden halo crown, flowing rose-gold robe with a sun symbol and glowing hands, serene smile, gold and rose pink" 81
echo ROSTER-DONE
