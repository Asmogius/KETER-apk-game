# POI Sandbox Guide

The POI Sandbox builds the floors you play on. You draw a hex map, mark what
matters, and print it at true size so the hexes on paper measure exactly what
the rules say they do.

Everything here describes the Sandbox as it works inside the KETER Companion.

## The top bar

On a phone the tool's header is a single strip: the level name on the left, then
**panel, undo, redo, help and more**. The panel button opens *and* closes the
panel from the same place, so you never have to scroll back up to shut it, and
the panel opens below the header rather than over it.

Pings and Tasks are not in the strip. They have their own docks at the bottom
right, which carry live counts so you can see what is outstanding without
opening either.

**Help** is the **?**. It opens the panel and its sections, then boxes every
control; tap one to read what it does, and **Done** at the bottom left to
finish.

Everything else — hex size, map radius, PDF layout, print scale and Export PDF —
lives behind the **more** button. Nothing is parked off the edge of the screen.

## Start here

Open **Sandbox**, tap the panel button in the top bar, and pick a Build
Tool. Drag on the map to place hexes. That's the whole loop — everything else
is refinement.

Two things worth knowing before you draw anything:

**Hex Size is a print setting, not a zoom setting.** It sets how large each hex
prints, measured across the flats. Pick 1 inch to match standard grid sheets,
4-per-inch for dense tactical rooms, 2 inch for a readable overview. Zooming on
screen changes nothing about the printed result.

**Map Radius is rings out from the centre.** Radius 8 means eight rings in every
direction, which is 17 tiles across. Growing the radius keeps your work.
Shrinking it discards anything outside the new hexagon, so grow freely and
shrink carefully.

## The build tools

| Tool | What it does |
| --- | --- |
| Place | Drops a plain hex |
| Highlight | Paints a colour into a hex |
| Wall / edge | Draws on a tile edge, not the tile |
| Erase | Removes a hex with its symbol and walls |
| Flood fill | Fills a connected area |
| Line | Draws a straight run |
| Select region | Marks an area for copy, cut or stamp |
| Range ruler | Measures distance in tiles |

Drag to apply any of them in a run. Right-click erases a hex under any tool.

**Highlight colours** are six fills plus a striped chip that clears a hex back
to plain. **Wall colours** are black plus six, so walls and doors read
differently on the same map — clicking an edge that already carries the selected
colour clears it, a different colour recolours it.

**The Range Ruler is the one people forget.** Drag between two hexes and it
reports the distance in tiles, which is exactly what you need to check Movement
Speed and Attack Range against a room before anyone plays it. It clears on
release and never prints.

## Shapes

The build tools decide **what** happens; the Shape row decides **how it is
applied**. Pick an action — Place, Highlight, Wall or Erase — then a shape, and
drag on the map.

**Free** applies the action tile by tile as you drag. **Line** runs from where
you press to where you release. **Hex**, **Rect** and **Circle** drag out from
the centre, and the **Fill / Outline** toggle decides whether the interior is
included or only the perimeter.

Both selections stay lit, and the hint under the row reads back what the pair
will do — "Highlight in a hex", "Erase in a line".

Circle uses true distance rather than hex distance, so it comes out round. Hex
distance would give you a hexagon, which is what the Hex shape is for.

## Mirror

**◑** turns mirroring on and off. Tap it, then tap a tile to set the **pivot**.
From then on every change you make — tiles, colours, walls, symbols, whole
stencils — is applied to both sides of the line.

**⥁** swings the mirror line through its three angles. It appears only once
there is an axis to swing.

**⬡** changes the symmetry: one line, a **cross** for four-way, or **six
slices**. Six is the hexagon sliced point to point, and it is what two mirror
planes 60 degrees apart naturally produce — a third plane adds nothing, because
the first two already imply it.

Every active plane is drawn as a dashed line, so what you see is what you get. A
tile sitting *on* a line is its own reflection and is changed once, not twice —
which is correct, though it can look as though the mirror missed.

Turning mirror off clears the pivot and the symmetry, so switching it back on
always starts from a deliberate choice. Mirror settings are a working aid: they
are never saved into a level, and never print.

## Zoom

The slider and the percentage box beside it both set the on-screen zoom, from
20% to 300%. Type a number into the box and press Enter; anything outside the
range is clamped, and the box then shows the value you actually got rather than
the one you typed.

**Zoom is a screen setting only.** Printed size is decided by Hex Size, and
nothing you do here changes it.

## Symbols

Type up to three characters in the Symbol Builder and add it. Each becomes a
toggle — arm one, then tap tiles to stamp it. Tap a stamped tile again to clear
it. Up to twenty symbols per level.

Beside each symbol is a description field. Fill it in. It prints on the legend
page, and a printed stack of floors with no descriptions is a stack of floors
nobody can run.

**Reset to KETER Defaults** loads the standard set from the POI rules — green
player spawns, red enemy spawns, yellow loot, orange and violet cover, blue
healing stations, the four wall meanings, and symbols for Hive, Key, Locked
Chest, Captive Survivor and Emergency Exit. It overwrites edits you've made, so
use it on a new level rather than a finished one.

## The pictogram library

Fifty drawn pictograms in five groups — Places, Loot, Hazards, Objects and
Marks — plus anything you import. The list scrolls; the title and buttons stay
put.

**Everything in the library is drawn.** The unicode characters that used to sit
below the pictograms are gone: they depended on the device's fonts, the PDF
export could not print them at all, and they meant nothing to anyone you shared
a floor with. What you see now looks the same on screen, in a PNG, on paper and
on someone else's phone.

## Importing your own symbols

**Import an image…** at the top of the pictogram library takes any image and
reduces it to a 48×48 **monochrome stencil**.

That reduction is deliberate rather than a limitation. A stencil prints — the
PDF has no image support, so a colour picture could only ever appear on screen,
the way unicode symbols do. A stencil is also about half a kilobyte, so it
travels with a floor you share rather than making the floor too big to send.

The **Threshold** slider decides which parts of the picture become solid. Line
art works at almost any setting; photographs need finding. **Invert** flips it,
which is what you want for a light shape on a dark background. The preview
updates as you drag, so set it by eye.

Give it a name and it joins the library beside the drawn pictograms, usable
anywhere they are. The **×** on an imported symbol removes it — the app will
refuse if that symbol is currently on your floor.

Imported symbols are kept on this device.

## Making room for the map

The **floor readout** at the bottom can be dragged by its top edge to any height,
or tapped to fold away entirely. Whatever it gives up, the map takes. Your choice
is remembered.

The tool row above the map scrolls sideways rather than wrapping onto three
lines, which returns about a quarter of the screen to the floor you are drawing.

## Filing a floor

Floor Info, Floor Notes and Rewards all print on the legend page. This is what
turns a stack of printed maps into something you can sort without writing on the
backs.

- **Floor Info** — name, District, POI type, level, floor size
- **Floor Notes** — objective, enemy waves, spawn timing, boss behaviour
- **Rewards** — loot tiers, guaranteed drops, Prototypes, whatever a Mini-Boss
  leaves behind

The **Task Checklist** dock counts down what a floor still needs: a name, filing
details, player and enemy spawns, an exit, and notes for whoever runs it. It
reads *Floor ready* at zero.

## Pings

The **Pings** dock is everything the tool has flagged. Red is a rule the floor
breaks or something unplayable. Amber is a consequence worth knowing about. Grey
is advisory. The badge takes the colour of the worst active item.

Nothing here ever blocks you. A red ping on a deliberate outlier is fine — the
point is that you decided, rather than not noticing.

## Generating a floor

The **Room Generator** builds a playable floor from your rules: footprint, walls
and doors, cover, spawns, features, then a reachability check to confirm the map
is actually traversable. It works inside your selection if you have one,
otherwise it fills the whole hexagon.

Density presets come from the Skull Level and are then yours to adjust. Cover is
a share of open tiles; spawns, loot and features are counts. Changing the Skull
Level resets them back to its preset, so set the level first and tune second.

Every generated result is a single undo step.

## Reusing work

**Select region**, then Copy or Cut, lifts hexes with their colours, symbols and
interior walls. Paste arms a ghost preview — tap to drop it. Rotate turns the
clipboard 60 degrees, Mirror flips it.

The **Stamp Library** saves a selection as a named stamp. Stamps are shared
across every level on this device *and* travel inside downloaded map files, so
sending someone a level sends them your library too.

## Printing

This is where floors go wrong, so it's worth being exact.

**Print Scale must be True Size** for anything you play on. Fit 1/2/4 shrinks
the map to that many pages, and Custom dials a percentage. Anything below 100%
gets stamped on the sheet header as a warning — that stamp is there so nobody
plays on a sheet where the hexes lie about their size.

**PDF Layout** is Tiled or Single. Tiled splits the map across 8.5×11 sheets
with crop marks and sheet labels. Single prints the whole map on one oversized
page, which is for a print shop, not a home printer.

**Ink Saver** strips colour fills to hairline outlines with a short code in each
tile — ES for Enemy Spawn, HC for Half Cover. It applies on screen, in PNG
exports and in the PDF, so a draft print costs almost no ink. Walls stay solid
black because they carry the room's structure.

Export PDF also appends a legend page with your symbols, tile colours, wall
colours, floor info and notes.

**On a phone:** large PDF exports can exhaust memory and kill the tab. A big
tiled map at 600dpi is exactly that kind of job. Build on your phone freely, but
do large print runs on a desktop.

## Sheet budgeting

The **Floor Readout** along the bottom gives you live figures: open tiles,
printed extent, how many sheets the floor takes at true size, and how much of
the map is reachable.

Floors follow a budget of **6 + Skull Level** sheets, counting Small as 1 sheet,
Medium as 2 and Large as 4. The readout is how you keep a floor inside it before
you've printed anything.

## The tile manifest

The Tile Manifest lists every symbol and highlighted tile with its A1
coordinate, grouped so it reads straight onto a POI card — `ES ×6: C4, C7, D9`.

Text is for card notes, CSV opens in a spreadsheet, Markdown drops into the
Handbook. Coordinates work whether or not you have labels switched on, though
turning **Coordinate Labels** on makes them print, so a POI card can reference
exact tiles.

## Saving and sharing

**Save** overwrites the current level; **Save As** names a new one. A level
carries its map, walls, symbols, legend descriptions, floor info and notes.

**Download** writes a `.keter.json` you can text or email to another player.

**POI Projects** groups floors into a POI folder — name, District, type, Skull
level, and an ordered list of floors. Adding the current level copies it in, so
later edits to the level don't disturb the stored floor unless you update it.
The project view tracks the sheet budget across all its floors.

Everything saves on this device. Export a backup from Home
after any session worth keeping.

## Spawn levels

Every Enemy Spawn tile carries its own **Skull Level**, 1 to 6, and each wave
draws an Enemy of that level onto it. Pick the **Spawn level** tool and tap a
spawn tile to raise it a step; 6 goes back to 1. Each tile shows its number, and
prints with it. With mirroring on, the reflections take the same level.

Only Enemy Spawn tiles have one. Tapping anything else says so rather than
changing it, except on a World Map level.

## World Map levels (the video game)

A level whose POI Type is **World Map** is the video game's world map, not a
floor, so the Battle Simulator never offers it as a floor to fight on. The World
Map page writes one when Dev Mode's **Edit in the Sandbox** is tapped, named
"World Map".

- **Districts are colours**, read by their labels ("District 3 · Vantage
  Robotics"). An uncoloured tile belongs to no District.
- **A blocked tile is an erased one.**
- **Symbols are contents**: **DK** the dock, **PO** a POI, **AM** an Ambush,
  **CA** a Cache, **EV** an Event.
- **The Spawn level tool sets any tile's Skull Level**, overriding the one its
  ring gives: tap to go 1 to 6, and a seventh tap clears it.

Save it, then use it from the World Map page (Dev Mode). The World Map Guide has
the rest.

## Battlefield size

A Floor's size decides how many Heroes enter a Combat on it — 1 on Small, 2 on
Medium, 3 on Large. Left on **Auto**, a floor takes the size its tile count
suggests, under 100 tiles for Small and over 250 for Large, and follows it as the
floor grows. Choosing a size by hand overrides that.

The Sandbox warns when a floor has fewer Player Spawn tiles than the Heroes it
admits, since every Hero needs one to start on.

## Battlefield chunks (the video game)

A level whose POI Type is **Chunk** is not a floor of its own. It is a piece of
one: a hexagon of 37 tiles (radius 3) that the video game and the World Map
join to others to grow a POI's battlefield. The Battle Simulator never offers a
chunk as a floor to fight on.

Choosing **Chunk** under POI Type opens the **Chunk** panel:

- **Role** says where it goes in a battlefield. A **Start** chunk holds your
  spawns and is always placed first. **Enemy** chunks hold theirs and go
  furthest from the start. **Loot** goes behind the Enemies, an **Exit** at the
  far end of a large one, and **Filler** between.
- **Open sides.** Each of the six sides (N, NE, SE, S, SW, NW) is open or
  walled. An open side joins only an open side of the chunk beside it; where
  either side is walled, a wall runs the length of the join.
- **Skull from / to** sets the Skull Levels it is used at.
- **Lay out a chunk** fills the radius-3 hexagon with deck to draw on.
- **Preview a battlefield** grows one from your saved chunks of the same
  District (and this one, as it stands), Small, Medium or Large. **Grow
  another** tries a new seed.

The District and the Spawn Level of its Enemy Spawn tiles come from where the
chunk is used: a grown battlefield sets every enemy pad to its Skull Level.
Small is 3 chunks, Medium 5, Large 7. Each chunk may be turned and mirrored,
so one chunk can sit twelve ways.

The app comes with 20 chunks for District 3 (Vantage Robotics): 4 Start, 6
Enemy, 3 Loot, an Exit and 6 Fillers. Four of them (v14.9) are gaps and
gantries, where a Unit with Leap goes the short way: Gantry Landing, Skitter
Nest, Gantry Crossing and Catwalk Run. It adds any that are missing to the floor
library and never overwrites one you have edited.

## Floor reward (the video game)

Under Rewards, **Floor reward** sets what the floor gives in the video game when
it is cleared, on top of what its Enemies drop:

- **Shards** — an exact amount of Aether shards
- **+ Exact components** — a number of one kind, such as 2 Rare Troop parts
- **+ Rolled components** — a number rolled at the floor's Skull Level, of any
  type or one type, optionally **rarer by** a Skull Level or more
- **+ Blueprint or chassis** (Dev Mode) — one blueprint level or chassis, given
  by its chance, 0 to 100%, if the player can use it. Outside Dev Mode such a
  line shows but cannot be changed, so a player never sees the whole list

It is kept with the floor, and the Battle Simulator gives it when the floor is
won. The line under it sums the reward up in words. The Rewards box above stays
the board game's.

A **Locked Chest** symbol (text LC, or LC3 for a chest of three) is opened in
the Battle Simulator by a friendly Unit moving onto it.

## Hazard tiles

A hazard is not a new kind of tile. It is a **symbol that does something**, so
placing, mirroring, stamping and undoing all work exactly as they already do.

Arm a symbol, then press **Hazard settings**. Give it a flat damage value, an
effect from the same keyword list the cards use, or both. The symbol turns red
in the library once it carries one.

A Unit entering that tile, or ending its turn on it, takes what you set. It is
terrain, so:

- it applies to **both sides**, not just the Enemies
- its damage is **not stopped by Armor Class**, because nothing is aiming it
- it fires **on entering and on remaining**, so standing in fire is worse than
  passing through it

The Battle Simulator reads hazards straight out of the saved floor. It hatches
those tiles in red, and Units walk around them when there is a way around and
through them when there is not — so a corridor of fire still gets crossed
rather than leaving a Unit stranded at the edge of it.
