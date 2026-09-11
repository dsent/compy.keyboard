-- Intro: the typewriter welcome. A passive demonstration the
-- child only watches: a simulated Caps Lock press, then the
-- fixed Latin heading COMPY types itself letter by letter,
-- lighting each bare letter key (honestly uppercase because
-- the demo shows Caps Lock on). Any key snaps the welcome
-- complete and shows Press Enter; Enter opens the menu.

INTRO = { phase = "caps", t = 0, idx = 0, simcaps = false }

function introEnter()
  INTRO.phase = "caps"
  INTRO.t = 0
  INTRO.idx = 0
  INTRO.simcaps = true
  SOUND.typeTick()
end

function introFinish()
  INTRO.idx = #WELCOME.heading
  INTRO.phase = "ready"
  INTRO.simcaps = false
end

function introNextLetter()
  INTRO.idx = INTRO.idx + 1
  INTRO.t = 0
  if INTRO.idx > #WELCOME.heading then
    introFinish()
  else
    SOUND.typeTick()
  end
end

function introTickCaps(dt)
  INTRO.t = INTRO.t + dt
  if INTRO.t >= WELCOME.caps_beat then
    INTRO.phase = "type"
    INTRO.t = 0
    introNextLetter()
  end
end

function introTickType(dt)
  INTRO.t = INTRO.t + dt
  if INTRO.t >= WELCOME.letter_beat then
    introNextLetter()
  end
end

function introUpdate(dt)
  if INTRO.phase == "caps" then
    introTickCaps(dt)
  elseif INTRO.phase == "type" then
    introTickType(dt)
  end
end

-- Any key finishes the typewriter early -- a lone Shift too. A
-- lone Alt does not reach here: appKeypressed filters it, since
-- "alt+*" cannot take a bare Alt press and the chord test it
-- replaced did. The Shift/Alt asymmetry is the game's own and
-- is left as it is, not "fixed" into a second difference.
function introKeypressed(k)
  if INTRO.phase ~= "ready" then
    introFinish()
    return
  end
  if k == "return" or k == "kpenter" then
    gotoScene("menu")
  end
end

function introSpaced(n)
  local out = { }
  for i = 1, n do
    out[#out + 1] = WELCOME.heading:sub(i, i)
  end
  return table.concat(out, " ")
end

function introDeco()
  local deco = { }
  if INTRO.simcaps then
    deco.capslock = { bg = COL_WARM_DIM }
  end
  if INTRO.phase == "type" then
    local c = WELCOME.heading:sub(INTRO.idx, INTRO.idx)
    deco[string.lower(c)] = {
      bg = COL_WARM, glow = COL_GLOW
    }
  end
  return deco
end

-- Welcome text wraps to several lines if needed; the author
-- keeps it short (spec: a short line, no scrolling).
function introWelcomeLines(font)
  return select(2, font:getWrap(STR.welcome, REF_W - 120))
end

function introDrawWelcome(font, top)
  gfx.setFont(font)
  gfx.setColor(COL_DIM)
  gfx.printf(STR.welcome, 60, top, REF_W - 120, "center")
end

-- At the prompt stage the welcome sits above Press Enter only
-- if both fit the status band; otherwise the prompt wins.
function introDrawReady(font, wh, band)
  local lh = font:getHeight()
  if wh + lh <= band then
    introDrawWelcome(font, STATUS_Y0)
  end
  gfx.setFont(font)
  gfx.setColor(COL_TEXT)
  gfx.printf(STR.prompt, 0, STATUS_Y1 - lh, REF_W, "center")
end

function introDrawStatus()
  local font = getFont(FONT_STATUS)
  local wh = #introWelcomeLines(font) * font:getHeight()
  local band = STATUS_Y1 - STATUS_Y0
  if INTRO.phase == "ready" then
    introDrawReady(font, wh, band)
  else
    introDrawWelcome(font, STATUS_Y0 + (band - wh) / 2)
  end
end

function introDraw()
  drawBandText(introSpaced(INTRO.idx), HEADER_BAND,
    getFont(FONT_HEAD), COL_TEXT)
  drawKeyboard(introDeco())
  drawIndicators(INTRO.simcaps or CAPS_STATE.on)
  introDrawStatus()
end

registerScene("intro", {
  enter = introEnter,
  update = introUpdate,
  draw = introDraw,
  keypressed = introKeypressed
})
