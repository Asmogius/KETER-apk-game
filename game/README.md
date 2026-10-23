# KETER, the game

This is the Godot project for KETER, the video game. **v0.28 adds
the Sandbox's Chassis builder; v0.27 brought pass and play.** You build a Strike Team in the game (its Heroes, its Deck, the
Action cards each Hero carries, its Aether Pouch, its Prototypes and its
Consumables), and send it out from the dock onto the World Map. It walks tile
by tile, fights the ambushes it meets and the POIs it enters, opens Caches,
makes its choices in Events, and comes home with what it found. Each fight is
a Battle: six waves of Enemies, with Aether generated, Chips drawn and cards
drawn into your hand each round, and your cards to play. Its Troops are your
own designs, built in the Workshop from the chassis and blueprints your teams
bring home. What they bring home is spent at the dock, at the Exchange and
on upgrades, and its Bounty Board pays for the Enemies they bring down.

New in 0.28 (Companion 14.15): **the Chassis builder**, the Sandbox's
second tool (its Chassis tab), the Companion's Chassis editor made over for
a thumb:

- **Every chassis**, the export's and your own, grouped by District.
- **Change any of them**: its name, District, body plan, subtypes (one or
  two Combat Roles), power cap, ability cap, Troop parts a copy, stats, the
  most range and AP and the best to-hit its designs' attacks may have, its
  Aether cost to deploy, and the keywords a design on it may use (each, or a
  category at once).
- **Try a design**: abilities checked against the chassis as it stands, built
  with the keyword builder offering only what it allows.
- **Save** keeps it over the export, and the Workshop, the drops and the
  Exchange have it at once; **a chassis you make is yours in the Workshop**
  without being found. Delete, Reset, Copy and New chassis work as in the
  Card Forge.
- **Export** now writes every chassis beside the cards, and the Companion's
  Import (14.15) puts them in its Chassis library.

New in 0.27 (Companion 14.14): **Pass and play**, on Home: a match between
two players and their Strike Teams on one phone.

- **Setting up**: a floor, then Player 1's Strike Team, who enters and leads,
  and its Starting Troops; then Player 2's. Every card is theirs to use:
  nothing is recruited, researched or paid for, and Strike Teams (on a team's
  step) builds or changes a team and comes back.
- **On the floor**: Player 1's team starts on the Player Spawn Tiles, Player
  2's on the Enemy Spawn Tiles (or the tiles furthest away). No Enemy waves.
- **Turns**: Player 1 first. Each player moves, acts and plays cards with
  their whole side, then ends their turn; the screen is covered until the
  other player taps Ready, so nobody sees the other's hand. Each player has
  their own Aether, Chips, Deck, hand, Consumables and Prototypes, and on
  their turn their own Units are the ones in cyan.
- **Statuses** last through the other player's turn, as Handbook 15.9 has
  them; "when the round begins" happens once a round, as Player 1's turn
  begins. Hold fire waits for an Enemy turn, which a match never has, so it
  isn't offered.
- **The winner** is the last side with a Hero standing. Rematch plays the
  same two teams again. A match keeps nothing.

New in 0.26 (Companion 14.14): **the Sandbox**, beside Strike Teams on Home:
the game's own tools for making content, the Companion's made over for a
thumb. Its first is the **Card Forge**:

- **Every card the game plays**, to find by kind, by name, or by what you
  have done to it (Changed, Yours, Deleted).
- **Change any of them**, the export's too: its kind, rarity, District,
  Skull Level, Aether cost, Combat Roles, Origin, Archetypes and every number;
  each ability's tag, role and numbers, and its effects, built with the
  keyword builder or typed; and its lore. The card is drawn as it changes.
- **Save** keeps it, and the whole game (Decks, fights, drops, the dock) has
  it at once. **Delete** takes a card out of the game, **Reset** puts one of
  the export's back as it came, **Copy** makes one of yours from any card,
  and **New card** starts one. Deleted cards can be restored.
- What you make is kept on the phone, over the export (`user://sandbox.json`),
  and **Export** writes every card as a Compendium file
  (`KETER_sandbox_….json`, in Downloads on the phone) for the Companion's Card
  Forge to import.
- The Chassis builder, the POI Sandbox and the Pixel Studio have their tabs,
  and come in the next versions.

New in 0.25 (Companion 14.14): **Recruit, a tab at the dock.** A Strike
Team leaves only with Heroes who are yours:

- **Three free Heroes**, Dock Hand (melee), Hangar Rifleman (ranged) and
  Field Medic (support): plain Heroes of no District, always yours and never
  lost, so a team can always leave. Each has its token.
- **Three on offer**, from the Districts your teams have fought in, priced in
  shards by rarity (40 to 1,200); one more for each level of Exchange stock.
  The roster changes when the Exchange restocks.
- **A recruited Hero is yours until a wipe**: one copy, for any of your
  teams. A wipe loses the recruited Heroes who went out with it.
- **A team with a Hero who isn't yours** is kept, but can't deploy: the
  Strike Teams list says which Hero to recruit, and the team editor marks
  them Not recruited. Practice fights take any Hero.

New in 0.24 (Companion 14.13): **Split Chip, Reforge, Hold Fast and
Quartermaster's Seal are withdrawn**, with their pictures. They were the last
four cards no keyword could write, so every card is now written in keywords.

New in 0.23, Revision 16.3's keywords (Companion 14.10, Companion 14.11 and
Companion 14.12):

- **Eleven keywords.** *Troop* and *Hero* narrow a Target; *all allies* and
  *all enemies* reach a whole side, wherever it stands; *Aim* makes ranged
  attacks easier to land; *Hardened* takes its number off every hit (never
  below 1), a Poisoned or Bleed tick included; *Draw* and *gain Aether* are
  yours to do; *Barricade* puts Half or Full Cover on an empty tile for the
  rest of the fight; *Line* and *Cone* carry an attack's damage to everyone in
  a straight run, or a wedge, toward the target. The keyword builder offers
  them, and each is a Workshop blueprint.
- **Line and Cone show their shape** as you aim: the tiles they run through
  are lit and anyone else caught is ringed, as AoE's area is.
- **Actions aimed at a tile.** A Unit's Action that says *target tile* (Test
  Bulwark's Raise Wall) lights the tiles within its range it can see; tap one
  to see it, again to use it. A Barricade put down stands on the board.
- **Hardened has its icon** (a riveted plate) and its mark on the board.
- **The effect box audit's cards**: 178 boxes written in keywords now, the
  21 Units that had none drafted, SPOOL gone, and the **Hardened Chip
  renamed the Bastion Chip** (still AC +2 for a turn).
- **Three test cards**: Test Bulwark, Test Muster and Test Shockwave.

New in 0.22, content batch 1 (District 3, highly mobile melee; Handbook
Revision 16.2, Companion 14.9):

- **18 new cards.** Skitter-bots to fight: the **Skitterling** (Skull 2), the
  **Skitter Stalker** (an Elite) and the **Brood Matriarch** (a Mini-Boss who
  deploys Skitterlings when she falls below half Health). A Hero, **Ilsa Varn,
  Jump-Frame Pilot**. Two each of Aether, Equipment, Commands, Chips,
  Consumables, Actions and Prototypes, all built on Lunge, Charge, Dash and
  Leap. Each Unit has its token and each card its picture.
- **The Skitter Frame**, a District 3 Hexapod chassis made for fast melee,
  and two pre-built Troops on it at the Exchange: the **Skitter Runner Mk I**
  (Pounce: Lunge 2, Charge 2) and the **Skitter Harrier Mk I** (Rake, then
  Dash 2; Leap 2 always). The Brood Matriarch can drop the frame.
- **Lunge, Charge, Dash and Leap blueprints** join District 3's pool.
- **Cards in the haul.** Elites, Mini-Bosses, Bosses, Caches and a POI's
  reward can drop a Consumable or a Prototype card of the District and the
  Skull Level; it comes home in the haul and is kept at the dock.
- **A Support Action aimed only at this Unit** is used at once, on the Unit
  itself, with no target to pick (Revision 16.2).
- **Four new chunks** for gaps and gantries: Gantry Landing (a Start), Skitter
  Nest and Gantry Crossing (where Enemies wake), and Catwalk Run (a Filler).
  A Unit with Leap goes the short way across.

New in 0.21, the movement keywords (Handbook Revision 16.1, Companion 14.8):

- **Lunge X** (on a Melee Action): the blow reaches a target X tiles
  further off. Used, the Unit first walks up to X tiles to stand beside it,
  free: off a hazard if it can, then the shortest way, then the tile beside
  the most Cover. A Burst
  lunges for its first attack only, and a held shot never does.
- **Charge X** (on a Melee Action): X more damage once the Unit has moved 3
  tiles or more this turn (a Lunge, a Leap and a Dash count; a Push does
  not). The odds over a target show it once it would apply, and the Log adds
  *(Charge +X)* to the hit.
- **Dash X**: X more tiles of Movement this turn. A Unit still moves once a
  round, but a Dash's tiles can be used after that move, or after attacking.
  An Enemy Dashes at once, away from the Unit it struck.
- **Leap X**: jumps up to X tiles over Units, walls, Cover and gaps; the
  jumps are among a Unit's lit tiles, and Enemies and Auto use them too.
- **Two new test cards** carry them: the Test Skirmisher (a Troop) and the
  Test Skitter (a Skull 2 Enemy that leaps, lunges, rakes and skitters off).

New in 0.20, battlefields grown from chunks:

- **A POI's floors are grown.** In a District that has battlefield chunks
  (hexagons of 37 tiles drawn in the Companion's Sandbox, POI Type
  **Chunk**), each floor of a POI is grown from them: a Start chunk with your
  pads, Fillers, Enemy chunks further on, Loot behind them and, on a large
  one, an Exit at the far end. Each chunk may be turned and mirrored; an open
  side joins only an open one, and a wall runs along any other join. Medium
  floors are 5 chunks; the last floor is Large (7) from Skull 4. A POI keeps
  its layout until it is cleared, then grows anew.
- **Ambushes are Small**: 3 chunks.
- **Boss floors.** A POI of two floors or more ends on a Sandbox floor whose
  POI Type is **Boss**, when one fits its District and Skull Level.
- **16 chunks come with it** for District 3 (Vantage Robotics). A District
  with none still draws whole floors, as before.
- The game grows exactly the battlefields Companion 14.7's World Map does,
  from the same chunks and seeds.

New in 0.19, the screens in motion:

- **Transitions.** One screen gives way to the next: between the menus
  (Home, the Strike Teams, a fight's setup, the dock, the Workshop, the map)
  in a **hex wipe**, hexagons sweeping across from the left, each edged in
  cyan as it goes; into a fight and out of one in a **pixel dissolve**, the
  old screen breaking up in blocks. The new screen is there, and answers
  taps, from the start. Faster at Fast; none at Instant.
- **Victory and Defeat.** The board dims and the sign powers on like a
  failing neon tube, stuttering before it holds. Victory comes on whole, in
  gold, your Units still standing lined up under it; Defeat sputters and
  never quite catches, its right half dim and flickering, your fallen
  greyed under it. About two seconds (a tap skips it), then the tally.
- **Cards dealt.** Your hand has the Deck beside it, face down, with how many
  are left; the cards drawn since you last looked are dealt from it one by
  one, sliding to their places and turning face up as they land.
- **The card back** carries the new KETER emblem: an upside-down crown, the
  colony's surface as a slab with its towers lit, and under it spires of
  uneven length going down to points, the underground labs, their windows
  red. Companion 14.6 has it in **Game look**, the game's own in its slot;
  draw over it and the game deals your back.

New in 0.18, the fight's atmosphere: what keeps a still board alive.

- **Glows.** Hazards, spawn pads, Emergency Exits and Healing Stations glow
  softly in their colours (acid green, fire orange, your pads cyan, theirs
  red), strongest in the middle and fading toward the tile's edge, breathing
  slowly brighter and dimmer.
- **The lights flicker** now and then: a stutter, a few times a minute.
- **Motes drift over the board.** In Vantage Robotics (District 3), embers
  rise off the hot metal, ash falls and tumbles, and sparks spit from its
  hazards in bursts; in a fight of any other District, dust drifts. A fight
  opens with the air already full.
- **Atmosphere** in Options: **Off**, **Subtle** (to begin with) or **Full**
  (about three times the motes, brighter glows, a deeper flicker). None of
  it touches the rules, and none of it is ever big enough to hide a Unit or a
  number.
- **Your motes in their place.** Companion 14.5's Effects hold the Ember,
  Spark, Ash and Dust, the game's own already in them; draw over one and the
  game drifts yours. The Look board plays each.

New in 0.17, card art. Every Aether, Equipment, Chip, Action, Command,
Consumable and Prototype card (83 of them) has its own picture, 128 by 90
pixels: the thing itself (a lance-emitter, a gauntlet, a chip, a bandage
roll), modelled and lit as the tokens are, on its District's backdrop:
Vantage Robotics' factory floor for District 3, the colony at night for a
card of any District or none. It fills the card's art window at its own
pixels in the hand, the Team editor and the Dock, and at twice them on a
card's sheet, where until now each showed a picture of its kind. Art you draw
for a card in the Companion (14.4 has the game's own on each card, to draw
over) still takes its place. The Look board shows them all.

New in 0.16, the rest of the drawn look (0.14 drew the fight, 0.15 the World
Map and the menus; this draws what happens in a fight):

- **The fight's effects, drawn frame by frame**, each in its own colours, in
  pixels at the board's scale, taking the place of 0.12's sparks and rings
  (the shots themselves stay as they were, in their side's colour):
  - a **muzzle flash**, white-hot, as a shot leaves the shooter;
  - an **impact**, gold sparks, where damage lands;
  - an **explosion**, orange fire breaking into smoke, on every tile a blast
    catches, rippling out from the middle, and where a shell comes down;
  - a **heal**, green pluses rising from a ring at the feet of whoever is
    mended or helped;
  - a **shield**, a blue hex that flares round a Unit when an attack hits it
    and glances off its armour.
  Shots now fly from the shooter's middle to the target's. The effects play
  faster at Fast, and not at all at Instant. A card that hurts or mends plays
  them too, where it did, and one with an area that hurts explodes on every
  tile it catches.
- **The turn strip.** Under the name of one of your Units, in your turn, the
  side panel shows what it can still do this turn, each with its icon:
  **Move** and how far (**Moved** once it has), **Attack** (lit while any of
  its Actions can be used now) and, for one with Suppressive Fire, **Hold
  fire** (**Holding** once it does). One used, or out of reach now, is
  dimmed.
- **End turn** wears an hourglass beside its words.
- **Your pictures in their place.** Companion 14.3's Pixel Studio draws in
  frames: its **Effects** slots hold the game's five, each with its frames
  and speed, and **Game look** the Move, Attack and End turn icons (Hold
  fire wears the Holding fire eye, redrawn). Draw over one and Export for
  Godot, and the game plays yours. See The game's look.

New in 0.15, the second half of the plan to make the game look its best
(0.14 drew the fight; this draws the World Map and the menus):

- **The World Map, drawn.** Each District has ground of its own, in hex
  pixels: Threshold's lab plating under frost, Halcyon's dim white tiles,
  Vantage's hazard-striped factory decks, Lazarus's server floors, Verdant's
  jungle through the grating, Meridian's plating crumbling to ash. A few of
  its things stand on its empty tiles (stopped clocks, amplifier pylons,
  scrapped bots, server racks, cracked vats, machines coming apart).
  Collapsed tiles are rubble. Thin lines run between the tiles, a light line
  along each District's border, and light dashes at each rise in Skull
  Level. Ground the team hasn't seen yet is dimmed, under faint scanlines.
- **What a tile holds** is an icon on a dark plate in its colour: a POI
  gold, a Unique POI pale gold, an Ambush red, a Cache green, an Event blue.
  The dock is **the Hangar**, lit, standing on its tile.
- **Your team** is its leader standing on a lit base that pulses, and the
  way to the tile you chose is a line of dots. The panel shows the tile's
  District as its emblem by its name.
- **Each District's fights** stand on its own floor (five plates of it, the
  quiet ones most often) among its own Half and Full Cover: consoles and
  pylons, desk barricades, parts bins and assembly frames, cooling units and
  server racks, roots and vats, rubble and machine hulks. Hazards, pads,
  crates, chests, Exits and Healing Stations are the same everywhere, and a
  floor in no District keeps the grey deck.
- **Home** is the colony's sign, KETER in neon over the night, with **Play**
  in gold (**Continue** while a team is out, straight to the map), and
  **Practice** (a Battle or a Quick battle, which it asks) beside **Strike
  Teams**. **Options** is the gear in the corner: the version, which export
  the content came from, and **Look again**.
- **The dock** is the Hangar inside, kept by **QM-7**, a Vantage Robotics
  logistics unit, who says one line at a time about the tab you opened, a
  team just home or lost, or what you bought, sold or couldn't. What a tab is
  for is behind its **?**. The Exchange's goods are tiles: each its picture,
  a gold price tag and its buttons. An empty section is one quiet line, and
  **Deploy** is the gold button.
- **The Workshop** shows the chassis as a banner (its body standing, its
  numbers as icons), each Action's numbers under their icons, what an effect
  does in large type, and the design as its card beside its token on a
  pedestal, always in view. **Strike Teams** and a fight's setup show each
  team's Heroes standing, and each floor its District's emblem.
- **The end of a fight**: **Victory** or **Defeat** in neon, a strip of how
  it went (the round, yours standing, theirs down), and what dropped as
  tiles, coming in one by one.
- **Your pictures in their place.** Companion 14.2's Pixel Studio has a slot
  for every piece of it, the game's own already in each: the map's under
  **World Map**, each District's fights under **District fights**, and the
  menus' under **Game look**. Draw over one and Export for Godot, and the game
  uses yours. See The game's look.

New in 0.14, the first half of the plan to make the game look its best
(the fight first; the map and the menus next):

- **Every Unit stands on its tile**: a token 48 pixels square, drawn for the
  game, its feet at the tile's middle, with a shadow under them, a ring round
  them in its side's colour (cyan yours, red the Enemies'), its Health as a
  row of pips under the ring (amber when it runs low), and a small mark by its
  head for each Status it has (faded, for one it is guarded against). Every
  master Unit has a token of its own; a design wears its skin's, and a Unit
  with no token stands in as a dark shape of its kind: a fighter, a shooter,
  a drone or a beast.
- **The board as things.** Each tile is a plate of the deck, five kinds of it
  scattered. Cover stands at the front of its tile (sandbags, barriers,
  stacked containers), so a Unit on it is seen behind it; a Loot Tile holds a
  crate, dimmed once it has been searched; Locked Chests, the Emergency Exit
  (a hatch in the floor) and Healing Stations are themselves; a hazard is the
  acid, sparks, razor wire, sludge or fire it is, with its Status's mark;
  spawn pads glow in their side's colour; walls stand on the tiles' edges.
  Units, cover and walls stand in one layer, the nearer in front.
- **Whole pixels.** At the usual zoom the board's art is drawn at twice its
  pixels, and the zoom rests at whole steps (each of its pixels 1, 2, 3 or 4
  of the screen's): the mouse wheel steps between them, and a pinch settles on
  the nearest. A fight opens at the usual zoom on your Units; **Fit** shows
  the whole floor.
- **The whole card, everywhere.** A card is printed as the Card Forge prints
  it, its District's colour round the edge, its name and its cost as gems,
  what kind of card it is, its art, its rules with each keyword in its
  colour, and its numbers along the bottom: on a tile, in your hand, and large
  on its sheet. A card with no art yet shows a picture of its kind.
- **Your hand as a fan** of those cards along the bottom, overlapping when
  there are many. The one you tap stands up out of the fan.
- **The top bar**: where you are and the round, your **Aether as gems** (one
  for each point, in its District's colour; white for Aether of any kind),
  and its buttons as icons: **Undo** (an arrow turning back), **Auto** (a loop
  round an A, lit while it is on), **Options** (the speed's arrows), **Log** (a
  page of lines), **Fit** (four corners) and **Leave** (a door with an arrow
  out). **End turn** is the one gold button.
- **A second typeface.** What you read in a fight and on a card is set in
  **VT323**, a pixel typeface made for reading; titles and numbers stay in
  Jersey 10. Each is used only at sizes where its pixels land whole.
- **The bottom line** is one line. When it's longer, it ends in "…", and a
  **?** at its end opens the whole of it.
- **The round's banner** names the phase once, as its title.
- **The side panel** shows the Unit's token large, each Action with its
  role's icon, and each Status with its own icon.
- **Look board**, under Options: every piece of the look on one screen (the
  type, the buttons, the frames, the icons, the marks and gems, a card at its
  two sizes, tokens and the board's pieces), to check it on your phone.
- **Your pictures in their place.** Companion 14.1's Pixel Studio has a slot
  for every piece of it (under **Game look** and **The fight**), the game's
  own picture already in each, and a token on every master Unit. Draw over
  one and Export for Godot, and the game uses yours. See The game's look.

New in 0.13, from a playtest of the action creator (Handbook 16.0, as in
Companion 14.0):

- **Locks: Stunned, Rooted, Pinned and Marked** last 2 turns at most, and a
  second dose does nothing while the first lasts. When one ends, the Unit is
  **guarded**: it can't be given the same lock again until the same point of
  the next round. A guarded Unit wears a hollow ring in the lock's colour
  beside its Status dots, and the side panel says **Guarded: Stunned** (and so
  on). An always-on Passive can't give a lock, and the keyword builder only
  offers 1 or 2 turns for one.
- **What an attack carries needs it to Penetrate.** The Statuses, Pushes and
  extra damage on a Melee, Ranged or Cyber attack land only when it gets
  through Armor Class (Integrity, for Cyber). Support Actions always land.
- **Execute**, a new Effect: an Enemy below half its Health is removed
  outright; an Elite, a Mini-Boss or a Boss never is. The builder offers it
  for Enemy Targets, as "target enemy faces an Execute".
- **Sacrifice** removes only your own Units, keeps the rest of its sentence,
  and no longer makes an ability cheaper.
- **Fairer prices.** An area effect costs ×1.5, ×2 or ×2.5 for a reach of 1,
  2 or 3 tiles. To-hit multiplies an attack's power by its chance to hit, so a
  surer shot costs more. Stunned is worth 2.
- **A chassis's best to-hit.** A design's To-Hit steps from its chassis's best
  (lowest) up to 20. A chassis from an older export keeps its order: a highest
  to-hit of 8 reads as a best of 4.
- **Overclock** is out of the builder: it has no rules in a fight yet.
- **The master Enemies aim at 8 to 10** (they were 14 to 18), in a
  Companion 14.0 export.

New in 0.12:

- **Attacks you can see.** A Melee attacker lunges at its target and steps
  back. A Ranged Action fires what its card says (the Companion's new
  **Projectile** choice): a **Bolt**, a short glowing slug; a **Shell**,
  arcing over the board and bursting where it lands; a **Beam**, drawn at
  once and flickering out; or a **Spray** of pellets. A miss flies past. Each
  shot of a Burst is fired in turn, and an area bursts over every tile it
  catches.
- **Hits you can feel.** The target flashes white and shakes, sparks fly,
  and the damage pops up big. A Unit brought down crumbles into pieces and is
  gone; a heavy blow, or a Unit brought down, shakes the screen a little.
- **Units hop** from tile to tile as they walk, rather than sliding.
- **Cards fly** from the Hand (or the Consumables or Chips) to whoever or
  wherever they go, and land with a flash.
- **Screens fade in, and boxes pop** open and shut.
- **Sound.** Retro blips the game makes for itself: a shot of each kind,
  hits, misses, downs, steps, cards and buttons. Yours can replace any of them
  (see Sounds, below).
- **Options**, from Home or from the speed button on a fight's bar: **Speed**
  (Normal, Fast or Instant, where nothing moves and the pauses are short),
  **Screen shake** and **Sound**. They are kept between sessions. None of it
  changes the rules: a fight is decided the moment you tap, and this only
  shows it.
- Your designs' Ranged and Cyber Actions choose their Projectile in the
  Workshop too (**Fires**, beside Range, To-Hit and AP).

New in 0.11:

- **A look of its own, in pixels.** Every word is in **Jersey 10**, a
  typeface drawn on a pixel grid, and text comes in a few whole sizes.
  Panels, buttons and boxes are pixel frames with cut corners: a button is a
  raised plate that lights in cyan when it is pressed or chosen. Every
  colour on the screens is one of the Pixel Studio's.
- **Backdrops.** Home opens on the colony at sunset; the dock looks out
  through its hangar window; the Strike Teams, the Workshop and a fight's
  setup stand on the colony at night. The game draws each in pixels, 256 by
  144, and it fills the screen at five times that.
- **Icons and big numbers.** Aether shards, Troop, Equipment and Aether
  parts, HP, AC, MS, NRG, Aether and Skull Level each have an icon, 16 by 16,
  shown at twice that. A fight's result adds up what it brings in as a row
  of them; the stockpile's and Reclaim's rows wear theirs; on the World Map
  the bar shows who is standing and the haul that way, and a tile's Skull
  Level is the skull and its number; the side panel's HP, AC, MS and NRG
  wear theirs.
- **A pixel board.** A fight's floor is a deck plate in pixels, and each
  tile has a pixel edge, lit along its top and shaded below. Where you have
  drawn ground for the floor's District (the Pixel Studio's Map ground
  slots), the tiles stand on it.
- **The bottom line** of a fight sits on a dark bar as tall as what it says.
- **Your own pictures in their place.** Companion 13.8's Pixel Studio has a
  **Game look** group in its Assets list: Title, Dock backdrop and Menu
  backdrop (256 by 144), Fight floor (64 by 64, repeated) and the ten icons
  (16 by 16). Draw in one and Export for Godot, and the game uses yours
  instead of its own. See The game's look, below.

New in 0.10:

- **The dock, in full**, as the Companion has it, on five tabs: the
  Stockpile, the Exchange, Reclaim, Bounties and Upgrades.
- **The Exchange.** Components (Commons always; a few lots of rarer ones,
  never rarer than your **reach**, the highest Skull Level a team has come
  home from), blueprints and chassis from the pools of the Districts you
  have fought in, Consumables and Prototypes, and pre-built Troops, all paid
  in Aether shards. It buys back at half price, and restocks after a
  deployment that sees new ground.
- **Consumables and Prototypes are bought, and packed.** What you buy is
  kept at the dock. As a team leaves, the **Pack** says which of them go
  with it: every one packed comes to each fight, one used is gone, the rest
  come home, and a wipe loses them all.
- **Pre-built Troops**: finished designs from your export, bought by the
  copy. The copies join the next deployment on top of its Deck, and are gone
  when it ends.
- **Reclaim**: three parts of a rarity into one of the next, or two of one
  part type into one of another.
- **The Bounty Board** names Enemies you have met. Beat one on a deployment
  and it pays when the team is home. Out there it wears a gold diamond, and
  its panel says **Bounty**.
- **Upgrades**: more Exchange stock, more free Frame Troopers, salvage
  insurance that keeps a share of a wiped haul, and a scanner that shows the
  team what lies further off.
- **Testing**, at the foot of the Stockpile, as in the Companion's Dev Mode:
  Restock now, Reach +1 and Reset the dock. Each asks first.

New in 0.9:

- **The Workshop**, on the dock. Design Troops on the chassis you have
  found: each ability's effects are built a sentence at a time with the
  keyword builder, by taps alone, from the keywords your blueprints unlock,
  and its numbers stop at what your blueprint's level allows. On the right,
  its power against the chassis's cap, whether it fits, and what a copy
  costs. Choose its look from your export's skins. A design is a Troop card:
  it goes into a Strike Team's Deck like any other.
- **Research.** Levels 2 and 3 of a blueprint you own can be bought with
  Aether shards, at the dock.
- **Leaving costs.** On a deployment a team's Troops must be your designs,
  and each copy is paid for in Troop parts as it leaves. The built-in
  **Frame Trooper**'s first 4 copies are free. A team made before 0.9 gets a
  **Field copy** button at the dock: a copy without its other Troops.
- **A testing switch** in the Workshop unlocks every chassis and blueprint
  while it is on (and nothing new drops).
- **The Companion's designs** in your export can be copied in and made
  yours.

New in 0.8:

- **The World Map.** The colony from your export: the dock in the middle,
  six Districts round it, Skull Level rising with distance. What a tile
  holds shows once your team has stood next to it.
- **A deployment.** One Strike Team goes out, as you built it.
  A Hero who goes down sits out the rest of it. A Troop that falls, and a
  Consumable that is used, are gone until the team is home.
- **Loot is kept.** It rides in the haul and goes into your stockpile when
  the team walks back onto the dock. A wipe loses it.
- **Blueprints and chassis** drop, as the Companion rolls them. They are
  named once the fight is won and yours once home.
- **Saved as you go**: after every step, Cache, Event and finished fight. A
  fight closed half-way starts again from its setup.
- **When a Status ticks** (Handbook 15.9): at the end of the turn after the
  one it arrived in. See Statuses, under What cards say.

**Battle** and **Quick battle** are under **Practice** on the home screen:
any team and any card, nothing paid, what drops is shown, and nothing is
kept.

It reads exports from **Companion 13.5** or later. An export from 13.1 to
13.4 has the map and will work. Export again from 13.5 all the same: its
Handbook is 15.9. Your own pictures for the game's
look come in exports from **Companion 13.8**; with an earlier one the game
uses its own. What a Ranged Action fires comes from **Companion 13.9**; with
an earlier export every shot is a Bolt. The game's rules are Handbook 16.0's,
as **Companion 14.0**'s are; export again from it for the master Enemies' new
to-hits and the chassis's best to-hits (an older export still works). The
pictures a fight is drawn with are the game's own; your drawings over them
come in exports from **Companion 14.1**, over the World Map's, each
District's fights' and the menus' from **Companion 14.2**, and over the
fight's effects (drawn in frames) and the turn strip's icons from **Companion
14.3**, over each card's picture from **Companion 14.4**, and over the
atmosphere's motes from **Companion 14.5**, and over the card back from
**Companion 14.6**.

Made for **Godot 4.7** (the editor's version must be 4.7 or later), held
sideways.

## Opening it on your phone

1. **Install Godot Engine 4** (the editor) from the Play Store, and let it
   access your files when it asks.
2. **Unzip `v0-28_KETER_game.zip`.** In the Files app, tap the zip and choose
   Extract. Inside is one folder, `KETER`; keep it somewhere easy to find, such
   as `Documents`. That folder is "the game's folder" below.
3. In Godot's **Project Manager**, tap **Import**, find that folder, choose
   `project.godot`, then **Import & Edit**. The first time, Godot spends a
   moment importing.
4. **Press Play** (▶, top right) to run the game on your phone. A keyboard's
   **F5** does the same; **F8** stops it.

## Or as an app, without Godot (0.21)

`v0-28_KETER.apk` is the game as an Android app: it installs and plays like
any other, with no Godot.

1. **Copy the APK to your phone** (or download it there) and tap it in the
   Files app. Android asks to allow installing apps from Files (or your
   browser): allow it, then **Install**. (Play Protect may warn that it
   doesn't know the app: tap **Install anyway**.)
2. **Open KETER.** It asks for **All files access**: allow it, so it can read
   the Companion's exports from your **Downloads**. Then go back to the game.
3. **Your content:** in the Companion, **Export for Godot**; the zip lands in
   Downloads. In the game, tap **Look again** (on Home, or in Options).

Until it may read Downloads, or with no export there, it plays the export
built into it (the Companion's test floors, master cards and World Map).
A newer APK installs over the old one and keeps your saves. The app is built
by `make_game.py android` (see `tools/android/README.md`).

## Adding your content

1. In the Companion, open the **Pixel Studio**, go to the **Assets** tab, and
   tap **Export for Godot**. It downloads `KETER_export_<date>.zip`.
2. **Move that zip into the game's folder**, next to `project.godot`. Don't
   unzip it: the game reads it as it is.
3. Run the game, or tap **Look again** in Options (the gear on Home).

The game uses the newest export it finds (by the date in its name), in the
game's folder or in a folder named `exports` inside it. Options, from Home,
says which one it is using. With no export yet, Home says so, and Look again
is on Home itself.

## The home screen

Home is the colony's sign, KETER in neon on a steel frame over the night
(one letter dark), with the colony's towers beneath it.

- **Play**, in gold: the dock, and from it a deployment. With a Strike Team
  already out it reads **Continue**, and goes straight back to the map where
  the team stands.
- **Practice** opens its two fights to pick from:
  - **Battle**: one of your Strike Teams on a floor you choose: six waves,
    Aether, and a hand of cards. Nothing is kept.
  - **Quick battle**: any Heroes and Troops from the export against one
    wave. No Strike Team, no Deck, no Aether. Good for trying a card or a
    floor.
- **Strike Teams**: build your teams and keep them.
- **Options**, the gear in the top right corner: Speed, Screen shake and
  Sound; the game's version and which export the content came from; **Look
  again**; and the Look board.

Under Play is where things stand: how many deployments so far, and whether
one is out.

## Options and sounds

**Options** is on Home, and behind the speed button on a fight's bar (it wears
one arrow at Normal, two at Fast, two and a bar at Instant):

- **Speed**: Normal; Fast, under half the time; or Instant, where nothing
  moves and the pauses between the Enemies' moves are short.
- **Screen shake**: on or off.
- **Sound**: on or off.

**To use your own sounds**, make a folder named `sounds` in the game's folder
and put a `.wav` in it named for the sound it replaces. The rest stay the
game's.

| File | Plays when |
| --- | --- |
| `bolt.wav` | a Bolt is fired |
| `shell.wav` | a Shell is fired |
| `beam.wav` | a Beam is fired |
| `spray.wav` | a Spray is fired |
| `blast.wav` | a Shell or an area lands (0.16: as it explodes) |
| `melee.wav` | a Unit lunges at another |
| `hit.wav` | an attack hurts |
| `miss.wav` | an attack misses, or glances off (0.16: as its shield flares) |
| `heal.wav` | a Unit is healed |
| `down.wav` | a Unit goes down |
| `step.wav` | a Unit steps onto a tile |
| `card.wav` | a card is played |
| `tap.wav` | a button is pressed |

They are read as the game starts.

## The game's look

The game draws its own pictures, in pixels and on the Pixel Studio's palette:

| Picture | Size | Where |
| --- | --- | --- |
| Title | 256 × 144 | Home: the colony's sign over the night (0.15), not dimmed |
| Dock backdrop | 256 × 144 | The Hangar inside (0.15), behind the dock's tabs, dimmed |
| Menu backdrop | 256 × 144 | The colony at night, behind the Strike Teams, the Workshop and a fight's setup, dimmed |
| Fight floor | 64 × 64 | Repeated under a fight's board, darkened |
| Icons | 16 × 16 each | Aether shards, Troop parts, Equipment parts, Aether parts, HP, AC, MS, NRG, Aether, Skull Level |

A backdrop fills the screen at five times its size, every pixel square;
the icons are shown at twice theirs.

**To use your own**, in the Companion (13.8 or later) open the Pixel
Studio's **Assets** tab: the **Game look** group has a slot for each, ready
sized (since 14.2, the game's own picture already in each but the fight
floor and the HP, AC, MS, NRG and Aether icons, which the game still draws as
it goes). Draw in one, tap **Export for Godot**, and put the export in the
game's folder as usual. Each slot you have drawn in is used in place of the
game's picture; the others stay the game's. Home's picture carries the
game's name, the sign: the game writes nothing over it, yours or its own. An
icon wants its edge left clear, as the game's are, so it doesn't run into
its neighbours.

### A fight's pictures (0.14)

A fight is drawn with pictures of the game's own, in square pixels on the
Pixel Studio's palette, each drawn at twice its size on the board:

| Picture | Size | Where |
| --- | --- | --- |
| A Unit's token | 48 × 48 | Every master Unit has one; the five body plans have one for a design's stand-in skin |
| Stand-ins | 48 × 48 | A Unit with no token: melee, ranged, drone or beast |
| Deck plates | 42 × 48 | One tile of the floor, five kinds |
| Spawn pads | 42 × 48 | Yours and the Enemies' |
| Hazards | 42 × 48 | Acid (Poisons), sparks (Stuns, Drains), razor wire (Bleeds, Sunders), sludge (Slows, Roots, Pins), fire (any other) |
| Cover | 48 × 48 | Two of Half Cover and two of Full Cover, at the front of their tile |
| Crate, Locked Chest | 32 × 32 | On a Loot Tile, and a Locked Chest's tile |
| Emergency Exit, Healing Station | 48 × 48 | On their tiles |
| Status icons | 16 × 16 | Beside a Status in the side panel |
| Status marks, Aether gems | 8 × 8 | By a Unit's head on the board; on the Aether button and in a card's cost |
| Bar and role icons | 16 × 16 | Undo, Auto, Log, Fit and Leave; before each Action, by its role |
| Card pictures | 64 × 45 | In the art window of a card with no art of its own, one for each kind |

**To use your own**, open Companion 14.1's Pixel Studio, **Assets** tab: the
**Game look** and **The fight** groups have a slot for each, with the game's
own picture already in it, and every master Unit's card has its token. Open
one, draw over it, and Export for Godot: the game uses yours. The export
carries only the ones you have drawn on, so the rest stay the game's (and a
newer game's, when it redraws them).

### The World Map's and the menus' pictures (0.15)

| Picture | Size | Where |
| --- | --- | --- |
| Ground | a hexagon of hex pixels, 9 to a side | Four for each District and four for ground in no District, one picked for each tile; darker the farther out |
| Rubble | the same | Three, for collapsed tiles |
| A District's things | 32 × 32 | Three for each District, one standing on one empty tile in five, at twice its size |
| Map icons | 16 × 16 | POI, Unique POI, Ambush, Cache and Event, each on a plate in its colour, at twice its size |
| The Hangar | 64 × 64 | Standing on the dock's tile, at twice its size |
| A District's floor plates | 42 × 48 | Five for each District, every tile of its fights wearing one |
| A District's cover | 48 × 48 | Its own Half Cover and Full Cover, at the front of their tile |
| QM-7, and blinking | 64 × 64 | The dock's keeper, over its tabs, at twice its size |
| Victory, Defeat | 139 × 32, 129 × 32 | Over a fight's result, at twice their size |
| The gear | 16 × 16 | Options, on Home |
| District emblems | 16 × 16 | By a tile's name on the map, and by a floor in a fight's setup |

The ground is drawn at three screen pixels to a hex pixel's corner at the
map's usual zoom, and clipped to the tile's hexagon. **To use your own**,
open Companion 14.2's Pixel Studio, **Assets** tab: **World Map** holds the
ground, rubble, things, icons and the Hangar; **District fights** each
District's plates and cover; **Game look** the menus' pictures. The game's own
is already in each. In a slot of several (ground, rubble, a District's
things), once one is yours the export carries the whole slot, and the game
uses that slot's pictures together. A map icon drawn in hex pixels before
0.15 still works: the game lays it over its tile, as it did.

### The fight's effects and the turn strip's icons (0.16)

| Picture | Size | Frames, a second | Where |
| --- | --- | --- | --- |
| Muzzle flash | 24 × 24 | 4, at 20 | At the shooter as a shot leaves, its middle over the muzzle |
| Impact | 32 × 32 | 5, at 16 | Where damage lands, its middle over the Unit's |
| Explosion | 48 × 48 | 8, at 14 | On every tile a blast catches and where a shell comes down, a little low, the fire rising |
| Heal | 32 × 48 | 6, at 12 | Rising from whoever is mended or helped, its foot at the Unit's feet |
| Shield | 48 × 48 | 6, at 14 | Round a Unit when an attack glances off its armour |
| Move, Attack | 16 × 16 | | The side panel's turn strip, at twice their size |
| End turn | 16 × 16 | | On End turn, beside its words |

Each effect is drawn on the board at twice its size, frame after frame at its
speed (faster at Fast), and is gone when its last frame has played. Hold
fire, in the strip, wears the Holding fire icon (an eye since 0.16), so the
panel shows one picture for it. **To use your own**, open Companion 14.3's
Pixel Studio, **Assets** tab: **Effects** has a slot for each, the game's own
in it with its frames and speed; open one and the strip under the canvas
shows its frames, to draw over, add to, copy, move, delete and play. The
export carries a picture's frames side by side, with how many and how fast,
and the game plays yours: as many frames as you drew, at your speed, sat as
the game's sits for its size. One of a single frame stays up as long as the
game's would play. **Game look** has the Move, Attack and End turn icons.

### The card back (0.19)

| Picture | Size | Where |
| --- | --- | --- |
| Card back | 75 × 105 | The Deck beside your hand, and every card as it is dealt, at twice its pixels |

### The fight's atmosphere (0.18)

| Picture | Size | Frames, a second | Where |
| --- | --- | --- | --- |
| Ember | 8 × 8 | 4, at 8 (looping) | Rising over a District 3 fight |
| Spark | 12 × 12 | 3, played once over its short life | Spat from a District 3 hazard, falling; its head at the bottom right, flipped when it flies left |
| Ash | 8 × 8 | 3, at 4 (looping) | Falling and tumbling over a District 3 fight |
| Dust | 6 × 6 | 2, at 3 (looping) | Drifting over a fight of any other District |

Each is drawn at twice its pixels, as the board is, fading in as it comes and
out as it goes. **To use your own**, open Companion 14.5's Pixel Studio,
**Assets** tab, **Effects**: each has a slot, the game's own in it.

### Card art (0.17)

| Picture | Size | Where |
| --- | --- | --- |
| A card's own picture | 128 × 90 | Its art window: at its pixels on a card in the hand, the Team editor and the Dock; at twice them on its sheet |

One for each of the 83 cards that are not Units (none for a test card or a
design of yours), found by the card's id, else by its name, and never for a
card of another kind that shares the name (the Aether Battery Unit keeps its
token; the Aether battery card has its picture). **To use your own**, open
Companion 14.4: each of those cards already wears the game's picture as its
art; open it in the Pixel Studio and draw over it, and Export for Godot
carries yours (art drawn for a card was always used in its place).

They are drawn by scripts in `tools/art` (see its README): every Unit is
modelled from simple shapes, lit from the top left and drawn in pixels with a
dark outline. Godot leaves that folder alone.

**Look board**, under Options, shows every piece of the look on one screen.

The typefaces are Jersey 10, by The Soft Type Project, for titles and
numbers, and VT323, by Peter Hull, for what you read in a fight and on a
card; both in `fonts/` with their licences (the SIL Open Font License).

## The dock

Deployments start and end at the dock, the Hangar. It has five tabs along
the top; with a Strike Team out you can look at all of them, but nothing is
bought, sold, reclaimed or upgraded until it is home.

**QM-7**, Hangar Operations, keeps it: its portrait over the tabs, now and
then blinking, says one line at a time, about the tab you opened, a team
just home or lost, or what you have bought, sold or made, or couldn't. What
the tab is for, at length, is behind its **?**. A section with nothing in it
is a single quiet line.

**Stockpile.**

- **Stockpile**: the Aether shards and components your teams have brought
  home, each kind of component with its rarity. Troop parts pay for the
  copies your teams take out; shards pay at the Exchange and for research.
- **Also kept here**: the Consumables and Prototypes you own, and the
  pre-built copies waiting for the next deployment.
- **Blueprints and chassis**: the ones you own.
- **Deployments**: each one so far, newest first, with how it ended and what
  it brought back or lost.
- **Testing**: Restock now, Reach +1 and Reset the dock, as the Companion's
  Dev Mode has them. Each asks first. Reset the dock forgets your reach, the
  upgrades, the Exchange's stock, the Bounty Board and what is kept here;
  the stockpile stays.

**Exchange.** Everything is paid in Aether shards; behind the **?** it says
how many you hold and your reach. What it sells are tiles: each its picture,
its price on a gold tag, and its buttons.

- **Components**: Commons of every part type, always, in any amount (**Buy**,
  **Buy 5**), and **Sell** for each rarity you hold, at half price.
- **Lots of rarer components**: a few at a time, never rarer than your
  reach. Skull Level 2 reaches Uncommon, 3 Rare, and so on. A lot sells out.
- **Blueprints and chassis**: from the pools of the Districts you have fought
  in, and only what you could use next (the next level of a blueprint you
  own part of, or a chassis you don't have). Bought, it is yours at once,
  in the Workshop.
- **Consumables and Prototypes**: a few at a time, taking turns as it
  restocks. Your export's list (ticked in the Companion's Dev Mode, with its
  prices) is the one used. An export that ticks none carries every
  Consumable and Prototype in it, at 20 shards each, and says so.
- **Pre-built Troops**: the Companion's pre-built designs in your export. A
  copy costs half again what its parts would cost at the Exchange. Bought
  copies wait at the dock and join the next deployment.
- **Sell**: the Consumables and Prototypes you own, at half price.

**It restocks** after a deployment that comes home or is wiped out having
seen new ground, and the Bounty Board changes with it.

**Reclaim.** Each component you hold, with what it can become: three of a
rarity into one of the next (never rarer than your reach), or two of one
part type into one of another, same rarity.

**Bounties.** Two Enemies and one Elite, Mini-Boss or Boss you have met, in
the Districts you have fought in (any Enemy you fight counts as met,
practice fights included). Each says what it pays: shards for each Skull
Level it falls at, and components. Beat one in a fight you win (or before an
Emergency Exit) and get home: it is paid then, into the stockpile, once. A
wipe loses the claim. Out there a wanted Enemy wears a **gold diamond** at
its shoulder, its panel says **Bounty**, and the Log says when one is down;
the map's **Team** box lists the board, and which you have beaten.

**Upgrades.** Four, each with three levels, paid in shards and parts:

- **Exchange stock**: more lots of rarer components, and more pre-built
  Troops on offer at once.
- **Starter bay**: more free Frame Trooper copies on every deployment: 6,
  then 8, then 10.
- **Salvage insurance**: a wipe keeps 10%, 20% or 30% of the haul's shards
  and parts.
- **Long-range scanner**: the team sees what tiles hold 2, 3 or 4 steps
  away, not only beside it.

**Deploy** lists your Strike Teams, each marked **Ready**, **Field copy
needed** or **Can't go**. Tap one: below the teams is its **Pack**, and the
bottom line says what its copies cost and what it takes, or why it can't go.
Then **Leave the dock**.

**The Pack.** Every Consumable and Prototype the dock keeps, with **−** and
**+**. A team packs to begin with what its own Consumables and Prototypes
tabs ask for, as far as the dock holds it; change it as you like. What is
packed leaves the dock with the team. Every packed Prototype joins each
fight, and so does every packed Consumable; one used is gone. What wasn't
used comes back when the team is home; a wipe loses it all. (A team's own
lists still set it up for practice fights, where nothing is spent.)

**What leaving costs.** On a deployment a team's Troops must be your designs
(see The Workshop). Each copy of a design in its Deck is paid for in Troop
parts as the team leaves, at the price the Workshop shows; what is paid is
spent, whatever happens out there. The built-in **Frame Trooper** brings its
first 4 copies free (more with the Starter bay). A team whose copies the
stockpile can't pay for stays at the dock, and the bottom line says what
they cost and what it holds. Pre-built copies bought at the Exchange go with
whichever team leaves next, on top of its Deck. Everything else in the team
(Heroes, Equipment, Commands, Aether cards, carried Action cards, the Pouch)
goes free, as before.

**Field copy.** A Strike Team with Troops that aren't your designs (every
team made before 0.9, with the export's Forge Troops in its Deck, or one
with a pre-built Troop in it) can't go, and the bottom line names those
Troops. **Field copy** makes a copy of it without them, with the Frame
Trooper's free copies if it had none, saves it beside the original and
chooses it. The original is left as it was, for practice fights.

**Workshop** opens the Workshop. **World Map** on the dock opens the map with
nobody out, to look around.

**One deployment at a time.** While a Strike Team is out it can't be changed
or deleted: under Strike Teams it reads **Out on a deployment**. You can copy
it and change the copy.

## The Workshop

Tap **Workshop** on the dock. It has three tabs.

**Designs** lists your designs: each one's chassis, its power against the
chassis's cap, whether it fits, what a copy costs and how many your
stockpile could pay for. The **Frame Trooper** is there from the start, on
the starter chassis: it can't be changed or deleted, and **Copy** makes one
that can. **New design** asks which chassis (only those you have found) and
opens the design.

**A design** shows its chassis (its District, subtypes and body plan, its
stats, the most an attack's range and AP can be and its best to-hit, its power cap, how
many abilities it holds, and how many of its keywords you can use), then its
abilities, then its look. On the right, all the time: its power against the
cap, its abilities against the most it holds, **Fits, and you own
everything it uses** or what is wrong, and what one copy costs. Everything
is kept as you change it.

- **+ Add an Action** or **+ Add a Passive**. An Action has a role (one of its
  chassis's subtypes: tap it to change it when there are more), an Energy
  cost, and, for an attack, its range, to-hit and AP. Step them with **−** and
  **+**; they stop at what the chassis allows (a to-hit, between the chassis's
  best and 20). Tap an ability's name to name
  it; **Remove** takes it out.
- **+ Add an effect** opens the **keyword builder**. It asks a step at a time:
  when it happens (every time, or only if something is so; for a Passive,
  always on, when something happens, or while something is true), who it is
  about, what it does, any Modifiers, and how long it lasts. Each step offers
  only what your design can use: the keywords its chassis allows that you
  own. A number is set with **−** and **+**, and stops at what your
  blueprint's level allows. The sentence reads across the top as you build
  it, with what it is worth. **Next** and **Skip** go on, **Back** goes back,
  and the review shows each part with **Change**. **Insert** puts the
  sentence into the ability. Each sentence then has **Change** and **×**.
- **Look**: the skins in your export for its chassis's body plan, those that
  suit its roles first. Tap one to make it the design's card art and board
  token. With none for its body plan, it has no picture yet: skins are drawn
  in the Companion's Pixel Studio.
- **Rename**, **Copy** and **Delete** are at the top. A design can't take the
  name of another design or of a card in your export (the Companion's own
  designs excepted: a design of yours takes the place of one). A Strike Team
  that holds a design keeps it under its new name.

**What a copy costs**, in Troop parts: the chassis's own price, and half the
design's power, rounded up. The prices are the ones in your export.

**What fits**: power within the cap, no more abilities than the chassis
holds, Energy and numbers within its limits, an Action's role one of its
subtypes, only keywords the chassis allows, every ability with an effect,
and the chassis and blueprints (at the levels its numbers need) yours. A
design that doesn't fit can be saved, and put in a Deck, but can't deploy.

**Blueprints** lists those you own, by kind, each with its level and the
highest number each level allows. Target words, damage, heal and turns are
yours from the start. **Research level 2** (or 3) buys the next level with
shards, at the price shown; tap it, and the box says what it costs and what
the stockpile holds. The first level of a blueprint is always found.

**Testing: everything unlocked**, at the top of Blueprints, is a switch.
While it is on, every chassis and blueprint counts as yours, at every level,
and nothing new drops. Switched off, everything is as it was, and a design
that uses what you haven't found can't deploy again until you find it.

**From your export** lists the designs your export carries from the
Companion's Workshop. **Copy in** makes one a design of yours (under a new
name if you have one called that), held to the same checks as any.

**While a Strike Team is out**, the Workshop can be looked at: the designs it
took are marked **Out** and can't be changed until it is home (Copy works),
and research waits.

## The World Map

The map comes from your export: the one on the Companion's World Map page,
with its tables, Events and Unique POIs. The dock, the Hangar, is in the
middle. Each District has its own ground, darker the farther out, with a few
of its things standing on its empty tiles; a light line runs along each
District's border and light dashes mark each rise in Skull Level; rubble is
collapsed structure that nothing gets through. Ground the team hasn't seen
yet is dimmed, under faint scanlines.

- **Drag** to move around, **pinch** to zoom. **Find team** brings the team
  back to the middle; **Fit** shows the whole map.
- **Tap a tile** and the panel on the right says its District, its Skull
  Level, the chance that stepping onto it springs an ambush, and what it
  holds, if you know.
- **What a tile holds shows once your team has stood next to it**, and stays
  known, as an icon on a plate in its colour: a POI gold, a Unique POI pale
  gold, an Ambush red, a Cache green, an Event blue. Faded means cleared: it
  comes back after a few deployments, and the panel says how many. Zoomed
  right out, the icons stay big enough to read.
- **Your team** is its first standing Hero, standing on a lit base; the way
  to the tile you chose is a line of dots.
- **Walk here.** Tap a tile further off and the way to it is drawn, with how
  many steps and the chance of at least one ambush on the way. **Walk here**
  sets off, a step at a time; **Stop** stops where it stands. The team stops
  by itself at anything it finds.
- **The bar** names the deployment and the team. Under it: Heroes standing,
  the haul, steps and fights. **Team** says who stands, who sits out, the
  Troops lost, the Consumables left, the Prototypes and pre-built copies
  with it, the Bounty Board and which of it the team has beaten, and what
  is carried. **Log** tells the
  deployment so far. **Home** goes to the home screen; the team stays out.

**Every step may spring an ambush**: the tile's Skull Level times the
Companion's ambush step, 5% at Skull 1 and 30% at Skull 6 as it ships. An
**Ambush** tile springs one for certain.

Where the team stands, the panel offers what can be done there:

- **A POI: Enter.** A run of floors fought in order, one for a low Skull
  Level and up to three for a high one, with a reward when the last is won.
  Once inside, the only way out early is an Emergency Exit (below). A Unique
  POI has its own floors and its own reward, set in the Companion.
- **A Cache: Open it.** Loot, no fight.
- **An Event.** A short situation and its choices. A choice may need a d20
  roll: "(d20, 10 or more)". The panel says what was rolled and what came of
  it: loot, a blueprint, part of the haul lost, or a fight.
- **The dock: Come home.** The haul goes into the stockpile, what was found
  is yours, the bounties beaten are paid, what was packed and not used goes
  back to the dock, and the deployment ends. The box says each.

When a fight is waiting (an ambush, a POI's next floor, an Event gone
wrong), the panel offers **Fight** and nothing else.

## A deployment's fights

**Fight** opens the setup at who enters. The floor is the one the ambush or
the POI drew; it takes the tile's District, so its Enemies and what they can
leave are that District's.

1. **Heroes.** Those still standing, as many as the floor lets in. A Hero
   held back here is a reserve.
2. **Troops.** Starting Troops, from the copies the Deck still has.
3. **Start battle.**

**Map**, on the first step, goes back to the map with the fight still waiting.

The fight is a Battle like any other, with these differences:

- **The tile's Skull Level sets the Enemies.** Each Enemy spawn tile is
  raised or lowered by as much as the tile's level differs from the floor's
  own, and an Enemy fights and drops at the level it arrived at.
- **No Dimensional Instability yet**, and the wave timer is 3.
- **The team is as it stands**: no Hero who sat out, no Troop that fell, no
  Consumable already used. Every Consumable and Prototype it packed comes to
  every fight, and so do its pre-built copies, on top of its Deck.
- **The Bounty Board's Enemies wear a gold diamond**, and their panel says
  **Bounty**. Bring one down and the Log says it pays once the team is home.
- **Leave** asks first. The team stays where it is on the map and the fight
  starts again from its setup; nothing from the attempt is kept, and nothing
  it used is spent.

**When it ends**, the result says what goes into the haul, who went down, the
Troops lost and the Consumables used, and what comes next:

- **Won:** back to the map; inside a POI, **Next floor**; after its last
  floor, the POI's reward as well.
- **Lost, with a Hero still standing:** what dropped in that fight is lost,
  the haul is safe. **Retry with reserves** sets the same fight up again with
  who is left, or **Give up** ends the deployment as a wipe.
- **Lost, with nobody left: a wipe.** The deployment is over and everything
  it carried is lost, what it packed too, and its claims on the Bounty
  Board. Salvage insurance, if you have it, keeps its share of the haul's
  shards and parts. Your Heroes are back at the dock for the next one.

**The Emergency Exit** is the Sandbox's **EX** symbol on a floor. Inside a
POI, when one of your Heroes ends a move on it, the game asks: **Leave the
POI**, or **Fight on**. Leaving takes the Strike Team out with what it found
on that floor; the POI's reward is given up, and the POI is cleared. A Troop
can't lead the way out, and in an ambush there is no way out.

## Blueprints and chassis

A blueprint unlocks a keyword for the Workshop; a chassis is a frame a Troop
is built on. Levels 2 and 3 of a blueprint raise the numbers it can be
written with, and can be found or researched.

- **Where they come from:** an Enemy that goes down (rarely, more often an
  Elite or a Mini-Boss), a Loot Tile, a Locked Chest, a Cache, a POI's
  reward, some Events, and a floor's own reward. An Enemy card can name its
  own drops; each District has a pool of what else can turn up there. The
  chances and the pools are the ones in your export.
- **Only what you can use drops:** the next level of a blueprint you are
  missing, or a chassis you don't have.
- **In the Log** one reads "leaves a blueprint not found before: win to keep
  it and learn what it is". Win the fight and it is named. It is **yours
  once the team is home**; a wipe loses it, though you will know its name
  when it turns up again.
- **The dock** lists what you own, and its Exchange sells what you could
  use next from the Districts you have fought in.

## What is kept, and where

Your Strike Teams, the Behavior keywords you chose, and your progress (the
map as you have explored it, the stockpile, your blueprints and chassis, your
designs, the testing switch, the dock (your reach, its upgrades, the
Exchange's stock and the Bounty Board) and what it keeps for you, the
deployment that is out, and the deployments so far) are stored with the Godot
app's data on your phone, not in the game's folder. A new version of the game
or a new export leaves them alone. Clearing the Godot app's data, or
uninstalling it, removes them.

Progress is saved after every step, Cache, Event and finished fight. Close
the game anywhere and the team is where you left it. **A fight is not saved
part-way**: close the game in one and it starts again from its setup.

If the phone ever refuses to write the file (no space left, say), the map
says so in a line under the status, and the dock on its bottom line, until a
save works. Buying, selling and everything else at the dock is saved as it is
done. It is tried again at every step.

**A new export with a different World Map** (another map chosen or made in
the Companion) starts exploration again: nothing is known, nothing is
cleared. The stockpile, what you own, the dock and your designs stay. A Strike Team that was out on
the old map is brought home with its haul. The home screen says so, once.
An export with no World Map at all (one from before Companion 13.1) counts
as a different map too.

This progress is the game's own. The Companion's own deployments, on its
World Map page, are separate.

## Strike Teams

A Strike Team is up to 3 Heroes, one Deck they share, the Action cards each
Hero carries, one Aether Pouch, any Prototypes, its Consumables, and a Player
Level.

Tap **Strike Teams**, then **New team**, and give it a name. A team opens on
seven tabs. On every tab the cards are tiles: the card's art (or three letters
until it has some), its name, its kind, and what matters most about it.
**Tap a tile to read the card in full**; what you can do with it is along the
bottom of that sheet. A gold **Plain text** strip across a tile's corner means
some of that card's text isn't written with keywords, so the game can't carry
it out (see Playing cards, below).

- **Heroes.** Every Hero in the export. Open one and tap **Add to the team**.
  A floor lets in 1, 2 or 3 of them by its size; the rest wait in reserve.
- **Deck.** Every Troop (your Workshop designs first, marked as yours),
  Equipment, Command and Aether card. Open one and set
  its copies with **−** and **+**; a gold badge on its tile counts them. The
  buttons above filter by kind, and **See Deck** shows only what's in it.
- **Carried.** Action cards are never in the Deck: a Hero carries them. Pick
  the Hero at the top, open an Action card and tap **Give to** that Hero. In
  a fight a carried Action card is one of that Hero's Actions.
- **Pouch.** A basic Chip for each District (1 Aether of that District), then
  every Aether Chip card. Open one and set how many are packed.
- **Prototypes.** They belong to the team, not the Deck. In a fight their
  Passives are always on, acting through the Hero who leads.
- **Consumables.** Every Consumable card. Open one and set how many the team
  carries into each Battle (up to 9 of a kind). They aren't in the Deck and
  aren't drawn: all of them are there from the first turn. The Handbook lets
  3 kinds be brought to a battle; a fourth is a note in Checks, not a block.
- **Checks.** What the Handbook says about the team as it stands: a Deck is 10
  to 60 cards, no Hero carries more Action cards than it has Action Slots,
  the Pouch holds at least as many Chips as the Deck's most expensive card
  costs (a variable cost counts at its least: X is 1), and so on. These are the Companion's Deck Builder's checks, word for
  word. Two more are the game's own, both notes: more than 3 kinds of
  Consumable, and, last, the names of the team's cards that have plain text.
  **None of them stops you.** Only a team with no Hero can't fight.

**Player Level** (top right, 1 to 6) is how many Chips come out of the Pouch
each round. Tap the team's name to rename it. On the list of teams, **Copy**
makes another like it and **Delete** asks first.

Any card in the export can go in a team, in any number, for the practice
fights. On a deployment its Troops must be your designs, and each copy is
paid for as it leaves: see The dock.

Every change is kept as you make it. Teams are stored with the Godot app's
data on your phone, not in the game's folder, so a new version of the game or
a new export leaves them alone. (Clearing the Godot app's data, or
uninstalling it, removes them.) A team remembers its cards by name. If a new
export no longer has one of them, the card stays in the team, shown in red
as "Not in this export", and is left out of a fight until an export brings
it back or you take it out.

## Setting up a Battle

1. **Floor.** Pick where to fight. A floor's size (set in the Sandbox) decides
   how many Heroes may enter: Small 1, Medium 2, Large 3.
2. **Strike Team.** Pick the team. Each says whether the Checks have anything
   to fix; you can send it in regardless.
3. **Heroes.** The team's first Heroes are sent in, as many as the floor
   allows. Tap one to hold it back or send it in. Tap **Lead** on a Hero to
   put it in charge: Prototypes act through the leader.
4. **Troops.** Starting Troops come out of the Deck and begin beside your
   Heroes at no Aether cost, within the pooled Leadership of the Heroes going
   in. You can't start more of a Troop than the Deck holds. A Troop with a
   variable cost that starts here was never paid for, so its X is 1. Under
   the Troops are two more rows (drag the list up if they're below the edge):
   the **wave timer** (1 to 10; the Companion uses 3), and **Districts
   cleared** (0 to 5), which sets Dimensional Instability: see below.
5. **Start battle.**

## A Battle, round by round

Enemies arrive in **six waves**, an Enemy on every open Enemy spawn tile each
time, dealt from a pile made for the floor (six for each spawn tile, at that
tile's level, from the floor's District). The next wave comes when the board
is clear, or when the wave timer runs out, whichever is first. You win when
the last wave has come and no Enemy is left. You lose when every Hero is down.

When you tap **End turn**, the Enemies take their turn, and then the round's
phases play out by themselves. Each is named in a banner across the top of
the board with what it did, and all of it goes in the Log. Tap the board to
hurry them.

1. **Waves.** The next wave arrives if it's due.
2. **Aether Generation.** Aether you didn't spend is lost. Every Hero still
   standing generates Aether of its own District, as much as its Affinity
   Level.
3. **Aether Draw.** Chips equal to your Player Level come out of the Pouch
   into the Bank. Every Chip in the Bank generates its Aether, this round and
   every round after.
4. **Draw.** You draw one card for each Hero still standing. (You open with
   six.)
5. **Recharge.** Statuses that arrived in your last turn tick, and Energy has
   refilled; it's your turn. (Statuses that arrived in the Enemies' turn tick
   when you tap End turn: see Statuses, under What cards say.)

On the screen:

- **The top bar** shows the wave and when the next is due ("Wave 2 of 6 ·
  next in 2", "· clear", "· the last"), the round, and **Aether**: what you
  have this turn, a gem for each point in its District's colour (white for
  any). Tap it for the Chips in the Bank, what's left in the Pouch, and the
  team's Prototypes.
- **Hand**, **Consumables** and **Chips** (bottom left) each open a tray over
  the lower part of the board, its cards side by side as a fan (0.14), each
  printed whole: the cards in your hand; what the team carries, one for each
  kind with how many are left; and the Chips in the Bank that have an effect
  to spend them for. Consumables shows only when
  the team carries some, Chips only when the Bank holds such a Chip. A tile
  that can't be played now is faded. Tap a tile to read the card in full, with
  **Play**, **Use** or **Spend** along the bottom. **Close** puts the tray
  away. While it's open the board above it still pans and takes taps.
- **Deck · Discard** (above those buttons) counts both. Tap it to look
  through the Discard Pile, newest first.
- **Auto** switches Auto on and off: see Auto, below.
- **Loot**, in pale yellow under the top bar, counts what has dropped so far.
- **End turn** asks first if one of your Units could still move or act. When
  the board is clear it doesn't ask: the next wave is waiting.
- **Leave** asks where to: stay, set up another Battle, or go home. A battle
  isn't kept once you leave it. (In a deployment's fight it asks whether to
  go back to the map.)

### Dimensional Instability

The Handbook's rule for a campaign: for every District you have cleared, each
Enemy spawn has a 3% chance (15% at most) of bringing an Elite, two times in
three, or a Mini-Boss, in place of the Enemy that was drawn, whatever the
tile's level. Nothing in the game counts cleared Districts yet, so for a
practice Battle you say how many as you set it up, on the last step. It
starts at 0 every time. **A deployment's fights have none** until Districts
can be cleared.

The Elite or Mini-Boss comes from the floor's own District. If the District
has none of the kind rolled, the Enemy that was drawn arrives after all, and
the Log says so ("Dimensional instability stirs, but District 3 has no Elite
to send"). The setup screen tells you how many of each the floor's District
has in this export before you start. With none, the setting does nothing.

When one arrives, the Waves banner and the Log name it. A Quick battle has no
Dimensional Instability.

## Auto

**Auto** in the top bar is a switch: the loop round an A, lit while it is on
(its name, **Auto: on** or **Auto: off**, is its tooltip). It stays as you
leave it until you tap it again, from one Battle to the next.

With Auto on, your turn opens as usual. Play your cards, and move or attack
with anyone you like. When you tap **End turn**:

1. Every Unit of yours **you haven't used this turn** takes its turn by
   itself, one at a time. Used means moved, used an Action, or holding fire.
   A Unit you have used is left exactly as you left it.
2. Then the Enemies take their turn, and the round turns over as always.

Tap the board to hurry them. End turn doesn't ask about the Units Auto is
about to take. It still asks about a Unit you used that could do something
more, since Auto won't finish its turn for you.

A Unit on Auto does what an Enemy does, by its **Behavior keywords**:

- With none, it closes on the nearest Enemy and attacks it with the most
  damaging Action it can pay for.
- **Who it attacks:** Valiant (the nearest Boss or Mini-Boss), Decisive (the
  lowest Health), Precise (the lowest Armor Class), Dauntless (the highest),
  Defiant (whoever last attacked it), Coordinated (an Enemy an ally has
  already attacked this round), Thorough (an Enemy with no status yet).
- **Where it goes:** Wary X (backs away from any Enemy within X tiles, then
  acts), Prudent X (at X Health or below, withdraws and does nothing else),
  Steadfast (holds its tile).
- **What else:** Medic (uses a Support Action on the most wounded ally before
  it looks for a target), Guardian (stays within 1 tile of your Hero).

**To set them,** tap one of your Units. Under its Actions the panel has **On
Auto**: what it carries now. Tap that row. The twelve keywords are listed,
each with what it does: tap one to put it on, tap it again to take it off.
Wary and Prudent have a **−** and a **+** for their number once they're on.
A Unit carries three at most. The order you put them on is the order they
count in: where two apply at once, a keyword with a condition outranks one
without, and of two with conditions the first wins. Two that both always
choose a target leave the second doing nothing, and the picker says so.
**Done** gives them to that Unit and to every other Unit of the same card on
your side.

**The game remembers what you chose for a card**, so its Units arrive with
the same keywords in every later Battle. A card you never chose for uses the
keywords printed on it, if it has any. The choices are kept with the Godot
app's data, beside your Strike Teams.

On Auto:

- A Hero pays the Aether a carried Action card costs, or doesn't use it. One
  with a variable cost is used at X = 1.
- A Burst makes all of its attacks, choosing its target afresh each time.
- A Unit that ends its turn on a Loot Tile or a Locked Chest finds the loot.
- Nothing Auto does can be taken back with Undo.
- Auto doesn't play cards, use Consumables or spend Chips. Those are yours.

An Enemy's panel shows its Behavior keywords too, under **Behavior**.

## Loot

- **An Enemy that goes down drops loot**, once: Aether shards, and often
  components (Troop, Equipment and Aether parts, in six rarities). How much
  depends on what it was (an Elite or a Mini-Boss drops more), its Skull
  Level, and what its card says it salvages into.
- **A Loot Tile** is captioned **Loot** on the board. The first of your Units
  to end a move on it finds what it holds, and its caption changes to
  **Empty**.
- **A Locked Chest** is the Sandbox's **LC** symbol. It holds two components,
  or the number written after LC (**LC3** holds three). The first of your
  Units to end a move on it opens it, and its symbol is struck through.
- Tap a Loot Tile or a Locked Chest with nothing chosen and the bottom line
  says what it is, and whether it's been emptied.
- **A floor's own reward** is set in the Sandbox (the Rewards box of a
  floor). It is rolled when you win the floor.

As it happens: a pale yellow number rises off the Enemy or your Unit, the
bottom line and the dice readout say what dropped, and the count under the
top bar grows ("Loot: 12 shards · 3 parts"). The **Log** has every drop in
pale yellow, and what has dropped so far in full under its title. Taking a
move back with Undo takes back what the move found.

**The result** totals it: what dropped and was found, the floor's reward, and
the two together. **On a deployment it goes into the haul**, and into your
stockpile when the team is home. **In a practice Battle nothing is kept**,
and the result says so. A fight that is lost loses what dropped in it.

A drop can also leave a blueprint or a chassis: see Blueprints and chassis.

The numbers come from the Companion's Loot page: the drop tables in your
export are the ones the game rolls on.

## Playing cards

Cards are played on your turn, in any order, between and around your Units'
moves and Actions. It always goes the same way: **tap the card to read it,
tap Play, then tap what lights up.** Nothing is paid until the card lands.
Until then a tap away from what's lit puts it back (the bottom line always
says where to tap), and End turn waits.

A card's sheet says, under its cost, how it will be played, or why it can't
be now ("needs 2 D3, and the Bank holds 1 D3", "Every Player Spawn Tile is
occupied", "Cards are played on your turn"), and then Play is off.

- **A Troop** arrives on a Player Spawn Tile nobody stands on. The open ones
  light up: tap one. With only one open it goes there by itself. It can move
  and act the turn it arrives, and it is chosen for you, ready to go. Its
  card stays with it on the Battlefield.
- **Equipment** goes on one of your Units: they light up, tap one. (With
  only one of yours standing, it goes on that one.) Its Passives are on from
  then; anything else it says happens once, as it goes
  on. The Unit's panel lists what it wears under **Equipment**. The card
  stays with the Unit.
- **A Command or an Aether card** is paid for, what it says is carried out
  through your leader, and it goes to the Discard Pile.
  - If it's aimed at an Enemy or at one of yours, those it can go to light
    up: tap one.
  - If it has an area as well, the first tap lights the area and names
    everyone else it would take in; tap the same Unit again to play it, or
    another to move it.
  - If it's aimed at a tile, tap any tile to see what it would take in there,
    and the same tile again to play it.
  - If it needs none of that, Play plays it.
- **A Consumable** is used the same way, with **Use**. It costs no Aether,
  does what it says once, and is gone for the rest of the Battle.
- **A Chip with an effect** can be spent for it once a round, with **Spend**.
  It has already generated its Aether this turn, and keeps doing so; it reads
  **Spent** until the Recharge.
- **Recover** (new in Handbook 15.7, and what a Repair Kit does) returns a
  Troop's card from the Discard Pile to your hand, to be played again at its
  normal cost. With several there, a tray of them opens: tap the one you
  want. With none, the card that Recovers can't be played, and says so.
- **Undo** (top bar) takes back the last card, Consumable or Chip, with
  everything it did, just as it takes back a move: the Aether returns, the
  card is back where it was. It works back through cards and moves in the
  order you made them, and stops at the last roll of the dice or the last
  card drawn.
- **The Discard Pile.** A Command or Aether card goes there as it's played. A
  Troop's card goes there when the Troop goes down, and an Equipment card
  when it's taken off or the Unit wearing it goes down. All of it returns to
  the Deck when the Battle ends.
- **An Action card a Hero carries** costs its Aether each time it's used, as
  well as its Energy: the panel shows both ("2 NRG + 1 D3 Aether"), and
  "Needs 1 D3 Aether" when the Bank is short. Holding fire with one pays both.

### Variable costs

A card may cost **X** (Handbook 15.8). Its tile and its sheet read "X D3",
"1 D3 + X any", or "XX any" where X is paid twice.

- **Choosing X.** The card's sheet has **X** with a **−** and a **+**, from 1
  up to the most the Bank could pay. As you step it, the sheet shows what
  that X costs and reads the card with the number in place: its text
  ("takes damage 3") and its numbers. Then **Play**, as for any card.
- **X is at least 1.** With the Bank short of X = 1 the card can't be played,
  and its sheet says what it needs at least.
- **X in the text** stands wherever a keyword takes a number: damage X, +X
  HP, for X turns, Deploy X of something.
- **A stat written N(X)** is N for each X: a Troop with Health 4(X), played
  for X = 3, arrives with 12. A Unit keeps its X: its panel reads with it.
- **Nobody paid:** a Starting Troop, or a Unit put down by a Deploy, has
  X = 1.
- **A carried Action card with a variable cost** asks each time it's used.
  Tap the Action and a box asks for X, with what it costs and what it will
  do; **Aim it** lights its targets, **Put it away** spends nothing. Holding
  fire with one, and Auto, use X = 1.
- **X on a card with no variable cost** has no value. Such a card stops on a
  card-problem box when it's played. The Forge flags it as you write it.

**Plain text.** A card can only do what its keywords say. Text with no
keywords is plain: the game can read it to you but can't carry it out. Such a
card can still be played. Its tile wears a gold **Plain text** strip, its
sheet warns you before you pay, the bottom line says so when it lands, and
the Log has the text that didn't happen. The Checks tab lists a team's
plain-text cards. To make one work, rewrite its text with keywords in the
Companion's Card Forge and export again.

## Setting up a Quick battle

1. **Floor.** As above.
2. **Heroes.** Any Heroes in the export, up to what the floor allows.
3. **Troops.** Optional. Your Workshop designs and pre-built Troops come first,
   marked, then every other Troop card. Tap a row (or its **+**) to bring one,
   **−** to take one back. Their Unit Slots come out of your Heroes' pooled
   Leadership, and the game says when one won't fit.
4. **Start battle.** Every Enemy spawn tile gets an Enemy, drawn from the
   floor's District at that tile's level (failing that any District, then the
   nearest level, lower first). One wave: bring them all down to win.

A Quick battle has Auto and shows its loot like any other. It has no
Dimensional Instability and no cards.

In both kinds of fight your Heroes, then your Troops, stand on your Player
Spawn Tiles; if there are more Units than tiles, the rest stand beside them.

## Fighting

- **Tap one of your Units** and the side panel shows it: its token, Health,
  Armor Class, Movement Speed, Energy and Integrity; (0.16) a strip of what it
  can still do this turn, Move and how far, Attack and Hold fire, each dimmed
  once used; its Actions and its Passives, each with its text as the card
  reads; every status on it; and anything changing its numbers. The tiles it
  can reach are lit.
- **Tap a lit tile** and the way there is shown, then the Unit walks it, one
  tile at a time. Walls and other Units are in the way; a flying Unit passes
  walls. **Undo** (top bar) takes a move back, with anything the move set
  off, until dice are rolled or a Unit holds fire. (It takes back cards the
  same way: see Playing cards.)
- **Tap an Action** in the panel to aim it. An Action that can't be used now
  is greyed, with the reason ("Needs 2 NRG", "Nothing in reach", "No line of
  sight"). The Units it can reach light up, each with a tag: the chance it
  gets through (hits, then Penetrates) and the damage, green, amber or red.
  The chance is exact, worked out from the rules, Cover included.
- **Tap a lit target** and the dice are rolled: a readout by the target shows
  each roll and what it needed, then what the Action's text did. Numbers and
  words rise off whoever they happened to: red for damage and what harms,
  green for healing and what helps. A Unit at 0 Health is down, and fades away.
- **Tap the Action again**, or anywhere else, to put it away.
- **Each of your Units moves once a round**, and uses any Actions it can pay
  Energy for, in any order. It's dimmed once it has moved.
- **End turn** (it asks first if a Unit could still move or act; with Auto
  on, the Units you haven't used take their own turns first) and the
  Enemies take their turn, one at a time: each backs off or closes in as its
  behaviour keywords say, picks its target, and attacks if it can reach, and
  what its Action says is carried out. A Stunned Enemy loses its turn. Tap the board to hurry them. Then held
  shots nobody walked into lapse, hazards bite, Energy refills (a Troop to
  full; a Hero keeps what it didn't spend, and adds its own), Statuses from
  your turn tick, and it's your turn again.
- **The battle ends** in Victory or Defeat, with what dropped: **Play again**
  (the same floor and team, dealt afresh), **New battle**, or **Home**. **See the board**
  leaves the result on screen; **Leave** brings the box back. (A deployment's
  fight ends on what the deployment does next: see A deployment's fights.)
- **Log** (top bar) lists everything that has happened, round by round.
- **Tap an Enemy** to see it in the panel; it acts on its own.
- **Drag** to move around the board; **pinch** to zoom (or use the mouse
  wheel). **Fit** frames the whole floor again.
- **The leader** of a Strike Team has "Leader" beside its name in the panel.

## What cards say

- **Statuses** show on the board as a small mark by the Unit's head, each
  status its own (0.14; they were coloured dots). The side panel names each in full, with what it does
  (its own number in place: "Slowed 2: Movement Speed reduced by 2") and how
  long it has left. Changes to a Unit's numbers (AC +2 for 2 turns) are listed
  under **Changes**, with where they came from.
- **When a Status ticks** (Handbook 15.9). A Status ticks at the end of the
  turn after the one it arrived in. One that arrives in **your turn** ticks
  at the Recharge, once the Enemies have had their turn. One that arrives in
  **the Enemies' turn** ticks when you tap End turn, before the Enemies act:
  the bottom line says what it did ("Your turn ends: ..."), and it is in the
  Log. So a Status of 1 turn always lasts through the whole of the next turn:
  an Enemy you Stun loses its turn, and a Hero an Enemy Stuns loses theirs.
  Poison from an Enemy bites after you have had a turn to answer it. A timed
  change to a Unit's numbers counts down the same way. Until 0.8 everything
  ticked at the Recharge.
- **Locks** (Handbook 16.0): Stunned, Rooted, Pinned and Marked last 2 turns
  at most, and a second dose does nothing ("Test Grunt is already Rooted").
  Once one ends, the Unit is guarded against it until the same point of the
  next round: the lock's mark, faded, beside its others, **Guarded** in the side panel,
  and a lock aimed at it is shrugged off, as the Log says.
- **An Action with an area** (an AoE, or "all enemies within 2") takes two
  taps. The first lights the blast and rings everyone it would take in, with
  **Yours!** over any of your own it would hurt, and the bottom line names
  them. Tap the same target again to fire, another lit target to move the
  blast, or anywhere else to put it away. Nothing is rolled or paid until it
  fires. Any other Action fires on the first tap.
- **A Burst** makes its Action several times for one payment of Energy. After
  each attack, the targets still in reach light up again with their odds: tap
  one for the next. When only one is in reach, it goes there by itself. A
  Burst runs to its end while a target remains, as in the Companion; End
  turn waits until it has.
- **Hold fire.** An Action with Suppressive Fire has a gold button under it.
  Tap it and the Unit pays the Action's Energy now and wears a gold sight. In
  the Enemies' turn it shoots the first of them to move into its reach, and
  the shot is shown as it happens. If none does, the hold lapses with the round.
  A Unit that has moved this round can't hold.
- **Hazards** wear a broken amber edge. A hazard tile in a Unit's reach is lit
  amber instead of cyan, and the bottom line says what it does; tapping it
  still moves there. Tap a hazard with nothing chosen to read what it is. A
  hazard bites a Unit that moves or is pushed onto it, and again if it ends
  the round there. Enemies walk round one when there's a way round.
- **Passives and Auras** work by themselves: always-on ones from the start,
  the rest when what they listen for happens. What they do shows as it
  happens and is in the Log.
- **A card that can't do what it says** (an effect with no Duration where one
  is needed, a keyword the library doesn't have) stops the fight on a box
  naming the card and what couldn't happen. Tap **OK** and the fight goes on
  without it; the line is in the Log, marked. Fix the card in the Companion's
  Card Forge and export again. Text on a card that isn't keywords is noted in
  the Log as not carried out, and doesn't stop anything.

## The rules

`scripts/rules.gd` is the Companion's `rules.js`, brought across whole: the
same Units, statuses, attacks, dice and turns. The game owns the rules: a rule
changes here first. (`rules.js` has changed three times for the last three versions,
in both builds together: see the end of this section.)

`scripts/battle.gd` runs the parts of a fight that need the board: aiming,
Cover, the Enemies' own turns, your Units' turns on Auto, the waves and
Dimensional Instability, Aether, Chips, the Deck, playing cards, Consumables,
loot, and the round turning over. `scripts/keywords.gd` is the Companion's
keyword library (`keywords.js`), which reads a card's text;
`scripts/effects.gd` carries it out. Those three come from the Companion's
Battle Simulator. `scripts/loot.gd` is the Companion's `loot.js`: the drop
tables and the rolls. `scripts/strike_teams.gd` holds a team and the Deck
Builder's checks. For 0.8, `scripts/world.gd` is the Companion's `world.js`
(the map, what a tile holds, ways across it, the floors a fight is drawn
from, Events), `scripts/deployment.gd` its `deploy.js` (a deployment, from
the dock and back to it), and `scripts/progress.gd` its `progress.js`
(blueprints and chassis, and what can drop). For 0.9, `scripts/workshop.gd`
is its `workshop.js` and `chassis.js` (designs, the fit check, what a copy
costs, a design as a Troop card), `scripts/scoring.gd` the part of
`scoring.js` that says what an ability is worth, `scripts/skins.gd` its
`skins.js` (a design's look), and `scripts/builder.gd` its keyword builder
(`builder.js`): every step, what each offers, what each tap does, and the
sentence it makes. For 0.10, `scripts/dock.gd` is its `dock.js`: the
Exchange, Reclaiming, the Bounty Board, the upgrades and what the dock keeps
for you.

All of it is proved to be the Companion's own, case by case:

- the Companion's rules suite, translated check for check (`tests/rules_tests.gd`);
- thousands of cases made by running `rules.js` itself, replayed here and
  compared (`tests/rules_diff.gd`);
- over 31,000 cases made by running the Battle Simulator's and the Deck
  Builder's own functions on the export's floors and cards: the keyword
  reader on every card's text; reach, sight and Cover; what an Action can do
  and who it can be aimed at; the start of a fight; your moves and attacks
  with everything the Action's text does; holding fire; whole Enemy phases
  with the round turning over; whole Strike Team fights from setting up to
  the last wave (the shuffle, the Enemy pile, each wave, the wave timer,
  Aether, Chips, the cards drawn, who wins and when); every card as it sits
  in a hand with what it costs and what it needs before it can be played;
  300 Strike Team fights with their cards played (Troops deployed, Equipment
  attached, Commands and Aether cards aimed at Units and at tiles,
  Consumables used, Chips spent, carried Action cards paid for in Aether,
  Troops' cards Recovered, and each of them refused when it can't be); and
  the Deck Builder's checks on hundreds of teams. New for 0.7: cards played
  for an X and carried Action cards used for one; a thousand turns taken on
  Auto under Behavior keywords dealt at random; Dimensional Instability at
  every setting, in Districts that have an Elite to send and Districts that
  don't; and loot, both the tables themselves (1,400 rolls, rewards and
  wordings, seed for seed) and loot in the fights: about 1,300 Enemies'
  drops, Loot Tiles found and Locked Chests opened by Units that walked onto
  them and by Units on Auto, and the floor's reward on a win. Each is
  replayed here and compared Unit by Unit, log line by log line, down to the
  numbers that rise off them and the last shard (`tests/sim_diff.gd`). New
  for 0.8 in those cases: the end of your turn, with Statuses and timed
  changes that arrived in either half of the round; blueprints and chassis
  left by Enemies, Loot Tiles, chests and a floor's reward, for players who
  own nothing and players who own some; and a hundred and fifty fights that
  are part of a deployment, at every Skull Level, with what each tells the
  deployment when it ends. So
  that every keyword is exercised, the generated fights also use Actions and
  Passives written for the purpose, and the test export carries one floor the
  Companion doesn't ship, **TEST · Loot**, with Loot Tiles, two Locked Chests,
  an Emergency Exit and a reward of its own. It also has a World Map that is
  the same every time, with a Unique POI on it, and three test Enemies that
  leave blueprints or a chassis (the Companion's own test cards leave none);
- for 0.8, over 3,600 cases made by running `world.js`, `deploy.js` and
  `progress.js` on the export's map: every tile; ways across the map and
  their risk; the floors drawn for a fight; Events; what can drop and what a
  drop is called; 1,000 drops rolled; and 150 runs of one to four
  deployments each, walked step by step (4,000 steps, ambushes sprung, POIs
  entered and fought to their reward, a Unique POI's own floors, Caches,
  Events with their checks, fights won, lost, retried and escaped, wipes and
  coming home), compared after every step down to the haul, the map as
  known and the log (`tests/world_diff.gd`). New for 0.9 in those cases:
  teams of designs leaving the dock (what each copy costs, the starter's free
  copies, and the reasons a team can't go, word for word), the copies paid
  and lost, and the testing switch;
- for 0.9, over 5,600 cases made by running `workshop.js`, `chassis.js`,
  `scoring.js`, `skins.js`, `progress.js` and the keyword builder itself
  (`tests/workshop_diff.gd`): 900 designs' power, fit check and cost and the
  Troop cards they make; the score of every keyword; blueprint levels,
  research prices and research; a design's look; and 520 walks through the
  keyword builder, 8,000 taps in all, each tap given to the Companion's
  builder as a click and the screen it draws then read back and compared
  with the game's, step by step: what is offered, the sentence, its worth,
  and what Insert gives;
- for 0.10, 600 cases made by running `dock.js` (`tests/dock_diff.gd`): its
  tables as Dev Mode may have saved them, sensible or not, and 400 runs of
  what a player does at the dock (restocking; buying and selling
  components, lots, blueprints, chassis, Consumables, Prototypes and
  pre-built copies, with too few shards as often as enough; Reclaiming;
  upgrades; deployments coming home with bounties to claim, or wiped out
  with insurance), compared after every step down to the last shard and
  the Exchange's shelves. The deployments in `tests/world_diff.gd` now leave
  with packs and pre-built copies, and end at the dock as the Companion's
  do: bounties paid, insurance kept, the Exchange restocked, the reach
  extended.

`tests/soak.gd` plays battles of both kinds through with the export's real
cards and a random hand, cards played and taken back included, checking that
nothing breaks, that no card is lost or made from nothing, and that a card
taken back leaves everything as it was. In 0.7 it also plays cards for an X
(and checks one asked for more than the Bank holds is refused), leaves rounds
to Auto, and checks every Enemy that goes down drops its loot once and every
fight that ends settles it once. In 0.8 it checks every blueprint and
chassis left behind as well: one the export knows, found once, with its line
in the Log, and settled with the fight. `tests/soak_screen.gd` does the same
through the screen, tap by tap, checking it never gets stuck and that the
loot count, the tiles emptied and the result say what is so.
The first also lists any card problems it met, which is a quick way to find
cards whose text needs fixing in the Forge.

`tests/soak_world.gd` (0.8) plays whole deployments with a random hand:
forty without the screen, each fight a real Battle with both sides on Auto,
and eight through the screen (the dock, the panel's buttons, Walk here, each
fight's setup, the Battle, its result box, and home). It checks that the
books balance (the haul and the stockpile are never short or over, a Hero
who went down stays out, a Troop that fell stays gone, a Consumable used
stays used, a blueprint is found once and in order), that what is saved is
what is so, and that the screen says what is so. In 0.9 its teams take out
designs made with the keyword builder by random taps, which fight, and it
checks that every team pays exactly what its copies cost as it leaves, and
that one that can't pay stays at the dock with nothing spent. In 0.10 it
shops at the Exchange between deployments and buys upgrades (every price
paid to the shard), packs what the dock keeps and takes pre-built copies
out, and checks that what is packed leaves the dock and what is unused
comes back, that a wipe loses the pack and insurance keeps exactly its
share, that a bounty is tagged in the fight and paid once at home, and that
the dock is closed while a team is out. Through the screen, a random hand
taps whatever the dock's tabs offer between deployments, and it checks that
what is saved and what is shown are what is so.

`tests/soak_workshop.gd` (0.9) uses the Workshop with a random hand, through
its screens: three hundred moves, designs made on random chassis, abilities
added and taken out, numbers stepped, effects built and changed with the
keyword builder by thousands of random taps (only ever those it offers),
looks chosen, designs renamed, copied, deleted and copied in, blueprints
researched, the testing switch flipped, and everything read back from the
save now and then. It checks that the design on the screen is the design
kept, that its power, its fit and its card are what the Workshop says, that
an effect the builder made never uses a keyword its chassis can't or a
number past your blueprints, that research spends exactly its price, and
that a rename reaches the Strike Teams that hold the design.

Where the game deliberately differs:

- **Two cards whose names differ only in capitals are two cards.** The
  simulator treats them as one and keeps the first, so of "Aether Battery"
  (a Troop) and "Aether battery" (an Aether card) it never sees the second.
  The game keeps both. Renaming one of them in the Forge would be clearer.
- **A few more numbers rise off Units.** The simulator shows nothing over a
  Unit bitten by a hazard or pushed into a wall; the game shows the damage
  (and the hazard's status). What happens is the same.
- **Taking a move back takes back what it set off** (a hazard's bite, a
  Passive that heard the move), not only the step.
- **The odds are exact.** They're counted from the rules, so an Aether
  attack shows 100%, and damage written only in an Action's text counts.
- **You choose where a Troop lands.** The simulator puts a Troop played from
  the hand on the first open Player Spawn Tile. The game lights the open
  ones and you tap one. (The comparison tells the game which tile the
  simulator used.)
- **More Units than spawn tiles:** the rest stand beside the spawn tiles,
  not at the bottom edge.
- **Enemies come from the floor's own District.** A spawn tile's Enemies are
  dealt from the floor's District at the tile's level, which is the
  simulator's rule on a deployment; a free fight in the simulator takes any
  District. The comparison gives the simulator the same rule, so everything
  else is still compared.

- **Auto takes only the Units you haven't used, and only when you end your
  turn.** The simulator's Auto plays the whole fight for you, every Unit,
  until you take over. What one Unit does on Auto is the same in both, and is
  compared; how the game fits that into your turn is the game's own.
- **Behavior keywords are chosen in the fight and remembered for the card.**
  The simulator sets them before a fight and keeps named presets.
- **A number stops at what your blueprint's level allows.** In the
  Companion's keyword builder a number can go past it, and the design then
  says which level it needs. The game's builder stops there, and says so;
  the fit check is the same in both.
- **A design of the Companion's has to be copied in.** In your export the
  Companion's designs are cards of their own; on a deployment a team takes
  only your designs, so one of the Companion's is copied in first. A team
  made before 0.9 gets a Field copy, which the Companion doesn't have.
- **The Emergency Exit asks first.** In the Companion a Hero who steps onto
  it takes the team out at once.
- **Every packed Consumable comes to every fight.** In the Companion each
  fight's setup chooses from what was packed, up to three kinds.
- **The Pack begins with the team's own lists**: what its Consumables and
  Prototypes tabs ask for, as far as the dock holds it. The Companion's Pack
  starts empty.
- **An export that ticks no Consumables or Prototypes for the Exchange**
  carries every one of them, at 20 shards. The Companion's Exchange carries
  none then.
- **The game keeps its own progress.** The map you have explored, the
  stockpile, your blueprints and chassis and your deployments are the
  game's, apart from the Companion's own on its World Map page.
- **Not here yet:** Dimensional Instability on a deployment.

Things that used to be on this list, now the same in both:

- An Enemy that still can't reach anyone after its move doesn't attack, and
  an Enemy brought down by a held shot as it moves doesn't go on to attack.
  Companion 13.2 fixed both in its simulator.
- Paying for a District card with Generic Aether when the Bank held none of
  that District left Not-a-Number in the Companion's Bank, which then
  couldn't pay for anything else that turn. Companion 13.3 fixed it in
  `rules.js`, and it now leaves a plain 0 as the game does.

And where 13.3 brought its simulator to the Handbook, alongside 0.6:
a Troop's card and an Equipment card stay with their Unit until it goes down
(they used to be discarded as they were played); Consumables do what their
text says; a carried Action card costs its Aether; a Chip counts as spent
when its effect happens, not when it's tapped; and Consumables and Chips are
used on your turn only.

With 0.7 and Companion 13.4:

- **`rules.js` changed again**, in both builds together: a Unit's stat may be
  written N(X), and a Unit remembers the X it was played for.
- **Three things the comparison found, fixed in the Companion's simulator:**
  on Auto, a Hero used a carried Action card without paying its Aether; a
  Burst on Auto made one attack, not all of them; and a Unit that Auto left
  standing on a Loot Tile or a Locked Chest didn't find the loot.
- **One neither had right: Stunned.** The Handbook says a Stunned Unit
  "cannot act or move at all". In both builds a Stunned Enemy was held to its
  tile but still attacked whoever it could reach on its own turn (your own
  Units' buttons were greyed, so it only ever went the Enemy's way). Now a
  Stunned Enemy loses its turn, its Combo starts again, and the Log says so;
  the same goes for a Stunned Unit of yours on Auto; and a Unit Stunned after
  taking aim doesn't take its held shot.
- **One it found in the game:** where a pushed Unit lands, a Pierce's line
  and one line of sight in several thousand came out differently, because the
  game worked the geometry out in single precision. It now uses double
  precision, as JavaScript does, and they agree.
- **Dimensional Instability** takes its Elite or Mini-Boss from the floor's
  own District in both, and sends the ordinary Enemy when the District has
  none (Handbook 15.8).

With 0.8 and Companion 13.5:

- **`rules.js` changed a third time**, in both builds together: when a
  Status ticks (Handbook 15.9). The round has two halves, a Status remembers
  which it arrived in, and there are two ticks: the Recharge, and the end of
  your turn.
- **Four things the comparison found, fixed in the Companion:**
  - Its Auto battle went from the Enemies straight back to your Units and
    skipped everything between: no wave after the first ever arrived (a
    fight with more to come ran sixty empty rounds and was called a Draw),
    no Aether was generated, and no Status ever ticked. The game's Auto was
    right; the Companion's now plays whole rounds too.
  - With no Enemy left to act in the Enemy turn (a cleared wave with more to
    come), the simulator ended the round twice: hazards bit twice and a
    Hero's Energy was refilled twice.
  - A POI's final reward was chosen without counting what its last floor had
    just given, so it could be the same blueprint again.
  - Two Units of one name that held fire one after the other were one line
    in its Log.
- **In the last README, one line was wrong.** It said the Companion works
  Dimensional Instability out from the Districts your campaign has cleared.
  It doesn't: its simulator has you set Districts cleared by hand, as the
  game does, and its deployments have none.

With 0.9 and Companion 13.6:

- **One thing the comparison found, fixed in the Companion:** when a Troop
  fell in a deployment's fight, the Companion counted a copy lost of any
  design with its name, whether the team had taken it or not (a Troop put
  down by another card's Deploy, say), and kept counting once the last copy
  was gone, each with its line in the log, so a design could lose more copies
  than went out. Now a fallen Troop costs a copy only of a design the team
  took, and only while one is left, as the game had it.
- The Workshop's rules, its prices, the fit check and the keyword builder
  agreed in every case. The game's screens for them are its own.

With 0.10 and Companion 13.7:

- **The dock agreed in every case**: the Exchange and its prices, Reclaiming,
  the Bounty Board, the upgrades, and how a deployment ends at the dock.
  Nothing in the Companion needed fixing this time.

With 0.12 and Companion 13.9:

- **What a Ranged Action fires** is carried on a Unit's Actions by both
  rules.js and the game, and on a design's Troop card by both Workshops, and
  the comparisons include it. Nothing in the rules changed.

With 0.11 and Companion 13.8:

- **Nothing in the rules changed.** The look is the game's own, and every
  comparison agrees as before. A keyword in a sentence keeps the
  Companion's colour for it, so the two read alike.
- What `dock.js` does with tables that Dev Mode saved oddly (a price written
  as a list, a fraction of a shard) the game does too, so that the two agree
  even there.

## Updating to a new version

Unzip the new version and put its `KETER` folder over the old one, letting it
replace the old files.
Your exports stay where they are, and so do your Strike Teams, the
Behavior keywords you chose and your progress on the map. If you've changed anything in the editor,
send the project folder back (zipped, without the hidden `.godot` folder)
before updating, so the next version builds on your changes.

## What's inside

| Folder | What it holds |
| --- | --- |
| `scenes/` | `main.tscn`, the one scene |
| `fonts/` | Jersey 10 and VT323, the game's typefaces, and their licences |
| `art/` | 0.14: the pictures a fight is drawn with, in four sheets (`tokens.png`, `board.png`, `icons.png`, `cards.png`); 0.15: the World Map's and the menus', in four more (`ground.png`, `map.png`, `district.png`, `menu.png`); 0.16: the fight's effects, each a row of its frames, in `fx.png`; 0.17: each card's picture in `cardart.png`; 0.18: the atmosphere's motes, in `fx.png` with the effects; 0.19: the card back, in `cardback.png`; and `art.json`, saying where each sits and what it is (for an effect, its frames, speed and anchor) |
| `tools/art/` | The scripts that draw them (Python, numpy and Pillow), with a README. Godot ignores this folder |
| `scripts/` | **Screens:** `main.gd` (the board, touch, moving, attacking, previews, Bursts, Auto, the Enemies' turn, the round's phases, playing cards, loot, the Bank, and a deployment's fights), `home_screen.gd`, `dock_screen.gd` (the dock's tabs: the Stockpile, the Exchange, Reclaim, the Bounty Board and Upgrades; choosing who goes out, the Pack, and Field copy; QM-7 over them), `qm7.gd` (0.15: what QM-7 says), `workshop_screen.gd` (the Workshop's tabs: designs, blueprints and research, the export's designs), `design_editor.gd` (a design, being built), `builder_sheet.gd` (the keyword builder, on the screen), `map_screen.gd` (the World Map's bar and panel, walking, Caches, Events, coming home), `map_view.gd` (the map, drawn: 0.15's ground, borders, things, icons, the Hangar and the team), `teams_screen.gd` (your Strike Teams), `team_editor.gd` (building one), `setup_screen.gd` (setting up a fight), `hand_tray.gd` (the trays: your hand, Consumables, Chips, the Discard Pile), `card_sheet.gd` (a card read in full, and X chosen), `card_grid.gd` and `card_tile.gd` (cards as tiles), `card_face.gd` (0.14: a card as printed, at any size), `card_fan.gd` (your hand, as a fan), `aether_gems.gd` (Aether as gems), `look_board.gd` (the Look board), `unit_panel.gd` (the side panel, and 0.16's turn strip), `behavior_sheet.gd` (choosing a Unit's Behavior keywords), `log_panel.gd`, `dialog.gd`, `x_dialog.gd` and `name_dialog.gd` (boxes), `board.gd` (the floor and what stands on it, hazards, walls and blasts), `unit_view.gd` (a Unit, standing on its tile), `overlay.gd` (odds, dice and numbers over the board), `touch_list.gd` (a list for fingers), `ui.gd` (colours and shared pieces), `look.gd` (the typeface, its sizes and the theme), `pixel_box.gd` (the pixel frames), `art.gd` (the game's own pictures: icons, backdrops, the floor, 0.14's drawn art, 0.15's and 0.16's effects, and yours in their place), `backdrop.gd` (a screen's backdrop), `info_back.gd` (the bar behind a fight's bottom line), `motion.gd` (0.12: the speed, shake and sound settings, and the shots drawn over a fight; 0.16: and the fight's effects, frame by frame), `sound.gd` (the game's sounds, and yours), `options_box.gd` (Options). **The game itself:** `battle.gd` (a battle: Units, aiming, attacks, the Enemies' turns, Auto, waves, Dimensional Instability, Aether, the Deck, playing cards, Consumables, Chips, loot, the round, the log), `effects.gd` (what cards say, carried out), `keywords.gd` (the keyword library, which reads card text), `rules.gd` (the rules), `loot.gd` (the drop tables and their rolls), `world.gd` (the World Map), `chunk_gen.gd` (0.20: battlefields grown from chunks), `deployment.gd` (a deployment), `progress.gd` (blueprints and chassis), `dock.gd` (the Exchange, Reclaiming, the Bounty Board, the upgrades, and what the dock keeps for you), `workshop.gd` (designs, the fit check and what a copy costs), `scoring.gd` (what an ability is worth), `builder.gd` (the keyword builder's steps and taps), `skins.gd` (a design's look), `campaign.gd` (what is kept between sessions), `behaviors.gd` (the Behavior keywords you choose, and remembering them), `strike_teams.gd` (a team, its checks, and keeping it), `roster.gd` (cards, out of the export), `keter_export.gd` (reading the export), `floor_data.gd` (a floor and its hazards), `hex.gd` (hex maths) |
| `tests/` | The game's own tests, and a real export they read |

To run the tests (on a computer):

```
godot --headless --path . --script res://tests/run_tests.gd     # the game
godot --headless --path . --script res://tests/touch_path.gd    # touches, as a phone sends them
godot --headless --path . --script res://tests/soak.gd          # 120 battles of both kinds, played by a random hand
godot --headless --path . --script res://tests/soak_screen.gd   # 24 more, through the screen, tap by tap
godot --headless --path . --script res://tests/soak_world.gd    # 48 deployments, by a random hand
godot --headless --path . --script res://tests/soak_workshop.gd # 300 moves in the Workshop, by a random hand
godot --headless --path . --script res://tests/rules_tests.gd   # the rules suite
godot --headless --path . --script res://tests/rules_diff.gd    # rules.gd against rules.js
godot --headless --path . --script res://tests/sim_diff.gd      # the battle code against the Battle Simulator
godot --headless --path . --script res://tests/world_diff.gd    # the map, deployments and drops against the Companion's
godot --headless --path . --script res://tests/workshop_diff.gd # the Workshop and the keyword builder against the Companion's
godot --headless --path . --script res://tests/dock_diff.gd     # the dock against the Companion's
godot --headless --path . --script res://tests/chunk_diff.gd    # 0.20: grown battlefields against the Companion's
```

The last six need `tests/fixtures/rule_cases.json`, `sim_cases.json`,
`world_cases.json`, `workshop_cases.json`, `dock_cases.json` and
`chunk_cases.json`, which are generated by the Companion's
`make_rule_cases.js`, `make_sim_cases.js`, `make_world_cases.js`,
`make_workshop_cases.js`, `make_dock_cases.js` and `make_chunk_cases.js` (in
its sources) and aren't in this zip.
The tests keep their Strike Teams, their Behavior choices and their progress
in files of their own, and never touch yours.
