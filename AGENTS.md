# AGENTS.md - Void Reckoning

Read this first. It is the hand-over document: a fresh human or agent session should be
able to rebuild full context from this file + `DESIGN.md`, and ship work without the
original chat. Per-chapter detail lives next to the chapter (`chapters/<ch>/AGENTS.md`
build notes, `chapters/<ch>/lore.md` story canon).

## 0. Prime directive - log every decision

A decision that lives only in chat is lost. Before a session ends, write it down:

| What | Where |
| --- | --- |
| Design / mechanic | `DESIGN.md` |
| World, narrative, characters | `chapters/<ch>/lore.md` (canon/tone, **not** the script - the cart's text is authoritative) |
| Chapter build/flow/balance, token figure | `chapters/<ch>/AGENTS.md` |
| Technical rule, workaround, tooling fact, hard-won lesson | **section 5 or 6 below** (rule-shaped, not a changelog) |
| Notable change | one line in section 14 |

Changed your mind? Update the entry and say why (dated) - never silently overwrite. If you
learned something the hard way, it becomes an anti-pattern in section 6.

## 1. What this is

**Void Reckoning** - top-down space action-RPG for **PICO-8**. Real-time flight/combat plus
docked negotiation, dark sci-fi (Bradbury/Strugatsky register). Released **chapter by
chapter** (Ch1-10), one cart per chapter, no pre-declared parts. Story milestones: **Ch3**
twist (the sealed cargo is empty), **Ch6** the fork (defect or die loyal), **Ch10** the Paragon.

**Status:** Chapter 1 is a complete, playable vertical slice (intro -> mine -> dock -> buy
hyper-cell -> jump -> warp finale, with save/continue and death-respawn). Chapters 2-10 and the
docked negotiation layer are not built (Ch2 has a lore stub only).

Doc map: `README.md` (public face) - `DESIGN.md` (full design + as-built numbers) -
this file (how to work) - `chapters/ch01/AGENTS.md` (Ch1 as built) - `chapters/*/lore.md`.

## 2. Environment

- Windows, **PowerShell 5.1** (no `&&`; chain with `;` or `if ($?) { ... }`).
- **PICO-8 v0.2.7** at `C:\Program Files (x86)\PICO-8\pico8.exe` (override with `$env:PICO8`).
- **Real Python 3** at `C:\Users\Artem Gavrilov\AppData\Local\Python\bin\python.exe` (the
  `python` alias is the Store stub - use the full path or `py`).
- Repo `C:\Users\Artem Gavrilov\Documents\Code\Void Reckoning`; GitHub `malltshik/void-reckoning`,
  branch `main`. **Never commit/push without an explicit request.** No committer identity is
  configured: use `git -c user.name=... -c user.email=...`; multi-line messages via
  `git commit -F <file>`. PowerShell shows git's stderr progress as an "error" (exit code 0 is fine).
- Files are **LF** (`.gitattributes` enforces it). On Windows the edit tools can leave mixed
  endings - normalise before committing if `git ls-files --eol` shows `w/mixed` or `w/crlf`.
- The `grep` tool chokes on the huge single-line `docs/*.js`; search it with PowerShell.
- **`tmp/`** is gitignored scratch (research carts, screenshots from `p8check shots`).
  Never reference it from tracked docs.

## 3. Workflow

**Agent builds -> verifies with the tools -> user playtests -> agent fixes.**

Definition of done for any code change:
1. `python common/tools/p8check.py all ch01` passes (tokens under 8192, smoke PASS, shots ok).
2. If rendering changed: look at the PNGs in `tmp/shots/` (the `read` tool shows images), and
   when the change should be invisible prove it with `shotdiff.py` (section 7).
3. `build_web.ps1` re-exports `docs/<ch>.js` (the web player is a committed build output).
4. Docs updated per section 0.
5. Hand off to the user with: how to run, the controls, what to look at. **Feel, balance and
   "does it look right" are the user's call** - screenshots catch layout/regressions, not taste.

## 4. Architecture

Monorepo: shared **engine** (`common/`) + per-chapter **content** (`chapters/<ch>/`), one thin
cart per chapter that `#include`s both. Include paths resolve **relative to the cart file's
folder** (not `-root_path`), so a chapter cart uses `../../common/src/...` and `src/...`.

```
common/src/00_core.lua      _init/new_game/reset_game, save/load/recover, state machine, helpers, print override
common/src/01_font.lua      memcpy the title font from __map__ to 0x5600
common/src/10_entities.lua  player/flight sim, foes AI, rocks, drops, particles, damage, camera
common/src/20_world.lua     load_system (seeded dressing), flight drawing, fade/trail, sprites
common/src/30_combat.lua    guns, charge, homing missiles, collisions
common/src/40_ui.lua        text helpers, menus, HUD, radar, title, game over
common/src/60_dialogue.lua  portrait dialogue runner (typewriter, two heads)
common/tools/p8check.py     tokens / smoke / shots (section 7)       common/tools/shotdiff.py
common/tools/harness/       prelude + helpers injected into test carts
common/tools/gen_*.py       sprites -> __gfx__, audio -> __sfx__/__music__, font -> __map__
common/font_map.hex         the 2048 title-font bytes (stored in __map__, section 5)
chapters/<ch>/<ch>.p8       the cart: #include list + __gfx__/__label__/__map__/__sfx__/__music__
chapters/<ch>/src/7x_*.lua  chapter content (see the contract below)
chapters/<ch>/tests/*.lua   smoke.lua (logic) + shots.lua (screens) drivers
chapters/<ch>/lore.md       canon                chapters/<ch>/AGENTS.md  build notes
docs/                       GitHub Pages: index.html (shell + chapter picker) + <ch>.js per cart
build_web.ps1               exports every chapter cart to docs/<ch>.js
```

Include order (globals - order matters only for top-level statements, functions resolve at call
time): `00 01 10 20 30 40 60` (engine) then the chapter's `70 71 72 ...`.

**State machine** (`state`, dispatched in `_update`/`_draw` of `00_core.lua`; add new states
to **both**): `0` title - `1` story/cutscene - `2` flight - `4` station - `5` jump/warp -
`6` game over - `8` ship menu. (`3` comms/negotiation and `7` are reserved, unbuilt.)

**Chapter contract** - what the engine expects a chapter to define (all in `chapters/<ch>/src`):

| Group | Names |
| --- | --- |
| Constants / data | `CHAPTER` (number; seeds the layout, tags the save), `foes_def` (per kind: `hp shd spd r cd range dmg bs bounty spr`), `FOE_POOL` (kinds reinforcements draw from), `talks` + `talkname` (dialogue scripts) |
| World hooks | `ch_stations()` (adds authored stations; first one is the respawn/continue dock), `ch_foes()` (opening patrol; called last so seeded RNG order stays stable), `objective()` (radar compass target), `draw_stations()` |
| Station (state 4) | `nearest_station(range)`, `dock(s)`, `update_station()`, `draw_station()` |
| Story (state 1) | `init_story()`, `start_story()`, `update_story()`, `draw_story()`, `mission_lines()`, `inventory_lines()` |
| Jump / warp (5) | `start_jump()`, `update_jump()`, `draw_jump()` |
| Engine-owned story globals the chapter may use | `qs` (quest stage), `ohint` (mission hint unlocked) - both persisted by `save_game` |

**Key globals:** `p` (player), `foes roids drops bullets missiles parts blasts floats planets
stations` (flat pools), `active` (respawn dock), `qs ohint`, `sm` (station menu) `mm` (ship
menu), `dg` (dialogue), `spages spg spt` (story pages), `jt` (jump timer), `got` (input
lockout after death/ending), `hassave`, `camx camy`, `frame`, `ARX ARY ARR` (system centre +
soft radius 380; the world is a 512x512 disc, past ARR is "dead space").

## 5. PICO-8 rules (dialect, budget, platform) - the canonical list

**Numbers**
- 16.16 fixed point, +-32768. `d*d` silently wraps past ~181px: **axis-guard before squaring**
  (`hit2`, `dist_trig`, Manhattan `abs(dx)+abs(dy)` for ranking). Never write a bare
  `dx*dx+dy*dy < k` on world coordinates.
- **Literals past +-32767 wrap too**: `99999` is `-31073`. Use `30000` as "huge". (This
  once kept the combat music on forever and stopped missiles from homing - found by `smoke`.)
- `cos/sin` take turns (0..1); `atan2(dx,dy)`; E=0, N=.25, W=.5, S=.75; `sin` is screen-flipped
  (`sin(.25)=-1`, up the screen). `\` is integer division.

**Language**
- Lua 5.2 subset (z8lua). **No `pcall`, no `goto`.** `!=` is valid. Compound ops (`+=`) must
  stay on one line. Lowercase identifiers.
- `split()` coerces numeric tokens to numbers (`tostr` them if you need strings); `split"1,2,3"`
  is the cheap way to write a numeric table. No string methods: use `sub(s,i,j)`, `#s`.
- A cart is one concatenated chunk: top-level `local` is shared by every later file.

**Tokens (hard 8192 per cart)** - an identifier/number/operator = 1; a bracket pair = 1; each
string literal = 1 (so long dialogue strings are nearly free); `local`, `end`, `,` `.` and
comments are free *as tokens*. **Compressed code must stay < 15,360 bytes** for `.p8.png`/`.p8.rom`/the
web export (not for `.p8`) - and comments DO count there (adding ~1.8k chars of comments once broke
the export). So the web build strips all comments first (section 11) and the sources can stay
richly commented; keep big raw data out of code (the font lives in `__map__`).
Characters: 65,535 max (Ch1 uses ~40k with comments, ~29k without).

**Text / UI**
- P8SCII: codes 128-255 print **8px** wide, 16-127 print 4px. Use `sw(s)`, never `#s*4`, for
  centering. Glyphs: `BX=chr(151)` (X), `BO=chr(142)` (O), 139/145 arrows, 131 down, 23 selector,
  16 cursor. (**143 is a diamond, not X.**) 128px = max **32 chars** of plain text per line.
- `print` is overridden in `00_core.lua` to lowercase everything (one consistent font size);
  UI text is terminal green `GT=11`, alerts red 8, dialogue white 7. Title font: `poke(0x5f58,0x81)`
  around `print_title` only.
- `btn(6)` is the pause key: keep `poke(0x5f30,1)` while held so our ship menu replaces
  PICO-8's.

**Rendering**
- Flight (state 2) does **not** `cls`: `fade_screen()` (20_world) dims the previous frame for the
  motion trail by redrawing the screen onto itself through the draw palette
  (`poke(0x5f54,0x60)` + `sspr` + `pal()`). `camera()` must be reset first (sspr honours it) and
  anything drawn in flight must be redrawn every frame. Every other state clears via `_draw`;
  don't add redundant `cls`.
- Sprite sheet: `gen_gfx.py` writes ships (0-7 player, 8-15 scout, 16-23 raider, 24-31 militia)
  and the two 16x16 portraits (32, 34). Colour 0 is transparent. The map region holds the title
  font - **use it for nothing else**.

**Headless PICO-8** (`pico8.exe -x`)
- Prints errors/`printh` to stdout, but a cart with a live main loop never exits. Use `p8check`
  (it owns this), or write `printh(msg,"p8log.txt")` + `stop()` yourself (the file lands in the
  cwd). It cannot take screenshots (`extcmd` is a no-op) - `p8check shots` dumps the screen
  buffer instead.
- The 8192 limit applies to *any* loaded cart, so a naive test cart (game + driver) never loads
  near the limit - which is why the harness strips code (section 7).

## 6. Patterns & anti-patterns

DO
- Flat pools + `deli` swap-remove while iterating backwards; `srand(1000+CHAPTER)` for the
  layout; authored skeleton + seeded dressing; return early on failed conditions.
- Keep tunables as named constants/tables (`ECO`, `foes_def`, `ROID_*`, `FOE_CAP`...) and mirror
  `DESIGN.md` instead of inventing numbers.
- Use the button constants (`BY=5` X = confirm/dock/buy/fire, `BN=4` Z = cancel/undock/missile).
- When you compact code, grep for `spr(` / `sspr(` in what you touched - a refactor once deleted
  the ship from two cutscenes while leaving the comments that described it.
- Add a test for every bug you fix (`tests/smoke.lua` assertions are cheap).

DON'T
- Don't use `pcall`/`goto`, radians, or string methods. Don't wrap `+=` statements across lines.
- Don't square distances without an axis-guard; don't write numeric literals > 32767.
- Don't put chapter content in `common/` (talks, stations, foe stats, ending text...). The engine
  only calls the hooks in the chapter contract.
- Don't reorder RNG calls in `load_system` casually - they define the map (check `shots`).
- Don't leave scratch carts in the repo (`_*.p8`, `chapters/*/_h/` are gitignored and cleaned
  by the tools). Don't blow the token budget with clever generality; measure with `p8check tokens`.
- Don't trust a visual/feel change without a playtest, and don't commit/push unasked.

## 7. Testing & tooling (`common/tools/p8check.py`)

```powershell
$py = "C:\Users\Artem Gavrilov\AppData\Local\Python\bin\python.exe"
& $py common\tools\p8check.py tokens ch01   # exact token count + headroom
& $py common\tools\p8check.py smoke  ch01   # scripted playthrough, asserts on game state
& $py common\tools\p8check.py shots  ch01   # 16 screens -> tmp\shots\ch01_*.png, + text-clipping sweep
& $py common\tools\p8check.py all    ch01   # all three (exit code 1 on any failure)
& $py common\tools\p8check.py size   ch01   # compressed-code headroom for the web export (~4.7k bytes left)
& $py common\tools\p8check.py export ch01   # comment-stripped web export -> docs\ch01.js (build_web.ps1 does this)
& $py common\tools\shotdiff.py tmp\shots\before.txt tmp\shots\ch01_dump.txt   # px diff per screen
```

- **tokens** builds a scratch cart = the real `#include`s + N dummy `dN=1` lines (3 tokens each) +
  `stop()` (2) and reads PICO-8's overflow message (`NNNN / 8192`): real = NNNN - 3N - 2.
- **smoke / shots** build a *stripped copy* of the cart in `chapters/<ch>/_h/` (removed after the
  run). `smoke` replaces every `draw_*` function with an empty stub to free tokens for a driver
  (`chapters/<ch>/tests/smoke.lua`) that feeds scripted buttons into the real `_update` and asserts
  with `ck(cond,"message")`. `shots` stubs the heavy sim instead and draws staged scenes
  (`tests/shots.lua`), dumping the screen buffer that Python turns into PNGs. Stubbing relies on the
  repo style: top-level functions close with a bare `end` at column 0.
- Both harnesses **mock `cartdata`/buttons** (`common/tools/harness/pre.lua`) so they never touch the
  player's real save. `lib.lua` provides `ck tick press hold shot finish` and a `print` guard that
  logs any string that would run off the 128px screen (skipped in flight).
- **Before/after proofs:** run `shots`, copy `tmp/shots/<ch>_dump.txt` aside, change code, re-run,
  `shotdiff.py`. The fade rewrite (-112 tokens, far less CPU) and the engine/chapter split were
  verified this way: 0 px different on all screens.
- Adding coverage: append `ck(...)` lines to `tests/smoke.lua` (`press(5)` = X, `hold(1,30)` =
  hold right 30 frames; arrows are 0-3 L/R/U/D, Z=4, X=5, Enter=6) or stage a new scene in
  `tests/shots.lua`. Teleport/poke state freely - it is a test.
- Not covered: audio, real-time feel, balance, anything only visible in motion.

## 8. Controls & UI conventions (current build)

- **Button roles are uniform everywhere** (`BY=5`, `BN=4`): **X = confirm / select / dock / buy /
  fire**, **Z = cancel / exit / undock / missile**. Cutscenes: X or Z advances.
- Flight: arrows = snappy 8-way (nose follows input, quick stop, no drift). **X** = gun (hold to
  charge, release to fire; power 1-3, power 3 adds a spread; charging suppresses shield regen; a
  gold ring marks full charge). **Z** = homing missile (needs fuel). **X near a station** =
  dock / jump (checked before the gun; a centred `X dock` / `X jump` prompt shows near it).
- **Enter/P** = ship menu (state 8): MISSIONS / INVENTORY / EXIT; the lower pane is a carousel
  (left/right cycle entries), Z returns, EXIT saves and quits to the title.
  `poke(0x5f30,1)` each held frame suppresses PICO-8's own pause menu.
- Title: X begin/continue, Z new game (only when a save exists). Station: up/down + X, Z undocks.
  Game over (X = recover) honours a short input lockout (`got`); the warp finale returns to the
  title on X.
- **HUD** (`40_ui.lua`): four even bars - HP/SH left, FU/CG right (`hbar`, colour is the only
  difference) - plus credits (`$n`, top right) and a missile icon + count (green = loaded,
  red = empty). The radar compass needle is the only objective guidance; flight messages are
  just `CARGO FULL`, `GATE LOCKED...`, `no fuel`, `dead space area`.
- Fuel burns 0.06/thrust-frame; at 0 you cannot thrust or fire, and in dead space dry fuel is
  instant death (`ADRIFT IN THE VOID`). Cargo is capped (`p.mcargo`).
- Colours: terminal green `GT=11` for UI, red 8 for alerts, white 7 for dialogue. Kill bounty
  and ore pickups spawn floating text (`flt`).
- A save always resumes docked at the outpost; death = recover there for a 25% fee and the cargo.

## 9. Token budget

Each chapter cart has its **own** 8192 tokens, but the engine is included in every one, so
engine tokens are paid N times: **trimming `common/` is the best investment**, and engine
additions must be justified. Current figure per chapter is in its own `AGENTS.md`.

Where the tokens are (2026-10-19, Ch1 = 8080): engine **6307** (`10_entities` 1699, `40_ui` 1199,
`20_world` 1088, `00_core` 944, `30_combat` 844, `60_dialogue` 528) + chapter content **~1773**
(`72_story` 897, `71_station` 536, `70_world` 340). So a new chapter has only ~1.9k tokens for
its own content, and the unbuilt negotiation layer / boss will not fit without trimming the
engine or leaving unused subsystems out of a chapter's `#include` list (DESIGN section 13). If you are out of room: measure first (`p8check tokens`), then look for
duplicated helpers (`wrap` vs `wrap_off`), one-use locals, and defaults for params every caller
passes. Features already cut for budget (re-add only if there is room): second enemy (raider),
charge meter, dead-space scan objective, hit flash, low-HP/fuel HUD blink, one-time control hint,
station art. In-editor, the `info` command prints code/token/compressed sizes.

## 10. Assets pipeline

All three generators take the cart path, edit only their own section and leave the rest
untouched (verified: re-running all three on `ch01.p8` reproduces its data byte-for-byte):

```powershell
& $py common\tools\gen_gfx.py     chapters\ch01\ch01.p8   # __gfx__: ships + portraits (art is ASCII in the script)
& $py common\tools\gen_audio.py   chapters\ch01\ch01.p8   # __sfx__/__music__ (SFX original, music vendored)
& $py common\tools\gen_fontmap.py chapters\ch01\ch01.p8   # __map__: 2048-byte title font from common/font_map.hex
```

`__label__` (the cartridge label, a title-screen capture) cannot be regenerated headless: when
starting a chapter, copy the previous cart so the label and data come along.

## 11. Web build & release

`docs/` is a GitHub Pages site: one hand-kept `index.html` (PICO-8's shell + a chapter picker,
~930 lines of CSS/JS we now own; re-sync if PICO-8's default shell changes) and one exported
`<chapter>.js` per cart, loaded via `?cart=<chapter>.js` (default `ch01.js`).
- Regenerate with `powershell -ExecutionPolicy Bypass -File build_web.ps1` and **commit** `docs/*.js`.
  The export embeds the proprietary PICO-8 runtime, so it **cannot run in CI** - local only.
  Pages deploys from branch `main` / `/docs` on every push.
- `build_web.ps1` -> `p8check.py export`: copies the sources to `tmp/web/` with every comment stripped
  (tokens unchanged - verified identical), exports from there, and **fails loudly** if PICO-8 refuses
  ("code block too large" = compressed code > 15,360 bytes) instead of shipping a stale file.
  `p8check.py size ch01` estimates the room left (~4.7k compressed bytes at the handover).
- **Music licence:** the soundtrack is "Pico-8 Tunes Vol. 1" by Gruber & krajzeg (CC BY-NC-SA,
  **non-commercial**). Attribution must stay on the title screen and the web page.
- Third-party carts were studied for reference only (gitignored in `tmp/`); nothing of theirs ships.

## 12. Starting the next chapter (checklist)

1. `chapters/ch02/`: copy `ch01/ch01.p8` -> `ch02.p8` (keeps gfx/map/sfx/music/label), then edit the
   include list to its own `src/` files; regenerate assets only if the generators changed.
2. Write `src/70_world.lua`, `71_station.lua`, `72_story.lua` (or more) satisfying the **chapter
   contract** (section 4): set `CHAPTER=2`, authored stations, `foes_def`/`FOE_POOL`, scripts, hooks.
   Copy ch01's files as a starting point - the shapes are deliberately small.
3. Copy `tests/smoke.lua` + `tests/shots.lua` and adapt; get `p8check all ch02` green early.
4. Write `chapters/ch02/AGENTS.md` (token figure, balance, flow) and flesh out `lore.md`.
5. `build_web.ps1` picks the new cart up automatically; add it to the `CH` list in `docs/index.html`
   (`soon:true` -> real).
6. **Open question (decide + log in DESIGN section 13):** how progress crosses carts. The save uses
   `cartdata("vrk1")` and slot 0 holds the chapter number, so a cart only continues a save from its
   own chapter; sharing the id would let ch02 read ch01's end state, but the web player cannot
   `load()` a sibling cart, so the hand-off is probably "the picker opens the next cart".

## 13. Known gaps & backlog (as of the 2026-10-19 handover)

- **Not built:** the docked negotiation layer (state 3), Ch2-10, upgrade tiers (DESIGN section 8),
  the Paragon boss, a real `.p8.png` release label per chapter.
- **Cut for the 8192-token wall, re-addable now there is headroom** (Ch1 has ~112 free): second
  enemy (raider; sprites already in the sheet), charge meter, hit flash, low-HP/fuel HUD blink,
  one-time control hint, dead-space scan side objective.
- **Possible engine trims** (each pays back in every chapter): merge `wrap`/`wrap_off`
  (`00_core` / `60_dialogue`; note `wrap("")` returns one empty line, which `draw_term` relies on
  for cursor placement), shrink the `lc()` print wrapper, generalise `draw_stations`.
- **Untested by tooling:** audio, feel/balance, anything only visible in motion - needs a human.
- **Open design question:** how progress crosses chapter carts (checklist step 6 above).
## 14. Changelog (brief - full detail is in git)

- [2026-10-19] **Outpost polish:** REPAIR is now partial like REFUEL (a short wallet buys what it
  can afford, 0 units -> `NOT ENOUGH $`; smoke asserts partial + no-money); both stations redrawn
  from primitives - outpost is a domed base on a lit moon chunk, gate is a solar-panel relay
  satellite (`draw_stations` in `chapters/ch01/src/70_world.lua`). Ch1: 8080/8192 tokens.
- [2026-10-19] **Playtest fixes:** full cargo no longer magnetises ore; REFUEL is partial when short
  on cash; reinforcements arrive as a 3-5 patrol (`FOE_CAP` 4 -> 8) so loitering is dangerous; each
  new game gets a per-run layout (`SEED`, saved with the run so continue = same system); the
  "chapter complete" screen was cut - the warp cutscene is the finale (Ch2 reuses it, new text:
  `chapters/ch02/AGENTS.md`).
- [2026-10-19] **Web export now strips comments** (`p8check export`): after the handover docs/comments
  grew the sources, the unstripped cart exceeded the 15,360-byte compressed limit and `build_web` failed.
  Stripping is token-neutral and leaves ~4.7k compressed bytes of headroom.
- [2026-10-19] **Handover pass:** added `p8check.py` (tokens/smoke/shots) + `shotdiff.py`; fixed
  wrapped `99999` literals (combat music was always on, missiles never homed; missiles now steer
  directly, 200px lock range); continue/respawn now always at the outpost; warp text no longer
  clipped; title credit centred; fade via `pal`+`sspr` (-112 tokens, pixel-identical); engine/
  chapter split (talks, stations, foe roster, ending moved to `chapters/ch01/src/70-72`, hooks
  documented as the chapter contract; `CHAPTER` constant; `new_game`/`reset_game`); removed dead
  code (`sys_w/h`, `trail`, param defaults, `80_boss.lua`); `.gitattributes` (LF), `build_web.ps1`
  now fails loudly; docs rewritten. Ch1: 7981/8192 tokens.
- [2026-10-19] **Wormhole cutscene ship restored** (a compaction had dropped the draws) at the cost of
  the one-time control hint.
- [2026-10-19] **Chapter 1 polish:** full-width HUD (credits + missile icon), save/continue
  (`cartdata`), death respawn with fee, missile shop, rock hp 12, ram knockback, story seeds.
- [2026-10-19] **Release model:** chapter by chapter (no Parts). **Web player:** one `index.html` +
  one `.js` per chapter; no CI (proprietary runtime). **Monorepo:** `common/` + `chapters/<ch>/`,
  cart-relative includes. **Font in `__map__`** to stay under the compressed-size limit.
- [2026-10-18] Ch1 vertical slice playable; unified buttons; `$` currency; carousel ship menu;
  radar compass; custom-font title.
