# **Battle Simulator Guide**

The Simulator plays a Combat. You act, and it resolves — no table, no
Minifigures, no dice hunting. It is the same rules the Handbook describes,
executed rather than remembered.

## Simulator or Datapad?

Both track a fight, and it is worth being clear which you want.

The **Combat Datapad** assists a Combat happening in front of you. You move the
Minifigures, you roll the dice, you tell it what happened. It counts the things
a table forgets.

The **Battle Simulator** *is* the Combat. It has the floor, the Units, the
Deck and the Aether. It runs the Enemies for you and decides nothing you were
meant to decide.

Use the Datapad at the table. Use the Simulator when the table is not out.

## Setting a Combat up

**Set up a combat** asks for a map first, because the Enemy Spawn tiles on it
decide how many Enemies you may field. Choose one of the three arenas or any
floor you have drawn in the POI Sandbox.

Then it asks only what changes from fight to fight:

**Strike Team.** One of the Loadouts you built in the Deck Builder, with its
Heroes, its Deck and its Aether Pouch.

**Who enters, and who leads.** The Floor's size decides how many Heroes may
come — 1 on a Small Floor, 2 on Medium, 3 on Large. Tap to choose, and tap
**Make leader** to set who leads. Heroes left behind are reserves.

**Enemies.** **Auto** fills the pile from your Enemy cards at each Spawn Tile's
Skull Level. **Manual** lets you name exactly what can appear, and warns you if
you pick Enemies at a Level no Spawn Tile on the Floor uses, since those could
never be drawn.

Then a **summary**, where everything else can be opened and changed:

**Starting Troops** — Troops taken out of the Deck to begin the combat beside
your Heroes, up to their pooled Leadership. They cost nothing. If one will not
fit, it says why.

**Action Cards** — what each Hero carries. They come from the Strike Team, and
changing them here is for this fight only.

**Aether Pouch** — what you carry, and whether it holds enough for the priciest
card in your Deck.

**Prototypes** and **Consumables** — as before.

**Waves and instability** — how many turns before the next wave arrives even if
the current one is not cleared, and how many Districts you have cleared, which
sets the chance of something worse spawning. The chance can be overridden. The
Elite or Mini-Boss comes from the floor's own District; if it has none of the
kind rolled, the ordinary Enemy arrives and the Log says so.

## The board

Units deploy on their own side's Spawn tiles, read from what the floor calls
its tile colours. A floor with no Spawn tiles puts each side at opposite edges
and tells you it did.

**Tap one of your Units** and the tiles it can reach light up, counted properly
around walls and other Units. Tap a lit tile to move there. Tapping the Unit
again deselects it.

**Tap a marked Enemy to attack it.** Only Enemies you can actually reach with an
Action you can afford are marked.

A Unit carries three characters on the board. Tap it to see the rest: Armor
Class, Movement Speed, Energy, Integrity, statuses, equipment, Behavior
keywords, and every Action with its cost, damage and range.

**Its token** is the picture it wears. A Hero wears the skin chosen on its
card, a design the skin chosen in the Workshop, and each Enemy that spawns a
random look from its card's own token and its skins. Every master Unit comes
with a token of its own (since 14.1, the game's drawing of it, 48 pixels
square), and so does each body plan's stand-in skin. The Pixel Studio Guide
has the rest.

On a floor too large to fit, the view holds a readable tile size and **pans** —
drag the board to look around.

## Cover and Spawn tiles

Tile colours mean what the floor says they mean. A Half Cover Barricade adds 2
to the To-Hit a Ranged Attack must beat and a Full Cover Barricade adds 4, but
**only when the Barricade stands between the shooter and the target**. Standing
next to one does nothing if the shot comes from the other side.

## Hazards

A floor drawn in the POI Sandbox can carry hazard tiles, hatched in red. A Unit
entering one, or ending its turn on one, takes its damage and its effect. It is
terrain: it applies to both sides, and Armor Class does not stop it.

Units route around a hazard when they can and through it when they cannot.

## The Datapad panel

Drag its top edge to size it, or tap the edge to fold it away.

**Fight** shows the Aether Bank, the Deck, Hand, Discard and Pouch counts, your
hand, any Prototypes and Consumables, and both sides' Units with their Health.

**Log** is everything that has happened, newest first. The line above the board
always carries the last event; tapping it opens the Log.

## Playing cards

**Tap a card to read it** — its cost, its full rules text, and whether the Bank
can pay for it. Nothing is spent until you confirm.

A **Troop** deploys to an open Player Spawn tile. **Equipment** attaches to a
Unit you choose and applies what it grants. An **Action** asks for a target and
resolves. A **Command** is logged for you to apply, because its text is written
for a person to read rather than for the app to parse.

A card you cannot afford is greyed and says what the Bank holds.

A Troop's card stays with its Troop and reaches the Discard Pile when the Troop
goes down. Equipment goes there when it is removed or the Unit wearing it goes
down. (Before 13.3 both were discarded the moment they were played.) A card
with **Recover** asks which Troop's card to return from the Discard Pile to your
hand, and cannot be played while there is none.

**Consumables** are read before they are used, like a card: tap one, then **Use
it**. Its text is carried out, with a target where it needs one. It costs no
Aether, is used on your turn, and is gone for the rest of the Combat. (Before
13.3 it was only marked used, with its text logged for you to apply.)

A carried **Action Card** that prints an Aether cost takes that Aether from the
Bank at every use, on top of its Energy. Its button shows both, and is greyed
while the Bank cannot pay.

A card with a **variable cost** (X) asks for X as you play it: a stepper from 1
up to what the Bank can pay, showing what each choice costs. Its text is then
carried out with that number wherever a keyword says X, and a Troop whose stat
is written N(X) arrives with N for each X. A Starting Troop with a variable
cost, or one put down by a Deploy, has X = 1. A carried Action Card with a
variable cost asks for X each time you use it.

## Aether

Three things happen before you play anything each turn.

Your Heroes **generate** Aether of their own Affinity equal to their Affinity
Level. You **draw** Aether Chips from the Pouch equal to your Player Level,
which comes from the Strike Team. And every Chip already in your **Bank**
generates its value again.

Drawn Chips stay in the Bank for the rest of the combat, so the Bank grows as
the fight goes on and a fuller Pouch keeps it growing for longer. Unspent Aether
is lost at the end of each turn — it is the Chips that carry over, never the
Aether.

The Bank shows on the Datapad as a row of chips. One with an effect is lit: on
your turn, tap it to spend it for that effect. It still generated its Aether this turn, and it
recharges, so each can be spent once a turn. Effects the resolver knows are
applied; anything else is written into the log for you to apply.

District Aether pays its own District. Generic Aether pays anything, and
District Aether can also pay the generic part of a cost.

## Dice

**Auto** rolls and reports. **Manual** asks what you rolled and waits, and tells
you what you need to beat. Switch at any point, including part-way through an
attack.

A Ranged Attack takes two rolls — one to hit, one to Penetrate — and only asks
for the second if the first lands. Melee always hits but must still Penetrate.
Aether does both automatically. What an attack carries (its Statuses, Pushes
and extra damage) lands only when it Penetrates (Handbook 16.0); a Support
Action's always does. A Support Action aimed only at *this Unit* (Handbook 16.2) has no target
to pick: choosing it uses it at once, on the Unit itself.

## The turn, in phases

Every round runs in the Handbook's order, and the tracker above the board shows
where you are:

**Waves · Aether Generation · Aether Draw · Draw · Recharge · Your turn · Enemy turn**

**Next** moves the turn on one step and does that step's work, so you watch the
Aether arrive and the cards come rather than finding it already done. The button
says what the next tap does: *Next ›*, *End turn*, or *Enemy 2* when two Enemies
still have to act.

**Only Your turn allows moving, acting and playing cards.** Tapping the board in
another phase selects a Unit to look at and says which phase you are in.

**Undo phase** takes back everything done in the phase you are in — every move,
attack and card — and puts you at its start. It replaced the old per-action
undo, so there is one way back rather than two.

Ending your turn with Movement or Energy unspent asks first, and names who still
has something left.

## Moving and acting

A Unit may move up to its **Movement Speed** each turn, and it does not have to
spend it all at once: move two tiles, use an Action, then move the rest. What it
has left is what it can reach, and selecting it again does not refill it.

Actions are limited by **Energy**. A Unit with 3 Energy can use three 1-Energy
Actions, interleaved with its movement however you like.

If an Action cannot be used, the Simulator says why — out of Energy, or out of
range, naming the Action and how far away the target is.

## Your hand

Your hand sits along the bottom of the board as your real cards, fanned and
overlapping. **Tap a card to raise it** — it grows so you can read it — and **tap
it again to play it**. If it needs a target, the Units it can reach light up on
the board: tap one, or Cancel. A card aimed at ground asks for a tile instead.

A card you cannot pay for is dimmed, and raising it says what it needs.

The **hand button** in the board's bottom-right corner — a fan of cards, with how
many you hold — hides the hand when you want the whole board, and brings it back.
While the hand is open it sits just above it, so it never covers a card. With a
Unit selected, it brings your hand back and deselects the Unit.

## Acting with a Unit

**Select one of your Units and the hand gives way to its action bar**, showing
its Movement and Energy and a button for each Action with its cost, range and
damage. An Action it cannot use is greyed with the reason: *Stunned*, *Needs 2
NRG*, *No line of sight*, *Nothing in reach*.

**Pick an Action first**, and every target it can reach lights up with its odds
above it — the chance to hit and penetrate, and the damage — coloured green,
amber or red. Tap a target to attack. The movement tiles step aside while an
Action is picked; tap anywhere else to drop it. Deselect the Unit to get your
hand back.

A Unit whose card grants Suppressive Fire has a **Hold fire** button here too.

## Zoom

Pinch to zoom, or use the wheel on a desktop. The buttons in the top corner of
the board zoom in and out and show how far; **Fit** returns to the whole floor.

## Debug mode

For checking that the Simulator does what the Handbook says. Switch it on in
**Settings**; a debug fight is marked **DEBUG** throughout.

- **Debug combat**, beside *Set up a combat*, starts a fight straight away on a
  test floor with the **Test Strike Team**: the test Heroes, a Deck of the test
  cards, each Hero carrying a test Action Card, and the test Prototype,
  Consumables and Aether Chip.
- The normal setup offers the Test Strike Team first, too.
- Fights draw **only the test Enemies**, so what you see is what the test cards
  do, not your real Enemies.

A **Debug** tab joins Fight and Log:

- **Next dice** — queue results for the next rolls, used in order before the
  dice roll normally again. Handy for forcing a hit or a miss.
- **Aether and cards** — add Aether, or put any card straight into your hand.
- **Units** — *Move freely* puts a selected Unit on any tile, ignoring Movement
  and walls; *Place* adds a Unit from any card, as an Enemy or an ally, at the
  next tile you tap. With a Unit selected, set its Health and Energy, and add or
  clear its Statuses.
- **Checklist** — for every test card, what it should do. Tick each item as you
  see it work. It remembers your ticks, and counts how many are confirmed.

Some items are expected to fail for now: **Aura** and **Overclock** do nothing
yet, **Half Cover** and **Full Cover** as card words do nothing, and a **Passive**
with no trigger never runs. That is what the checklist is for.

## The test floors

Four floors marked TEST join your floor library, each with notes on what it is
for. **Sight Lines** has a lone wall, a wall run and a sealed corner.
**Corridor** lines Units up for Push, Pierce and Chain. **Hazards and Cover**
puts acid tiles beside Half and Full Cover. **Waves** has Spawn Tiles at Skull
Levels 1 to 4. Edit them in the Sandbox if you like; an edited one is never
overwritten, and deleting one brings the original back.

## What the Simulator carries out

A card's coloured words are its rules, and the Simulator runs them: damage,
heals, every Status, the Stats changes (+2 AC), Push, Burst, Pierce, Chain, AoE, Deploy, Sacrifice, remove,
the Conditions that gate them, and every Passive. White text is flavour and is written into
the log for you instead.

Two kinds of thing stop short. **Plain text** with no keywords is logged and the
fight carries on. An effect that **carries keywords but could not resolve** — a
withdrawn word, a Stats change with no Duration — pauses the fight until you have
seen it, since it was meant to run. The Card Forge flags the same problems.

A keyword that resolves to nothing is named: *Chain found no second Enemy*,
*Deploy had nowhere to put it*.

## Conditions and Passives

Revision 15.6. Conditions are grammar — *when*, *if* or *while*, who it is about,
and an event or a state — and the Simulator follows each:

- **when** listens. Taking or dealing damage, a kill, being deployed or
  Incapacitated, attacking or being attacked (hit or miss), finishing a move
  (a Push is not a move), gaining a Status, and **the round beginning** at
  Recharge are all announced as they happen, and a Passive waiting on one fires
  **each time**. It never fires from anything its own effect set off, so a
  chain of Passives always ends.
- **if** checks as the effect resolves: in an Action it can ask what the Action
  just did (*if the target takes damage*), and anywhere it can ask what is true
  (*if the target has Slowed*, *is below half HP*, *is within 2 tiles*).
- **while** keeps an effect on exactly as long as its state holds.

A **Passive with no Condition is always on** while its card is active — a Unit
standing, Equipment attached, a Prototype in the fight (through the leading
Hero). Its Statuses and Stats are worked out afresh from where everyone stands
every time the board changes, so stepping next to a Prototype's bearer, or out
of an Aura, turns them on or off, and Health or Energy moves only by the
difference. Its damage or healing happens **once a round, at Recharge**. Enemies'
Passives work the same way.

**Narrowing words** limit who counts: an Action or card written *target Sniper
ally* can only be aimed at a Sniper, and *all Ranged allies within 3 tiles* skips
the rest. Units carry their subtypes, Archetypes and Districts into the fight
for this.

## Statuses

A dot under a Unit is a Status; tap the Unit and the panel names each in its
colour, with its strength and the turns it has left — *Poisoned 3 · 2 turns*.

Handbook 15.4: **every Status lasts its Duration at full strength, then ends** —
1 turn if its card gives none. A second dose **adds** its strength and its turns.
When a Status ticks, Poisoned deals its strength, Bleed takes a rounded 10% of
remaining Health, and each loses a turn. Drained comes off every Energy refill
while it lasts.

Handbook 15.9: **a Status ticks at the end of the turn after the one it arrived
in.** One that arrives in your half of the round (from the Recharge to the end
of your turn) ticks at the next **Recharge**, once the Enemies have had their
turn. One that arrives in the Enemies' half (their turn, and the Waves, Aether
and Draw phases after it) ticks as you **end your next turn**, before the
Enemies act; the Log shows it there. So a Hero Stunned by an Enemy loses the
turn that follows, and an Enemy's Poison does its damage after you have had a
turn to answer it. A timed Stats change counts down the same way. Until v13.5
everything ticked at the Recharge.

Handbook 16.0: **Stunned, Rooted, Pinned and Marked are locks.** Each lasts 2
turns at most, and a second dose does nothing while the first lasts; the Log
says *already Stunned*. When one ends, the Unit is guarded against it until the
same point of the next round: a hollow ring in its colour sits beside the
Unit's Status dots, the Unit's details say **Guarded**, and a lock aimed at it
is shrugged off.

## Attacks you can see

A **ranged** attack fires a small pixel bolt — cyan from your side, red from the
Enemies'. When it lands, the result floats above the target for two seconds:
**-X HP** in red, or **Miss** and **-0 HP** (a hit that doesn't penetrate) in
white. A melee attack floats its result at once. Healing floats **+X HP** in
green; a Status floats its name in green if it helps (Evasive, cover) and red if
it hinders. Several at once over one Unit queue, one after another — the
attack's damage first, then what it caused. It all plays during auto-battle
too.

## Burst

An Action with **Burst 3** is made three times in all, for one payment of its
Energy. Each attack rolls and applies its effects separately. After each one,
the targets in reach light up again with their odds: tap the next, a new one or
the same. With only one in reach, the Burst carries on by itself. A Burst runs
to the end while a target remains, so until it finishes, ending the turn,
playing a card and the hand button wait. An Enemy with Burst chooses each
attack's target afresh; a Unit holding fire with a Burst Action fires the whole
Burst at the Enemy that set it off.

## Lunge, Charge, Dash and Leap

Revision 16.1's movement keywords are carried out in full.

- **Lunge.** A Melee Action with **Lunge 2** lights targets up to 3 tiles
  away. Use it and the Unit walks up to 2 tiles to stand beside the target
  (off a hazard if it can, then the shortest way, then the tile beside the most Cover), free, then
  attacks. The Log says *lunges 2 tiles*. A Burst lunges for its first
  attack only.
- **Charge.** Once a Unit has moved 3 tiles this turn (a Lunge's tiles
  included), a Charge Action's odds show the extra damage, and the Log adds
  *(Charge +2)* to the hit.
- **Dash.** One of yours given **Dash 2** shows the extra tiles in its action
  bar (*Move 6/6*) and can use them after attacking. An Enemy Dashes away
  from whoever it struck, at once.
- **Leap.** A Unit that can Leap has the jumps among its lit tiles, over
  Units, walls and gaps; the Log says *leaped*.

## Revision 16.3's keywords

- **Troop and Hero** narrow a Target: *all Troop allies* reaches your Troops
  only. **all allies** and **all enemies** reach a whole side, wherever it
  stands.
- **Aim** lowers what a ranged attack needs to hit: a Unit with +2 Aim shows
  better odds over its targets, and its To-Hit of 10 is rolled as 8.
- **Hardened** takes its number off each hit on the Unit, never below 1; the
  Log shows the damage after the cut.
- **Draw** puts cards from the Deck in your hand; **gain Aether** adds to the
  Bank (the card's District, or Neutral). On an Enemy's card neither does
  anything.
- **Barricade** puts a Half or Full Cover Barricade on the tile you aim at, if
  it is empty. It counts as Cover from then on, like one drawn on the floor. Undo takes it
  back (14.12).
- **Line** and **Cone** carry an attack's damage on: to every Unit in a
  straight run of tiles through the target, or in the wedge widening toward
  it. Friend or foe, as AoE.

## Actions aimed at a tile (14.12)

A Unit's Action that says *target tile* (Test Bulwark's Raise Wall) lights
every tile within its range that the Unit can see. Tap one and the Action is
carried out there: no attack roll, its Energy paid as any other. Tap the
Action again to put it away. Auto never uses one.

## Sight and walls

A ranged Action needs **range and line of sight**. Only walls block sight, and
the rule is generous: if any line between the two tiles gets past every wall,
the shot is on. Select a Unit and the board **shades what it cannot see**.

Walls also stop movement — yours and the Enemies' — and they are drawn on the
board. A Flying Unit ignores them when moving, and cannot be hit by melee.

## Aiming at ground

A card aimed at a tile — *all units within 2 of target tile* — enters aiming:
tap a tile, see the area lit and who it would catch, then **Confirm**. Nothing
happens until you do. An area effect hits friend and foe alike.

## Holding fire

A Unit whose card grants **Suppressive Fire** can hold fire from its panel,
if it has not moved this turn. It pays the Action's Energy at once and shoots
the first Enemy that moves within range and sight during the Enemy turn; the
Enemy takes the shot and carries on. An unused hold lapses when the Enemy turn
ends. A **Pinned** Enemy is always hit by the shot.

## The Enemy turn

Each Enemy moves and acts on one tap, and stays ringed afterwards, so you can
follow who did what before moving on.

## Waves

Enemies arrive in **six waves**. Each wave fills every Enemy Spawn Tile on the
Floor, and each tile draws an Enemy of its own Skull Level — set in the POI
Sandbox with the Spawn level tool. The next wave arrives when the current one is
cleared, or when the wave timer runs out.

Every spawn can also produce something worse. For each District you have
cleared, there is a 3% chance — up to 15% — of an Elite or a Mini-Boss arriving
in place of the drawn Enemy, whatever the tile's Level. The log says when it
happens.

The pile is counted. When it runs out, no more Enemies arrive.

The Combat is **won** when every Enemy is down and nothing more can come: after
the sixth wave, or sooner if the pile has run dry. It is **lost** only when every
Hero present is Incapacitated — Troops still standing do not keep it alive, and
losing the leader does not end it while another Hero stands.

## Loot

Each Enemy drops Aether shards and components as it goes down, and the log says
what fell. What drops depends on its kind, its Skull Level and its **Salvage**,
set in the Card Forge. A friendly Unit that moves onto a **Loot Tile** or a
**Locked Chest** (a symbol whose text is LC, or LC3 for three components) takes
what is there, once.

The haul so far shows beside the round. A fight you set up here is
**practice**: winning it shows what would have dropped, floor reward and all,
but keeps nothing (Dev Mode keeps it, for testing). Loot you keep comes from
deployments on the World Map. The Loot Guide has the numbers.

Now and then a **blueprint or chassis** drops too. The log says so, but keeps a
blueprint you have not found before unnamed until the fight is won. A floor's
reward can hold one as well. Designs from the Workshop can be deployed like any
other Troop card. The Workshop and Codex Guide has the details.

## Deployment fights

A fight on a deployment opens here from the World Map. It's already set up
with:

- **The floor** from the POI or ambush.
- **The District and Skull Level** from the tile.
- **The Strike Team** as it stands, with fallen Heroes and lost Troop copies
  left out, and any pre-built copies bought at the dock on top of its Deck.
- **What was packed**: every packed Prototype, and the packed Consumables.
  The Prototypes and Consumables steps offer only what's packed, and a
  Consumable used in the fight is gone for good.

Setup asks only who enters and who leads, and the Starting Troops:

- **Enemies spawn at the tile's Skull Level.** A spawn tile painted higher on
  its floor stays that much higher.
- **Enemies come from the tile's District**, or from any District when it has
  none at that level.

On a POI floor, a Hero stepping onto an **EX** symbol (an Emergency Exit) takes
the team out of the POI there and then.

The result says what went into the haul and what comes next:

- **Next floor**, inside a POI.
- **Back to the map.**
- **Retry with reserves**, when a Hero still stands.
- **Deployment lost**, a wipe. It lists what was lost, packed items
  included, and what Salvage insurance kept, if the dock has it.

The World Map Guide has the rules.

## Auto battle

**Auto** gives each of your Units up to three Behavior keywords and plays the
whole fight out. Both sides follow their keywords, which is what makes the
result worth anything.

Keywords come in three kinds — one that chooses targets, one that decides
movement, one that sets a role — and a set worth keeping can be **saved as a
named preset** and applied to any Unit.

A keyword with a condition outranks one without, so a Unit that is *Wary 2,
Prudent 5* kites while healthy and withdraws once it drops to 5 Health.

On Auto a Hero pays the Aether a carried Action card costs (at X = 1 if its
cost is variable), or doesn't use it, and a Burst makes all of its attacks. A
Unit left standing on a Loot Tile or a Locked Chest finds what is there. A
Stunned Unit loses its turn, on either side.

Auto plays whole rounds (v13.5): after the Enemies, the next wave arrives if it
is due, Heroes generate Aether, Chips and cards are drawn, and Statuses tick,
exactly as when you tap **Next** through the phases yourself. Cards in your hand
are not played for you.

While Auto plays, its button reads **Take over**. Tap it and the fight comes back
to you at the start of the next round, so choosing Auto never locks you in.

## Undo

Every move, attack, card and Consumable can be taken back, and the button says
what it would revert. A whole Enemy phase undoes as one step, because ending
your turn was one decision however many Enemies acted on it.

With Manual dice you could undo an attack and roll it again. The Simulator does
not stop you — it is a place to try things — but it is worth knowing you are
doing it.

## What it does not do

It does not model line of sight, Tokens spawning beside their parent, or the
Aether Chips' own effects. Those are on the list. Where it cannot read a card's
text it logs the text for you rather than guessing.
