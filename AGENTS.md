# AGENTS.md - Void Reckoning

Read this first. It exists so a fresh session can rebuild full context without the
original chat history. When in doubt, this file + `DESIGN.md` are the source of truth for
engine/design; per-chapter story canon lives in `chapters/<ch>/lore.md` and per-chapter
build notes in `chapters/<ch>/AGENTS.md`.

## 0. THE PRIME DIRECTIVE - LOG EVERY DECISION

Every important decision MUST be written down in this file (or `DESIGN.md`, or the
chapter's `lore.md`) before the session ends. A decision that lives only in chat is lost
forever.

- New design/mechanic decision -> `DESIGN.md`. New world/narrative/canon -> the chapter's
  `chapters/<ch>/lore.md`. Per-chapter build/flow/balance detail -> that chapter's
  `chapters/<ch>/AGENTS.md` (keep the root file chapter-agnostic).
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

Released **chapter by chapter**: ten chapters (Ch1-10), each shipped as it's done. There is
no pre-declared part structure. Story beats (chapter milestones, not groupings): **Ch3** -
Twist 1 (the sealed cargo is empty); **Ch6** - the fork (defect, or die loyal); **Ch10** -
The Paragon.

Current status: **Chapter 1 vertical slice is implemented and passes headless
validation.** Chapters 2-10 and the negotiation layer are not built yet.

## 2. Environment

- OS: **Windows**, shell is **PowerShell 5.1** (no `&&`; use `;` or
  `cmd1; if ($?) { cmd2 }`).
- PICO-8: **v0.2.7** at `C:\Program Files (x86)\PICO-8\pico8.exe`.
- Real Python: `C:\Users\Artem Gavrilov\AppData\Local\Python\bin\python.exe` (the
  `python` alias is the Store stub - use the full path).
- Repo: `C:\Users\Artem Gavrilov\Documents\Code\Void Reckoning`.
  - Git repo, default branch **`main`**, remote **`origin`** =
    `https://github.com/malltshik/void-reckoning`. **Never commit/push without an explicit
    request.** (Initial push 2026-10-19: the whole tree was rebased onto GitHub's README
    commit; the local `master` was renamed `main`. No committer identity is configured, so
    commits need `git -c user.name=... -c user.email=...`.)
- `grep` tool fails on the huge single-line source HTML
  (`Ripgrep JSON record exceeded 65536 bytes`). Use PowerShell string ops for that file.
- **`tmp/`** (gitignored) holds local-only scratch: `tmp/research/` (third-party reference
  carts + `tmp/RESEARCH.md` teardown notes - study only, never ship) and throwaway test
  harness carts. Nothing in it is tracked; do not reference it from tracked docs.

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
- Compressed-size limit (<15,360 bytes) applies only to `.p8.png`/`.p8.rom` **and the html
  web-player export**, **not** `.p8`. See section 12 - a near-full cart trips it, and the
  fix is to keep big raw data (the title font) in `__map__`, not in code.
- `#include` is allowed for authoring; each chapter ships as **its own cart**. Include
  paths resolve **relative to the cart file's folder** (NOT `-root_path`) - section 6.
- Sprite sheet: tiles 0-31 = our ship art, tiles 32-35/48-51 (rows 2-3) = 16x16 dialogue
  portraits (pilot idx 32, rooke idx 34), written by
  `python common/tools/gen_gfx.py <cart>.p8`. The rest of the sheet is unused. Colour 0 in
  sprites is transparent.
- **Cartridge data sections:** `__map__` holds the 2048-byte custom title font (raw bytes
  at 0x2000; `01_font.lua` does `memcpy(0x5600,0x2000,2048)` at boot) and `__label__` holds
  the cartridge label image. Regenerate the map with
  `python common/tools/gen_fontmap.py <cart>.p8` (source of truth: `common/font_map.hex`).
  Do NOT use the map region for anything else.

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
one thin cart per chapter `#include`s both. Load order matters (globals). Run/test headless
(`pico8 -x chapters\<ch>\<ch>.p8`) or in the browser web build (section 12).

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
common/tools/gen_fontmap.py title font  -> __map__   (source: common/font_map.hex)
common/font_map.hex         the 2048 custom-font bytes (XOR-able; see section 12)
docs/index.html             hand-kept player: PICO-8 shell + chapter picker (loads ?cart=)
docs/<chapter>.js           exported web player per cart (build output, committed)
build_web.ps1               exports every chapter cart -> docs/<chapter>.js for Pages
chapters/<ch>/<ch>.p8       the cart (#include + __gfx__/__label__/__map__/__sfx__/__music__)
chapters/<ch>/src/*.lua     chapter content (station/economy, story/flow, boss stub)
chapters/<ch>/AGENTS.md     per-chapter build notes (layout/balance for that chapter)
chapters/<ch>/lore.md       per-chapter story canon
tmp/                        gitignored: research/provenance + test harness carts (section 2)
```

**`#include` base rule:** PICO-8 resolves includes **relative to the cart file's folder**
(NOT `-root_path`). A cart in `chapters/<ch>/` therefore uses
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
`chapters/<ch>/` (so `src/...` + `../../common/src/...` resolve):

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
  to read the exact figure. Each chapter's current figure lives in its `AGENTS.md`.

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

## 11. Chapter-specific context

This file stays **chapter-agnostic**. Per-chapter detail lives with the chapter:

- Build/flow/balance notes -> `chapters/<ch>/AGENTS.md` (Ch1: `chapters/ch01/AGENTS.md`).
- Story canon -> `chapters/<ch>/lore.md`.

If a note only matters for one chapter, put it there - not here.

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

**Cartridge size & web export (the 15,360-byte limit)**
- Saving `.p8.png`/`.p8.rom` **and exporting the html web player** require the *compressed*
  code block < 15,360 bytes (manual 1.5); `.p8` is exempt. Code/strings compress ~2:1, so a
  ~4 KB high-entropy hex literal is what pushed a cart over ("failed: code block too large").
  **Keep big raw data out of code** (the font lives in `__map__`; section 4). The `info()`
  command prints code/token/compressed sizes.
- Web build lives in `docs/`: **one hand-kept `index.html`** (PICO-8's default shell + a
  small chapter picker) that loads `?cart=<chapter>.js` (default `ch01.js`), plus one
  exported `<chapter>.js` per chapter. The `.js` is self-contained (it only needs a
  `<canvas>` + `Module.canvas`, which the shell already provides). Regenerate the `.js` with
  `build_web.ps1`, which **exports with a bare filename and cwd = `docs/`**
  (`pico8 -export <ch>.js ..\chapters\<ch>\<ch>.p8`). The shell in `index.html` is ~930 lines
  of PICO-8 CSS/UI we now own - re-sync it if the engine's default plate changes.
- **The web export CANNOT run in CI** (decided 2026-10-19): the `.js` embeds the proprietary
  PICO-8 runtime, so only the desktop engine can generate it. The license forbids
  redistributing the binary and it is too big for a repo secret, so there is no clean CI
  route. Regenerate locally with `build_web.ps1` and **commit** `docs/*.js`; GitHub Pages
  "deploy from branch `/docs`" republishes on every push. (The `.p8.png` cart is NOT
  sufficient to rebuild the web player.)

**Token budget (HARD 8192, per-chapter cart)**
- Each chapter's cart has its own **8192** token budget - they do **not** share it. Every
  feature added must be offset by trimming the same cart; a chapter's current figure lives
  in its `chapters/<ch>/AGENTS.md`.
- The headless harness's **own code counts** toward the budget, so a normal `_smoke.p8`
  overflows near the limit. Test by temporarily hooking `_init()` (set state / call
  `dock`+`open_menu`) with `printh(...,"p8log.txt")`, running the **real cart** `-x`,
  then reverting. Measure the exact count with a `stop()`+dummy-identifier cart: each
  `dN=1` is 3 tokens, so real = `reported - 3N`.

## 13. Changelog (brief - the full play-by-play lives in git/chat)

- [2026-10-19] **Split per-chapter context out of the root `AGENTS.md`:** the Ch1 "as built"
  notes moved to `chapters/ch01/AGENTS.md`; the root §11 is now a chapter-agnostic pointer.
  Genericized the remaining ch01 examples (`<ch>`/`<cart>`) and moved the ch01 token figure
  into that chapter file, so later-chapter work isn't burdened by Ch1 detail.
- [2026-10-19] **Dropped the Part I/II/III structure:** released **chapter by chapter**
  (Ch1-10), no pre-declared parts; Ch3/Ch6/Ch10 kept as story milestones. Updated
  `DESIGN.md`/`README.md`/`chapters/ch01/lore.md`, the ending screen text (`TO BE
  CONTINUED`, was "PART I - TO BE CONTINUED"), and re-exported the web player.
- [2026-10-19] **Web player = one html + N js:** dropped the per-chapter exported `.html`.
  `docs/index.html` is now the PICO-8 default shell (hand-kept) + a small chapter picker; it
  loads `?cart=<chapter>.js` (default `ch01.js`). `build_web.ps1` exports only the `.js`.
  Deleted `docs/ch01.html`. Trade-off: we now own the ~930-line shell (re-sync on engine
  updates).
- [2026-10-19] **CI decision:** no pipeline for the web build - the exported `.js` needs the
  proprietary PICO-8 engine (can't be run in CI; license/size). Exports stay a **local**
  `build_web.ps1` step committed to `docs/`; Pages deploy-from-branch publishes on push.
- [2026-10-19] **Repo tidy + two-pane landing page:** moved `research/` + `RESEARCH.md` into
  a gitignored `tmp/` (scratch/provenance lives there now; tracked docs no longer reference
  it), removed the `play.bat` launchers (test in the browser / headless instead), and
  rewrote `docs/index.html` as a responsive two-pane chapter browser (chapter list left,
  selected chapter + player right; the list collapses to a top chip row on phones).
  *(Superseded - `docs/index.html` is now the single player/shell; see the entry above.)*
- [2026-10-19] **Web build + font-as-data:** the html web-player export failed with
  "code block too large" - the cart's *compressed* code exceeded the manual's 15,360-byte
  limit (a 4 KB hex font literal barely compresses). Moved the title font into the cart's
  unused map region (`common/font_map.hex` -> `__map__` via `gen_fontmap.py`; `01_font.lua`
  now `memcpy`s it) and captured a `__label__` from the title screen. Added the `docs/`
  GitHub Pages site (per-chapter web player + `index.html`) and `build_web.ps1`.
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
  ~7691/8192.
