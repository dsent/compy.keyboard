-- train.lua

-- Load the train. A cap hovers over the next empty platform;
-- press it and the cap settles onto the deck as cargo. When
-- every platform is loaded the train DEPARTS and an empty one
-- rolls in behind it, and that departure is what one unit of
-- the gauge counts.
--
-- Press-count engine (gauge.lua) as in Press, so the key set
-- and the learning records live there. PROGRESSION sets how
-- many platforms a train has, so a later level asks for a
-- longer train; the NOTCH sets the key set and how many trains
-- a level asks for, and nothing else. There is no timer
-- anywhere: the cap waits as long as the child needs, which is
-- what makes this the game for the youngest. Full canvas, no
-- keyboard picture: the hovering cap is the target.

ensureFile("props.lua")

TRAIN = { level = 1, burst = nil, wrong = nil, fw = { } }

-- cars: the keys already riding this train, in platform order.
-- phase: wait (cap hovering), load (cap settling onto the
-- deck), depart (the full train leaving), arrive (the next one
-- rolling in). t is the time spent in the phase.

LOAD = { cars = { }, phase = "wait", t = 0 }

-- Car pitch and the deck height are fixed, so they are derived
-- once here rather than per frame.

TRAIN_CAR_W = 16 * TRAIN_U
TRAIN_PITCH = TRAIN_CAR_W + TRAIN_CAR_GAP
TRAIN_LOCO_W = 20 * TRAIN_U
TRAIN_DECK_Y = TRAIN_GROUND_Y - 5.2 * TRAIN_U
TRAIN_CAP_W = TRAIN_CAP_H * KB_STD_W / KB_STD_H
TRAIN_CAP_U = TRAIN_CAP_H / KB_STD_H

function trainNotch()
  return TRAIN_NOTCH[notchGet("train")]
end

-- Progression: level L runs L + 1 platforms, up to the last one
-- whose car still fits the track.

function trainPlatforms()
  return math.min(TRAIN.level + 1, TRAIN_PLAT_MAX)
end

function trainAtTop()
  return TRAIN.level + 1 >= TRAIN_PLAT_MAX
end

-- The ladder the gauge draws its segments from: progression is
-- its own here, so the rungs are levels rather than notches.

function trainRung()
  return TRAIN.level
end

function trainRungs()
  return TRAIN_PLAT_MAX - 1
end

-- The goal is trains, not presses, so the reserve rule is left
-- to bias the pick toward keys not yet cleared rather than to
-- stretch the level: a level counted in trains that had to
-- cover every new glyph would run to eighteen departures at the
-- full key set, which is no level for the youngest player.

function trainGoal()
  return trainNotch().trains
end

-- The teacher's notch, so the chord visibly lands. Progression
-- is already on screen as the platform count.

function trainSky()
  skyLevel(notchGet("train") - TRAIN_LO)
end

function trainResetLevel()
  TRAIN.level = 1
end

TRAIN_CFG = {
  id = "train",
  notch = TRAIN_NOTCH,
  lo = TRAIN_LO,
  hi = TRAIN_HI
}

-- An empty train and a still beat: the state every fresh level
-- and every departure leaves behind.

function trainReset()
  LOAD.cars = { }
  LOAD.phase = "wait"
  LOAD.t = 0
end

-- The gauge counts trains, so the presses a level budgets are
-- reported separately for the reserve rule.

function trainFill(st, cfg)
  st.plan = st.goal * trainPlatforms()
  st.spent = 0
  trainReset()
  gaugeNext(st, cfg)
end

function trainAdvance(st, cfg)
  if not trainAtTop() then
    TRAIN.level = TRAIN.level + 1
  end
  gaugeStartLevel(st, cfg)
end

function trainEnter()
  TRAIN.level = 1
  TRAIN.burst = nil
  TRAIN.wrong = nil
  fkEnter(TRAIN, TRAIN_CFG)
end

-- The train grows to the right of the locomotive.

function trainCarX(i)
  return TRAIN_LOCO_X + TRAIN_LOCO_W + (i - 1) * TRAIN_PITCH
end

-- The platform the next cap fills. It never runs past the last
-- one: a full train departs rather than waiting for one more.

function trainNextSlot()
  return math.min(#LOAD.cars + 1, trainPlatforms())
end

-- A full train leaves, and the gauge takes its unit as it
-- pulls away rather than once it is gone -- otherwise the last
-- train of a level fills the gauge on a screen nobody sees. The
-- last one leaves under the level screen's own celebration, so
-- it does not sound twice.

function trainDepart()
  LOAD.phase = "depart"
  LOAD.t = 0
  TRAIN.hits = TRAIN.hits + 1
  if TRAIN.hits < TRAIN.goal then SOUND.win() end
end

-- The train is gone: either the level ends here or the next one
-- rolls in behind it.

function trainArrive()
  LOAD.cars = { }
  LOAD.phase = "arrive"
  LOAD.t = 0
  if TRAIN.hits >= TRAIN.goal then
    gaugeWin(TRAIN, TRAIN_CFG)
    fkCelebrate(TRAIN)
  end
end

function trainTickLoad()
  if TRAIN_LOAD <= LOAD.t then
    LOAD.phase = "wait"
    LOAD.t = 0
  end
end

function trainTickDepart()
  if TRAIN_DEPART <= LOAD.t then trainArrive() end
end

function trainTickArrive()
  if TRAIN_ARRIVE <= LOAD.t then
    LOAD.phase = "wait"
    LOAD.t = 0
  end
end

TRAIN_TICK = { }
TRAIN_TICK.load = trainTickLoad
TRAIN_TICK.depart = trainTickDepart
TRAIN_TICK.arrive = trainTickArrive

function trainUpdate(dt)
  fkUpdate(TRAIN, TRAIN_CFG, dt)
  if fkDone(TRAIN) then return end
  local tick = TRAIN_TICK[LOAD.phase]
  if not tick then return end
  LOAD.t = LOAD.t + dt
  tick()
end

-- A loaded platform. A full train departs instead of waiting
-- for another cap, so there is no full-row case to re-index and
-- no cargo ever changes the car it rides on.

function trainHit(k)
  if not TRAIN.fumbled then
    TRAIN.learn[k].n = TRAIN.learn[k].n + 1
  end
  TRAIN.spent = TRAIN.spent + 1
  LOAD.cars[#LOAD.cars + 1] = k
  trainBurst(k)
  SOUND.match()
  gaugeNext(TRAIN, TRAIN_CFG)
  if trainPlatforms() <= #LOAD.cars then
    trainDepart()
    return
  end
  LOAD.phase = "load"
  LOAD.t = 0
end

-- The knock always sounds and the press always counts as a
-- fumble; the cap is only shown for a key this game has a cap
-- for. A keyboard reports names no cap exists for, and echoing
-- one prints it straight past the edge of its own cap.

function trainWrong(k)
  SOUND.reject()
  TRAIN.wrong = nil
  if capKnown(k) then
    TRAIN.wrong = { key = k, t = TRAIN_HIT_T }
  end
  gaugeOnWrong(TRAIN, TRAIN_CFG)
end

function trainKeypressed(k)
  if fkDone(TRAIN) then
    fkDoneKey(TRAIN, TRAIN_CFG, k)
    return
  end
  if LOAD.phase ~= "wait" then return end
  if k == gaugeCurrent(TRAIN) then
    trainHit(k)
  elseif not Key.is_mod(k) and k ~= "capslock" then
    trainWrong(k)
  end
end

function trainOnNotch(delta)
  fkOnNotch(TRAIN, TRAIN_CFG, delta)
end

function trainDone()
  return fkDone(TRAIN)
end

-- Drawing

-- A cap centred on a car deck at x, sitting on it as cargo.

function trainCargoCell(x, y)
  return {
    x = x + (TRAIN_CAR_W - TRAIN_CAP_W) / 2,
    y = y - TRAIN_CAP_H,
    w = TRAIN_CAP_W,
    h = TRAIN_CAP_H
  }
end

function trainDrawCap(x, y, k)
  drawKeycap(trainCargoCell(x, y), {
    name = k,
    unit = TRAIN_CAP_U
  })
end

-- The whole train moves as one, and it moves LEFT: the
-- locomotive stands at the head of the consist with its cars
-- behind it, so that is the way it faces. A departure
-- accelerates it off the left edge and the next one rolls in
-- from the right.

function trainOffset()
  if LOAD.phase == "depart" then
    local f = LOAD.t / TRAIN_DEPART
    return -f * f * REF_W * 1.4
  end
  if LOAD.phase == "arrive" then
    local f = 1 - LOAD.t / TRAIN_ARRIVE
    return f * f * REF_W * 1.4
  end
  return 0
end

-- The cap just pressed rides down from the hover height onto
-- its deck, so the press and the cargo are one movement.

function trainCargoDrop(i)
  if LOAD.phase ~= "load" then return 0 end
  if i ~= #LOAD.cars then return 0 end
  return -(1 - LOAD.t / TRAIN_LOAD) * TRAIN_HOVER
end

-- Every platform this level runs is on the track from the
-- start, loaded or not, so the count progression sets is there
-- to be seen.

function trainDrawCars(ox)
  for i = 1, trainPlatforms() do
    local x = trainCarX(i) + ox
    drawCar(x, TRAIN_GROUND_Y, TRAIN_U)
    if LOAD.cars[i] then
      trainDrawCap(x, TRAIN_DECK_Y + trainCargoDrop(i),
        LOAD.cars[i])
    end
  end
end

-- The target hovers over the platform the next cap will fill.

function trainHoverCell()
  return trainCargoCell(trainCarX(trainNextSlot()),
    TRAIN_DECK_Y - TRAIN_HOVER)
end

function trainDrawTarget()
  trainDrawCap(trainCarX(trainNextSlot()),
    TRAIN_DECK_Y - TRAIN_HOVER, gaugeCurrent(TRAIN))
end

-- A full-canvas scene has no keyboard picture to hang the
-- engine's feedback on: a correct press bursts over the deck
-- the cap just landed on, and a wrong one shows the key that
-- was pressed under the pink wrong-key wash, where the target
-- hovers.

function trainBurst(k)
  local c = trainCargoCell(trainCarX(#LOAD.cars),
    TRAIN_DECK_Y)
  TRAIN.burst = { key = k, t = TRAIN_HIT_T,
    x = c.x + c.w / 2, y = c.y + c.h / 2 }
end

-- The key that was pressed stands BESIDE the one that is
-- wanted, not over it, so the two can be compared instead of
-- overprinting each other.

function trainDrawWrong()
  local cell = trainHoverCell()
  cell.x = cell.x - TRAIN_CAP_W * 1.4
  drawKeycap(cell, {
    name = TRAIN.wrong.key,
    unit = TRAIN_CAP_U,
    glow = COL_PINK,
    alpha = math.min(1, TRAIN.wrong.t / TRAIN_HIT_T * 3)
  })
end

function trainDrawFeedback()
  if TRAIN.burst then drawBurst(TRAIN.burst) end
  if TRAIN.wrong then trainDrawWrong() end
end

function trainDrawScene()
  local ox = trainOffset()
  drawMeadow(REF_W, REF_H, TRAIN_GROUND_Y)
  drawTrack(0, TRAIN_GROUND_Y - 6, REF_W)
  drawLoco(TRAIN_LOCO_X + ox, TRAIN_GROUND_Y, TRAIN_U)
  drawSmoke(TRAIN_LOCO_X + ox + 5 * TRAIN_U,
    TRAIN_GROUND_Y - 11 * TRAIN_U, love.timer.getTime())
  trainDrawCars(ox)
  if LOAD.phase == "wait" then trainDrawTarget() end
end

function trainDraw()
  if trainDone() then
    fkDrawEndScreen(TRAIN, TRAIN_CFG)
    fwDraw(TRAIN)
    return
  end
  trainDrawScene()
  trainDrawFeedback()
  drawWinGauge(fkGauge(TRAIN, TRAIN_CFG))
  fwDraw(TRAIN)
  fkDrawExitHint()
end

-- The seams gauge.lua offers a scene whose level shape is its
-- own. Attached here rather than in the table above, since a
-- name has to hold a function before it can be handed over.

TRAIN_CFG.sky = trainSky
TRAIN_CFG.goal = trainGoal
TRAIN_CFG.fill = trainFill
TRAIN_CFG.atTop = trainAtTop
TRAIN_CFG.advance = trainAdvance
TRAIN_CFG.reset = trainResetLevel
TRAIN_CFG.rung = trainRung
TRAIN_CFG.rungs = trainRungs

registerScene("train", {
  enter = trainEnter,
  update = trainUpdate,
  draw = trainDraw,
  keypressed = trainKeypressed,
  onNotch = trainOnNotch,
  noHint = trainDone
})
