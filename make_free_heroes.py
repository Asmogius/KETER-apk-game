#!/usr/bin/env python3
"""The free Heroes (Companion 14.14, game 0.25): three plain Heroes of no
District who are always yours at the dock and never lost, so a Strike Team
can always leave, shards or none. The others are recruited (dock.js). Adds
them to compendium_full.json, replacing any of the same id; one you have since
edited in the Card Forge keeps your edit."""
import json

def E(name, kind, text, role="", dmg="", rng="", hit="", ap="", nrg=""):
    e = {"name": name, "kind": kind, "text": text}
    if role: e["role"] = role
    if dmg != "": e["damage"] = str(dmg)
    if rng != "": e["attackRange"] = str(rng)
    if hit != "": e["toHit"] = str(hit)
    if ap != "": e["armorPenetration"] = str(ap)
    if nrg != "": e["energyCost"] = str(nrg)
    return e
def hero(cid, name, entries, **kw):
    c = {"id": cid, "cardType": "hero", "name": name, "createdBy": "Claude", "lastEditedBy": "Claude",
         "affinities": [], "level": 1, "entries": entries, "rarity": "common", "origin": "Human"}
    c.update(kw)
    return c

CARDS = [
 hero("D0-H01", "Dock Hand", [
   E("Wrench Swing", "Active", "", "melee", 5, "", "", 5, 1),
   E("Shove", "Active", "[[target enemy]] takes [[Push 1]].", "melee", 3, "", "", 5, 1)],
   archetypes=["Fighter"], combatRoles=["melee"],
   stats={"hp": "32", "ac": "10", "int": "10", "slots": "1", "apT": "4", "move": "3", "ldr": "2"},
   lore="Loads the crates, fixes the lifts, and goes out when nobody else will.", loreEnabled=True),
 hero("D0-H02", "Hangar Rifleman", [
   E("Rifle Shot", "Active", "", "ranged", 5, 4, 9, 3, 1),
   E("Aimed Shot", "Active", "", "ranged", 7, 5, 10, 3, 2)],
   archetypes=["Gunfighter"], combatRoles=["ranged"],
   stats={"hp": "26", "ac": "11", "int": "11", "slots": "1", "apT": "4", "move": "3", "ldr": "2"},
   lore="Hangar watch, issue rifle, two magazines. The Hangar sends what it has.", loreEnabled=True),
 hero("D0-H03", "Field Medic", [
   E("Patch Up", "Active", "[[target ally]] gains [[heal 4]].", "support", nrg=1),
   E("Sidearm", "Active", "", "ranged", 3, 3, 8, 2, 1)],
   archetypes=["Healer"], combatRoles=["support"],
   stats={"hp": "24", "ac": "10", "int": "10", "slots": "1", "apT": "4", "move": "3", "ldr": "3"},
   lore="A satchel of dressings and a pistol she hopes not to need.", loreEnabled=True),
]
NAMES = [c["name"] for c in CARDS]

if __name__ == "__main__":
    comp = json.load(open("compendium_full.json"))
    by_id = {c.get("id"): i for i, c in enumerate(comp["cards"])}
    added = replaced = kept = 0
    for c in CARDS:
        i = by_id.get(c["id"])
        if i is None:
            comp["cards"].append(c); added += 1
        elif comp["cards"][i].get("lastEditedBy") not in (None, "Claude"):
            kept += 1          # someone has edited it in the Forge since: leave it
        else:
            comp["cards"][i] = c; replaced += 1
    json.dump(comp, open("compendium_full.json", "w"), indent=1)
    print(f"free Heroes: {added} added, {replaced} replaced, {kept} kept as edited ({len(CARDS)} cards)")
