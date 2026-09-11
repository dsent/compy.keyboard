-- Parametric Compy keyboard renderer. Reuses the physical key
-- proportions of the original graphics.lua, but fits the
-- keyboard band by a computed scale and origin (no hardcoded
-- 960px path). drawKeyboard(deco) tints/pulses/glows keys via a
-- per-key decoration map; keyRect(name) exposes key geometry.
-- Caps draw in the original board style: black fill, Sarasa
-- labels, the shifted symbol engraved above the base one.

require("utf8")

KB = { scale = 0, x = 0, y = 0, w = 0, h = 0 }
KB.cells = { }
KB.rect = { }

KB_ROWS = { }
KB_ROWS[1] = {
  "escape", "f1", "f2", "f3", "f4", "f5", "f6",
  "f7", "f8", "f9", "f10", "f11", "f12",
  "numlk", "delete"
}
KB_ROWS[2] = {
  "`", "1", "2", "3", "4", "5", "6", "7",
  "8", "9", "0", "-", "backspace"
}
KB_ROWS[3] = {
  "tab", "q", "w", "e", "r", "t", "y",
  "u", "i", "o", "p", "=", "\\"
}
KB_ROWS[4] = {
  "capslock", "a", "s", "d", "f", "g",
  "h", "j", "k", "l", ";", "return"
}
KB_ROWS[5] = {
  "lshift", "\\", "z", "x", "c", "v", "b",
  "n", "m", ",", ".", "/", "up", "rshift"
}
KB_ROWS[6] = {
  "fn", "lctrl", "zzz", "lalt", "pause",
  "space", "menu", "[", "]", "'",
  "left", "down", "right"
}

-- Physical key metrics in millimetres (from graphics.lua).
KB_W_MM = 201.5
KB_STD_W = 15
KB_TOP_W = 12.5
KB_SMALL_W = 11
KB_MED_W = 19
KB_WIDE_W = 23
KB_SPACE_W = 59.5
KB_TOP_H = 11
KB_STD_H = 12.5
KB_GAP_MM = 1.0

-- Per-name width overrides (millimetres).
KB_WMM = { }
KB_WMM.space = KB_SPACE_W
for _, n in ipairs({
  "`", "=", "\\", ";", ",", ".", "/", "up", "rshift"
}) do
  KB_WMM[n] = KB_SMALL_W
end
for _, n in ipairs({ "tab", "lshift" }) do
  KB_WMM[n] = KB_MED_W
end
for _, n in ipairs({ "capslock", "return" }) do
  KB_WMM[n] = KB_WIDE_W
end

-- Original cap engravings (ported from graphics.lua). Digit
-- and punctuation caps print the shifted symbol above the
-- base one; named keys carry their full engraving; letters
-- print uppercase, like the physical keys.

CAP_NUM_SYM = {
  "!", "@", "#", "$", "%",
  "^", "&", "*", "(", [0] = ")"
}
CAP_LOWER, CAP_UPPER = { }, { }
for num, sym in pairs(CAP_NUM_SYM) do
  local n = "" .. num
  CAP_LOWER[n] = n
  CAP_UPPER[n] = sym
end

function capShift(lower, upper)
  CAP_LOWER[lower] = lower
  CAP_UPPER[lower] = upper
end
capShift("`", "~")
capShift("-", "_")
capShift("=", "+")
capShift("\\", "|")
capShift(";", ":")
capShift(",", "<")
capShift(".", ">")
capShift("/", "?")
capShift("[", "{")
capShift("]", "}")
capShift("'", "\"")

-- Original font sizes in millimetres.
CAP_F1 = 5
CAP_F2 = 4
CAP_F3 = 3

-- Board-cap text forms in the original offsets; unit s is
-- pixels per millimetre of the drawn cap.

function capLetter(cell, name, s)
  gfx.setFont(capFont(CAP_F1 * s))
  gfx.print(string.upper(name), cell.x + 2 * s, cell.y + s)
end

function capDouble(cell, name, s)
  gfx.setFont(capFont(CAP_F2 * s))
  gfx.print(CAP_UPPER[name], cell.x + 2 * s, cell.y + s)
  gfx.print(CAP_LOWER[name], cell.x + 2 * s,
    cell.y + (2 + CAP_F2) * s)
end

function capDouble2(cell, name, s)
  gfx.setFont(capFont(CAP_F3 * s))
  gfx.print(CAP_UPPER[name], cell.x + s, cell.y + 2 * s)
  gfx.print(CAP_LOWER[name], cell.x + s,
    cell.y + (3 + CAP_F3) * s)
end

function capSingle(cell, name, s)
  gfx.setFont(capFont(CAP_F3 * s))
  gfx.print(CAP_UPPER[name], cell.x + s, cell.y + 3 * s)
end

function capSpace()
end

-- Fn and Zzz keep their cyan engraving.
function capAux(cell, name, s, a)
  kcapColor(CAP_AUX, a)
  capSingle(cell, name, s)
end

CAP_FORM = { space = capSpace }
for name in pairs(CAP_LOWER) do
  CAP_FORM[name] = capDouble
end

function capKey(name, label)
  CAP_UPPER[name] = label
  CAP_FORM[name] = capSingle
end

function capKey2(name, up, lo)
  CAP_UPPER[name] = up
  CAP_LOWER[name] = lo
  CAP_FORM[name] = capDouble2
end

capKey("escape", "Esc")
capKey("numlk", "Numlk")
capKey("delete", "Delete")
capKey("backspace", utf8.char(10229))
capKey("tab", "Tab " .. utf8.char(8633))
capKey("return", "Enter")
capKey("lshift", utf8.char(8679) .. "Shift")
capKey("rshift", "Shift")
capKey("lctrl", "Ctrl")
capKey("lalt", "Alt")
capKey("menu", utf8.char(9636, 8598))
capKey("fn", "Fn")
capKey("zzz", "Zzz")
capKey("up", utf8.char(8593))
capKey("left", utf8.char(8592))
capKey("down", utf8.char(8595))
capKey("right", utf8.char(8594))
for i = 1, 12 do
  capKey("f" .. i, "F" .. i)
end
capKey2("capslock", "Caps", "Lock")
capKey2("pause", "Pause", "Break")
CAP_FORM.fn = capAux
CAP_FORM.zzz = capAux

-- Can this name be drawn as a cap at all? A named key with a
-- form engraves; a single glyph falls through to capLetter and
-- prints upright. Anything else -- select, printscreen, a name
-- from a keyboard this game knows nothing about -- has no cap,
-- and capLetter would print it straight past the edge.
--
-- This is the test for ECHOING A KEY THE CHILD PRESSED, which
-- must simply not be shown. It is NOT a licence to clamp a cap
-- the game itself chose to present: an unmapped name on a
-- TARGET still has to draw wrong and loud, which is the only
-- reason the stray-key defect was ever noticed. See
-- docs/decisions.md -> invalid-state-renders-visibly.

function capKnown(name)
  if not name then return false end
  if CAP_FORM[name] then return true end
  return #name == 1
end

function kbWidthMM(name, ri)
  local w = KB_WMM[name]
  if w then return w end
  if ri == 1 then return KB_TOP_W end
  if ri == 6 then return KB_SMALL_W end
  return KB_STD_W
end

function kbRowH(ri)
  if ri == 1 then return KB_TOP_H * KB.scale end
  return KB_STD_H * KB.scale
end

function kbComputeScale()
  local total = KB_TOP_H + 5 * KB_STD_H + 5 * KB_GAP_MM
  local sw = 912 / KB_W_MM
  local sh = 340 / total
  KB.scale = math.min(sw, sh)
  KB.w = KB_W_MM * KB.scale
  KB.h = total * KB.scale
  KB.x = (REF_W - KB.w) / 2
  local band = KBAND_Y1 - KBAND_Y0
  KB.y = KBAND_Y0 + (band - KB.h) / 2
end

function kbAddCell(cell)
  KB.cells[#KB.cells + 1] = cell
  if not KB.rect[cell.name] then
    KB.rect[cell.name] = cell
  end
end

function kbPlaceRow(ri, y, h, gap)
  local x = KB.x
  for _, name in ipairs(KB_ROWS[ri]) do
    local w = kbWidthMM(name, ri) * KB.scale
    kbAddCell({ name = name, x = x, y = y, w = w, h = h })
    x = x + w + gap
  end
end

function kbRowSum(ri)
  local sum = 0
  for _, name in ipairs(KB_ROWS[ri]) do
    sum = sum + kbWidthMM(name, ri) * KB.scale
  end
  return sum
end

function kbBuildCells()
  local y = KB.y
  for ri = 1, #KB_ROWS do
    local h = kbRowH(ri)
    local row = KB_ROWS[ri]
    local gap = (KB.w - kbRowSum(ri)) / (#row - 1)
    kbPlaceRow(ri, y, h, gap)
    y = y + h + KB_GAP_MM * KB.scale
  end
end

kbComputeScale()

-- Sarasa Bold, the original board font (a bundled platform
-- asset: the same path graphics.lua loaded). Cached by pixel
-- size, so the board and every enlarged cap share fonts.
CAP_FONT_PATH = "assets/fonts/SarasaGothicJ-Bold.ttf"
CAP_FONTS = { }
function capFont(px)
  px = math.floor(px)
  if not CAP_FONTS[px] then
    CAP_FONTS[px] = gfx.newFont(CAP_FONT_PATH, px)
  end
  return CAP_FONTS[px]
end
-- Top-band target sizing, plus the glyph font for Alt's
-- produced-glyph targets (monospace so 0/O and l/I/1 read
-- clearly). Named-key targets engrave instead (below).
KCAP_T_H = 64
KCAP_T_BIG = getGlyphFont(40)
kbBuildCells()

-- Effective case of letter keycaps: upper iff Caps XOR Shift.
function capsEffectiveUpper()
  if Key.shift() then return not CAPS_STATE.on end
  return CAPS_STATE.on
end

-- Shared keycap renderer. drawKeycap(cell, opts) draws ONE cap
-- at an arbitrary cell { x, y, w, h }: the on-board keys, the
-- top-band target, and Hunt's falling caps all go through it.
-- opts = { name, unit, label, font, bg, glow, halo, color,
-- scale, alpha } is required; its fields are optional. A named
-- board key engraves via the original cap forms (unit = px per
-- mm); an explicit label prints centered and needs a font. glow
-- frames the cap edge, halo radiates outside it. The caller
-- owns cell geometry, layout, and any glow-layering; this draws
-- a single cap.
function kcapColor(c, a)
  gfx.setColor(c[1], c[2], c[3], (c[4] or 1) * a)
end

function kcapLabel(cell, opts, a)
  local label = opts.label
  if not label or label == "" then return end
  local font = opts.font
  gfx.setFont(font)
  kcapColor(opts.color or CAP_LABEL, a)
  local ty = cell.y + (cell.h - font:getHeight()) / 2
  gfx.printf(label, cell.x, ty, cell.w, "center")
end

-- A soft radiance OUTSIDE the cap: concentric frames stepping
-- out, each fainter, so a cap can be marked by class without
-- touching its black face or its engraving (a falling cap the
-- child must skip, or one to catch). Distinct from the glow
-- frame, which sits on the cap edge.

CAP_HALO_LAYERS = 3
CAP_HALO_STEP = 5
CAP_HALO_ALPHA = 0.5

function kcapHaloRing(cell, c, a, i)
  local d = CAP_HALO_STEP * i
  kcapColor(c, a)
  gfx.setLineWidth(CAP_HALO_STEP)
  gfx.rectangle("line", cell.x - d, cell.y - d,
    cell.w + d * 2, cell.h + d * 2)
  gfx.setLineWidth(1)
end

function kcapHalo(cell, c, a)
  for i = 1, CAP_HALO_LAYERS do
    local fade = 1 - (i - 1) / CAP_HALO_LAYERS
    kcapHaloRing(cell, c, a * fade * CAP_HALO_ALPHA, i)
  end
end

-- The glow frame stays: it is the find-target affordance the
-- original board expressed through key_bg fills.
function kcapGlowFrame(cell, opts, a)
  kcapColor(opts.glow, a)
  gfx.setLineWidth(3)
  gfx.rectangle("line", cell.x, cell.y, cell.w, cell.h)
  gfx.setLineWidth(1)
end

-- Named caps engrave via the original forms (opts.color can
-- override the engraving color -- Hunt's state ramp); a bare
-- label (Alt's glyph target) prints centered.
function kcapText(cell, opts, a)
  if opts.name then
    kcapForms(cell, opts, a)
    return
  end
  kcapLabel(cell, opts, a)
end

function kcapForms(cell, opts, a)
  kcapColor(opts.color or CAP_LABEL, a)
  local form = CAP_FORM[opts.name] or capLetter
  form(cell, opts.name, opts.unit, a)
end

-- The cap face, in the original board style: a sharp black
-- fill, no paper outline or corner rounding.
function kcapFace(cell, opts)
  local a = opts.alpha or 1
  if opts.halo then kcapHalo(cell, opts.halo, a) end
  kcapColor(opts.bg or CAP_BG, a)
  gfx.rectangle("fill", cell.x, cell.y, cell.w, cell.h)
  if opts.glow then kcapGlowFrame(cell, opts, a) end
  kcapText(cell, opts, a)
end

function drawKeycap(cell, opts)
  local sc = opts.scale or 1
  local cx = cell.x + cell.w / 2
  local cy = cell.y + cell.h / 2
  gfx.push()
  gfx.translate(cx, cy)
  gfx.scale(sc, sc)
  gfx.translate(-cx, -cy)
  kcapFace(cell, opts)
  gfx.pop()
end

-- On-board key: the original engraved cap, keyed by name;
-- dec carries the per-key bg/glow and the pulse scale.
function drawKey(cell, dec, sc)
  drawKeycap(cell, {
    name = cell.name,
    unit = KB.scale,
    bg = dec and dec.bg,
    glow = dec and dec.glow,
    scale = sc
  })
end

-- A highlighted key (pulse or glow) is redrawn on a top layer
-- so it never z-fights with neighbours drawn after it.
function kbRaised(dec)
  return dec and (dec.pulse or dec.glow)
end

-- Board caps are static engravings, like the physical keys.
function drawKeyboard(deco)
  for _, c in ipairs(KB.cells) do
    drawKey(c, deco and deco[c.name], 1)
  end
  for _, c in ipairs(KB.cells) do
    local dec = deco and deco[c.name]
    if kbRaised(dec) then
      drawKey(c, dec, dec.pulse or 1)
    end
  end
end

function keyRect(name)
  return KB.rect[name]
end

-- Named-key target in the top band: an ENLARGED COPY of the
-- board cap, engraved by the same forms -- so a non-reading
-- child matches pictures, never words. The keyboard picture
-- below carries any glow; this is the calm "what to press"
-- cap.
function kbTargetKeyCell(name)
  local u = KCAP_T_H / KB_STD_H
  local w = (KB_WMM[name] or KB_STD_W) * u
  local band = HEADER_Y1 - HEADER_Y0
  local cell = { }
  cell.x = (REF_W - w) / 2
  cell.y = HEADER_Y0 + (band - KCAP_T_H) / 2
  cell.w = w
  cell.h = KCAP_T_H
  return cell
end

function drawKeycapTarget(name)
  drawKeycap(kbTargetKeyCell(name), {
    name = name,
    unit = KCAP_T_H / KB_STD_H
  })
end

-- A key-hint line: the engraved cap of the key to press, then
-- the hint text, centered together in a y-band. The cap is the
-- picture a non-reading child matches against the board.
KEYHINT_GAP = 12
KEYHINT_PAD = 10

function keyHintCapW(name, h)
  local u = h / KB_STD_H
  return (KB_WMM[name] or KB_STD_W) * u
end

function keyHintX(cw, text, font)
  return (REF_W - cw - KEYHINT_GAP
    - font:getWidth(text)) / 2
end

function drawKeyHint(name, text, band, color)
  local font = getFont(FONT_STATUS)
  local h = font:getHeight() + KEYHINT_PAD
  local cw = keyHintCapW(name, h)
  local x = keyHintX(cw, text, font)
  local y = band[1] + (band[2] - band[1] - h) / 2
  drawKeycap({ x = x, y = y, w = cw, h = h },
    { name = name, unit = h / KB_STD_H })
  gfx.setFont(font)
  gfx.setColor(color)
  gfx.print(text, x + cw + KEYHINT_GAP,
    y + KEYHINT_PAD / 2)
end

-- The same line for a key that needs a modifier held: the caps
-- sit side by side, closer to each other than to the text, so
-- they read as one chord rather than two choices.

function chordHintW(keys, h)
  local w = 0
  for _, name in ipairs(keys) do
    w = w + keyHintCapW(name, h)
  end
  return w + (#keys - 1) * KEYHINT_GAP / 2
end

function chordHintCaps(keys, x, y, h)
  for _, name in ipairs(keys) do
    local w = keyHintCapW(name, h)
    drawKeycap({ x = x, y = y, w = w, h = h },
      { name = name, unit = h / KB_STD_H })
    x = x + w + KEYHINT_GAP / 2
  end
end

function drawChordHint(keys, text, band, color)
  local font = getFont(FONT_STATUS)
  local h = font:getHeight() + KEYHINT_PAD
  local cw = chordHintW(keys, h)
  local x = keyHintX(cw, text, font)
  local y = band[1] + (band[2] - band[1] - h) / 2
  chordHintCaps(keys, x, y, h)
  gfx.setFont(font)
  gfx.setColor(color)
  gfx.print(text, x + cw + KEYHINT_GAP,
    y + KEYHINT_PAD / 2)
end

-- Glyph target cell (Alt): sized from the glyph itself.
function kbTargetCell(label, font)
  local w = font:getWidth(label) + 28
  if w < KCAP_T_H then w = KCAP_T_H end
  local band = HEADER_Y1 - HEADER_Y0
  local cell = { }
  cell.x = (REF_W - w) / 2
  cell.y = HEADER_Y0 + (band - KCAP_T_H) / 2
  cell.w = w
  cell.h = KCAP_T_H
  return cell
end

-- Alt's produced-glyph target: a single glyph on a cap.
function drawTargetCap(label)
  drawKeycap(kbTargetCell(label, KCAP_T_BIG), {
    label = label, font = KCAP_T_BIG
  })
end

-- Expanding-ring success burst, b = { x, y, t } with t in
-- seconds counting down from 0.5.
function drawBurst(b)
  local p = 1 - b.t / 0.5
  local rad = 8 + p * 38
  local a = b.t / 0.5
  gfx.setColor(COL_BURST[1], COL_BURST[2], COL_BURST[3], a)
  gfx.setLineWidth(3)
  gfx.circle("line", b.x, b.y, rad)
  gfx.circle("line", b.x, b.y, rad * 0.55)
  gfx.setLineWidth(1)
end

-- The bang: a blast at a cap the child should not have pressed.
-- An expanding red ring with shards thrown out -- bigger and
-- sharper than the catch burst, so a forbidden press reads as
-- an event, not a near-miss. b = { x, y, t }.

BANG_T = 0.45
BANG_R = 70
BANG_SHARDS = 8
BANG_SHARD_R = 11

function bangShard(b, i, p)
  local ang = (i / BANG_SHARDS) * 2 * math.pi
  local d = BANG_R * (0.4 + p * 0.8)
  gfx.circle("fill", b.x + math.cos(ang) * d,
    b.y + math.sin(ang) * d, BANG_SHARD_R * (1 - p))
end

function drawBang(b)
  local a = b.t / BANG_T
  local p = 1 - a
  kcapColor(COL_RED, a)
  gfx.setLineWidth(4)
  gfx.circle("line", b.x, b.y, BANG_R * p)
  gfx.setLineWidth(1)
  for i = 1, BANG_SHARDS do
    bangShard(b, i, p)
  end
end

-- Subtle win-gauge: a vertical thermometer in the right margin
-- (the left edge is clipped on current hardware), filling
-- bottom-up as the set is cleared. Clear of the bottom hints
-- and the lock cluster. Dark ink reads over every pastel; a
-- scene played against a dark background passes its own light
-- ink instead, so there is one gauge rather than two.
WGAUGE_W = 8

function winGaugeFrac(cleared, total)
  if total <= 0 then return 0 end
  local f = cleared / total
  if f < 0 then return 0 end
  if f > 1 then return 1 end
  return f
end

function winGaugeTrough(c, x, y0, h)
  gfx.setColor(c[1], c[2], c[3], 0.2)
  gfx.rectangle("fill", x, y0, WGAUGE_W, h, 4)
  gfx.setColor(c[1], c[2], c[3], 0.5)
  gfx.setLineWidth(1)
  gfx.rectangle("line", x, y0, WGAUGE_W, h, 4)
end

-- The whole bar is the whole LADDER, not one level of it. A
-- gauge that empties every time a level is cleared reads as
-- progress being taken away; this one keeps climbing, and the
-- ticks say how many rungs there are and which one is under
-- way. g = { fill, of, rung, rungs, ink }.

function winGaugeSpan(g)
  local rungs = g.rungs or 1
  local rung = g.rung or 1
  local within = winGaugeFrac(g.fill, g.of)
  return (rung - 1 + within) / rungs
end

function winGaugeTicks(g, x, y0, h)
  local rungs = g.rungs or 1
  if rungs < 2 then return end
  local c = g.ink or COL_KEY_LABEL
  gfx.setColor(c[1], c[2], c[3], 0.65)
  for i = 1, rungs - 1 do
    gfx.rectangle("fill", x, y0 + h * (1 - i / rungs) - 1,
      WGAUGE_W, 2)
  end
end

-- A gauge that has something to say beyond its reading: three
-- soft frames spreading outward, so it can be noticed without
-- being read.

function winGaugeGlow(g, x, y0, h)
  if not g.glow then return end
  local c = g.ink or COL_KEY_LABEL
  for i = 1, 3 do
    gfx.setColor(c[1], c[2], c[3], 0.13)
    gfx.rectangle("fill", x - i * 4, y0 - i * 4,
      WGAUGE_W + i * 8, h + i * 8, 6)
  end
end

function drawWinGauge(g)
  local f = winGaugeSpan(g)
  local x = REF_W - 16
  local y0 = KBAND_Y0
  local h = KBAND_Y1 - KBAND_Y0
  local c = g.ink or COL_KEY_LABEL
  winGaugeGlow(g, x, y0, h)
  winGaugeTrough(c, x, y0, h)
  gfx.setColor(c[1], c[2], c[3], 0.9)
  gfx.rectangle("fill", x, y0 + h * (1 - f), WGAUGE_W, h * f, 4)
  winGaugeTicks(g, x, y0, h)
end
