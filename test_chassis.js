/* Generated: the test chassis, each built to exercise a different rule. The app adds
   any that are missing; one you have edited is left as you left it. */
window.KETER_TEST_CHASSIS={
 "ch_test_general": {
  "name": "Test Frame · General",
  "district": "",
  "bodyPlan": "Bipedal",
  "powerCap": 12,
  "abilityCap": 2,
  "cost": {
   "troop": 3
  },
  "stats": {
   "hp": 14,
   "ac": 11,
   "move": 4,
   "dmg": 3,
   "nrg": 3,
   "int": 10
  },
  "allowed": [
   "target enemy",
   "target ally",
   "this Unit",
   "damage",
   "heal",
   "turns"
  ],
  "notes": "A plain frame for any District: basic attacks and repairs only.",
  "id": "ch_test_general",
  "test": true,
  "subtypes": [
   "Ranged"
  ],
  "maxRange": 5,
  "bestHit": 5,
  "maxAP": 5,
  "aether": {
   "generic": 1,
   "affinity": 0
  }
 },
 "ch_test_threshold": {
  "name": "Test Frame · Threshold Burst",
  "district": "1",
  "bodyPlan": "Quadcopter",
  "powerCap": 30,
  "abilityCap": 2,
  "cost": {
   "troop": 6
  },
  "stats": {
   "hp": 10,
   "ac": 12,
   "move": 6,
   "dmg": 2,
   "nrg": 4,
   "int": 11
  },
  "allowed": [
   "target enemy",
   "damage",
   "Burst",
   "Pierce",
   "Marked",
   "turns"
  ],
  "notes": "Many light shots: Burst and Pierce, and Marking a target.",
  "id": "ch_test_threshold",
  "test": true,
  "subtypes": [
   "Ranged",
   "Cyber"
  ],
  "maxRange": 7,
  "bestHit": 3,
  "maxAP": 5,
  "aether": {
   "generic": 1,
   "affinity": 1
  }
 },
 "ch_test_verdant": {
  "name": "Test Frame · Verdant Bulwark",
  "district": "5",
  "bodyPlan": "Quadruped",
  "powerCap": 24,
  "abilityCap": 3,
  "cost": {
   "troop": 6
  },
  "stats": {
   "hp": 22,
   "ac": 14,
   "move": 3,
   "dmg": 2,
   "nrg": 3,
   "int": 12
  },
  "allowed": [
   "this Unit",
   "target ally",
   "all allies within",
   "heal",
   "AC",
   "HP",
   "Aura",
   "Evasive",
   "turns",
   "persistent",
   "when",
   "an ally",
   "takes damage",
   "that Unit",
   "while",
   "is below half HP",
   "Support"
  ],
  "notes": "A slow, tough carrier that shelters and repairs its allies.",
  "id": "ch_test_verdant",
  "test": true,
  "subtypes": [
   "Support"
  ],
  "maxRange": 4,
  "bestHit": 6,
  "maxAP": 6,
  "aether": {
   "generic": 2,
   "affinity": 1
  }
 },
 "ch_test_meridian": {
  "name": "Test Frame · Meridian Swarm",
  "district": "6",
  "bodyPlan": "Octopod",
  "powerCap": 16,
  "abilityCap": 1,
  "cost": {
   "troop": 4
  },
  "stats": {
   "hp": 9,
   "ac": 10,
   "move": 5,
   "dmg": 3,
   "nrg": 2,
   "int": 9
  },
  "allowed": [
   "target enemy",
   "damage",
   "AoE",
   "Chain",
   "Burst"
  ],
  "notes": "One ability only, built around the multiplying Modifiers.",
  "id": "ch_test_meridian",
  "test": true,
  "subtypes": [
   "Melee"
  ],
  "maxRange": 6,
  "bestHit": 4,
  "maxAP": 6,
  "aether": {
   "generic": 1,
   "affinity": 1
  }
 },
 "ch_test_lazarus": {
  "name": "Test Frame · Lazarus Siege",
  "district": "4",
  "bodyPlan": "Hexapod",
  "powerCap": 40,
  "abilityCap": 4,
  "cost": {
   "troop": 9
  },
  "stats": {
   "hp": 18,
   "ac": 13,
   "move": 3,
   "dmg": 4,
   "nrg": 5,
   "int": 13
  },
  "allowed": [
   "Rooted",
   "Stunned",
   "Slowed",
   "Marked",
   "Pinned",
   "Poisoned",
   "Bleed",
   "Weakened",
   "Sundered",
   "Drained",
   "Evasive",
   "Overclock",
   "Aura",
   "Half Cover",
   "Full Cover",
   "damage",
   "heal",
   "HP",
   "AC",
   "MS",
   "DMG",
   "INT",
   "Range",
   "AP",
   "NRG",
   "Burst",
   "Push",
   "Pierce",
   "Chain",
   "AoE",
   "Deploy",
   "Sacrifice",
   "Suppressive Fire",
   "Flying",
   "remove",
   "target enemy",
   "target ally",
   "target tile",
   "this Unit",
   "attached Unit",
   "all enemies within",
   "all allies within",
   "all units within",
   "adjacent",
   "the target",
   "an ally",
   "an enemy",
   "any Unit",
   "that Unit",
   "Melee",
   "Ranged",
   "Support",
   "Cyber",
   "District",
   "within",
   "when",
   "if",
   "while",
   "takes damage",
   "deals damage",
   "kills an enemy",
   "is deployed",
   "is Incapacitated",
   "attacks",
   "is attacked",
   "moves",
   "ends its move within",
   "gains",
   "the round begins",
   "is below half HP",
   "is at full HP",
   "has",
   "is within",
   "is further than",
   "turns",
   "persistent",
   "while attached",
   "Archetype"
  ],
  "notes": "Allows every keyword, so the power cap does all the limiting.",
  "id": "ch_test_lazarus",
  "test": true,
  "subtypes": [
   "Ranged"
  ],
  "maxRange": 6,
  "bestHit": 4,
  "maxAP": 7,
  "aether": {
   "generic": 1,
   "affinity": 1
  }
 }
};
