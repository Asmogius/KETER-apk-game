#!/usr/bin/env python3
"""Companion 14.11: round 2 of the effect box audit, applied to compendium_full.json.
The boxes 14.10 left flagged or partly written take the texts approved on the
Keyword Additions Review (conv2.py): written with Revision 16.3's keywords, or
rewritten; 14.10's partial texts stand, their notes cleared; four stay flagged.
Run once, from the build folder:   python3 audit_effects/apply_audit2.py"""
import json, sys, os
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from conv import CONV
from conv2 import CONV2

P = "compendium_full.json"
comp = json.load(open(P, encoding="utf-8"))
cards = comp["cards"]
# 14.10's partly written boxes not named in conv2 keep their text, and lose the note
for k, v in CONV.items():
    if v[1] == "partial" and k not in CONV2:
        CONV2[k] = (v[0], "keep", "")
done = {"text": 0, "fix": 0, "flag": 0, "settled": 0}
for key, v in CONV2.items():
    ci, ei = map(int, key.split("."))
    e = cards[ci]["entries"][ei]
    text, status, note = v[0], v[1], v[2]
    fixes = v[3] if len(v) > 3 else {}
    if status == "flag":
        e["needsReview"] = note
        done["flag"] += 1
        continue
    if e.get("text") != text:
        e["text"] = text
        done["text"] += 1
    else:
        done["settled"] += 1
    e.pop("needsReview", None)
    for f, val in fixes.items():
        e[f] = val
        done["fix"] += 1
    cards[ci]["lastEditedBy"] = "Claude"
json.dump(comp, open(P, "w", encoding="utf-8"), indent=1)
print(done)
