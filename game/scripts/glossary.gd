## (0.36) The campaign's words, each in a line: what the dock's "?" offers
## under Words, for a player who meets them for the first time.
class_name Glossary
extends RefCounted

const WORDS := [
	["Aether", "What cards are paid with in a fight. Heroes generate it, and so do the Chips in the Bank."],
	["Chips", "Aether Chips, in the team's Pouch. Each round some are drawn into the Bank, and make Aether every round after."],
	["Player Level", "How many Chips are drawn each round."],
	["Skull Level", "How dangerous a tile of the World Map is, 1 by the dock to 6 at the edge. Higher: tougher Enemies, better loot."],
	["Shards", "Aether shards: the dock's money."],
	["Parts", "Troop, Equipment and Aether parts, Common to Mythic: what designs, crafting and upgrades are paid in."],
	["Stash", "The Uncommon and rarer cards the run holds. A deployment takes its cards from here, or crafts them as it leaves."],
	["Reach", "The highest Skull Level your teams have reached: it sets the rarest part the Exchange sells."],
	["Haul", "What a team out on a deployment has picked up. It is yours once the team is home; a wipe loses it."],
	["Wipe", "Every Hero in a fight down. The deployment ends, and what it carried is lost."],
	["Design", "A Troop of your own, built in the Workshop on a chassis you have found, with blueprints you own."],
]


static func text() -> String:
	return "\n".join(WORDS.map(func(w): return "%s: %s" % [w[0], w[1]]))
