/* The keywords decided after the 14.10 effect box audit (Revision 16.3, proposed).
   Written in keywords.js's own shape, so they can be dropped into its KEYWORDS
   list when the build comes. Until then the audit's checks add them for themselves. */
var NEW_KEYWORDS=[
  /* decision 1: narrowing words for the two kinds of your Units */
  {name:"Troop", cat:"target", narrow:"cardtype", num:null, weight:0, desc:"Narrows a Target to Troops. Every Troop is a mechanical robot, so this is how a card names Mechanical Units."},
  {name:"Hero",  cat:"target", narrow:"cardtype", num:null, weight:0, desc:"Narrows a Target to Heroes."},
  /* decision 3 */
  {name:"gain Aether", cat:"effect", num:"amount", numLabel:"Aether", weight:2,
   desc:"Gains that much Aether of the card's own District, or Neutral Aether if the card has none. Nothing on an Enemy's card."},
  /* decision 4: everyone on one side, wherever they stand */
  {name:"all allies",  cat:"target", num:null, weight:1, desc:"Every friendly Unit on the Battlefield. Counted like an area of 4 tiles (x3) for its power."},
  {name:"all enemies", cat:"target", num:null, weight:1, desc:"Every Enemy on the Battlefield. Counted like an area of 4 tiles (x3) for its power."},
  /* decision 5 */
  {name:"Aim", cat:"stats", num:"signed", numLabel:"Amount (+ or −)", weight:2,
   desc:"The Unit's ranged attacks need that much less to hit (more when negative): the mirror of Evasive. It must carry a Duration."},
  /* decision 6 */
  {name:"Draw", cat:"effect", num:"amount", numLabel:"Cards", weight:2,
   desc:"Draws that many cards from your Deck into your hand. Nothing on an Enemy's card."},
  /* decision 7 */
  {name:"Hardened", cat:"status", num:"amount", numLabel:"Damage stopped",
   desc:"Each hit on this Unit deals the number less damage, never below 1. It lasts as long as its Duration — 1 turn if none is given — at full strength, then ends. A second dose adds its strength and its turns."},
  /* decision 9 */
  {name:"Barricade", cat:"effect", num:"what", numLabel:"Half or Full", weight:3,
   desc:"Puts a Half or Full Cover Barricade on the target tile, which must be empty. It stays for the rest of the fight."},
  /* decision 10 */
  {name:"Line", cat:"modifier", num:"amount", numLabel:"Tiles", weight:4,
   desc:"Hits every Unit on the tiles running straight from the attacker through the target, that many tiles long, friend or foe, for full damage."},
  {name:"Cone", cat:"modifier", num:"amount", numLabel:"Tiles", weight:4,
   desc:"Hits every Unit in the wedge widening from the attacker toward the target, that many tiles deep, friend or foe, for full damage."}
];
if(typeof module!=="undefined") module.exports=NEW_KEYWORDS;
