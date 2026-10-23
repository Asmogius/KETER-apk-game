#!/usr/bin/env python3
"""Content batch 1 (Companion 14.9, game 0.22): District 3, highly mobile melee.
The skitter-bots (Vantage Robotics' spider-legged assembly arms, gone feral in
the gantries), a jump-frame test pilot, and two of each other kind of card, all
written in keywords. Adds them to compendium_full.json, replacing any of the
same id; one you have since edited in the Card Forge keeps your edit."""
import json

D3 = lambda lvl=0: [{"district": "3", "symbol": "€", "level": lvl}]
def E(name, kind, text, role="", dmg="", rng="", hit="", ap="", nrg=""):
    e = {"name": name, "kind": kind, "text": text}
    if role: e["role"] = role
    if dmg != "": e["damage"] = str(dmg)
    if rng != "": e["attackRange"] = str(rng)
    if hit != "": e["toHit"] = str(hit)
    if ap != "": e["armorPenetration"] = str(ap)
    if nrg != "": e["energyCost"] = str(nrg)
    return e
def card(cid, t, name, entries, **kw):
    c = {"id": cid, "cardType": t, "name": name, "createdBy": "Claude", "lastEditedBy": "Claude",
         "affinities": kw.pop("affinities", D3()), "level": 1, "entries": entries, "batch": 1}
    c.update(kw)
    return c

CARDS = [
 # ---------------------------------------------------------------- Units
 card("D3-E16", "enemy", "Skitterling", [
   E("Weld Claw", "Combo", "[[Lunge 2]].", "melee", 4, "", "", 5),
   E("Hamstring", "Combo", "[[if]] [[the target]] [[takes damage]], [[target enemy]] gains [[Slowed 1]].", "melee", 3, "", "", 5),
   E("Gantry Legs", "Passive", "[[this Unit]] gains [[Leap 2]].")],
   archetypes=["Swarm"], combatRoles=["melee"], skullLevel=2, origin="Mechanical", salvage="troop",
   stats={"hp": "16", "ac": "11", "move": "5", "int": "10"},
   setDrops=[{"item": "bp:Lunge:1", "chance": 15}], lootPool=["bp:Dash:1"],
   lore="An assembly arm that learned to walk. It never learned to stop.", loreEnabled=True),
 card("D3-EL02", "elite", "Skitter Stalker", [
   E("Pounce", "Combo", "[[Lunge 3]]. [[Charge 3]].", "melee", 7, "", "", 7),
   E("Rend", "Combo", "[[if]] [[the target]] [[takes damage]], [[target enemy]] gains [[Bleed]] for [[turns 2]]. [[this Unit]] gains [[Dash 2]].", "melee", 5, "", "", 7),
   E("Spring-Steel Legs", "Passive", "[[this Unit]] gains [[Leap 3]].")],
   archetypes=["Assassin"], combatRoles=["melee"], skullLevel=3, origin="Mechanical", salvage="troop",
   behaviors=[{"k": "cunning"}], stats={"hp": "42", "ac": "14", "move": "5", "int": "13"},
   setDrops=[{"item": "bp:Leap:1", "chance": 30}, {"item": "cd:Grav-Boot Charge", "chance": 25}], lootPool=["bp:Charge:1", "bp:Lunge:2"],
   lore="It waits above the line, counting heartbeats.", loreEnabled=True),
 card("D3-M02", "miniboss", "Brood Matriarch", [
   E("Gantry Drop", "Combo", "[[Lunge 3]]. [[Charge 3]].", "melee", 9, "", "", 8),
   E("Scything Legs", "Combo", "[[Burst 2]].", "melee", 6, "", "", 7),
   E("Brood Call", "Aura", "[[Aura 2]]: [[all allies within 2]] gain [[MS +1]]."),
   E("Brood Panic", "Passive", "[[when]] [[the round begins]], [[if]] [[this Unit]] [[is below half HP]], [[Deploy 1 Skitterling]] [[adjacent]]."),
   E("Gantry Legs", "Passive", "[[this Unit]] gains [[Leap 2]].")],
   archetypes=["Spawner"], combatRoles=["melee"], skullLevel=4, origin="Mechanical", salvage="mixed",
   stats={"hp": "85", "ac": "15", "move": "4", "int": "15"},
   setDrops=[{"item": "ch:ch_skitter_frame", "chance": 25}, {"item": "cd:Kinetic Recycler", "chance": 40}], lootPool=["bp:Leap:2", "bp:Charge:2"],
   lore="The line's old fabricator. It still makes things.", loreEnabled=True),
 card("D3-H06", "hero", "Ilsa Varn, Jump-Frame Pilot", [
   E("Jump Jets", "Active", "[[this Unit]] gains [[Leap 4]] for [[turns 1]].", "support", nrg=1),
   E("Hammerfall", "Active", "[[Lunge 2]]. [[Charge 4]].", "melee", 7, "", "", 7, 2),
   E("Shoulder Thrusters", "Active", "[[target enemy]] takes [[Push 2]]. [[this Unit]] gains [[Dash 2]].", "melee", 4, "", "", 6, 1),
   E("Gyro-Stabilised", "Passive", "[[when]] [[this Unit]] [[kills an enemy]], [[this Unit]] gains [[Dash 2]].")],
   affinities=D3(3), rarity="epic", archetypes=["Fighter", "Light Infantry"], combatRoles=["melee"], origin="Human",
   stats={"hp": "32", "ac": "12", "int": "12", "slots": "2", "apT": "4", "move": "5", "ldr": "2"},
   lore="Vantage built the frame to test the gantries. She tests the frame.", loreEnabled=True),
 # ---------------------------------------------------------------- Aether
 card("D3-AE14", "aether", "Kinetic Surge", [E("", "Active", "[[all allies within 3]] gain [[Dash 2]].")],
   aetherCost={"generic": 2, "affinity": 1, "affinity2": 0}, rarity="uncommon"),
 card("D3-AE15", "aether", "Gravity Well", [E("", "Active", "[[all enemies within 2]] of [[target tile]] gain [[Slowed 2]] for [[turns 2]].")],
   aetherCost={"generic": 3, "affinity": 1, "affinity2": 0}, rarity="rare"),
 # ---------------------------------------------------------------- Equipment
 card("D3-EQ18", "equipment", "Leaper Greaves", [E("", "Passive", "[[attached Unit]] gains [[Leap 2]].")],
   aetherCost={"generic": 1, "affinity": 1, "affinity2": 0}, rarity="uncommon", stats={}),
 card("D3-EQ19", "equipment", "Momentum Plating", [E("", "Passive", "[[attached Unit]] gains [[AC +1]] [[while attached]]. [[when]] [[attached Unit]] [[moves]], [[attached Unit]] gains [[Evasive 1]].")],
   aetherCost={"generic": 2, "affinity": 1, "affinity2": 0}, rarity="rare", stats={}),
 # ---------------------------------------------------------------- Commands
 card("D3-CM09", "command", "Flank Them", [E("", "Active", "[[all allies within 3]] [[Melee]] gain [[Dash 2]].")],
   aetherCost={"generic": 1, "affinity": 1, "affinity2": 0}, rarity="common"),
 card("D3-CM10", "command", "Pin the Runner", [E("", "Active", "[[target enemy]] gains [[Rooted]] for [[turns 1]].")],
   aetherCost={"generic": 2, "affinity": 0, "affinity2": 0}, rarity="uncommon"),
 # ---------------------------------------------------------------- Chips
 card("D3-AS06", "sphere", "Spring Chip", [E("", "Active", "[[target ally]] gains [[Dash 1]].")],
   rarity="uncommon", aetherValue="1"),
 card("D3-AS07", "sphere", "Gyro Chip", [E("", "Active", "[[target ally]] gains [[Leap 2]] for [[turns 1]].")],
   rarity="rare", aetherValue="2"),
 # ---------------------------------------------------------------- Consumables
 card("D3-CN05", "consumable", "Grav-Boot Charge", [E("", "Active", "[[target ally]] gains [[Leap 3]] for [[turns 1]].")],
   rarity="common"),
 card("D3-CN06", "consumable", "Adrenal Overdrive", [E("", "Active", "[[target ally]] gains [[Dash 3]]. [[target ally]] gains [[DMG +1]] for [[turns 1]].")],
   rarity="uncommon"),
 # ---------------------------------------------------------------- Action cards
 card("D3-A16", "action", "Vault Strike", [E("Vault Strike", "Active", "[[Lunge 3]]. [[Charge 2]].", "melee", 5, "", "", 6, 2)],
   aetherCost={"generic": 0, "affinity": 1, "affinity2": 0}, rarity="rare"),
 card("D3-A17", "action", "Skitter Step", [E("Skitter Step", "Active", "[[this Unit]] gains [[Dash 3]].", "support", nrg=1)],
   aetherCost={"generic": 0, "affinity": 1, "affinity2": 0}, rarity="uncommon"),
 # ---------------------------------------------------------------- Prototypes
 card("D3-PR02", "prototype", "Kinetic Recycler", [E("", "Passive", "[[when]] [[an ally]] [[kills an enemy]], [[that Unit]] gains [[Dash 1]].")],
   rarity="rare"),
 card("D3-PR03", "prototype", "Gantry Mapper", [E("", "Passive", "[[all allies within 2]] gain [[Leap 2]].")],
   rarity="uncommon"),
]

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
    print(f"batch 1: {added} added, {replaced} replaced, {kept} kept as edited ({len(CARDS)} cards)")
