"""The menus' icons (0.15), 16 x 16 as icons.py draws them: Aether shards, the
three kinds of parts (shown large on the dock's tiles), the Skull Level and
the gear that opens Options. The Health, Armour, Movement, Energy and Aether
icons stay as the game draws them."""
from icons import icon

UI_ICONS = {}

UI_ICONS["shards"] = icon([
    "................",
    "........a.......",
    ".......aba......",
    "......abcba.....",
    "..a...abcba.....",
    ".aba..abcbba....",
    ".abba.abccba....",
    ".abcba.abcba..a.",
    "..abcbaabcba.aba",
    "..abccbabcbaabba",
    "...abcbabcbabcba",
    "...abccbbcbabcba",
    "....abcbbccbbca.",
    ".....abbbbbbba..",
    "......aaaaaaa...",
    "................",
], {"a": "2c3b39", "b": "59cf93", "c": "d0ffea"})

UI_ICONS["part_troop"] = icon([
    "................",
    "......aaaa......",
    "...aa.abba.aa...",
    "..abbaabbaabba..",
    "..abbbbbbbbbba..",
    "...abbcccccba...",
    ".aabbcddddcbbaa.",
    ".abbbcdeedcbbba.",
    ".abbbcdeedcbbba.",
    ".aabbcddddcbbaa.",
    "...abbcccccba...",
    "..abbbbbbbbbba..",
    "..abbaabbaabba..",
    "...aa.abba.aa...",
    "......aaaa......",
    "................",
], {"a": "27412d", "b": "59cf93", "c": "42a459", "d": "171819", "e": "97edca"})

UI_ICONS["part_equipment"] = icon([
    "................",
    "..aaaaaaaaaaaa..",
    ".abbbbbbbbbbbba.",
    ".abcbbbbbbbbcba.",
    ".abbbbbbbbbbbba.",
    ".abbddddddddbba.",
    ".abbdeeeeeedbba.",
    ".abbdeeeeeedbba.",
    ".abbdeeeeeedbba.",
    ".abbdeeeeeedbba.",
    "..abbddddddbba..",
    "..abbbbbbbbbba..",
    "...abcbbbbcba...",
    "....abbbbbba....",
    ".....aaaaaa.....",
    "................",
], {"a": "724b2c", "b": "d6a851", "c": "fff089", "d": "b47538", "e": "efdd91"})

UI_ICONS["part_aether"] = icon([
    "................",
    "......aaaa......",
    ".....abccba.....",
    "....aabbbbaa....",
    "....adddddda....",
    "....adeeeeda....",
    "....adeffeda....",
    "....adeffeda....",
    "....adeeeeda....",
    "....adeffeda....",
    "....adeffeda....",
    "....adeeeeda....",
    "....adddddda....",
    "....aabbbbaa....",
    ".....aaaaaa.....",
    "................",
], {"a": "1b2447", "b": "8aa1f6", "c": "f1f2ff", "d": "4572e3", "e": "8aa1f6", "f": "c9d4fd"})

UI_ICONS["skull"] = icon([
    "................",
    ".....aaaaaa.....",
    "....abbbbbba....",
    "...abbbbbbbba...",
    "...abbbbbbbba...",
    "...abccbbccba...",
    "...abccbbccba...",
    "...abbbbbbbba...",
    "....abbccbba....",
    ".....abbbba.....",
    ".....abcbca.....",
    ".....abbbba.....",
    "......aaaa......",
    "................",
    "................",
    "................",
], {"a": "886e6a", "b": "e8dcc4", "c": "171516"})

UI_ICONS["gear"] = icon([
    "................",
    "......aaaa......",
    "...aa.abba.aa...",
    "..abbaabbaabba..",
    "..abbbbbbbbbba..",
    "...abbbaabbba...",
    ".aabbaa..aabbaa.",
    ".abbba....abbba.",
    ".abbba....abbba.",
    ".aabbaa..aabbaa.",
    "...abbbaabbba...",
    "..abbbbbbbbbba..",
    "..abbaabbaabba..",
    "...aa.abba.aa...",
    "......aaaa......",
    "................",
], {"a": "88a3bc", "b": "dceaee"})

if __name__ == "__main__":
    from kart import sheet, preview_path
    names = list(UI_ICONS)
    sheet([UI_ICONS[n] for n in names], preview_path("ui_icons.png"), scale=6, labels=names, cols=6)
    print("ok")
