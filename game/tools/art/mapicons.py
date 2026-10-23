"""What a World Map tile holds (0.15), as 16x16 icons the game sets on a dark
plate in the icon's colour: a POI, a Unique POI, an Ambush, a Cache and an
Event. Each is an ASCII picture as in icons.py, with its dark outline."""
from icons import icon

MAP_ICONS = {}
# the plate's rim, by what the tile holds (the game draws the plate)
PLATE = {"poi": "d6a851", "unique": "f8e398", "ambush": "ff2a3c", "cache": "59cf93", "event": "42bfe8"}

MAP_ICONS["poi"] = icon([
    "................",
    "................",
    ".......aa.......",
    "......abba......",
    ".....abccba.....",
    "....abccccba....",
    "...abbbbbbbba...",
    "...accccccccb...",
    "...acddccddcb...",
    "...acddccddcb...",
    "...accccccccb...",
    "...acceeeeccb...",
    "...acceffeccb...",
    "...acceffeccb...",
    "...bbbbbbbbbb...",
    "................",
], {"a": "fff089", "b": "b47538", "c": "d6a851", "d": "0e0c0c", "e": "724b2c", "f": "f8c53a"})

MAP_ICONS["unique"] = icon([
    "................",
    ".......aa.......",
    ".......ab.......",
    "......aabb......",
    "......abbb......",
    "aaaaaaabbbbbbbbb",
    ".abbbbbcbbbbbbb.",
    "..abbbbccbbbbb..",
    "...abbbccbbbb...",
    "....abbbbbbb....",
    "....abbbbbbb....",
    "...abbbbbbbbb...",
    "...abbb...bbb...",
    "..abb.......bb..",
    "..ab.........b..",
    "................",
], {"a": "fcf7be", "b": "f8c53a", "c": "fff089"})

MAP_ICONS["ambush"] = icon([
    "................",
    ".......aa.......",
    "......abba......",
    "......abba......",
    ".....abccba.....",
    ".....abccba.....",
    "....abbccbba....",
    "....abbccbba....",
    "...abbbccbbba...",
    "...abbbccbbba...",
    "..abbbbbbbbbba..",
    "..abbbbccbbbba..",
    ".abbbbbccbbbbba.",
    ".abbbbbbbbbbbba.",
    ".bbbbbbbbbbbbbb.",
    "................",
], {"a": "ff2a3c", "b": "b81418", "c": "f1f2ff"})

MAP_ICONS["cache"] = icon([
    "................",
    "................",
    "................",
    "...aaaaaaaaaa...",
    "..abbbbbbbbbbc..",
    "..addddddddddc..",
    "..abbbbbbbbbbc..",
    "..abbbbeebbbbc..",
    "..abbbbffbbbbc..",
    "..abbbbbbbbbbc..",
    "..addddddddddc..",
    "..abbbbbbbbbbc..",
    "..abbbbbbbbbbc..",
    "...cccccccccc...",
    "................",
    "................",
], {"a": "9eb280", "b": "65735a", "c": "3c4a3a", "d": "d6a851", "e": "fff089", "f": "b47538"})

MAP_ICONS["event"] = icon([
    "................",
    ".....aaaaa......",
    "....abbbbba.....",
    "...abbccbbba....",
    "...abba..abba...",
    "...ccc...abba...",
    ".........abba...",
    "........abbc....",
    ".......abbc.....",
    "......abbc......",
    "......abba......",
    "......cccc......",
    "................",
    "......aaaa......",
    "......abba......",
    "......cccc......",
], {"a": "c9d4fd", "b": "42bfe8", "c": "2789cd"})

if __name__ == "__main__":
    from kart import sheet, preview_path
    names = list(MAP_ICONS)
    sheet([MAP_ICONS[n] for n in names], preview_path("map_icons.png"), scale=6, labels=names, cols=5)
    print("ok")
