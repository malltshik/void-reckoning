# AGENTS.md - Chapter 2 (XR-7PO)

Read the repo-root `AGENTS.md` first (engine, chapter contract, PICO-8 gotchas, tooling).
Story canon/tone: `chapters/ch02/lore.md` (the cart's text is authoritative).

**Status: playable pure-combat slice, original script.** The author's canon may still describe
an earlier plan (Kaelus Prime, negotiation); the built chapter is XR-7PO. Negotiator engine is
not included (no `negs`).

- **Cart budget:** 8025 / 8192 tokens (167 free), ~41.6k chars. No `50_negotiation.lua` include
  (~378 tokens saved). Measure with `p8check tokens ch02`.
- **Verification:** `p8check all ch02` = tokens + smoke (35+ assertions) + 14 staged screens
  (`tmp/shots/ch02_*.png`) with a text-clipping sweep.

## Source layout

```
chapters/ch02/ch02.p8             cart: includes (00..40, 60, then src/70-73) + gfx/label/map/sfx/music
chapters/ch02/src/70_world.lua    CHAPTER, tunables, foes_def + FOE_POOL, ch_stations, ch_foes, objective, draw_stations
chapters/ch02/src/71_station.lua  docking, LOCAL INDEX + SLICE TERMINAL, recover override (keeps fragments)
chapters/ch02/src/72_story.lua    talks (arrive/hail/archive/slice), mission/inventory, story flow, start_jump, jlines, jump_end
chapters/ch02/src/73_combat.lua   engine overrides: hit_foe / update_drops (fragments, salvage, the reaver trigger)
chapters/ch02/tests/smoke.lua     logic playthrough      chapters/ch02/tests/shots.lua  staged screens
```

## Flow as built

1. **Arrival** (state 1): `arrive` (narration + pilot) -> `hail` (scavenger picket demands the hold)
   -> flight. There is no cutscene page; `update_story` handles only `dlg` pages.
2. **Hunt** (`qs=1`): kill the swarm for **navigation fragments**. The radar compass points at the
   nearest drone. Waves use the engine's `update_spawn` with Ch2's aggressive globals
   (`FOE_CAP=10`, spawn every 5-10 s, 3-5 ships). No ore, no trade: `p.credits=0`, `p.mcargo=24`
   and `p.ore` is the fragment count (the HUD `CG` bar fills to 24).
3. **The reaver** (`qs<3`, 23 fragments): `update_drops` spawns one `reaver` (militia sprite, 240
   HP + 140 shield, 3-shot salvo) and shows `THE REAVER WAKES`. Its death drops the 24th fragment.
4. **Key complete** (`qs=3`): picking up the 24th sets the stage; the compass points at the archive.
5. **Slice** (state 4, archive at 392,128): first dock plays `archive` (sets `ohint`); the menu has
   **LOCAL INDEX** (fragment count) and, at `qs>=3`, **SLICE TERMINAL**. The slice dialogue ends ->
   `qs=4`, `NAV KEY REBUILT` (refuses a second slice).
6. **Jump** (gate at 136,392): `start_jump` needs `qs>=4`; the engine warp plays `jlines`;
   `jump_end()` calls `load("ch03")` (falls back to the title if absent).

## Rules implemented as chapter overrides (why / how to change)

The engine stays generic; XR-7PO's rule differences live in `73_combat.lua` and `71_station.lua`
(globals resolved at call time, so the later definition wins; the harness stubs by name):

| Override | Why | Change it here |
| --- | --- | --- |
| `hit_foe` | kills drop a fragment until 23 (the reaver holds the last) + a 35% salvage canister; **no bounty** | `73_combat.lua` |
| `update_drops` | fragment (2) / fuel (1,3) / missiles (4) / hull (5) pickups, and the per-frame reaver trigger | `73_combat.lua` |
| `recover` | death **keeps the fragments** (they are the progress) and refits for free; there is no money | `71_station.lua` |

Engine features this chapter drives with **data** (not overrides): per-kind enemy volley
`foes_def.n` (lancer/reaver fire 3 in a fan), drop colour `drop.c` (fragment blue 12, salvage
white 7, asteroid ore keeps the blink), wave pacing via `FOE_CAP`/`SPAWN_*`/`WAVE_*` globals,
and `p.mcargo=RELIC_GOAL` (the HUD bar). `hit_roid` is the engine's: asteroid wrecks drop `kind=1`,
which `update_drops` reads as a fuel cell.

## Balance / tunables (`70_world.lua` unless noted)

- `RELIC_GOAL=24`; waves 3-5, `FOE_CAP=10`, spawn 300-600 frames. Interceptor: 30 HP, fast
  (bs 3.0). Lancer: 60/30, 3-shot fan (bs 3.4). Reaver: 240/140, slow, 3-shot fan.
- Salvage from kills: 35%; from asteroids: the engine always drops one (read as fuel).
  Fuel cell +30, missiles +2, hull +25.
- `p.credits=0`, no bounty, no services; death is free and keeps fragments.
- Numbers are first-pass; **feel and difficulty are the user's call** (playtest).

## UI geometry (so edits don't clip)

- Station: title y8, `fragments n/24` y18 (blue 12), menu items from y26 step 11 (`LOCAL INDEX`,
  `SLICE TERMINAL`), prompt y112. `menu_show` status text is wrapped to 2 lines at y92.
- Flight: dock/jump prompt y105, message bar y114+, radar bottom right; drops are 5x5 squares.
- Warp narration `jlines` are <= 31 chars; the shots sweep fails on any string off-screen.

## Tests / future

- Smoke covers: fragments from kills (no bounty), pickup, fuel cells, no fragments from rocks,
  the reaver at 23, the 24th from the reaver, the 3-shot volley, the slice (and its stale-second-use
  refusal), death keeping fragments, the locked/unlocked gate, and seed-reproducible layouts.
- **Not done:** carrying fragments/credits between chapters; a real `.p8.png` label; audio.
- If a later chapter needs the same drop/boss plumbing, consider adding generic engine hooks
  (the current overrides duplicate a little engine logic by design - see root AGENTS section 4).
