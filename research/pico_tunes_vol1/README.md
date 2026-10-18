# Pico-8 Tunes Vol. 1 — music source (reusable, with attribution)

Third-party cart used as the **music source** for Void Reckoning. Unlike a plain
reference, this one is *licensed for reuse in games* — see below. Still, do not paste it
wholesale; we only copy the specific tunes we use (via `tools/gen_audio.py`).

- Thread: https://www.lexaloffle.com/bbs/?tid=29008  (cart #38440)
- Cart download: https://www.lexaloffle.com/bbs/cposts/3/38440.p8.png
- Authors: **Gruber** (@gruber_music, music) and **Jakub Wasilewski / krajzeg**
  (code, art, animations).
- License: **CC BY-NC-SA** (BBS badge) / the authors state the music+art is
  CC-BY-SA and the code ~zlib. Both authors explicitly invite reuse:
  *"The idea was to create a cart with music that others can use in their games, so please
  feel free to do so!"* → **attribution + non-commercial** is required.

## What we use
Three of the twelve tunes, copied as SFX phrases + music patterns (channels 0-1 only):
- **"space"** (original patterns 18-23, SFX 15-19) → our **flight** theme.
- **"boss"**  (original patterns 42-45, SFX 35-39) → our **combat** theme.
- **"travel"**(original patterns 48-54, SFX 44-48) → our **station** theme.

In our cart they live at SFX ids 20-34 and music patterns 0/6/10 (see `tools/gen_audio.py`).

## Files
- `gruber_picotunes1.p8.png` — the downloaded cart.
- `gruber_picotunes1.p8` — full text cart reconstructed from the PNG by
  `%TEMP%\opencode\p8extract.py` (code + `__sfx__` + `__music__`), for reading the setlist
  (`setlist={...}` gives each tune's starting pattern via `at=`).

## Credit line for our game
> Music: "Pico-8 Tunes Vol. 1" by Gruber & krajzeg (CC BY-NC-SA)
