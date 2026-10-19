#!/usr/bin/env python
"""Diff two screenshot dumps from `p8check.py shots` (tmp/shots/<ch>_dump.txt).

    python common/tools/shotdiff.py tmp/shots/baseline_dump.txt tmp/shots/ch01_dump.txt

Prints, per named shot, how many of the 16384 pixels differ - use it to prove that a
rendering refactor/optimisation is pixel-identical (or to see exactly what it changed).
"""
import sys


def load(path):
    shots, name, rows = {}, None, []
    for line in open(path, encoding="utf-8").read().split("\n"):
        if line.startswith("SHOT "):
            if name:
                shots[name] = rows
            name, rows = line[5:].strip(), []
        elif line:
            rows.append(line)
    if name:
        shots[name] = rows
    return shots


def main():
    a, b = load(sys.argv[1]), load(sys.argv[2])
    bad = 0
    for name in a:
        if name not in b:
            print("%-20s missing in second dump" % name)
            bad += 1
            continue
        n = sum(1 for ra, rb in zip(a[name], b[name]) for x, y in zip(ra, rb) if x != y)
        print("%-20s %5d px differ" % (name, n))
        bad += n > 0
    for name in b:
        if name not in a:
            print("%-20s new" % name)
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
