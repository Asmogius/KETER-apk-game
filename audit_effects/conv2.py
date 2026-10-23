# Round 2 of the effect box audit: the boxes 14.10 left flagged or partly written, rewritten
# with the keywords decided after it (keyword_decisions.md) and, for the one-offs, by rewriting
# the card. Keyed as conv.py is: "card index.entry index" -> (new text, status, note[, fixes])
# status: kw       written with the new keywords, saying what the card said
#         rewrite  the card's idea kept, but what it does changes (decision 11, or a SPOOL card)
#         keep     14.10's text stands as it is (its note still says what was left out)
#         flag     still can't be written: the old text stays
KW, RW, KEEP, X = "kw", "rewrite", "keep", "flag"
CONV2 = {
 # ---- decision 1: Troop and Hero
 "22.2": ("[[Aura 4]]: [[all allies within 4]] [[Troop]] gain [[AC +1]].", KW, "Mechanical Units are your Troops. (In 14.10 I wrote that this Aura had no radius: it has, 4 tiles.)"),
 "38.0": ("[[attached Unit]] gains [[AC +1]]. [[attached Unit]] [[Troop]] gains [[AC +1]].", KW, "+1 AC, and +2 in all on a Troop (a Mechanical Unit)"),
 "40.0": ("[[target ally]] [[Troop]] gains [[NRG +3]] for [[turns 1]].", RW, "Refilling all Energy can't be written; +3 Energy for the turn is about a Troop's full bar"),
 "48.0": ("[[all allies]] [[Troop]] gain [[MS +1]] for [[turns 1]]. [[all allies]] [[Troop]] gain [[NRG +1]] for [[turns 1]].", KW, ""),
 "51.0": ("[[all allies]] [[Ranged]] gain [[Range +2]] for [[turns 1]]. [[all allies]] [[Ranged]] gain [[Rooted]] for [[turns 1]].", KW, "\"Can't move\" is Rooted, on your own Ranged Units"),
 "68.0": ("[[target ally]] [[Troop]] gains [[NRG +2]] for [[turns 1]]. [[target ally]] [[Troop]] gains [[Drained 1]].", KW, ""),
 "72.0": ("[[all allies]] [[Troop]] gain [[MS +2]] for [[turns 1]]. [[all allies]] [[Troop]] gain [[DMG +2]] for [[turns 1]]. [[all allies]] [[Troop]] gain [[Drained 1]].", KW, ""),
 "73.0": ("[[all allies]] [[Troop]] gain [[AC +1]] for [[turns 1]]. [[all allies]] [[Troop]] gain [[INT +1]] for [[turns 1]].", KW, "SEC is INT now"),
 "78.0": ("[[target ally]] [[Troop]] is spent as a [[Sacrifice]]. [[Recover]] a Troop's card from the Discard Pile.", KW, ""),
 "86.0": ("[[while]] [[an ally]] [[Troop]] [[is within 1]], [[this Unit]] gains [[AC +2]].", RW, "A bonus for each adjacent Unit can't be written: it's +2 AC while any Troop stands beside it"),
 "79.0": ("[[Aura 1]]: [[all allies within 1]] [[Hero]] gain [[AC +2]].", KW, "It becomes an Aura of 1 tile", {"kind": "Aura", "auraRadius": "1"}),
 "127.0": ("[[target ally]] [[Troop]] gains [[heal 8]].", KW, ""),
 "140.0": ("[[all allies]] [[Troop]] gain [[HP +2]].", KW, ""),
 "18.0": ("[[target ally]] [[Hero]] gains [[HP +10]] for [[turns 1]].", RW, "\"Can't be reduced below 1 Health\" can't be written: 10 more Health until your next turn is the nearest"),
 # ---- decision 2: SPOOL dropped; one SPOOL stack was +2 DMG and +1 MS, so a stack is written as those
 "74.0": ("[[when]] [[the round begins]], [[this Unit]] gains [[DMG +2]] for [[turns 3]]. [[when]] [[the round begins]], [[this Unit]] gains [[MS +1]] for [[turns 3]].", RW, "Each round adds a dose that lasts 3 rounds, so he builds to +6 DMG and +3 MS by his third turn and holds there: Spin-Up to 3 stacks, without SPOOL"),
 "74.1": ("", RW, "The +2 a stack is now Spin-Up's DMG, which raises Grinder's 8 as it builds"),
 "27.0": ("[[attached Unit]] gains [[DMG +2]]. [[when]] [[the round begins]], [[attached Unit]] gains [[AP +1]] for [[turns 2]].", RW, "+2 AP from its second round on, as SPOOL 2 did"),
 "55.0": ("[[target ally]] gains [[DMG +2]] for [[turns 3]]. [[target ally]] gains [[MS +1]] for [[turns 3]].", RW, "One stack's worth, for 3 turns"),
 "69.0": ("[[all enemies within 1]] of [[target ally]] take [[damage 4]].", RW, "Unchanged from 14.10: the +2 per stack is gone with SPOOL"),
 "71.0": ("[[when]] [[attached Unit]] [[is deployed]], [[attached Unit]] gains [[DMG +2]] for [[turns 3]]. [[when]] [[attached Unit]] [[is deployed]], [[attached Unit]] gains [[MS +1]] for [[turns 3]].", RW, "One stack's worth as the fight starts"),
 "71.1": ("[[this Unit]] gains [[DMG +2]] for [[turns 3]]. [[this Unit]] gains [[MS +1]] for [[turns 3]]. [[this Unit]] gains [[Drained 1]].", RW, "One stack's worth now, Drained after"),
 "113.0": ("[[when]] [[the round begins]], [[attached Unit]] gains [[DMG +1]] for [[turns 3]].", RW, "A new effect (its old one raised SPOOL's limit): a slower spin-up of its own, to +3 DMG"),
 "142.0": ("[[when]] [[the round begins]], [[this Unit]] gains [[DMG +1]] for [[turns 3]].", RW, "A new effect (its old one raised SPOOL's limit): the leading Hero spins up to +3 DMG"),
 # ---- decision 3: gain Aether
 "5.0": ("[[this Unit]] is spent as a [[Sacrifice]]. [[gain Aether 1]].", KW, "The Aether is District 3's (the card's own) rather than Neutral"),
 "115.0": ("[[when]] [[the round begins]], [[gain Aether 1]].", KW, "Of the card's own District, which is the Unit's Affinity on a District 3 card"),
 "136.0": ("[[when]] [[the round begins]], [[gain Aether 1]].", KW, ""),
 "121.0": ("[[gain Aether 1]].", KW, "The extra 1, on top of the 1 every Chip gives"),
 "76.0": ("[[target ally]] [[Troop]] is spent as a [[Sacrifice]]. [[gain Aether 1]].", KW, "Gain Aether 1 in place of drawing a Chip"),
 "77.0": ("[[target ally]] [[Troop]] is spent as a [[Sacrifice]]. [[gain Aether 1]].", KW, "Gain Aether 1 in place of drawing a Chip"),
 "12.0": ("[[target ally]] [[Troop]] is spent as a [[Sacrifice]]. [[gain Aether 2]].", RW, "A set 2 Aether in place of the Troop's own cost", {"kind": "Active"}),
 "125.0": (None, X, "Counting as any District's Aether is a rule of the Aether Pouch, not an effect"),
 # ---- decision 4: all allies
 "116.0": ("[[all allies]] gain [[DMG +2]] for [[turns 1]].", RW, "Against every target, not only marked ones"),
 "138.0": ("[[all allies]] gain [[heal 1]].", KW, "An always-on Passive heals once each round, at Recharge"),
 # ---- decision 5: Aim
 "19.1": ("[[this Unit]] gains [[Aim +2]] for [[turns 2]]. [[this Unit]] gains [[Range +1]] for [[turns 2]].", KW, ""),
 "57.0": ("[[this Unit]] gains [[Aim +2]] for [[turns 2]].", KW, ""),
 "98.1": ("[[Aura 2]]: [[all allies within 2]] gain [[Aim +1]].", KW, ""),
 "139.0": ("[[all allies]] gain [[Aim +1]].", KW, ""),
 "114.0": ("[[attached Unit]] gains [[Aim +1]].", RW, "+1 at every range in place of +2 at range 4 or more"),
 "132.0": ("[[all allies]] gain [[Aim +1]] for [[turns 1]].", RW, "Against every Enemy, not one"),
 # ---- decision 6: Draw
 "31.0": ("[[Draw 2]].", KW, ""),
 "110.0": ("[[Draw 2]].", KW, ""),
 "102.0": ("[[when]] [[this Unit]] [[is deployed]], [[Draw 1]].", KW, ""),
 "141.0": ("[[when]] [[an ally]] [[Troop]] [[is Incapacitated]], [[Draw 1]].", KW, ""),
 "29.1": ("[[Draw 1]].", RW, "Any card, not a chosen Equipment card"),
 "119.0": ("[[Draw 3]].", RW, "Draw 3, without discarding your hand first"),
 # ---- decision 7: Hardened
 "30.0": ("[[target ally]] gains [[Hardened 1]] for [[turns 1]].", KW, "", {"kind": "Active"}),
 "100.0": ("[[this Unit]] gains [[Hardened 1]].", KW, ""),
 "137.0": ("[[all allies]] gain [[Hardened 1]].", RW, "1 less from every hit, in place of 2 less from Aether attacks"),
 # ---- decision 9: Barricade
 "34.0": ("[[Barricade Full]] on [[target tile]].", KW, "On any empty tile in reach, not only one beside a friendly Unit"),
 "35.0": ("[[Barricade Half]] on [[target tile]].", KW, "On any empty tile in reach, not only one beside a friendly Unit"),
 "15.0": ("[[Aura 1]]: [[all allies within 1]] gain [[Evasive 2]].", RW, "A Unit can't be Cover: its neighbours get Evasive 2, as Half Cover's +2 does, from every side", {"kind": "Aura", "auraRadius": "1"}),
 # ---- decision 10: Line and Cone
 "8.0": ("[[target enemy]] takes [[damage 6]] with [[Line 4]].", KW, ""),
 "21.0": ("[[Cone 2]].", KW, ""),
 # ---- decision 8: DMG stands
 "58.0": ("[[attached Unit]] gains [[AC +2]]. [[attached Unit]] gains [[DMG +2]]. [[attached Unit]] gains [[HP +20]].", RW, "DMG stands (decision 8); its +20 SHIELD is written as +20 Health"),
 "93.0": ("[[attached Unit]] gains [[DMG +1]].", KEEP, "DMG stands (decision 8)"),
 # ---- the one-offs (decision 11)
 "14.0": ("[[Suppressive Fire]]. [[target enemy]] gains [[Pinned]] for [[turns 1]].", RW, "It holds fire, as its name says, and the shot Pins: the \"6 more if it attacks one of yours\" becomes the held shot itself"),
 "14.1": ("[[target enemy]] gains [[Sundered 1]] for [[turns 1]].", RW, "Each shot leaves the target easier to get through, and a second dose adds: the weak point builds up"),
 "22.1": ("[[target ally]] gains [[HP +10]] for [[turns 2]].", RW, "\"10 ARMOR\" read as a shield of 10 Health"),
 "29.0": ("[[this Unit]] gains [[HP +10]].", RW, "+10 Health; carrying any number of Equipment cards can't be written"),
 "33.0": ("[[Aura 1]]: [[all allies within 1]] gain [[Range +1]]. [[Aura 1]]: [[all allies within 1]] gain [[DMG +1]].", RW, "Every ally beside it, not only Constructs", {"kind": "Aura", "auraRadius": "1"}),
 "49.1": ("[[this Unit]] gains [[Aim +5]] for [[turns 1]]. [[this Unit]] gains [[AP +3]] for [[turns 1]].", RW, "Close to sure to hit and get through, for the turn"),
 "75.0": ("[[attached Unit]] gains [[Dash 3]].", RW, "3 more tiles every turn in place of a second movement phase"),
 "75.1": ("[[target enemy]] gains [[Bleed]] for [[turns 2]].", RW, "It tears: Bleed in place of +5 against Organic Units"),
 "80.0": ("[[when]] [[this Unit]] [[kills an enemy]], [[gain Aether 1]].", RW, "Aether now in place of loot after the fight"),
 "81.0": ("[[target enemy]] takes [[damage 1]].", RW, "+1 against every Enemy, not only Mechanical ones"),
 "99.0": ("[[when]] [[the round begins]], [[gain Aether 1]].", RW, "1 more Aether each round in place of a Chip arriving early"),
 "101.1": ("[[this Unit]] gains [[Aim +2]].", RW, "+2 Aim always, about what Cover takes away, in place of ignoring Cover from far off"),
 "106.0": ("[[this Unit]] gains [[Evasive 2]].", RW, "Hard to hit, like a cloud of decoys, in place of three tokens"),
 "124.0": ("[[target ally]] gains [[Evasive 4]] for [[turns 1]].", RW, "Very hard to hit with a ranged attack, rather than impossible to target", {"kind": "Active"}),
 "133.0": ("[[target ally]] gains [[remove Poisoned]]. [[target ally]] gains [[remove Bleed]].", RW, "Clears Poisoned and Bleed, in place of any one Status an Enemy gave"),
 "117.0": (None, X, "Recover returns only a Troop's card; returning Equipment would need Recover widened"),
 "120.0": (None, X, "Being immune to Push has no keyword, and no fair rewrite"),
 "143.0": (None, X, "A rule for packing a Strike Team, not an effect in a fight"),
}
