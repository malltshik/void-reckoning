# VOID RECKONING — Design Document

> Top-down space action-RPG for PICO-8. A bonded courier is sent to die, discovers the
> empire that owns him is built on slavery and genocide, and chooses a side.
> Cold, dark, and explicit about what an empire costs.

**Status:** design locked (post-grilling). Built and released **chapter by chapter** (Ch1–10).
**Story canon:** per-chapter `chapters/<ch>/lore.md` (Ch1 written; Ch2 source text written, canon WIP). It holds the story, world, and characters as prose/canon — **not** verbatim script; the cart's on-screen text is authoritative. Align narrative work to it.

---

## 0. Release plan

Shipped **chapter by chapter**: ten chapters (Ch1–10), each released as it's finished. There
is no pre-declared part structure — chapters stand on their own. Milestones along the way
(story beats at specific chapters):

| Chapter | Beat |
| :-- | :-- |
| 3 | **Twist 1** — the sealed crate is empty; first Resistance contact |
| 6 | **The fork** — defect, or die loyal |
| 10 | **The Paragon / General Vane** — the reckoning |

Everything below is the full 10-chapter design.

---

## 1. Identity & pillars

- **Genre:** top-down space action-RPG; *two-phase hybrid*.
- **Core pillar — challenge in both phases.** Real-time flight/combat and docked
  negotiation are *equally* load-bearing. Botch a negotiation and you can be ambushed
  the moment you undock. Dialogue is a skill system, not a wrapper.
- **Tone:** dark, cold, explicit. The game is about what the Imperium does to people.
  Rendering stays abstract (PICO-8), but the writing and implication go hard.
- **The rule behind every system:** the player should feel *owned* early and *free* late.

---

## 2. Platform & hard constraints

- **Engine:** PICO-8 v0.2.7 (Lua 5.2 / z8lua subset).
- **Hard limits:** 8,192 tokens of code; 65,535 characters; 128×128 display; 4 audio channels; 64 SFX.
- **Token rules:** a word or operator = 1 token; bracket-pairs and strings = 1 token each;
  commas, periods, `local`, `;`, `end`, and comments are free. → All dialogue blocks live in
  pipe-delimited strings (`"A|B|C"`) parsed by one lookup, so a whole chapter of text ≈ 1 token.
- **Compressed-size limit** (<15,360 bytes) applies only to `.p8.png`/`.p8.rom` **and the html
  web-player export**, not `.p8`. (A near-full cart trips it; keep big raw data — e.g. the title
  font — in `__map__`, not in code. See AGENTS §5.)
- Author in `#include` chunks; **each chapter ships as its own cart** (`.p8.png` flattens includes).

---

## 3. World & space model

- **Known space is a linear corridor of 10 systems** (1 chapter = 1 system), running from the
  deep frontier (Ch1) inward to the Imperium core (Ch10). Progression is linear.
- **The wormhole** dumped 1393 at the corridor's isolated edge — officially "contaminated /
  enemy space," where the Imperium assumes no one survives (its favored disposal route).
  "No escape" is Imperium framing; deeper passage needs clearance/keys the story provides.
- **In-system space (as built):** a flown **disc** — a 512×512 grid centred on `ARX,ARY` with a
  soft radius `ARR=380`; past it is empty **dead space** (no spawns; dry fuel there is death).
  The camera keeps the ship screen-centred (no edge clamp) and a round **radar** sits bottom
  right with a compass needle for the current objective. Room to fight, mine, and dodge rocks.
- **World gen = authored skeleton + procedural dressing.**
  - *Authored:* key stations, the plot planet/target, quest beats, spawn intent, hazard type.
  - *Seeded* (`srand(1000+chapter)`): planet positions/radii/palette, asteroid density, background, ambient traffic.
  - Plot reliability stays 100%; art/token cost ≈ 0.

---

## 4. Core loop & progression

- Each system has **one main objective** (delivered on dock via comms; may be combat, negotiation,
  or an environmental challenge) that unlocks the **jump gate**, plus **2–3 optional activities**
  (bounty, mine/salvage, trade, scan) for credits.
- **Docking** = full-screen station menu. **Comms/negotiation** = full-screen panel with portraits
  and choices; light in-flight comms reuse the engine in a smaller window (e.g. the ambush taunt on undock).

---

## 5. Flight & combat (as built; all values tunable)

**Snappy 8-way flight, no inertia drift** (changed from the original rotate-and-thrust baseline
on 2026-10-18 — it plays better on a d-pad): the nose snaps to the input direction, velocity eases
to the target and stops quickly. **Forward-firing**; 8 sprite angles; homing missiles secondary.
Depth comes from enemy behavior and hazards, not input complexity.

| Constant | Value (code) |
| :-- | :-- |
| Player speed | 1.8 px/frame (`update_flight`) |
| Velocity easing | 35% of the gap to target per frame (quick start/stop) |
| Fuel burn | 0.06 per thrust frame |
| Charged cannon | hold X up to `CHGMAX=45` frames → power 1–3; power 3 adds a ±spread pair |
| Missile | launches at 1.5 px/f, +0.1/f up to 3.5; heading lerps 0.1/f toward the nearest foe within 200 px (Manhattan); 40 dmg; 300-frame life |
| Asteroid impact damage | `ceil(size × velocity × 1.5)` + knockback |
| Foe ram | 2 dmg + knockback, 30-frame cooldown |
| World | no wrap; the disc described in §3 |

**Vitals (start):** HP 100/100 · Shield 50/50 (regen 0.10/f, 180-frame delay on hit) ·
Fuel 100/100 (thrust **0.06/f**, doubled 2026-10-19) · Missiles 10/10 · Credits 150 (Ch1 starts at **40 CR** - see §8). Base weapon: L1 Laser (8 dmg, 4.0 vel, 8f cooldown).

---

## 6. Negotiation system (the second pillar)

- **Branching choices, leverage-gated.** Each option has hidden requirements — cash,
  faction reputation, intel gathered, your visible ship power. Success is a real skill+state
  check, not random.
- **Some critical moments are timed** (respond or the NPC walks / turns hostile).
- **Consequences are physical:** failure shifts disposition and can flag you for an
  **ambush on undock** (the fight picks up the negotiation's result).
- **The empty crate is *not* a negotiation** — the reveal is scripted and unavoidable.
  The Resistance agent's contact right after *is* the negotiation, and its outcome sets your
  standing/relationship into Ch4–5.

**As built (2026-10-19):** `common/src/50_negotiation.lua` (state 3; optional include, so a chapter
without `negs` pays nothing). Data: `negs.id={who=2,name="...",start="node",n={...}}`; a node is
`{t=text,o={{t=label,to=node,c=cost}},res=outcome,go=fn,tm=frames,to=timeoutNode}`. Up to three
options, credit-cost leverage (`c`), timed fallback, an outcome code and an on-enter hook.
Consequences are physical through the `ambush` flag: `leave_station()` spends it on undock and calls
the chapter's `ch_ambush()`. No chapter currently uses `negs` (Ch2 had a dockmaster clearance in its
placeholder slice; the built XR-7PO chapter is pure combat), so the subsystem is dormant but ready.
Still future: reputation/intel/disposition gating, and persisting the outcome/ambush across a save.

---

## 7. Failure, death & fuel

- **On death:** respawn at the last docked station; lose the **cargo hold** + a **recovery fee**
  (~20–25% of credits, or a flat scaled cost); **keep** upgrades and story progress.
  Bad fights and bad choices cost money and time — never the story.
  *(2026-10-19: implemented — `recover()` in `00_core.lua`: 25% fee, cargo wiped, respawn at the
  last dock via `active`; the game-over prompt is "X to recover".)*
- **Out of fuel:** you drift, vulnerable — you cannot thrust or fire (gun *or* missiles). In
  system you can still be towed/refuelled at a station; in **dead space, dry fuel is death** (no
  one to hail). *(2026-10-19: implemented — `fuel<=0` inside the disc = adrift + unarmed;
  outside it triggers `ADRIFT IN THE VOID`.)*

---

## 8. Economy & upgrades

- **Single currency: credits (CR).**
  - *Sources:* mission rewards, bounties, salvage (ore/scrap from wrecks & asteroids), light trade
    of a few commodities (Ore, Hyper-Fluid, Medical).
  - *Sinks:* repair, refuel, missiles, upgrades, modules, the odd docking/intel fee.
- **Prices rise in the back half** (Ch1–5 "cheap tier" vs Ch6–10 "war tier"): repair 2→5 CR/HP,
  fuel 1→3 CR/unit, missiles 15→35 CR.
- **Ch1 slice (as built):** start 40 CR; ore sells 10; scout bounty 15; **cargo cap 10**; the
  **Hyper-Cell (jump key) costs 250** (= **25 ore**, or ~**20 ore + 5 pirate kills**) so it is
  *not* affordable on start cash — the player must salvage **and** fight. Reinforcements arrive as
  a **patrol of 3–5** every ~20–30s (max 8 alive as built): loitering is punished, so keep moving.
  Asteroids are solid
  (`ROID_CAP=22`) and **top back up over time** (`ROID_RESPAWN=150`); missiles damage them.
  Values live in `ECO` (`chapters/ch01/src/71_station.lua`), `foes_def`/`FOE_POOL`
  (`chapters/ch01/src/70_world.lua`) and `FOE_CAP`/`WAVE_*`/`SPAWN_*` (`common/src/10_entities.lua`).
  *(2026-10-19: cargo 3→10, ore sell 30→10, cell 150→250 — the cell must be a real grind, not a
  short hop. Station menu sells **missiles at 15 CR**; solid rocks have 12 hp so a charged shot
  mines faster. REPAIR and REFUEL are **partial** — a short wallet buys as many HP/units as it can
  afford (`units=min(need,flr(credits/rate))`), 0 units -> `NOT ENOUGH $`.)*
- **Upgrade pacing rule:** *best-in-slot tier ≈ current chapter − 1 (casual) / chapter (min-maxer)*,
  capped at Tier 4. Shop stock is era-gated; cost is the real throttle.
  (→ End of Ch3 ≈ Tier 2 comfortably, second Tier-2 if you chase content, Tier-3 weapon only with grind.)

**Upgrade matrix (baseline, tunable):**

| Category | Tier | Cost | Spec |
| :-- | :-- | :-- | :-- |
| Weapon | L1 Laser Pulse | free | 8 dmg, 4.0 vel, 8f cd |
| Weapon | L2 Dual Plasma | 250 | twin, 14 dmg, 4.5 vel, 7f cd |
| Weapon | L3 Heavy Proton | 600 | 32 dmg, 5.0 vel, 12f cd, pierce 1 |
| Weapon | L4 Void Disruptor | 1200 | 45 dmg, 6.0 vel, 6f cd, +50% vs shields |
| Hull | L1 Light Alloy | free | HP 100 |
| Hull | L2 Reinforced Plating | 200 | HP 175 |
| Hull | L3 Titanium Matrix | 550 | HP 275 |
| Hull | L4 Void Weave | 1100 | HP 400 |
| Shield | L1 Standard | free | 50, regen .10/f |
| Shield | L2 Deflector | 300 | 100, .18/f |
| Shield | L3 Phase | 700 | 180, .28/f |
| Shield | L4 Zero-Point | 1500 | 300, .45/f; impacts return 2% as fuel |
| Module | Thermal Plating | 350 | −75% radiation/flare damage (needed Ch4) |
| Module | ECM Jammer | 500 | (unlock Ch7) X breaks missile locks, blinds AI 3s, 10s cd |

---

## 9. Enemy roster (baseline)

| ID | Name | HP | Shield | Speed | Weapon | AI | Drop |
| :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- |
| `E_SCOUT` | Pirate Drone | 25 | 0 | 2.0 | Light Laser 5 | circles at 35px, fires /30f | 15–25 CR, 10% missile |
| `E_RAIDER` | Pirate Interceptor | 60 | 30 | 2.2 | Dual Laser 10 | straight strafe runs | 45–70 CR, 25% missile |
| `E_MIL_PATROL` | Military Fighter | 90 | 50 | 2.1 | Pulse Rifle 14 | flanker, holds 40px | 80–120 CR |
| `E_MIL_HEAVY` | Heavy Gunship | 220 | 120 | 1.2 | Heavy Cannon 25 + homing missile /5s | slow pursuit | 200–300 CR, 2 missiles |
| `E_ELITE_SPEC` | Vane Elite Guard | 350 | 200 | 2.4 | Disruptor 30 | fast pursuit; ECM under 20% shield | 450–600 CR |

Enemies read behavior from a shared AI table with per-archetype params (data, not code branches).
*As built (Ch1):* only `scout` exists, in `foes_def` (`chapters/ch01/src/70_world.lua`) — speed 1.0
(not 2.0: it chases on acceleration and circles inside 40 px), range 90, 15 CR bounty, 30%
missile drop. The other archetypes are baselines for later chapters; each chapter defines the
`foes_def` kinds it uses plus a `FOE_POOL` for reinforcements. Sprites for raider (16) and
militia (24) already exist in the sheet.

---

## 10. Chapter blueprint

**Twists:** **Twist 1 (Ch3)** — the sealed cargo is empty. **Twist 2 (Ch6)** — the full truth
(no mission, no cargo; you were classified *bio-social contamination*).
**Fork (Ch6):** join the Resistance → Ch7–10; stay loyal → game over.

| Ch | System (working name) | Role | Beat |
| :-- | :-- | :-- | :-- |
| **1** | Vector-Alpha | Thaw | Wake adrift post-wormhole; ship AI restates the mission. Tutorial: fly, salvage fuel, first skirmish, dock. Nav data corrupted → hop toward the relay. |
| **2** | XR-7PO | The archive's dead face | A stripped Imperium archive. Scavenger picket hails you; kill the swarm for **24 navigation fragments** (the hold carries keys, not ore), the **reaver** wakes at 23 and holds the last, then dock the archive and **slice its terminal** to rebuild the nav key. Pure-combat chapter: no trade, salvage from wrecks. |
| **3** | Oort-Novex | **Twist 1** | After the objective, a quiet beat: break protocol, open the crate — **empty**. A Resistance agent hails you (the demo's big negotiation). You chase the truth; agent gives **BR-11K0**'s true coordinates with a warning. |
| **4** | Helios-9 | Doubt | Radiation frontier; the Imperium's orders turn dirty. Witness the machine up close. |
| **5** | BR-11K0 | **Twist 2** | Reach the dead world: its entire population was exterminated centuries ago to "combat bio-social contamination." You realize *you* are contamination. |
| **6** | Deadzone-X | **The Fork** | Confront the truth and choose. Defect → campaign. Stay loyal → the Imperium disposes of you as a loose end; **game over**. |
| **7** | Shadow Reach | Joining | Resistance haven; refit (ECM). Earn trust. |
| **8** | Crucible-V | Strike back | Sabotage Imperium war industry. |
| **9** | The Abyss | Final prep | Black hole sector; recover what you need for the core run. |
| **10** | Vane's Citadel | **The Reckoning** | The **Paragon**: 3-phase boss (outer turrets → shield pylons + escorts → exposed core overdrive). |

> Ch4–10 system *names* are provisional (carried from the original draft); their roles are locked.

---

## 11. Characters (working names — provisional)

- **Pilot 1393** — the protagonist. *No name, only a number* — because to the Imperium he is
  inventory. Recruited by intelligence for a "vital mission," trained to resist capture, made to
  believe in it. Bonded; his ship and license are Imperium property. He obeys because he has no
  legal existence outside the contract. **Arc:** believing servant → witness → defector.
- **Handler Rooke** — the Imperium intelligence officer who groomed and dispatched 1393; the
  personal face of the empire's cynicism. Appears at the cold open and recurs. *He always knew.*
  (Holds a commander's rank — the "commander" of the opening cutscene.)
- **General Vane** — Imperium high command; architect of the wartime regime and the bio-social
  purges. Distant, untouchable, the final antagonist (the Paragon).
- **Commander Lyra** — Resistance leader. The first agent contact and, later, your commander.
  Believes in the cause; not naive about what a rebellion costs.
- **Agent Kesh** — first Resistance contact (the Ch3 hails). Offers surrender; instead hands you
  BR-11K0's coordinates and a warning.
- **The Imperium** — not a mustache-twirl: a machine. The top ~5% live on ~99% of resources, most
  never asking where it comes from; the rest of known space labors in slavery (asteroid mining
  farms, toxic-world harvesting) or fights back. "Bio-social contamination" is its word for people
  it has decided not to feed. **Motivation:** optimize. Survive. Keep the lights on upstairs.
- **The Resistance** — the wronged, fighting for rights and resources. Legitimate cause; its own
  compromises. **Motivation:** stop being property.

Full dramatization in the chapter canon (`chapters/ch01/lore.md`).

---

## 12. Art & audio

**Art — hybrid, cold and faction-coded.** Vector/primitive rendering for ships, planets, stations,
bullets, FX (zero pixel-art labor, cheap in tokens); a small 8×8 sprite set for UI icons and
negotiation portraits (start as procedural dither-silhouettes; upgrade to real art later).

- **Palette:** near-black/indigo void; **Imperium** = steel blue/cyan/white, hard clean geometry;
  **Resistance** = amber/orange/rust, worn and improvised; **slavery/industry** = sickly greens and grey;
  **hazards** = red/warning. Heavy dithering, hard edges, military-terminal typography.

**Audio — generated chip patterns (placeholder-friendly).**
- Tracks (4-channel, from the 64-SFX budget): *Calm Flight*, *Combat*, *Station*, *Dread/Reveal*, *Ending*.
- SFX list: laser, explosion, thrust, shield hit, hull hit, alarm, comms blip, menu, warp, cargo-open.
- Generated now; the user may compose the **main theme** later (DAW work → transcribed to PICO-8 patterns).
- **Licence:** the shipped placeholder soundtrack is "Pico-8 Tunes Vol. 1" by Gruber & krajzeg and
  the gameplay SFX are Gruber's "Pico-8 SFX Pack!" (both CC BY-NC-SA, **non-commercial**). They must
  be replaced with original/commissioned audio before any paid release (Steam).

---

## 13. Technical architecture

**States:** `0 Title · 1 Prologue/Cutscene · 2 Flight · 3 Comms/negotiation (built 2026-10-19;
no chapter uses it yet) · 4 Station · 5 Jump/Route · 6 Game Over · 7 (reserved, unbuilt) · 8 Ship menu`.

**Entity model:** flat pooled tables with swap-remove; overflow-safe distance collision (axis-guard
before squaring — see AGENTS.md §5: 16.16 fixed point overflows past ~181px); no spatial hash.
Soft caps as built: `FOE_CAP=8` live foes in Ch1 (Ch2 raises it to 10, arriving as
`WAVE_MIN..WAVE_MIN+WAVE_VAR-1` = 3–5 ship patrols), `ROID_CAP=22` solid rocks (+ background rocks), a few
dozen projectiles/particles. Off-screen sim is not culled (the field is small).

**Token budget (hard 8,192 per cart) — reality check.** The original plan was an even split across
systems (flight 450, enemy AI 900, negotiation 700, boss 700, …). As built (2026-10-19), the shared
engine (`common/src`) is **~6.3k tokens** and every chapter cart pays it again, leaving ~1.5–1.8k for
chapter content. Measured: **Ch1 = 8,145 / 8,192 (47 free)**, **Ch2 = 8,003 / 8,192 (189 free)**.
The negotiation engine is `common/src/50_negotiation.lua` at **~378 tokens**, and it is *optional* -
only chapters that define `negs` include it (neither current chapter does, so neither pays for the
second pillar; Ch2 instead redefines the engine's `hit_foe`/`update_drops`/`recover` for its rules).

Consequences for planning: a **boss (~700)** and fancier negotiation features still do not fit next
to the current engine without trimming it, so (a) every engine token saved is paid back in all ten
carts, (b) chapters that don't need a subsystem can leave it out of their `#include` list (e.g. a
cutscene-heavy chapter without full combat, a chapter without negotiation), and (c) new UI should
reuse `menu_*`/`dlg_*` rather than add its own. Measure with `p8check tokens`.
Reserve **~22–25k of the 65,535 chars** for dialogue/narration (Ch1 uses ~40k total).

**Source layout & build:**

```
common/src/00_core.lua      # init, save/load/recover, state machine, helpers, print override
common/src/01_font.lua      # custom title font (memcpy from __map__ -> 0x5600)
common/src/10_entities.lua  # flight sim, foes AI, rocks, drops, particles, damage, camera
common/src/20_world.lua     # load_system (seeded dressing), flight drawing, fade trail, sprites
common/src/30_combat.lua    # weapons, projectiles, missiles, collisions
common/src/40_ui.lua        # text helpers, menus, HUD, radar, title, game over, warp cutscene
common/src/50_negotiation.lua # OPTIONAL docked negotiation (state 3); only chapters using `negs`
common/src/60_dialogue.lua  # portrait dialogue runner, story pages, terminal page (scripts live in the chapter)
common/tools/               # p8check.py (tokens/smoke/shots/export/bundle), shotdiff.py, harness/, gen_*.py
chapters/ch01/ch01.p8       # thin cart: #include lines + gfx/label/map/sfx/music data
chapters/ch01/src/70_world.lua    # stations/foes hooks, enemy roster, station drawing
chapters/ch01/src/71_station.lua  # dock services, economy
chapters/ch01/src/72_story.lua    # dialogue scripts, quests, cutscenes, jump_end + warp text
chapters/ch01/tests/              # smoke.lua + shots.lua drivers for p8check
chapters/ch02/                    # XR-7PO combat slice (world/station/story + 73_combat rule overrides)
docs/  build_web.ps1              # Pages player: index.html shell + <ch>.js per cart
tmp/                              # gitignored local scratch (research, screenshots)
DESIGN.md  AGENTS.md  chapters/<ch>/lore.md  chapters/<ch>/AGENTS.md
```

One cart **per chapter** (each its own 8192-token budget); `#include` resolves relative to
the cart file's folder, so the Ch1 cart uses `../../common/src/...` + `src/...`. The engine/chapter
boundary is the **chapter contract** in `AGENTS.md` §4 — engine code never contains chapter content.

**Shipping = one multicart bundle (built 2026-10-19).** All ten carts ship as a *single* product.
PICO-8's multicart `EXPORT` bundles up to 32 carts and lets each `load()` another as if it were a
local file. `p8check.py bundle` (run by `build_web.ps1`) emits `docs/game.html` + `docs/game.js`
from the comment-stripped sources; the main cart is the pico8 argument and the extras go inside the
`-export` string, using **relative, space-free paths** (an absolute path containing a space breaks
the export). Extras are **include-flattened** first: PICO-8 resolves an extra's `#include`s against
the main cart's folder, so a non-flattened extra would compile the wrong chapter's content. A chapter ends with `jump_end()` → `load("chNN")` (returns `false` if the sibling is
absent, so a lone cart falls back to the title); progress rides the shared `cartdata("vrk1")` id.
`load(name,breadcrumb,param)` passes `param` to the new cart via `stat(6)` (not used yet). Caveats:
multicart is **not** supported on the BBS, headless `-x` does not actually swap carts (only the
exported bundle does), `game.bin` for Steam is not built, and `reload()`/data carts need the file
extension. The per-chapter `<ch>.js` exports + the `docs/` picker stay for dev/preview.
**Blocker for a paid (Steam) release: the current soundtrack is CC BY-NC-SA (non-commercial) — replace
it with original music first.** All code lowercase, PICO-8 conventions, no external libs.

**Save (`cartdata`):** pack into the 64 numeric slots — current chapter, branch flag, credits,
missile count, upgrade tiers (3 small ints), quest_step, a story-flags bitfield, and a
seen-dialogue bitset. Version-tag the save.
*(2026-10-19 Ch1: partial — `save_game`/`load_game` in `00_core.lua` persist chapter (slot 0),
`qs`, `ohint`, credits, ore, missiles (slots 1–5) and a has-save flag (slot 8) to `cartdata("vrk1")`,
saved on dock, jump, recover and ship-menu EXIT; the title offers `X continue` / `O new game`.
Continue always resumes docked at the outpost. Upgrade tiers and the dialogue bitset are still to
come; a cart only continues a save tagged with its own `CHAPTER`.)*
*(2026-10-19 Ch2: slot 6 now stores the run's layout seed. A negotiation's outcome/ambush flag are
**not** persisted — save slots 7/9 were dropped for token budget, so reloading during the ambush
loses it. The per-cart `CHAPTER` gate is still in place: a save continues only in its own cart.
Carrying credits/upgrades into the next chapter and the global "furthest chapter + flags" slot are
still not built; `stat(6)` load-param carry is the intended hook.)*

**Test loop:** `python common/tools/p8check.py all ch01` — exact token count, a scripted headless
playthrough (40+ assertions on the real game logic), and staged screenshots (16 for Ch1, 13 for
Ch2) with a text-clipping sweep (the agent can read the PNGs). The user still does interactive playtests for feel/balance;
audio is untested by tooling. See `AGENTS.md` §7.

---

## 14. Open / provisional items

- Working names (Rooke, Kesh) and Ch4–10 system names are provisional.
- All numeric baselines (physics, prices, enemy stats, rewards) are tunable during playtest.
- Whether shop stock is hard era-gated or purely cost-gated: leaning **both** (stock era-gated, cost throttles).
- ~~Negotiation engine data format details to be finalized when implementation begins.~~
  *(Settled 2026-10-19 and built - see §6 and §13. Remaining: reputation/intel gating and saving
  the outcome/ambush.)*
