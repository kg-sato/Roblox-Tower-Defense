--!strict
-- Collectible lore fragments (T071): 12 per chapter, five chapters of five stages. Text only; where each one sits on a
-- board and how a find is saved are separate tasks. Source and tone: Roblox Dev/Lore/Lore Fragments.md.

export type Fragment = { id: string, chapter: number, stage: number, kind: string, text: string }

local LoreFragments = {}

LoreFragments.list = {
	{ id = "LF-C1-01", chapter = 1, stage = 1, kind = "tag", text = [==[A paper tag on a lamp bracket: Trim the wick short and the street kind. Lit by hand, as always.]==] },
	{ id = "LF-C1-02", chapter = 1, stage = 1, kind = "sign", text = [==[A shop sign painted over twice. Under the second coat, still legible: Open until the last lamp goes out.]==] },
	{ id = "LF-C1-03", chapter = 1, stage = 2, kind = "note", text = [==[Tamsin's note, pinned to the Seventh Lamp: If it flickers, do not blame the gas. It is the street thinking.]==] },
	{ id = "LF-C1-04", chapter = 1, stage = 2, kind = "inscription", text = [==[Initials scratched around a lamp post, sixty hands deep. The oldest is dated. The newest is only T.]==] },
	{ id = "LF-C1-05", chapter = 1, stage = 2, kind = "ledger", text = [==[A ledger page: Lamp oil bought, forty gallons. Lamp oil sold, none. The shop has not opened since the dusk began.]==] },
	{ id = "LF-C1-06", chapter = 1, stage = 3, kind = "sign", text = [==[A pie-stall chalkboard: Today's pie is yesterday's. Tomorrow's pie, ask again tomorrow. Nobody has.]==] },
	{ id = "LF-C1-07", chapter = 1, stage = 3, kind = "object", text = [==[A button in a jar labelled Very Good Button. Beside it, a smaller jar: Slightly Good Button.]==] },
	{ id = "LF-C1-08", chapter = 1, stage = 3, kind = "object", text = [==[The street clock, hands removed. Whoever did it wrapped them in a handkerchief and left them on the sill.]==] },
	{ id = "LF-C1-09", chapter = 1, stage = 4, kind = "inscription", text = [==[Chalk on the gate post, in many hands: Do not follow the bell. Do not follow the bell. Do not follow the bell.]==] },
	{ id = "LF-C1-10", chapter = 1, stage = 4, kind = "object", text = [==[A shawl hung over the gate, wet through. Its owner is nowhere. It smells faintly of moth and woodsmoke.]==] },
	{ id = "LF-C1-11", chapter = 1, stage = 5, kind = "drawing", text = [==[A child's drawing pinned to a lamp: a tall grey figure with no face, and a small lamp beside it, very bright.]==] },
	{ id = "LF-C1-12", chapter = 1, stage = 5, kind = "inscription", text = [==[Scratched on the cobbles near the boss ground: It learns names. Do not give it yours. Give it a nickname.]==] },
	{ id = "LF-C2-01", chapter = 2, stage = 6, kind = "manifest", text = [==[A shipping manifest: Cargo, brass, forty crates. Destination, tomorrow. The date is the same on every page.]==] },
	{ id = "LF-C2-02", chapter = 2, stage = 6, kind = "sign", text = [==[A tide table pinned to a piling. Every column reads the same: the water will return soon.]==] },
	{ id = "LF-C2-03", chapter = 2, stage = 7, kind = "inscription", text = [==[Painted on a crane arm: The Guild builds it to last. Below, in another hand: Last what?]==] },
	{ id = "LF-C2-04", chapter = 2, stage = 7, kind = "object", text = [==[A chain left to hang. Verdigris has climbed it link by link, as patient as a vine.]==] },
	{ id = "LF-C2-05", chapter = 2, stage = 7, kind = "ledger", text = [==[Bram's timesheet, signed in three inks: Morning, Night, Morning. The shifts never ended, so neither did the pay.]==] },
	{ id = "LF-C2-06", chapter = 2, stage = 8, kind = "message", text = [==[A clockwork crow's undelivered message, one word pressed into brass: Hold.]==] },
	{ id = "LF-C2-07", chapter = 2, stage = 8, kind = "object", text = [==[A brass feather on the quay, warm as if it had just been shed.]==] },
	{ id = "LF-C2-08", chapter = 2, stage = 8, kind = "note", text = [==[On a bare lamp bracket: Stolen. Please return. No questions. Several. Bring tea.]==] },
	{ id = "LF-C2-09", chapter = 2, stage = 9, kind = "object", text = [==[A coat pocket full of stolen wicks, each labelled with the address it came from. He keeps accounts.]==] },
	{ id = "LF-C2-10", chapter = 2, stage = 9, kind = "note", text = [==[A scrap in careful print: I take the lights so the fog cannot. It is not stealing if I mean to give them back.]==] },
	{ id = "LF-C2-11", chapter = 2, stage = 10, kind = "object", text = [==[On the Automaton's crank, a fresh smear of oil. The cloth that left it is still folded on the rail.]==] },
	{ id = "LF-C2-12", chapter = 2, stage = 10, kind = "plate", text = [==[A brass plate riveted inside the Automaton's chest: Standing order, one hour. Hold until relieved. Signed with a flourish.]==] },
	{ id = "LF-C3-01", chapter = 3, stage = 11, kind = "object", text = [==[A candle that burns without wax. Its flame leans toward the lantern, politely, like a guest.]==] },
	{ id = "LF-C3-02", chapter = 3, stage = 11, kind = "book", text = [==[A hymn book open to a blank page, with a pressed flower where the words should be.]==] },
	{ id = "LF-C3-03", chapter = 3, stage = 12, kind = "object", text = [==[Under a white sheet, a statue's hand is just visible. It holds a small brass key.]==] },
	{ id = "LF-C3-04", chapter = 3, stage = 12, kind = "object", text = [==[A hat on the third pew, left by someone who stood to sing and never sat down.]==] },
	{ id = "LF-C3-05", chapter = 3, stage = 12, kind = "note", text = [==[A note tucked in a pew: I was not sad until the cloth went up. Then I was everything.]==] },
	{ id = "LF-C3-06", chapter = 3, stage = 13, kind = "object", text = [==[A child's mitten on the altar step, frosted at the edge. It has been placed, not dropped.]==] },
	{ id = "LF-C3-07", chapter = 3, stage = 13, kind = "object", text = [==[Snow on the altar, indoors. Someone has made a very small snowman and put a candle in its arms.]==] },
	{ id = "LF-C3-08", chapter = 3, stage = 13, kind = "object", text = [==[On the west front, the Gargoyle has been given a scarf. Nobody admits it.]==] },
	{ id = "LF-C3-09", chapter = 3, stage = 14, kind = "object", text = [==[At the statue's feet, a child's lantern, lit. The oil in it has not dropped in forty years.]==] },
	{ id = "LF-C3-10", chapter = 3, stage = 14, kind = "object", text = [==[A pair of small boots by the lantern, dry. The laces are tied in a double bow.]==] },
	{ id = "LF-C3-11", chapter = 3, stage = 14, kind = "inscription", text = [==[Carved under the statue, new and shallow: Run. I will keep it lit. It is the only sentence the weather has not touched.]==] },
	{ id = "LF-C3-12", chapter = 3, stage = 15, kind = "tag", text = [==[The bell rope, tied up with a ribbon. A tag reads: Ring for the quiet. Do not ring for the loud.]==] },
	{ id = "LF-C4-01", chapter = 4, stage = 16, kind = "inscription", text = [==[Rails once ran out of this room. Someone has chalked an arrow on each: This way home.]==] },
	{ id = "LF-C4-02", chapter = 4, stage = 16, kind = "object", text = [==[A mug on the railing, still steaming. The steam rises, hesitates, and goes back into the mug.]==] },
	{ id = "LF-C4-03", chapter = 4, stage = 16, kind = "note", text = [==[A work order on the wall: Bank the furnaces. Keep them warm. I will return before the hour.]==] },
	{ id = "LF-C4-04", chapter = 4, stage = 17, kind = "inscription", text = [==[A Sentinel's helmet on a hook, polished daily. Inside the brim, in pencil: Good lad.]==] },
	{ id = "LF-C4-05", chapter = 4, stage = 17, kind = "log", text = [==[A patrol log in a stiff hand: Rounds complete. Nothing to report. Nothing to report. Nothing to report.]==] },
	{ id = "LF-C4-06", chapter = 4, stage = 17, kind = "object", text = [==[A tin of springs, labelled: Spare, for sentimental reasons.]==] },
	{ id = "LF-C4-07", chapter = 4, stage = 18, kind = "log", text = [==[A tally book in pawprint ink: Visitors, none. Friends, one. Friends, two. Friends, three.]==] },
	{ id = "LF-C4-08", chapter = 4, stage = 18, kind = "note", text = [==[A dog bowl full of bolts, with a note: He is not fussy, but he is particular.]==] },
	{ id = "LF-C4-09", chapter = 4, stage = 19, kind = "object", text = [==[A small coat on a hook beside the cold furnace. The sleeves have been rolled up, as if for work.]==] },
	{ id = "LF-C4-10", chapter = 4, stage = 19, kind = "object", text = [==[A candle stub on a saucer, replaced every Sunday. The saucer is chipped in the same place each time.]==] },
	{ id = "LF-C4-11", chapter = 4, stage = 19, kind = "book", text = [==[A sealed ledger on the shelf. A ribbon marks one page. The seal bears no name, only a gear.]==] },
	{ id = "LF-C4-12", chapter = 4, stage = 20, kind = "object", text = [==[The Foundry bell is gone. Where it hung is a clean rectangle in the soot, the shape of a mourner's hand.]==] },
	{ id = "LF-C5-01", chapter = 5, stage = 21, kind = "object", text = [==[The first step of the stair is worn in the middle, as if climbed by someone who never came down.]==] },
	{ id = "LF-C5-02", chapter = 5, stage = 21, kind = "object", text = [==[A star caught in a bottle on the ground. It is warm and does not complain.]==] },
	{ id = "LF-C5-03", chapter = 5, stage = 21, kind = "inscription", text = [==[Rune writing around the stair. Someone has translated it in pencil: I do not know either.]==] },
	{ id = "LF-C5-04", chapter = 5, stage = 22, kind = "object", text = [==[A mirror leaning on a step. In it, the stair goes down instead of up.]==] },
	{ id = "LF-C5-05", chapter = 5, stage = 22, kind = "drawing", text = [==[Chalk marks of a child's game on the stair: hopscotch squares ending in a small circle labelled Home.]==] },
	{ id = "LF-C5-06", chapter = 5, stage = 22, kind = "object", text = [==[A single grey feather, drifting without a bird, and without falling.]==] },
	{ id = "LF-C5-07", chapter = 5, stage = 23, kind = "object", text = [==[Paw prints that stop at the mirror and continue on the other side, a little larger.]==] },
	{ id = "LF-C5-08", chapter = 5, stage = 23, kind = "object", text = [==[A ribbon of grey cloth tied around a lamp bracket. It is a gift. It is also a leash. It is unclear.]==] },
	{ id = "LF-C5-09", chapter = 5, stage = 23, kind = "note", text = [==[A note in the Choir's hand: We did not mean to end it. We meant to finish it.]==] },
	{ id = "LF-C5-10", chapter = 5, stage = 24, kind = "inscription", text = [==[On the back of the Great Clock, in tiny letters: For her, because she kept the lamps.]==] },
	{ id = "LF-C5-11", chapter = 5, stage = 24, kind = "object", text = [==[A brass key on a string, the twin of the one in the statue's hand. It fits nothing, and everything.]==] },
	{ id = "LF-C5-12", chapter = 5, stage = 25, kind = "plate", text = [==[A blank brass plate beside the clock's centre, left for whoever finishes the sentence.]==] },
} :: { Fragment }

-- Chapter of a stage: stages 1-5 are chapter 1, 6-10 chapter 2, and so on to chapter 5 (stages 21-25). Nil outside 1-25.
function LoreFragments.chapterForStage(stage: number): number?
	local s = math.floor(stage)
	if s < 1 or s > 25 then
		return nil
	end
	return math.ceil(s / 5)
end

function LoreFragments.forStage(stage: number): { Fragment }
	local s = math.floor(stage)
	local found = {}
	for _, f in LoreFragments.list do
		if f.stage == s then
			table.insert(found, f)
		end
	end
	return found
end

function LoreFragments.byId(id: string): Fragment?
	for _, f in LoreFragments.list do
		if f.id == id then
			return f
		end
	end
	return nil
end

function LoreFragments.count(): number
	return #LoreFragments.list
end

return LoreFragments
