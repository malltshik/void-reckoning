# Chapter 1 - Canon & Lore

> **Disclaimer.** This is canon, not script. The cart's text is terse, lowercased, and
> will **not** match this prose 1:1. Treat this file as the authority for *world, conflict,
> characters, tone, and story beats*; the cart/`ch01.p8` is the authority for *what the
> player actually reads on screen*. If they disagree, the cart wins and this file is
> updated to match. Build the story along the way - do not treat any line here as a
> verbatim string to paste into the game.

Chapter 1 covers **the sending, the thaw, and the first system** - ending the moment the
player fits a hyper-cell, opens the jump gate, and leaves the first system behind.

---

## Tone

Dark, cold science fiction in the register of Bradbury and the Strugatskys - quiet dread,
bureaucratic cruelty, a machine that files people away without ever raising its voice. The
horror is administrative, not monstrous. Nobody in this story thinks they are a villain;
they think they are keeping the lights on.

Rendering stays abstract (PICO-8, primitives, hard edges). The implication does the work.

---

## The world

**The Imperium.** Not a mustache-twirling empire - a *machine*. Roughly the top five percent
live on nearly all of the resources, most of them never asking where dinner comes from. The
rest of known space labors for it: asteroid mining farms, toxic-world harvesting, contract
labor that everyone politely does not call slavery. Its operating principle is **optimize**:
survive, keep the lights on upstairs, and when a population becomes an expense, strike it
from the ledger. Its word for people it has decided not to feed is **bio-social
contamination** - a thing to be *resolved*, which is to say, erased.

**Known space** is a linear corridor of **ten systems**, running from the deep frontier
(Ch1) inward to the Imperium core (Ch10). Progression is linear - you are always moving
inward, against the flow.

**The frontier (Ch1's system).** The wormhole dumped 1393 at the corridor's isolated outer
edge - officially "contaminated / enemy space," where the Imperium assumes no one survives.
That is the point: it is the Imperium's favored disposal route. A star system gone to seed:
a few planets hanging in the dark, a belt of ragged stone, an old mining outpost blinking a
slow, tired light. No traffic, no patrol, no comforting grid of Imperium beacons stamping
order onto the dark. Just **the system disc** - and past its soft edge, **dead space**:
empty, silent, and (for a ship with no fuel) final.

**The Resistance.** The wronged, fighting for rights and resources. A legitimate cause with
its own compromises. It has not appeared yet in Ch1 - its first contact is Kesh, in Ch3.
What Ch1 plants is only the *seed* of the break: the first hairline crack in 1393's belief.

---

## The conflict (as it will matter)

The pilot believes he is an Imperium man on an important, secret mission. He is actually a
**line item** - a man the Imperium classified as disposable and routed through a wormhole
whose collapse warning was scrubbed from the chart. The whole story is the slow, irreversible
collapse of that belief into knowledge, and then into a choice.

Ch1 is the *before*: the mission is still real, the Imperium is still home, and he is still
obedient. Everything in this chapter plays straight. The rot is only visible at the edges -
the scrubbed chart he does not yet understand, the officer who looks away in fear, the word
printed on a wall he cannot read.

**Structural twists (locked, revealed later):**
- **Twist 1 (end of Part I, Ch3):** the sealed crate is **empty**. There was never cargo,
  never a delivery, never a recipient - only a courier nobody would miss, sent to die.
- **Twist 2 (Ch6):** the full truth - no mission, no cargo; he was classified *bio-social
  contamination*. He was never meant to come home.

Neither is revealed in Ch1. In Ch1 the crate is simply **sealed**, and he does not open it.

---

## Cast

- **Pilot 1393** - the protagonist. No name, only a number, because to the Imperium he is
  inventory. Twenty-three. Imperial courier's gray. Chosen from eleven thousand candidates
  for this run, and made to feel special about it. Trained to resist capture, to lie under
  interrogation, to swallow the pill. Believes in the mission. **Arc (whole game):**
  believing servant -> witness -> defector. In Ch1 he is entirely the first.
- **Commander Rooke** - Imperial intelligence officer; the personal, patient face of the
  empire's cynicism. A narrow man with kind eyes who files other people's lives in a small
  book. He grooms and dispatches 1393 with genuine warmth, which is the worst part. *He
  always knew.* Recurs later; dies off-page before the end (an "accounting error," filed
  under N/A).
- **The outpost officer** - the unglamorous survivor running the mining outpost in Ch1's
  system. Sees the courier's uniform and understands it is a death sentence out here. Was
  maybe Imperium once, or just pragmatic. Explains where 1393 is, that his comms are dead
  and his hyper-cell is shot, and trades him a spare cell for ore - "I never saw you."
  (Reuses portrait 2's art in the cart.)
- **The Imperium** - see *The world*. The real antagonist of the story; Vane is only its
  face.
- **Kesh / Lyra / Vane** - not in Ch1. Kesh (Resistance agent) first hails in Ch3; Lyra
  (Resistance commander) becomes his commander in Part III; General Vane is the final
  antagonist (the Paragon, Ch10).

---

## Chapter 1 - as it happens (canon)

1. **The sending.** The room they gave him had no windows - windows are a thing you earn.
   It had a table, two chairs, and a wall pretending to be a window: a screen showing the
   capital at a slow, tasteful dusk. Rooke comes in and briefs him: a top-secret delivery.
   The cargo is sealed. He will not open it, will not ask what it is. He will carry it to
   the coordinates in his flight plan and hand it over. Serve the Imperium well, and it will
   remember you.

   *In-cart:* the cold open is Rooke's dialogue. It begins with four portrait-less narrator
   lines carrying the Central Command briefing - `IMPERIUM CENTRAL COMMAND` / `COURIER 1393 -
   BRIEFING` / `ASSET: SEALED` / `DESTINATION: BR-11K0` - then shows Rooke's face. There is
   no separate briefing screen; it lives in `talks.intro`.

2. **The jump.** He climbs in, straps in, and engages the drive - and the stars do not move
   the way stars move. The flight plan led through a jump he was assured was charted, safe,
   routine. He is never told, and does not yet discover, that the same coordinates were
   flagged fourteen years earlier as a collapse hazard and that someone scrubbed the warning.

   *In-cart:* a fly-into-the-wormhole cutscene, then a wormhole-tunnel animation.

3. **The thaw.** He wakes to a field of red console warnings - wormhole drift, navigation
   data corrupted, hyper-cell damaged. The system disc is outside his viewport: wrong
   colours, everything too far apart, no traffic, no patrol. He is, he understands, somewhere
   else. The primary directive still glows on the console: deliver the sealed asset to
   BR-11K0. He lectures himself that it is a clerical error, and gets to work.

   *In-cart:* a corrupted-terminal page (`> critical: wormhole collision` /
   `> navigation data corrupted` / `> hyper-cell damaged`), then he is dropped into the
   flown system disc. Past the soft edge of the disc is blinking-alert **dead space** with
   nothing in it - empty forever.

4. **The outpost.** To get anywhere he needs a **hyper-cell** (a jump key); his is shot, his
   comms are dead. The only place out here that will deal with him is an old mining outpost.
   On the first dock the **outpost officer** hails him - the uniform is a death sentence in
   this system, but the officer trades rather than shoots. Break the white rocks, sell the
   ore, and the officer will fit a spare cell; then take the jump gate and get out.

   *In-cart:* the mission pane reads "no active orders. hail the outpost." until this hail
   (`ohint=false`). The officer dialogue sets `ohint=true` / `qs=1`.

5. **The work.** He mines. The white rocks carry ore; raiders and scavengers come for his
   ship in the dark between them. Sell ore (10 per unit) at the outpost, repair, refuel,
   survive. The cell costs **250** - roughly **25 ore**, or **20 ore plus five pirate kills**;
   he starts with only **40**. He must both salvage *and* fight.

   *In-cart:* cargo cap 10; scout bounty 15; ore sells at 10; the grind is deliberate (the
   cell must feel earned, not handed over).

6. **The gate.** With the hyper-cell fitted, he flies to the **jump gate** and opens it. The
   gate folds shut behind him. The system is gone - no patrol, no hunter. But this is not his
   destination, only the far side of a doorway. The crate waits. The coordinates do not.

   *In-cart:* a warp cutscene; it holds on its last narration line and waits for `X
   continue`. Then "Chapter 1 complete."

The crate is **still sealed** when he leaves. He has not opened it. He still believes.

---

## Open threads carried into Chapter 2

- **The sealed crate.** Unopened, bolted to the deck, marked BR-11K0. (Empty - Twist 1,
  Ch3.)
- **The scrubbed chart.** 1393 has not yet connected the wormhole to a deliberate disposal.
- **The destination.** BR-11K0's coordinates are corrupted and a course cannot be plotted.
  Where he is actually going is unknown to him.
- **The crack.** The first hairline fracture in his belief - the officer's fear, the wrong
  colours, the dead comms - has been placed. It widens from here.
- **Contacts not yet made.** Kesh (Ch3 hail), Lyra (later), the Imperium proper (Ch4+).

---

## See also

- Chapter 2 canon bible: [`../ch02/lore.md`](../ch02/lore.md)
- Full design & mechanics: [`../../DESIGN.md`](../../DESIGN.md)
- Engine/session guide: [`../../AGENTS.md`](../../AGENTS.md)
