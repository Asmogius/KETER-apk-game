#!/usr/bin/env python3
"""Add an entry to What's New or the Change Log, at the top, every time.

Entries used to be inserted by searching for the previous version string. When
the file fell out of order that search matched the wrong place, so new entries
landed mid-file and at least one was dropped without anyone noticing. A fixed
marker cannot drift.
"""
import sys, pathlib

MARKERS = {
    "whatsnew.md":  "<!-- NEWEST ENTRY GOES BELOW THIS LINE -->",
    "changelog.md": "<!-- NEWEST REVISION GOES BELOW THIS LINE -->",
}

def add(fname, text):
    marker = MARKERS[fname]
    p = pathlib.Path(fname)
    s = p.read_text(encoding="utf-8")
    if marker not in s:
        raise SystemExit(f"{fname} has lost its marker; fix that before adding")
    i = s.index(marker) + len(marker)
    p.write_text(s[:i] + "\n\n" + text.strip() + "\n" + s[i:], encoding="utf-8")
    print(f"added to {fname}")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        raise SystemExit("usage: add_entry.py <whatsnew.md|changelog.md> <text>")
    add(sys.argv[1], sys.argv[2])
