#!/usr/bin/env python
"""Dev tooling for Void Reckoning carts (headless PICO-8).  See AGENTS.md section 7.

    python common/tools/p8check.py tokens [chapter]   exact code-token count + headroom
    python common/tools/p8check.py smoke  [chapter]   scripted playthrough of the real game logic
    python common/tools/p8check.py shots  [chapter]   render key screens to tmp/shots/*.png
    python common/tools/p8check.py all    [chapter]   tokens + smoke + shots   (default chapter: ch01)
    python common/tools/p8check.py export [chapter]   comment-stripped web export -> docs/<ch>.js (build_web.ps1 calls this)
    python common/tools/p8check.py size   [chapter]   how much compressed-code room is left for the web export

Why this exists: the cart is always within a few dozen tokens of PICO-8's 8192 limit, so a
normal test harness (cart code + driver) can never load. `smoke` and `shots` therefore
build a *stripped copy* of the cart under chapters/<ch>/_h/ (scratch, gitignored):

  smoke  strips every draw function, then drives the game through scripted input
         (chapters/<ch>/tests/smoke.lua) and asserts on state - covers boot, intro, flight,
         dock/menu/economy, save/load, death/recover, dead space, jump, ending.
  shots  strips the heavy simulation functions instead and draws fixed scenes
         (chapters/<ch>/tests/shots.lua), dumping the 128x128 screen buffer as text which
          this script turns into PNGs (PICO-8 cannot write screenshots when headless).

  Both harnesses mock cartdata/buttons (common/tools/harness/pre.lua) so they never touch
  the player's real save.

export / size exist because the web export (and .p8.png) need the *compressed* code under
15,360 bytes - a second hard limit besides the 8192 tokens. Comments cost compressed bytes,
so the sources stay richly commented and the release build strips every comment (safe:
tokens are unchanged) into tmp/web/ before exporting.

Needs real Python 3 (not the Store stub) and PICO-8 v0.2.7; set PICO8 if it is not in the
default install path.
"""
import os
import re
import struct
import subprocess
import sys
import zlib

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
PICO8 = os.environ.get("PICO8", r"C:\Program Files (x86)\PICO-8\pico8.exe")
HARNESS = os.path.join(ROOT, "common", "tools", "harness")
LIMIT = 8192

# functions replaced by empty stubs in each harness (matched on the name after `function`)
STRIP = {
    "smoke": r"draw_\w+|print_title|hbar|misicon|rplot|menu_show|portrait|fade_screen|ne_stars",
    "shots": r"update_(flight|spawn|foes|roids|drops|bullets|missiles|camera)|collide_all",
}

# PICO-8 default palette (index -> RGB)
PAL = ["000000", "1D2B53", "7E2553", "008751", "AB5236", "5F574F", "C2C3C7", "FFF1E8",
       "FF004D", "FFA300", "FFEC27", "00E436", "29ADFF", "83769C", "FF77A8", "FFCCAA"]


def read(path):
    with open(path, encoding="utf-8", newline="") as f:
        return f.read().replace("\r\n", "\n")


def write(path, text):
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)


def cart_path(ch):
    return os.path.join(ROOT, "chapters", ch, ch + ".p8")


def split_cart(ch):
    """-> (header lines up to and incl. __lua__, lua lines, data-section lines)"""
    lines = read(cart_path(ch)).split("\n")
    i = lines.index("__lua__")
    j = next(k for k in range(i + 1, len(lines)) if re.fullmatch(r"__\w+__", lines[k]))
    return lines[: i + 1], lines[i + 1: j], lines[j:]


def run(cart, timeout):
    """Run a cart headless from the repo root; returns (stdout+stderr, timed_out)."""
    try:
        p = subprocess.run([PICO8, "-x", cart], cwd=ROOT, capture_output=True,
                           text=True, timeout=timeout)
        return (p.stdout or "") + (p.stderr or ""), False
    except subprocess.TimeoutExpired as e:
        out = (e.stdout or b"") if isinstance(e.stdout, bytes) else (e.stdout or "")
        err = (e.stderr or b"") if isinstance(e.stderr, bytes) else (e.stderr or "")
        if isinstance(out, bytes):
            out = out.decode("utf-8", "replace")
        if isinstance(err, bytes):
            err = err.decode("utf-8", "replace")
        return out + err, True


# ---------------------------------------------------------------- tokens

def count_tokens(ch):
    """Exact token count: same #includes + N dummy `dN=1` (3 tokens each) + stop() (2).
    PICO-8 only reports the total when it overflows, so keep adding dummies until it does."""
    head, lua, _ = split_cart(ch)
    cart = os.path.join("chapters", ch, "_tok.p8")
    try:
        for n in (200, 800, 2400):
            dummies = " ".join("d%d=1" % i for i in range(n))
            write(os.path.join(ROOT, cart), "\n".join(head + lua + [dummies, "stop()"]) + "\n")
            out, _t = run(cart, 15)
            m = re.search(r"(\d+) / %d tokens" % LIMIT, out)
            if m:
                return int(m.group(1)) - 3 * n - 2
    finally:
        try:
            os.remove(os.path.join(ROOT, cart))
        except OSError:
            pass
    return None


def cmd_tokens(ch):
    real = count_tokens(ch)
    if real is None:
        print("%s: could not measure tokens" % ch)
        return False
    chars = 0
    _, lua, _ = split_cart(ch)
    base = os.path.join(ROOT, "chapters", ch)
    for l in lua:
        if l.startswith("#include "):
            chars += len(read(os.path.normpath(os.path.join(base, l.split(None, 1)[1].strip()))))
    free = LIMIT - real
    print("%s: %d / %d tokens (%d free), ~%d / 65535 chars" % (ch, real, LIMIT, free, chars))
    return free >= 0


# ---------------------------------------------------------------- harness build

def strip_functions(src, pattern):
    """Replace top-level functions whose name matches `pattern` with empty stubs.
    Relies on the repo style: top-level functions close with a bare `end` at column 0."""
    rx = re.compile(r"^(local\s+)?function\s+(%s)\s*\(" % pattern)
    out, skipping = [], False
    for line in src.split("\n"):
        if skipping:
            if line.rstrip() == "end":
                skipping = False
            continue
        m = rx.match(line)
        if m:
            out.append("%sfunction %s() end" % (m.group(1) or "", m.group(2)))
            if not line.rstrip().endswith("end"):
                skipping = True
            continue
        out.append(line)
    return "\n".join(out)


def build_harness(ch, mode):
    """Write chapters/<ch>/_harness.p8 (+ _h/ scratch sources). Returns cart path rel. to ROOT."""
    head, lua, data = split_cart(ch)
    base = os.path.join(ROOT, "chapters", ch)
    hdir = os.path.join(base, "_h")
    os.makedirs(hdir, exist_ok=True)
    tests = os.path.join(base, "tests", mode + ".lua")
    if not os.path.exists(tests):
        raise SystemExit("missing %s" % tests)
    write(os.path.join(hdir, "pre.lua"), read(os.path.join(HARNESS, "pre.lua")))
    write(os.path.join(hdir, "lib.lua"), read(os.path.join(HARNESS, "lib.lua")))
    write(os.path.join(hdir, "driver.lua"), read(tests))
    body = ["#include _h/pre.lua"]
    for k, l in enumerate(lua):
        if l.startswith("#include "):
            rel = l.split(None, 1)[1].strip()
            src = read(os.path.normpath(os.path.join(base, rel)))
            name = "%02d_%s" % (k, os.path.basename(rel))
            write(os.path.join(hdir, name), strip_functions(src, STRIP[mode]))
            body.append("#include _h/" + name)
        else:
            body.append(l)
    body += ["#include _h/lib.lua", "#include _h/driver.lua"]
    cart = os.path.join("chapters", ch, "_harness.p8")
    write(os.path.join(ROOT, cart), "\n".join(head + body + data))
    return cart


def cleanup(ch):
    import shutil
    base = os.path.join(ROOT, "chapters", ch)
    shutil.rmtree(os.path.join(base, "_h"), ignore_errors=True)
    for f in (os.path.join(base, "_harness.p8"),):
        try:
            os.remove(f)
        except OSError:
            pass


def fresh(*names):
    for n in names:
        try:
            os.remove(os.path.join(ROOT, n))
        except OSError:
            pass


# ---------------------------------------------------------------- smoke

def cmd_smoke(ch):
    fresh("p8log.txt")
    cart = build_harness(ch, "smoke")
    try:
        out, timed_out = run(cart, 90)
    finally:
        cleanup(ch)
    log = read(os.path.join(ROOT, "p8log.txt")) if os.path.exists(os.path.join(ROOT, "p8log.txt")) else ""
    fresh("p8log.txt")
    for line in log.strip().split("\n"):
        if line:
            print("  " + line)
    extra = [l for l in out.strip().split("\n") if l and not l.startswith("RUNNING")]
    ok = bool(re.search(r"^SMOKE OK", log, re.M)) and not timed_out
    if not ok:
        for l in extra:
            print("  [pico8] " + l)
        if timed_out:
            print("  [pico8] timed out (driver never reached stop())")
    print("%s smoke: %s" % (ch, "PASS" if ok else "FAIL"))
    return ok


# ---------------------------------------------------------------- shots

def write_png(path, rows, scale=3):
    w = len(rows[0]) * scale
    h = len(rows) * scale
    pal = [bytes(int(c[i:i + 2], 16) for i in (0, 2, 4)) for c in PAL]
    raw = bytearray()
    for r in rows:
        line = b"".join(pal[int(ch, 16)] * scale for ch in r)
        raw += (b"\x00" + line) * scale

    def chunk(tag, data):
        c = struct.pack(">I", len(data)) + tag + data
        return c + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)

    png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(bytes(raw), 9)) + chunk(b"IEND", b"")
    with open(path, "wb") as f:
        f.write(png)


def cmd_shots(ch):
    fresh("p8log.txt", "p8shots.txt")
    cart = build_harness(ch, "shots")
    try:
        out, timed_out = run(cart, 90)
    finally:
        cleanup(ch)
    path = os.path.join(ROOT, "p8shots.txt")
    if not os.path.exists(path):
        print("no screenshots written")
        for l in out.strip().split("\n"):
            print("  [pico8] " + l)
        return False
    lines = [l for l in read(path).split("\n") if l]
    os.makedirs(os.path.join(ROOT, "tmp", "shots"), exist_ok=True)
    # keep the raw dump so two runs can be diffed pixel-for-pixel (e.g. before/after an optimisation)
    write(os.path.join(ROOT, "tmp", "shots", "%s_dump.txt" % ch), "\n".join(lines) + "\n")
    log = ""
    if os.path.exists(os.path.join(ROOT, "p8log.txt")):
        log = read(os.path.join(ROOT, "p8log.txt"))
    fresh("p8shots.txt", "p8log.txt")
    clips = [l for l in log.split("\n") if l.startswith("CLIP")]
    for l in clips:
        print("  " + l)
    n, i = 0, 0
    while i < len(lines):
        if lines[i].startswith("SHOT "):
            name = lines[i][5:].strip()
            rows = lines[i + 1: i + 129]
            if len(rows) == 128 and all(len(r) == 128 for r in rows):
                dest = os.path.join(ROOT, "tmp", "shots", "%s_%s.png" % (ch, name))
                write_png(dest, rows)
                print("  tmp/shots/%s_%s.png" % (ch, name))
                n += 1
            i += 129
        else:
            i += 1
    ok = n > 0 and not timed_out and not clips
    for l in out.strip().split("\n"):
        if l and not l.startswith("RUNNING"):
            print("  [pico8] " + l)
    print("%s shots: %d written, %d clipped strings (%s)" % (ch, n, len(clips), "ok" if ok else "FAIL"))
    return ok


# ---------------------------------------------------------------- release build / web export

def strip_lua_comments(text):
    """Remove `--` comments (quote-aware) and blank lines. Tokens are unaffected."""
    out = []
    for line in text.split("\n"):
        q, cut, i = None, len(line), 0
        while i < len(line):
            c = line[i]
            if q:
                if c == "\\":
                    i += 1
                elif c == q:
                    q = None
            elif c in "\"'":
                q = c
            elif c == "-" and line.startswith("--", i):
                cut = i
                break
            i += 1
        s = line[:cut].rstrip()
        if s.strip():
            out.append(s)
    return "\n".join(out) + "\n"


def release_tree(ch, pad_chars=0):
    """Copy common/src + the chapter into tmp/web/ with comments stripped; returns the cart
    path (relative to ROOT). pad_chars > 0 appends incompressible filler (used by `size`)."""
    import random
    import shutil
    web = os.path.join(ROOT, "tmp", "web")
    shutil.rmtree(web, ignore_errors=True)
    for rel in (os.path.join("common", "src"), os.path.join("chapters", ch, "src")):
        os.makedirs(os.path.join(web, rel))
        for name in sorted(os.listdir(os.path.join(ROOT, rel))):
            if name.endswith(".lua"):
                write(os.path.join(web, rel, name), strip_lua_comments(read(os.path.join(ROOT, rel, name))))
    cart = read(cart_path(ch))
    if pad_chars:
        rng = random.Random(1)
        alphabet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        pad = ["zpad%d=\"%s\"" % (k, "".join(rng.choice(alphabet) for _ in range(min(1000, pad_chars - k * 1000))))
               for k in range((pad_chars + 999) // 1000)]
        write(os.path.join(web, "chapters", ch, "zz_pad.lua"), "\n".join(pad) + "\n")
        cart = cart.replace("__gfx__", "#include zz_pad.lua\n__gfx__", 1)
    dest = os.path.join("tmp", "web", "chapters", ch, ch + ".p8")
    write(os.path.join(ROOT, dest), cart)
    return dest


def export_js(cart, out_dir, js):
    """pico8 -export <js> <cart> with cwd=out_dir (bare filename keeps the output relative).
    Returns (ok, message)."""
    target = os.path.join(out_dir, js)
    before = os.path.getmtime(target) if os.path.exists(target) else 0
    p = subprocess.run([PICO8, "-export", js, os.path.join(ROOT, cart)], cwd=out_dir,
                       capture_output=True, text=True, timeout=120)
    out = ((p.stdout or "") + (p.stderr or "")).strip()
    ok = os.path.exists(target) and os.path.getmtime(target) > before and "failed" not in out
    return ok, out


def cmd_export(ch):
    docs = os.path.join(ROOT, "docs")
    ok, out = export_js(release_tree(ch), docs, ch + ".js")
    if ok:
        print("%s export: docs/%s.js (%s bytes, comments stripped)" % (ch, ch, format(os.path.getsize(os.path.join(docs, ch + ".js")), ",")))
    else:
        print("%s export FAILED: %s" % (ch, out or "no output written"))
        print("  compressed code is over 15,360 bytes - trim code/strings (run `size` to measure)")
    return ok


def cmd_size(ch):
    """Binary-search how much incompressible filler still exports: ~ the remaining headroom."""
    scratch = os.path.join(ROOT, "tmp", "web")
    lo, hi = 0, 16000
    ok, _ = export_js(release_tree(ch), scratch if os.path.isdir(scratch) else ROOT, "size_probe.js")
    if not ok:
        print("%s: already over the 15,360-byte compressed limit even with comments stripped" % ch)
        return False
    while hi - lo > 250:
        mid = (lo + hi) // 2
        ok, _ = export_js(release_tree(ch, mid), scratch if os.path.isdir(scratch) else ROOT, "size_probe.js")
        lo, hi = (mid, hi) if ok else (lo, mid)
    print("%s: ~%d bytes of incompressible code still fit under the 15,360-byte web-export limit "
          "(real code compresses ~2:1, so roughly %d chars)" % (ch, lo, lo * 2))
    return True

def main():
    if len(sys.argv) < 2 or sys.argv[1] not in ("tokens", "smoke", "shots", "all", "export", "size"):
        print(__doc__)
        return 2
    cmd = sys.argv[1]
    ch = sys.argv[2] if len(sys.argv) > 2 else "ch01"
    if not os.path.exists(PICO8):
        print("PICO-8 not found at %s (set the PICO8 env var)" % PICO8)
        return 2
    steps = {"tokens": [cmd_tokens], "smoke": [cmd_smoke], "shots": [cmd_shots],
             "export": [cmd_export], "size": [cmd_size],
             "all": [cmd_tokens, cmd_smoke, cmd_shots]}[cmd]
    ok = True
    for s in steps:
        ok = s(ch) and ok
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
