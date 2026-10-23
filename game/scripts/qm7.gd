## QM-7 (0.15), Vantage Robotics Logistics Unit, Hangar Operations: the dock's
## keeper. It says one line at a time, in its own flat voice, fitting what is
## happening: a tab opened, a team home or lost, something bought or refused.
## About forty lines, so they seldom repeat.
class_name QM7
extends RefCounted

const LINES := {
	"stockpile": [
		"Everything you brought home is here. I have counted it twice.",
		"Shards by the bin. Parts by the crate. Hope is not stocked.",
		"Your stockpile is in order. I would know.",
		"I count the stock at the end of every shift. There are no shifts anymore. I count it anyway.",
	],
	"exchange": [
		"Prices are fixed. The Exchange does not haggle. I was not built to.",
		"Commons, always, in any amount. The rarer stock comes and goes.",
		"Mythic stock shipped directly to the Nexus. None on hand.",
		"Buy what you need. Sell what you don't. I keep the ledger either way.",
		"Please do not stare at the rarer stock. The others dim when it is near.",
	],
	"reclaim": [
		"Three of a kind make one better. It is the only arithmetic down here that improves things.",
		"Reclaiming is not waste. Waste is what the Districts do.",
		"Two of one kind make one of another. Nothing is lost that I have not logged.",
	],
	"bounties": [
		"The board names what the Districts are sending. Bring proof. I do not accept anecdotes.",
		"A claim is void if the claimant is. Get home.",
		"Bounties are paid in Shards. The Hangar accepts no responsibility for personnel.",
	],
	"upgrades": [
		"The Hangar can be improved. Most things here cannot.",
		"Upgrades are paid in shards and parts. Gratitude is not accepted as currency.",
		"I have a list of improvements. It is long. Start anywhere.",
	],
	"deploy": [
		"Sign out a Strike Team. I will hold the door.",
		"Copies are paid for as they leave. Returns are not guaranteed.",
		"Check your packs. The Districts do not restock.",
		"The airlock cycles in ninety seconds. I have timed it eleven thousand times.",
	],
	"out": [
		"A team is out. I am keeping the lights on.",
		"Your team is in the Districts. The ledger stays open until it is home.",
		"Nothing changes here while they are out. I have locked the shelves.",
	],
	"home": [
		"Strike Team returned. Condition on arrival: awake.",
		"Welcome back. Your haul is logged and shelved.",
		"Back again. The odds said otherwise. I have updated the odds.",
	],
	"wipe": [
		"No one came back. I have kept what insurance allowed. The rest is pending.",
		"The team did not return. I have left the door unlocked.",
	],
	"bought": [
		"Logged. It is yours.",
		"Transaction complete. Do not lose it in the Districts.",
		"Sold to you. I have written it down.",
	],
	"sold": [
		"Sold. The Exchange thanks you, in Shards.",
		"Taken back. Half price is still a price.",
	],
	"made": [
		"Done. The stock is better than it was. Briefly.",
		"Reclaimed. I have updated the count.",
	],
	"refused": [
		"That cannot be done. I have checked the ledger.",
		"Insufficient. The Exchange extends no credit.",
	],
	"upgraded": [
		"Installed. The Hangar is slightly less as it was.",
	],
	"restock": [
		"New stock on the shelves. Counted, once.",
	],
	"anytime": [
		"Welcome to KETER. Please declare all Aetherite.",
		"Some of the Security Forces come to the doors after the lights go down. They do not knock. Their suits knock.",
		"My clock says three years since the silence. Yours will disagree. One of us is wrong.",
		"There is one Chip I did not intake. It is still pending.",
		"The Purifier hangs from the crane as a warning. It has not worked as a warning.",
	],
}


## One of QM-7's lines for a moment, the n-th of those that fit (it wraps
## round). A tab's own lines take turns with the ones it says any time.
static func line(moment: String, n: int) -> String:
	var own: Array = LINES.get(moment, [])
	var pool: Array = own.duplicate()
	if moment in ["stockpile", "exchange", "reclaim", "bounties", "upgrades"]:
		pool += LINES["anytime"]
	if pool.is_empty():
		pool = LINES["anytime"]
	return str(pool[posmod(n, pool.size())])


## Every line it has (for the tests).
static func count() -> int:
	var n := 0
	for k in LINES:
		n += LINES[k].size()
	return n
