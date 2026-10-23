# **Combat Datapad Guide**

The Datapad tracks a fight happening in front of you. It counts, it does not
adjudicate — you decide what is legal and what happens; it remembers the
numbers a table always loses.

## Datapad or Simulator?

The **Combat Datapad** assists a Combat on your table. You move the
Minifigures, you roll the dice, you tell it what happened.

The **Battle Simulator** *is* the Combat — floor, Units, Deck and Aether, with
the Enemies run for you.

Use this one at the table. Use the Simulator when the table is not out. Neither
knows about the other, and nothing carries between them.

## What it is for

Three things get forgotten at a table, every session:

**Instances of damage.** A Unit hit once for seven has taken one instance; hit
seven times for one it has taken seven. Cards can care about the difference, and
nobody tracks it by hand.

**Energy across turns.** Heroes generate Energy each turn and carry over what
they do not spend; Troops reset. Two different rules, both easy to get wrong.

**Status durations.** A two-turn effect applied on round three ends on round
five, and remembering that for six Units at once is what slows a fight down.

## Adding Units

**Add unit** offers your own cards. Pick one and its Health, Energy,
Integrity and Actions all come with it. Hero cards read Energy from
**+NRG**, Troops from their own **NRG** stat. Enemy and Boss cards join the
enemy side; Heroes and Troops join yours.

You can also name a Unit by hand and set its stats with **Stats**. That is what
you want for an Enemy you have not built a card for yet.

**Carries unspent Energy** is ticked for Heroes and clear for Troops, matching
the Handbook. A hand-added Unit starts unticked, so set it if you are tracking
a Hero.

## Damage

Enter a number and press **Hit**. That records one instance, which is the point:
a minus button pressed seven times would record seven instances wrongly.

**Heal** restores up to the Unit's starting Health and tells you what was wasted
at full. **Gain** goes above it, and the bar turns green — healing and gaining
are different things, and only one of them is capped.

When a Unit reaches zero it is marked down. Healing brings it back.

## Actions

An Action from a card appears as a button showing its Energy cost and damage.
Tapping one shows what it does and asks you to confirm, so nothing is spent by
a mis-tap.

If the Action has a number the Datapad can read — damage on the strip, or
"Heals 5" in the text — it offers a target list. The other side is offered first
for an attack, your own for a heal. Pick one and the effect is applied when you
confirm. **Legality is assumed**: if you say it hits, it hits.

An Action you cannot afford is greyed out and the shortfall is spelled out.

## Statuses

**Status** is a dropdown of the keywords the Card Forge defines, plus anything
you have added there. Choosing one shows its definition and asks how many turns
it lasts before applying it — 0 means until you remove it.

The Datapad applies what a status changes:

- **Rooted** and **Stunned** stop movement, and Stunned stops Actions too.
- **Slowed** and **Sundered** lower Movement Speed and Armor Class by their strength.
- **Weakened** lowers the damage a Unit deals.

## Consumables and Prototypes

The Datapad does not hold these for you, because at a table they are cards in
front of you: a **Consumable** is always available at no Aether cost and goes
back to the Loot pile once used, and a **Prototype** is a persistent buff that
is simply true for the whole Combat.

What the Datapad can do is record the result. Use **Heal**, **Gain** or a status
when one of them fires, and the log will show it alongside everything else.

The Battle Simulator does track both, since there are no cards on a table to
look at.

## Enemy Combos

An Enemy's Combo Actions run in strict sequence. The strip shows which is next,
with **Advance** to step through and **Restart** to go back to step one —
which is the rule most often forgotten, because an interrupted Combo starts
again rather than continuing.

**Special…** arms a Special Ability. It overrides the next Combo Action without
advancing the sequence, so the Combo picks up where it left off.

## Turns

**Next turn** does the three things at once: Energy is generated, status
durations count down, and the damage instance counters clear.

## The log

Everything is recorded — every hit, every Action, every status, every turn. The
**⋯** menu shows a summary of the fight and lets you export the log.

That log is worth more than it looks. A run of logged fights tells you how long
combats actually last, what does the killing, and which statuses actually
matter in play — questions you cannot answer from a single session at a table.

**Ending a fight** clears the Units and keeps the log.

## Undo, in the Simulator

The Battle Simulator keeps a snapshot before anything that changes the fight,
so a mis-tap costs a tap rather than the match. The button says what it would
take back.

An Enemy phase undoes as a single step. You ended your turn; that was one
decision, however many Enemies acted on it.

Note that with Manual dice you could undo an attack and roll it again. The
Simulator is a place to try things, so it does not stop you — but it is worth
knowing you are doing it.

## What it does not do

It does not roll dice, check range, or decide whether an Action is legal. It has
no notion of the map. Those are yours; the Datapad is there so you are not also
doing arithmetic.
