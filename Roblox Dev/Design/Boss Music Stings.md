# Boss phase music stings (T186)
Three stings per boss, 15 in total, specified as cues only (no audio made). A sting plays at a phase change (at 66% and 33% hp) and at the start of the fight, over the stage music, 3 to 5 seconds, ducking the stage track by about 6 dB while it plays (the ducking rule is T164). Mood follows the grief arc in [[The Clockmaker]]; palette follows the stage set's music. Boss phases and attacks: [[Boss Designs]].

| Boss | Fight start | Phase 2 (66%) | Phase 3 (33%) |
|---|---|---|---|
| The Unbound (denial) | a low soft pad swells, one muted bell, then silence | the pad turns hollow, a second bell a half step lower | the pad cuts out, a single high thin tone, bells scatter |
| Clockmaker's Automaton (bargaining) | steady gear ticks speed up into a brass hit | the ticks halt on a held chord (the offered pause), then resume | ticks go irregular, steam hiss, a cracked brass note |
| Star Choir's Echo (anger) | a held vocal note answered by its echo | a second voice enters a fifth above, echo doubles | all three voices on one chord, sharp and loud, then a cut |
| Hollow Court Regent (sorrow) | the bell tolls twice, low strings under it | the bell tolls faster, one candle-flicker pluck per candle | the bell slows, strings thin to one violin, a last toll |
| The Clockmaker (acceptance) | a slow single tick, a deep clock chime | the tick stops mid-beat (time stop), a long breath | the ticks run backwards (reversed sample), then forward again on a major chord |

Notes: write the stings in the stage set's key so they sit on the music; keep each under 5 seconds and mono-compatible; the Clockmaker's last sting must resolve (the ending is `[ THE CLOCK TURNS ]`). Make them with the project's synthesis scripts (`VFX/sfx/make_sfx.py` style) or a composer; not done. Not wired: no sting IDs, no trigger code.
