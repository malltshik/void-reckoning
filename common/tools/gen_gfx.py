import sys, math
from collections import Counter

# Writes the __gfx__ section of a chapter cart. Run from the repo root:
#   python common/tools/gen_gfx.py chapters/ch01/ch01.p8
# Sheet layout: sprites 0-7 player, 8-15 scout, 16-23 raider, 24-31 militia (8 angle
# frames each; ch01 only uses player + scout - the rest are ready for later chapters),
# 32-35 / 48-51 the two 16x16 dialogue portraits (pilot=32, rook=34).
# ---------------------------------------------------------------------------
# Original sprite art for Void Reckoning (hand-drawn, our own - no third party).
# We hand-draw only the N frame; the generator derives the rest: the four
# diagonals come from a supersampled 45-degree rotation of N (plain nearest
# sampling of 8x8 art is gappy, so we coverage-sample), and E/S/NW/SW/SE come
# from 90/180-degree rotations and mirroring.
#
# Frame order in the sheet is the angle order used at runtime (see ship_frame in
# 20_world.lua):  k=0 E, 1 NE, 2 N, 3 NW, 4 W, 5 SW, 6 S, 7 SE
#
# '.' = colour 0 (transparent); any hex digit '0'-'f' = that palette colour.
# ---------------------------------------------------------------------------

ART = {
    # player fighter - Resistance amber/white cockpit
    "player": {
        "N": [
            "...bb...",
            "...bb...",
            "..b77b..",
            "..b77b..",
            ".bbbbbb.",
            "bb.bb.bb",
            "b..bb..b",
            "...bb...",
        ],
    },
    # scout - small green dart
    "scout": {
        "N": [
            "........",
            "...88...",
            "...88...",
            "..8778..",
            ".888888.",
            "8.8888.8",
            "........",
            "........",
        ],
    },
    # raider - green hull, amber accents
    "raider": {
        "N": [
            "...bb...",
            "..8bb8..",
            ".88bb88.",
            ".887788.",
            "88888888",
            "8.8..8.8",
            "...88...",
            "........",
        ],
    },
    # militia - steel-blue blocky gunship
    "mil": {
        "N": [
            "..cccc..",
            ".c7777c.",
            "cc7777cc",
            "cccddccc",
            "cccccccc",
            "c.cccc.c",
            "c......c",
            "........",
        ],
    },
}

ORDER = ["player", "scout", "raider", "mil"]  # sprite bases 0,8,16,24

# 16x16 character portraits for the dialogue screen (placed as sprite blocks;
# the Lua side draws them with sspr - see PORT in common/src/60_dialogue.lua).
PORTRAITS = {"pilot": 32, "rook": 34}  # sprite index of the block's top-left
P_ART = {
    # pilot 1393 - blue helmet, dark visor, white rim
    "pilot": [
        "................",
        "....77777777....",
        "..77cccccccc77..",
        ".7cccccccccccc7.",
        ".7cc11111111cc7.",
        ".7c1111111111c7.",
        ".7c1111111111c7.",
        ".7c1111111111c7.",
        ".7c1111111111c7.",
        ".7c1111111111c7.",
        ".7cc11111111cc7.",
        ".7cccccccccccc7.",
        "..77cccccccc77..",
        "..cccccccccccc..",
        "..777777777777..",
        "................",
    ],
    # handler rooke - grey hair, blue uniform, white collar
    "rook": [
        "................",
        "....66666666....",
        "..666666666666..",
        "..666666666666..",
        "..6ffffffffff6..",
        "..ffffffffffff..",
        "..fff1fffff1ff..",
        "..ffffffffffff..",
        "..ffffffffffff..",
        "..6ffffffffff6..",
        "...ffffffffff...",
        "....ffffffff....",
        "..cccccccccccc..",
        ".cccccccccccccc.",
        ".ccc77777777ccc.",
        ".cccccccccccccc.",
    ],
}

N = 8


def rot90cw(a):
    # new[i][j] = old[N-1-j][i]  -> nose at top (N) ends at the right (E)
    return ["".join(a[N - 1 - j][i] for j in range(N)) for i in range(N)]


def rot180(a):
    return ["".join(a[N - 1 - y][N - 1 - x] for x in range(N)) for y in range(N)]


def mirror_x(a):
    return [row[::-1] for row in a]


def mirror_y(a):
    return a[::-1]


def rot45_ne(n):
    # rotate the N art 45 degrees (nose up -> nose up-right) using supersampled
    # coverage, so the diagonal silhouette stays solid and on-model instead of the
    # gappy mess you get from nearest-sampling thin 8x8 art.
    K = 8
    th = math.radians(45)
    cs = math.cos(th)
    sn = math.sin(th)
    out = [["."] * N for _ in range(N)]
    for y in range(N):
        for x in range(N):
            cnt = 0
            cols = Counter()
            for sy in range(K):
                for sx in range(K):
                    px = x + (sx + 0.5) / K - 4.0
                    py = y + (sy + 0.5) / K - 4.0
                    rx = px * cs + py * sn
                    ry = -px * sn + py * cs
                    ix = int(rx + 4.0)
                    iy = int(ry + 4.0)
                    if 0 <= ix < N and 0 <= iy < N and n[iy][ix] != ".":
                        cnt += 1
                        cols[n[iy][ix]] += 1
            if cnt >= 0.5 * K * K and cols:
                out[y][x] = cols.most_common(1)[0][0]
    return ["".join(r) for r in out]


def frames_for(kind):
    n = ART[kind]["N"]
    ne = rot45_ne(n)
    e = rot90cw(n)
    s = rot180(n)
    w = rot180(e)
    return [
        e,                # 0 E
        ne,               # 1 NE
        n,                # 2 N
        mirror_x(ne),     # 3 NW
        w,                # 4 W
        mirror_x(mirror_y(ne)),  # 5 SW
        s,                # 6 S
        mirror_y(ne),     # 7 SE
    ]


def build_gfx():
    grid = [[0] * 128 for _ in range(128)]
    base = 0
    for kind in ORDER:
        for fi, frame in enumerate(frames_for(kind)):
            n = base + fi
            tx = (n % 16) * 8
            ty = (n // 16) * 8
            for y in range(N):
                row = frame[y]
                for x in range(N):
                    ch = row[x]
                    if ch != ".":
                        grid[ty + y][tx + x] = int(ch, 16)
        base += 8
    for name, idx in PORTRAITS.items():
        tx = (idx % 16) * 8
        ty = (idx // 16) * 8
        art = P_ART[name]
        for y in range(16):
            row = art[y]
            for x in range(16):
                ch = row[x]
                if ch != ".":
                    grid[ty + y][tx + x] = int(ch, 16)
    return ["".join("%x" % v for v in row) for row in grid]


def main():
    cart = sys.argv[1]
    with open(cart, "r", encoding="utf-8", newline="\n") as f:
        lines = f.read().split("\n")

    # split into code header and the trailing data sections
    cut = len(lines)
    for k, ln in enumerate(lines):
        if ln.startswith("__gfx__") or ln.startswith("__sfx__") or ln.startswith("__music__"):
            cut = k
            break
    head = lines[:cut]
    data = lines[cut:]
    # drop an existing __gfx__ block (everything up to the next __section__)
    if data and data[0].startswith("__gfx__"):
        j = 1
        while j < len(data) and not data[j].startswith("__"):
            j += 1
        data = data[j:]
    out = head + ["__gfx__"] + build_gfx() + data
    with open(cart, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(out) + "\n")
    print("wrote", cart, "with __gfx__", len(build_gfx()), "rows")


if __name__ == "__main__":
    main()
