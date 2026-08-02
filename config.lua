-- Keyboard game configuration and shared data tables.
-- Names and sets are copied from the spec data section.

-- Light/paper theme palette (the cross-program standard).
-- Named constants because the 16-color Color[] palette cannot
-- express a paper theme; to be lifted into a shared theme
-- module later.

COL_BG = { 0.93, 0.93, 0.90 }
COL_KEY = { 1.00, 1.00, 0.99 }
COL_KEY_EDGE = { 0.58, 0.58, 0.54 }
COL_KEY_LABEL = { 0.18, 0.18, 0.18 }
COL_WARM = { 1.00, 0.64, 0.10 }
COL_WARM_DIM = { 0.97, 0.85, 0.58 }
COL_GLOW = { 0.95, 0.45, 0.05, 0.75 }
COL_TEXT = { 0.16, 0.16, 0.16 }
COL_DIM = { 0.50, 0.50, 0.48 }
COL_IND_ON = { 0.16, 0.60, 0.32 }
COL_OK = { 0.16, 0.60, 0.32 }

-- Deep "typed" green for the Words phrase strip: keeps contrast
-- on every pastel (including the red top notch), unlike COL_OK.

COL_DONE = { 0.05, 0.32, 0.13 }
COL_RED = { 0.85, 0.30, 0.25 }

-- Soft pink for the brief wrong-key glow (find-key games): a
-- gentle "not that one" marker, less saturated than COL_RED
-- (which Compy reserves for errors) and fainter than the warm
-- target glow.

COL_PINK = { 0.95, 0.52, 0.62, 0.70 }
COL_BURST = { 0.98, 0.50, 0.05 }
COL_OVERLAY = { 0.95, 0.95, 0.92, 0.88 }
COL_GROUND = { 0.55, 0.60, 0.52 }

-- Physical-board cap palette, ported from the original
-- graphics.lua board: black caps, bright-white labels, cyan
-- Fn/Zzz engravings. The caps fit the standard Color[]
-- palette (unlike the paper chrome above).

CAP_BG = Color[Color.black]
CAP_LABEL = Color[Color.white + Color.bright]
CAP_AUX = Color[Color.cyan]

-- Per-notch pastel backgrounds: the Compy palette ramp, mild
-- (green) -> serious (red), indexed by level above an
-- exercise's floor. Hex inlined (paper theme, outside Color[]).
-- L0 #63F5C1 L1 #71E6EF L2 #FFF484 L3 #FF936F L4 #FF6666.

PASTEL_RAMP = { }
PASTEL_RAMP[0] = { 99 / 255, 245 / 255, 193 / 255 }
PASTEL_RAMP[1] = { 113 / 255, 230 / 255, 239 / 255 }
PASTEL_RAMP[2] = { 255 / 255, 244 / 255, 132 / 255 }
PASTEL_RAMP[3] = { 255 / 255, 147 / 255, 111 / 255 }
PASTEL_RAMP[4] = { 255 / 255, 102 / 255, 102 / 255 }
PASTEL_FADE = 0.3

-- Key sets (LOVE key constants).

KEYSETS = { }
KEYSETS.central = {
  "f", "g", "h", "j", "d",
  "k", "s", "l", "a"
}
KEYSETS.numbers = {
  "1", "2", "3", "4", "5",
  "6", "7", "8", "9", "0"
}
KEYSETS.remaining_letters = {
  "q", "w", "e", "r", "t", "y",
  "u", "i", "o", "p", "z", "x",
  "c", "v", "b", "n", "m"
}
-- full_alphabet = every letter (central + remaining), built at
-- load; the Alt exercise reuses it for its lowercase set.

KEYSETS.full_alphabet = { }
for _, k in ipairs(KEYSETS.central) do
  KEYSETS.full_alphabet[#KEYSETS.full_alphabet + 1] = k
end
for _, k in ipairs(KEYSETS.remaining_letters) do
  KEYSETS.full_alphabet[#KEYSETS.full_alphabet + 1] = k
end

-- Letter rows by physical position, for the Press/Find ladder
-- (grow by row), plus the special-key groups the ladder adds at
-- specific notches.

KEYSETS.home_row = {
  "a", "s", "d", "f", "g",
  "h", "j", "k", "l"
}
KEYSETS.bottom_row = {
  "z", "x", "c", "v", "b", "n", "m"
}
KEYSETS.top_row = {
  "q", "w", "e", "r", "t",
  "y", "u", "i", "o", "p"
}
-- The top row in two halves, one per hand, for a ladder that
-- needs a step between "the bottom two rows" and "all of them".

KEYSETS.top_left = { "q", "w", "e", "r", "t" }
KEYSETS.top_right = { "y", "u", "i", "o", "p" }
KEYSETS.press_space = { "space" }
KEYSETS.press_enter_back = { "return", "backspace" }
KEYSETS.press_tab = { "tab" }

-- Fixed menu order (ids). Display labels are localized in
-- locale.lua.

-- Asteroids takes the falling-caps slot Hunt held, and its
-- burning rocks now cross the same sky, so the set is eight
-- games and Hide and Train follow Bubble directly.

MENU_ORDER = {
  "press", "find", "astro", "alt", "words", "bubble",
  "hide", "train"
}

-- Per-game notch at program start. Unlisted games start at 0.
-- The key-set ladder runs one way across the games: notch 0 is
-- the full set, negative notches limit it. A game whose notch
-- also carries speed starts eased; Hide and Train, whose notch
-- carries the key set alone, start at the full set.

NOTCH_START = {
  bubble = -2
}

-- Typewriter welcome timing. The heading is a fixed Latin
-- wordmark (not localized); the beats are slow enough that a
-- child sees each key light and its letter appear together.

WELCOME = {
  heading = "COMPY",
  caps_beat = 0.9,
  letter_beat = 0.6
}

-- Press the key, press-count model. Notch -2..+1 grows the key
-- set by physical row; `add` lists the groups a notch adds on
-- top of the lower notches. Each key is untimed.

PRESS_LO = -2
PRESS_HI = 1
PRESS_NOTCH = { }
PRESS_NOTCH[-2] = { add = { "press_space", "home_row" } }
PRESS_NOTCH[-1] = { add = { "bottom_row" } }
PRESS_NOTCH[0] = { add = { "top_row", "press_enter_back" } }
PRESS_NOTCH[1] = { add = { "numbers", "press_tab" } }

-- A scene game sets the cap on a prop, where it is drawn at one
-- fixed width. Space and the service keys are wide on the real
-- board and are known by that shape, so a fixed-width cap shows
-- space as a blank slab nobody can read. They stay in the
-- keyboard games, which draw the board; the scenes teach the
-- letters and digits, and each scene's own notch table below
-- ladders that set.

-- Press-count learning engine (gauge.lua). G is the review
-- FLOOR: a level needs max(G, its mandatory count) first-try
-- hits, so the gauge always covers every new glyph (the reserve
-- rule) and G only adds review -- correct for any level size,
-- including the 29-key default Press/Find entry. GTOP raises
-- the floor at the top notch. GAUGE_LOWN_BIAS skews selection
-- toward low-press glyphs. All tunable on-device.

PRESS_G = 15
PRESS_GTOP = 25
ALT_G = 30
ALT_GTOP = 45
GAUGE_LOWN_BIAS = 4

-- The falling-caps stream (stream.lua), which Asteroids
-- rides. Caps enter at the top edge and fall until they
-- reach the force field; the y a cap enters at is here, and the
-- line it stops at is the field arc below.

STREAM_SPAWN_Y = -70

-- Progression gauge, counted PER CAP: a clean shot adds 1, a
-- cap reaching the field takes 1 away. Reaching `promote`
-- raises the level a step, or at lmax opens the win screen.
--
-- The gauge stops at EMPTY. A gauge carrying a hidden negative
-- reads as a game that stopped answering: several clean shots
-- move nothing. Caps that reach the field while it is already
-- empty are counted separately instead, and `demote` of them
-- lowers the level; any clean shot clears that count.
--
-- review_hits = the correct presses that retire a key from
-- review. review_p = how often a spawn is drawn from review
-- rather than fresh, and `recent` is how many of the last keys
-- spawned are held back -- together they are what stops a key
-- that just got away coming straight back, over and over.

STREAM_CFG = {
  review_hits = 1,
  review_p = 0.4,
  recent = 4,
  demote = 3
}

-- How far across the canvas a cap may drift on its way down.
-- Ordinary caps come down at a slant, but a much steeper one
-- than a burning rock's, so "falling on the shield" and
-- "crossing past it" still tell each other apart at a glance.

STREAM_DRIFT = 210

-- Fall times (seconds, top edge to the field): the window a
-- child has to find ONE key on a keyboard they cannot read
-- fluently, so they are generous. The sky holds min(level,
-- ncap) rocks; a rock leaving it books its replacement after
-- a pause drawn between dlo and dhi, the spread tightening
-- with the level -- so the fall sets the ceiling on how long
-- a rock may take and the child sets the pace. The notch also
-- sets the level CEILING (lmax) and the `promote` threshold;
-- the floor is always level 1.
-- Caps-to-win is promote * lmax (10/18/28/40/45).
--
-- `danger` is the chance, per ordinary spawn, that a burning
-- rock crosses the sky at that level (stream.lua). Negative
-- notches never see one. At notch 0 the ladder ends on one
-- EXTRA level -- ncap stays put -- where the burning rock
-- debuts as a novelty; the positive notches meet it earlier
-- and end on a level where it is frequent.

STREAM_NOTCH = { }
STREAM_NOTCH[-2] = { fall = 23.0, lmax = 2, ncap = 2,
  promote = 5, dlo = 1.8, dhi = 4.0 }
STREAM_NOTCH[-1] = { fall = 18.0, lmax = 3, ncap = 3,
  promote = 6, dlo = 1.4, dhi = 3.5 }
STREAM_NOTCH[0] = { fall = 16.0, lmax = 4, ncap = 3,
  promote = 7, dlo = 1.0, dhi = 3.0,
  danger = { [4] = 0.12 } }
STREAM_NOTCH[1] = { fall = 11.5, lmax = 5, ncap = 4,
  promote = 8, dlo = 0.75, dhi = 2.5,
  danger = { [3] = 0.10, [4] = 0.12, [5] = 0.25 } }
STREAM_NOTCH[2] = { fall = 8.0, lmax = 5, ncap = 4,
  promote = 9, dlo = 0.6, dhi = 2.0,
  danger = { [1] = 0.08, [2] = 0.10, [3] = 0.12,
    [4] = 0.15, [5] = 0.30 } }

-- The key set by notch, on the shared ladder: notch 0 is the
-- full set and the negative notches limit it by physical row. A
-- notch ADDS its groups on top of the lower ones. The positive
-- notches add no keys -- they raise difficulty through speed
-- and the level ceiling instead.

STREAM_NOTCH[-2].add = { "home_row" }
STREAM_NOTCH[-1].add = { "bottom_row" }
STREAM_NOTCH[0].add = { "top_row" }
STREAM_NOTCH[1].add = { }
STREAM_NOTCH[2].add = { }

-- Alt characters. Press-count engine over produced GLYPHS, not
-- physical keys. Five notches add ~15 new glyphs each, growing
-- alphanumeric -> capitals/punctuation, with the non-printing
-- service keys last. Each notch ADDS a glyph group; the
-- available set is the floor..notch union. The non-printing key
-- targets (Backspace/Tab/Enter, matched via keypressed) live in
-- ALT_KEYTARGET (alt.lua); space is a normal produced glyph.

ALT_LO = 0
ALT_HI = 4

-- Lowercase split 15 + 11 (home-row-first order from
-- full_alphabet); capitals split 5 + 14 + 7; digits 4 + 6.

ALT_LOWER_A = { }
ALT_LOWER_B = { }
for i, k in ipairs(KEYSETS.full_alphabet) do
  if i <= 15 then ALT_LOWER_A[#ALT_LOWER_A + 1] = k
  else ALT_LOWER_B[#ALT_LOWER_B + 1] = k end
end
-- Uppercase A-Z (same order), then split 5 + 14 + 7 by notch.

ALT_UPPER = { }
for _, k in ipairs(KEYSETS.full_alphabet) do
  ALT_UPPER[#ALT_UPPER + 1] = string.upper(k)
end
ALT_UPPER_A = { }
ALT_UPPER_B = { }
ALT_UPPER_C = { }
for i, k in ipairs(ALT_UPPER) do
  if i <= 5 then ALT_UPPER_A[#ALT_UPPER_A + 1] = k
  elseif i <= 19 then ALT_UPPER_B[#ALT_UPPER_B + 1] = k
  else ALT_UPPER_C[#ALT_UPPER_C + 1] = k end
end
ALT_DIGITS_A = { "1", "2", "3", "4" }
ALT_DIGITS_B = { "5", "6", "7", "8", "9", "0" }
ALT_PUNCT_A = { ".", ",", "/" }
ALT_PUNCT_B = { "!", "?", ":" }
ALT_PUNCT_C = { "=", "\\", "[", "]", ";", "'", "-" }
ALT_SPACE = { " " }
ALT_SERVICE = { "return", "backspace", "tab" }

-- Glyph groups by name, unioned into the available set.

ALT_GROUPS = {
  lower_a = ALT_LOWER_A, lower_b = ALT_LOWER_B,
  digits_a = ALT_DIGITS_A, digits_b = ALT_DIGITS_B,
  upper_a = ALT_UPPER_A, upper_b = ALT_UPPER_B,
  upper_c = ALT_UPPER_C, punct_a = ALT_PUNCT_A,
  punct_b = ALT_PUNCT_B, punct_c = ALT_PUNCT_C,
  space = ALT_SPACE, service = ALT_SERVICE
}

-- Notch 0..4, start 0. Notches 0-1 are alphanumeric; capitals
-- and punctuation mix in from notch 2; the service keys land at
-- the top. `groups` are ADDED at that notch.

ALT_NOTCH = { }
ALT_NOTCH[0] = { groups = { "lower_a" } }
ALT_NOTCH[1] = { groups = { "lower_b", "digits_a" } }
ALT_NOTCH[2] = {
  groups = { "digits_b", "punct_a", "space", "upper_a" }
}
ALT_NOTCH[3] = { groups = { "upper_b" } }
ALT_NOTCH[4] = {
  groups = { "punct_b", "punct_c", "upper_c", "service" }
}

-- Shift-hint budget. The first ALT_HINT_FIRST Shift-requiring
-- targets of an entry are hinted (the first is forced to be
-- one); the teacher chord (Ctrl+Alt+H) re-arms ALT_HINT_MORE.

ALT_HINT_FIRST = 4
ALT_HINT_MORE = 3

-- SHIFT_MAP: the symbol a base key makes with Shift held. Used
-- by Alt for symbol targets' base keys and by the live-case
-- keyboard's Shift-gated symbol labels.

SHIFT_MAP = {
  ["1"] = "!", ["2"] = "@", ["3"] = "#", ["4"] = "$",
  ["5"] = "%", ["6"] = "^", ["7"] = "&", ["8"] = "*",
  ["9"] = "(", ["0"] = ")", ["`"] = "~", ["-"] = "_",
  ["="] = "+", ["["] = "{", ["]"] = "}", ["\\"] = "|",
  [";"] = ":", ["'"] = "\"", [","] = "<", ["."] = ">",
  ["/"] = "?"
}

-- Words and phrases (Exercise 5). An order-2 character Markov
-- (markov.lua) over a bundled Alice chapter (words_corpus.lua),
-- the table built at first entry. A low order keeps the words
-- playfully unreal. Rung = notch 0..4: each rung sets the word
-- count k (k..kmax), the per-word length range, whether the
-- line is Capitalized (phrase-initial), and whether it carries
-- punctuation. Lines are multi-word at every rung; the gauge
-- fills one notch per word typed cleanly (no learnable token
-- set -- the per-word count is the whole mechanic). WORDS_G is
-- the clean-word goal per rung.

WORDS_LO = 0
WORDS_HI = 4
MARKOV_ORDER = 2
MARKOV_TRIES = 20
MARKOV_CAP = 28
WORDS_RUNGS = { }
WORDS_RUNGS[0] = { k = 3, kmax = 4, lmin = 3, lmax = 6,
  caps = false, punct = false }
WORDS_RUNGS[1] = { k = 4, kmax = 5, lmin = 3, lmax = 6,
  caps = false, punct = false }
WORDS_RUNGS[2] = { k = 4, kmax = 6, lmin = 3, lmax = 7,
  caps = false, punct = false }
WORDS_RUNGS[3] = { k = 5, kmax = 6, lmin = 3, lmax = 7,
  caps = true, punct = false }
WORDS_RUNGS[4] = { k = 5, kmax = 6, lmin = 3, lmax = 7,
  caps = true, punct = true }
WORDS_G = { }
WORDS_G[0] = 12
WORDS_G[1] = 13
WORDS_G[2] = 14
WORDS_G[3] = 15
WORDS_G[4] = 16

-- Phrase strip: a fixed font size smaller than the keycap
-- target glyph (KCAP_T_BIG = 40) but well above editor body
-- text; the generator caps line length to fit REF_W at this
-- size, with a side margin each edge.

WORDS_STRIP_PX = 26
WORDS_STRIP_MARGIN = 36

-- Blow the bubble. The child HOLDS the target key to inflate a
-- bubble over that key and releases while its edge is inside
-- the ring band. RIPE is the fixed time to reach the inner
-- ring; the notch only narrows the window that follows, so a
-- level asks for a finer release, never a different picture.
-- A hold is slower than a press, so the goals are shorter than
-- the Press ones. All tunable on-device.

BUBBLE_G = 10
BUBBLE_GTOP = 14
BUBBLE_RIPE = 1.0

-- Release windows by notch (seconds after RIPE). The ladder is
-- the Press key ladder, so the notch grows the key set and
-- tightens the window together.

BUBBLE_WINDOW = { }
BUBBLE_WINDOW[-2] = 1.2
BUBBLE_WINDOW[-1] = 0.9
BUBBLE_WINDOW[0] = 0.7
BUBBLE_WINDOW[1] = 0.5

-- Bubble geometry (reference px) and effect timings. R0 is the
-- radius at the moment of the press; RIPE_R the inner ring.

BUBBLE_R0 = 8
BUBBLE_RIPE_R = 52
BUBBLE_RATE = (BUBBLE_RIPE_R - BUBBLE_R0) / BUBBLE_RIPE
BUBBLE_FLY_T = 0.45
BUBBLE_FLY_RISE = 70
BUBBLE_POP_T = 0.3
BUBBLE_POP_GROW = 0.6

-- Scenery palette for the prop games. Kept beside the chrome
-- palette so every color lives in one file; the props
-- themselves are in props.lua.

-- The sky over a scene reads the level as a time of day rather
-- than as the chrome pastel, which would hang a green or yellow
-- sky over green grass. One step per notch of the Press ladder.

SKY_RAMP = { }
SKY_RAMP[0] = { 0.75, 0.89, 0.97 }
SKY_RAMP[1] = { 0.62, 0.83, 0.95 }
SKY_RAMP[2] = { 0.96, 0.87, 0.70 }
SKY_RAMP[3] = { 0.97, 0.71, 0.53 }

-- Deep space over the Asteroids scene: the same idea one notch
-- wider, from a calm night to a hot nebula. Five steps, since
-- the falling-caps games run the full -2..+2 ladder.

SPACE_RAMP = { }
SPACE_RAMP[0] = { 0.09, 0.11, 0.20 }
SPACE_RAMP[1] = { 0.11, 0.10, 0.24 }
SPACE_RAMP[2] = { 0.17, 0.10, 0.26 }
SPACE_RAMP[3] = { 0.24, 0.10, 0.24 }
SPACE_RAMP[4] = { 0.30, 0.10, 0.18 }

-- Asteroids palette: rock, hull, dome, and the lamps that show
-- the charge. A dark lamp is the gun still reloading. EMBER is
-- the charred body of a rock that is already burning, and FLAME
-- the head of the trail it drags.

-- A rock is a ring of flat facets around a black hollow.
-- ROCK_BASE is the facet grey face-on to nothing, ROCK_SPAN is
-- how far the light from ROCK_LIGHT's direction swings it, and
-- ROCK_GRAIN is per-facet noise on top. ROCK_TINT lifts blue a
-- touch so stone reads cold against every sky in the ramp.
-- ROCK_LIT is the grey of blast shards.

-- ROCK_CORE is the cap's own black, exactly: the cap is then
-- invisible as a shape and what a child sees is a letter down
-- in a cavity, which is the whole point. Any value at all
-- above black brings the rectangle back -- 0.13 was enough to
-- draw its every edge.

STAR = { 1, 1, 1 }
ROCK_LIGHT = { -0.55, -0.83 }
ROCK_BASE = 0.50
ROCK_SPAN = 0.16
ROCK_GRAIN = 0.05
ROCK_TINT = 0.04
ROCK_LIT = { 0.65, 0.65, 0.69 }
ROCK_CORE = { 0, 0, 0 }
HULL = { 0.29, 0.56, 0.83 }
DOME = { 0.75, 0.89, 0.98 }
LAMP = { 0.96, 0.77, 0.26 }
LAMP_OFF = { 0.35, 0.33, 0.28 }
BOLT = { 0.95, 0.35, 0.30 }
EMBER = { 0.20, 0.16, 0.16 }
EMBER_LIT = { 0.98, 0.55, 0.12 }
FLAME = { 1.00, 0.93, 0.72 }
SMOKE_TRAIL = { 0.42, 0.38, 0.40 }

-- The win gauge is dark ink over the pale chrome, which sinks
-- into a space background; the space scenes hand it this ink
-- instead. Bright enough to read on the hottest nebula ramp.

GAUGE_SPACE_INK = { 0.86, 0.95, 1.00 }

-- The gauge once it is full and the level is finishing: green
-- and glowing, so "you have it -- clear the sky" is on the same
-- object that was counting.

GAUGE_DONE_INK = { 0.45, 1.00, 0.58 }

-- How long the sky stays up after the last cap is cleared, so
-- the shot that finished the level is seen finishing it.

STREAM_FINISH_HOLD = 0.8

-- Asteroids. The gun reloads after every shot; a blank costs
-- longer than a hit, so hammering every key keeps the gun cold
-- and looking first is the cheaper move. Times are tuned on
-- device.

ASTRO_RELOAD_HIT = 0.35
ASTRO_RELOAD_MISS = 0.9
ASTRO_BOLT_T = 0.18
ASTRO_SHAKE_T = 0.4
ASTRO_SHAKE_PX = 9

-- A rock shot clean comes apart: a flash, its own material
-- thrown outward, and the cap it carried popping over the top
-- so the letter just cleared is the last thing seen.

ASTRO_BLAST_T = 0.45
ASTRO_BLAST_SHARDS = 8

-- A rock that reaches the shield gets a longer one, because its
-- cap has to stay readable while it fades: that letter is the
-- one just booked into review.

ASTRO_IMPACT_T = 0.85

-- Scene geometry in reference pixels. Rocks keep clear of the
-- edges; the ship rides under the force field's apex, so the
-- arc reads as the thing standing between it and the rocks.

STREAM_MARGIN = 40
ASTRO_GROUND_Y = 486
ASTRO_SHIP_U = 5
ASTRO_STARS = 60

-- The force field: a shallow arc across almost the whole width,
-- struck through three points -- (margin, edge y), (centre,
-- apex y), (width - margin, edge y). Those give a circle of
-- radius ~1108 centred ~988 px below the bottom of the screen,
-- so what the screen shows is one slice of a sphere far too big
-- to draw. props.lua derives the centre and radius from these.
-- Tune the ENDPOINT height first: flattening the arc enlarges
-- the sphere but brings the ends UP, which is the opposite of
-- what a rock aimed past the field needs.

FIELD_MARGIN = 20
FIELD_APEX_Y = 420
FIELD_EDGE_Y = 520
FIELD_W = 7
FIELD_GLOW = 16
FIELD_HIT_T = 0.5

-- The notch, carried in the field colour. The space ramp alone
-- reads too subtly on device, so the arc takes the mild ->
-- serious ladder the chrome pastel uses and the background only
-- backs it up. One entry per notch of the -2..+2 ladder.

FIELD_RAMP = { }
FIELD_RAMP[0] = { 0.38, 0.96, 0.66 }
FIELD_RAMP[1] = { 0.36, 0.84, 0.99 }
FIELD_RAMP[2] = { 1.00, 0.90, 0.38 }
FIELD_RAMP[3] = { 1.00, 0.62, 0.28 }
FIELD_RAMP[4] = { 1.00, 0.40, 0.46 }

-- Dangerous Asteroids. Everything Asteroids does, plus burning
-- rocks: a charred, spiked body dragging a flame trail,
-- crossing the screen on a straight diagonal to a point on the
-- far side low enough that it passes OUTSIDE the field. The
-- trail draws the path it is on, so the child can see where it
-- is going; take the flame away and the crossing line still
-- says it.
--
-- One is booked by an ordinary spawn, half a pause behind it,
-- by the notch's per-level `danger` chance -- and only one at
-- a time, aloft or booked (stream.lua).
--
-- Aim y is the band the arc's clearance table settles: at 428
-- to 448 the rock centre clears the arc by 74 to 91 px against
-- its own radius of ~55, which is the "misses, just barely"
-- reading. Aiming lower reaches the field; the bottom corner
-- reaches it from every spawn position, so it is off the table.
-- A hostile rock always starts on the FAR side from the point
-- it is aimed at, so it crosses at least half the width and its
-- line is readable long before it arrives.

DANGER_AIM_LO = 428
DANGER_AIM_HI = 448
DANGER_FAR = 0.55
DANGER_TRAIL = 7
DANGER_TRAIL_GAP = 0.55
DANGER_SPIKES = 9

-- Shooting one knocks it down. It keeps a little of its forward
-- speed, tumbles, and falls onto the very shield it was going
-- to miss -- so what firing at it achieved is on screen a
-- moment later. Gravity is stiff enough that the crash reads as
-- a consequence of the shot rather than a slow drift.

DANGER_CRASH_G = 900
DANGER_CRASH_DRAG = 0.35
DANGER_CRASH_SPIN = 5.0

HILL = { 0.55, 0.72, 0.48 }
GROUND = { 0.45, 0.62, 0.38 }
WOOD = { 0.75, 0.54, 0.29 }
WOOD_DARK = { 0.56, 0.37, 0.18 }
IRON = { 0.18, 0.18, 0.18 }
HUB = { 0.79, 0.79, 0.79 }
BOILER = { 0.84, 0.27, 0.27 }
CAB = { 0.24, 0.42, 0.70 }
CAB_GLASS = { 0.75, 0.85, 0.95 }
RAIL = { 0.42, 0.42, 0.45 }
SLEEPER = { 0.47, 0.36, 0.24 }

-- Sleeper pitch: the track is the busiest prop on a scene, so
-- this is the knob if it ever costs too much.

SLEEPER_GAP = 26
SMOKE = { 0.85, 0.85, 0.85 }

-- Hide and seek. A ROTATION of keys is in play and any of them
-- scores at any moment; only one is shown at a time, peeking
-- from one of the crates. Untimed: the peek cycle drives what
-- is VISIBLE and never expires an answer, so a child may take
-- as long as they want.
--
-- The gauge goal is one unit per correct press, scaled to the
-- rotation, since a bigger rotation is a bigger thing to hold.

HIDE_LO = -2
HIDE_HI = 0
HIDE_G_BASE = 4
HIDE_G_STEP = 2

-- The notch sets three things and nothing else: the peek-cycle
-- timing, the glyph set, and the CEILINGS that progression
-- fills up to. `show` is the seconds a glyph stands out and
-- `away` the empty spell after it hides -- a higher notch
-- shortens the first and lengthens the second, so a level asks
-- for more memory and less looking. `rot` and `box` are the
-- ceilings; `add` is the key-set ladder, full at notch 0.

HIDE_NOTCH = { }
HIDE_NOTCH[-2] = { show = 2.4, away = 0.5, rot = 3, box = 2,
  add = { "home_row" } }
HIDE_NOTCH[-1] = { show = 1.7, away = 0.9, rot = 4, box = 3,
  add = { "bottom_row" } }
HIDE_NOTCH[0] = { show = 1.1, away = 1.4, rot = 5, box = 4,
  add = { "top_row" } }

HIDE_SLIDE = 0.35

-- Scene geometry in reference pixels. Crates stand along a
-- shallow band of ground; a key slides out from behind one of
-- them, leaving HIDE_CAP_LIP of itself covered so it still
-- reads as coming from behind rather than standing free.

HIDE_GROUND_Y = 360
HIDE_BAND = 70
HIDE_MARGIN = 120
HIDE_CRATE_U = 13
HIDE_CAP_H = 84
HIDE_CAP_LIP = 16
HIDE_HIT_T = 0.6
HIDE_MARK_Y = 40

-- Load the train. A cap hovers over the next platform; press it
-- and the cap settles onto the deck as cargo. A full train
-- DEPARTS and an empty one arrives, which is what one unit of
-- the gauge counts. Untimed throughout: the cap waits as long
-- as the child needs, which is what makes this the game for the
-- youngest.

TRAIN_LO = -3
TRAIN_HI = 0
TRAIN_LOAD = 0.4
TRAIN_DEPART = 1.6
TRAIN_ARRIVE = 1.2

-- Progression sets the platform count: level L runs L + 1
-- platforms, up to what the track holds. The notch sets the key
-- set only, full at notch 0, and how many trains a level asks
-- for -- a wider key set wants more trains to cover it. Four
-- notches over three rows, so the top row arrives a hand at a
-- time rather than all at once.

TRAIN_PLAT_MAX = 6
TRAIN_NOTCH = { }
TRAIN_NOTCH[-3] = { trains = 3, add = { "home_row" } }
TRAIN_NOTCH[-2] = { trains = 3, add = { "bottom_row" } }
TRAIN_NOTCH[-1] = { trains = 4, add = { "top_left" } }
TRAIN_NOTCH[0] = { trains = 4, add = { "top_right" } }

-- Scene geometry in reference pixels. The locomotive stands at
-- the left and platforms fill in to its right; TRAIN_PLAT_MAX
-- is the last one whose car still fits the canvas.

TRAIN_GROUND_Y = 404
TRAIN_U = 6
TRAIN_LOCO_X = 96
TRAIN_CAR_GAP = 14
TRAIN_CAP_H = 60
TRAIN_HOVER = 132
TRAIN_HIT_T = 0.5
