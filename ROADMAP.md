# Roadmap

What's planned beyond the work in hand, so it isn't lost between sessions.

## Done

- **KETER Lab** (1 Nov 2026): an experimental build that installs beside KETER
  (com.keter.game.lab), for the simpler card systems chosen 31 Oct 2026, in the game
  and in the Companion (the Lab switch, in Dev Mode):
  1. an ability library (fixed abilities with tiers I, II and III) in place of free keyword sentences;
  2. Workshop modules: a player's Troop is a chassis plus modules from the library;
  3. stats from a table (role and size; Enemies by Skull Level) rather than typed;
  5. a core of about 30 keywords, the long tail folded in;
  6. one job per card type, and a limit on entries (units 3, a Mini-Boss 4).

  Not chosen: one cost number (4), and a simpler hit roll (7).

  The Lab set (game/data/lab_set.json, lab/make_lab_set.js) rebuilds the master
  cards; the systems' tables are lab/spec_data.py (written out by
  lab/make_lab_systems.py), tuned by the balance lab to L4.

## Next, once KETER Lab has been played

- The calls made in the Lab set: its merges, the Mythic's cost, Volt-Warden Ryska's
  Leadership, the abilities that left cards.
- Skull 6 POIs below target on both sets (the Titans' paired tier III attacks).
- Workshop module designs in fights.
- Whether the Lab systems replace today's in KETER itself.

(Fights from Skull 3 run 9-15 rounds on both sets, longer than the lab's 5-9 target:
that is fine for the harder levels, decided 1 Nov 2026.)

## Later

- **The KETER Companion as an Android app (APK)**. A side project for a later time,
  noted 31 Oct 2026.
