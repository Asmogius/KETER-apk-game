⬡

**KETER CARD FORGE**

**U S E R   G U I D E**

Tool version 2.1

Card data format v6  ·  Schema v1.0

*Reconciled against Player Handbook v11*

# **Quick Guide**

*The bare essentials. Everything else in this document is detail you can reach for when you need it.*

## **Open it**

Open **Forge** from the tab bar. It works offline once the app is installed, and your cards save on the device you built them on.

## **Make a card**

- Pick a Card type at the top of the panel. Everything below reshapes to match.

- Type a Name.

- Choose an Affinity. This sets the card’s entire colour scheme.

- Fill the Stat Bar, or the Aether cost on Combat Cards.

- Tick at least one Combat Role on Heroes, Troops and Enemies.

- Add an Effect and write its rules text.

- Watch the Tasks dock on the right count down to Card ready.

- Save, then Export print sheet.

The card number fills itself in. Leave it unless you want your own.

## **The four things that matter most**

- **Print at 100%. **No scaling, no fit-to-page, or the cards will not be 2.5 × 3.5 inches.

- **Commission art to the figure in the readout strip, not a fixed number. **The art window resizes as you type, and art made for the wrong size gets cropped rather than scaled.

- **Export a backup regularly. **Home → Export backup writes every card, map and loadout to one file. It is the only copy that lives outside this device.

- **Test one duplex sheet before a run. **Backs assume a long-edge flip; printers vary.

## **Reading the screen**

- **Tasks dock **— what the card still needs. Click any item to set it by hand.

- **Pings dock **— red is a rules contradiction, amber a layout consequence, grey advisory.

- **Readout strip **— live art dimensions, the pixel target at 600 dpi, and the current text size.

- **? Help **— outlines every control. Click one for an explanation.

## **Keyboard**

| **Key** | **Action** |
| --- | --- |
| Ctrl / Cmd + S | Save |
| Ctrl / Cmd + Z | Undo |
| Ctrl / Cmd + Shift + Z | Redo |
| Esc | Close a help popup, then exit help mode (on a keyboard) |

**Remember  **Blank cards start genuinely empty — no placeholder values. If the Tasks dock shows something complete that you have not filled, you hand-ticked it; those carry an amber outline.

# **Contents**

| ** ** | **Section** | **Covers** |
| --- | --- | --- |
| 1 | What this is | Where your cards live, and why backups matter |
| 2 | The twelve card types | Stat lines, effect caps, ranges, standing rules |
| 3 | Affinity, cost and colour | Districts, the corner cluster, rarity |
| 4 | The layout engine | How art and text compete, and art dimensions |
| 5 | The two docks | Pings by severity, and the Tasks checklist |
| 6 | Levels and scaling | Baked values, the scaling table, the three buttons |
| 7 | The library | Filters, print runs, rename and duplicate |
| 8 | Printing | PNG, print sheets, the completeness gate, duplex |
| 9 | Aether Chips | The circular type and its Spent face |
| 10 | Files and backup | Schema export and import |
| 11 | Reference | Help mode, preview options, numbering |
| 12 | When something looks wrong | Symptoms and fixes |
| 13 | Known limits | What this tool does not do |

Affinity is carried by the card's colour and its corner pips.

# **1.  What this is**

The card workshop inside the KETER Companion. It lays out cards and Aether Chips, previews them at true print size, and exports print-ready PNGs and PDFs. It handles twelve card types, tracks what each card still needs, and warns you about layouts that will not survive printing.

It does not handle art. The art window is a placeholder frame; you composite art afterwards, or in the companion app later.

## **Where your cards live**

The **Card Files** tab lists everything you have saved. Sort by name, card
number, type, rarity, affinity or Aether cost, and filter by affinity, type or
rarity. Card numbers sort naturally, so D3-H2 comes before D3-H10 rather than
after it.

Saved cards live on this device. Two consequences worth knowing:

- Moving or renaming the file can orphan your library.

- Clearing the app's site data deletes every saved card. The app keeps a mirrored copy and rolling restore points, but an exported backup is the only copy that survives losing the device.

**Backup  **Export a library schema file regularly. It is the only backup that survives either of those.

# **2.  The twelve card types**

| **Type** | **Code** | **Stat line** | **Eff.** | **Effect tags** | **Role** | **Aether** | **Corner** |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Hero | H | HP · AC · +⚔ · +AP · MS · LDR | 4 | Active / Passive | Yes | — | Spheres |
| Troop | T | HP · AC · INT · MS · ◎ · ☖ | 4 | Active / Passive | Yes | Yes | Cost pips |
| Enemy | E | HP · AC · MS · INT | 4 | Combo / Special | Yes | — | Skulls |
| Mini-Boss | M | HP · AC · MS · INT | 4 | Combo / Special | Yes | — | Skulls |
| Boss | B | HP · AC · MS · INT | 4 | Combo / Special | Yes | — | Skulls |
| Action | A | none | 2 | Active / Passive | — | Yes | Cost pips |
| Aether | AE | none | 1 | Active | — | Yes | Cost pips |
| Equipment | EQ | none | 4 | Active / Passive | — | Yes | Cost pips |
| Command | CM | none | 1 | Active | — | Yes | Cost pips |
| Consumable | CN | none | 1 | Active | — | — | Affinity pip |
| Prototype | PR | none | 2 | Passive / Active | — | — | Affinity pip |
| Aether Chip | AS | none | — | — | — | — | circular |

Unit can carry a pistol and a rifle with different reach. Ranged Actions also
carry a To-Hit threshold; Melee and Ranged Actions can carry Penetration, which
does not print when it is zero.

A Ranged Action also chooses its **Projectile**: what the game draws as it
fires. **Bolt** is a short glowing slug, fast and straight; **Shell** arcs over
the board and bursts where it lands; **Beam** is a line drawn at once from
shooter to target, flickering out; **Spray** is a quick spread of pellets. It
starts as a Bolt, changes nothing in the rules, and isn't printed on the card.

Switching type keeps any stat the two types share and blanks the rest. Effect tags remap rather than being dropped — an Enemy’s Combo becomes Active if you switch to Hero.

## **Stat ranges**

From Player Handbook §3–§5.

| **Type** | **Stats and ranges** |
| --- | --- |
| Heroes | HP 15–60 · AC 5–16 · Action Slots 1–10 · AP/turn 0–6 · MS 1–6 · Leadership 1–30 |
| Enemies | HP 10–50 · AC 3–18 · MS 0–6 · Integrity 1–20 |

Every Unit carries **Integrity (INT)**, 1 to 20: its armour against Cyber. Values outside these ranges raise a grey advisory, never a block — bosses and outliers are expected.

**Changed in Revision 15.5** Integrity replaced Will and Security on every Unit, and Intelligence retired: an Enemy's behaviour keywords decide how it acts.

## **Cards that carry a standing rule**

Four types print a reminder line at the foot of the rules box. These are automatic and reserve their own space, so rules text can never collide with them.

| **Type** | **Printed reminder** |
| --- | --- |
| Aether | Aether Damage ignores Armor Class. |
| Command | Discarded after use. |
| Consumable | Returns to the Loot pile after use. |
| Prototype | Always active while in combat. |

# **3.  Affinity, cost and colour**

Affinity drives every accent on the card — the keyline, art brackets, rules headings and stat abbreviations. Set a second Affinity and the colour sweeps diagonally, first at the top-left, second at the bottom-right.

| **District** | **Symbol** | **Megacorp** |
| --- | --- | --- |
| 1 | £ | Threshold Dynamics |
| 2 | ¢ | Halcyon Cognition |
| 3 | € | Vantage Robotics |
| 4 | ¥ | Lazarus Computing |
| 5 | § | Verdant Biogenics |
| 6 | ∆ | Meridian Entropics |
| Any | ° | Usable regardless of District |
| Neutral | ✓ | No District |

## **Variable costs**

Any cost slot can be set to X, XX or XXX instead of a number. An X in Any
Affinity prints pale; an X in a Dedicated slot takes its District colour. What X
buys has to be spelled out in the card's own text — the Forge warns you if it is
not.

Handbook 15.8 says how X is spelled out so the Simulator and the game can carry
it out:

- **As a keyword's number.** In the keyword builder, the number step has a
  second button on a card with a variable cost: **Use X**. It writes *damage
  X*, *+X HP*, *for X turns*, *Deploy X Aether Battery*. Typing X into the
  number box does the same.
- **In a stat, as N(X).** Type `5(X)` into Health and the Troop has 5 Health
  for each X.

X is chosen as the card is played, at least 1. X in plain words, outside a
keyword, is only words: the Forge warns that nothing will carry it out. X on
a card whose cost has no X is flagged as a problem.

A card saved before v13.4 remembered only that it had a variable cost, not
which slot the X stood in. Opened now, its X is put in the first empty slot,
Any Affinity first. Check it, and move it if that is wrong.

**The corner cluster**

Only one thing occupies the top-right, and which one depends on the type.

- **Affinity spheres **(Heroes) — one pip per Affinity level, capped at 6 total across both Affinities. Raising one lowers the other automatically.

- **Skulls **(Enemy, Mini-Boss, Boss) — set the Skull Level here; what it means is in the Handbook, §Symbology Key.
- **Salvage **(Enemy, Elite, Mini-Boss, Boss) — the video game only: which parts it gives when defeated (Troop, Equipment, Aether, or Mixed for any of the three). Not printed on the card. See the Loot Guide.
- **Blueprints and chassis **(Enemy, Elite, Mini-Boss, Boss; Dev Mode) — the video game only. **Can also drop** adds blueprint levels and chassis to its District's pool whenever it rolls a random blueprint drop; **Set drops** drops particular ones by their own chance, 0 to 100%. A player only ever gets the next level they are missing. Not printed on the card. See the Workshop and Codex Guide.

- **Cost pips **(Combat Cards) — the corner cluster the Forge builds from your cost fields. How Aether is paid is in the Handbook, §Affinity and Cost.

- **Affinity pip **(Consumable, Prototype) — a single hex, drawn only if you set a District. Any Affinity items like Rations need none.

## **Archetypes**

An Archetype is a targeting label and nothing else. It grants no ability; it
exists so other cards can name it. Up to three per card, and **+ New** adds your
own with just a name — the name is the whole of what other cards target.

One control, up to three Archetypes. Choose from the list to add one, tap a chip
to take it off. All three print under the card name and all three are live for
card effects — another card can hit every Assassin, or repair every Mechanical
Unit. The Title field is gone; it did the same job less precisely.

**Combat Role**

Every Hero, Troop and Enemy carries at least one Combat Role, and may carry any combination of the three. The icons print top-left of the card name.

| **Role** | **Icon** | **What it means** |
| --- | --- | --- |
| Melee | Fist | Fights at close quarters. Uses Melee Actions and Equipment. |
| Ranged | Crosshair | Attacks at a distance. Uses Ranged Actions and Equipment. |
| Support | Cross | Buffs, heals and controls rather than dealing direct damage. |

Combat Role describes what a Unit does and lets card effects target by Role. It restricts nothing: any Unit may use any card (Handbook 15.8).

Role and Archetype do different jobs, and the Handbook defines both in §Heroes. Both are labels that card effects can target a Unit by, so the two controls are separate and both can be set.

A Unit with no Role set raises a warning, and the Tasks dock lists it as outstanding.

## **Subtypes**

Revision 15.5. Every Unit has **one or two subtypes**, set with the Combat Role
tick boxes: **Melee**, **Ranged**, **Support** or **Cyber**. They decide which
kinds of Actions the Unit can have, and the Forge flags an Action outside them.
A third box won't tick. **Passives are exempt** (Revision 15.6): a Passive applies
whatever the Unit's subtypes, so it is never flagged.

A subtype is also a **narrowing word**: *target Ranged ally* can only be aimed at a
Ranged Unit. So is every Archetype, custom ones included, and *District 3*.

Whether a Unit is Human, Cyborg or Mechanical is **lore only** now; no rule reads
it, and a card that carried it keeps it as a note. Every Troop is a mechanical
robot. A **Cyber** Action must penetrate its target's **Integrity** rather than
its Armor Class.

**Rarity**


| **Rarity** | **Name colour** | **Aether value on a Chip** |
| --- | --- | --- |
| Common | Grey | 1 |
| Uncommon | Green | 2 |
| Rare | Blue | 3 |
| Epic | Purple | 4 |
| Legendary | Gold | 5 |
| Mythic | Crimson | 6 |

Enemies, Mini-Bosses and Bosses have no rarity — they are encounters, not loot.

# **4.  The layout engine**

The card is 2.5 × 3.5 inches. Within it, the art window, rules box and lore box compete for a fixed vertical span, and the tool resolves that competition automatically as you type.

## **Priority order when the rules text will not fit**

- Text shrinks from 8pt down to a 6pt floor.

- The lore box drops, and the text resets to the largest size that now fits.

- The art window shrinks toward a floor of 50% of its maximum.

- Overflow is flagged.

The art holds full size as long as the text can cope. Unit types start at 1.683 in tall; text-heavy types — everything with no stat line — start at 1.100 in and therefore have a much larger rules box.

## **Art dimensions**

The strip under the preview reports live dimensions and the exact pixel target at 600 dpi.

| **Card group** | **Art at full size** | **Pixel target at 600 dpi** | **At the floor** |
| --- | --- | --- | --- |
| Unit types | 2.270 × 1.683 in | 1362 × 1010 px | 2.270 × 0.842 in |
| Text-heavy types | 2.270 × 1.100 in | 1362 × 660 px | 2.270 × 0.842 in |

**Watch this one  **If a card’s art window has shrunk, art commissioned at full size will be cropped vertically, not scaled. The ping tells you when this has happened and reports the current ratio. Always commission to the figure in the readout strip.

# **4b.  Action stats**

Each Action carries its own numbers, printed as a small boxed strip under the
Action's name. Only values you actually set appear.

| Shown | On | Meaning |
| --- | --- | --- |
| AP | Heroes, Troops, Action Cards | Action Points to use it |
| DMG | any | Damage dealt |
| RNG | Ranged Actions | Reach in tiles |
| HIT | Ranged Actions | Threshold a d20 must meet; Cover and Evasive add to it |
| PEN | Melee and Ranged | Armor Penetration, added to the roll. Hidden at 0 |

**5.  The two docks**

Pinned to the right edge of the preview. Click a tab to slide it out; they open independently.

## # **4c.  Effects, keywords and Auras**

**Entry types.** An effect is Active, Passive or Aura. Active is something you
choose to do and usually costs Energy; Passive is always true; **Aura** affects
only Units within a printed **Radius**, and the card will flag an Aura with no
radius as an error.

**Combat keywords.** Each effect has an **Insert keyword** dropdown. Choosing
one drops it into the rules text *at your cursor*, stored as `[[Name]]` and
printed in italics with no brackets. Tapping it in the editor shows what it
means.

Five come from the rules — Evasive, Overclock, Aura, Half Cover and Full Cover —
and every keyword in the library has its definition too. **+ New** adds your own with a name and a definition,
kept on this device. The keyword itself changes nothing: the effect that names
it does the work.

**Energy costs** print on the effect as a badge. On a Troop they also fill
sections of the Energy bar under the art, so the bar shows at a glance how much
of a turn an effect costs.

# **4d.  Editing on the card**

The card image is interactive. Tap the **name** or a **stat** and you edit it
where it sits; tap the **type line**, the **cost cluster** or an **effect** and
a small editor opens beside it — pickers and multi-line text need the room.

Outlines flash while you touch the card and fade again, so the preview stays an
accurate proof of what will print.

The side panel does everything it always did. The card is a second way in, not a
replacement, and both write to the same card: edit in one and the other updates.

# **4e.  Equipment**

Equipment's stat bar holds **changes, not values**. +5 HP means it grants five,
not that it has five. Only the stats you fill in appear, and a gain prints with
its plus sign so a bonus and a penalty can never be confused.

Equipment effects may carry an **Energy cost**, paid by the Unit using them.

**Who may use it.** Anyone. Handbook 15.8 removed Usability Restrictions, so
the **Usable by** box is gone, and Equipment, Action and Command cards no
longer take Archetypes. Their type line reads *Any Unit*, *Any Hero* or *Any
Troop*. A card that named a subtype or Archetypes before simply stops naming
them; nothing else about it changes.

An Equipment card needs only four things to be finished: a name, a card number,
an Aether cost and a rarity. Everything else is optional.

**World Map Tiles**

A World Map Tile works like an Aether Chip: the piece you cut out is drawn live
into the art window, so the card and the token can never disagree.

The hexagon takes its colour from the **Affinity**. **Tile text** prints in a
band across the lower third \u2014 keep it short, it shrinks to fit. **Tile symbol**
is drawn from the same library the POI Sandbox uses, so any pictogram you have
imported there is available here too.

Effects on the card work as they do anywhere else, and describe what the tile
does once it is on the map.

**Behavior**

Enemy, Mini-Boss and Boss cards carry a **Behavior** section. Add keywords from
the list and each one states its rule underneath; the ones taking a number get a
field for it.

Keywords print at the foot of the card as names only — *Cunning · Cautious 2* —
with the definitions in the Handbook, the same way combat keywords work. That
keeps the card readable when an Enemy also carries a Combo.

The Forge flags combinations that cannot work, such as two targeting keywords
that both always apply.

**Pings**

Colour-coded by severity. The badge takes the colour of the worst active item.

### **Red — a rules contradiction or lost data**

- An AP cost on a Passive or Special effect, which will not be printed


- Rules text overruns with both the art and text at their floors

### **Amber — a layout consequence**

- Rules text is at its 6pt floor

- The art window is at its 50% floor, with the current ratio

- The lore box was dropped to make room

- A Chip has no Rarity, so it generates no Aether

- A Hero, Troop or Enemy with no Combat Role set

### **Grey — advisory**

- A stat outside the Handbook’s range

- An AP cost on a type that does not spend AP

- An Affinity level set with no Affinity chosen

- An Enemy with effects but no Combo

- The lore box is on but empty

## **Silencing a ping**

Every ping has an × . Silencing one hides it for that card only, and the dock
says how many you have quietened so a muted dock never looks like a clean one.
Show all brings them back. Silences travel with the card.

**Tasks**

Counts down what the card still needs, for its type. Reads Card ready at zero.

Every item is also clickable. Click to cycle it: automatic, then forced complete, then forced incomplete, then back to automatic. Hand-set items get an amber outline and a tooltip telling you what the tool reads it as, so an override never silently hides a real gap.

Title, second Archetype, lore and effects are deliberately absent from the list — a card is finishable without them. Combat Role is required on Heroes, Troops and Enemies.

# **6.  Levels and scaling**

Cards carry a Level 1–6. Scaling is baked: the values are written onto the card, so what you see is what prints. Editing the scaling table later never silently rewrites an existing card.

## **How it works**

The first time you scale, the tool captures a base snapshot of the Level 1 values. Every later scale recomputes from that snapshot rather than from current values, so multipliers can never compound. Base to Level 4 to Level 6 gives the same result as base to Level 6 directly.

## **The table**

One row per numeric field, each with a mode:

- **× multiply **— applies a factor

- **+ add **— applies a flat step

- **— freeze **— leaves the value alone

Defaults follow the Handbook: HP and Action Damage scale on the curve below. Everything else, including Armor Class, is frozen. Every row is editable.

| **Level** | **1** | **2** | **3** | **4** | **5** | **6** |
| --- | --- | --- | --- | --- | --- | --- |
| HP and Damage | ×1.00 | ×1.35 | ×1.70 | ×2.05 | ×2.40 | ×2.75 |

Rounding is to nearest whole. ∞, blanks and dashes pass through untouched. This table travels inside the schema export, so the companion app reads the same rules rather than reimplementing them.

## **The three buttons**

- **Scale to level… **recomputes from base at the chosen Level, showing a before-and-after diff before writing anything.

- **Re-scale from base **reapplies the table after you have edited it.

- **Set current as base **makes the values on screen the Level 1 baseline, for cards authored by hand rather than scaled up.

**Why Damage is a field  **Damage scales from each effect’s Damage field, not from prose. Damage written into rules text will not scale.

# **7.  The library**

Every card saved on this device, with filters by District and card type above the list.

Each row carries a tick to include it in a print run, a copy count, the type code and level, a pencil to rename, a plus to duplicate, and a cross to delete. Incomplete cards show their name in amber with a tooltip counting what is missing.

**Useful behaviour  **Filtering never changes what is ticked. A selected card stays selected while hidden, so you can build a mixed print run in passes.

Duplicate opens a dialog for a new name and an optional target Level, diffs the change, and assigns a fresh card number. It works on the card currently on screen too, saved or not — use the Duplicate this card button in Card Files.

# **8.  Printing**

## **Export PNG**

The current card alone at 600 dpi. Cards come out 1500 × 2100 px; chips 921 × 921 px. Guides are never included.

## **Export print sheet**

A letter-size PDF with crop ticks.

| **Item** | **Grid** | **Per sheet** |
| --- | --- | --- |
| Cards | 3 across × 3 down | 9 |
| Aether Chips | 5 across × 6 down | 30 |

It uses whatever is ticked in the library, with your copy counts, and falls back to the card on screen if nothing is ticked. Each distinct card is rasterised once no matter how many copies you print, so a 15-card deck at 4 copies each renders 15 images, not 60.

If a run mixes cards and chips, two PDFs are emitted — the grids cannot share a page.

**Critical  **Print at 100% with no scaling, or the cards will not be 2.5 × 3.5 inches.

## **Completeness gate**

Exporting anything incomplete raises a confirmation listing which cards are short and what they are missing. It is a confirm, not a block, since some cards are deliberately part-finished. Hand-ticked checklist items count as complete.

## **Duplex backs**

Tick Include backs for duplex printing and each front page is followed by a back page with the columns mirrored, so a long-edge flip lands the right back on the right card.

For Aether Chips, the back is the Spent face — §624 says spending a Sphere flips it face-down until it recharges, so a two-sided chip sticker gives you the flip mechanic for free.

**Test first  **Run one sheet before committing to a print run. If your printer flips short-edge, the backs will land rotated.

# **9.  Aether Chips**

Chips are ordinary cards now, with the circular 39mm face drawn into the art
window. It redraws as you change Level, Rarity or Affinity, so the card and the
token can never disagree. The card carries the Chip's Effects, which a physical
chip has nowhere to hold.

Generation is **Level plus a Rarity bonus**. Level 1–6 gives 1–6 Aether; Rarity
adds +0 for Common and Uncommon, +1 for Rare and Epic, +2 for Legendary and
Mythic. A Level 6 Mythic Chip generates 8, which is the ceiling. Rarity's other
job is signalling how strong the Chip's Effect is — Common Chips usually have
none.

**10.  Files and backup**

| **Action** | **What it writes** | **Use it for** |
| --- | --- | --- |
| Save / Save as | This device | Day-to-day work |
| Download card file | One card as JSON | Sending one card to another player |
| Open card file… | Reads that JSON | Restoring one card |
| Export library schema | The whole library, versioned | Backup, and feeding the companion app |
| Import library schema… | Merges a schema file back | Restoring, or merging another machine’s work |

The schema file is the important one. It carries schemaVersion 1.0, the generator version, every card with canonical field names, base values alongside baked ones, and the scaling table.

Import merges rather than replaces. Cards match on card number first, then name. You see how many will be added and how many overwritten — and which — before anything is written. Name collisions on new cards get suffixed rather than clobbering.

Older files migrate automatically on load: armor becomes Armor Class, retired stats are dropped, old Subtype becomes Title, retired Leadership effects become Passives, and a Hero’s old Will value moves into Leadership.

# **11.  Reference**

## **Help mode**

The **?** in the top bar, between the panel button and More, outlines every control in cyan. It opens the panel and its sections first, since help can only label what is on screen. Tap a control for an explanation and tap it again to close it; only one is open at a time. **Done**, at the bottom left, ends help mode, and so does tapping the lit **?** again.

## **Preview options**

- **True print size **— renders at exactly 2.5 × 3.5 in. The only honest test of whether 6pt text is readable.

- **Bleed and safe zone **— red is the trim edge, amber the safe zone. Never exported.

- **Light print theme **— white card with darker accents, far cheaper to print, and it applies to exports.

- **Preview the card back **— shows the back, or the Spent face for chips.

- **Zoom **— screen only, never affects export resolution.

## **Card numbering**

Format D<district>-<type><nn>, sequenced against cards already on this device. D3-H01 is District 3, Hero 01. Each type keeps its own sequence, so D3-H01 and D3-E01 coexist. Typing your own switches the field to manual; Auto takes it back.

| **Code** | **Type** | **Code** | **Type** |
| --- | --- | --- | --- |
| H | Hero | AE | Aether |
| T | Troop | EQ | Equipment |
| E | Enemy | CM | Command |
| M | Mini-Boss | CN | Consumable |
| B | Boss | PR | Prototype |
| A | Action | AS | Aether Chip |

## **Panel sections**

Identity, Level & Scaling, Lore, Stat Bar, Effects, Preview, Card Files. Open and closed state is remembered between sessions. Sections that do not apply to the current card type hide themselves.

Undo holds 60 steps and coalesces fast typing, so a sentence is one step rather than forty. It resets when you load or create a card.

# **12.  When something looks wrong**

| **Symptom** | **Cause and fix** |
| --- | --- |
| The card is cyan and will not change colour | No Affinity is set. Blank cards start with none. |
| Tasks shows items complete that I have not filled | You hand-ticked them. Hand-set items carry an amber outline; click to return them to automatic. |
| My rules text is tiny | It has hit the 6pt floor. Shorten an effect, or move one onto an Action Card. |
| Art looks cropped | The art window shrank to make room for text. Regenerate art to the figure in the readout strip, or cut text. |
| Cards print the wrong size | Print at 100% with no scaling or fit-to-page. |
| Duplex backs are on the wrong cards | Your printer flips short-edge rather than long-edge. |
| My library vanished | Site data was cleared. Try Home → Restore points first; otherwise import your most recent backup. |

# **13.  Known limits**

- **No art handling. **The window is a placeholder; composite art afterwards.

- **This device only. **Nothing syncs between phones. To share cards, export them from the Compendium and send the file.

- **Nothing is verified on paper. **Every dimension in this tool is verified arithmetic. Whether 6pt reads at the table, whether skulls hold at 0.12 in, and how your printer duplexes are all still unknown until you print a sheet.

*Reconciled against KETER Player Handbook v11. Where this guide and the Handbook disagree, the Handbook wins.*

KETER Card Forge v2.1  ·

**A note on this guide**

This guide covers the Card Forge, not the rules. Where a card's numbers come from
and what they mean lives in the Player Handbook, which is one tap away in Guides.
Any term in this document can be tapped for its definition, and the Glossary page
lists every keyword with the section that defines it.

## Writing effect text

Rules meaning lives in the **coloured** words. Everything you type yourself stays
white: it reads on the table and the Simulator ignores it.

Seven categories, each a colour (Handbook 15.4):

| Colour | Category | Example |
| --- | --- | --- |
| Violet | Condition | *when this Unit takes damage*, *if the target has Slowed* |
| Cyan | Target | *target Sniper ally*, *all enemies within 2 tiles* |
| Amber | Effect | *damage 5*, *heal 3*, *Push 1 tile* |
| Crimson | Status | *Rooted*, *Poisoned 3* |
| Pink | Duration | *for 3 turns*, *persistent* |
| Green | Modifier | *Burst 3*, *AoE 1*, *Pierce* |
| Blue | Stats | *+10 HP*, *−2 AC* |

### The keyword builder

**+ Build an effect** (Revision 15.6) walks you through **one effect** — one
sentence — a step at a time:

1. **When does it happen?** An Action happens every time it is used, or *only
   if* something is so. A Passive is *always on*, reacts *when something
   happens*, or holds *while something is true*.
2. **Who is it about?** this Unit, an ally, an enemy, any Unit, the target — or
   *the round*, for *when the round begins*. An ally, enemy or any Unit can be
   narrowed: a subtype, an Archetype, a District, within N tiles.
3. **What happens, or what must be true?** Events for *when*, states for
   *while* and *if*. A Passive's *when* may add one *if* check.
4. **Who does it affect?** Optional, and it can be narrowed too.
5. **What does it do?** Effects, Statuses, Stats or cover; add as many as it
   does.
6. **Any Modifiers?** and **how long does it last?** when they apply.

Every step offers only what that kind of ability may use, **Back** and **Skip**
are always there for optional steps, the sentence builds at the top as you go,
and the power shows live — this effect, and the ability as a whole. It ends on a
**review** of the whole sentence where any part can be changed; **Insert** adds
it. Each effect is then listed under **Effects**: tap one to reopen it at the
review and change it (**Replace**). Words of your own in a sentence are lost if
you rebuild it, and the review says so.

**Insert keyword** still puts in a single keyword wherever the cursor is, so
nothing can be mistyped or half-marked. The list is grouped by category; choose a keyword and it asks for
its number using that keyword's own wording — Damage each turn for Poisoned,
Tiles for AoE, an amount up or down for a Stats keyword such as AC — because what
the number means differs by keyword. A Status's number is its strength; how long
it lasts comes from a Duration. A Stats change must carry a Duration, and the
Forge warns if it doesn't. A keyword that
takes no number goes straight in.

**Write one effect per sentence**, in the order **Condition → Target → Effect →
Modifier → Duration**. A card that does two things uses two sentences, so it is
never unclear which number belongs to which.

**Conditions are grammar** (Revision 15.6): a connector (*when*, *if*, *while*),
who it is about, and an event or a state. An **Action** checks with *if*; a
**Passive** reacts with *when* (plus at most one *if*), holds *while* a state
does, or with no Condition is **always on** — its Stats need no Duration, and
its damage or healing happens once a round, at Recharge. The Handbook's
Conditions table lists every event and state.

**How it prints.** Distances say *tiles*, turns read *for 2 turns*, and a
narrowing word prints inside its Target — *all District 3 allies within 2 tiles*.
An older card's one-piece Conditions (*if damaged*, *when deployed*…) are
rewritten as grammar when it loads.

The card shows what you will get as you type. If a keyword prints grey, it has
been withdrawn and needs rewriting.

## What the Forge will tell you about effects

The checks flag an effect using a **withdrawn** keyword, an effect marking a
word that is **not in the library**, an effect with **no keywords at all** (the
Simulator will log it for you rather than carry it out), and — Revision 15.6 —
**grammar it cannot read**: an Action using *when*, a *while* with an event, an
event with no connector, *that Unit* with nothing to point back at. An
always-on Passive also says, in grey, what it will do: a Duration in turns does
nothing there, damage comes once a round, and with no Target it applies to
this Unit (or the attached Unit, on Equipment).

Cards converted from before Revision 15.1 carry a note saying why they were left
as plain text — usually a condition, a scaling value or a dice roll that could
not be marked up safely without changing what the card means.

## Elites

An Elite is its own card type, sitting between an ordinary Enemy and a
Mini-Boss. It uses the Enemy stat line, with ranges set halfway between the two:
Health 30–70, Armor Class 6–18, Movement 1–6, Integrity 1–20.
Like an Enemy it carries Behavior keywords and a Skull bounty, and like an Enemy
it has no Rarity — it is an encounter, not loot.

## What an Action Card costs to use

An Action Card is assigned to a Hero before a Combat and then used like one of
their own Actions, so its cost is paid **every time it is used**, not once.
**Each use costs** sets which: Energy, Aether, or both. It prints on the card, and
the fields follow — choose Energy and the Aether cost disappears.

A card made before this existed works its answer out from what it already
carries, so nothing you made changes meaning.

## An Aether Chip's value

Every Chip prints its own Aether value, from 0 to 10, in the **Aether value**
field. Leave it empty and the Chip uses the guideline instead, shown in the box:
Level sets a base of 1 to 6, and Rarity adds a bonus — nothing for Common and
Uncommon, +1 for Rare and Epic, +2 for Legendary and Mythic.

## Power score

A small badge **under the card** shows its score while you work. It is a second
opinion, not a rule, and it is never part of the card itself — nothing about it
appears on an export or a print.

The badge shows the points and the verdict. **Tap it** to see the budget and
where that budget came from; tap again to fold it away.

**What a card costs buys it a budget. What it carries spends that budget.** The
useful part is the gap, because it tells you what to change: *12 over, so drop 6
Health or charge 3 more Aether.*

The dot is green within 6 points either way, amber when over or under, and red
when far enough out to be deliberate or a mistake.

### Where the numbers came from

They were fitted to cards you had already made by hand. Across 25 complete
Troops, Aether cost predicts stats with an R-squared of 0.74 — so this is the
curve already in use, not one imposed on top of it.

| What | Points |
| --- | --- |
| Health | 1 each |
| Armor Class | 1 each |
| Energy | 3 each |
| Movement Speed | 1 each |
| Integrity | 1 each |
| Leadership | 2 each |
| A targeting or movement keyword | 2 |
| Medic or Guardian | 3 |
| Each point of a keyword's number | 1 |

Energy being worth three times Health is not a guess. It falls out of what you
priced your own Troops at.

### Budgets

A card priced in Aether is budgeted on that price, plus 1.5 Aether for every
Unit Slot past the first.

An Enemy has no Aether cost, so it is budgeted on its **Skull Level**. That one
is fitted on only six Enemies that carry both a Skull Level and stats, so treat
it as a starting point rather than a measurement. Filling in the missing Skull
Levels would sharpen it.

Everything else with no Aether cost — Heroes, Consumables, Prototypes, Aether
Chips — is budgeted on **Rarity**, which is the only dial those cards have.

### Scoring an effect

Rules text cannot be read honestly by a machine, so you score it yourself in the
**Power** field on each effect. Score by comparison, not in a vacuum:

| Points | Compare against |
| --- | --- |
| 2 | *Heals 4* — small, one target |
| 4 | *Deal 5 damage* — an ordinary damaging Action |
| 6 | *Every Enemy within 2 gains Rooted* — several targets, no damage |
| 8 | *Deal 8 damage, take 3 yourself* — large, with a real cost |
| 12 | *The first time each round a Unit would go down, it stays at 1 Health* — persistent, changes a rule |

An effect left blank counts as 4, and the card says how many are unscored, so
nothing is silently treated as free.

An effect written in keywords scores itself (the keyword builder shows it
live). A sentence aimed at an area — *all enemies*, *all allies* or *all units
within* N — counts (1 + 0.5 × N) times what it carries (Handbook 16.0).

### Warnings worth knowing (Handbook 16.0)

- **Stunned, Rooted, Pinned and Marked last 2 turns at most.** A longer
  Duration, *persistent* or *while attached* is flagged, and so is one given
  by an always-on Passive.
- **Execute** must be aimed at an Enemy: *target enemy* or *all enemies within*.
- **Overclock** has no rules in a fight yet. A card that has it is warned that
  it does nothing there; the rest of the effect still works.
