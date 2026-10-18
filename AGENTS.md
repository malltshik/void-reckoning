# AGENTS.md - Void Reckoning

Read this first. It exists so a fresh session can rebuild full context without the
original chat history. When in doubt, this file + `DESIGN.md` are the source of truth for
engine/design; per-chapter story canon lives in `chapters/<ch>/lore.md`.

## 0. THE PRIME DIRECTIVE - LOG EVERY DECISION

Every important decision MUST be written down in this file (or `DESIGN.md`, or the
chapter's `lore.md`) before the session ends. A decision that lives only in chat is lost
forever.

- New design/mechanic decision -> `DESIGN.md`. New world/narrative/canon -> the chapter's
  `chapters/<ch>/lore.md`.
- New technical convention, workaround, gotcha, or tooling fact -> add to
  **Common rules & gotchas** below (keep it rule-shaped, not a changelog).
- Changed your mind? Do not silently overwrite: update the entry and note why (dated).
- If you learned something the hard way, it MUST become an anti-pattern entry here.

Rule of thumb: if a future session would be confused or would redo work without it,
write it down. Prefer one durable rule over ten dated play-by-play lines.

## 1. What this is

**Void Reckoning** - a top-down space action-RPG for **PICO-8** (fantasy console).
Part game, part story. Two equally load-bearing phases: real-time flight/combat and
docked negotiation. Dark sci-fi tone (Bradbury / Strugatsky register).

Full design: `DESIGN.md`. Story canon: per-chapter `chapters/<ch>/lore.md` (Ch1 written,
Ch2 WIP) - lore is canon/tone, NOT verbatim script; the cart is authoritative for text.
Reference-cart teardown / ideas to port: `RESEARCH.md` (+ `research/<cart>/` for
provenance - third-party carts there are study-only, never ship them).

Release in 3 parts:
- **Part I - demo (Ch1-3)**, ends on Twist 1 (the sealed cargo is empty).
- **Part II - doubling (Ch4-6)**.
- **Part III - resistance (Ch7-10)**.

Current status: **Part I, Chapter 1 vertical slice is implemented and passes headless
validation.** Chapters 2-10 and the negotiation layer are not built yet.

## 2. Environment

- OS: **Windows**, shell is **PowerShell 5.1** (no `&&`; use `;` or
  `cmd1; if ($?) { cmd2 }`).
- PICO-8: **v0.2.7** at `C:\Program Files (x86)\PICO-8\pico8.exe`.
- Real Python: `C:\Users\Artem Gavrilov\AppData\Local\Python\bin\python.exe` (the
  `python` alias is the Store stub - use the full path).
- Repo: `C:\Users\Artem Gavrilov\Documents\Code\Void Reckoning`.
  - Git repo with **no commits and no remote**. Intended remote:
    `https://github.com/malltshik/void-reckoning` (not wired). **Never commit/push
    without an explicit request.**
- `grep` tool fails on the huge single-line source HTML
  (`Ripgrep JSON record exceeded 65536 bytes`). Use PowerShell string ops for that file.

## 3. Workflow (non-negotiable)

**Agent builds -> user tests -> agent fixes -> user tests -> ...**

- The agent **cannot see the screen**. Headless tests only catch syntax/runtime errors
  and `printh` values. Visual/feel/balance judgments belong to the user.
- After implementing, hand off with: how to run, the controls, and what to look at.
- Prefer small, testable increments. Verify every increment with the headless harness
  (section 7) before handing off.

## 4. PICO-8 constraints (hard limits)

- **8,192 code tokens**, **65,535 chars**, 128x128 display, 4 audio channels, 64 SFX.
- 16 colors (indices 0-15). Palettes by faction: Imperium steel blue/cyan/white;
  Resistance amber/orange/rust; slavery/industry sickly green/grey; hazards red.
- Token accounting: a word/operator/identifier = 1 token; a bracket-pair `()`/`[]`/`{}`
  and each string literal = 1 token; `,` `.` `local` `end` and comments are free -> long
  pipe-delimited dialogue strings cost ~1 token.
- Compressed-size limit (<15,360 bytes) applies only to `.p8.png`/`.p8.rom`, **not**
  `.p8`.
- `#include` is allowed for authoring; each chapter ships as **its own cart**. Include
  paths resolve **relative to the cart file's folder** (NOT `-root_path`) - section 6.
- Sprite sheet: tiles 0-31 = our ship art, tiles 32-35/48-51 (rows 2-3) = 16x16 dialogue
  portraits (pilot idx 32, rooke idx 34), written by
  `python common/tools/gen_gfx.py <cart>.p8`. The map and the rest of the sheet are
  unused. Colour 0 in sprites is transparent.

## 5. PICO-8 Lua dialect - gotchas (read before writing code)

- Lua 5.2-ish subset (**z8lua**). NOT full Lua.
- **Numbers are 16.16 fixed point, range +-32768.** `d*d` **overflows past ~181px**
  (181^2 ~= 32761), wrapping to garbage - it does NOT error, it silently lies. On a
  512x512 world this breaks naive squared-distance math. **Always axis-guard before
  squaring** (see `hit2` in `00_core.lua`): `if abs(x1-x2)>=r then return false end`
  first, then square the (now-small) deltas. Same for any `dx*dx+dy*dy` you compare.
- **Numeric LITERALS beyond +-32768 wrap silently too.** `99999` is not a big number here -
  it lands as garbage (`damage_player(99999,...)` dealt ~3390 and did not kill). Keep
  sentinel/constant values <= ~30000 (use `30000` for "certain death").
- **`pcall` is NOT available.** Do not use it.
- **`goto` is unsupported / risky.** Do not use it.
- Shorthand: `+=` `-=` `*=` `/=` (rule: the *whole statement* must be on one line,
  e.g. `f.dx*=d.spd/sp f.dy*=d.spd/sp` is one line - do not wrap).
- `!=` is valid; `//` and `\` - `\` is integer division.
- `cos()` / `sin()` take turns (**0..1**, not radians). `atan2(dx,dy)`.
  - Confirmed convention (probe): `atan2(1,0)=0` (E), `atan2(0,-1)=0.25` (N/up),
    `atan2(-1,0)=0.5` (W), `atan2(0,1)=0.75` (S/down). `sin` is **screen-flipped**:
    `sin(0.25)=-1` (points up the screen), so `cos/sin` point *down* for positive y.
- `add`/`del`/`deli`/`all`/`foreach`, `flr`/`ceil`/`abs`/`min`/`max`/`sqrt`/`rnd`/`srand`,
  `split(str,sep)`, `tostr`, `printh`.
- **`split()` coerces numeric-looking tokens to numbers** (wrap with `tostr`). **String
  methods (`s:sub`) don't exist** - use the globals `sub(s,i,j)` / `#s`.
- **P8SCII widths:** codes **128-255 print 8px wide**, 16-127 print 4px wide. Use `sw(s)`
  (`40_ui.lua`) for centered/right-aligned text; `#s*4` is WRONG for strings containing
  button/arrow glyphs. Key codes: `131` down-arrow, `139` left-arrow, `142` O-button,
  `145` right-arrow, `148` up-arrow, `151` X-button, `16` cursor, `23` selector.
  (`143` is a diamond, NOT X!) `btnp(X-button)`/`btnp(O-button)` also work (5/4).
- **Headless `printh`:** `-x` does **not** surface `printh(msg)` on stdout here - write
  `printh(msg,"p8log.txt")` (lands in the repo root). `-x` also seems to stop the cart
  ~400 frames in; keep scratch loops short and `stop()` explicitly.
- Lowercase identifiers in `.p8`/`.lua` files. Local scope defaults are restrictive;
  hoist to globals when functions defined earlier need later declarations.
- Names to avoid (reserved/quirky): don't shadow built-ins like `stat`, `count`, etc.

## 6. Architecture (monorepo: shared engine + one cart per chapter)

`common/src/*.lua` = **shared engine**; `chapters/<ch>/src/*.lua` = **chapter content**;
one thin cart per chapter `#include`s both. Load order matters (globals). Root `play.bat`
launches `chapters\ch01\ch01.p8`.

```
common/src/00_core.lua      init, state machine, reset, clampi, _update/_draw dispatch, camx/camy
common/src/01_font.lua      custom title font (poked to 0x5600; from the author's heartshooter)
common/src/10_entities.lua  player/flight sim, foes, asteroids, drops, particles, camera, damage
common/src/20_world.lua     load_system (seeded dressing), all flight drawing, ship_frame/SPR_*
common/src/30_combat.lua    weapons, bullets, missiles, collision
common/src/40_ui.lua        text/center helpers, HUD, radar, ship menu, overlays
common/src/60_dialogue.lua  portraits + dialogue scene runner (scripts, typewriter, 2 heads)
common/tools/gen_gfx.py     sprite art -> __gfx__   (python common/tools/gen_gfx.py <cart>.p8)
common/tools/gen_audio.py   sfx/music   -> __sfx__/__music__
chapters/ch01/ch01.p8       the cart (thin #include + __gfx__/__sfx__/__music__)
chapters/ch01/play.bat      per-chapter launcher
chapters/ch01/src/50_station.lua docking, services menu, economy actions (ECO table)
chapters/ch01/src/70_story.lua   chapter flow, cutscenes, quest logic, jump sequence
chapters/ch01/src/80_boss.lua    The Paragon (Ch10) - stub
```

**`#include` base rule:** PICO-8 resolves includes **relative to the cart file's folder**
(NOT `-root_path`). The cart in `chapters/ch01/` therefore uses
`#include ../../common/src/00_core.lua` + `#include src/50_station.lua`; scratch/harness
carts kept in the repo **root** instead use `#include common/src/...` (see section 7).
Include order: `00 01 10 20 30 40`, then ch `50_station`, then `60_dialogue`, then ch
`70_story 80_boss`.

**State machine** (global `state`):
`0` Title . `1` Prologue/Cutscene . `2` Flight . `3` Comms/negotiation overlay .
`4` Station . `5` Jump . `6` Game Over . `7` Ending . `8` Ship menu (pause: mission/inventory).

`_update()` / `_draw()` in `00_core.lua` dispatch to `update_<name>` / `draw_<name>` per
state. Add new states by extending both dispatch chains.

**Key globals:** `p` (player), `foes`, `roids`, `drops`, `bullets`, `missiles`, `parts`,
`floats`, `planets`, `stations`, `active` (docked station), `chapter`, `qs` (quest stage),
`smenu`, `sys_w`/`sys_h` (512x512 world grid), `ARX`/`ARY`/`ARR` (system centre + soft
radius), `camx`/`camy` (ship is kept screen-centred, no edge clamp).

## 7. Testing pattern (the harness)

`-x` (headless) **does** print errors and `printh` output to stdout, then exits - but
only if the cart terminates. A cart with a live main loop runs forever, so build a
throwaway harness that drives the game and then calls `stop()`.

Recipe: create a scratch cart in the repo **root** (so `common/src/...` resolves) or in
`chapters/ch01/` (so `src/...` + `../../common/src/...` resolve):

```lua
pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
#include common/src/00_core.lua
#include common/src/01_font.lua
-- ... all other modules in order (see section 6) ...
_init()
for i=1,180 do _update() _draw() end
printh("SMOKE_OK hp="..p.hp.." state="..state,"p8log.txt")
stop()
```

Run:
```powershell
& "C:\Program Files (x86)\PICO-8\pico8.exe" -root_path "C:\Users\Artem Gavrilov\Documents\Code\Void Reckoning" -x _smoke.p8
```
Delete the harness afterward so it doesn't ship or confuse anyone.

**Caution - the harness's own code counts toward the 8192 budget.** Near the limit a
normal `_smoke.p8` no longer compiles. Then test by temporarily adding a few lines to
`_init()` (set the start state, call `dock`+`open_menu`) plus `printh(...,"p8log.txt")`,
run the **real cart** `-x`, and revert the hook. When the cart has no `stop()`, capture
stdout via `Start-Process ... -RedirectStandardOutput` (a killed process loses buffered
stdout). A `pcall`-wrapped harness also fails silently-ish because **pcall doesn't
exist**; run straight-line and let `-x` report the error with a line number.

Measure the exact token count with a cart = the same `#include`s + `stop()` + N dummy
lines `dN=1`. Each dummy is 3 tokens and `stop()` is 2, so real code =
`reported - 3N - 2`. No overflow means `real <= 8192 - 3N - 2`; raise N until it overflows
to read the exact figure. Example (current): ch01 = **~7693 / 8192 (~499 free)**.

## 8. Patterns - DO

- **Overflow-safe distance tests**: use `hit2(x1,y1,x2,y2,r)` (in `00_core.lua`). It
  rejects via `abs` on each axis *before* squaring, so the squares never exceed the
  fixed-point range. For "is it far?" checks use `abs(dx)<R and abs(dy)<R` instead of
  comparing `dx*dx+dy*dy`; for ranking distances (e.g. nearest enemy) use Manhattan
  `abs(dx)+abs(dy)`. Never write a bare `dx*dx+dy*dy < k` on world coordinates.
- **Flat pools + `deli` swap-remove** while iterating `for i=#t,1,-1`.
- **Seed per system**: `srand(1000+chapter)` for deterministic dressing.
- **Authored skeleton + seeded dressing**: hand-place stations/gates/objectives; let
  RNG place planets/asteroids.
- **Pipe-delimited dialogue** in a per-chapter string (token-cheap) + a tiny parser.
- **Return early** on failed conditions (`if p.ore<=0 then smsg="..." return end`).
- **Keep tunable numbers as named fields/tables** (`ECO` in `50_station.lua`, `foes_def`
  in `10_entities.lua`) so balance passes are one edit.
- **Check the design values in `DESIGN.md`** before inventing balance numbers.

## 9. Anti-patterns - DON'T

- **Don't trust `split()` to return strings** - it coerces numeric tokens to numbers
  (`split("1393"," ")` yields the number `1393`); wrap with `tostr()`. Also string
  methods (`s:sub`) are unavailable - call the global `sub(s,i,j)` instead.
- **Don't use `pcall`, `goto`, or anything outside the z8lua subset.**
- **Don't write `dx*dx+dy*dy` on world coordinates without an axis-guard first** - it
  overflows silently past ~181px and produces phantom/absent collisions (section 5).
- **Don't use radians** with `cos`/`sin` (they're turns). Don't forget `atan2(dx,dy)`
  arg order.
- **Don't wrap `+=`-style compound statements** across lines.
- **Don't invent balance/economy numbers from scratch** - mirror `DESIGN.md`.
- **Don't add build/runtime dependencies** PICO-8 doesn't have (no OOP libs, no
  external Lua).
- **Don't blow the token budget** with verbose code; the budget table lives in
  `DESIGN.md`.
- **Don't commit/push or create a remote** without an explicit user request.
- **Don't trust a visual/feel change** is correct without the user's playtest.
- **Don't leave temp harness/scratch carts** in the repo.
- **Don't make a decision and skip logging it** (see section 0).

## 10. Controls (current build)

- **Button roles are uniform everywhere** (constants `BY=5`, `BN=4` in `00_core.lua`):
  **`X`(BY) = confirm / yes / select / dock / buy / fire.** **`Z`(BN) = cancel / no /
  exit / undock / missile / brake.**
- Title: `X` start. Cutscene: `X` or `Z` advance.
- Flight: arrows = **snappy 8-way**. **`X` = fire the gun** (hold to charge, release to
  fire; power 1-3, power 3 adds a 3-shot spread; charging suppresses shield regen).
  **`Z` = fire a homing missile** (no flip/brake).
  **`X` near a station = dock / jump** (dock check runs before the gun). A centred
  "dock" prompt appears near the bottom of the screen.
- Station menu: up/down select, **`X` buy / confirm**, **`Z` undock**. Items: repair,
  refuel, sell ore, buy hyper-cell. **No UNDOCK item** - `Z` undocks (the prompt says so).
- `Enter`/`P` (btn 6): **ship menu** (state 8) - a 3-item list **MISSIONS / INVENTORY /
  EXIT**. The lower pane shows **one entry at a time** (round carousel): left/right
  (`btnp 0/1`) cycle entries (mission goals tagged `[main]`/`[side]`; inventory shows one
  item + quantity), EXIT quits to the title, and `Z` returns to flight (no RESUME item).
  Pause menu suppressed each held frame via `poke(0x5f30,1)`.
- The flight HUD is **four even bars** (`hbar` in `40_ui.lua`): HP/SH (left), FU/CG (right)
  - same size, colour is the only difference. **No credits or missile text up there**
  (money/cargo/missiles live in the ship menu's INVENTORY tab).
- **Cargo is limited** (`p.ore` / `p.mcargo=10`): ore pickups stop when full (`CARGO FULL`
  floating text).
- **Fuel** burns **0.06/thrust-frame** (doubled). At `fuel<=0` you cannot thrust or fire
  (gun OR missiles). Inside the system you merely drift and get picked apart; out in
  **dead space dry fuel is instant death** (`ADRIFT IN THE VOID`).
- **No mission text on the flight screen** - the radar compass needle (outpost, then the
  gate once `qs>=3`) is the only guidance. The only flight messages are `CARGO FULL`,
  `GATE LOCKED...`, `no fuel`, `dead space area`.
- Currency is **`$n`** everywhere. Kill bounty + ore pickup spawn **floating text**
  (`flt`/`update_floats`/`draw_floats`). Alerts (dead space) stay **red (8)**; the rest of
  the non-dialogue UI is terminal green (`GT=11`).
- Prompts use P8SCII glyphs: `BO=chr(142)` (O), `BX=chr(151)` (X). `lc()` leaves them
  intact (codes >90).
- Flight screen uses a **fade-to-black framebuffer trail** (`trail=true` global toggles
  it; off = plain `cls`).
- Game over / ending: `X` restarts, but only **after a short lockout** (`got`) so the
  death screen is readable.

## 11. Chapter 1 as built

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

## 12. Common rules & gotchas (durable - read before coding)

**PICO-8 dialect**
- 16.16 fixed point (+-32768): **never square a distance without an axis-guard** (`hit2`,
  `dist_trig`). `d*d` silently wraps past ~181px. **Literals > ~32768 also wrap** - a
  `99999` sentinel becomes garbage; keep constants <= 30000.
- No `pcall`, no `goto`. `cos/sin` take turns; `atan2(dx,dy)` (E=0, N=.25, W=.5, S=.75;
  `sin` is screen-flipped). `!=` / `\` ok; `+=`-style statements must stay on one line.
- `split()` coerces numeral tokens to numbers (wrap with `tostr`). No string methods ->
  `sub`.
- `btn(6)` is the pause/Enter button: suppress PICO-8's pause menu with `poke(0x5f30,1)`
  every held frame. Button scheme (use the constants, don't hardcode): **`BY=5` = X =
  confirm / select / dock / buy / fire**, **`BN=4` = Z = cancel / exit / undock /
  missile**.
- P8SCII widths: codes 128-255 are 8px, 16-127 are 4px -> use `sw()`. Glyphs:
  `BX=chr(151)` (X), `BO=chr(142)` (O), 139/145 arrows, 23 selector, 16 cursor. (**143
  is a diamond.**)
- The `print` override lowercases text; non-dialogue text is terminal green `GT=11`
  (alerts such as dead-space stay **red 8**); dialogue text is white 7.
- A custom font is written to 0x5600 by `src/01_font.lua` (reused from the author's own
  `heartshooter` cart); enable it only around the title via `poke(0x5f58,0x81)` ->
  `0x0` (`print_title` in `40_ui.lua`).

**Architecture & conventions**
- Monorepo: `common/src/*.lua` (engine) + `chapters/<ch>/src/*.lua` (content) are
  `#include`d by the chapter's cart; **load order matters** (globals). Include paths are
  relative to the **cart folder** (section 6). `80_boss.lua` is the empty Ch10 stub.
- State machine in `_update`/`_draw` (`00_core.lua`): `0` title . `1` story . `2` flight
  . `4` station . `5` jump . `6` gameover . `7` ending . `8` ship menu. Add new states to
  **both** dispatch chains.
- Flat pools + `deli` swap-remove iterating backwards; `srand(1000+chapter)` per system;
  authored skeleton + seeded dressing. Return early on failed conditions.
- Keep tunables as named fields (`ECO` in `50_station.lua`, `foes_def` in
  `10_entities.lua`) and mirror `DESIGN.md` rather than inventing numbers.

**Token budget (HARD 8192, per-chapter cart)**
- ch01 currently **~7693/8192 (~499 free)**. Every feature added must be offset by
  trimming the same cart; each chapter is its own cart, so they do not share the budget.
- The headless harness's **own code counts** toward the budget, so a normal `_smoke.p8`
  overflows near the limit. Test by temporarily hooking `_init()` (set state / call
  `dock`+`open_menu`) with `printh(...,"p8log.txt")`, running the **real cart** `-x`,
  then reverting. Measure the exact count with a `stop()`+dummy-identifier cart: each
  `dN=1` is 3 tokens, so real = `reported - 3N`.

## 13. Changelog (brief - the full play-by-play lives in git/chat)

- [2026-10-18] **Ch1 vertical slice** playable: intro (briefing -> Rooke dialogue ->
  fly-into-wormhole -> tunnel -> corrupted terminal) -> flight; mine -> dock -> buy
  hyper-cell -> jump to "Chapter 1 complete". Original sprite art, 2-portrait dialogue
  engine, parallax starfield + fade trails, radar, vendored music + SFX, explosions and
  floating text.
- [2026-10-18] **Fit the token wall & UI pass:** unified buttons; `$` currency; carousel
  ship menu (missions/inventory/resume/exit); limited cargo; radar compass replaces the
  screen-edge nav arrow; custom-font title; dead-space alert stays red; hand-drawn
  diagonals replaced by generated 45-degree sprites.
- [2026-10-18] **Controls/UI polish:** `Z` fires missiles only (flip/brake removed);
  outpost menu dropped UNDOCK (Z undocks) and the ship menu dropped RESUME (Z backs out);
  dock prompt centred near the bottom; radar moved lower; dead-space banner shortened to
  one line. Cart trimmed to ~7949/8192 (~243 free).
- [2026-10-19] **Monorepo + Ch1 content pass:** repo split into `common/` (shared engine)
  + `chapters/ch01/` (cart); includes are **cart-relative** (`../../common/src/...` -
  `-root_path` does not affect resolution). Added the outpost-officer dialogue (mission
  gating via `ohint`), the jump-gate warp cutscene, cargo cap 3->6, ore sell 30->10,
  asteroid respawn, missiles damage solid rocks, title planet restored, radar needle moved
  outside the ring (yellow). Trimmed the cart 8324 -> ~7825 tokens.
- [2026-10-19] **HUD/UX + balance pass:** HUD is 4 even bars (HP/SH/FU/CG, colour-only
  difference), no money/missile text in flight nor in the ship-menu header (both live in
  INVENTORY). Flight screen shows **no mission nags** (radar compass only). Central-command
  briefing folded into Rooke's dialogue as portrait-less narrator lines (separate briefing
  screen + its draw/update branches removed). Warp cutscene **holds for `X continue`**.
  Fuel burn doubled (0.06/f); no fuel = no thrust/fire, and dry in dead space = instant
  death. Cargo 10, hyper-cell 250 (25 ore / 20 ore + 5 kills). Cart ~7772/8192.
- [2026-10-19] **Dialogue heads:** both portraits always drawn undimmed (no dither overlay,
  no caret arrow); the speaking character is marked only by their highlighted name. Cart
  ~7693/8192.
