# The game's own art, and how it is drawn

Every picture a fight is drawn with (game 0.14) is made by these scripts: a
token for every master Unit, the five body plans and the four stand-ins (48 by
48 pixels), the board's deck plates, spawn pads, hazards, cover, crates,
chests, Emergency Exit and Healing Station, the Status icons (16 by 16) and
their marks on the board (8 by 8), the Aether gems, the bar's and the roles'
icons, and a picture for each kind of card that has no art of its own (64 by
45). Each is modelled from simple 3D shapes, lit from the top left, and drawn
in pixels on the Pixel Studio's palette, with a dark outline.

And since game 0.15, the World Map and the menus: the map's ground for each
District (four tiles of it, in hex pixels, as the Pixel Studio draws them: a
hexagon of flat-top hex pixels nine to a side, rendered at three pixels to a
hex pixel's corner) and rubble; each District's things (32 by 32) and the
Hangar (64 by 64); the map's icons (16 by 16); each District's five floor
plates (42 by 48) and its Half and Full Cover (48 by 48); Home's picture, the
Hangar inside and the colony at night (256 by 144); QM-7 and its blink (64 by
64); Victory and Defeat in neon; and the icons for shards, the parts, the
Skull Level and the gear.

And since game 0.16, the fight's effects, drawn frame by frame, each in its
own colours: the muzzle flash (24 by 24, 4 frames), the impact (32 by 32, 5),
the explosion (48 by 48, 8), the heal (32 by 48, 6) and the shield (48 by 48,
6), each with how many frames a second it plays at and the pixel that sits
over the point it plays at; and the turn strip's icons, Move and Attack, End
turn's hourglass, and the Holding fire eye that Hold fire wears too.

And since game 0.17, card art: a picture for each of the 83 cards that are not
Units (128 by 90), the thing itself on its District's backdrop (Vantage
Robotics' factory floor for District 3, the colony at night for a card of any
District or none). The backdrops are banded, dithered only at the seams between
bands, which keeps them small for the Companion to store.

And since game 0.18, the fight's atmosphere's motes, in `fx.png` beside the
effects (marked `atmos` in `art.json`): the ember (8 by 8, 4 frames), the
spark (12 by 12, 3), the ash (8 by 8, 3) and the dust (6 by 6, 2).

And since game 0.19, the card back (75 by 105, in `cardback.png`), drawn by
`cardback.py`: a dark plate in a cyan hex frame, and the KETER emblem, an
upside-down crown modelled and lit as the tokens are (the colony's surface
over the spires of its underground labs).

From the game's folder:

    python3 tools/art/build_art.py

writes `art/tokens.png`, `board.png`, `icons.png`, `cards.png`, since
0.15 `ground.png`, `map.png`, `district.png` and `menu.png`, since 0.16
`fx.png` (each effect a row of its frames, side by side), and since 0.17
`cardart.png` (each card's picture, keyed by its name, with its id and kind),
with `art.json`
(where each picture sits in its sheet, and what it is; for the ground, its
hex pixels too, as the Pixel Studio keeps them; for an effect, its frames,
speed and anchor). It takes about a
minute and needs Python 3 with numpy and Pillow. It reads the cards (each
master Unit's number and kind) from the Companion's `compendium_full.json`
beside the game's folder, as the sources lay them out, or else from the test
export the game's tests read. Add `--sheet` for a contact sheet of the tokens,
in `out/` here.

- `kart.py`: the palette, the materials and their colour ramps, the shapes,
  the renderer, the outlines.
- `rigs.py`: bodies: people in their poses, quadrupeds, spiders, drones,
  titans, arms and weapons.
- `sample.py`: the style sample's models, which some Units and props reuse.
- `units.py`: every Unit, by name (with its pose, colours and size).
- `props.py`, `tiles.py`, `icons.py`, `cards.py`: the board's things, its
  tiles, the icons and marks, and the card pictures and stand-ins.
- `hexpix.py`: the map's hex pixels: the hexagon of cells, and drawing it
  clipped to a tile.
- `mapart.py`, `mapprops.py`, `mapicons.py`: each District's ground and the
  rubble, its things and the Hangar, and the map's icons.
- `districts.py`: each District's floor plates and cover.
- `menus.py`, `uiicons.py`: Home's sign and skyline, the Hangar inside, the
  colony at night, QM-7, Victory and Defeat; and the menus' icons.
- `effects.py`: the fight's effects, frame by frame (`python3 effects.py`
  writes a contact sheet of each in `out/`).
- `cardart.py`: each card's picture, by the card's name (with its District,
  view and size), and the two backdrops (`python3 cardart.py [names]` writes a
  contact sheet in `out/`).
- `build_art.py`: draws them all and packs the sheets.

To change how a Unit looks, change its entry in `units.py` and run
`build_art.py` again; the game uses the new sheets the next time it opens.
Godot leaves this folder alone (`tools/.gdignore`).

A picture you draw in the Companion's Pixel Studio takes the place of any of
these, through Export for Godot: the Companion has a copy of each (made from
`art/` by its `make_art_pack.py`), in the World Map, Game look, The fight,
District fights and (since 14.3) Effects slots, on every master Unit's
card as its token and (since 14.4) on every card that is not a Unit as its
art. An effect goes in as one picture of several frames, at its speed.
