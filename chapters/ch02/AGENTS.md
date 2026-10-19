# AGENTS.md - Chapter 2 (XR-7PO)

Read the repo-root `AGENTS.md` first (engine, chapter contract, PICO-8 gotchas, tooling).
Story canon/tone: `chapters/ch02/lore.md` (the cart's text is authoritative).

**Status: playable infiltration slice, original script.** The author's canon may still describe
an earlier plan (Kaelus Prime, negotiation); the built chapter is XR-7PO. Negotiator engine is
not included (no `negs`).

- **Cart budget:** 8147 / 8192 tokens (45 free), ~43.4k chars. No `50_negotiation.lua` include
  (~378 tokens saved). Measure with `p8check tokens ch02`.
- **Verification:** `p8check all ch02` = tokens + smoke (~35 assertions) + 17 staged screens
  (`tmp/shots/ch02_*.png`) with a text-clipping sweep.

## Source layout

```
chapters/ch02/ch02.p8             cart: includes (00..40, 60, then src/70-73) + gfx/label/map/sfx/music
chapters/ch02/src/70_world.lua    CHAPTER, tunables, foes_def, ch_stations (containers), ch_foes, objective, draw_stations
chapters/ch02/src/71_station.lua  docking: containers open the minigame, the archive briefs then auto-cracks, recover
chapters/ch02/src/72_story.lua    the warp-in warp, contact/archive talks, portraits, mission/inventory, start_jump, jump_end
chapters/ch02/src/73_combat.lua   the slicing minigame + overrides: hit_foe (direct salvage), fail/win
chapters/ch02/tests/smoke.lua     logic playthrough      chapters/ch02/tests/shots.lua  staged screens
```

## Flow as built

1. **Warp in** (state 5): a new game replays the Chapter 1 warp-out animation with `JIN` narration
   (recap + the new goal: recover the coordinates, but how is unknown). `X` ends it -> `jump_end`.
2. **Incoming signal** (state 1, `contact`): a beep, then a short hail from a **red resistance
   pilot** (portrait 36) -> flight.
3. **The field**: no opening patrol, no white rocks (`ROID_CAP=0`, `WAVE_MIN=0` - the engine's
   reinforcement loop spawns nothing). Five **sealed relic containers** (fixed positions, stations
   2-6) and the radar compass points at the next one in order.
4. **Slice** (X near a container): the timed terminal minigame - a 6x20 stream of random symbols
   hides exactly one 4-char sequence repeated twice (both copies always sit fully inside one
   20-char row - the window never straddles a line break); arrows move the 4-char window
   (shift 1), `X` takes it (a wrong pick just buzzes), `Z` abandons. `SLICE_T` =
   {3400,2340,1600,1050,600} per container (10x the first, 5x the last, linear). **Success**: the
   container **collapses** (unenterable, dim), +relic floating text, +20 fuel, autosave.
   **Timeout or abandon**: `fail_slice()` - `ALARM`, 3-6 guards spawn (`2+(idx or 4)`, capped 6,
   lancers from idx 3), and a container is **relocated** to a fresh random spot (findable on the
   radar); the archive itself stays put. There is no dock lockout: retry any time, but every
   attempt that ends (timeout or exit) burns the relic once more.
5. **Kill salvage**: `hit_foe` grants fuel +30 / missiles +2 / hull +25 straight off the wreck
   (no drops to chase; the drop system was cut for tokens) and the last kill cools the alarms
   (`GUARDS DOWN`). No bounty, `p.credits=0`.
6. **Crack the code** (archive at 392,128): the first dock plays the short `archive` brief
   (terminal portrait 38); once `qs>=3` the crack starts automatically (the archive has no menu -
   docking IS the crack). The terminal runs the same minigame at `SLICE_T[6]=80` (pure reaction);
   success -> `qs=4`, `COORDINATES RECOVERED`.
7. **Jump** (gate at 136,392): `start_jump` needs `qs>=4`; the engine warp plays `JOUT`;
   `jump_end()` calls `load("ch03")` (falls back to the title if absent).

## Rules implemented as chapter overrides (why / how to change)

The engine stays generic; XR-7PO's rule differences live in `73_combat.lua` and `71_station.lua`
(globals resolved at call time, so the later definition wins; the harness stubs by name):

| Override | Why | Change it here |
| --- | --- | --- |
| `hit_foe` | kills grant fuel/missiles/hull directly (no bounty, no drops); the last kill cools `hot` containers | `73_combat.lua` |
| `recover` | death **keeps the relics** (they are the progress) and refits for free; there is no money | `71_station.lua` |

Engine features driven by **data**: per-kind enemy volley `foes_def.n` (the lancer fires 3 in a
fan), drop colours `drop.c` (unused since the drop system was cut), `ROID_CAP=0` (no white rocks),
`WAVE_MIN=0` (no ambient patrols), `p.mcargo=RELIC_GOAL` (the HUD bar), station `label="slice"`
(the dock prompt). `update_drops`/`hit_roid` stay engine: with no drops and no solid rocks they
are no-ops here.

**Portraits:** the engine's `PORT` table is global, so `talk(id,port)` in `72_story.lua` swaps
`PORT[2]` before `dlg_start` - the red pilot (36, pixels 32,16) and the terminal (38, pixels
48,16) without an engine change. `gen_gfx.py` bakes both 16x16 blocks; 34 (rook) is unused here.

## Balance / tunables

- `RELIC_GOAL=5` (70_world); `SLICE_T={3400,2340,1600,1050,600,400}` and the 40-frame wrong-pick
  penalty (73_combat); guards `2+(idx or 4)` capped 6, lancer chance `idx*0.14`.
- A failed slice no longer locks the container or the terminal: the alarm guards spawn and keep
  hunting you, but you may retry at any time. The salvage is the reason to fight them.
- Container success also grants +20 fuel - the loop stays survivable without ever failing; every
  failed slice costs hull/fuel but the wrecks pay it back. **Feel and difficulty are the user's
  call** (playtest): the last container and the terminal are meant to be near-impossible to read,
  only reaction.
- The archive is the respawn dock (`active`); a failed crack makes it `hot` too, so death during
  guards respawns into the fight.

## UI geometry (so edits don't clip)

- Minigame (state 4 via `draw_mg`): title y8, timer bar y20-24 (blue 12, red 8 under 90 frames),
  stream rows y32..y72 at x24 (20 chars x 4px = 80px wide), window box + white chars, prompt y112.
- Station: frame 6..121, static text y26/y36, prompt y112.
- Flight: dock/jump prompt y105, message bar y114+ (keep messages <= 32 chars), radar bottom right.
- Warp narration `jlines` (JIN/JOUT) are <= 31 chars; the shots sweep fails on any string off-screen.

## Tests / future

- Smoke covers: the warp-in -> signal -> flight handoff, no patrol/no white rocks, no-bounty
  kills with direct salvage, the stream's unique repeated 4-gram, wrong-pick penalty, the key win,
  the alarm + guards + cool-down, **retrying a container while its guards are up**, the archive
  brief -> auto-crack (hardest timer), Z leaving the minigame, death keeping relics, the
  locked/unlocked gate, seed reproducibility.
- **Not done:** carrying relics/credits between chapters; a real `.p8.png` label; audio; a seamless
  Ch1->Ch2 handoff (the bundle still shows the Ch2 title before the warp-in); persisting the
  per-container `sliced`/`hot` flags (a reload re-arms containers; `p.ore` is saved and capped).
- If a later chapter wants the same minigame, lift `gen_buf`/`update_mg`/`draw_mg` into an engine
  file and keep the chapter hooks thin - it costs ~250 tokens per cart (measure first).
