# Workshop and Codex

The Workshop is where the video game's Troops are designed. The Codex is
where you learn what the world holds and where to find it. Neither is part of
the board game, and none of this is in the Handbook.

For now the Workshop designs **Troops only**. Equipment and Aether card
designs will follow.

## How it fits together

A design is a **chassis** plus **abilities**.

- **The chassis** is the frame. It fixes the design's stats, its subtypes,
  what it costs in Aether to deploy, how much power it can carry, how many
  abilities it can have, which keywords it may use, and the best numbers its
  attacks may have.
- **The abilities** are yours. You name each one, pick its Energy cost, set
  an attack's range, to-hit and armour penetration, and write it in keywords.
- **Blueprints** unlock the keywords. Most keywords have to be found as loot
  before a design can use them.
- **Components** pay for copies. Each copy of a design costs Troop parts from
  your stockpile.

Chassis and blueprints are both found as loot, and you have to travel to find
them all. Each District drops its own, and some Enemies carry ones found
nowhere else. The dock's Exchange also sells a few, from the Districts you've
fought in.

## Chassis

A chassis sets:

| | |
| --- | --- |
| **Stats** | HP, AC, MS, NRG, INT, and DMG, the damage every attack it makes deals |
| **Subtypes** | one or two of Melee, Ranged, Support and Cyber; each Action takes one of them as its role |
| **Aether** | what a copy costs to deploy: an amount of any Affinity, plus an amount of its own District's |
| **Power cap** | the most power its abilities may add up to |
| **Ability cap** | how many abilities it can have |
| **Allowed keywords** | the only keywords a design on it may use |
| **Attacks up to** | the highest range and AP an attack may have, and its best (lowest) to-hit |
| **Cost** | Troop parts per copy, before its abilities are added |

Chassis are made on the **Chassis** page, found on Home. The **Attacks up to**
and **Aether** fields there are new in v12.7.

A to-hit is a d20 roll to reach, so a lower one is better. Since v14.0 a
chassis sets its **best to-hit**, and its designs' attacks choose from that up
to 20. A chassis made before kept a highest to-hit instead; it reads as 12
minus that number, so the old order holds: a highest of 8 is a best of 4.

You start with one chassis, **Test Frame · General**, a plain frame for any
District. You find the others the same way you find blueprints.

## Blueprints

Some keywords are yours from the start: the target words (**target enemy**,
**this Unit** and the rest), **damage**, **heal** and **turns**. Every other
keyword is a **blueprint**.

A blueprint with a number has **three levels**. Each level raises the highest
number a design may use:

| Blueprint | Level 1 | Level 2 | Level 3 |
| --- | --- | --- | --- |
| Burst | 2 | 3 | 4 |
| A stat (HP, AC, MS, DMG…) | 2 | 4 | 6 |
| Anything else with a number (Chain, Push, Weakened…) | 1 | 2 | 3 |

A blueprint without a number, such as **when**, **Pierce** or **Flying**, has one level.

- **Level 1** is found as loot, or bought at the dock's Exchange. Until you
  find it, or see it on the Exchange's shelf, the blueprint has no name. You
  won't see it listed anywhere, only hints of where one lies.
- **Levels 2 and 3** are found as loot, bought at the Exchange, or researched
  with shards on the Workshop's **Blueprints** tab: 60 shards for level 2,
  120 for level 3. Research waits while a Strike Team is out.
- **Levels come in order.** A drop only ever gives the next level you're
  missing, so level 2 never drops before level 1.

## Where they're found

Blueprints and chassis drop rarely, from everything that drops components:

| Source | Chance of one |
| --- | --- |
| Enemy | 2% |
| Elite | 6% |
| Mini-Boss | 15% |
| Boss | 35% |
| Loot Tile | 8% |
| Locked Chest | 15% |

These are starting values. You can change them in the **Blueprint %** column
on the Loot page's Tables tab.

What drops comes only from lists set by hand, never from the whole game:

- **Each District has a pool**, the blueprint levels and chassis that can drop
  anywhere in it. District 3, where the test floors are, starts with a test
  pool. The rest start empty.
- **An Enemy card can carry its own.** Under **Can also drop**, it adds items
  to its District's pool whenever it rolls a drop. Under **Set drops**, it
  drops particular items by their own chance, 0 to 100%.
- **A floor's reward** can include a blueprint or chassis, with a chance.
- **The World Map** carries them too: a POI's final reward, a Cache and some
  Events have a chance of one from the District's pool, and a Unique POI can
  set its own, each with a chance.

A drop is only ever something you can use: the next level you're missing, or
a chassis you don't have.

### In a fight

- **An Enemy that drops one** says so in the log. If it's a blueprint you
  haven't found before, the log doesn't name it until the fight is won.
- **On a deployment**, a won fight names it and puts it in the haul. It's yours
  when the Strike Team gets home to the dock; a wipe loses it.
- **Lose the fight**, and it's lost with the rest of that fight's loot.
- **A free fight** in the Battle Simulator is practice and keeps nothing,
  except in Dev Mode.

## Designing a Troop

On the Workshop's **Designs** tab, **New design** asks for a chassis. Only the
chassis you've found are offered, and the page says how many are still out
there.

The editor shows the chassis and its limits, then its abilities:

- **Name** the design and each ability.
- **Action or Passive.** An Action's **role** is one of the chassis's
  subtypes.
- **Energy**, from 0 to the chassis's NRG.
- **Range and AP**, up to the chassis's maximums, and **To-Hit**, from the
  chassis's best up to 20. A Melee attack sets AP. Ranged and Cyber attacks set
  all three. Support Actions and Passives set none.
- **Projectile.** A Ranged or Cyber attack also chooses what the game draws
  as it fires: Bolt, Shell, Beam or Spray. It starts as a Bolt and changes
  nothing in the rules.
- **The text.** Type keywords in `[[double brackets]]`, or tap **Build** to
  pick them. Build offers only the chassis's keywords that you own.

Every attack deals the chassis's DMG.

Below the abilities, the result updates as you work: power against the cap,
the number of abilities against its cap, and the **fit check**. If the design
doesn't fit, the fit check says why:

- It's over the power cap.
- A keyword isn't allowed on this chassis.
- A blueprint hasn't been found, or not at the level used.
- An Action costs more Energy than the chassis's NRG.
- An attack's range or AP is over the chassis's maximum, or its to-hit is
  better than the chassis's best (or over 20, when it could never hit).
- The chassis itself hasn't been found yet.

Designs save as you go. The list shows every design with its power, whether
it fits, and what a copy costs.

### Its look

Below the result, **Look** offers the **skins** of the chassis's body plan:
each one's card art and board token, in each of its colour variants. Tap one
and the design wears it on its card, in the Compendium, the Deck Builder and on
the board. Skins that suit the design's roles are listed first and marked
**suits its roles**, but any can be chosen.

A design with no skin chosen wears the first drawn skin on offer. Every body
plan has at least a stand-in. Skins are drawn in Dev Mode, on the Pixel
Studio's **Skins** tab; the Pixel Studio Guide has the rest.

Art drawn for a design before v13.0 became a skin of its body plan, and the
design goes on wearing it.

### Power

An ability's power is:

1. **The keyword score.** An attack counts 4, and each keyword adds its own.
   A sentence aimed at an area (*all enemies*, *all allies* or *all units
   within* N) counts (1 + 0.5 × N) times what it carries: ×1.5 at 1 tile, ×2
   at 2, ×2.5 at 3. Modifiers multiply.
2. **Plus its range and AP above the baseline**: +0.5 for each point above 4.
   A number below the baseline counts against it.
3. **Times its chance to hit**, for a Ranged or Cyber attack: (21 − to-hit) ÷
   15. That's ×1 at the priced-at to-hit of 6, ×1.33 at 1 (it always hits),
   ×0.67 at 11, and nothing at 21. A surer shot costs more.
4. **Times its Energy.** An Action costing less than 2 Energy counts for more:
   ×1.25 at 1 Energy, ×1.5 at 0.

For example, *[[target enemy]] takes [[damage 2]]* as a Ranged attack at the
baselines is 4 + 2 = 6. At 1 Energy that's 6 × 1.25, which rounds to **8**.

There's no limit on Modifiers. The power cap is the limit.

### What a copy costs

A copy of a design costs:

- **The chassis's cost, plus 0.5 × power**, rounded up, in Common Troop
  parts. The Rifleman above, on Test Frame · General (cost 3), is 3 + 4 =
  **7 Commons**.
- **Plus rarer parts for some keywords**, from a table you fill on the Costs
  tab (Dev Mode). It starts empty.

The editor lists each part of the cost and says how many copies your
stockpile could pay for. Copies are paid when you deploy from the World Map:
each copy of a design in the Strike Team's Deck costs this much. The World Map
Guide has the rest.

### The starter

**Frame Trooper**, a plain design on Test Frame · General, is built in. Every
deployment brings up to **4 copies of it free**, or more with the dock's
**Starter bay**, so you can always go out, even with an empty stockpile.
That's why it can't be changed or deleted. **Copy** it to make your own
version.

### At the dock

Designs can be changed only at the dock. A design that's out on a deployment
opens read-only, marked **Out on a deployment**, until the Strike Team comes
home.

## Designs are cards

Every design is a real Troop card:

- **The Compendium** lists designs under the source **Designs**.
- **The Deck Builder** can put them in a deck.
- **The Battle Simulator** can deploy them, with the chassis's stats and your
  numbers.

A design is deleted in the Workshop, not in the Compendium.

## The Workshop's other tabs

- **Blueprints**: the blueprints you own, each with its level, and **Research**
  for the next level when you have the shards.
- **Costs**: the rate (parts per power), the Energy baseline and the power it
  adds per step below, and each attack number's baseline and power per point.
  To-hit has a baseline only, the to-hit it is priced at: it multiplies.
  In Dev Mode it also has each blueprint's level caps, research prices, and
  the rarer parts a copy needs at each level.

## The Codex

**Codex**, on Home, is a bestiary of **Enemies**, **Blueprints**, **Chassis**
and **Components**. It starts mostly redacted and fills in as you play:

- **An Enemy** fills in once you've met it in a fight. Its stats and roles
  show, and so does what it drops. Enemies not met yet are counted by kind,
  one line per District.
- **A blueprint or chassis** fills in once you've found it. The Codex then
  lists each level you haven't found yet and where to find it.
- **A component** is named once you've looted it.

Everything the Codex lists says where it's found. Places are always named. An
Enemy is named only once you've met it, and until then it's "an Elite in
District 3". Unknown items that share a place show as one line, such as
**"8 blueprints — found in District 3"**. The Codex never lists everything,
so there's always more to find.

## Dev Mode

Dev Mode sees everything, and the editors that would list every blueprint are
kept there:

- **The Codex** shows every entry, named.
- **Loot · Pools**: pick a District, then toggle each blueprint level and
  chassis on or off its pool. **Reset every pool** puts them back.
- **The Forge**: an Enemy card's **Blueprints and chassis** section holds
  **Can also drop** and **Set drops**.
- **The Sandbox**: a floor reward's **+ Blueprint or chassis** line. A player
  sees an existing line but can't change it.
- **The Workshop**: on Blueprints, a testing switch that unlocks every
  blueprint and chassis, and **Reset progress**. On Costs, each blueprint's
  levels, prices and rarer parts.
- **The Workshop's Pre-built tab**: the finished Troops the dock's Exchange
  sells by the copy. A pre-built can use any chassis and any keyword, found or
  not, up to each keyword's top level, and it never appears among your
  designs, in the Compendium or in the Deck Builder. **New pre-built** picks a
  chassis; **↑** moves one earlier in the order the Exchange offers them. The
  Dock Guide has the rest.

Your designs, progress, pools and tables are kept on this device.
