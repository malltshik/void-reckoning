# PICO Space (drakeblue) — reference cart, DO NOT SHIP

Third-party cart kept **only for study**. It is not part of Void Reckoning and must
never be compiled into `void_reckoning.p8` or shipped in any build.

- Game/thread: https://www.lexaloffle.com/bbs/?tid=42279
- Dev blog (teardown write-up by the author): https://www.lexaloffle.com/bbs/?tid=42353
- Itch: https://drake-blue.itch.io/pico-space
- Author: Drake Blue. Cart id used at boot: `drakeblue_picospace_1`.
- **License: CC BY-NC-SA** (study/reference only; no wholesale copying). If any specific
  idea is ported, re-implement it in our own code and log it in `AGENTS.md` /
  `RESEARCH.md`.

## Files
- `drakeblue_picospace-3.p8.png` — the cart as downloaded from
  `https://www.lexaloffle.com/bbs/cposts/dr/drakeblue_picospace-3.p8.png`.
- `decoded_decompressed.lua` — code section extracted from the PNG (30,713 bytes, PXA
  format). Minified single/double-letter identifiers; control chars are P8SCII codes.

## How it was decoded
PNG is unfiltered manually; the 2 low bits of each ARGB channel carry code bytes
(byte = colour & 3, MSB-first, in R,G,B,(A) order). First 8 bytes at ROM `0x4300`
are the header: `\0pxa` = PXA, `:c:\0` = legacy, neither = raw Lua. Our decoder:
`%TEMP%\opencode\decode_p8.py picospace.p8.png out.lua`. The same decoder works for any
PICO-8 `.p8.png` (it handles PXA + legacy compression).
