-- hide.lua

-- Hide and seek. A ROTATION of keys is in play. Only one of
-- them is shown at a time, peeking out from behind one of the
-- crates, and the rest stay hidden; the child may press ANY key
-- in the rotation, shown or hidden. A pressed key leaves the
-- rotation and another takes its place. A key outside the
-- rotation knocks.
--
-- UNTIMED. The peek cycle drives only what is VISIBLE: it never
-- expires an answer, nothing is ever scored as late, and a
-- child may take as long as they want. The mechanic is the
-- inverse of a find-the-key drill -- the cap on show is a
-- refresher for a set held in memory, not the thing under test.
--
-- Press-count engine (gauge.lua) as in Press, so the key set
-- and the learning records live there. This file owns the
-- rotation, the peek cycle and the scene. Full canvas: no
-- keyboard picture, since a board below would only show the
-- keys the game is asking the child to remember.

ensureFile("props.lua")

HIDE = { rot = { }, hold = { }, boxes = { }, level = 1,
  peek = 1, burst = nil, wrong = nil, fw = { } }

-- phase: out (sliding into view), show (fully out), back
-- (sliding away), away (nothing shown). t is the time spent in
-- the phase. box and side are picked fresh every time the
-- peek advances, so a key that came from one crate may next
-- come from another, and from any of its edges.

PEEK = { phase = "away", t = 0, box = 1, side = "left" }
HIDE_SIDES = { "left", "right", "top" }

-- Cap and crate sizes are fixed, so the travel a cap needs to
-- clear a crate -- less the lip that stays covered, which is
-- what makes it read as coming from behind -- is derived once.

HIDE_CAP_W = HIDE_CAP_H * KB_STD_W / KB_STD_H
HIDE_BOX_W = 10 * HIDE_CRATE_U
HIDE_TRAVEL_X = (HIDE_BOX_W + HIDE_CAP_W) / 2 - HIDE_CAP_LIP
HIDE_TRAVEL_Y = (HIDE_BOX_W + HIDE_CAP_H) / 2 - HIDE_CAP_LIP

function hideNotch()
  return HIDE_NOTCH[notchGet("hide")]
end

-- Progression fills the notch's ceilings: level L runs L + 1
-- keys in the rotation and L + 1 crates, each stopped at what
-- the notch allows. The top level is the one that reaches the
-- rotation ceiling.

function hideRotSize()
  return math.min(HIDE.level + 1, hideNotch().rot)
end

function hideBoxCount()
  return math.min(HIDE.level + 1, hideNotch().box)
end

function hideAtTop()
  return HIDE.level + 1 >= hideNotch().rot
end

-- The ladder the gauge draws its segments from: progression is
-- its own here, so the rungs are levels rather than notches.

function hideRung()
  return HIDE.level
end

function hideRungs()
  return hideNotch().rot - 1
end

-- One unit per correct press, scaled to the rotation: a bigger
-- rotation is a bigger thing to hold, so it asks for more.

function hideGoal()
  return HIDE_G_BASE + HIDE_G_STEP * hideRotSize()
end

-- The teacher's notch, so the chord visibly lands. Progression
-- is already on screen as the crate count and how many keys the
-- rotation holds.

function hideSky()
  skyLevel(notchGet("hide") - HIDE_LO)
end

function hideResetLevel()
  HIDE.level = 1
end

HIDE_CFG = {
  id = "hide",
  notch = HIDE_NOTCH,
  lo = HIDE_LO,
  hi = HIDE_HI
}

-- The rotation is the set the child is holding, so the gauge is
-- told to keep its members out of the next pick.

function hideHold()
  local set = { }
  for _, k in ipairs(HIDE.rot) do set[k] = true end
  HIDE.hold = set
end

function hideFill(st, cfg)
  HIDE.rot = { }
  HIDE.hold = { }
  st.cur = nil
  while #HIDE.rot < hideRotSize() do
    HIDE.rot[#HIDE.rot + 1] = gaugeTake(st, cfg)
    hideHold()
  end
  st.phase = "glow"
  HIDE.peek = 1
  hidePlaceBoxes()
  hideGoto("out")
end

-- The answered key leaves and a fresh one takes its slot, so
-- the rotation keeps its size and its order. st.cur holds the
-- key just answered, which is what stops it coming straight
-- back. Answering the key ON SHOW ends its peek there and then:
-- what is shown always belongs to the rotation, and the cap
-- going the moment it is named reads as the reward.

function hideReplace(i, old)
  table.remove(HIDE.rot, i)
  hideHold()
  HIDE.cur = old
  table.insert(HIDE.rot, i, gaugeTake(HIDE, HIDE_CFG))
  hideHold()
  if i == HIDE.peek then hideGoto("away") end
end

-- The crates stand in random places along a shallow band of
-- ground, one to a sector so they never overlap, and nearer
-- ones are drawn last. A fresh level lays them out again.

function hideBoxSort(a, b)
  return a.y < b.y
end

function hidePlaceBoxes()
  HIDE.boxes = { }
  local n = hideBoxCount()
  local span = (REF_W - 2 * HIDE_MARGIN) / n
  for i = 1, n do
    local jitter = love.math.random() * (span - HIDE_BOX_W)
    HIDE.boxes[i] = {
      x = HIDE_MARGIN + (i - 1) * span + jitter,
      y = HIDE_GROUND_Y + love.math.random() * HIDE_BAND
    }
  end
  table.sort(HIDE.boxes, hideBoxSort)
  PEEK.box = love.math.random(n)
end

-- The peek cycle. Each tick returns the phase to enter next, or
-- nil to stay, so the table below reads as the cycle itself.

function hideGoto(phase)
  PEEK.phase = phase
  PEEK.t = 0
end

function hideStep()
  HIDE.peek = HIDE.peek % #HIDE.rot + 1
  PEEK.box = love.math.random(#HIDE.boxes)
  PEEK.side = HIDE_SIDES[love.math.random(#HIDE_SIDES)]
end

function hideTickOut()
  if HIDE_SLIDE <= PEEK.t then return "show" end
end

function hideTickShow()
  if hideNotch().show <= PEEK.t then return "back" end
end

function hideTickBack()
  if HIDE_SLIDE <= PEEK.t then return "away" end
end

function hideTickAway()
  if hideNotch().away <= PEEK.t then
    hideStep()
    return "out"
  end
end

HIDE_TICK = { }
HIDE_TICK.out = hideTickOut
HIDE_TICK.show = hideTickShow
HIDE_TICK.back = hideTickBack
HIDE_TICK.away = hideTickAway

function hideEnter()
  HIDE.level = 1
  HIDE.burst = nil
  HIDE.wrong = nil
  fkEnter(HIDE, HIDE_CFG)
end

function hideUpdate(dt)
  fkUpdate(HIDE, HIDE_CFG, dt)
  if fkDone(HIDE) then return end
  PEEK.t = PEEK.t + dt
  local next = HIDE_TICK[PEEK.phase]()
  if next then hideGoto(next) end
end

-- Tab on the level screen: one more key in the rotation and one
-- more crate, up to the notch's ceilings; at the ceiling the
-- level runs again, so play never stops.

function hideAdvance(st, cfg)
  if not hideAtTop() then
    HIDE.level = HIDE.level + 1
  end
  gaugeStartLevel(st, cfg)
end

function hideInRotation(k)
  for i, key in ipairs(HIDE.rot) do
    if key == k then return i end
  end
  return nil
end

-- Any rotation member scores at any moment, visible or hidden.
-- Nothing here reads a clock.

function hideHit(k, i)
  local e = HIDE.learn[k]
  e.n = e.n + 1
  hideBurst(k)
  SOUND.match()
  HIDE.hits = HIDE.hits + 1
  hideReplace(i, k)
  if HIDE.hits >= HIDE.goal then
    gaugeWin(HIDE, HIDE_CFG)
    fkCelebrate(HIDE)
  end
end

-- The knock always sounds; the cap is only shown for a key this
-- game has a cap for. A keyboard reports names no cap exists
-- for, and echoing one prints it straight past the edge of the
-- cap it is drawn on.

function hideWrong(k)
  SOUND.reject()
  HIDE.burst = nil
  HIDE.wrong = nil
  if capKnown(k) then
    HIDE.wrong = { key = k, t = HIDE_HIT_T }
  end
end

function hideKeypressed(k)
  if fkDone(HIDE) then
    fkDoneKey(HIDE, HIDE_CFG, k)
    return
  end
  local i = hideInRotation(k)
  if i then
    hideHit(k, i)
  elseif not Key.is_mod(k) and k ~= "capslock" then
    hideWrong(k)
  end
end

function hideOnNotch(delta)
  fkOnNotch(HIDE, HIDE_CFG, delta)
end

function hideDone()
  return fkDone(HIDE)
end

-- Drawing

-- How far the cap has slid out, 0 hidden to 1 fully shown.

function hideSlideFrac()
  if PEEK.phase == "show" then
    return 1
  elseif PEEK.phase == "out" then
    return PEEK.t / HIDE_SLIDE
  elseif PEEK.phase == "back" then
    return 1 - PEEK.t / HIDE_SLIDE
  end
  return 0
end

function hideBoxRect(i)
  local b = HIDE.boxes[i]
  return { x = b.x, y = b.y - HIDE_BOX_W,
    w = HIDE_BOX_W, h = HIDE_BOX_W }
end

-- Hidden, the cap sits centred behind its crate; it slides out
-- along whichever edge the peek picked.

function hideCapCell()
  local r = hideBoxRect(PEEK.box)
  local f = hideSlideFrac()
  local cell = {
    x = r.x + (r.w - HIDE_CAP_W) / 2,
    y = r.y + (r.h - HIDE_CAP_H) / 2,
    w = HIDE_CAP_W, h = HIDE_CAP_H
  }
  if PEEK.side == "left" then
    cell.x = cell.x - f * HIDE_TRAVEL_X
  elseif PEEK.side == "right" then
    cell.x = cell.x + f * HIDE_TRAVEL_X
  else
    cell.y = cell.y - f * HIDE_TRAVEL_Y
  end
  return cell
end

function hideDrawCap()
  if hideSlideFrac() <= 0 then return end
  drawKeycap(hideCapCell(), {
    name = HIDE.rot[HIDE.peek],
    unit = HIDE_CAP_H / KB_STD_H
  })
end

-- The cap is drawn BEFORE its crate, so the crate covers
-- whatever has not slid clear yet.

function hideDrawBoxes()
  for i, b in ipairs(HIDE.boxes) do
    if i == PEEK.box then hideDrawCap() end
    drawCrate(b.x, b.y, HIDE_CRATE_U)
  end
end

-- A full-canvas scene has no keyboard picture to hang the
-- engine's feedback on, so the press itself is shown: the key
-- just answered pops as a cap with a ring around it, and a key
-- outside the rotation shows the same cap under the pink
-- wrong-key wash. Both stand in the band above the crates.

function hideMarkCell()
  return { x = (REF_W - HIDE_CAP_W) / 2, y = HIDE_MARK_Y,
    w = HIDE_CAP_W, h = HIDE_CAP_H }
end

-- One mark stands at a time: a hit and a wrong press mean
-- opposite things, and the latest press is the one being
-- answered.

function hideBurst(k)
  HIDE.wrong = nil
  HIDE.burst = { key = k, t = HIDE_HIT_T }
end

-- The mark holds full strength for most of its life and fades
-- only at the end, so the glyph is legible while it is up.

function hideMarkAlpha(m)
  return math.min(1, m.t / HIDE_HIT_T * 3)
end

function hideDrawMark(m, glow)
  drawKeycap(hideMarkCell(), {
    name = m.key,
    unit = HIDE_CAP_H / KB_STD_H,
    glow = glow,
    alpha = hideMarkAlpha(m)
  })
end

-- The ring expands from OUTSIDE the cap, so the glyph it is
-- celebrating stays readable underneath it.

function hideDrawRing(m)
  local a = m.t / HIDE_HIT_T
  local c = hideMarkCell()
  gfx.setColor(COL_BURST[1], COL_BURST[2], COL_BURST[3], a)
  gfx.setLineWidth(4)
  gfx.circle("line", c.x + c.w / 2, c.y + c.h / 2,
    HIDE_CAP_W * 0.7 + (1 - a) * 48)
  gfx.setLineWidth(1)
end

function hideDrawFeedback()
  if HIDE.burst then
    hideDrawRing(HIDE.burst)
    hideDrawMark(HIDE.burst, COL_WARM)
  end
  if HIDE.wrong then
    hideDrawMark(HIDE.wrong, COL_PINK)
  end
end

function hideDrawScene()
  drawMeadow(REF_W, REF_H, HIDE_GROUND_Y)
  hideDrawBoxes()
end

function hideDraw()
  if hideDone() then
    fkDrawEndScreen(HIDE, HIDE_CFG)
    fwDraw(HIDE)
    return
  end
  hideDrawScene()
  hideDrawFeedback()
  drawWinGauge(fkGauge(HIDE, HIDE_CFG))
  fwDraw(HIDE)
  fkDrawExitHint()
end

-- The seams gauge.lua offers a scene whose level shape is its
-- own. Attached here rather than in the table above, since a
-- name has to hold a function before it can be handed over.

HIDE_CFG.sky = hideSky
HIDE_CFG.goal = hideGoal
HIDE_CFG.fill = hideFill
HIDE_CFG.atTop = hideAtTop
HIDE_CFG.advance = hideAdvance
HIDE_CFG.reset = hideResetLevel
HIDE_CFG.rung = hideRung
HIDE_CFG.rungs = hideRungs

registerScene("hide", {
  enter = hideEnter,
  update = hideUpdate,
  draw = hideDraw,
  keypressed = hideKeypressed,
  onNotch = hideOnNotch,
  noHint = hideDone
})
