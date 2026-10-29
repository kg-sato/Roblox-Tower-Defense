# Tone guide: narration, captions, item text, UI text (T057)

Status: draft written overnight 2026-10-28. The bracketed caption style already exists in the cutscenes (for example `[ STARS GATHER ]`, `[ STARFALL ]`, `[ IMPACT CONFIRMED ]`, from [[Beam and Impact VFX Recipes]]). The voice rules, examples and banned phrases below are proposals. They draw on [[Short lore writing references]], [[Hades voice and lore delivery]], [[Disco Elysium voice and UI text]], [[Naming in whimsical dark fantasy]] and [[Cult of the Lamb tone and cult-building UI]]. All example lines are original; none is copied from another game.

## Voice in one sentence
Calm, a little wry, warm at the edges: a lamplighter who has seen the fog and still tells you the time. Whimsical shapes, dark facts, no gore.

## Rules
1. **Short.** Narration lines 4 to 12 words. One idea per line. Item and card lines 15 to 25 words; collection bios 120 to 200 words (see [[Character Bible Rules]]).
2. **Concrete.** Name a place, an object and one odd detail. Imply the feeling; never name it.
3. **Present tense, plain words.** Say "the lamp gutters", not "the lamp was in the process of failing".
4. **Second person for the player, third person for the world.** The narrator speaks to "you" only for instructions and warnings.
5. **Dark by implication.** Loss, forgetting and fog are fine; no gore, no cruelty to the player, no shame for failing.
6. **One joke at most per screen,** dry, never at the player's expense.
7. **No pressure language in the shop or rolls:** no fake urgency, no guilt (see [[Monetisation players accept vs hate]]).
8. **Names are short and concrete** ([[Naming in whimsical dark fantasy]]); the glossary (T058) is the source of truth.

## Caption style (existing, keep)
- Bracketed capitals with inner spaces, one beat per caption, 2 to 5 words (widened from 4 when the chapter scripts needed it): `[ THE LAMPS GUTTER ]`, `[ FOG ON THE QUAY ]`.
- Typewriter reveal at about 0.4 s per line, static when reduced motion is on (T190).
- Not for sentences. Anything that needs a verb phrase longer than five words goes into narration instead.

## Narration examples (by use)
- Stage intro: "Lampwick Lane. Dusk, again."
- Stage clear: "The lamps hold. The fog thinks it over."
- Boss warning: "Something is walking in the fog without footsteps."
- Failure: "The lantern goes out. Light it again." (no blame)
- Cosmic turn: "A gap in the fog. A star behind it."

## Item and card text examples
- Familiar card: "Ember: carried a Keeper's first lamp home and never forgot the way."
- Relic: "A brass key with no door. It warms when you are lost."
- Faction line: "Guild: if it is wound, it is loyal."
- Tooltip (plain, no flavour): "Range 4. Slows enemies for 2 seconds."

## UI text rules
- Buttons: one or two plain verbs ("Light", "Merge", "Back"), sentence case.
- Errors: say what happened and what to do ("Could not save. Try again."); no jokes, no blame.
- Numbers: use the number format setting; units always shown.
- Tooltips: facts only, 14 px minimum ([[Accessibility guidelines for our game]]).

## Banned phrases and habits
- Gamer filler: "epic", "OP", "grind", "nerf", "unlock the power of", "level up your".
- Menace for its own sake: "doom", "blood", "slaughter", "die" (use "go out", "fall").
- Pressure: "last chance", "hurry", "don't miss out", "you will regret".
- Generic fantasy: "ancient evil", "chosen one", "the prophecy", "dark lord".
- Direct quotes or recognisable lines from any other game, show or book.
- Insulting the player or naming their failure ("you failed", "too weak").
- Real-world slurs, religion mockery and real people.
- More than one exclamation mark on a screen.

## Checks
- A simple script can scan strings for banned words (candidate for the localisation table, T087 and T233).
- A human reads each new batch aloud; if it sounds like marketing, rewrite it.
- Human judgement of the voice stays UNVERIFIED until the user reads sample screens.
