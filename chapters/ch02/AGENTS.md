# AGENTS.md - Chapter 2

Not built yet. Start with the repo-root `AGENTS.md` (section 12 is the "start the next
chapter" checklist). Canon/tone: `chapters/ch02/lore.md`.

## To do

- **Open Chapter 2 with the Chapter 1 warp animation, but different text.** Ch1 now ends on
  the warp cutscene (state 5): radial streaks from the core with one narration line typed in
  at a time. The animation code is `draw_jump`/`update_jump` and the text is `jlines`, both in
  `chapters/ch01/src/72_story.lua`. Reuse that animation for Ch2's cold open and swap `jlines`
  for Chapter 2's arrival text (keep every line <= 31 chars - the shots test fails on clipping).
  It may be worth hoisting the warp animation into the engine (`common/src`) so chapters share
  it instead of copying it.
- Ch1 note: the separate "chapter complete" ending screen was **removed** - the warp cutscene
  *is* the finale. Only reintroduce a completion screen if a chapter actually needs one.

## Chapter notes (fill in as built)

- CHAPTER number, cart token figure, flow, balance, cuts. See `chapters/ch01/AGENTS.md` for
  the shape.
