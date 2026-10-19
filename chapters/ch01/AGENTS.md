# AGENTS.md - Chapter 1 (Courier 1393)

**Read the repo-root `AGENTS.md` first** - it holds the engine, architecture, chapter
contract, PICO-8 gotchas, tooling and shared rules. This file carries only what is **specific
to Chapter 1**, so work on later chapters isn't burdened by it. Story canon:
`chapters/ch01/lore.md`.

- **Cart budget:** 7981 / 8192 tokens (211 free) at the 2026-10-19 handover - measure with
  `p8check tokens ch01` before and after any change. ~40k / 65k chars. Each chapter is its own
  cart with its own 8192 budget (root `AGENTS.md` section 9). Web export: ~29k chars once comments
  are stripped, ~4.7k compressed bytes under the 15,360 limit (`p8check size ch01`).
- **Verification:** `python common/tools/p8check.py all ch01` = tokens + a 40+-assertion smoke
  playthrough + 17 staged screenshots (`tmp/shots/ch01_*.png`) with a text-clipping sweep.
- **Source layout:**
  ```
  chapters/ch01/ch01.p8             cart: #include list + __gfx__/__label__/__map__/__sfx__/__music__
  chapters/ch01/src/70_world.lua    CHAPTER, foes_def + FOE_POOL, ch_stations/ch_foes, objective, draw_stations
  chapters/ch01/src/71_station.lua  docking, services menu, economy (ECO)
  chapters/ch01/src/72_story.lua    dialogue scripts, mission/inventory text, cutscene flow, warp, ending
  chapters/ch01/tests/smoke.lua     logic playthrough       chapters/ch01/tests/shots.lua  staged screens
  chapters/ch01/lore.md             canon
  ```

## Flow as built

1. **Cold open** (state 1, `spages` in `72_story.lua`): Rooke dialogue (it opens with 4 narrator
   lines, no portrait - the Central Command briefing: `IMPERIUM CENTRAL COMMAND` / `COURIER 1393
   - BRIEFING` / `ASSET: SEALED` / `DESTINATION: BR-11K0`) -> **fly-into-wormhole** cutscene
   (ship races across space into the 'hole, then a white flash) -> **wormhole tunnel** (ship
   spins at the collapsing core) -> corrupted-terminal page -> you wake adrift in a **system
   disc** (flight). Fly past its soft edge and you are in empty **dead space** (blinking alert,
   no spawns) forever. There is no separate briefing screen.
2. **Outpost** (150,110): the first dock triggers the **outpost officer** dialogue (reuses
   portrait 2's art), which sets `ohint=true` / `qs=1`. Until then the mission pane reads "no
   active orders. hail the outpost." Services: REPAIR / REFUEL / SELL ORE / BUY MISSILE / BUY
   HYPER-CELL. Docking autosaves.
3. **Quest stages** (`qs`): `1` salvage -> `2` first ore sale -> `3` hyper-cell fitted (gate
   unlocked). The radar compass needle points at the outpost, then the gate (`objective()`).
4. **Jump Gate** (400,400): `X` -> `GATE LOCKED - FIT A HYPER-CELL` until `qs>=3`, then the
   **warp cutscene** (radial streaks + 8 centred narration lines, `JPER=45` frames each; `X`
   skips the reveal, then holds on `X continue`) -> "CHAPTER 1 COMPLETE" ending -> `X` resets
   to the title and clears the save.

## Economy, enemies, balance (all tunable; mirror DESIGN section 8/9)

- Start **40 $**; `ECO={oresell=10, cell=250, repair=2, fuel=1, missile=15}` (`71_station.lua`);
  scout bounty 15; cargo cap `p.mcargo=10`. The cell is deliberately unaffordable at start:
  target **~25 ore (2.5 cargos) OR ~20 ore + 5 kills**, plus fuel/repair.
- Rocks: `ROID_CAP=22` solid rocks kept topped up (`ROID_RESPAWN=150`), `ROID_HP=12` (a charged
  shot mines fast; missiles do 12). Non-solid dark rocks are background only.
- Foes: only `scout` (`foes_def` in `70_world.lua`; hp 25, speed 1.0, range 90, dmg 5).
  Opening patrol of 2; reinforcements (`update_spawn`) every ~20-30 s, 150-210 px away,
  max `FOE_CAP=4`, none in dead space.
- Homing missile: locks the nearest foe within 200 px (Manhattan), steers its heading directly
  (lerp 0.1/frame) while speed ramps 1.5 -> 3.5 px/frame; 40 dmg to foes, 300-frame life.
  *Tuned only in the headless test (it connects); whether it feels right is a playtest call.*
- Ramming a foe: 2 dmg + knockback, then a 30-frame `p.ramt` cooldown (no per-frame drain).
- Death = setback: `recover()` respawns at the outpost, wipes the cargo, takes a 25% credit
  fee, keeps story progress. Out of fuel in dead space is instant death.
- Save (cartdata `vrk1`): chapter, `qs`, `ohint`, credits, ore, missiles. Written on dock, on
  jump, on recover and on ship-menu EXIT. **Continue always resumes docked at the outpost**
  (hull/fuel/position are not saved).

## UI geometry (so edits don't clip - `p8check shots` fails on any string off-screen)

- Station screen: status strip under the title (`$`@10, hull@34, fuel@84, y18); menu items from
  y26, step 11; `sub` status text <= 2 lines at y92; prompt y112. Ship menu (state 8): status
  line y44, prompt y112. Flight: dock/jump prompt y105, message bar y114+, radar bottom right.
- Plain text is 4 px/char -> max 32 chars per line; warp narration lines are kept <= 31.

## Cut for the token budget (re-add when a chapter has room)

Second enemy (raider - sprites exist in the sheet), charge meter (replaced by the gold ring at
full charge), dead-space scan side objective, hit flash, low-HP/fuel HUD blink, one-time
control hint, extra station art.
