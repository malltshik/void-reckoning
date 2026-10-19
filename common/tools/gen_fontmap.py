import sys, os

# ---------------------------------------------------------------------------
# Writes the custom title font into a cart's __map__ section.
#
# The 2048 font bytes are stored in common/font_map.hex and copied to the font
# area (0x5600) at boot by common/src/01_font.lua. The map region (0x2000) is
# otherwise unused, and holding the font there instead of as a Lua literal keeps
# the compressed code block under PICO-8's 15360-byte limit so the cart can be
# exported as a standalone html/js web player.
# ---------------------------------------------------------------------------

HERE = os.path.dirname(os.path.abspath(__file__))
HEX = os.path.join(HERE, "..", "font_map.hex")


def load_rows():
    with open(HEX, "r", encoding="utf-8") as f:
        h = "".join(f.read().split())
    if not h or len(h) % 256:
        raise SystemExit("font_map.hex must hold a whole number of 128-byte rows")
    rows = [h[i:i + 256] for i in range(0, len(h), 256)]
    while rows and rows[-1] == "0" * 256:
        rows.pop()
    return rows


def main():
    cart = sys.argv[1]
    with open(cart, "r", encoding="utf-8", newline="\n") as f:
        lines = f.read().split("\n")

    # drop any existing __map__ block
    out, i = [], 0
    while i < len(lines):
        if lines[i].startswith("__map__"):
            i += 1
            while i < len(lines) and not lines[i].startswith("__"):
                i += 1
        else:
            out.append(lines[i])
            i += 1

    # canonical position: after __gfx__, before __sfx__/__music__
    at = len(out)
    for k, ln in enumerate(out):
        if ln.startswith("__sfx__") or ln.startswith("__music__"):
            at = k
            break

    rows = load_rows()
    out = out[:at] + ["__map__"] + rows + out[at:]
    with open(cart, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(out))
    print("wrote", cart, "with __map__", len(rows), "rows", len(rows) * 128, "bytes")


if __name__ == "__main__":
    main()
