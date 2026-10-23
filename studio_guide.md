# Pixel Studio

Draw **card art** and **board tokens** in the KETER palette. Everything saves
itself as you draw.

## Getting in

- **From a card**: in the Forge, under the card's name, tap **Draw art** or
  **Draw token**. Card art is **128 or 64 pixels across** — 128 is the default.
  It begins as a square and the bottom is trimmed off, so the canvas is exactly
  the shape of that card's art box as it is now. Once a card has art, its art
  box keeps that shape and the text adjusts around it, so a later edit never
  crops the picture. **Back** returns you to the Forge.
- **On the card** the picture fills the art box exactly once each pixel is four
  or more dots across, as in print (128 across prints at about 5 dots a pixel),
  since a one-dot difference between columns cannot be seen there. Smaller than
  that it is drawn at a whole number of dots per pixel, so every pixel is the
  same size. Where the card is shown smaller than the picture — in your hand —
  it is averaged down, so fine detail blends rather than disappearing.
- **From Home**: the Pixel Studio tile opens on three tabs: **Library**,
  **Skins** and **Assets**. On Library, start **Art for a card** (type part of
  a card's name to find it) or a **New token**, which asks for its size: 16, 24,
  32 or 48 pixels. The game draws every Unit at 48 (since game 0.14), so that
  is the size to draw a new one at; a smaller one is drawn at twice or three
  times its pixels.

## Blank canvases

**Blank canvas** on the studio's home is for any graphic, not tied to a card:
icons, tiles, sprites, loading screens, illustrations. Choose square pixels
(16×16 to **256×256**, or 64×32, 128×64 and **256×144**, the shape of a wide
screen) or type your own width and height, up to 256 each way; or hex pixels as a
rectangle, columns by rows (up to 128 each way — hex pixels are several times
slower to draw), or a hexagon of 6 to 48 per side. They appear in the library as
graphics.

A 256×256 picture takes a real share of the space your browser gives the app,
so the library's heading says how much the pictures, and the whole app, are
using, out of about 5 MB.

## From an image

**From an image** on the studio's home turns any picture file — a photo, a
render, concept art — into palette pixels. It shows the result as you change:

- **Pixels across** — 32, 64, 128 or 256; the height follows the image's shape
  (never more than 256).
- **How many colours** — all, or at most 64, 32, 16 or 8. The image is snapped
  to the palette, then the colours whose loss costs least are merged away — a
  shade between two others goes first, a small bright accent far from
  everything else stays.
- **Colours from** — the whole palette, without the neons, Splendor 128 only,
  Splendor with KETER 56, your own colours only, or one of your swatch groups.
- **Dither** — off, soft or full (spreading each pixel's error to its
  neighbours) or pattern (an even ordered pattern).
- **Clear the background** — removes the colour around the edge, and whatever
  joins it that is close to it: a character on white comes out on transparent.
- **Brightness**, **Contrast** and **Saturation**, applied before the colours
  are chosen. **Show the original** compares.

**Create the picture** puts it in the library on a layer called *Converted*, as
a graphic named after the file. The image comes too, as the drawing's
reference, hidden until you show it.

**An image onto a new layer…** in the menu (⋯) does the same inside the picture
you are drawing — card art, a token, hex pixels too — at that picture's size:
**Fit the whole image** (margins stay empty where the shapes differ) or **Fill
the canvas** (the edges are cropped). It lands on a new layer above the one you
are on, and Undo takes it away.

## Double the pixels

**Double the pixels** in the menu (⋯) turns every pixel into a 2×2 block, in
every layer: 64-across card art becomes 128 across, and a blank canvas up to
256. The picture looks the same; the room is for finer detail. Undo takes it
back.

## Drawing

- **Pencil**, **Eraser**, **Fill** (fills the area of one colour you tap), and
  **Pick colour** (takes a colour off the picture, then returns to the pencil).
- **Brush size** — 1, 2, 3, 4, 6 or 8 pixels, **square** or **round**, for the
  pencil, the eraser, the dither brush and the line's width. Always whole
  pixels, never soft. In Cursor mode the outline shows every pixel the brush
  will paint.
- **A long press** anywhere picks the colour under your finger, whatever tool
  you are using.
- **Mirror** cycles left–right, top–bottom, both, and off; what you draw is
  copied across the orange axis.
- **Direct** draws under your finger. Tap it for **Cursor**: the pixel is placed
  just above your finger, with a crosshair, so your fingertip never hides it.
- **Undo** and **Redo** at the top, one stroke at a time.
- **Pinch** to zoom and pan with two fingers; **−**, **+** and **Fit** do the
  same. Zoom is always in whole steps so pixels stay square. A grid appears once
  you are close enough to use it.

## Shapes

- **Line** — drag from one end to the other; it follows your finger until you
  let go.
- **Rectangle** and **Circle** — drag across the area. Choose **Outline** or
  **Filled** in the row under the tools.

Mirror and symmetry apply to shapes as they do to the pencil.

## Dither

The **Dither** brush paints a pattern as you drag:

- **Two colours** alternates your current colour with a second one. Tap the
  second swatch beside the current colour, then pick from the palette.
- **Over what's there** paints only the pattern's pixels and leaves the rest as
  it was.

On square pixels choose the pattern: **25%**, **50%** (a checkerboard) or
**75%** coverage, spread evenly, or **Hatch**, diagonal lines. The pattern
belongs to the canvas, not the stroke, so strokes laid side by side line up.

**Gradient** fades one colour into another: drag across an area and it goes
from the second colour (or what is there, with *Over what's there*) where you
start to your colour where you stop, in an even ordered pattern. It fills the
joined pixels you start on, as Fill would — so fill a shape first, then
gradient it.

Hex pixels have no checkerboard, so they offer **⅓**, **½ rows** and **⅔**.

## Selecting

With **Select**, choose how it picks:

- **Box** — drag across the picture.
- **Joined colour** — tap a pixel; its colour, where it touches, is selected.
- **Colour on layer** — tap a pixel; every pixel of that colour on the layer.
- **All** — everything on the layer.

Drag inside the selection to move it — it moves by whole pixels, so it lands on
the grid unchanged. The **arrows** nudge it exactly one pixel; with nothing
selected, they move the whole layer. On a keyboard, the arrow keys do the
same. Then: **Flip ↔**, **Flip ↕**, **Turn ↻** (a quarter-turn, square pixels
only), **Copy**, **Paste**, **Delete**, and **Done** to set it down.

**Scaling** (square pixels): **×2** makes every pixel a 2×2 block, **½** halves
it, and **Scale %** takes any percentage from 10 to 800. Enlarging repeats
pixels; shrinking gives each new pixel the colour most of its block had, or
leaves it empty if most of it was. The selection keeps its centre.

## Text

**Text** (square pixels) types in two pixel fonts: **Small 3×5** and **Large
5×7**, with **Tight**, **Normal** or **Wide** spacing. Letters are capitals;
numbers and . , ! ? : ; - + = / ' " ( ) % * # & are there too, and two lines
are each centred. **Place** puts the text down in your colour as a selection,
in the middle of the picture: drag or nudge it into place, scale it if you
like, then **Done**.

## Layers

**Layers** under the palette opens the layer panel. **+ Layer** adds one above
the current layer, which is the one you draw on. Tap a layer to draw on it. Each
layer can be shown or hidden, locked, moved up or down, renamed, duplicated or
deleted, and has its own **opacity** and **mode**:

- **View** — opacity only fades it while you work; it saves whole.
- **Snap** — really blended, each result snapped to the nearest palette colour.
- **Dither** — translucency saved as a pattern of the layer's own pixels.

The layer you are on also offers:

- **Alpha lock** — paint only where the layer already has pixels, so you can
  shade or recolour a shape without going over its edge. Nothing on it can be
  erased while it is on. An α beside the name shows it.
- **Solo** — see this layer alone while you work on it. It changes only the
  view; the picture still has every layer.
- **Merge down** — fold this layer into the one below, keeping how its opacity
  mode would save it.

Every change to the layers can be undone, including deleting one.

## Frames

Since 14.3 a picture can have several **frames**, played one after another: the
game's fight effects are drawn this way. **Frames** under the canvas opens the
strip (a picture with more than one frame opens with it showing). Each frame
has its own layers.

- **Tap a frame** in the strip to draw on it. The one you are on is outlined.
- **+ Frame** adds a blank frame after it, with the same layers, named and set
  the same, empty. **Copy frame** adds a copy of it, to change a little.
- **Earlier** and **Later** move the frame along the strip; **Delete frame**
  takes it out (a picture always keeps one).
- **Onion skin** shows the frame before, faintly, under the one you are
  drawing on, so each frame can follow from the last. It is only a view.
- **Play** runs the frames in turn on the canvas, over and over, at the
  **speed** set beside it, in frames a second; a tap on the canvas or **Stop**
  ends it. The speed is saved with the picture, and the game plays it so.

Every frame change can be undone. Everywhere a picture is shown as one (the
library, a card, the board), it shows its first frame. **Export as PNG**
writes a picture of several frames as one image with its frames side by side,
first to last, and Export for Godot carries them so. (A picture in hex pixels
can have frames to draw and play, but goes out as its first frame.)

## Colour

Your current colour and the ones you have used recently sit under the tools.

**Ramp** shows, around your current colour, the nearest darker and lighter
palette colours of a like hue, in order — the steps to shade with. Tap one to
use it; the ramp follows.

**All colours** opens the full palette in a panel that scrolls on its own:

- **In this picture** — the colours the picture already uses, most used first.
- **Your swatch groups** — named sets you keep for every picture: Gunmetal,
  Rust, Bone, Verdant. **New group from this picture** saves the picture's
  colours; **New empty group** starts with your current colour. On a group,
  **+** adds the current colour, **−** takes it out, **✕** deletes the group.
- **Splendor 128**, then the eleven neons, then **KETER 56**, then **My
  colours**.

The palette holds **255 colours** — as many as one byte a pixel allows, with
transparent as the 256th:

- **Splendor 128** by Adigun A. Polack.
- **Neon 11** — the glow Splendor leaves soft.
- **KETER 56** — grime greys, drab greens, dusk violets, steel blue, Mars
  dust, rust and oil, skin, bone, blood and toxic, each chosen to sit clear of
  every colour already there.
- **My colours** — up to 60 of your own.

To find your way through them, the top of the open palette has:

- **Which colours** — all, one set, this picture's, or your swatch groups.
- **Order** — palette order, **by hue**, or **light to dark**.
- **Value** — any, or only the **dark**, **mid** or **light** ones.
- **Family chips** — Reds, Oranges, Earth (browns, skin, bone), Yellows,
  Greens, Teals, Blues, Purples, Pinks, Greys.

Your current colour's hex code and name are shown at the end of the ramp (on a
computer, hovering over any swatch shows its own). How you like the palette
shown is remembered on this device.

**Adding your own colour**: choose one with the colour picker or type it as a
hex code (#7a3b2e), then **Add**. A colour the palette already has is simply
chosen. **From the reference** takes a colour from the reference picture: tap
the picture where the reference has it, then **Use nearest** (the closest
palette colour) or **Add as my colour**. **Remove the current colour** takes
one of yours out — not while this picture uses it.

Your colours are kept on this device, and **every picture that uses one carries
a copy**, so it looks the same on a card, in the Forge, in a PDF or on another
device. Opening such a picture in the Studio brings its colours back into your
palette; if a slot there already holds a different colour, the picture's
pixels move to a free slot, and the status line says so.

The number of colours a picture uses is shown at the top.

## Reference

**Reference** opens a panel for a picture to draw from — a photo, a sketch,
concept art. **Load a reference picture** takes one from your device; it is
fitted to the canvas at half opacity. Then:

- **Hide / Show** it, and put it **Under the art** (it shows through empty
  pixels) or **Over the art** (a tint over everything, for checking shapes).
- **Move** — drag it into place; your pixels are not touched while it is on.
  **Fit** puts it back. **Opacity** and **Size** sliders.
- **Replace** or **Remove** it.

It is kept with the drawing, on this device, scaled down to 1024 pixels on its
longest side, and stored apart from the picture library so it does not use that
space. It is **never exported**, never printed, and never counted among the
picture's colours.

## The menu (⋯)

- **Export as PNG** — an image file for screens and other software, at 1×, 2×,
  4×, 8× or 16× (each pixel becomes a block that many pixels across).
  Transparency is kept, and every pixel is exactly a palette colour. A picture
  of several frames comes out with its frames side by side.

- **Preview** shows card art on the real card, or a token on board hexes at
  three sizes.
- **Export as PDF** gives one letter page for printing. A blank canvas prints
  at the width you choose; card art and tokens print at their true size — card art 2.27 inches wide, as on the card; a token at the size it fills
  on a 1.25-inch board tile, inside the tile's outline to cut along. Pixels are
  drawn as vector shapes, so they print crisp at any resolution.
- **Show / hide grid**, **Double the pixels** (above), and **Clear the
  picture** (which Undo can bring back).
- **View** — **Colour**; **Value**, every colour as its lightness in grey, to
  check contrast; or **Silhouette**, every pixel dark on a light ground, to
  check the shape reads. A tag on the canvas says which view is on; tap it to go
  back to colour. The view never changes the picture.
- **Show at 1× and 2×** — a small preview in the corner of the canvas at one and
  two screen points a pixel, updated as you draw. It stays on for the next
  picture until you hide it.
- **An image onto a new layer…** (above).

## The library

Every picture is kept in the library. **Copy** makes a separate picture you
can change without touching the original; **Delete** removes one (cards using
it lose their art).

## Skins

A **skin** is a card art and a board token that go together, in one or more
**colour variants**. You draw every skin in Dev Mode; players only choose, and
every skin is free. The **Skins** tab lists them all in three groups:

| Group | Who wears them | Where the choice is made |
| --- | --- | --- |
| **Body plans** | Troop designs, pre-built Troops included, of that body plan | The design's **Look**, in the Workshop |
| **Heroes** | That Hero, everywhere | The Hero's card, in the Compendium |
| **Enemies** | That Enemy | Nobody: each one that spawns wears a random look |

- **The stand-ins.** Each of the five body plans (Bipedal, Quadcopter,
  Quadruped, Hexapod, Octopod) comes with a plain stand-in skin, so no design
  goes without a look. Redraw it, or add skins of your own. **Bring back the
  stand-ins** restores any you delete.
- **A Hero** wears its card's own art until a skin is chosen for it.
- **An Enemy** wears a random look each time it spawns: its card's own token or
  one of its skins' variants.

In Dev Mode, **Edit** on a skin opens it:

- **Draw art** and **Draw token** open a blank picture sized for a skin, or the
  one it has. **Art from an image** and **Token from an image** do the same,
  then put a picture file on it through **From an image**.
- **New skins** at the top sets their size: art 128 or 64 across (shaped like a
  Troop's art box), and a token 48 by 48 (the game's size for a Unit, and the
  default), of hex pixels (9 per side), or 32, 24 or 16 square.
- **Roles**: a body-plan skin can be tagged Melee, Ranged, Support or Cyber.
  Designs with those roles are offered it first. Any design of the body plan
  can still wear it.
- **Make a variant** copies a variant's art and token and opens the
  **recolour tool**. Tap a colour it uses, then the colour to put in its place;
  the preview shows the result. **Apply** changes every layer of the variant's
  art and token together, never the original. Open its art or token afterwards
  to touch it up.
- **Move up** sets the order skins are offered in. **Delete** removes a skin;
  anything wearing it goes back to the first drawn skin on offer.

A design with no skin chosen wears the first drawn skin on offer to it: one
that suits its roles if there is one. A skin not yet drawn is never the
default.

Players see this tab too, but can't change anything on it.

## Assets

The **Assets** tab lists every graphic the game uses, drawn or still missing,
with a count for each group:

- **Skins**: every variant's art and token.
- **Cards**: every card's art, and a Unit's token. **Find a card** narrows the
  list. Every master Unit comes with the game's own token (see *The game's own
  art*, below).
- **World Map**: ground for each District and for tiles in no District, and
  collapsed tiles, drawn in hex pixels, a hexagon 9 per side filling a map
  tile; each holds several pictures, scattered at random. Since 14.2 (game
  0.15), in square pixels drawn at twice their size: each District's
  **things**, 32 by 32, several to a District, one standing on one empty tile
  in five, its foot near the bottom; the **icons** for a POI, a Unique POI, an
  Ambush, a Cache and an Event, 16 by 16, each set on a plate in its colour;
  and **the Hangar**, 64 by 64, standing on the dock's tile. An icon drawn in
  hex pixels before 14.2 still works: the game lays it over its tile.
- **Game look**: the pictures the game draws for itself, which yours can
  replace. **Title**, **Dock backdrop** and **Menu backdrop** are 256 by 144:
  the game fills its screen with one at five times that, every pixel square.
  A Title replaces Home's picture and its name, so draw the name in if you
  want it. **Fight floor** is 64 by 64 and repeats under a fight's board,
  darkened. And ten **icons**, 16 by 16, shown at twice that: Aether shards,
  Troop parts, Equipment parts, Aether parts, Health (HP), Armour (AC),
  Movement (MS), Energy (NRG), Aether and Skull Level. Leave an icon's edge
  clear, so it doesn't run into what's beside it. A slot left empty stays
  the game's own. Since 14.1, a fight's icons as well: each **Status's icon**
  (16 by 16, beside it in a Unit's side panel) and its **mark** (8 by 8, by the
  Unit's head on the board), the **Aether gems** (8 by 8, one for each
  District and one for Aether of any kind: on a fight's Aether button and in a
  card's cost), the icons of the fight bar's **Undo, Auto, Log, Fit and
  Leave** buttons, the four **role icons** (before each Action in the side
  panel), and a **card picture** (64 by 45) for each kind of card that has no
  art of its own, shown in its art window. Since 14.2, the menus' too:
  **QM-7**, the dock's keeper, 64 by 64, and **QM-7, blinking**, shown for a
  moment now and then; **Victory** and **Defeat**, over a fight's result; the
  **Options icon** (the gear on Home); and each **District's emblem**, by a
  tile's name on the World Map and by a floor in a fight's setup. Since 14.3,
  the side panel's **turn strip**: the **Move** and **Attack** icons, and
  **End turn**'s, beside its words; Hold fire wears the **Holding fire** icon.
- **The fight** (14.1): a fight as the game draws it, in square pixels drawn
  at twice their size. The five **deck plates** a tile can wear, 42 by 48 (one
  tile); **your** and the **Enemies' spawn pads**; the five **hazards** (acid
  for one that Poisons, sparks for Stuns and Drains, razor wire for Bleeds and
  Sunders, sludge for Slows, Roots and Pins, fire for any other); two pictures
  each of **Half Cover** and **Full Cover**, which stand at the front of their
  tile so a Unit on it is seen behind them; the **loot crate**, the **Locked
  Chest**, the **Emergency Exit** (a hatch a Unit stands over) and the
  **Healing Station**; and the four **stand-ins**, 48 by 48, that a Unit with
  no token of its own stands in as: melee, ranged, drone or beast.
- **District fights** (14.2): each District's own fights, in square pixels
  drawn at twice their size. Five **floor plates**, 42 by 48, every tile of a
  fight in that District wearing one (the first most often, the last seldom),
  and its own **Half Cover** and **Full Cover**, 48 by 48. Hazards, spawn
  pads, crates, chests, Exits and Healing Stations are the same everywhere
  (under **The fight**), and a floor in no District keeps the grey deck.
- **Effects** (14.3): the fight's effects, each drawn frame by frame (see
  *Frames*, above) and played at its speed, in square pixels drawn at twice
  their size: the **muzzle flash** (24 by 24, 4 frames) at a shooter as a shot
  leaves; the **impact** (32 by 32, 5 frames) where damage lands; the
  **explosion** (48 by 48, 8 frames) on every tile a blast catches and where a
  shell comes down, sitting a little low so the fire rises; the **heal** (32 by
  48, 6 frames) rising from whoever is mended, its foot at the Unit's feet; and
  the **shield** (48 by 48, 6 frames) that flares round a Unit when an attack
  glances off its armour. Each row says how many frames it has and how fast it
  plays. Yours can have more frames or fewer, and its own speed; one of a
  different size sits as the game's does for its size, and one of a single
  frame stays up as long as the game's would play.
- **Your slots**: graphics the app doesn't use yet, such as a loading screen, a
  logo or UI icons. **Add a slot** names one and sets its size: square pixels
  up to 256 each way, or a hexagon of hex pixels.

**Missing only** hides what's drawn. In Dev Mode every row has **Draw** (or
**Draw another**) and **From an image**, already sized for its slot. Players
see the list but can't draw on it.

### The game's own art

Since 14.1 the Companion carries the game's own pictures, drawn for game 0.14:
a token for every master Unit, 48 by 48; the five body plans' stand-in tokens
(the stand-in skins wear them); and a picture in each slot of **The fight** and
of the fight's icons under **Game look**. Since 14.2, game 0.15's as well: the
World Map's ground, rubble, things, icons and Hangar, every slot of **District
fights**, Home's picture and the two backdrops, QM-7, Victory and Defeat, the
gear and the District emblems. Since 14.3, game 0.16's: the five **Effects**,
each with its frames and speed, and the **Move**, **Attack** and **End turn**
icons (and the **Holding fire** eye, redrawn). Since 14.4, game 0.17's: a
picture for every card that is not a Unit (Aether, Equipment, Chips, Actions,
Commands, Consumables, Prototypes), 128 by 90, the thing itself on its
District's backdrop, as that card's art. Since 14.5, game 0.18's: the four
motes of the fight's atmosphere (Ember, Spark, Ash and Dust) under **Effects**.
Since 14.6, game 0.19's card back, under **Game look**.
A slot that holds several pictures is given all of the game's. They join the picture library when the app starts, so the
Card Forge, the Battle Simulator, the World Map and the Pixel Studio show them.

- **Open one to draw over it.** The game uses yours in its place, through
  Export for Godot. One you have drawn on is yours from then on: a later
  release never replaces it.
- **One nobody has drawn on is refreshed** when a release redraws it, and stays
  out of Export for Godot: the game has its own copy, so a newer game shows
  its newer picture. In a slot of several (ground, rubble, a District's
  things), once one is yours the export carries the whole slot, the game's
  own with it, and the game uses that slot's pictures together.
- **A master Unit is given its token only if it has none**, a card that is
  not a Unit its art only if it has none, and a slot its picture only while
  the slot is empty, each once. A token you take off a card,
  or a picture you take out of its slot, stays off.

### Export for Godot

**Export for Godot** downloads one zip, `KETER_export_<date>.zip`, holding
everything the game reads:

- **A PNG of every drawn graphic**, in folders by kind: `skins/`, `cards/`,
  `map/ground/`, `map/icons/` (the Hangar with them), `map/things/`,
  `map/collapsed/`, `ui/` (the Game look: its icons in `ui/icons/`, the Status
  icons in `ui/status/`, their marks and the Aether gems in `ui/marks/`, the
  card pictures in `ui/cards/`), `fight/` (The fight, its stand-ins in
  `fight/standins/`, District fights in `fight/districts/`, Effects in
  `fight/effects/`) and `custom/`. The game's own pictures go only once you
  have drawn on them.
- **A picture of several frames** is one PNG with its frames side by side,
  first to last; the manifest says how many frames and how many a second.
- **Square pictures at their true size.** Hex pictures have no pixel grid, so
  they're drawn 4 pixels to a hex's half-width, about 7 pixels across each
  hex.
- **The content**, in `content/`, one file per kind, each saying its format:

  | File | What it holds |
  | --- | --- |
  | `cards.json` | Every card: master, test, your own, designs and pre-built Troops |
  | `floors.json` | Every floor saved in the Sandbox |
  | `world_map.json` | The World Map, its tables, Events and Unique POIs |
  | `chassis.json` | Every chassis |
  | `pools.json` | Each District's pool of blueprints and chassis |
  | `tables.json` | The Loot, Workshop, World Map and Dock tables |
  | `skins.json` | Every skin and its variants |

- **manifest.json**, listing each file with its name, what it is (art, token or
  a slot), who it belongs to, its size (a frame's, for a picture of several:
  with its `frames` and `fps`), and for hex pictures their columns, rows,
  shape and scale. It also lists the content files and says which
  Companion made the export.

Undrawn slots are left out, and nothing about your progress (stockpile,
designs owned, what you've explored) is included.

**To use it in the game**, put the zip in the game's folder as it is, next to
`project.godot`. The game reads the newest export it finds. The game's own
README says more.

## Hex pixels (experimental)

The **Hex Studio** tile on Home opens the same studio for drawing with
hexagonal pixels. The Pixel Studio offers hex pixels too, alongside square
ones, whenever you start a picture.

- **A hexagon** — for tokens: 6, 9 or 12 hex pixels per side, filling a board
  tile's hexagon.
- **A rectangle** — for card art: 32, 40 or 48 hex pixels across, filling the
  art box.
- **Pointy-top or flat-top** pixels, chosen per picture. Flat-top pixels build a
  pointy-top hexagon — the board's own shape — so a flat-top token lines up
  with its tile.

Every tool works on hex pixels. **Fill** spreads to the six neighbours, and
lines run as unbroken chains of hexes. **Mirror** adds **Three-way** and
**Six-way** symmetry: what you draw repeats around the centre every 120° or 60°.
**Kaleidoscope** reflects each of the six copies as well, so a stroke appears
twelve times, mirrored across six lines — or six times if you draw right on one
of the lines.
A hex picture exports to PDF with each pixel drawn as a hexagon.
