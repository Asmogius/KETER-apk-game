## The keyword library (Handbook Revision 16.3), brought across from the
## Companion's keywords.js: the words in a card's text that carry rules meaning,
## how to read a marked text into them, how a sentence's grammar is sorted
## (Condition, Target, Effect, Duration), what is wrong with one, and how it
## prints. The tables are generated from keywords.js, word for word.
##
## Proved to read every card the same way the Companion does (tests/sim_diff.gd).
class_name Keywords
extends RefCounted

const CATEGORIES := [ { "k": "condition", "label": "Condition", "colour": "#b07be0", "hint": "When the effect applies at all." }, { "k": "target", "label": "Target", "colour": "#57d8e3", "hint": "Who or what it happens to." }, { "k": "effect", "label": "Effect", "colour": "#e0b34d", "hint": "What happens." }, { "k": "status", "label": "Status", "colour": "#d94f5c", "hint": "A named state applied to a Unit." }, { "k": "duration", "label": "Duration", "colour": "#e07bc8", "hint": "How long it lasts." }, { "k": "modifier", "label": "Modifier", "colour": "#7bd88f", "hint": "Changes how an Action works." }, { "k": "stats", "label": "Stats", "colour": "#6f9dff", "hint": "Raises or lowers a stat, for as long as its Duration." } ]
const KEYWORDS := [
	{"name":"Rooted","cat":"status","num":null,"numLabel":null,"weight":3,"desc":"Cannot move. It lasts as long as its Duration — 1 turn if none is given, 2 at most — then ends. A second dose does nothing while it lasts. When it ends, the Unit cannot be Rooted again until the same point of the next round. An always-on Passive cannot give it."},
	{"name":"Stunned","cat":"status","num":null,"numLabel":null,"weight":2,"desc":"Cannot act or move at all. It lasts as long as its Duration — 1 turn if none is given, 2 at most — then ends. A second dose does nothing while it lasts. When it ends, the Unit cannot be Stunned again until the same point of the next round. An always-on Passive cannot Stun."},
	{"name":"Slowed","cat":"status","num":"amount","numLabel":"Movement lost","weight":2,"desc":"Movement Speed reduced by the number. It lasts as long as its Duration — 1 turn if none is given — at full strength, then ends. A second dose adds its strength and its turns."},
	{"name":"Marked","cat":"status","num":null,"numLabel":null,"weight":3,"desc":"Ranged attacks against this Unit always hit. It lasts as long as its Duration — 1 turn if none is given, 2 at most — then ends. A second dose does nothing while it lasts. When it ends, the Unit cannot be Marked again until the same point of the next round. An always-on Passive cannot give it."},
	{"name":"Pinned","cat":"status","num":null,"numLabel":null,"weight":2,"desc":"Suppressive Fire reaction shots against this Unit always hit. It lasts as long as its Duration — 1 turn if none is given, 2 at most — then ends. A second dose does nothing while it lasts. When it ends, the Unit cannot be Pinned again until the same point of the next round. An always-on Passive cannot give it."},
	{"name":"Poisoned","cat":"status","num":"amount","numLabel":"Damage each turn","weight":3,"desc":"Deals the number in damage at each Recharge. It lasts as long as its Duration — 1 turn if none is given — at full strength, then ends. A second dose adds its strength and its turns."},
	{"name":"Bleed","cat":"status","num":null,"numLabel":null,"weight":3,"desc":"Deals 10% of the Unit's remaining Health at each Recharge (at least 1). It lasts as long as its Duration — 1 turn if none is given — at full strength, then ends. A second dose adds its strength and its turns."},
	{"name":"Weakened","cat":"status","num":"amount","numLabel":"Damage lost","weight":2,"desc":"Deals the number less damage. It lasts as long as its Duration — 1 turn if none is given — at full strength, then ends. A second dose adds its strength and its turns."},
	{"name":"Sundered","cat":"status","num":"amount","numLabel":"Armor lost","weight":2,"desc":"Armor Class reduced by the number. It lasts as long as its Duration — 1 turn if none is given — at full strength, then ends. A second dose adds its strength and its turns."},
	{"name":"Drained","cat":"status","num":"amount","numLabel":"Energy lost","weight":2,"desc":"Generates the number less Energy at each refill. It lasts as long as its Duration — 1 turn if none is given — at full strength, then ends. A second dose adds its strength and its turns."},
	{"name":"Evasive","cat":"status","num":"amount","numLabel":"To-Hit added","weight":3,"desc":"Adds its number to the To-Hit threshold of Ranged Attacks against this Unit. It lasts as long as its Duration — 1 turn if none is given — at full strength, then ends. A second dose adds its strength and its turns."},
	{"name":"Hardened","cat":"status","num":"amount","numLabel":"Damage stopped","weight":3,"desc":"Each hit on this Unit deals the number less damage, never below 1. It lasts as long as its Duration — 1 turn if none is given — at full strength, then ends. A second dose adds its strength and its turns."},
	{"name":"Overclock","cat":"modifier","num":null,"weight":3,"desc":"A Vantage Robotics mechanic: spend now for a stronger effect, at a cost paid afterwards. It has no rules in a fight yet, so it does nothing there and costs nothing."},
	{"name":"Aura","cat":"modifier","num":"amount","numLabel":"Radius","weight":3,"desc":"A Passive that affects only Units within its radius."},
	{"name":"Half Cover","cat":"target","num":null,"weight":0,"desc":"A Unit adjacent to a Half Cover Barricade gains +2 To-Hit against Ranged Attacks from the opposite side."},
	{"name":"Full Cover","cat":"target","num":null,"weight":0,"desc":"A Unit adjacent to a Full Cover Barricade gains +4 To-Hit against Ranged Attacks from the opposite side."},
	{"name":"damage","cat":"effect","num":"amount","numLabel":"Damage","weight":1,"desc":"Deals the number in damage."},
	{"name":"heal","cat":"effect","num":"amount","numLabel":"Health restored","weight":1,"desc":"Restores the number in Health, never above the Unit's maximum."},
	{"name":"HP","cat":"stats","num":"signed","numLabel":"Amount (+ or −)","weight":2,"desc":"Raises maximum Health by the amount, and current Health with it; lowers both when negative. It must carry a Duration."},
	{"name":"AC","cat":"stats","num":"signed","numLabel":"Amount (+ or −)","weight":2,"desc":"Raises or lowers Armor Class by the amount. It must carry a Duration."},
	{"name":"MS","cat":"stats","num":"signed","numLabel":"Amount (+ or −)","weight":2,"desc":"Raises or lowers Movement Speed by the amount. It must carry a Duration."},
	{"name":"DMG","cat":"stats","num":"signed","numLabel":"Amount (+ or −)","weight":2,"desc":"Raises or lowers the damage this Unit deals by the amount. It must carry a Duration."},
	{"name":"INT","cat":"stats","num":"signed","numLabel":"Amount (+ or −)","weight":2,"desc":"Raises or lowers Integrity, armour against Cyber, by the amount. It must carry a Duration."},
	{"name":"Range","cat":"stats","num":"signed","numLabel":"Amount (+ or −)","weight":2,"desc":"Raises or lowers the reach of ranged Actions by the amount. It must carry a Duration."},
	{"name":"AP","cat":"stats","num":"signed","numLabel":"Amount (+ or −)","weight":2,"desc":"Raises or lowers Armor Penetration by the amount. It must carry a Duration."},
	{"name":"Aim","cat":"stats","num":"signed","numLabel":"Amount (+ or −)","weight":2,"desc":"The Unit's ranged attacks need that much less to hit (more, when it is negative): the mirror of Evasive. It must carry a Duration."},
	{"name":"NRG","cat":"stats","num":"signed","numLabel":"Amount (+ or −)","weight":2,"desc":"Raises or lowers Energy by the amount. It must carry a Duration."},
	{"name":"Burst","cat":"modifier","num":"amount","numLabel":"Attacks in all","weight":4,"desc":"The Action is made the number of times in all, for one payment of its Energy. Each attack rolls and applies its effects separately; the next target is chosen each time, and it continues automatically when only one is in reach. It runs to the end while a target remains."},
	{"name":"Push","cat":"effect","num":"amount","numLabel":"Tiles","weight":2,"desc":"Moves the target that many tiles straight away from the attacker. Blocked, it stops and takes 1 damage per tile it could not move."},
	{"name":"Pierce","cat":"modifier","num":null,"numLabel":null,"weight":4,"desc":"The attack carries on through to the Unit directly behind the target."},
	{"name":"Chain","cat":"modifier","num":"amount","numLabel":"Tiles","weight":4,"desc":"The attack jumps to the nearest other Enemy within that many tiles, for the same damage."},
	{"name":"AoE","cat":"modifier","num":"amount","numLabel":"Tiles","weight":5,"desc":"Hits everything within that many tiles of the target, friend or foe, for full damage."},
	{"name":"Deploy","cat":"effect","num":"card","numLabel":"How many, and what","weight":4,"desc":"Puts a Unit or token on a friendly Spawn Tile, or beside the deploying Unit if the card says adjacent."},
	{"name":"Sacrifice","cat":"effect","num":null,"numLabel":null,"weight":0,"desc":"Removes a friendly Unit as a cost. It counts as Incapacitated, so anything triggering on a Unit going down still triggers. It never touches an Enemy."},
	{"name":"Execute","cat":"effect","num":null,"numLabel":null,"weight":6,"desc":"Removes an Enemy below half its Health outright. An Elite, a Mini-Boss or a Boss is never Executed, nor is an Enemy at half its Health or more: they are untouched."},
	{"name":"Suppressive Fire","cat":"modifier","num":null,"numLabel":null,"weight":4,"desc":"Hold fire: pay the Action's Energy now, and shoot the first Enemy that moves within range and line of sight during the Enemy turn."},
	{"name":"Flying","cat":"effect","num":null,"numLabel":null,"weight":5,"desc":"Ignores terrain and walls when moving, and cannot be hit by melee attacks."},
	# Revision 16.1: the movement keywords. Lunge and Charge belong on a Melee
	# Action; Dash and Leap are given to a Unit, like Flying.
	{"name":"Lunge","cat":"modifier","num":"amount","numLabel":"Tiles","weight":1,"desc":"On a Melee Action: before it attacks, the Unit may move up to that many tiles to reach its target, so the target may be that many tiles further off. The move costs no Movement and no Energy, walks round walls and Units, and ends beside the target (off a hazard if it can, then the shortest way, then the tile beside the most Cover). It counts toward Charge."},
	{"name":"Charge","cat":"modifier","num":"amount","numLabel":"Damage added","weight":1,"desc":"On a Melee Action: the attack deals that much more damage if the Unit has moved 3 tiles or more this turn before it lands. Walking, a Lunge, a Leap and a Dash count; being Pushed does not."},
	{"name":"Line","cat":"modifier","num":"amount","numLabel":"Tiles","weight":4,"desc":"Hits every Unit on the tiles running straight from the attacker through the target, that many tiles long, friend or foe, for full damage."},
	{"name":"Cone","cat":"modifier","num":"amount","numLabel":"Tiles","weight":4,"desc":"Hits every Unit in the wedge widening from the attacker toward the target, that many tiles deep, friend or foe, for full damage."},
	{"name":"Dash","cat":"effect","num":"amount","numLabel":"Tiles","weight":1,"desc":"The Unit may move that many tiles more this turn, before or after it acts. It is not a Stat, so Slowed does not cut it; Rooted and Stunned still stop it. An Enemy Dashes at once, away from the Unit it attacked."},
	{"name":"Leap","cat":"effect","num":"amount","numLabel":"Tiles","weight":1,"desc":"The Unit may jump to any empty tile within that many tiles that its Movement can pay for, over Units, Cover, walls, gaps and hazards: only the tile it lands on counts. With a Duration it lasts that long; without one, for the rest of the fight."},
	{"name":"remove","cat":"effect","num":"what","numLabel":"What to take off","weight":3,"desc":"Takes a piece of Equipment or a Status off the target, chosen by whoever plays it. A removed Equipment Card goes to the Discard Pile."},
	{"name":"Recover","cat":"effect","num":null,"numLabel":null,"weight":4,"desc":"Returns a Troop's card from the Discard Pile to your hand, chosen by whoever plays it. The Troop is played again at its normal cost."},
	{"name":"Draw","cat":"effect","num":"amount","numLabel":"Cards","weight":2,"desc":"Draws that many cards from your Deck into your hand. On an Enemy's card it does nothing."},
	{"name":"gain Aether","cat":"effect","num":"amount","numLabel":"Aether","weight":2,"desc":"Gains that much Aether of the card's own District, or Neutral Aether if the card has none. On an Enemy's card it does nothing."},
	{"name":"Barricade","cat":"effect","num":"cover","numLabel":"Half or Full","weight":3,"desc":"Puts a Half or Full Cover Barricade on the target tile, which must be empty. It stays for the rest of the fight."},
	{"name":"target enemy","cat":"target","num":null,"weight":0,"desc":"One Enemy within the Action's range and line of sight."},
	{"name":"target ally","cat":"target","num":null,"weight":0,"desc":"One friendly Unit within range and line of sight."},
	{"name":"target tile","cat":"target","num":null,"weight":0,"desc":"A tile within range and line of sight, whoever is standing on it."},
	{"name":"this Unit","cat":"target","role":"both","num":null,"weight":0,"desc":"The Unit using the Action, or the Unit whose card this is."},
	{"name":"attached Unit","cat":"target","role":"both","equipmentOnly":true,"num":null,"weight":0,"desc":"The Unit this card is attached to."},
	{"name":"all enemies within","cat":"target","num":"amount","numLabel":"Tiles","weight":1,"desc":"Every Enemy within that many tiles of the target."},
	{"name":"all allies within","cat":"target","num":"amount","numLabel":"Tiles","weight":1,"desc":"Every friendly Unit within that many tiles of the target."},
	{"name":"all units within","cat":"target","num":"amount","numLabel":"Tiles","weight":1,"desc":"Everything within that many tiles of the target, friend or foe."},
	{"name":"all allies","cat":"target","num":null,"weight":1,"desc":"Every friendly Unit on the Battlefield, the one using it included."},
	{"name":"all enemies","cat":"target","num":null,"weight":1,"desc":"Every Enemy on the Battlefield."},
	{"name":"adjacent","cat":"target","num":null,"weight":0,"desc":"Next to the target. On Deploy, places the new Unit beside the deploying one."},
	{"name":"the target","cat":"target","role":"subject","actionOnly":true,"num":null,"weight":0,"desc":"The Unit the Action was used on. Used in an Action's Condition."},
	{"name":"an ally","cat":"target","role":"subject","quant":"ally","num":null,"weight":0,"desc":"Any one friendly Unit other than this one. Used in a Condition."},
	{"name":"an enemy","cat":"target","role":"subject","quant":"enemy","num":null,"weight":0,"desc":"Any one Enemy. Used in a Condition."},
	{"name":"any Unit","cat":"target","role":"subject","quant":"any","num":null,"weight":0,"desc":"Any Unit at all, this one included. Used in a Condition."},
	{"name":"that Unit","cat":"target","role":"both","num":null,"weight":0,"desc":"The Unit the Condition is about: the one that took the damage, moved or was deployed."},
	{"name":"Melee","cat":"target","narrow":"subtype","num":null,"weight":0,"desc":"Narrows a Target to Units with the Melee subtype."},
	{"name":"Ranged","cat":"target","narrow":"subtype","num":null,"weight":0,"desc":"Narrows a Target to Units with the Ranged subtype."},
	{"name":"Support","cat":"target","narrow":"subtype","num":null,"weight":0,"desc":"Narrows a Target to Units with the Support subtype."},
	{"name":"Cyber","cat":"target","narrow":"subtype","num":null,"weight":0,"desc":"Narrows a Target to Units with the Cyber subtype."},
	{"name":"Troop","cat":"target","narrow":"cardtype","num":null,"weight":0,"desc":"Narrows a Target to Troops (every Troop is a mechanical robot)."},
	{"name":"Hero","cat":"target","narrow":"cardtype","num":null,"weight":0,"desc":"Narrows a Target to Heroes."},
	{"name":"District","cat":"target","narrow":"district","num":"district","numLabel":"District","weight":0,"desc":"Narrows a Target to Units of that District."},
	{"name":"within","cat":"target","narrow":"distance","num":"amount","numLabel":"Tiles","weight":0,"desc":"Narrows a Target to Units that many tiles or fewer from this Unit."},
	{"name":"when","cat":"condition","role":"connector","num":null,"weight":0,"desc":"Waits for an event, and the effect happens each time it does. Passives only."},
	{"name":"if","cat":"condition","role":"connector","num":null,"weight":0,"desc":"Checks something as the effect resolves; if it is not so, the effect does not happen."},
	{"name":"while","cat":"condition","role":"connector","num":null,"weight":0,"desc":"The effect is on for as long as a state holds, and off the moment it does not. Passives only."},
	{"name":"takes damage","cat":"condition","role":"event","actionIf":true,"num":null,"weight":0,"desc":"Loses at least 1 Health to an attack or an effect."},
	{"name":"deals damage","cat":"condition","role":"event","actionIf":true,"num":null,"weight":0,"desc":"Its own attack or effect takes at least 1 Health from another Unit. Damage from a Status or a hazard does not count."},
	{"name":"kills an enemy","cat":"condition","role":"event","actionIf":true,"num":null,"weight":0,"desc":"Its own attack or effect Incapacitates an Enemy. Damage from a Status or a hazard does not count."},
	{"name":"is deployed","cat":"condition","role":"event","num":null,"weight":0,"desc":"Arrives on the Battlefield: at the start of the fight, or when it is played or Deployed."},
	{"name":"is Incapacitated","cat":"condition","role":"event","actionIf":true,"num":null,"weight":0,"desc":"Is reduced to 0 Health or Sacrificed."},
	{"name":"attacks","cat":"condition","role":"event","num":null,"weight":0,"desc":"Makes an attack, whether or not it hits."},
	{"name":"is attacked","cat":"condition","role":"event","num":null,"weight":0,"desc":"Is the target of an attack, whether or not it hits."},
	{"name":"moves","cat":"condition","role":"event","num":null,"weight":0,"desc":"Finishes a move of its own. Being pushed does not count."},
	{"name":"ends its move within","cat":"condition","role":"event","noSelf":true,"num":"amount","numLabel":"Tiles","weight":0,"desc":"Finishes a move of its own that many tiles or fewer from this Unit."},
	{"name":"gains","cat":"condition","role":"event","num":"status","numLabel":"Status","weight":0,"desc":"Is given the named Status."},
	{"name":"the round begins","cat":"condition","role":"event","noSubject":true,"num":null,"weight":0,"desc":"The Recharge Phase of every round, as Statuses tick."},
	{"name":"is below half HP","cat":"condition","role":"state","num":null,"weight":0,"desc":"Has less than half of its maximum Health."},
	{"name":"is at full HP","cat":"condition","role":"state","num":null,"weight":0,"desc":"Has all of its maximum Health."},
	{"name":"has","cat":"condition","role":"state","num":"status","numLabel":"Status","weight":0,"desc":"Carries the named Status."},
	{"name":"is within","cat":"condition","role":"state","noSelf":true,"num":"amount","numLabel":"Tiles","weight":0,"desc":"Stands that many tiles or fewer from this Unit."},
	{"name":"is further than","cat":"condition","role":"state","noSelf":true,"num":"amount","numLabel":"Tiles","weight":0,"desc":"Stands more than that many tiles from this Unit."},
	{"name":"turns","cat":"duration","num":"amount","numLabel":"Turns","weight":1,"desc":"How long the effect lasts, from 2 to 10 turns."},
	{"name":"persistent","cat":"duration","num":null,"weight":3,"desc":"Lasts until something removes it."},
	{"name":"while attached","cat":"duration","num":null,"weight":2,"desc":"Lasts as long as the card granting it stays on the Unit, so a bonus from Equipment ends when that Equipment is removed."},
]
const RETIRED := ["SPOOL","Splash","if this penetrates","when combat begins","Modify","Human","Cyborg","Mechanical","Overwhelmed","Compromised","WIL"]
const STATS := ["HP","AC","MS","NRG","INT","DMG","Range","AP","Aim"]
const ARCHETYPES := ["Juggernaut","Spawner","Assassin","Sniper","Commando","Kamikaze","Shield-Bearer","Healer","Fighter","Transport","Gunfighter","Door Kicker","Veteran Tactician","Disabler","Berserker","Devourer","Tinkerer","Light Infantry","Heavy Infantry","Drone","O.B.O.L.™ Bot","Battle Buddy™ Bot","Swarm","General","Necromancer","Abomination","Chaff"]

## Archetypes a card carries join the narrowing words (the Roster adds them).
static var extra_arch: Array = []
static var _all_list: Array = []
static var _rx := {}
## What the library works out from its tables is worked out once, and again
## only when the cards bring a new Archetype: a fight reads card text
## constantly, and a phone should not feel it.
static var _stamp = null         # the Archetypes the lists below were built for
static var _arch: Array = []
static var _lows: Array = []     # each keyword's name in lower case, alongside _all_list
static var _index := {}          # lower-case name -> keyword
static var _resolved := {}       # token -> what it resolves to
static var _parsed := {}         # text -> its parts
static var _split := {}          # text -> its sentences


static func _re(p: String) -> RegEx:
	if not _rx.has(p):
		_rx[p] = RegEx.create_from_string(p)
	return _rx[p]


static func _test(p: String, s: String) -> bool:
	return _re(p).search(s) != null


## JavaScript's s.replace(/p/g, fn): every match replaced by what fn makes of it.
static func _replace_all(s: String, p: String, fn: Callable) -> String:
	var out := ""
	var last := 0
	for m in _re(p).search_all(s):
		out += s.substr(last, m.get_start() - last) + str(fn.call(m))
		last = m.get_end()
	return out + s.substr(last)


static func _grp(m: RegExMatch, i: int) -> String:
	return m.get_string(i) if m.get_start(i) >= 0 else ""


## Revision 15.6: the old one-piece Conditions are rewritten as they're read.
static func migrate_text(text) -> String:
	var s := "" if text == null else str(text)
	if s.find("[[") < 0:
		return s
	s = _replace_all(s, "(?i)\\[\\[\\s*if damaged\\s*\\]\\]", func(_m): return "[[if]] [[the target]] [[takes damage]]")
	s = _replace_all(s, "(?i)\\[\\[\\s*when deployed\\s*\\]\\]", func(_m): return "[[when]] [[this Unit]] [[is deployed]]")
	s = _replace_all(s, "(?i)\\[\\[\\s*when Incapacitated\\s*\\]\\]", func(_m): return "[[when]] [[this Unit]] [[is Incapacitated]]")
	s = _replace_all(s, "(?i)\\[\\[\\s*if this Unit kills an Enemy\\s*\\]\\]", func(_m): return "[[if]] [[this Unit]] [[kills an enemy]]")
	s = _replace_all(s, "(?i)\\[\\[\\s*further than(?:\\s+(\\d+))?\\s*\\]\\](?:\\s*(\\d+))?", func(m):
		var a := _grp(m, 1)
		var b := _grp(m, 2)
		return "[[if]] [[the target]] [[is further than " + (a if a != "" else (b if b != "" else "1")) + "]]")
	s = _replace_all(s, "(?i)\\[\\[\\s*closer than(?:\\s+(\\d+))?\\s*\\]\\](?:\\s*(\\d+))?", func(m):
		var a := _grp(m, 1)
		var v = Rules.num(a if a != "" else _grp(m, 2), 0)
		return "[[if]] [[the target]] [[is within " + str(maxi(0, (v if Rules.truthy(v) else 1) - 1)) + "]]")
	return s


static func register_archetypes(list) -> void:
	for a in (list if list is Array else []):
		var s := str(a if a != null else "").strip_edges()
		if s != "" and not extra_arch.has(s):
			extra_arch.append(s)


static func _build() -> void:
	var stamp := extra_arch.hash()
	if _stamp != null and _stamp == stamp:
		return
	_stamp = stamp
	var seen := {}
	_arch = []
	for a0 in ARCHETYPES + extra_arch:
		var a := str(a0 if a0 != null else "").strip_edges()
		var low := a.to_lower()
		if a == "" or seen.has(low):
			continue
		if RETIRED.any(func(r): return r.to_lower() == low):
			continue
		if KEYWORDS.any(func(k): return k["name"].to_lower() == low):
			continue
		seen[low] = 1
		_arch.append(a)
	_all_list = KEYWORDS.duplicate()
	for a in _arch:
		_all_list.append({"name": a, "cat": "target", "narrow": "archetype", "num": null, "weight": 0, "archetype": true,
			"desc": "Narrows a Target to " + a + " Units. " + a + " is an Archetype."})
	_lows = _all_list.map(func(k): return k["name"].to_lower())
	_index = {}
	for i in _all_list.size():
		if not _index.has(_lows[i]):
			_index[_lows[i]] = _all_list[i]
	_resolved = {}
	_parsed = {}
	_split = {}


static func archetypes() -> Array:
	_build()
	return _arch.duplicate()


static func all_keywords() -> Array:
	_build()
	return _all_list


static func by_name(n) -> Variant:
	_build()
	return _index.get(str(n if n != null else "").strip_edges().to_lower())


static func is_retired(n) -> bool:
	var want := str(n if n != null else "").strip_edges().to_lower()
	return RETIRED.any(func(r): return r.to_lower() == want)


static func category(k) -> Variant:
	for c in CATEGORIES:
		if c["k"] == k:
			return c
	return null


static func colour_of(name) -> Variant:
	var kw = by_name(name)
	if kw == null:
		return null
	var c = category(kw["cat"])
	return c["colour"] if c != null else null


## A marked keyword in stored text: [[Name]] or [[Name N]]. The keyword is the
## longest name that starts the token; the rest is its parameter.
static func resolve(token) -> Dictionary:
	_build()
	var raw := str(token if token != null else "").strip_edges()
	if not _resolved.has(raw):
		_resolved[raw] = _resolve(raw)
	return _resolved[raw].duplicate()


static func _resolve(raw: String) -> Dictionary:
	var low := raw.to_lower()
	var best = null
	var best_len := -1
	for i in _all_list.size():
		var n: String = _lows[i]
		if (low == n or low.begins_with(n + " ")) and n.length() > best_len:
			best = _all_list[i]
			best_len = n.length()
	if best != null:
		var rest := raw.substr(best["name"].length()).strip_edges()
		return {"kw": best, "name": best["name"], "param": rest if rest != "" else null, "retired": false}
	var ret = null
	for r in RETIRED:
		var n2: String = r.to_lower()
		if low == n2 or low.begins_with(n2 + " "):
			ret = r
	if ret != null:
		var rest2 := raw.substr(ret.length()).strip_edges()
		return {"kw": null, "name": ret, "param": rest2 if rest2 != "" else null, "retired": true}
	var sm := _re("^([+-](?:\\d+|X))\\s+(.+)$").search(raw)
	if sm != null:
		var sk = by_name(sm.get_string(2))
		if sk != null and sk["cat"] == "stats":
			return {"kw": sk, "name": sk["name"], "param": sm.get_string(1), "retired": false}
	var m := _re("^(.*?)\\s+([+-]?\\d+)$").search(raw)
	return {"kw": null, "name": m.get_string(1) if m != null else raw, "param": m.get_string(2) if m != null else null, "retired": false}


## Card text as text and keyword parts: {type: "text", text} and
## {type: "kw", name, n, kw, retired}. (Each call hands back parts of its own.)
static func parse(text) -> Array:
	_build()
	var key := str(text if text != null else "")
	if not _parsed.has(key):
		_parsed[key] = _parse(text)
	return _parsed[key].map(func(p): return p.duplicate())


static func _parse(text) -> Array:
	var out := []
	var last := 0
	var src := migrate_text(text)
	for m in _re("\\[\\[([^\\]]+)\\]\\](?:\\s*(\\d+))?").search_all(src):
		if m.get_start() > last:
			out.append({"type": "text", "text": src.substr(last, m.get_start() - last)})
		var r := resolve(m.get_string(1))
		var n = m.get_string(2) if m.get_start(2) >= 0 else r["param"]
		out.append({"type": "kw", "name": r["name"], "n": n, "kw": r["kw"], "retired": r["retired"]})
		last = m.get_end()
	if last < src.length():
		out.append({"type": "text", "text": src.substr(last)})
	return out


static func is_distance(kw) -> bool:
	return kw != null and (kw.get("numLabel") == "Tiles" or kw.get("numLabel") == "Radius")


static func plural(n, one: String) -> String:
	return str(n) + " " + one + ("" if str(n) == "1" else "s")


## How a keyword reads on a card: +2 AC, for 2 turns, within 2 tiles.
static func label(p, before = "") -> String:
	if p == null:
		return ""
	if p["type"] == "text":
		return p["text"]
	var kw = p["kw"]
	var n := "" if p["n"] == null else str(p["n"]).strip_edges()
	if kw != null and kw["cat"] == "stats" and n != "":
		var v := n
		if _test("^(\\d|X$)", v):
			v = "+" + v
		return v + " " + p["name"]
	if kw != null and kw["name"] == "turns" and n != "":
		var has_for := _test("(?i)\\bfor\\s*$", str(before if before != null else ""))
		return ("" if has_for else "for ") + plural(n, "turn")
	if kw != null and is_distance(kw) and _test("^(\\d+|X)$", n):
		return p["name"] + " " + plural(n, "tile")
	# Revision 16.3: Barricade Full reads "Full Cover Barricade"
	if kw != null and kw["name"] == "Barricade":
		return ((n.substr(0, 1).to_upper() + n.substr(1).to_lower() + " Cover ") if n != "" else "") + "Barricade"
	return p["name"] + ((" " + n) if n != "" else "")


## One sentence is one effect.
static func sentences(text) -> Array:
	var s := str(text if text != null else "")
	if not _split.has(s):
		var out := []
		var last := 0
		for m in _re("(?<=[.!?])\\s+").search_all(s):
			out.append(s.substr(last, m.get_start() - last))
			last = m.get_end()
		out.append(s.substr(last))
		_split[s] = out.map(func(t): return t.strip_edges()).filter(func(t): return t != "")
	return _split[s].duplicate()


## Sorts a sentence's keywords into the grammar: an optional [when] clause, an
## optional [if]/[while] check, who it happens to (each with its narrowing
## words), and what it does.
static func analyse(sent) -> Dictionary:
	var out := {"when": null, "check": null, "targets": [], "effects": [], "mods": [], "durations": [], "covers": [],
		"bad": [], "stray": [], "all": []}
	var clause = null
	var last_target = null
	for p in parse(sent):
		if p["type"] != "kw":
			continue
		out["all"].append(p)
		if p["kw"] == null:
			out["bad"].append(p)
			continue
		var k: Dictionary = p["kw"]
		if k.get("role") == "connector":
			if clause != null:
				out["stray"].append(clause["connector"])
			clause = {"connector": p, "subject": null, "narrow": [], "event": null}
			continue
		if clause != null:
			if k["cat"] == "target" and Rules.truthy(k.get("narrow")):
				clause["narrow"].append(p)
				continue
			if k["cat"] == "target" and clause["subject"] == null and (k.get("role") == "subject" or k.get("role") == "both"):
				clause["subject"] = p
				continue
			if k.get("role") == "event" or k.get("role") == "state":
				clause["event"] = p
				var c := {"connector": clause["connector"]["kw"]["name"], "subject": clause["subject"], "narrow": clause["narrow"], "event": p}
				if c["connector"] == "when" and out["when"] == null:
					out["when"] = c
				elif out["check"] == null and c["connector"] != "when":
					out["check"] = c
				else:
					out["stray"].append(p)
				clause = null
				last_target = null
				continue
		if k.get("role") == "event" or k.get("role") == "state":
			out["stray"].append(p)
			continue
		if k["cat"] == "target":
			if Rules.truthy(k.get("narrow")):
				if last_target != null:
					last_target["narrow"].append(p)
				else:
					out["stray"].append(p)
				continue
			if k["name"] == "Half Cover" or k["name"] == "Full Cover":
				out["covers"].append(p)
				continue
			last_target = {"part": p, "narrow": []}
			out["targets"].append(last_target)
			continue
		if k["cat"] == "modifier":
			out["mods"].append(p)
			continue
		if k["cat"] == "duration":
			out["durations"].append(p)
			continue
		if k["cat"] == "condition":
			out["stray"].append(p)
			continue
		out["effects"].append(p)
	if clause != null:
		out["stray"].append(clause["connector"])
	return out


static func kind_of(tag) -> String:
	var t := str(tag if tag != null else "").to_lower()
	return "passive" if (t == "passive" or t == "aura") else "action"


static func is_continuous(an: Dictionary) -> bool:
	return an["when"] == null


## What is wrong with a sentence, for the kind of ability it belongs to.
static func problems(an: Dictionary, ctx = null) -> Array:
	if ctx == null:
		ctx = {}
	var kind: String = ctx.get("kind") if Rules.truthy(ctx.get("kind")) else "action"
	var out := []
	var nm := func(p) -> String: return "" if p == null else (p["kw"]["name"] if p["kw"] != null else p["name"])
	for p in an["stray"]:
		var k: Dictionary = p["kw"] if p["kw"] != null else {}
		if k.get("role") == "connector":
			out.append("“" + k["name"] + "” has no event or state after it")
		elif k.get("role") == "event" or k.get("role") == "state":
			out.append("“" + k["name"] + "” needs a connector before it (when, if or while)")
		elif Rules.truthy(k.get("narrow")):
			out.append("“" + label(p) + "” narrows nothing: put it after a Target")
		else:
			out.append("“" + nm.call(p) + "” is out of place")
	if kind == "action":
		if an["when"] != null:
			out.append("an Action cannot use “when” — that is for Passives. Use “if”")
		if an["check"] != null and an["check"]["connector"] == "while":
			out.append("an Action cannot use “while” — that is for Passives")
	else:
		if an["check"] != null and an["check"]["connector"] == "if" and an["when"] == null:
			out.append("in a Passive, “if” follows a “when”; for something that stays true, use “while”")
		if an["when"] != null and an["check"] != null and an["check"]["connector"] == "while":
			out.append("“when” and “while” cannot share an effect; check with “if”")
	for c in [an["when"], an["check"]]:
		if c == null:
			continue
		var ev: Dictionary = c["event"]["kw"]
		var conn: String = c["connector"]
		var subj = c["subject"]["kw"] if c["subject"] != null else null
		if conn == "when" and ev.get("role") != "event":
			out.append("“when” waits for an event, and “" + ev["name"] + "” is a state; use “while” or “if”")
		if conn == "while" and ev.get("role") != "state":
			out.append("“while” needs a state, and “" + ev["name"] + "” is an event; use “when”")
		if conn == "if" and ev.get("role") == "event" and not (kind == "action" and Rules.truthy(ev.get("actionIf"))):
			out.append("“if” checks a state, and “" + ev["name"] + "” is an event" + (" an Action cannot check" if kind == "action" else "; use “when”"))
		if Rules.truthy(ev.get("noSubject")) and subj != null:
			out.append("“" + ev["name"] + "” is about no one, so it takes no Target before it")
		if not Rules.truthy(ev.get("noSubject")) and subj == null:
			out.append("“" + ev["name"] + "” needs to say who: this Unit, an ally, an enemy…")
		if subj != null and Rules.truthy(ev.get("noSelf")) and (subj["name"] == "this Unit" or subj["name"] == "attached Unit"):
			out.append("“" + ev["name"] + "” is measured from this Unit, so it needs someone else before it")
		if subj != null and subj["name"] == "the target" and kind != "action":
			out.append("“the target” is for Actions; in a Passive, use “that Unit” or an ally/enemy")
		if subj != null and subj["name"] == "that Unit" and not (conn != "when" and an["when"] != null and an["when"]["subject"] != null):
			out.append("“that Unit” points back at a “when” that names someone")
		if ev.get("num") == "status" and by_name(str(c["event"]["n"] if c["event"]["n"] != null else "")) == null:
			out.append("“" + ev["name"] + "” needs a Status to name")
	# Revision 15.8: X stands for a number only on a card whose Aether cost has an X
	if ctx.has("variable") and ctx["variable"] is bool and ctx["variable"] == false and an["all"].any(func(p): return is_x_part(p)):
		out.append("X needs a variable cost: put X in this card's Aether cost, or write a number")
	for t in an["targets"]:
		var k2: Dictionary = t["part"]["kw"]
		if k2.get("role") == "subject":
			out.append("“" + k2["name"] + "” belongs in a Condition; who the effect happens to is a Target such as target enemy or that Unit")
		if k2["name"] == "that Unit" and not ((an["when"] != null and an["when"]["subject"] != null) or (an["check"] != null and an["check"]["subject"] != null)):
			out.append("“that Unit” points back at a Condition that names someone")
	# Handbook 16.0: an always-on Passive (no "when") cannot keep anyone locked
	for p in an["effects"]:
		var lk: bool = ["Stunned", "Rooted", "Pinned", "Marked"].has(p["kw"]["name"])
		if lk and kind == "passive" and an["when"] == null:
			out.append("an always-on Passive cannot Stun: give it a “when”" if p["kw"]["name"] == "Stunned" else "an always-on Passive cannot keep anyone " + p["kw"]["name"] + ": give it a “when”")
		# and a lock lasts 2 turns at most
		if lk:
			for d in an["durations"]:
				var dn: String = str(d["kw"]["name"]) if d.get("kw") != null else ""
				var t = Scoring.digits(d.get("n"))
				if dn == "persistent" or dn == "while attached" or (dn == "turns" and t != null and int(t) > 2):
					out.append(p["kw"]["name"] + " lasts 2 turns at most: use turns 1 or 2")
	# Revision 16.1: Lunge and Charge are made with an attack
	for p in an["mods"]:
		if (p["kw"]["name"] == "Lunge" or p["kw"]["name"] == "Charge") and kind == "passive":
			out.append(str(p["kw"]["name"]) + " is made with an attack: put it on a Melee Action")
	# Revision 16.3: Line and Cone are shapes an attack makes; a Barricade is Half or Full, on a tile
	for p in an["mods"]:
		if (p["kw"]["name"] == "Line" or p["kw"]["name"] == "Cone") and kind == "passive":
			out.append(str(p["kw"]["name"]) + " is a shape an attack makes: put it on an Action")
	for p in an["effects"]:
		if p["kw"]["name"] != "Barricade":
			continue
		if not _test("(?i)^(Half|Full)$", str(p["n"] if p["n"] != null else "").strip_edges()):
			out.append("Barricade needs Half or Full")
		if not an["targets"].any(func(t): return t["part"]["kw"]["name"] == "target tile"):
			out.append("Barricade goes on a tile: use target tile")
	# Execute removes an Enemy: aimed at anyone else it would do nothing
	if an["effects"].any(func(p): return p["kw"]["name"] == "Execute") and not (not an["targets"].is_empty() and an["targets"].all(func(t): return t["part"]["kw"]["name"] == "target enemy" or t["part"]["kw"]["name"] == "all enemies within" or t["part"]["kw"]["name"] == "all enemies" or t["part"]["kw"].get("role") == "narrow" or Rules.truthy(t["part"]["kw"].get("narrow")))):
		out.append("Execute removes an Enemy: use target enemy or all enemies within")
	# Sacrifice removes a friendly Unit as a cost; it is not a way to kill Enemies
	if an["effects"].any(func(p): return p["kw"]["name"] == "Sacrifice") and an["targets"].any(func(t): return t["part"]["kw"]["name"] == "target enemy" or t["part"]["kw"]["name"] == "all enemies within" or t["part"]["kw"]["name"] == "all enemies"):
		out.append("Sacrifice removes a friendly Unit: use this Unit, target ally or all allies within")
	return out


# ---------------------------------------------------------------- variable costs
## Revision 15.8. A card whose Aether cost holds an X may write X wherever a
## keyword takes a number: [[damage X]], [[HP +X]], [[turns X]], [[Deploy X
## Aether Battery]]. X is chosen as the card is played, at least 1, and from
## then on the text reads with that number. Only a keyword's own number
## counts: a Deploy of a card called "Model X" is left alone.
static func _x_spot(inner) -> Variant:
	var raw := str(inner if inner != null else "").strip_edges()
	var m := _re("(?i)^(deploy\\s+)X(\\s+.+)$").search(raw)
	if m != null:
		return {"pre": m.get_string(1), "post": m.get_string(2)}
	if _test("(?i)^deploy(\\s|$)", raw):
		return null
	m = _re("^(.*\\S\\s+[+-]?)X$").search(raw)
	if m != null:
		return {"pre": m.get_string(1), "post": ""}
	m = _re("^([+-])X(\\s+.+)$").search(raw)
	if m != null:
		return {"pre": m.get_string(1), "post": m.get_string(2)}
	return null


static func is_x_part(p) -> bool:
	if p == null or p.get("type") != "kw" or p.get("n") == null:
		return false
	var n := str(p["n"]).strip_edges()
	return _test("^[+-]?X$", n) or (p.get("kw") != null and p["kw"].get("num") == "card" and _test("^X\\s", n))


static func uses_x(text) -> bool:
	for m in _re("\\[\\[([^\\]]+)\\]\\]").search_all(str(text if text != null else "")):
		if _x_spot(m.get_string(1)) != null:
			return true
	return false


static func fill_x(text, x) -> String:
	var v = Rules.num(x, 1)
	var n := str(maxi(1, int(v) if Rules.truthy(v) else 1))
	return _replace_all(str(text if text != null else ""), "\\[\\[([^\\]]+)\\]\\]", func(m: RegExMatch):
		var sp = _x_spot(m.get_string(1))
		return ("[[" + sp["pre"] + n + sp["post"] + "]]") if sp != null else m.get_string(0))


# ---------------------------------------------------------------- how it prints
const NOUN := {"target enemy": ["target", "enemy"], "target ally": ["target", "ally"],
	"an ally": ["a", "ally"], "an enemy": ["a", "enemy"], "any Unit": ["any", "Unit"],
	"all enemies within": ["all", "enemies"], "all allies within": ["all", "allies"], "all units within": ["all", "units"],
	"all enemies": ["all", "enemies"], "all allies": ["all", "allies"]}


static func article(word: String) -> String:
	return "an" if _test("(?i)^[aeiou]", word) else "a"


static func phrase(p: Dictionary, narrow: Array) -> String:
	var g := {"district": [], "subtype": [], "archetype": [], "distance": []}
	for q in narrow:
		var kind = q["kw"].get("narrow")
		(g[kind] if g.has(kind) else g["archetype"]).append(q)
	var groups := [g["district"].map(func(q): return "District " + (str(q["n"]) if Rules.truthy(q["n"]) else "?")),
		g["subtype"].map(func(q): return q["kw"]["name"]),
		g["archetype"].map(func(q): return q["kw"]["name"])]
	var adj := " ".join(groups.filter(func(a): return not a.is_empty()).map(func(a): return " or ".join(a)))
	var within := (" within " + plural(g["distance"][0]["n"] if Rules.truthy(g["distance"][0]["n"]) else "1", "tile")) if not g["distance"].is_empty() else ""
	var shape = NOUN.get(p["kw"]["name"])
	var n := "" if p["n"] == null else str(p["n"]).strip_edges()
	if shape == null:
		return label(p) + ((" (" + adj + ")") if adj != "" else "") + within
	var lead: String = (article(adj) if adj != "" else "an") if shape[0] == "a" else shape[0]
	var tail := (" within " + plural(n if n != "" else "1", "tile")) if _test("within$", p["kw"]["name"]) else ""
	return lead + ((" " + adj) if adj != "" else "") + " " + shape[1] + tail + within


## The text as runs, keywords marked with their colours: {t, kw, cat, colour, ...}.
static func display_runs(text) -> Array:
	var parts := parse(text)
	var runs := []
	var i := 0
	while i < parts.size():
		var p: Dictionary = parts[i]
		if p["type"] == "text":
			runs.append({"t": p["text"], "kw": false})
			i += 1
			continue
		var cat = category(p["kw"]["cat"]) if p["kw"] != null else null
		var run := {"t": null, "kw": true, "cat": p["kw"]["cat"] if p["kw"] != null else null,
			"colour": cat["colour"] if cat != null else ("#8a8f94" if p["retired"] else null),
			"retired": Rules.truthy(p["retired"]), "unknown": p["kw"] == null and not p["retired"], "part": p}
		if p["kw"] != null and p["kw"]["cat"] == "target" and not Rules.truthy(p["kw"].get("narrow")):
			var narrow := []
			var last := i
			var j := i + 1
			while j < parts.size():
				var q: Dictionary = parts[j]
				if q["type"] == "text":
					var nx = parts[j + 1] if j + 1 < parts.size() else null
					if _test("(?i)^[\\s,]*(?:(?:or|and)\\s*)?$", q["text"]) and nx != null and nx["type"] == "kw" and nx["kw"] != null and Rules.truthy(nx["kw"].get("narrow")):
						j += 1
						continue
					break
				if q["kw"] != null and Rules.truthy(q["kw"].get("narrow")):
					narrow.append(q)
					last = j
					j += 1
					continue
				break
			if not narrow.is_empty():
				run["t"] = phrase(p, narrow)
				runs.append(run)
				i = last + 1
				continue
		var before: String = runs[runs.size() - 1]["t"] if not runs.is_empty() and not runs[runs.size() - 1]["kw"] else ""
		run["t"] = label(p, before)
		runs.append(run)
		i += 1
	var at_start := true
	for r in runs:
		if not r["kw"]:
			if _test("\\S", r["t"]):
				at_start = _test("[.!?]\\s*$", r["t"])
			continue
		if at_start and r["t"] != "":
			r["t"] = r["t"].substr(0, 1).to_upper() + r["t"].substr(1)
		at_start = false
	return runs


## Card text as it reads: no markers, distances in tiles.
static func render(text) -> String:
	return "".join(display_runs(text).map(func(r): return str(r["t"])))
