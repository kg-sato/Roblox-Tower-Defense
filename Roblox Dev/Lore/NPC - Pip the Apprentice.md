# NPC: Pip, the Clockmaker's apprentice (T069)

Status: draft written overnight 2026-10-28. The task asks for "the Clockmaker's apprentice (a friendly voice in the lobby)". Everything below is a proposal. It follows [[Tone Guide]] and [[Character Bible Rules]] and keeps the spoilers of [[The Clockmaker]] intact. The shop NPC is a separate task (T070).

## One design decision to confirm
The Clockmaker's story involves a lost apprentice (see [[The Clockmaker]] and [[Chapter 4 - Clockwork Foundry]]). To avoid giving that away in the lobby, Pip is **a younger, later apprentice**: Ysolde Marrow took Pip on years after the Foundry night and left the Lane before the clock stopped, so Pip does not know the full story and is cheerful. Alternatives for the user: make Pip the Voice in the Lantern (strong twist, changes the lobby tone), or cut the NPC. I recommend the later apprentice.

## Who Pip is
- **Name:** Pip Tallow (short, concrete, easy to say; per [[Naming in whimsical dark fantasy]]).
- **Role:** the lobby guide. Pip answers "what do I do next?" with a hint matched to the player's progress, and does not hand out rewards or sell anything (the server decides rewards; Pip only points).
- **Faction:** Clockwork Guild (apprentice), but friendly to the Keepers.
- **Look:** a small figure in an oversized apron with a pocket full of springs, a loupe pushed up into their hair, and a brass key on a string. Colour: the Guild's verdigris with brass trim and the faction gear glyph ([[Factions]]). Gesture: tightens an invisible screw whenever they think. Flaw: talks too fast when excited and then apologises.
- **Voice (3 words):** bright, earnest, fidgety. Lines are 14 words or fewer.
- **Where:** a workbench beside the lobby lamp. Tap to hear a line; a small lantern-shaped marker shows when Pip has a new hint.

## Behaviour rules
1. Lines are drawn from the pools below by the player's progress (highest stage cleared) and by what they have not tried yet. Each line plays at most once, then the pool rotates ([[Hades voice and lore delivery]]).
2. Pip never states a spoiler from the Clockmaker's arc. Lines about the clock stay at "it stopped one night" and "nobody knows why".
3. No pressure language and no sales; Pip never mentions Robux or purchases.
4. Text only for now; recording notes are later (T098).

## Line pools (36 lines)
| id | pool | text |
|---|---|---|
| PIP-01 | greeting | Oh! A visitor. Mind the springs, they like to wander. |
| PIP-02 | greeting | Hello! The lamp is lit, the kettle is not. Both are my fault. |
| PIP-03 | greeting | You again! I mean, welcome back. I mean both. |
| PIP-04 | greeting | Morning! Well. Dusk. It is always dusk. Hello anyway. |
| PIP-05 | greeting | Shh, listen. No, nothing. Just checking. Welcome! |
| PIP-06 | greeting | Ready for the Lane? I made you a map. It is mostly arrows. |
| PIP-07 | hint, roll | Spend a few coins on a roll. The lantern likes surprises. |
| PIP-08 | hint, merge | Three the same, touching: they become one, and learn more. |
| PIP-09 | hint, placement | Put the little ones near the bend. They see further from corners. |
| PIP-10 | hint, upgrade | Spare coins? Teach a familiar something. They keep it. |
| PIP-11 | hint, skill tree | Have you looked at the tree yet? It is lovely and slightly alive. |
| PIP-12 | hint, daily | Come back tomorrow. The lamp saves a little something for you. |
| PIP-13 | hint, speed | If the wave is slow, the dial by the lantern makes time hurry. |
| PIP-14 | hint, settings | Too bright? Too loud? The gear in the corner fixes both. |
| PIP-15 | chapter 1 | Lampwick Lane is the easy one. Easy-ish. Nobody says easy for long. |
| PIP-16 | chapter 1 | Tamsin at the Seventh Lamp is lovely. Do not call her old. |
| PIP-17 | chapter 1 | The street clock has no hands. I asked. Nobody answered. |
| PIP-18 | chapter 2 | The harbour is next. Bring a coat. The cranes are, ah, noisy. |
| PIP-19 | chapter 2 | Wren in the harbour makes the best repairs. She will not say so. |
| PIP-20 | chapter 2 | A thief takes lamps there. Please say you will bring one back. |
| PIP-21 | chapter 3 | The Cathedral is quiet. Be quiet back, but not too quiet. |
| PIP-22 | chapter 3 | Pell rings the bell for the quiet ones. I like Pell. |
| PIP-23 | chapter 3 | There is a Frostling there. If it follows you, say thank you. |
| PIP-24 | chapter 4 | The Foundry is where my master worked. It is warm. It is also sad. |
| PIP-25 | chapter 4 | The Hound there keeps a tally. He will count you too. |
| PIP-26 | chapter 4 | If you find a small coat on a hook, do not move it. |
| PIP-27 | chapter 5 | The sky is open! Did you see? I did. I cried a little. |
| PIP-28 | chapter 5 | The clock is far up. I am not allowed. I am very curious. |
| PIP-29 | chapter 5 | Whatever happens up there, you were brave to look. |
| PIP-30 | idle | I have been oiling this spring since Tuesday. It has opinions. |
| PIP-31 | idle | Do you ever feel the Lane is listening? No? Only me. Lovely. |
| PIP-32 | idle | If you hear a click, it is the key. It is always the key. |
| PIP-33 | idle | I asked the lamp for a story. It gave me a moth. |
| PIP-34 | farewell | Off you go! Mind the fog. It minds you back. |
| PIP-35 | farewell | Good luck, Keeper. Light the corners first. |
| PIP-36 | farewell | I will be here. I am always here. It is an excellent bench. |

## Checks
- `Overnight/evidence/T069_check.py` checks 36 lines, each 14 words or fewer, no banned words, and that no line names the lost apprentice, the Clockmaker's real name or the motive (a spoiler list of `Ysolde`, `Marrow`, `stopped it`, `apprentice who`). Output in `Overnight/evidence/T069.txt`.
- Voice and the "later apprentice" decision are proposals and UNVERIFIED by the user.

## Open questions for the user
1. Pip as a later apprentice, as the Voice, or cut?
2. Should Pip be the daily-reward giver (the server still decides the reward)?
3. Should Pip be a tappable model in the lobby, or only a portrait in the UI?
