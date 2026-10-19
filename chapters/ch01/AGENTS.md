# AGENTS.md - Chapter 1 (Courier 1393)

**Read the repo-root `AGENTS.md` first** - it holds the engine, architecture, conventions,
PICO-8 gotchas and shared rules. This file carries only what is **specific to Chapter 1**,
so work on later chapters isn't burdened by it. Story canon: `chapters/ch01/lore.md`.

- **Cart budget:** ~8145 / 8192 tokens (~47 free) at last measure - very tight; trim before
  adding. Each chapter is its own cart with its own 8192 budget (root `AGENTS.md` §7/§12).
- **Source layout:**
  ```
  chapters/ch01/ch01.p8            cart (#include + __gfx__/__label__/__map__/__sfx__/__music__)
  chapters/ch01/src/50_station.lua docking, services menu, economy actions (ECO table)
  chapters/ch01/src/70_story.lua   chapter flow, cutscenes, quest logic, jump sequence
  chapters/ch01/src/80_boss.lua    The Paragon (Ch10) - stub
  ```

## Chapter 1 as built

- Cold-open: **Rooke dialogue** - it opens with 4 narrator lines (no portrait drawn,
  `NN={w=0}`) carrying the Central Command briefing (`IMPERIUM CENTRAL COMMAND` /
  `COURIER 1393 - BRIEFING` / `ASSET: SEALED` / `DESTINATION: BR-11K0`), then Rooke's face
  -> **flight-into-wormhole cutscene** (ship races across space, is swallowed by the
  'hole) -> wormhole tunnel -> corrupted-terminal page -> you wake adrift in a **system
  disc**; fly past its soft edge and you enter empty **dead space** (blinking alert, no
  spawns) forever. There is **no separate briefing screen** - it lives in `talks.intro`.
- On the first Outpost dock the **outpost officer** hails you (reuses portrait 2 art);
  until then the mission pane reads "no active orders. hail the outpost." (`ohint=false`).
  The officer sets `ohint=true` / `qs=1` and points you at the work.
- Mine ore -> dock Outpost -> SELL ORE (first sale sets `qs=2`) -> buy Hyper-Cell
  (**250 $**, sets `qs=3`) -> fly to Jump Gate -> `X` -> **warp cutscene** (radial streaks
  + 7 centred narration lines revealed `JPER=45` frames each). It **holds on the last
  line and shows `X continue`** - it never auto-advances (`X` skips the reveal first) ->
  "Chapter 1 complete".
- Economy (start **40 $**, cell deliberately unaffordable): `ECO={oresell=10, cell=250,
  repair=2, fuel=1, missile=15}`; scout bounty 15; **cargo cap `p.mcargo=10`**. Target:
  **~25 ore (2.5 cargos) OR ~20 ore + 5 pirate kills ~= the cell**, plus fuel/repair.
  Tunables in `ECO` (`50_station.lua`) + `foes_def` (`10_entities.lua`).
- Foes: only `E_SCOUT` spawns here (`foes_def` trimmed to scout; later chapters re-add).
  Authored Outpost (`150,110`) + Jump Gate (`400,400`); seeded planets/roids
  (`ROID_CAP=22`, `ROID_RESPAWN=150` - solid rocks top back up over time); missiles now
  damage solid rocks.
- **Reinforcements**: `update_spawn` spawns a scout 150-210px off the player every ~20-30s
  (`FOE_CAP=4` live), so exploring stays calm. `spawnt` is the timer.
- Quest stages (`qs`): `1` salvage -> `2` sell -> `3` jump unlocked.
- Station screen: status strip under the title (`$`@10, hull@38, fuel@88); menu items y26
  step 11; `sub`/status text <=2 lines at y92; prompt y112. Ship menu (state 8): status
  line y44, prompt y112.

## Polish pass (2026-10-19)

- **HUD** is full width: `HP/SH` left, `FU/CG` right (bars 42px), with **credits** at the
  right of row 1 and a **missile icon** (green = have rockets, red = empty) + count at the
  right of row 2 (`misicon` in `40_ui.lua`).
- **Save/continue (DESIGN §13):** `save_game`/`load_game` in `00_core.lua` persist
  qs/ohint/credits/ore/missiles to cartdata `vrk1`; saved on dock, on jump, and on ship-menu
  EXIT. The title offers `X continue` / `O new game` when a save exists.
- **Death = setback, not reset (DESIGN §7):** `recover()` respawns at the last dock, wipes
  cargo and takes a 25% credit fee; keep progress. Game-over prompt is `X to recover`.
- Gate prompt now says **jump** (was "dock"); dock/jump radius widened 14 -> 20.
- Station menu gained **BUY MISSILE** (`ECO.missile=15`); solid rocks `hp` 3 -> **12** so a
  charged shot mines faster (bullets pass their damage; missiles do 12).
- Ramming a foe knocks you back with a 30-frame `p.ramt` cooldown (no more per-frame drain).
- `spawn_roid` won't drop a rock on the player; planets keep clear of the two stations.
- Story seeds: terminal adds `nav chart: warning entry erased`; the inventory shows
  `cargo: sealed (br-11k0)`; the officer names br-11k0 and "a word scratched on the wall".
- Flight shows a one-time control hint (`tut`), and the ship rings gold at full charge.
- Dropped for token budget: second enemy (raider), charge meter, dead-space scan side
  objective, hit-flash, station extra art.
