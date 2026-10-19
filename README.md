# Void Reckoning

A top-down space action-RPG for the [PICO-8](https://www.lexaloffle.com/pico-8.php)
fantasy console. Part game, part story: real-time flight and combat out in a star
system, and negotiation when you dock. Dark sci-fi tone.

**▶ Play in your browser:** <https://malltshik.github.io/void-reckoning/>

**Status:** **Chapter 1** is a playable vertical slice — mine ore, dock at the outpost,
sell, buy a hyper-cell, jump out. The game is released chapter by chapter; Chapters 2–10
and the docked negotiation layer are not built yet.

Progress autosaves on dock, on jump and on quit; the title offers **continue / new game**.
Dying respawns you at the last dock for a 25% fee and your cargo — the story never resets.
The flight HUD shows HP/shield/fuel/cargo bars, plus your credits and missile count
(missile icon: green = loaded, red = empty).

## Controls

| Input | Action |
| --- | --- |
| Arrows | Fly (snappy 8-way) |
| **X** | Fire the gun (hold to charge, release to fire) · confirm · **dock / jump** near a station |
| **Z** | Fire a homing missile · cancel · undock |
| **Enter / P** | Ship menu (missions · inventory) |

At a station: up/down to select, **X** to buy, **Z** to undock.

## Play locally

Requires PICO-8 (v0.2.7):

```
"C:\Program Files (x86)\PICO-8\pico8.exe" chapters\ch01\ch01.p8
```

## Browser build

The GitHub Pages site under `docs/` is one player page (`index.html`) plus one exported
`<chapter>.js` per chapter. `index.html` loads `?cart=<chapter>.js` (default `ch01.js`)
and offers a small chapter picker. Regenerate the `.js` after changing a cart with:

```powershell
powershell -ExecutionPolicy Bypass -File build_web.ps1
```

Publish it from **Settings → Pages → Deploy from a branch → `main` / `docs`**.

## Layout

```
common/src/*.lua      shared engine   (core, font, entities, world, combat, ui, dialogue)
common/tools/         p8check.py (tokens / smoke test / screenshots), shotdiff.py, asset generators
common/font_map.hex   custom title font bytes, stored in each cart's map region
chapters/ch01/        Chapter 1: cart, src/ (world, station, story), tests/, lore.md, AGENTS.md
chapters/ch02/        Chapter 2 (lore only, in progress)
docs/                 GitHub Pages player (index.html shell + one <chapter>.js per cart)
AGENTS.md             start here when developing: workflow, architecture, PICO-8 gotchas, tooling
DESIGN.md             full game design
```

Each chapter is its own PICO-8 cart (8192-token limit each) that includes the shared engine
plus its own content.

## Development

```powershell
python common/tools/p8check.py all ch01     # token count + headless playthrough + screenshots
powershell -ExecutionPolicy Bypass -File build_web.ps1   # re-export the web player
```

`AGENTS.md` is the hand-over document (environment, definition of done, chapter contract,
how to start the next chapter). The generators re-create a cart's art/audio/font sections:
`python common/tools/gen_gfx.py chapters/ch01/ch01.p8` (likewise `gen_audio.py`, `gen_fontmap.py`).
## Credits & license

- Code, art and design: malltshik.
- Music: **Pico-8 Tunes Vol. 1** by Gruber & krajzeg (CC BY-NC-SA). **Non-commercial.**
- Third-party carts were studied for reference only; none of their code or assets ship in
  this game.
