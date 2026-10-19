# VOID RECKONING — Design Document

> Top-down space action-RPG for PICO-8. A bonded courier is sent to die, discovers the
> empire that owns him is built on slavery and genocide, and chooses a side.
> Cold, dark, and explicit about what an empire costs.

**Status:** design locked (post-grilling). Target: build the Ch1–3 vertical slice, then Parts II–III.
**Story canon:** per-chapter `chapters/<ch>/lore.md` (Ch1 written, Ch2 WIP). It holds the story, world, and characters as prose/canon — **not** verbatim script; the cart's on-screen text is authoritative. Align narrative work to it.

---

## 0. Release plan (three parts)

| Part | Chapters | Content | Ends on |
| :-- | :-- | :-- | :-- |
| **I — Demo** | 1–3 | The sending, the thaw, the Imperium forward base, the empty crate | Twist 1 (the crate is empty) + first Resistance contact |
| **II — The Doubting Episode** | 4–6 | Dirty orders, the road to **BR-11K0**, the dead world, the moral break | The Ch6 fork: defect, or die loyal |
| **III — The Reckoning** | 7–10 | Joining the Resistance; the war back to the Imperium core | The Paragon / General Vane |

Everything below is the full 10-chapter design; Part I is the build target first.

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
  font — in `__map__`, not in code. See AGENTS §12.)
- Author in `#include` chunks; **each chapter ships as its own cart** (`.p8.png` flattens includes).

---

## 3. World & space model

- **Known space is a linear corridor of 10 systems** (1 chapter = 1 system), running from the
  deep frontier (Ch1) inward to the Imperium core (Ch10). Progression is linear.
- **The wormhole** dumped 1393 at the corridor's isolated edge — officially "contaminated /
  enemy space," where the Imperium assumes no one survives (its favored disposal route).
  "No escape" is Imperium framing; deeper passage needs clearance/keys the story provides.
- **In-system space:** a flown field (~640×640) with a **scrolling camera** and an
  off-screen **radar/minimap**. Generous room to fight, hide behind planets, and dodge hazards.
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

## 5. Flight & combat (baseline values, tunable)

Rotation + thrust with inertia; **forward-firing**, 16 rotation angles; homing missiles secondary.
Depth comes from enemy behavior and hazards, not input complexity.

| Constant | Value |
| :-- | :-- |
| Player acceleration (`acc`) | 0.12 px/frame |
| Player max velocity (`max_vel`) | 2.5 px/frame |
| Friction/drag | 0.96 × per frame |
| Rotation speed | 0.08 rad/frame (16 vectors) |
| Missile acceleration | 0.25 px/frame |
| Missile turn rate | 0.04 rad/frame (homes nearest target) |
| Asteroid impact damage | `ceil(size × velocity × 1.5)` |
| Map wrap | optional; camera scrolls a ~640×640 field |

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

---

## 7. Failure, death & fuel

- **On death:** respawn at the last docked station; lose the **cargo hold** + a **recovery fee**
  (~20–25% of credits, or a flat scaled cost); **keep** upgrades and story progress.
  Bad fights and bad choices cost money and time — never the story.
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
  *not* affordable on start cash — the player must salvage **and** fight. Patrols are **rare** (a
  foe roughly every 20–30s, max 4 alive) so exploration is calm. Asteroids are solid
  (`ROID_CAP=22`) and **top back up over time** (`ROID_RESPAWN=150`); missiles damage them.
  Values live in `ECO` (`50_station.lua`) and `foes_def`/`FOE_CAP` (`10_entities.lua`).
  *(2026-10-19: cargo 3→10, ore sell 30→10, cell 150→250 — the cell must be a real grind, not a
  short hop.)*
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

---

## 10. Chapter blueprint

**Twists:** **Twist 1 (Ch3)** — the sealed cargo is empty. **Twist 2 (Ch6)** — the full truth
(no mission, no cargo; you were classified *bio-social contamination*).
**Fork (Ch6):** join the Resistance → Ch7–10; stay loyal → game over.

| Ch | System (working name) | Role | Beat |
| :-- | :-- | :-- | :-- |
| **1** | Vector-Alpha | Thaw | Wake adrift post-wormhole; ship AI restates the mission. Tutorial: fly, salvage fuel, first skirmish, dock. Nav data corrupted → hop toward the relay. |
| **2** | Kaelus Prime | The Imperium's face | Check in as a courier; they're shocked you live. Run a job for clearance + gate key. First negotiation set-piece; first glimpse of casual cruelty (labor crews, a "reassignment" = death sentence). |
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

---

## 13. Technical architecture

**States:** `0 Title · 1 Prologue/Cutscene · 2 Flight · 3 Comms (overlay, pauses flight) ·
4 Station · 5 Jump/Route · 6 Game Over · 7 Ending`.

**Entity model:** flat pooled tables with swap-remove; overflow-safe distance collision (axis-guard
before squaring — see AGENTS.md gotcha: 16.16 fixed point overflows past ~181px); no spatial hash.
Soft caps: **~12 enemies, ~24 asteroids, ~64 projectiles, ~16 pickups** live; Paragon = 4 pinned
sprites + sub-hits. Off-screen sim culled; hazards on timers.

**Token budget (8,192 target):**

| System | ~Tokens |
| :-- | --: |
| Core / init / state machine | 400 |
| Player physics, input, camera | 450 |
| Entity system, collision, pooling | 700 |
| Enemy AI (5 archetypes) | 900 |
| Weapons / projectiles / missiles / ECM | 650 |
| World generation + hazards | 550 |
| Station & economy menus | 900 |
| Dialogue engine (parse, typewriter, choices) | 450 |
| Negotiation engine (leverage, timer, disposition) | 700 |
| UI / HUD / radar | 600 |
| Story flow, quests, cutscenes | 900 |
| Final boss (3 phases) | 700 |
| Music/SFX drivers | 150 |
| Title / pause / route menus | 350 |
| **Reserve** | **692** |

Reserve **~22–25k of the 65,535 chars** for dialogue/narration (~2–2.5k chars/chapter, punchy register).

**Source layout & build:**

```
common/src/00_core.lua      # init, state machine, input, state dispatch
common/src/01_font.lua      # custom title font (memcpy from __map__ -> 0x5600)
common/src/10_entities.lua  # pools, collision, spawn
common/src/20_world.lua     # system gen, camera, flight drawing
common/src/30_combat.lua    # weapons, projectiles, missiles
common/src/40_ui.lua        # HUD, menus, text/typewriter
common/src/60_dialogue.lua  # pipe-string parse, dialogue engine
common/tools/gen_gfx.py     # art -> __gfx__  (gen_audio.py -> __sfx__/__music__; gen_fontmap.py -> __map__)
chapters/ch01/ch01.p8       # thin cart: #include lines + gfx/label/map/sfx/music data
chapters/ch01/src/50_station.lua  # dock services, economy
chapters/ch01/src/70_story.lua    # chapter flow, quests, cutscenes
chapters/ch01/src/80_boss.lua     # Paragon (Ch10 stub)
docs/  build_web.ps1              # GitHub Pages web player (one per chapter)
tmp/                              # gitignored local scratch (research, test harnesses)
DESIGN.md  AGENTS.md  chapters/<ch>/lore.md
```

One cart **per chapter** (each its own 8192-token budget); `#include` resolves relative to
the cart file's folder, so the Ch1 cart uses `../../common/src/...` + `src/...`.

Ship via `EXPORT`/`SAVE` to `.p8.png` (includes flatten automatically), and to a browser
player via `build_web.ps1` (site in `docs/`). All code lowercase, PICO-8 conventions, no
external libs.

**Save (`cartdata`):** pack into the 64 numeric slots — current chapter, branch flag, credits,
missile count, upgrade tiers (3 small ints), quest_step, a story-flags bitfield, and a
seen-dialogue bitset. Version-tag the save.

**Test loop:** I run `pico8 -x chapters\ch01\ch01.p8` headless to catch syntax/runtime errors and read
`printh` diagnostics; the user runs interactive playtests and reports. Token/char counts verified in
PICO-8's editor / at export.

---

## 14. Open / provisional items

- Working names (Rooke, Kesh) and Ch4–10 system names are provisional.
- All numeric baselines (physics, prices, enemy stats, rewards) are tunable during playtest.
- Whether shop stock is hard era-gated or purely cost-gated: leaning **both** (stock era-gated, cost throttles).
- Negotiation engine data format details to be finalized when implementation begins.
