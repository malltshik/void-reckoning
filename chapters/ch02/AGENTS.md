# AGENTS.md - Chapter 2 (XR-7PO)

Read the repo-root `AGENTS.md` first (engine, chapter contract, PICO-8 gotchas, tooling).
Story canon/tone: `chapters/ch02/lore.md` (the cart's text is authoritative).

**Status: playable pure-combat slice, original script.** The author's canon may still describe
an earlier plan (Kaelus Prime, negotiation); the built chapter is XR-7PO. Negotiator engine is
not included (no `negs`).

- **Cart budget:** 8158 / 8192 tokens (34 free), ~42.3k chars. No `50_negotiation.lua` include
  (~378 tokens saved). Measure with `p8check tokens ch02`.
- **Verification:** `p8check all ch02` = tokens + smoke (~40 assertions) + 16 staged screens
  (`tmp/shots/ch02_*.png`) with a text-clipping sweep.

## Source layout

```
chapters/ch02/ch02.p8             cart: includes (00..40, 60, then src/70-73) + gfx/label/map/sfx/music
chapters/ch02/src/70_world.lua    CHAPTER, tunables, foes_def + FOE_POOL, ch_stations, ch_foes, objective, draw_stations
chapters/ch02/src/71_station.lua  docking, LOCAL INDEX + CRACK THE CODE, recover override (keeps relics)
chapters/ch02/src/72_story.lua    the warp-in warp, contact/archive/slice talks, portraits, mission/inventory, start_jump, jump_end
chapters/ch02/src/73_combat.lua   engine overrides: update_spawn (waves + the reaver), hit_foe, update_drops
chapters/ch02/tests/smoke.lua     logic playthrough      chapters/ch02/tests/shots.lua  staged screens
```

## Flow as built

1. **Warp in** (state 5): a new game replays the Chapter 1 warp-out animation with `JIN` narration
   (recap + the new goal: recover the coordinates, but how is unknown). `X` ends it -> `jump_end`.
2. **Incoming signal** (state 1, `contact`): a beep, then a short hail from a **red resistance
   pilot** (`P_RES`, portrait 36) -> flight.
3. **Waves** (`qs=1`): no opening patrol; `update_spawn` (73_combat) spawns a group (3, growing to
   a cap of 7), then a **~8 s salvage break** while the field is clear, then the next wave. Kills
   drop **navigation relics** (blue) + a 35% salvage canister. The radar compass points at the
   nearest drone. No ore, no trade: `p.credits=0`, `p.mcargo=24`, `p.ore` = relic count.
4. **The reaver** (`qs<3`, 23 relics, field clear): one `reaver` (militia sprite, 240 HP + 140
   shield, 3-shot fan) arrives alone and drops the 24th relic.
5. **Set complete** (`qs=3`): the compass points at the archive.
6. **Crack the code** (state 4, archive at 392,128): the first dock plays the short `archive`
   brief (terminal portrait 38); the menu has **LOCAL INDEX** and, at `qs>=3`, **CRACK THE CODE**.
   `qs=4` (refuses a second crack).
7. **Jump** (gate at 136,392): `start_jump` needs `qs>=4`; the engine warp plays `JOUT`;
   `jump_end()` calls `load("ch03")` (falls back to the title if absent).

## Rules implemented as chapter overrides (why / how to change)

The engine stays generic; XR-7PO's rule differences live in `73_combat.lua` and `71_station.lua`
(globals resolved at call time, so the later definition wins; the harness stubs by name):

| Override | Why | Change it here |
| --- | --- | --- |
| `update_spawn` | waves with salvage breaks instead of the engine's trickle; the reaver spawn triggers here (field clear + 23 relics) | `73_combat.lua` |
| `hit_foe` | kills drop a relic until 23 (the reaver holds the last) + a 35% salvage canister; **no bounty** | `73_combat.lua` |
| `update_drops` | relic (2) / fuel (1,3) / missiles (4) / hull (5) pickups | `73_combat.lua` |
| `recover` | death **keeps the relics** (they are the progress) and refits for free; there is no money | `71_station.lua` |

Engine features this chapter drives with **data** (not overrides): per-kind enemy volley
`foes_def.n` (lancer/reaver fire 3 in a fan), drop colour `drop.c` (relic blue 12, salvage white 7,
asteroid ore keeps the blink), and `p.mcargo=RELIC_GOAL` (the HUD bar). `hit_roid` is the engine's:
asteroid wrecks drop `kind=1`, which `update_drops` reads as a fuel cell.

**Portraits:** the engine's `PORT` table is global, so `talk(id,port)` in `72_story.lua` swaps
`PORT[2]` before `dlg_start` - the red pilot (36, pixels 32,16) and the terminal (38, pixels
48,16) without an engine change. `gen_gfx.py` bakes both 16x16 blocks; 34 (rook) is unused here.

## Balance / tunables (`73_combat.lua` unless noted)

- `RELIC_GOAL=24` (70_world). Wave n = `min(2+wave,7)` ships, lancer chance `min(0.1+wave*0.08,0.5)`,
  first wave after `wavet=240` frames, `240`-frame break after each clear. Interceptor: 30 HP, fast
  (bs 3.0). Lancer: 60/30, 3-shot fan (bs 3.4). Reaver: 240/140, slow, 3-shot fan.
- Salvage from kills: 35%; from asteroids: the engine always drops one (read as fuel).
  Fuel cell +30, missiles +2, hull +25.
- `p.credits=0`, no bounty, no services; death is free and keeps relics.
- Numbers are first-pass; **feel and difficulty are the user's call** (playtest).

## UI geometry (so edits don't clip)

- Station: title y8, `relics n/24` y18 (blue 12), menu items from y26 step 11 (`LOCAL INDEX`,
  `CRACK THE CODE`), prompt y112. `menu_show` status text is wrapped to 2 lines at y92.
- Flight: dock/jump prompt y105, message bar y114+ (keep messages <= 32 chars), radar bottom right.
- Warp narration `jlines` (JIN/JOUT) are <= 31 chars; the shots sweep fails on any string off-screen.

## Tests / future

- Smoke covers: the warp-in -> signal -> flight handoff, relics from kills (no bounty), pickup,
  fuel cells, no relics from rocks, wave 1 = 3 + the cleared-break, the reaver at 23, the 24th from
  the reaver, the 3-shot volley, the code crack (and its stale-second-use refusal), death keeping
  relics, the locked/unlocked gate, and seed-reproducible layouts.
- **Not done:** carrying relics/credits between chapters; a real `.p8.png` label; audio; a seamless
  Ch1->Ch2 handoff (the bundle still shows the Ch2 title before the warp-in).
- If a later chapter needs the same wave/drop/boss plumbing, consider generic engine hooks (the
  current overrides duplicate a little engine logic by design - see root AGENTS section 4).
