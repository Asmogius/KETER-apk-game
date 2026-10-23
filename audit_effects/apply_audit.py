#!/usr/bin/env python3
"""Companion 14.10: the effect box audit, applied to compendium_full.json.
Every box the audit converted gets its keyword text (and the field fixes found
with it); every flagged box keeps its text and says why in needsReview; the 21
blank Units get their approved drafts. Run once, from the build folder:
    python3 audit_effects/apply_audit.py"""
import json, sys, os
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from conv import CONV
from drafts import DRAFTS

P = "compendium_full.json"
comp = json.load(open(P, encoding="utf-8"))
cards = comp["cards"]
done = {"text": 0, "fix": 0, "flag": 0, "drafted": 0}
for key, v in CONV.items():
    ci, ei = map(int, key.split("."))
    e = cards[ci]["entries"][ei]
    text, status, note = v[0], v[1], v[2]
    fixes = v[3] if len(v) > 3 else {}
    if status == "flag":
        e["needsReview"] = note
        done["flag"] += 1
    else:
        if e.get("text") != text:
            e["text"] = text
            done["text"] += 1
        e.pop("needsReview", None)
        if status == "partial":
            e["needsReview"] = "Left out of the keywords: " + note
    for f, val in fixes.items():
        e[f] = val
        done["fix"] += 1
    cards[ci]["lastEditedBy"] = "Claude"

by = {c["name"]: c for c in cards}
for name, d in DRAFTS.items():
    c = by[name]
    st = dict(c.get("stats") or {})
    st.update({k: str(v) for k, v in d["stats"].items()})
    c["stats"] = st
    c["combatRoles"] = d["combatRoles"]
    c["archetypes"] = d["archetypes"]
    if d.get("skullLevel"):
        c["skullLevel"] = d["skullLevel"]
    if d.get("rarity"):
        c["rarity"] = d["rarity"]
    ents = []
    for e in d["entries"]:
        out = {}
        for k, val in e.items():
            if val is None or val == "":
                continue
            out[k] = str(val) if k in ("energyCost", "damage", "attackRange", "toHit", "armorPenetration", "auraRadius") else val
        if "text" not in out:
            out["text"] = ""
        ents.append(out)
    c["entries"] = ents
    c["lastEditedBy"] = "Claude"
    done["drafted"] += 1

json.dump(comp, open(P, "w", encoding="utf-8"), indent=1)
print(done)
