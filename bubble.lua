-- Blow the bubble. The shared keyboard marks the target key
-- with a warm cap and a ring band over it; the child HOLDS
-- that key to inflate a bubble and lets go while its edge is
-- inside the band. Letting go early or holding past the band
-- pops it, and the same key returns. Press-count engine
-- (gauge.lua) and scene core (findkey.lua) as in Press: this
-- scene adds only the hold judge and the bubble over the board.
-- The notch tightens the release window and grows the key set
-- together (it rides the Press ladder), so a level asks for a
-- finer release, never a different picture.

BUBBLE = { pulse = 0, burst = nil, wrong = nil, fw = { } }
BUBBLE_CFG = {
  id = "bubble",
  notch = PRESS_NOTCH,
  lo = PRESS_LO,
  hi = PRESS_HI,
  g = BUBBLE_G,
  gtop = BUBBLE_GTOP
}

-- key: the key held right now (nil = nothing inflating); t: how
-- long it has been held; fx: the fly/pop overlay, which runs
-- independently so the next target is live at once.

BUB = { key = nil, t = 0, fx = nil }

function bubbleWindow()
  return BUBBLE_WINDOW[notchGet("bubble")]
end

-- The radius grows linearly, reaching the inner ring at RIPE.

function bubbleRadius(t)
  return BUBBLE_R0 + BUBBLE_RATE * t
end

-- The outer ring: the last moment a release still counts.

function bubbleOuterR()
  return bubbleRadius(BUBBLE_RIPE + bubbleWindow())
end

-- Centre of the cap a bubble grows over.

function bubbleAt(k)
  local r = keyRect(k)
  if not r then return nil, nil end
  return r.x + r.w / 2, r.y + r.h / 2
end

-- The key the band belongs to: the one being held, else the
-- live target.

function bubbleTargetKey()
  if BUB.key then return BUB.key end
  if gaugeGlowing(BUBBLE) then return gaugeCurrent(BUBBLE) end
  return nil
end

function bubbleClear()
  BUB.key = nil
  BUB.t = 0
end

function bubbleEnter()
  bubbleClear()
  BUB.fx = nil
  fkEnter(BUBBLE, BUBBLE_CFG)
end

function bubbleStartFx(kind, life)
  local x, y = bubbleAt(BUB.key)
  BUB.fx = {
    x = x,
    y = y,
    r = bubbleRadius(BUB.t),
    t = life,
    life = life,
    kind = kind
  }
end

-- A release inside the band: the bubble flies off and the gauge
-- advances. The fly overlay stands in for the shared key burst,
-- so one effect marks one success.

function bubbleFly()
  bubbleStartFx("fly", BUBBLE_FLY_T)
  bubbleClear()
  SOUND.match()
  gaugeOnCorrect(BUBBLE, BUBBLE_CFG)
  fkCelebrate(BUBBLE)
end

-- Too early, or held too long. The key itself was right, so
-- this is not the wrong-key path: no pink glow on the board and
-- no knock at the key, just the pop and the gauge fumble, which
-- keeps a new key mandatory and brings it back.

function bubblePop()
  bubbleStartFx("pop", BUBBLE_POP_T)
  bubbleClear()
  SOUND.reject()
  gaugeOnWrong(BUBBLE, BUBBLE_CFG)
end

function bubbleRelease()
  if BUB.t < BUBBLE_RIPE then
    bubblePop()
  else
    bubbleFly()
  end
end

function bubbleGrow(dt)
  BUB.t = BUB.t + dt
  if BUBBLE_RIPE + bubbleWindow() < BUB.t then
    bubblePop()
  end
end

function bubbleFxTick(dt)
  BUB.fx.t = BUB.fx.t - dt
  if BUB.fx.t <= 0 then BUB.fx = nil end
end

function bubbleUpdate(dt)
  fkUpdate(BUBBLE, BUBBLE_CFG, dt)
  if BUB.key then bubbleGrow(dt) end
  if BUB.fx then bubbleFxTick(dt) end
end

-- A key pressed while a bubble is already inflating is ignored:
-- mid-hold curiosity must not read as a wrong answer.

function bubbleKeypressed(k)
  if fkDone(BUBBLE) then
    fkDoneKey(BUBBLE, BUBBLE_CFG, k)
    return
  end
  if BUB.key then return end
  if not gaugeGlowing(BUBBLE) then return end
  if k == gaugeCurrent(BUBBLE) then
    BUB.key = k
    BUB.t = 0
  elseif not Key.is_mod(k) and k ~= "capslock" then
    fkWrong(BUBBLE, BUBBLE_CFG, k)
  end
end

-- The one judge in the game that keys on the release EVENT --
-- a chosen channel, not a platform limit.
-- The caution: a release lost to a focus change leaves BUB.key
-- set with no release coming. bubbleGrow's timeout pops the
-- bubble a moment later: the cost is a pop the child retries.
function bubbleKeyreleased(k)
  if k ~= BUB.key then return end
  bubbleRelease()
end

-- A teacher notch change restarts the level, so an inflating
-- bubble and any effect go with it.

function bubbleOnNotch(delta)
  bubbleClear()
  BUB.fx = nil
  fkOnNotch(BUBBLE, BUBBLE_CFG, delta)
end

function bubbleDone()
  return fkDone(BUBBLE)
end

-- Drawing

-- The ring band: let go while the bubble edge is between these
-- circles. Inner ring green (from here it counts), outer dim
-- (the last moment). The picture is the whole instruction.

function bubbleDrawBand(x, y)
  gfx.setColor(COL_OK[1], COL_OK[2], COL_OK[3], 0.9)
  gfx.circle("line", x, y, BUBBLE_RIPE_R)
  gfx.setColor(COL_DIM[1], COL_DIM[2], COL_DIM[3], 0.7)
  gfx.circle("line", x, y, bubbleOuterR())
end

-- A soft warm skin with a firm edge, so the bubble reads over
-- both the caps and the pastel background.

function bubbleSkin(x, y, r, a)
  gfx.setColor(COL_WARM_DIM[1], COL_WARM_DIM[2],
    COL_WARM_DIM[3], a * 0.6)
  gfx.circle("fill", x, y, r)
  gfx.setColor(COL_WARM[1], COL_WARM[2], COL_WARM[3], a)
  gfx.setLineWidth(3)
  gfx.circle("line", x, y, r)
  gfx.setLineWidth(1)
end

-- The flown bubble drifts up and fades.

function bubbleDrawFly(fx, p)
  local rise = (1 - p) * BUBBLE_FLY_RISE
  bubbleSkin(fx.x, fx.y - rise, fx.r, p)
end

-- The popped bubble blows out as a pink ring -- the gentle
-- "not that" marker, never the error red.

function bubbleDrawPop(fx, p)
  local r = fx.r * (1 + (1 - p) * BUBBLE_POP_GROW)
  gfx.setColor(COL_PINK[1], COL_PINK[2], COL_PINK[3], p)
  gfx.setLineWidth(3)
  gfx.circle("line", fx.x, fx.y, r)
  gfx.setLineWidth(1)
end

BUBBLE_FX = {
  fly = bubbleDrawFly,
  pop = bubbleDrawPop
}

function bubbleDrawFx()
  local fx = BUB.fx
  BUBBLE_FX[fx.kind](fx, fx.t / fx.life)
end

function bubbleDrawTarget()
  local k = bubbleTargetKey()
  if not k then return end
  local x, y = bubbleAt(k)
  if not x then return end
  bubbleDrawBand(x, y)
  if not BUB.key then return end
  bubbleSkin(x, y, bubbleRadius(BUB.t), 1)
end

function bubbleDrawOverlay()
  bubbleDrawTarget()
  if BUB.fx then bubbleDrawFx() end
end

-- The target cap is warm, as in Press, so the key stays
-- unmistakable under the band.

function bubbleDeco()
  local deco = { }
  local k = bubbleTargetKey()
  if k then deco[k] = { bg = COL_WARM } end
  return deco
end

function bubbleDraw()
  fkDraw(BUBBLE, BUBBLE_CFG, bubbleDeco(), bubbleDrawOverlay)
end

registerScene("bubble", {
  enter = bubbleEnter,
  update = bubbleUpdate,
  draw = bubbleDraw,
  keypressed = bubbleKeypressed,
  keyreleased = bubbleKeyreleased,
  onNotch = bubbleOnNotch,
  noHint = bubbleDone
})
