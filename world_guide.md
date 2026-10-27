# World Map

The World Map is where the video game's loot comes from. You take a Strike
Team out from the dock, walk the colony, fight, and bring the haul home. None
of this is in the Handbook; the board game's world map is its own.

## The map

The colony is a hex map of **18 rings**, about a thousand tiles.

- **The dock** sits at the centre. Every deployment leaves from it and ends
  there.
- **Six Districts** fan out from the dock as wedges, each in its colour.
  Every District has safe ground near the dock and deadly ground at the
  border.
- **Skull Level** rises every three rings: 1 for the first three, up to 6 at
  the border. A light line on the map marks each rise, and tiles darken the
  farther out they are.
- **Collapsed structure** blocks about one tile in seven. Routes bend around
  it, but every open tile can be reached from the dock.

You always see the layout, the Districts and the Skull rings. What a tile
holds shows once your team has stood next to it, and stays known. The dock's
**Long-range scanner** upgrade shows it from further away: 2, 3 or 4 steps.

### Map art

Zoomed in, drawn art takes the place of colours and symbols wherever it
exists:

- **Ground**: each District's own, picked at random for each tile, still
  darkened farther out and edged in the District's colour.
- **Things** (14.2): a few of each District's, one standing on one empty tile
  in five, the same tile every time.
- **Icons**: POIs, Unique POIs, Ambushes, Caches and Events, each on a plate in
  its colour (a POI gold, a Unique POI pale gold, an Ambush red, a Cache green,
  an Event blue). An icon drawn in hex pixels before 14.2 covers its tile.
- **The dock**: the Hangar, standing on its tile.
- **Collapsed tiles**: rubble.
- **Your team**: its first standing Hero's token, in the skin chosen for it.

Map art is drawn on the Pixel Studio's **Assets** tab. Since 14.2 the game's
own is there already, the same pictures game 0.15 draws its World Map with;
take one out of its slot and the map goes back to its colours and symbols
there.

### What tiles hold

| Tile | What happens |
| --- | --- |
| **POI** ◆ | A run of floors fought in order, with a reward at the end |
| **Unique POI** ★ | A POI with a floor list and reward set by hand |
| **Ambush** ! | A fight sprung when you step on it |
| **Cache** ▣ | Loot with no fight |
| **Event** ? | A short situation and a choice, sometimes a d20 check |

A cleared POI, Cache, Event or Ambush comes back, restocked, after **three
more deployments**. Nearby ground can't be farmed every trip.

## Deploying

Tap **Deploy**, then choose a Strike Team from the Deck Builder. The screen
shows its Heroes, the copies of your designs in its Deck, and what they cost.

- **Troops must be designs** from the Workshop. A Troop from the Forge stops
  the deployment, and so does a design that doesn't pass its fit check.
- **Every copy costs Troop parts**: the design's cost, once per copy in the
  Deck.
- **The starter design**, Frame Trooper, comes with **4 free copies** every
  deployment; the dock's **Starter bay** frees the copies of more designs. It's a plain design on
  the General chassis, so you can always go out even with an empty stockpile.
- **Pre-built copies** bought at the dock's Exchange go too, on top of the
  Deck. They're gone when the deployment ends.
- **Every other card** in the Deck comes along free for now: Heroes, Actions,
  Equipment and Aether cards.

### Packing

Consumables and Prototypes are bought at the dock and kept there. **Pack**
lists the ones you own: tap **+** and **−** to choose how many of each to
take.

- **Every packed Prototype** joins each fight. **Each fight's setup** lets you
  choose from the packed Consumables, up to three kinds.
- **A Consumable used is gone.**
- **Coming home** returns every Prototype and anything unused to the dock.
- **A wipe** loses everything packed.

**Pay and deploy** takes the parts from your stockpile and the packed items
from the dock. The copies are spent whatever happens. While the team is out,
its Strike Team is locked in the Deck Builder, its designs are locked in the
Workshop, and the dock is closed, until it comes home.

Only one deployment runs at a time.

## Walking

Tap a tile to see it: its District, Skull Level, what it holds if you know, and
the chance of an ambush on stepping there. Tap one farther off and the panel
says how many steps away it is and the chance of at least one ambush on the
way. **Walk here** walks the team by the shortest open path.

- **Every step** can spring an ambush: **5% per Skull Level**, so 5% beside
  the dock and 30% at the border. A trip to the border and back averages about
  six ambushes.
- **The walk stops** at an ambush, at any tile with something on it, or where
  you told it to go. **Stop** halts it early.

## Fights

Every fight opens in the Battle Simulator:

- **The floor** comes from the POI or ambush.
- **The District and Skull Level** come from the tile.
- **The Strike Team** is as it stands on the deployment.

You choose who enters and who leads, then the Starting Troops. There's no
choosing Enemies:

- **Enemies spawn at the tile's Skull Level.** A spawn tile painted higher
  than the rest of its floor stays that much higher.
- **Enemies come from the tile's District.** When the District has none at
  that level, they come from any District.

You can play a fight by hand or give it to **Auto**. While Auto plays, its
button reads **Take over**, which hands the fight back to you at the start of
the next round.

### Winning and losing

- **Win**, and the fight's loot goes into the **haul**, with the floor's own
  reward. Then it's back to the map, or on to the next floor.
- **A Hero who goes down**, in any fight, sits out the rest of the
  deployment.
- **A Troop copy that goes down** is gone for the rest of the deployment.
- **Lose** a fight with a Hero still standing, and the haul is safe. **Retry
  with reserves** sets the same floor up again with the Heroes left. **Give
  up** is a wipe.
- **Lose with no Hero left**, and it's a **wipe**: the haul is lost, and so is
  everything packed, the copies were spent, and the Heroes recover at the
  dock. The dock's **Salvage insurance** keeps a share of the haul's shards
  and parts.
- **Every Enemy that goes down** in a won fight is noted with the Skull Level
  it fell at, for the dock's Bounty Board.

## POIs

A POI has **1 floor at Skull 1–2, 2 at Skull 3–4 and 3 at Skull 5–6**.

**Where its District has chunks**, each floor is a battlefield grown from them
(the Sandbox Guide's *Battlefield chunks* says how they are drawn): Medium
floors, the last one Large from Skull 4. A POI keeps its layout until it is
cleared; clear it and it grows anew the next time. A POI of two floors or more
ends on a **Boss** floor (a Sandbox floor whose POI Type is Boss) when one fits
its District and is within a Skull Level of it. A Boss floor is never drawn as
an ordinary one.

**Otherwise** the floors are drawn from your saved Sandbox floors:

1. Floors of the tile's District, at the nearest Skull Level.
2. Then floors with no District set.
3. Then any others.

Your own floors come before the test floors, which fill in until you have
enough.

Its type (Lab, Security Armory, Bunker or Overrun Hideout) is a label for now.

Once inside, you fight floor by floor. There's no walking out between floors.
The only way out early is an **Emergency Exit**: a floor with the **EX**
symbol lets a Hero who steps onto it take the whole team out mid-fight, with
the haul and whatever that fight had found. The POI's final reward is given up,
and the POI counts as cleared. Troops still standing come out with you.

Clear the last floor and the POI gives its **final reward**:

- **10 shards per Skull Level.**
- **3 rolled components**, one Skull Level rarer.
- **A 35% chance** of a blueprint or chassis from the District's pool.
- **A 30% chance** of a Consumable or a Prototype card (v14.9) of the
  District, no rarer than the Skull Level allows.

## District Cores (v14.23)

Each District has a **Core** (★): its tile farthest from the dock. It is a
POI of **three floors**, the last a Boss's where one fits, at the tile's Skull
Level. Beat it and the **District is cleared for good**: 5 merits for the
Colony Rank, and the Core never comes back, on this map or another.

Every District cleared brings **Dimensional Instability** to a deployment's
fights: 3% of it each, 15% at most, sending Elites and Mini-Bosses in place of
ordinary Enemies. Clear all six and the colony is safe.

## Ambushes, Caches and Events

- **An Ambush** is one fight on one floor: a Small battlefield grown from
  chunks where its District has them. Otherwise ambushes prefer floors whose
  POI Type is **Ambush**, then Small floors. Beating an Ambush tile clears it.
- **A Cache** gives **3 shards per Skull Level** and **2 rolled components**,
  with a **15% chance** of a blueprint or chassis and a **20% chance** of a
  Consumable or a Prototype card. Tap **Open it**.
- **An Event** shows what the team finds and two or more choices. A choice with
  a check rolls a d20 and needs the number shown or more. Outcomes can add to
  the haul (shards, components, a blueprint chance), cost part of it, or bring
  on a fight. Eight Events come drafted; Dev Mode can rewrite them.

## Coming home

Walk back onto the dock and tap **Come home**. The haul goes into your
stockpile, blueprints and chassis go into the Workshop in order, cards found
(v14.9) are kept at the dock, and the
components you brought back are marked found in the Codex. The deployment ends,
and the locks lift.

The dock then does its part, and the note on the map says what happened:

- **Bounties** the team beat are paid.
- **Your reach** rises if the team went further out than before, so the
  Exchange can carry rarer parts.
- **The Exchange restocks** if the team revealed new ground. A wipe that
  revealed new ground restocks it too.

The Dock Guide has the rest.

A blueprint found on a deployment is **named** as soon as its fight is won, so
you know what you're carrying. It's only yours once you're home.

## Free fights

Fights set up in the Battle Simulator itself are practice. They show what would
have dropped, but keep nothing. Only Dev Mode keeps their loot, for testing.

## Dev Mode

In Dev Mode the World Map shows every tile's contents and adds four sections:

- **The map**:
  - **Generate a new map**, from a seed if you give one. This forgets what has
    been explored and abandons a deployment in progress.
  - **Edit in the Sandbox**, which saves the map as a World Map level named
    "World Map" and opens it there.
  - **Use this map**, which takes any World Map level from the Sandbox. When
    the Sandbox copy has been saved since, **Use the new version** brings the
    edits in without forgetting what has been explored.
  - **Forget what has been explored**, and **Abandon the deployment** (nothing
    banked).
- **Unique POIs**:
  - A name, a type, and floors in the order you list them.
  - A reward (shards, rolled parts, rarer by, blueprint chance) and set drops
    with their own chance.
  - **Place on the map**, then tap a tile.
- **Events**: rewrite, add or delete them. Each choice has a label, a d20 check
  (0 for none), and what happens if it goes well and if the check fails.
  **Back to the eight drafts** resets them.
- **Tables**: the map's size, rings per Skull Level, blocked tiles and content
  amounts (for the next map generated), the ambush chance, how long cleared
  tiles stay cleared, free starter copies (before the Starter bay), floors per
  POI by Skull Level, and the Cache and POI rewards.

### Editing the map in the Sandbox

A World Map level is an ordinary Sandbox level whose POI Type is **World
Map**:

- **Districts are colours**, read by their labels ("District 3 · Vantage
  Robotics"). An uncoloured tile belongs to no District.
- **A blocked tile is an erased one.** Place a tile to open it.
- **Symbols are contents**: **DK** the dock, **PO** a POI, **AM** an Ambush,
  **CA** a Cache, **EV** an Event.
- **The Spawn level tool** sets any tile's Skull Level by hand, overriding its
  ring; a seventh tap clears it.

Skull Level otherwise follows the distance from the dock, wherever you put it.

Your map, what you have explored, the deployment and its history are kept on
this device.
