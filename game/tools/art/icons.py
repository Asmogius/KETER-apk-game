"""16x16 icons drawn pixel by pixel. Each icon is an ASCII picture: letters are
shades, '.' is empty; a dark outline is added around it."""
import numpy as np
from kart import idx, to_png, sheet, preview_path

OUT = idx("0e0c0c")


def icon(rows, key):
    img = np.zeros((16, 16), np.int32)
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch in key:
                img[y, x] = idx(key[ch])
    solid = img > 0
    out = img.copy()
    for y in range(16):
        for x in range(16):
            if solid[y, x]:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                X, Y = x + dx, y + dy
                if 0 <= X < 16 and 0 <= Y < 16 and solid[Y, X]:
                    out[y, x] = OUT
                    break
    return out


ICONS = {}

ICONS["stunned"] = icon([
    "................",
    "..........aaa...",
    ".........abba...",
    "........abba....",
    ".......abba.....",
    "......abba......",
    ".....abbbbbba...",
    "......aabbba....",
    "........bba.....",
    ".......bba......",
    "......bba....a..",
    ".....ba.....aba.",
    ".....a.......a..",
    "..a.............",
    ".aba............",
    "..a.............",
], {"a": "f8c53a", "b": "fff089"})

ICONS["rooted"] = icon([
    "................",
    ".....aaaaaa.....",
    "....abbbbbba....",
    "....abccccba....",
    "....abccccba....",
    "....abccccba....",
    "....abbbbbba....",
    ".....aaaaaa.....",
    "......dddd......",
    ".....dd..dd.....",
    "....dd.dd.dd....",
    "...dd..dd..dd...",
    "..dd..dddd..dd..",
    ".dd..dd..dd..dd.",
    ".d..dd....dd..d.",
    "................",
], {"a": "724b2c", "b": "b47538", "c": "d6a851", "d": "8c5b3e"})

ICONS["pinned"] = icon([
    "................",
    ".....aaaaaa.....",
    "....abbbbbba....",
    "....abccccba....",
    "....abbbbbba....",
    ".....aaaaaa.....",
    "......abba......",
    "......abba......",
    "......abba......",
    "......abba......",
    "...aaaabbaaaa...",
    "....abbbbbba....",
    ".....abbbba.....",
    "......abba......",
    ".......aa.......",
    "................",
], {"a": "654370", "b": "9c8bdb", "c": "ceaaed"})

ICONS["marked"] = icon([
    "................",
    "......aaaa......",
    "....aa.bb.aa....",
    "...a...bb...a...",
    "..a.........a...",
    "..a..........a..",
    ".a............a.",
    ".abb...cc...bba.",
    ".abb...cc...bba.",
    ".a............a.",
    "..a..........a..",
    "...a........a...",
    "...a...bb...a...",
    "....aa.bb.aa....",
    "......aaaa......",
    "................",
], {"a": "ff7a1a", "b": "fca570", "c": "ffe0b7"})

ICONS["poisoned"] = icon([
    "................",
    ".......a........",
    "......aba.......",
    "......aba.......",
    ".....abbba......",
    ".....abbba......",
    "....abbcbba.....",
    "...abbcccbba....",
    "...abccccbba....",
    "..abbcccccbba...",
    "..abccccccbba...",
    "..abbcccccbba...",
    "...abbccbbba....",
    "....abbbbba.....",
    ".....aaaaa......",
    "................",
], {"a": "27412d", "b": "42a459", "c": "6dff3a"})

ICONS["bleed"] = icon([
    "................",
    ".......a........",
    "......aba.......",
    "......aba.......",
    ".....abbba......",
    ".....abbba......",
    "....abbcbba.....",
    "...abbcbbbba....",
    "...abcbbbbba....",
    "..abbcbbbbbba...",
    "..abbbbbbbbba...",
    "..abbbbbbbbba...",
    "...abbbbbbba....",
    "....abbbbba.....",
    ".....aaaaa......",
    "................",
], {"a": "7e0e0e", "b": "b81418", "c": "f6a2a8"})

ICONS["slowed"] = icon([
    "................",
    "....aaaaaaaa....",
    "....abbbbbba....",
    ".....abbbba.....",
    "......abba......",
    "......acca......",
    ".......ca.......",
    ".......ca.......",
    "......acca......",
    ".....abccba.....",
    "....abccccba....",
    "....abccccba....",
    "....aaaaaaaa....",
    "................",
    "................",
    "................",
], {"a": "485262", "b": "88a3bc", "c": "c9d4fd"})

ICONS["drained"] = icon([
    "................",
    "......aaaa......",
    "....aaaaaaaa....",
    "....a......a....",
    "....a......a....",
    "....a......a....",
    "....a......a....",
    "....a......a....",
    "....a......a....",
    "....a......a....",
    "....abbbbbba....",
    "....abbbbbba....",
    "....aaaaaaaa....",
    "................",
    "................",
    "................",
], {"a": "5a6da6", "b": "2f7bff"})

ICONS["evasive"] = icon([
    "................",
    "................",
    "..aaaaaa........",
    "........aaaa....",
    "....bbbbbb..a...",
    "..........bb.a..",
    "...cccccccc.b.a.",
    "...........c.b..",
    "...cccccccc.b.a.",
    "..........bb.a..",
    "....bbbbbb..a...",
    "........aaaa....",
    "..aaaaaa........",
    "................",
    "................",
    "................",
], {"a": "a69e9a", "b": "cbc6c1", "c": "ffffff"})

ICONS["weakened"] = icon([
    "................",
    ".......aa.......",
    "......abba......",
    "......abba......",
    "......abba......",
    "......abba......",
    ".....aabbaa.....",
    "...aabbbbbbaa...",
    "....aabbbbaa....",
    "......abba......",
    ".......aa.......",
    "................",
    "...cc.......cc..",
    "....cc.....cc...",
    ".....ccccccc....",
    "................",
], {"a": "595757", "b": "a69e9a", "c": "807b7a"})

ICONS["sundered"] = icon([
    "................",
    "...aaaa..aaaa...",
    "...abba..abba...",
    "...abba.abbba...",
    "...abbba.abba...",
    "...abba.abbba...",
    "...abbba.abba...",
    "....abba.bba....",
    "....abb.abba....",
    ".....aba.ba.....",
    "......a.a.......",
    "................",
    "................",
    "................",
    "................",
    "................",
], {"a": "724b2c", "b": "b28b78"})

# Revision 16.3 (game 0.23): Hardened, a riveted plate over plate
ICONS["hardened"] = icon([
    "................",
    "...aaaaaaaaaa...",
    "..abbbbbbbbbba..",
    ".abdbbbbbbbbdba.",
    ".abbbccccccbbba.",
    ".abbcbbbbbbcbba.",
    ".abbcbccccbcbba.",
    ".abbcbcbbcbcbba.",
    ".abbcbcbbcbcbba.",
    ".abbcbccccbcbba.",
    ".abbcbbbbbbcbba.",
    ".abbbccccccbbba.",
    ".abdbbbbbbbbdba.",
    "..abbbbbbbbbba..",
    "...aaaaaaaaaa...",
    "................",
], {"a": "2c3438", "b": "64878c", "c": "afe9df", "d": "d6a851"})

ICONS["half cover"] = icon([
    "................",
    "................",
    "................",
    "................",
    "................",
    "................",
    "................",
    "..aaaaaaaaaaaa..",
    "..abbbbbbbbbba..",
    "..abccccccccba..",
    "..abccccccccba..",
    "..abbbbbbbbbba..",
    "..aaaaaaaaaaaa..",
    "................",
    "................",
    "................",
], {"a": "486859", "b": "5d9b79", "c": "b5e7cb"})

ICONS["full cover"] = icon([
    "................",
    "..aaaaaaaaaaaa..",
    "..abbbbbbbbbba..",
    "..abccccccccba..",
    "..abccccccccba..",
    "..abbbbbbbbbba..",
    "..aaaaaaaaaaaa..",
    "..abbbbbbbbbba..",
    "..abccccccccba..",
    "..abccccccccba..",
    "..abbbbbbbbbba..",
    "..aaaaaaaaaaaa..",
    "................",
    "................",
    "................",
    "................",
], {"a": "2c3b39", "b": "486859", "c": "86c69a"})

ICONS["guarded"] = icon([
    "................",
    "...aaaaaaaaaa...",
    "...abbbbbbbba...",
    "...abccccccba...",
    "...abccccccba...",
    "...abccbbccba...",
    "...abccbbccba...",
    "....abccccba....",
    "....abccccba....",
    ".....abccba.....",
    "......abba......",
    ".......aa.......",
    "................",
    "................",
    "................",
    "................",
], {"a": "2b4e95", "b": "4572e3", "c": "8aa1f6"})

# (0.16) an eye, watching: holding fire, and the Hold fire Action (act_hold is this one)
ICONS["overwatch"] = icon([
    "................",
    "................",
    "......LLLL......",
    "....LLLLLLLL....",
    "...LLWWWWWWLL...",
    "..LWWWIIIIWWWL..",
    ".LWWWIJGJJIWWWL.",
    "LWWWWIJPPJIWWWWL",
    "LWWWWIJPPJIWWWWL",
    ".LWWWIJJJJIWWWL.",
    "..LWWWIIIIWWWL..",
    "...LLWWWWWWLL...",
    "....LLLLLLLL....",
    "................",
    "................",
    "................",
], {"L": "d6a851", "W": "f1ebdb", "I": "b47538", "J": "f8c53a", "P": "0e0c0c", "G": "ffffff"})

# ---- roles
ICONS["role_melee"] = icon([
    "................",
    "............aa..",
    "...........abba.",
    "..........abbba.",
    ".........abbba..",
    "........abbba...",
    ".......abbba....",
    "..aa..abbba.....",
    "..abaabbba......",
    "...abbbba.......",
    "...acbba........",
    "..acacba........",
    ".acca.aa........",
    ".aca............",
    "..a.............",
    "................",
], {"a": "595757", "b": "cbc6c1", "c": "b47538"})

ICONS["role_ranged"] = icon([
    "................",
    "................",
    "................",
    "...........aa...",
    ".aaaaaaaaaabba..",
    ".abbbbbbbbbbbba.",
    ".aaaaaaaaaabba..",
    "...........aa...",
    "................",
    "..cc...cc...cc..",
    "................",
    "................",
    "................",
    "................",
    "................",
    "................",
], {"a": "595757", "b": "cbc6c1", "c": "f8c53a"})

ICONS["role_support"] = icon([
    "................",
    "................",
    "......aaaa......",
    "......abba......",
    "......abba......",
    "..aaaaabbaaaaa..",
    "..abbbbccbbbba..",
    "..abbbbccbbbba..",
    "..aaaaabbaaaaa..",
    "......abba......",
    "......abba......",
    "......aaaa......",
    "................",
    "................",
    "................",
    "................",
], {"a": "27412d", "b": "59cf93", "c": "d0ffea"})

ICONS["role_cyber"] = icon([
    "................",
    "...a..a..a..a...",
    "...a..a..a..a...",
    "..aaaaaaaaaaaa..",
    "..abbbbbbbbbba..",
    "aaabcccccccbaaa.",
    "..abcbbccbbcba..",
    "..abcbccbbbcba..",
    "aaabcbbbccbcbaaa",
    "..abcccccccba...",
    "..abbbbbbbbbba..",
    "..aaaaaaaaaaaa..",
    "...a..a..a..a...",
    "...a..a..a..a...",
    "................",
    "................",
], {"a": "494182", "b": "7864c6", "c": "ceaaed"})

# ---- actions (0.16: drawn again for the side panel's turn strip and End turn)
ICONS["act_move"] = icon([
    "................",
    "................",
    ".........a......",
    ".........aa.....",
    ".........aca....",
    "....aaaaaabca...",
    "....acccccbbca..",
    "....abbbbbbbbba.",
    "....adddddbbda..",
    "....aaaaaabda...",
    ".........ada....",
    ".........aa.....",
    ".........a......",
    "................",
    "................",
    "................",
], {"a": "2b4e95", "b": "8aa1f6", "c": "c9d4fd", "d": "4572e3"})

ICONS["act_attack"] = icon([
    ".......tt.......",
    ".......tt.......",
    "....hhhhhrrr....",
    "...hhhh..rrrr...",
    "..hhh......rrr..",
    "..hh........rr..",
    "..hh........rr..",
    "tth....oo....stt",
    "tth....oo....stt",
    "..rr........ss..",
    "..rr........ss..",
    "..rrr......sss..",
    "...rrrr..ssss...",
    "....rrrsssss....",
    ".......tt.......",
    ".......tt.......",
], {"r": "f1641f", "h": "fca570", "s": "b9451d", "t": "f8c53a", "o": "fff089"})

ICONS["act_hold"] = ICONS["overwatch"]

ICONS["act_end"] = icon([
    "................",
    ".hhhhhhhhhhhhhh.",
    ".bbbbbbbbbbbbbb.",
    "...g........g...",
    "...gw.......g...",
    "....gss..ssg....",
    ".....gssssg.....",
    "......gllg......",
    "......gllg......",
    ".....g.ll.g.....",
    "....g..ll..g....",
    "...g..ssss..g...",
    "...gSSSSSSSSg...",
    ".bbbbbbbbbbbbbb.",
    ".aaaaaaaaaaaaaa.",
    "................",
], {"h": "e2b27e", "b": "b47538", "a": "724b2c", "g": "b8ccd8", "w": "ffffff", "s": "f8c53a", "S": "d6a851", "l": "fff089"})

# ---- Districts
ICONS["district_1"] = icon([
    "................",
    ".....aaaaaa.....",
    "...aabbbbbbaa...",
    "..abbaaaaaabba..",
    "..aba......aba..",
    ".aba........aba.",
    ".aba........aba.",
    ".aba..cccc..aba.",
    ".aba..c..c..aba.",
    ".aba..c..c..aba.",
    ".aba..c..c..aba.",
    ".aba..c..c..aba.",
    ".aaa..cccc..aaa.",
    "................",
    "................",
    "................",
], {"a": "494182", "b": "9c8bdb", "c": "ceaaed"})

ICONS["district_2"] = icon([
    "................",
    "................",
    "................",
    "....aaaaaaaa....",
    "..aabbbbbbbbaa..",
    ".abbbbaaaabbbba.",
    "abbbbaccccabbbba",
    "abbbacddddcabbba",
    "abbbbaccccabbbba",
    ".abbbbaaaabbbba.",
    "..aabbbbbbbbaa..",
    "....aaaaaaaa....",
    "................",
    "................",
    "................",
    "................",
], {"a": "64364b", "b": "d480bb", "c": "f6a2a8", "d": "fad6ff"})

ICONS["district_3"] = icon([
    "................",
    "......aaaa......",
    "..aa..abba..aa..",
    "..abaabbbbaaba..",
    "...abbbbbbbba...",
    "..abbbaaaabbba..",
    "aaabbaccccabbaaa",
    "abbbbaccccabbbba",
    "abbbbaccccabbbba",
    "aaabbaccccabbaaa",
    "..abbbaaaabbba..",
    "...abbbbbbbba...",
    "..abaabbbbaaba..",
    "..aa..abba..aa..",
    "......aaaa......",
    "................",
], {"a": "673931", "b": "e88a36", "c": "271f1b"})

ICONS["district_4"] = icon([
    "................",
    "..a.a.a.a.a.a...",
    ".aaaaaaaaaaaaa..",
    "aabbbbbbbbbbbaa.",
    ".abbbbccbbbbba..",
    "aabbbbccbbbbbaa.",
    ".abbccccccbbba..",
    "aabbccccccbbbaa.",
    ".abbbbccbbbbba..",
    "aabbbbccbbbbbaa.",
    ".abbbbbbbbbbba..",
    ".aaaaaaaaaaaaa..",
    "..a.a.a.a.a.a...",
    "................",
    "................",
    "................",
], {"a": "7e0e0e", "b": "c8624d", "c": "fdc9c9"})

ICONS["district_5"] = icon([
    "................",
    "...........aaa..",
    "........aaabba..",
    "......aabbbbba..",
    ".....abbbbcbba..",
    "....abbbbcbbba..",
    "...abbbbcbbbba..",
    "...abbbcbbbba...",
    "..abbbcbbbbba...",
    "..abbcbbbbba....",
    "..abcbbbbaa.....",
    "..acbbaaa.......",
    ".aca............",
    ".aa.............",
    "................",
    "................",
], {"a": "27412d", "b": "42a459", "c": "97edca"})

ICONS["district_6"] = icon([
    "................",
    ".....aaaaaa.....",
    "...aabbbbbbaa...",
    "..abbbbccbbbba..",
    "..abbbbccbbbba..",
    ".abbbbbccbbbbba.",
    ".acccccccccccca.",
    ".acccccccccccca.",
    ".abbbbbccbbbbba.",
    "..abbbbccbbbba..",
    "..abbbbccbbbba..",
    "...aabbbbbbaa...",
    ".....aaaaaa.....",
    "................",
    "................",
    "................",
], {"a": "1b2447", "b": "2789cd", "c": "c9d4fd"})


# ---- the fight bar's buttons
ICONS["bar_undo"] = icon([
    "................",
    "................",
    "....a...........",
    "...aba..........",
    "..abbaaaaaaa....",
    ".abbbbbbbbbbaa..",
    "..abbaaaaaaabba.",
    "...aba.......aba",
    "....a........aba",
    ".............aba",
    "............abba",
    "....aaaaaaaabbba",
    "....abbbbbbbbba.",
    "....aaaaaaaaaa..",
    "................",
    "................",
], {"a": "485262", "b": "c9d4fd"})

ICONS["bar_auto"] = icon([
    "................",
    ".....aaaaa......",
    "...aabbbbbaa....",
    "..abba...abba.a.",
    ".aba.......abaa.",
    ".aba........aba.",
    "aba....c...abba.",
    "aba...ccc..aaaa.",
    "aba..cc.cc......",
    "aba..ccccc..aaaa",
    ".aa..cc.cc..abba",
    ".a..........aba.",
    "....abba...abba.",
    "....aabbbbbbaa..",
    "......aaaaaa....",
    "................",
], {"a": "485262", "b": "c9d4fd", "c": "f8c53a"})

ICONS["bar_log"] = icon([
    "................",
    "..aaaaaaaaaaa...",
    "..abbbbbbbbba...",
    "..abaaaaaaaba...",
    "..abbbbbbbbba...",
    "..abaaaaaabba...",
    "..abbbbbbbbba...",
    "..abaaaaaaaba...",
    "..abbbbbbbbba...",
    "..abaaaaabbba...",
    "..abbbbbbbbba...",
    "..abaaaaaaaba...",
    "..abbbbbbbbba...",
    "..aaaaaaaaaaa...",
    "................",
    "................",
], {"a": "485262", "b": "c9d4fd"})

ICONS["bar_fit"] = icon([
    "................",
    ".aaaaa....aaaaa.",
    ".abbba....abbba.",
    ".abaa......aaba.",
    ".aba........aba.",
    ".aa..........aa.",
    "................",
    "................",
    "................",
    "................",
    ".aa..........aa.",
    ".aba........aba.",
    ".abaa......aaba.",
    ".abbba....abbba.",
    ".aaaaa....aaaaa.",
    "................",
], {"a": "485262", "b": "c9d4fd"})

ICONS["bar_leave"] = icon([
    "................",
    "..aaaaaaaa......",
    "..abbbbbba......",
    "..ab....ba......",
    "..ab....ba..a...",
    "..ab....ba..aa..",
    "..ab..aaaaaabba.",
    "..ab..abbbbbbbba",
    "..ab..aaaaaabba.",
    "..ab....ba..aa..",
    "..ab....ba..a...",
    "..ab....ba......",
    "..abbbbbba......",
    "..aaaaaaaa......",
    "................",
    "................",
], {"a": "485262", "b": "c9d4fd"})


# ---- the board's small status marks, 8 x 8 (one colour each, an outline)
def mark(rows, colour, lite):
    img = np.zeros((8, 8), np.int32)
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch == "a":
                img[y, x] = idx(colour)
            elif ch == "b":
                img[y, x] = idx(lite)
    solid = img > 0
    out = img.copy()
    for y in range(8):
        for x in range(8):
            if not solid[y, x] and any(0 <= x + dx < 8 and 0 <= y + dy < 8 and solid[y + dy, x + dx]
                                       for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                out[y, x] = OUT
    return out


MARKS = {
    "stunned": mark(["........", "....ab..", "...ab...", "..aaaa..", "...ba...", "..ba....", "........", "........"], "f8c53a", "fff089"),
    "rooted": mark(["........", "..aaaa..", "..abba..", "..aaaa..", "...aa...", "..a..a..", ".a....a.", "........"], "b47538", "d6a851"),
    "pinned": mark(["........", "..aaaa..", "...ab...", "...ab...", ".aaaaaa.", "..aaaa..", "...aa...", "........"], "9c8bdb", "ceaaed"),
    "marked": mark(["........", "..aaaa..", ".a.bb.a.", ".ab..ba.", ".ab..ba.", ".a.bb.a.", "..aaaa..", "........"], "ff7a1a", "fca570"),
    "poisoned": mark(["........", "...a....", "..aba...", "..aba...", ".abbba..", ".aaaaa..", "........", "........"], "42a459", "6dff3a"),
    "bleed": mark(["........", "...a....", "..aba...", "..aaa...", ".aaaaa..", ".aaaaa..", "..aaa...", "........"], "b81418", "f6a2a8"),
    "slowed": mark(["........", ".aaaaaa.", "..abba..", "...aa...", "..abba..", ".aaaaaa.", "........", "........"], "88a3bc", "c9d4fd"),
    "drained": mark(["...aa...", "..aaaa..", "..a..a..", "..a..a..", "..abba..", "..aaaa..", "........", "........"], "5a6da6", "2f7bff"),
    "evasive": mark(["........", ".aaaa...", "......a.", ".bbbb..a", "......a.", ".aaaa...", "........", "........"], "cbc6c1", "ffffff"),
    "weakened": mark(["...aa...", "...aa...", ".aaaaaa.", "..aaaa..", "...aa...", "........", ".bbbbbb.", "........"], "807b7a", "a69e9a"),
    "sundered": mark(["........", ".aa.aa..", ".ab.ba..", ".aab.a..", "..a.aa..", "...a....", "........", "........"], "b28b78", "e1bf89"),
    "hardened": mark(["........", ".aaaaaa.", ".abaaba.", ".aaaaaa.", ".aaaaaa.", ".abaaba.", ".aaaaaa.", "........"], "64878c", "d6a851"),
    "half cover": mark(["........", "........", "........", ".aaaaaa.", ".abbbba.", ".aaaaaa.", "........", "........"], "5d9b79", "b5e7cb"),
    "full cover": mark(["........", ".aaaaaa.", ".abbbba.", ".aaaaaa.", ".abbbba.", ".aaaaaa.", "........", "........"], "486859", "86c69a"),
    "guarded": mark(["........", ".aaaaaa.", ".abbbba.", ".abbbba.", "..abba..", "...aa...", "........", "........"], "4572e3", "8aa1f6"),
    "overwatch": mark(["........", "..aaaa..", ".aabbaa.", "aab..baa", ".aabbaa.", "..aaaa..", "........", "........"], "d6a851", "f8c53a"),
}

# Aether gems, 8 x 8: one per point, in its District's colour (any: white)
GEM = ["........", "...aa...", "..abba..", ".abbbba.", ".abbbba.", "..abba..", "...aa...", "........"]
GEMS = {}
for d, (c, l) in {"1": ("7864c6", "ceaaed"), "2": ("b25266", "f6a2a8"), "3": ("e88a36", "fca570"), "4": ("c8624d", "fdc9c9"),
                  "5": ("42a459", "97edca"), "6": ("2789cd", "c9d4fd"), "any": ("a69e9a", "ffffff")}.items():
    GEMS["gem_" + d] = mark(GEM, c, l)
MARKS.update(GEMS)

if __name__ == "__main__":
    names = list(ICONS)
    sheet([ICONS[n] for n in names], preview_path("icons.png"), scale=5, labels=names, cols=9, show1x=False)
    sheet([MARKS[n] for n in MARKS], preview_path("marks.png"), scale=8, labels=list(MARKS), cols=8, show1x=False)
