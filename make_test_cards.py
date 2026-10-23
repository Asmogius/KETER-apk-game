#!/usr/bin/env python3
"""The test cards: realistic cards whose job is to exercise every keyword in the
library, so the Battle Simulator can be checked against what the Handbook says.
They are ordinary cards with real numbers, marked testCard so the Source filter
can show or hide them as "Test Cards". Each records the keywords it covers and
what should happen, which debug mode turns into a checklist."""
import json, sys

D3=[{"district":"3","symbol":"\u20ac","level":2}]
def A(name,kind,text,role="",dmg="",rng="",hit="",ap="",nrg=""):
    a={"name":name,"kind":kind,"text":text}
    if role: a["role"]=role
    if dmg!="": a["damage"]=str(dmg)
    if rng!="": a["attackRange"]=str(rng)
    if hit!="": a["toHit"]=str(hit)
    if ap!="":  a["armorPenetration"]=str(ap)
    if nrg!="": a["energyCost"]=str(nrg)
    return a
def card(cid,t,name,abilities,expect,covers,stats=None,**kw):
    c={"id":cid,"cardType":t,"name":name,"affinities":D3,"archetypes":[],"rarity":kw.pop("rarity","common"),
       "level":1,"stats":stats or {},"entries":abilities,
       "testCard":True,"testCovers":covers,"testExpect":expect}
    c.update(kw)
    # the pixel art shipped with the app (test_pictures.js, made by make_test_art.py)
    slug="".join(ch if ch.isalnum() else "_" for ch in name.lower())
    while "__" in slug: slug=slug.replace("__","_")
    c["pixelArt"]="px_test_"+slug+"_art"
    if t in ("hero","troop","enemy","elite","miniboss"): c["pixelToken"]="px_test_"+slug+"_token"
    return c

CARDS=[
 # ---- Heroes ----
 card("D3-H04","hero","Test Warden",[
   A("Pinning Volley","Active","[[target enemy]] takes [[damage 2]] and gains [[Pinned]] for [[turns 2]].","ranged",4,5,8,4,1),
   A("Overwatch","Active","[[Suppressive Fire]].","ranged",5,5,8,6,2),
   A("Field Medicine","Active","[[target ally]] gains [[heal 5]]. [[target ally]] gains [[remove Poisoned]].","support",nrg=1),
   A("Steady Nerve","Passive","[[this Unit]] gains [[INT +1]].")],
   ["Pinning Volley: on a hit, 2 extra damage and the target is Pinned for 2 turns",
    "Overwatch: Hold fire appears only if the Warden has not moved; it pays 2 Energy, and the first Enemy to move into range is shot",
    "A Pinned Enemy is always hit by that reaction shot",
    "Field Medicine: another friendly Unit heals 5 and loses Poisoned; the Warden cannot target itself",
    "Steady Nerve: an always-on Passive — the Warden's Integrity is 1 higher for as long as it stands"],
   ["target enemy","damage","Pinned","Suppressive Fire","target ally","heal","remove","this Unit","INT"],
   {"hp":"30","ac":"13","int":"13","apT":"4","move":"4","ldr":"4"}, combatRoles=["ranged"], archetypes=["Veteran Tactician"]),
 card("D3-H05","hero","Test Striker",[
   A("Shoulder Check","Active","[[target enemy]] takes [[Push 2]].","melee",4,"","",6,1),
   A("Rending Blow","Active","[[if]] [[the target]] [[takes damage]], [[target enemy]] gains [[Bleed]] and [[Sundered 2]] for [[turns 3]].","melee",6,"","",8,2),
   A("Finisher","Active","[[target enemy]] faces an [[Execute]]. [[if]] [[this Unit]] [[kills an enemy]], [[this Unit]] gains [[heal 4]].","melee",5,"","",6,1),
   A("Bloodied Fury","Passive","[[while]] [[this Unit]] [[is below half HP]], [[this Unit]] gains [[DMG +2]].")],
   ["Shoulder Check: the target is pushed 2 tiles straight away; blocked, it and anything it hit take 1 per tile lost",
    "Rending Blow: only when it damages, the target gains Bleed and Sundered 2 for 3 turns",
    "Bleed deals 10% of remaining Health (at least 1) at each Recharge for its 3 turns",
    "Sundered lowers Armor Class by 2 for all 3 turns, then ends",
    "Finisher: heals 4 only when its own blow Incapacitates the Enemy",
    "Finisher: an Enemy its blow leaves below half its Health is Executed (never an Elite, a Mini-Boss or a Boss), but that doesn't count as its blow's kill",
    "Bloodied Fury: while the Striker is below half its Health it deals 2 more damage, and the bonus goes when it is healed past half"],
   ["Push","if","the target","takes damage","Bleed","Sundered","kills an enemy","while","is below half HP","DMG","Execute"],
   {"hp":"34","ac":"14","int":"14","apT":"4","move":"4","ldr":"2"}, combatRoles=["melee"], archetypes=["Fighter"]),
 # ---- Troops ----
 card("D3-T35","troop","Test Drone",[
   A("Lift Off","Passive","[[this Unit]] gains [[Flying]]."),
   A("Tag","Active","[[target enemy]] gains [[Marked]] for [[turns 2]].","ranged",2,6,6,4,1),
   A("Rapid Fire","Active","[[Burst 3]]. [[target enemy]] takes [[damage 1]].","ranged",2,5,8,4,2)],
   ["Lift Off: the Drone moves over walls, and melee attacks cannot hit it",
    "Tag: the target is Marked for 2 turns, so ranged attacks against it always hit",
    "Rapid Fire: three attacks for one payment of 2 Energy, each rolled separately, choosing the next target each time (automatically if only one is in reach)"],
   ["Flying","Marked","Burst"],
   {"hp":"12","ac":"10","int":"10","nrg":"3","move":"5","uslot":"1"},
   aetherCost={"generic":1,"affinity":0,"affinity2":0}, combatRoles=["ranged"], archetypes=["Drone"]),
 card("D3-T36","troop","Test Sapper",[
   A("Satchel Charge","Active","[[target enemy]] is caught in an [[AoE 1]] blast.","ranged",3,3,6,6,2),
   A("Dead Man's Switch","Passive","[[when]] [[this Unit]] [[is Incapacitated]], [[all enemies within 1]] take [[damage 3]]."),
   A("Field Patch","Passive","[[when]] [[the round begins]], [[this Unit]] gains [[heal 1]].")],
   ["Satchel Charge: everything within 1 tile of the target takes the full damage too, friend or foe",
    "Dead Man's Switch: when the Sapper goes down, each Enemy within 1 tile takes 3",
    "Field Patch: at every Recharge, as the round begins, the Sapper heals 1"],
   ["AoE","when","is Incapacitated","all enemies within","the round begins"],
   {"hp":"16","ac":"11","int":"11","nrg":"3","move":"3","uslot":"1"},
   aetherCost={"generic":1,"affinity":1,"affinity2":0}, combatRoles=["ranged"], archetypes=["Kamikaze"]),
 card("D3-T37","troop","Test Battery",[
   A("Overcharge","Active","[[this Unit]] is spent as a [[Sacrifice]]. [[all allies within 2]] gain [[MS +1]] for [[turns 2]].","support"),
   A("Jump Start","Passive","[[when]] [[this Unit]] [[is deployed]], [[all allies within 2]] gain [[heal 2]].")],
   ["Overcharge: the Battery is removed and counts as Incapacitated",
    "Friendly Units within 2 tiles gain 1 Movement for 2 turns, then it wears off",
    "Jump Start: as the Battery is deployed, friendly Units within 2 tiles of it heal 2"],
   ["Sacrifice","all allies within","turns","is deployed"],
   {"hp":"8","ac":"8","int":"8","nrg":"3","move":"2","uslot":"1"}, token=True,
   aetherCost={"generic":0,"affinity":0,"affinity2":0}, combatRoles=["support"]),
 card("D3-T38","troop","Test Scout",[
   A("Quick Shot","Active","[[if]] [[this Unit]] [[deals damage]], [[this Unit]] gains [[MS +1]] for [[turns 1]].","ranged",2,5,7,3,1),
   A("Spotter","Passive","[[when]] [[an enemy]] [[Support]] or [[Cyber]] [[moves]], [[that Unit]] gains [[Marked]]."),
   A("Steady Hands","Passive","[[while]] [[any Unit]] [[District 3]] [[is at full HP]], [[this Unit]] gains [[AP +1]].")],
   ["Quick Shot: on a damaging hit the Scout gains 1 Movement for a turn",
    "Spotter: an Enemy with the Support or Cyber subtype that finishes a move is Marked for 1 turn",
    "Steady Hands: while any District 3 Unit on the board (either side) is at full Health, the Scout Penetrates 1 better"],
   ["deals damage","an enemy","Support","Cyber","moves","while","any Unit","District","is at full HP"],
   {"hp":"12","ac":"11","int":"11","nrg":"3","move":"5","uslot":"1"},
   aetherCost={"generic":1,"affinity":0,"affinity2":0}, combatRoles=["ranged","support"], archetypes=["Light Infantry"]),
 card("D3-T39","troop","Test Swarm",[
   A("Swarm Bite","Active","[[target enemy]] takes [[damage X]].","melee",1,"","",4,1)],
   ["It costs X: playing it asks for X first, from 1 up to what the Bank can pay",
    "It arrives with 4 Health for each X: 12 at X = 3",
    "Swarm Bite: on a hit, X extra damage, with the X it was played for",
    "As a Starting Troop, or put down by a Deploy, nobody chose X: it is 1"],
   [],
   {"hp":"4(X)","ac":"9","int":"9","nrg":"3","move":"4","uslot":"1"},
   aetherCost={"generic":0,"affinity":"X","affinity2":0}, hasVariableCost=True, combatRoles=["melee"]),
 # Revision 16.1: the movement keywords
 card("D3-T40","troop","Test Skirmisher",[
   A("Pounce","Active","[[Lunge 2]]. [[Charge 2]].","melee",3,"","",5,1),
   A("Spring","Active","[[this Unit]] gains [[Leap 3]] for [[turns 2]].","support",nrg=1),
   A("Light Feet","Passive","[[when]] [[this Unit]] [[deals damage]], [[this Unit]] gains [[Dash 2]].")],
   ["Pounce: it can strike an Enemy up to 3 tiles away, walking up to 2 tiles to stand beside it first, free; the Lunge keeps off hazards where it can, then takes the shortest way, then the tile with the most Cover beside it",
    "Pounce: 2 more damage once the Skirmisher has moved 3 tiles or more this turn, the Lunge's tiles included",
    "Spring: for 2 turns its moves can jump up to 3 tiles, over Units, walls, Cover and gaps",
    "Light Feet: each time it deals damage, it may move 2 tiles more this turn, even after attacking"],
   ["Lunge","Charge","Leap","Dash"],
   {"hp":"14","ac":"11","int":"11","nrg":"3","move":"4","uslot":"1"},
   aetherCost={"generic":1,"affinity":1,"affinity2":0}, combatRoles=["melee"], archetypes=["Light Infantry"]),
 # Revision 16.3: shapes, cover and Hardened
 card("D3-T41","troop","Test Bulwark",[
   A("Raise Wall","Active","[[Barricade Full]] on [[target tile]].","support","",3,"","",1),
   A("Breach Shot","Active","[[Line 3]].","ranged",3,5,8,5,1),
   A("Scatter Shot","Active","[[Cone 2]].","ranged",2,3,7,3,1),
   A("Bracing","Passive","[[when]] [[this Unit]] [[is attacked]], [[this Unit]] gains [[Hardened 1]] for [[turns 1]].")],
   ["Raise Wall: an empty tile within 3 becomes Full Cover for the rest of the fight; a tile with a Unit or an object on it is refused",
    "Breach Shot: on a hit, every other Unit on the 3 tiles running straight from the Bulwark through its target takes the same damage, friend or foe",
    "Scatter Shot: on a hit, every other Unit in the wedge 2 tiles deep toward its target takes the same damage, friend or foe",
    "Bracing: each time it is attacked, hit or miss, it gains Hardened 1 for 1 turn: every hit on it deals 1 less, never below 1, a Poisoned or Bleed tick included"],
   ["Barricade","target tile","Line","Cone","Hardened"],
   {"hp":"16","ac":"12","int":"11","nrg":"3","move":"3","uslot":"1"},
   aetherCost={"generic":1,"affinity":1,"affinity2":0}, combatRoles=["ranged"], archetypes=["Shield-Bearer"]),
 # ---- Enemies ----
 card("D3-E12","enemy","Test Grunt",[
   A("Jab","Combo","[[target enemy]] gains [[Weakened 2]] for [[turns 2]]. [[if]] [[the target]] [[has Slowed]], [[target enemy]] takes [[damage 1]].","melee",3,"","",6),
   A("Bash","Combo","[[if]] [[the target]] [[takes damage]], [[target enemy]] gains [[Slowed 2]].","melee",4,"","",6),
   A("Thick Skull","Passive","[[when]] [[this Unit]] [[is attacked]], [[this Unit]] gains [[AC +1]] for [[turns 1]].")],
   ["Jab: the struck Unit deals 2 less damage for 2 turns, and a Slowed one takes 1 more",
    "Bash: when it damages, the struck Unit loses 2 Movement for one turn",
    "The Grunt alternates Jab and Bash as a Combo",
    "Thick Skull: each time the Grunt is attacked, hit or miss, it gains +1 AC for 1 turn"],
   ["Weakened","Slowed","has","is attacked"],
   {"hp":"18","ac":"10","move":"3","int":"10"}, skullLevel="1", combatRoles=["melee"], archetypes=["Light Infantry"], salvage="troop"),
 card("D3-E13","enemy","Test Gunner",[
   A("Long Shot","Combo","[[if]] [[the target]] [[is further than 3]], [[target enemy]] takes [[damage 2]].","ranged",3,6,8,5),
   A("Point Blank","Combo","[[if]] [[the target]] [[is within 1]], [[target enemy]] gains [[Stunned]].","ranged",4,2,6,6)],
   ["Long Shot: 2 extra damage only when the target is more than 3 tiles away",
    "Point Blank: the target is Stunned for 1 turn (no moving or acting) only when it is within 1 tile",
    "Neither can shoot through a wall"],
   ["is further than","is within","Stunned"],
   {"hp":"16","ac":"11","move":"3","int":"11"}, skullLevel="1", combatRoles=["ranged"], archetypes=["Gunfighter"], salvage="equipment"),
 card("D3-E14","enemy","Test Hacker",[
   A("Spike","Combo","[[Burst 2]]. [[target enemy]] gains [[Drained 2]] for [[turns 2]].","ranged",2,4,8,4),
   A("Breach","Special","[[if]] [[the target]] [[takes damage]], [[target enemy]] gains [[Slowed 1]].","cyber",3,5,6,2),
   A("Feedback","Passive","[[when]] [[an enemy]] [[ends its move within 2]], [[that Unit]] gains [[Drained 1]].")],
   ["Spike: a Burst of 2, each attack choosing its target afresh; the target generates 2 less Energy at each refill for 2 turns",
    "Breach: a Cyber attack \u2014 it must penetrate the target's Integrity, not its Armor Class, and Slows only what it damages",
    "Feedback: any of your Units that ends a move within 2 tiles of the Hacker is Drained 1 for 1 turn",
    "The Hacker is Skull Level 2, so it only spawns on a Level 2 Spawn Tile"],
   ["Drained","an enemy","ends its move within","that Unit"],
   {"hp":"14","ac":"10","move":"3","int":"10"}, skullLevel="2", combatRoles=["ranged","cyber"], archetypes=["Disabler"], salvage="aether"),
 card("D3-E15","enemy","Test Skitter",[
   A("Claw","Combo","[[Lunge 2]]. [[Charge 1]].","melee",3,"","",5),
   A("Rake","Combo","[[if]] [[the target]] [[takes damage]], [[this Unit]] gains [[Dash 2]].","melee",2,"","",5),
   A("Spring Legs","Passive","[[this Unit]] gains [[Leap 2]]."),
   A("Skittish","Passive","[[this Unit]] gains [[Dash 1]].")],
   ["Claw: it strikes from up to 3 tiles away, lunging up to 2 tiles to stand beside its target first",
    "Claw: 1 more damage when it has moved 3 tiles or more this turn",
    "Rake: when it damages, it Dashes 2 tiles away from the Unit it struck, at once",
    "Spring Legs: it can jump up to 2 tiles over Units, walls and gaps as it moves",
    "Skittish: once it has attacked, it Dashes 1 tile away from the Unit it attacked last"],
   ["Lunge","Charge","Dash","Leap"],
   {"hp":"12","ac":"10","move":"4","int":"10"}, skullLevel="2", combatRoles=["melee"], archetypes=["Light Infantry"], salvage="troop"),
 # ---- Elite and Mini-Boss ----
 card("D3-EL01","elite","Test Juggernaut",[
   A("Plated Hide","Passive","[[this Unit]] gains [[Evasive 2]]. [[when]] [[this Unit]] [[takes damage]], [[if]] [[this Unit]] [[is below half HP]], [[this Unit]] gains [[AC +2]] for [[turns 2]]."),
   A("Slam","Combo","[[target enemy]] takes [[Push 1]]. [[adjacent]] units take [[damage 2]].","melee",7,"","",8),
   A("Venom Spit","Combo","[[target enemy]] gains [[Poisoned 3]] for [[turns 2]].","ranged",3,4,8,6)],
   ["Plated Hide: ranged attacks against it need 2 more to hit, for the whole fight; once below half Health, each hit it takes gives it +2 AC for 2 turns",
    "Slam: the target is pushed 1, and Units next to it take 2",
    "Venom Spit: Poisoned 3 for 2 turns deals 3 at each Recharge; a second dose adds its strength and turns"],
   ["Evasive","adjacent","Poisoned","when","if","is below half HP"],
   {"hp":"45","ac":"14","move":"3","int":"14"}, skullLevel="3", combatRoles=["melee"], archetypes=["Juggernaut"], salvage="troop"),
 card("D3-M01","miniboss","Test Overseer",[
   A("Arc Lash","Combo","[[target enemy]] takes [[Chain 3]].","ranged",5,5,8,7),
   A("Call Reinforcement","Special","[[Deploy 1 Test Grunt]] [[adjacent]].","support"),
   A("Oppressive Presence","Aura","[[Aura 2]]: [[all enemies within 2]] gain [[Weakened 1]]."),
   A("Vengeance","Passive","[[when]] [[an ally]] [[Melee]] [[within 3]] [[is Incapacitated]], [[this Unit]] gains [[DMG +1]] [[persistent]].")],
   ["Arc Lash: after the hit, the same damage jumps to the nearest other target within 3",
    "Call Reinforcement: a Test Grunt appears beside the Overseer",
    "Oppressive Presence: while within 2 tiles of it, your Units are Weakened 1",
    "Vengeance: each time a Melee Enemy within 3 tiles of it goes down, the Overseer deals 1 more damage for the rest of the fight"],
   ["Chain","Deploy","Aura","an ally","Melee","within"],
   {"hp":"70","ac":"15","move":"3","int":"15"}, skullLevel="4", combatRoles=["ranged"], archetypes=["General"], salvage="mixed"),
 # ---- Action Cards ----
 card("D3-A13","action","Test Piercing Rounds",[
   A("Piercing Rounds","Active","[[target enemy]] takes a round that [[Pierce]]s through.","ranged",5,6,8,6,2)],
   ["The shot hits the target, then the Unit directly behind it for the same damage",
    "Assigned to a Hero, it appears in that Hero's action bar"],
   ["Pierce"], aetherCost={"generic":0,"affinity":1,"affinity2":0}, rarity="uncommon"),
 card("D3-A14","action","Test Overclock Routine",[
   A("Overclock Routine","Active","[[Overclock]]: [[this Unit]] gains [[DMG +2]] for [[turns 2]]. [[this Unit]] gains [[Drained 2]].","support",nrg=1)],
   ["The Hero deals 2 more damage for 2 turns",
    "and pays for it: 2 less Energy on its next refill"],
   ["Overclock"], aetherCost={"generic":0,"affinity":1,"affinity2":0}, rarity="uncommon"),
 card("D3-A15","action","Test Overcharge",[
   A("Overcharge","Active","[[target enemy]] takes [[damage X]].","ranged",3,5,8,4,1)],
   ["Carried by a Hero, it asks for X each time it is used, and takes X District 3 Aether as well as its Energy",
    "On a hit, X extra damage"],
   [], aetherCost={"generic":0,"affinity":"X","affinity2":0}, hasVariableCost=True, rarity="uncommon"),
 # ---- Equipment ----
 card("D3-EQ17","equipment","Test Capacitor",[
   A("","Passive","[[attached Unit]] gains [[HP +X]].")],
   ["It costs 1 District 3 and X: the wearer has X more Health, maximum and current, while it wears it"],
   [], aetherCost={"generic":"X","affinity":1,"affinity2":0}, hasVariableCost=True, rarity="uncommon"),
 card("D3-EQ15","equipment","Test Plating",[
   A("","Passive","[[attached Unit]] gains [[AC +2]]. [[when]] [[attached Unit]] [[gains Slowed]], [[attached Unit]] gains [[remove Slowed]].")],
   ["The wearer's Armor Class rises by 2 while it carries the Plating",
    "and drops back the moment the Plating is removed",
    "Anything that Slows the wearer is shaken off at once"],
   ["attached Unit","gains"], aetherCost={"generic":1,"affinity":0,"affinity2":0}),
 card("D3-EQ16","equipment","Test Targeting Suite",[
   A("","Passive","[[attached Unit]] gains [[Range +1]] and [[AP +2]] [[while attached]]. [[when]] [[attached Unit]] [[attacks]], [[attached Unit]] gains [[Evasive 1]].")],
   ["The wearer's ranged Actions reach 1 tile further",
    "and Penetrate 2 better",
    "Each time the wearer attacks, hit or miss, it is Evasive 1 for a turn"],
   ["while attached","attacks"], aetherCost={"generic":1,"affinity":1,"affinity2":0}, rarity="uncommon"),
 # ---- Commands ----
 card("D3-CM04","command","Test Mortar Strike",[
   A("","Active","[[all units within 1]] of [[target tile]] take [[damage 4]].")],
   ["Playing it asks for a tile, shows the area and who it would catch, and waits for Confirm",
    "Everything within 1 of that tile takes 4, friend or foe"],
   ["all units within","target tile"], aetherCost={"generic":2,"affinity":0,"affinity2":0}),
 card("D3-CM05","command","Test Snare",[
   A("","Active","[[target enemy]] gains [[Rooted]] for [[turns 2]].")],
   ["The chosen Enemy cannot move for 2 turns"],
   ["Rooted"], aetherCost={"generic":1,"affinity":1,"affinity2":0}),
 card("D3-CM07","command","Test Rally",[
   A("","Active","[[all allies within 3]] [[Ranged]] gain [[AC +1]] for [[turns 2]].")],
   ["Every Ranged friendly Unit within 3 tiles of the Hero gains +1 AC for 2 turns",
    "A Melee Unit in the same area gains nothing"],
   ["Ranged","all allies within"], aetherCost={"generic":1,"affinity":0,"affinity2":0}),
 card("D3-CM06","command","Test Strip",[
   A("","Active","[[target ally]] gains [[remove Equipment]].")],
   ["Takes one piece of Equipment off another friendly Unit, to the Discard Pile",
    "Anything that Equipment granted while attached goes with it"],
   [], aetherCost={"generic":1,"affinity":0,"affinity2":0}),
 card("D3-CM08","command","Test Barrage",[
   A("","Active","[[target enemy]] takes [[damage X]] and gains [[Weakened X]] for [[turns 2]].")],
   ["Playing it asks for X, then for the Enemy",
    "The Enemy takes X damage and deals X less damage for 2 turns",
    "The Log says what X was"],
   [], aetherCost={"generic":"X","affinity":0,"affinity2":0}, hasVariableCost=True),
 card("D3-CM11","command","Test Muster",[
   A("","Active","[[all allies]] [[Hero]] gain [[Aim +2]] for [[turns 1]]. [[all allies]] [[Troop]] gain [[Hardened 1]] for [[turns 1]]. [[gain Aether 1]].")],
   ["No target to pick: every friendly Hero on the Battlefield gets +2 to hit for 1 turn, and every friendly Troop Hardened 1 for 1 turn",
    "Aim only helps ranged and Cyber attacks: a Melee strike is not helped",
    "Then 1 District 3 Aether goes into the Bank, the card's own District"],
   ["all allies","Hero","Troop","Aim","gain Aether"], aetherCost={"generic":2,"affinity":0,"affinity2":0}),
 # ---- Aether ----
 card("D3-AE13","aether","Test Drone Bank",[
   A("","Active","[[Deploy X Test Drone]].")],
   ["It costs XX: 2 Aether for each X",
    "X Test Drones arrive on open Player Spawn tiles; with fewer tiles open, the rest have nowhere to go"],
   [], aetherCost={"generic":"XX","affinity":0,"affinity2":0}, hasVariableCost=True, rarity="uncommon"),
 card("D3-AE12","aether","Test Surge",[
   A("","Active","[[target ally]] gains [[HP +5]] for [[turns 2]]. [[all allies within 3]] gain [[MS +1]] for [[turns 2]].")],
   ["The target ally gains +5 HP for 2 turns, maximum and current",
    "Friendly Units within 3 gain 1 Movement for 2 turns"],
   ["HP","MS"], aetherCost={"generic":2,"affinity":0,"affinity2":0}, rarity="uncommon"),
 card("D3-AE16","aether","Test Shockwave",[
   A("","Active","[[all enemies]] take [[damage 1]]. [[Draw 1]].")],
   ["No target to pick: every Enemy on the Battlefield takes 1 damage, however far away",
    "Then the top card of the Deck goes to your hand; with the Deck empty, nothing is drawn"],
   ["all enemies","Draw"], aetherCost={"generic":3,"affinity":0,"affinity2":0}, rarity="uncommon"),
 # ---- Consumables ----
 card("D3-CN01","consumable","Test Stim",[
   A("","Active","[[target ally]] gains [[heal 6]]. [[target ally]] gains [[NRG +1]] for [[turns 1]].")],
   ["Heals a friendly Unit by 6, never above its maximum, and gives it +1 NRG for 1 turn"],
   []),
 card("D3-CN02","consumable","Test Smoke",[
   A("","Active","[[this Unit]] counts as behind [[Half Cover]] for [[turns 2]].")],
   ["The user is treated as in Half Cover for 2 turns: +2 to be hit by ranged attacks"],
   ["Half Cover"]),
 card("D3-CN03","consumable","Test Sandbags",[
   A("","Active","[[target ally]] counts as behind [[Full Cover]] for [[turns 2]].")],
   ["The chosen friendly Unit is treated as in Full Cover for 2 turns: +4 to be hit by ranged attacks"],
   ["Full Cover"]),
 card("D3-CN04","consumable","Test Repair Kit",[
   A("","Active","[[Recover]] a Troop's card from the Discard Pile.")],
   ["Returns one Troop's card from the Discard Pile to your hand; with more than one there, it asks which",
    "It cannot be used while no Troop's card is in the Discard Pile",
    "A Troop's card is in the Discard Pile once that Troop has gone down, not before",
    "The Troop is then played again at its normal cost, onto an open Player Spawn tile"],
   ["Recover"]),
 # ---- Prototype ----
 card("D3-PR01","prototype","Test Aegis Core",[
   A("","Passive","[[all allies within 1]] gain [[AC +1]].")],
   ["Always on: friendly Units next to the leading Hero have +1 Armor Class, for as long as they stay next to it"],
   [], rarity="rare"),
 # ---- Aether Chip ----
 card("D3-AS05","sphere","Test Spark Chip",[
   A("","Active","[[target enemy]] takes [[damage 3]].")],
   ["In the Bank the chip is lit; spending it deals 3 to a chosen Enemy",
    "It still generates its Aether that turn, and recharges"],
   [], rarity="uncommon", chipValue="2"),
]

if __name__=="__main__":
    comp=json.load(open("compendium_full.json"))
    have={c.get("id") for c in comp["cards"]}
    comp["cards"]=[c for c in comp["cards"] if not c.get("testCard")]
    clash=[c["id"] for c in CARDS if c["id"] in have and not any(x.get("id")==c["id"] and x.get("testCard") for x in json.load(open("compendium_full.json"))["cards"])]
    if clash: sys.exit("number already taken: "+", ".join(clash))
    comp["cards"]+=CARDS
    json.dump(comp, open("compendium_full.json","w"), indent=1)
    print(f"{len(CARDS)} test cards written")
