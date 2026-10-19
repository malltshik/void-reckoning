# Void Reckoning

A top-down space action-RPG for the [PICO-8](https://www.lexaloffle.com/pico-8.php)
fantasy console. Part game, part story: real-time flight and combat out in a star
system, and negotiation when you dock. Dark sci-fi tone.

**▶ Play in your browser:** <https://malltshik.github.io/void-reckoning/>

**Status:** **Chapter 1** is a playable vertical slice — mine ore, dock at the outpost,
sell, buy a hyper-cell, jump out. The game is released chapter by chapter; Chapters 2–10
and the docked negotiation layer are not built yet.

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
common/tools/*.py     asset generators (sprites, audio, font map)
common/font_map.hex   custom title font bytes, stored in each cart's map region
chapters/ch01/        Chapter 1 cart + story src/ + lore.md
chapters/ch02/        Chapter 2 (lore only, in progress)
docs/                 GitHub Pages player (index.html shell + one <chapter>.js per cart)
AGENTS.md             dev conventions, PICO-8 gotchas, token budget
DESIGN.md             full game design
```

Each chapter is its own PICO-8 cart. Regenerate art/audio/font-map after editing the
generators (`python common/tools/<tool>.py chapters/ch01/ch01.p8`).

## Credits & license

- Code, art and design: malltshik.
- Music: **Pico-8 Tunes Vol. 1** by Gruber & krajzeg (CC BY-NC-SA). **Non-commercial.**
- Third-party carts were studied for reference only; none of their code or assets ship in
  this game.
