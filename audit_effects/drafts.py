# Drafts for the Units that are blank: stats, Combat Roles, Archetypes and abilities,
# from each one's name, role, Archetype and token. For approval before anything goes in.
import json


def combo(name, role, dmg=None, rng=None, hit=None, ap=None, text=""):
    return {"name": name, "kind": "Combo", "role": role, "damage": dmg, "attackRange": rng, "toHit": hit, "armorPenetration": ap, "text": text}


def act(name, role, nrg, dmg=None, rng=None, hit=None, ap=None, text=""):
    return {"name": name, "kind": "Active", "energyCost": nrg, "role": role, "damage": dmg, "attackRange": rng, "toHit": hit, "armorPenetration": ap, "text": text}


def passive(name, text):
    return {"name": name, "kind": "Passive", "text": text}


def aura(name, r, text):
    return {"name": name, "kind": "Aura", "auraRadius": r, "text": text}


def enemy(skull, hp, ac, ms, roles, arch, entries, why, salvage=None):
    d = {"skullLevel": skull, "stats": {"hp": hp, "ac": ac, "move": ms, "int": ac}, "combatRoles": roles, "archetypes": arch, "entries": entries, "why": why}
    return d


def troop(hp, nrg, ac, ms, slots, roles, arch, entries, why):
    return {"stats": {"hp": hp, "nrg": nrg, "ac": ac, "move": ms, "uslot": slots, "int": ac}, "combatRoles": roles, "archetypes": arch, "entries": entries, "why": why}


DRAFTS = {
 # ---------------------------------------------------------------- the Cleaner Bots (sanitation bots, gone wrong)
 '"Binder" Cleaner Bot': enemy(1, 16, 7, 3, ["ranged"], ["Disabler"], [
     combo("Foam Gun", "ranged", 3, 3, 9, text="[[target enemy]] gains [[Rooted]] for [[turns 1]]."),
     combo("Scrub", "melee", 4)],
     "Its foam gun binds: a light shot that roots, and a scrubbing arm up close. Disabler, as it pins Units down."),
 '"Hunter" Cleaner Bot': enemy(2, 20, 9, 4, ["ranged"], ["Sniper"], [
     combo("Harpoon", "ranged", 7, 5, 9, 1, "[[target enemy]] gains [[Slowed 2]]."),
     combo("Sensor Tag", "ranged", 2, 6, 8, text="[[target enemy]] gains [[Marked]] for [[turns 1]].")],
     "A harpoon gun and a sensor mast: it tags a target from afar for the others, then reels it in with a harpoon that slows."),
 '"Mincer" Cleaner Bot': {"stats": {"hp": 38, "ac": 11, "slots": 2, "apT": 4, "move": 3, "ldr": 2, "int": 11}, "rarity": "rare",
     "combatRoles": ["melee"], "archetypes": ["Berserker"], "entries": [
     act("Mince", "melee", 2, 8, text="[[target enemy]] gains [[Bleed]] for [[turns 2]]."),
     act("Grinding Drum", "melee", 3, 5, text="[[Burst 3]]."),
     passive("Overdrive Teeth", "[[while]] [[this Unit]] [[is below half HP]], [[this Unit]] gains [[DMG +3]].")],
     "why": "A Hero: a cleaner bot that kept its toothed drum. Berserker, so it hits harder the more it is hurt."},
 '"Purifier" Cleaner Bot': enemy(2, 24, 8, 3, ["ranged"], ["Fighter"], [
     combo("Sterilise", "ranged", 6, 2, 8, text="[[AoE 1]]. [[target enemy]] gains [[Poisoned 2]] for [[turns 2]]."),
     combo("Flare Up", "melee", 5)],
     "A flamethrower and fuel tanks: a short-range burst of fire that burns friend and foe (AoE), the burn as Poisoned. It had no Combat Role set."),
 '"Stitcher" Cleaner Bot': enemy(2, 18, 8, 3, ["support"], ["Spawner", "Healer"], [
     combo("Suture", "support", text="[[target ally]] gains [[heal 6]]."),
     combo("Reassemble", "support", text="[[Deploy 1 Exo Worker Husk]] [[adjacent]]."),
     combo("Needle", "melee", 4, text="[[target enemy]] gains [[Bleed]].")],
     "Needles and a thread spool: it sews its side back together, and stitches a husk back to its feet (Spawner)."),
 # ---------------------------------------------------------------- the Husks and the Centibot
 "Centibot": enemy(2, 22, 9, 4, ["ranged"], ["Disabler"], [
     combo("Static Antenna", "ranged", 4, 4, 9, text="[[target enemy]] gains [[Drained 1]] for [[turns 2]]."),
     combo("Coil", "melee", 5, text="[[target enemy]] gains [[Rooted]] for [[turns 1]].")],
     "Its front segments rear up round a disabler's antenna: it drains Energy at range and coils round anything close."),
 "Exo Worker Husk": enemy(1, 18, 5, 3, ["melee"], ["Fighter"], [
     combo("Rivet Punch", "melee", 5),
     combo("Grab", "melee", 3, text="[[target enemy]] gains [[Slowed 1]].")],
     "The plainer cousin of the Exo Husk (Skull 2): Skull 1, a worker frame that punches and grabs."),
 "Laz Welder Husk": enemy(2, 22, 6, 3, ["ranged"], ["Fighter"], [
     combo("Arc Weld", "ranged", 7, 2, 8, text="[[target enemy]] gains [[Sundered 2]] for [[turns 2]]."),
     combo("Torch", "melee", 5)],
     "A welding mask and gas bottle: a short-range weld that cuts through armour (Sundered)."),
 # ---------------------------------------------------------------- the Titans (Skull 5 and 6)
 "Construction Titan": enemy(5, 110, 16, 2, ["melee"], ["Juggernaut"], [
     combo("Wrecking Swing", "melee", 16, ap=2, text="[[target enemy]] takes [[Push 2]]."),
     combo("Stomp", "melee", 10, text="[[AoE 1]].")],
     "A walking construction frame: huge, slow, and it knocks Units back."),
 "Decimation Titan": enemy(6, 140, 17, 2, ["ranged"], ["Heavy Infantry"], [
     combo("Gatling Sweep", "ranged", 6, 5, 8, text="[[Burst 3]]."),
     combo("Missile Salvo", "ranged", 14, 7, 8, 2, "[[AoE 1]].")],
     "A gatling and missile racks: many shots close in, a blast from afar. No Combat Role was set: Ranged."),
 "Earthshaker Titan": enemy(6, 160, 17, 2, ["melee"], ["Juggernaut"], [
     combo("Hammer Fists", "melee", 18, ap=3, text="[[target enemy]] gains [[Stunned]] for [[turns 1]]."),
     combo("Quake", "melee", 8, text="[[AoE 2]]. [[target enemy]] gains [[Slowed 2]].")],
     "Hammer fists and cracked ground at its feet: a stunning blow, and a quake that slows all round it."),
 "Starkiller Titan": enemy(6, 130, 16, 2, ["ranged"], ["Sniper"], [
     combo("Rail Cannon", "ranged", 22, 9, 8, 4, "[[Pierce]]."),
     combo("Core Vent", "ranged", 8, 2, 8, text="[[AoE 1]]. [[target enemy]] gains [[Weakened 2]] for [[turns 2]].")],
     "A rail cannon that punches through a line, and a core that vents on anything that gets close."),
 "Titan Command Center": enemy(5, 120, 16, 1, ["support"], ["Spawner", "General"], [
     combo("Launch Bay", "support", text="[[Deploy 2 Exo Worker Husk]] [[adjacent]]."),
     combo("Point Defence", "ranged", 6, 4, 9),
     aura("Command Uplink", 3, "[[Aura 3]]: [[all allies within 3]] gain [[DMG +2]].")],
     "Tracks, a tower and a bay that lets things out: it sends out husks and drives its side harder."),
 # ---------------------------------------------------------------- the ONYX squad (rare Troops)
 "ONYX Assassin": troop(20, 3, 13, 5, 1, ["melee"], ["Assassin"], [
     act("Monofilament Blade", "melee", 2, 9, text="[[Lunge 2]]."),
     passive("Cape", "[[this Unit]] gains [[Evasive 2]].")],
     "A cape and a blade: it closes in fast and is hard to hit."),
 "ONYX Blademaster": troop(26, 4, 14, 4, 2, ["melee"], ["Fighter"], [
     act("Whirlwind", "melee", 2, 6, text="[[Burst 3]]."),
     passive("Riposte", "[[when]] [[this Unit]] [[is attacked]], [[target enemy]] takes [[damage 3]].")],
     "A sword: three cuts in one, and it answers every attack."),
 "ONYX Breacher": troop(28, 3, 14, 4, 2, ["melee", "ranged"], ["Door Kicker"], [
     act("Breaching Shotgun", "ranged", 2, 10, 2, 11, text="[[target enemy]] takes [[Push 1]]."),
     act("Breaching Charge", "ranged", 2, 6, 3, 12, text="[[AoE 1]]. [[target enemy]] gains [[Sundered 2]] for [[turns 2]].")],
     "A short heavy shotgun and a breaching charge on the belt."),
 "ONYX Brute": troop(35, 3, 12, 3, 2, ["melee"], ["Heavy Infantry"], [
     act("Power Fist", "melee", 2, 10, text="[[target enemy]] takes [[Push 2]]."),
     act("Haymaker", "melee", 3, 6, text="[[target enemy]] gains [[Stunned]] for [[turns 1]].")],
     "Power fists: knock them back, or knock them out."),
 "ONYX Guardian": troop(34, 3, 16, 3, 2, ["melee", "support"], ["Shield-Bearer"], [
     act("Shield Bash", "melee", 1, 5, text="[[target enemy]] takes [[Push 1]]."),
     aura("Shield Wall", 1, "[[Aura 1]]: [[all allies within 1]] gain [[AC +2]].")],
     "A tower shield: it guards those beside it."),
 "ONYX Sharpshooter": troop(20, 3, 12, 3, 1, ["ranged"], ["Sniper"], [
     act("Long Shot", "ranged", 2, 12, 8, 12, 2),
     passive("Ghillie Cloak", "[[this Unit]] gains [[Evasive 2]].")],
     "A long rifle and a ghillie cloak."),
 "ONYX Stitcher": troop(22, 4, 12, 4, 1, ["support"], ["Healer"], [
     act("Field Stitch", "support", 1, text="[[target ally]] gains [[heal 6]]."),
     act("Dermal Patch", "support", 2, text="[[target ally]] gains [[remove Bleed]]. [[target ally]] gains [[remove Poisoned]].")],
     "A med pack, a stitching arm and a glowing dermal patch: it heals, and clears Bleed and Poison."),
 "ONYX Wraith": troop(18, 3, 14, 5, 1, ["melee", "support"], ["Assassin"], [
     act("Phase Step", "support", 1, text="[[this Unit]] gains [[Leap 3]] for [[turns 1]]. [[this Unit]] gains [[Evasive 3]] for [[turns 1]]."),
     act("Shadow Blade", "melee", 2, 8, text="[[target enemy]] faces an [[Execute]].")],
     "A long shimmering cloak: it slips through and finishes the wounded (Execute)."),
}
