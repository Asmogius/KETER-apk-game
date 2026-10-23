## How a design looks. (The Companion's skins.js, the part designs use.)
##
## A skin is a card art and a board token that go together, in one or more
## colour variants. They are drawn in the Companion's Pixel Studio and arrive
## in the export; here you only choose.
##
## A design wears a skin of its chassis's body plan (Bipedal, Quadcopter,
## Quadruped, Hexapod, Octopod). Skins tagged with one of the design's roles
## are offered first; any can be picked. A design with no choice wears the
## first on offer that has been drawn.
##
## Proved to offer and choose what skins.js does (tests/workshop_diff.gd).
class_name Skins
extends RefCounted

var all: Array = []                    # every skin in the export
var chassis := {}                      # id -> chassis (the Progress's)
var has_picture: Callable = Callable() # picture id -> whether the export has it drawn


func _init(skins_content = null, chassis_by_id: Dictionary = {}, drawn: Callable = Callable()) -> void:
	var list = skins_content.get("skins") if skins_content is Dictionary else skins_content
	for k in (Rules.ints(list) if list is Array else []):
		if not (k is Dictionary):
			continue
		if not (k.get("roles") is Array):
			k["roles"] = []
		if not (k.get("variants") is Array) or k["variants"].is_empty():
			k["variants"] = [{"id": "v1", "name": "Standard", "art": null, "token": null}]
		all.append(k)
	chassis = chassis_by_id
	has_picture = drawn


func get_skin(id) -> Variant:
	for k in all:
		if k.get("id") == id:
			return k
	return null


## The skins of one owner (a body plan, a Hero, an Enemy), in their order.
func for_owner(kind: String, key) -> Array:
	var mine := all.filter(func(k): return k.get("owner") is Dictionary and k["owner"].get("kind") == kind and str(k["owner"].get("key")) == str(key))
	return Rules.stable_sort(mine, func(a, b):
		var d := World.number(a.get("order")) - World.number(b.get("order"))
		if d != 0.0:
			return d
		return str(a.get("name", "")).naturalnocasecmp_to(str(b.get("name", ""))))


static func variant_of(k, vid) -> Variant:
	if not (k is Dictionary):
		return null
	for v in k.get("variants", []):
		if v is Dictionary and v.get("id") == vid:
			return v
	return null


func body_plan_of(d) -> String:
	var ch = chassis.get(str(d.get("chassis"))) if d is Dictionary else null
	return str(ch["bodyPlan"]) if ch is Dictionary and Rules.truthy(ch.get("bodyPlan")) else "Bipedal"


## A design's roles: its Actions' roles, or failing those its chassis's subtypes.
func roles_of(d) -> Array:
	var r := []
	for a in (d["abilities"] if d is Dictionary and d.get("abilities") is Array else []):
		if a is Dictionary and a.get("kind") != "passive" and Rules.truthy(a.get("role")) and not r.has(a["role"]):
			r.append(a["role"])
	if r.is_empty():
		var ch = chassis.get(str(d.get("chassis"))) if d is Dictionary else null
		for x in (ch["subtypes"] if ch is Dictionary and ch.get("subtypes") is Array else []):
			if not r.has(x):
				r.append(x)
	return r


static func fits(k: Dictionary, roles: Array) -> bool:
	return (k["roles"] if k.get("roles") is Array else []).any(func(x): return roles.has(x))


## The skins on offer for a design, those that suit its roles first: [{skin, fits}].
func options_for(d) -> Array:
	var roles := roles_of(d)
	var list := for_owner("body", body_plan_of(d))
	var out := []
	for k in list:
		if fits(k, roles):
			out.append({"skin": k, "fits": true})
	for k in list:
		if not fits(k, roles):
			out.append({"skin": k, "fits": false})
	return out


func _drawn(id) -> bool:
	return Rules.truthy(id) and has_picture.is_valid() and has_picture.call(id)


## The look a design wears: {skin, variant, chosen}, or null with none on offer.
func look_of(d) -> Variant:
	var opts := options_for(d)
	var c = d.get("skin") if d is Dictionary else null
	if c is Dictionary:
		for o in opts:
			if o["skin"].get("id") == c.get("skin"):
				var v = variant_of(o["skin"], c.get("variant"))
				if v == null:
					v = o["skin"]["variants"][0]
				return {"skin": o["skin"]["id"], "variant": v.get("id"), "chosen": true}
	# no choice: the first on offer that has been drawn (a skin still blank is never the default)
	for o in opts:
		for v in o["skin"]["variants"]:
			if v is Dictionary and (_drawn(v.get("art")) or _drawn(v.get("token"))):
				return {"skin": o["skin"]["id"], "variant": v.get("id"), "chosen": false}
	if not opts.is_empty():
		return {"skin": opts[0]["skin"]["id"], "variant": opts[0]["skin"]["variants"][0].get("id"), "chosen": false}
	return null


## The pictures of a look: {art, token} (picture ids, either may be null).
func pics_of(look) -> Variant:
	if not (look is Dictionary):
		return null
	var v = variant_of(get_skin(look.get("skin")), look.get("variant"))
	if v == null:
		return null
	return {"art": v["art"] if Rules.truthy(v.get("art")) else null, "token": v["token"] if Rules.truthy(v.get("token")) else null}


func pics_of_design(d) -> Variant:
	return pics_of(look_of(d))


## The look that wears these pictures, if any does: {skin, variant}. (For a
## design copied in from the export, which says only what it wears.)
func look_wearing(art, token) -> Variant:
	for k in all:
		if not (k.get("owner") is Dictionary) or k["owner"].get("kind") != "body":
			continue
		for v in k["variants"]:
			if v is Dictionary and ((Rules.truthy(art) and v.get("art") == art) or (Rules.truthy(token) and v.get("token") == token)):
				return {"skin": k["id"], "variant": v.get("id")}
	return null
