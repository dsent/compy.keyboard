-- Exercise 5: Words and phrases. The child types whole lines of
-- silly words, left to right, on the live-case keyboard
-- (untimed). Words are order-2 Markov gibberish (markov.lua)
-- built from a bundled Alice chapter at first entry. A single-
-- line phrase strip shows the target: completed characters
-- green, the current one in a pale highlight box, the rest at
-- rest; a space is a blank cell the cursor steps over. Typing
-- strict left to right with no buffer. Each correct key gives a
-- soft tick, a wrong key a dull knock (not accepted). The count
-- gauge fills one notch per WORD typed cleanly (no wrong key in
-- it); G clean words open the level-up screen; Tab climbs the
-- rung (rung = notch 0..4), the top rung loops a review.
-- Capitals arrive at rung 3, punctuation at rung 4. Words has
-- no per-glyph learning table (its content is freshly
-- generated), so it drives this small count rather than
-- gauge.lua, but reuses the win gauge, level-up screen, pastel,
-- firework, and exit hint of the find-key core.
dofile("words_corpus.lua")
dofile("markov.lua")

WORDS = {
  line = "", pos = 1, hits = 0, goal = 0,
  phase = "play", event = nil, wordClean = true,
  burst = nil, fw = { }, pulse = 0
}
WORDS_CFG = { id = "words", lo = WORDS_LO, hi = WORDS_HI }

function wordsRung()
  return notchGet("words")
end

-- Max line length (chars) that fits REF_W at the strip font,
-- measured by the widest lowercase glyph so any line fits.
function wordsCap()
  local font = getFont(WORDS_STRIP_PX)
  local avail = REF_W - 2 * WORDS_STRIP_MARGIN
  return math.floor(avail / font:getWidth("m"))
end

-- Red-rung punctuation: a comma after a middle word about half
-- the time, and a terminal period. Operates on the joined line.
function wordsPunctuate(p)
  local words = { }
  for w in p:gmatch("%S+") do words[#words + 1] = w end
  if #words >= 3 and love.math.random(1, 2) == 1 then
    local i = love.math.random(1, #words - 1)
    words[i] = words[i] .. ","
  end
  words[#words] = words[#words] .. "."
  return table.concat(words, " ")
end

-- Clean words still needed to fill the gauge.
function wordsRemaining()
  return WORDS.goal - WORDS.hits
end

-- Words for the next line: the rung's random count, but never
-- more than the clean words still needed, so a full line never
-- overshoots the goal mid-typing. The final line is exactly the
-- remaining count (regenerated after a fumble), so a shown line
-- is always finished before the level ends.
function wordsLineWords(cfg)
  local k = love.math.random(cfg.k, cfg.kmax)
  local rem = wordsRemaining()
  if rem < k then k = rem end
  if k < 1 then k = 1 end
  return k
end

-- Assemble a rung's line: k words sized to the gauge (above);
-- rungs 3-4 capitalize the first letter; rung 4 also adds
-- punctuation.
function wordsAssemble(cfg)
  local k = wordsLineWords(cfg)
  local p = markovPhrase(k, cfg.lmin, cfg.lmax)
  if cfg.caps then
    p = p:sub(1, 1):upper() .. p:sub(2)
  end
  if cfg.punct then
    p = wordsPunctuate(p)
  end
  return p
end

-- One line for the current rung, regenerated (then trimmed as a
-- last resort) so it never overflows the strip width.
function wordsMakeLine()
  local cfg = WORDS_RUNGS[wordsRung()]
  local cap = wordsCap()
  local p = wordsAssemble(cfg)
  local tries = 0
  while #p > cap and tries < 8 do
    p = wordsAssemble(cfg)
    tries = tries + 1
  end
  if #p > cap then p = p:sub(1, cap) end
  return p
end

function wordsNewLine()
  WORDS.line = wordsMakeLine()
  WORDS.pos = 1
  WORDS.wordClean = true
end

function wordsStartLevel()
  WORDS.hits = 0
  WORDS.goal = WORDS_G[wordsRung()]
  WORDS.event = nil
  WORDS.phase = "play"
  WORDS.wordClean = true
  wordsNewLine()
end

function wordsEnter()
  notchEnterReset("words")
  markovBuild()
  WORDS.burst = nil
  WORDS.fw = { }
  WORDS.pulse = 0
  pastelLevel(wordsRung())
  pastelSnap()
  wordsStartLevel()
end

function wordsUpdate(dt)
  WORDS.pulse = WORDS.pulse + dt
  fwUpdate(WORDS, dt)
  if WORDS.burst then
    WORDS.burst.t = WORDS.burst.t - dt
    if WORDS.burst.t <= 0 then WORDS.burst = nil end
  end
end

function wordsDone()
  return WORDS.phase == "done"
end

function wordsExpected()
  return WORDS.line:sub(WORDS.pos, WORDS.pos)
end

-- The physical key a target glyph is produced on: space for a
-- space, a letter's lowercase key, a shifted symbol's unshifted
-- key, else the glyph itself.
function wordsBaseKey(ch)
  return glyphBaseKey(ch)
end

-- The gauge filled: celebrate and show the level-up screen.
function wordsWin()
  if wordsRung() >= WORDS_HI then
    WORDS.event = "win"
  else
    WORDS.event = "levelup"
  end
  WORDS.phase = "done"
  fkCelebrate(WORDS)
end

-- A finished word: a clean one (no wrong key) fills the gauge
-- by one; either way reset clean for the next word. The level
-- ends at a LINE boundary (wordsEndLine), never mid-word.
function wordsScoreWord()
  if WORDS.wordClean then
    WORDS.hits = WORDS.hits + 1
  end
  WORDS.wordClean = true
end

-- A word completes when the just-typed char was the last non-
-- space of a token (the next char is a space or the line end).
function wordsCheckWord()
  local prev = WORDS.line:sub(WORDS.pos - 1, WORDS.pos - 1)
  local atEnd = WORDS.pos > #WORDS.line
  local space = WORDS.line:sub(WORDS.pos, WORDS.pos) == " "
  if prev ~= " " and (atEnd or space) then
    wordsScoreWord()
  end
end

-- A correct glyph: a key tick, a burst on its key, advance and
-- green it; score a finished word, and end the line once the
-- whole line is typed (a shown line is always finished first).
function wordsGood()
  local r = keyRect(wordsBaseKey(wordsExpected()))
  if r then
    WORDS.burst = { x = r.x + r.w / 2,
      y = r.y + r.h / 2, t = 0.5 }
  end
  SOUND.match()
  WORDS.pos = WORDS.pos + 1
  wordsCheckWord()
  if WORDS.pos > #WORDS.line then wordsEndLine() end
end

-- The whole line is typed: end the level if the gauge is full
-- (the shown line was finished first), else serve a new line.
function wordsEndLine()
  if WORDS.hits >= WORDS.goal then
    wordsWin()
  else
    wordsNewLine()
  end
end

-- A wrong glyph: a dull knock and no advance; it marks the
-- current word unclean, so that word will not fill the gauge.
function wordsBad()
  SOUND.reject()
  WORDS.wordClean = false
end

-- Printable glyphs are judged here (every Words target is
-- printable). spendGlyph takes one glyph per press and drops
-- the rest, exactly as Alt does: a held key types once.
function wordsTextinput(ch)
  if spendGlyph(wordsBaseKey(ch)) then return end
  if wordsDone() then return end
  local want = wordsExpected()
  if want == "" then return end
  if ch == want then
    wordsGood()
  else
    wordsBad()
  end
end

-- Only an end screen consumes a key: Tab climbs a rung, and at
-- the top rung, where there is nothing new ahead, Enter plays
-- again instead. Play-time keys are judged in textinput, so the
-- non-printing keys (Backspace, Enter, Tab) are ignored during
-- play.
function wordsEndKey(k)
  if fkAtEnd(WORDS, WORDS_CFG) then
    if k == "return" or k == "kpenter" then
      wordsAdvance()
    end
    return
  end
  if k == "tab" then wordsAdvance() end
end

function wordsKeypressed(k)
  if wordsDone() then wordsEndKey(k) end
end

-- Tab on the level-up screen: climb a rung into a fresh level,
-- or (at the top rung) loop another fresh review level.
function wordsAdvance()
  WORDS.fw = { }
  WORDS.burst = nil
  if wordsRung() < WORDS_HI then
    notchShift("words", 1, WORDS_LO, WORDS_HI)
    pastelLevel(wordsRung())
  end
  wordsStartLevel()
end

-- Teacher chord (Ctrl+Alt+up/down): shift the rung, cross-fade
-- the pastel, start a fresh level. A no-op shift is ignored.
function wordsOnNotch(delta)
  local before = wordsRung()
  notchShift("words", delta, WORDS_LO, WORDS_HI)
  if wordsRung() == before then return end
  pastelLevel(wordsRung())
  WORDS.fw = { }
  WORDS.burst = nil
  wordsStartLevel()
end

function wordsNoHint()
  return wordsDone()
end

-- The current character sits in a pale highlight box that reads
-- over every pastel background (the warm ink blended into the
-- orange/red rungs); the glyph itself is drawn dark on top.
function wordsDrawCurrent(x, y, w, h, ch)
  gfx.setColor(COL_KEY)
  gfx.rectangle("fill", x, y - 2, w, h + 4, 3)
  gfx.setColor(COL_KEY_EDGE)
  gfx.rectangle("line", x, y - 2, w, h + 4, 3)
  if ch ~= " " then
    gfx.setColor(COL_TEXT)
    gfx.print(ch, x, y)
  end
end

-- Completed characters are deep green, upcoming ones dark ink;
-- both keep contrast over every pastel, incl. the red top notch
-- (COL_OK green and COL_DIM grey both wash out on red).
function wordsCharColor(i)
  if i < WORDS.pos then return COL_DONE end
  return COL_TEXT
end

-- Draw one strip character at x and return the next x. A space
-- prints nothing but still reserves its cell (and the cursor).
function wordsDrawChar(font, ch, i, x, y)
  local w = font:getWidth(ch)
  if i == WORDS.pos and not wordsDone() then
    wordsDrawCurrent(x, y, w, font:getHeight(), ch)
  elseif ch ~= " " then
    gfx.setColor(wordsCharColor(i))
    gfx.print(ch, x, y)
  end
  return x + w
end

-- The phrase strip: one centered, non-wrapping line in the
-- header band, drawn glyph by glyph for per-character coloring.
function wordsDrawStrip()
  local font = getFont(WORDS_STRIP_PX)
  gfx.setFont(font)
  local x = (REF_W - font:getWidth(WORDS.line)) / 2
  local band = HEADER_Y1 - HEADER_Y0
  local y = HEADER_Y0 + (band - font:getHeight()) / 2
  for i = 1, #WORDS.line do
    x = wordsDrawChar(font, WORDS.line:sub(i, i), i, x, y)
  end
end

function wordsDrawPlay()
  wordsDrawStrip()
  drawWinGauge(fkGauge(WORDS, WORDS_CFG))
  fkDrawExitHint()
end

function wordsDraw()
  local done = wordsDone()
  drawKeyboard({ })
  if not done then wordsDrawPlay() end
  if WORDS.burst then drawBurst(WORDS.burst) end
  drawIndicators(CAPS_STATE.on)
  if done then
    fkDrawEndScreen(WORDS, WORDS_CFG)
  end
  fwDraw(WORDS)
end

registerScene("words", {
  enter = wordsEnter,
  update = wordsUpdate,
  draw = wordsDraw,
  keypressed = wordsKeypressed,
  textinput = wordsTextinput,
  onNotch = wordsOnNotch,
  noHint = wordsNoHint
})
