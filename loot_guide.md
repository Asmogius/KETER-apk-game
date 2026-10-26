# Loot

Loot is the video game's economy. The board game's loot cards are unchanged;
none of this is in the Handbook.

Everything you find is either **Aether shards**, the currency, or
**components**, the parts designs are built from. You bring them home from
deployments on the World Map. The Workshop spends them: parts pay for copies of
designs, and shards research blueprints.

Blueprints and chassis are loot too, but rarer. The **Workshop and Codex
Guide** explains where they drop and how they're kept.

## Components

There are three part types, each in the Handbook's six rarities, which makes
eighteen kinds. They stack: you hold a count of each.

| Rarity | Troop parts | Equipment parts | Aether parts |
| --- | --- | --- | --- |
| Common | Scrap servos | Machined fittings | Inert Aetherite |
| Uncommon | Actuator packs | Alloy plating | Charged filaments |
| Rare | Myomer bundles | Focusing coils | Resonant crystals |
| Epic | Neural harness | Plasma cells | Aetherite prisms |
| Legendary | Synthetic spine | Phase lattice | Void glass |
| Mythic | Aetherborn heart | Singularity core | Rift seed |

These are the starting names. You can rename any of them on the Loot page's
Tables tab.

- **Troop parts** build copies of Troop designs.
- **Equipment parts** build copies of Equipment designs.
- **Aether parts** build copies of Aether card designs.
- **Aether shards** buy blueprints, parts and trades at the dock.

## Skull Level and rarity

A point of interest's **Skull Level** runs from 1 beside the dock to 6 at the
outer border. It sets the rarest component that can drop there. Skull 1 drops
only Commons, and a Mythic needs Skull 6. Within that ceiling, drops are
weighted toward the low end.

| Skull | Common | Uncommon | Rare | Epic | Legendary | Mythic |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 100 | — | — | — | — | — |
| 2 | 60 | 40 | — | — | — | — |
| 3 | 40 | 35 | 25 | — | — | — |
| 4 | 28 | 30 | 26 | 16 | — | — |
| 5 | 20 | 25 | 25 | 19 | 11 | — |
| 6 | 15 | 20 | 23 | 20 | 15 | 7 |

The figures are the percentage of components at each rarity. They're starting
weights, and you can change them on the Tables tab.

A floor's Skull Level is the one set in the Sandbox. If none is set, it's the
highest Skull Level among the floor's Enemy Spawn Tiles.

## What drops

Every drop includes shards. The numbers here are the starting values.

| Source | Shards | Components | Rarity |
| --- | --- | --- | --- |
| Enemy | 4 per Skull Level | 2 | its own Skull Level |
| Elite | 8 per Skull Level | 4 | one Skull Level higher |
| Mini-Boss | 16 per Skull Level | 6 | one Skull Level higher |
| Boss | 32 per Skull Level | 10 | the POI's Skull Level, two always at the rarest it can reach |
| Loot Tile | 6 per Skull Level | 2 to 4 | the POI's Skull Level |
| Locked Chest | 6 per Skull Level | the number on its tile | the POI's Skull Level |

- **Shards** vary by up to half either way, so an Enemy at Skull 3 drops 6 to 18.
- **A blueprint or chassis** can drop too, by a small chance for each source:
  4% from an Enemy, up to 70% from a Boss.
- **Rolling one Skull Level higher** means an Elite at Skull 1 can drop an
  Uncommon, but never a Rare.
- **A Locked Chest** in the Sandbox is a symbol whose text is **LC**, with its
  count after it: **LC3** holds three components. With no number it holds four.

### Salvage

Which part type an Enemy drops comes from its **Salvage** line in the Card
Forge: Troop, Equipment, Aether, or **Mixed** (any of the three, equally
often). An Enemy you haven't set drops Mixed. Elites, Mini-Bosses and Bosses
have it too. Salvage isn't printed on the card. Loot Tiles and chests give any
type.

## A floor's own reward

In the Sandbox's floor settings, **Floor reward** sets what a floor gives when
it's cleared, on top of what its Enemies drop:

- **Shards**: an exact amount.
- **+ Exact components**: a number of one kind, such as 2 Rare Troop parts.
- **+ Rolled components**: a number rolled at the floor's Skull Level, of any
  type or one type, and optionally **rarer by** one or more Skull Levels.

- **+ Blueprint or chassis** (Dev Mode): one item, given by its chance, 0 to
  100%, if the player can use it.

Lines can be mixed freely, and the editor sums them up in words. The Rewards
text box above it is still the board game's.

## In the Battle Simulator

- **Each Enemy** drops its loot as it goes down, and the log says what fell.
- **A friendly Unit** that moves onto a Loot Tile or a Locked Chest takes
  what's there. Each can be taken only once.
- **The haul so far** shows beside the round: shards, and the number of
  parts.
- **On a deployment** (the World Map), a won fight's haul and the floor's
  reward go into the deployment's haul. They reach your **stockpile** only when
  the Strike Team walks home to the dock, and a wipe loses them. The World Map
  Guide has the details.
- **A free fight**, set up in the Battle Simulator itself, is practice: the
  result says what would have dropped, but nothing is kept, except in Dev
  Mode, for testing.
- **Lose** and the fight's haul is gone. Blueprints and chassis found in the
  fight are lost with it.

## The Loot page

**Loot** on Home has four tabs.

- **Stockpile**: your shards and all eighteen counts. **Adjust** lets you
  change any count by hand for testing, and **Reset** empties it. **Also kept
  here** lists the Consumables and Prototypes you own and any pre-built copies
  waiting to go out; they're bought at the dock. **Recent** lists what was
  added and spent and why: hauls, bounties, what you bought, sold and
  reclaimed.
- **Roll**: pick a source, a Skull Level and a Salvage, then **Roll once** to
  see one drop (and add it to the stockpile if you like), or **Roll 1,000** to
  see the spread. The spread shows average shards and their range, components
  per roll, the share at each rarity, and each type's share. **A floor's
  reward** rolls a saved floor's reward.
- **Tables**: every number above. The rarity weights for each Skull Level;
  each source's shards, fewest and most components, **Rarer by**, **At the
  top**, **Blueprint %** (its chance of a blueprint or chassis) and **Card %**
  (v14.9: its chance of a Consumable or a Prototype card of the District, no
  rarer than the Skull Level allows, kept at the dock once home); how much
  shards vary; and the eighteen names. Changes save on this device. **Reset**
  puts the starting values back.
- **Pools** (Dev Mode): each District's pool, the blueprint levels and chassis
  that can drop anywhere in it. Pick a District and toggle each one on or off.
  The pools list every blueprint in the game, so a player sees only a note
  about them.

Shards and components are spent at the dock too: the Exchange sells and buys
parts, and Reclaiming turns parts into other parts. The Dock Guide has the
prices.

The stockpile and your tables are kept on this device.
