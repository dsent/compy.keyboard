-- stream.lua

-- The falling-caps stream. Capital keycaps ride rocks down from
-- the top edge at a constant, even cadence and the child types
-- them, in any order, before they reach the force field. There
-- are no waves: every cap carries its own position and its own
-- lifetime, the spawn interval is the fall time divided by the
-- level, and the level is therefore the number of caps in
-- flight.
--
-- The teacher's NOTCH is difficulty: fall speed, the level
-- ceiling, the gauge threshold and the key set. The child's
-- GAUGE is progression: a clean shot adds one, a cap that
-- reaches the field takes one away.
--
-- This file is the stream only. The scene both Asteroids
-- variants play on is astrocore.lua.

ensureFile("props.lua")

STREAM = {
  caps = { },
  struck = { },
  review = { },
  order = { },
  recent = { },
  chars = { },
  taught = { },
  wait = 0,
  jit = 0,
  burn = nil,
  level = 1,
  g = 0,
  sink = 0,
  count = 0,
  breaches = 0,
  lastx = nil,
  phase = "play",
  after = nil,
  hold = 0,
  fw = { }
}

-- The engine serves one game at a time, so the running game is
-- state. A game carries its own notch id (progress is per
-- game), its teacher-notch bounds, its background ramp and
-- whether burning rocks cross its sky. streamEnter is the only
-- thing that sets this; update and draw never run before a
-- scene has entered.

STREAM_GAME = nil

-- Falling caps are enlarged board caps: height in px, width
-- from the board's letter-cap proportions. The rock under a cap
-- is wider than the cap, and its radius is what has to clear
-- the force field.

STREAM_CAP = 56
STREAM_CAP_W = math.floor(STREAM_CAP * KB_STD_W / KB_STD_H)
STREAM_ROCK_R = STREAM_CAP_W * 0.82
STREAM_ROCK_D = STREAM_ROCK_R * 2

-- Game-owned catch chime: win.ogg pitched up -- lighter than
-- correct.ogg and brighter, which conveys speed. EVERY hit
-- plays it: with no waves there is no final hit to reserve it
-- for, so one shot sounds like one shot throughout.

STREAM_CHIME = love.audio.newSource(
  "assets/sounds/win.ogg", "static")
STREAM_CHIME:setPitch(1.35)

function streamChime()
  love.audio.stop(STREAM_CHIME)
  love.audio.play(STREAM_CHIME)
end

function streamCfg()
  return STREAM_NOTCH[notchGet(STREAM_GAME.id)]
end

-- The ramp step for the current notch, above the game's floor.

function streamColorLevel()
  return notchGet(STREAM_GAME.id) - STREAM_GAME.lo
end

-- Paint the background for the current notch. Asteroids plays
-- in space, where the chrome pastel would be wrong, so the game
-- brings its own ramp.

function streamPaintSky()
  local ramp = STREAM_GAME.ramp
  if ramp then
    pastelSetTarget(ramp[streamColorLevel()])
  else
    pastelLevel(streamColorLevel())
  end
end

-- The key set at the current notch: an ordered list for the
-- spawn pick, and a lookup for "is this a key the game can put
-- on a cap". A notch adds its groups on top of the lower ones.

function streamAddGroup(g)
  for _, c in ipairs(KEYSETS[g]) do
    STREAM.chars[#STREAM.chars + 1] = c
    STREAM.taught[c] = true
  end
end

function streamBuildChars()
  STREAM.chars = { }
  STREAM.taught = { }
  for n = STREAM_GAME.lo, notchGet(STREAM_GAME.id) do
    for _, g in ipairs(STREAM_NOTCH[n].add) do
      streamAddGroup(g)
    end
  end
end

-- The review set: keys that got away and should come back. Its
-- counts live in a hash and its membership in an ORDERED list
-- beside it, because a random pick over pairs() order is not
-- reproducible between processes -- and a stream that cannot be
-- replayed from a seed costs real time when a bug has to be
-- pinned down.

function streamReviewAdd(ch)
  if not STREAM.review[ch] then
    STREAM.order[#STREAM.order + 1] = ch
  end
  STREAM.review[ch] = STREAM_CFG.review_hits
end

function streamReviewDrop(ch)
  STREAM.review[ch] = nil
  for i, k in ipairs(STREAM.order) do
    if k == ch then
      table.remove(STREAM.order, i)
      return
    end
  end
end

-- One correct press toward retiring a key from review.

function streamReviewHit(ch)
  local n = STREAM.review[ch]
  if not n then return end
  if n <= 1 then
    streamReviewDrop(ch)
  else
    STREAM.review[ch] = n - 1
  end
end

function streamInFlight(ch)
  for _, c in ipairs(STREAM.caps) do
    if c.ch == ch then return true end
  end
  return false
end

-- The last few keys spawned are held back from the next spawn.
-- Without it a key that got away came straight back, and kept
-- coming back until it was answered. The window can never eat
-- the whole set: what is in the sky needs candidates too.

function streamRecentMax()
  local room = #STREAM.chars - STREAM.level - 2
  if room < STREAM_CFG.recent then
    return math.max(0, room)
  end
  return STREAM_CFG.recent
end

function streamRecall(ch)
  STREAM.recent[#STREAM.recent + 1] = ch
  while streamRecentMax() < #STREAM.recent do
    table.remove(STREAM.recent, 1)
  end
end

function streamTaken(ch)
  if streamInFlight(ch) then return true end
  for _, k in ipairs(STREAM.recent) do
    if k == ch then return true end
  end
  return false
end

-- A key from the taught set that is neither in the sky nor
-- freshly used, so no two caps carry the same letter and none
-- repeats on its own heels.

function streamFreshChar()
  local n = #STREAM.chars
  local s = love.math.random(n)
  for j = 0, n - 1 do
    local ch = STREAM.chars[(s + j - 1) % n + 1]
    if not streamTaken(ch) then return ch end
  end
  return STREAM.chars[s]
end

function streamReviewChar()
  local keys = { }
  for _, ch in ipairs(STREAM.order) do
    if not streamTaken(ch) then keys[#keys + 1] = ch end
  end
  if #keys == 0 then return streamFreshChar() end
  return keys[love.math.random(#keys)]
end

-- Keys that got away come back more often, but never so often
-- that the stream stops teaching anything new.

function streamPickChar()
  local due = #STREAM.order > 0
  local ch = nil
  if due and love.math.random() < STREAM_CFG.review_p then
    ch = streamReviewChar()
  else
    ch = streamFreshChar()
  end
  streamRecall(ch)
  return ch
end

-- Rocks are scattered across the width. A spawn keeps clear of
-- the last one, so two never come down the same column and read
-- as one stack.

function streamSpawnX()
  local lo = STREAM_MARGIN + STREAM_ROCK_R
  local hi = REF_W - STREAM_MARGIN - STREAM_ROCK_R
  local span = hi - lo
  local x = lo + love.math.random() * span
  local last = STREAM.lastx
  if last and math.abs(x - last) < STREAM_ROCK_D then
    x = lo + (x - lo + span / 2) % span
  end
  STREAM.lastx = x
  return x
end

-- Where a rock coming straight down at x stops: its own radius
-- above the field arc, which is where it touches.

function streamStopY(x)
  return fieldY(x) - STREAM_ROCK_R
end

-- The field is one huge circle, so "has it reached the shield"
-- is a distance from that circle's centre, not a height. A cap
-- coming down at a slant needs it that way: a height test fires
-- wherever the SLANTED path happens to cross, which is not the
-- point it was aimed at, and the fall then takes a different
-- time from the one it was given.

STREAM_STOP_R = nil

function streamStopRadius()
  if not STREAM_STOP_R then
    STREAM_STOP_R = FIELD_R + STREAM_ROCK_R
  end
  return STREAM_STOP_R
end

function streamAtField(cap)
  local ex = cap.x - REF_W / 2
  local ey = cap.y - FIELD_CY
  local rs = streamStopRadius()
  return ex * ex + ey * ey <= rs * rs
end

-- How far a cap must travel along the line it is on before it
-- touches the field: a ray meeting that circle. Exact, so a
-- slanted cap's fall lasts as long as a straight one's.

function streamReach(x, dx, dy)
  local rs = streamStopRadius()
  local ex = x - REF_W / 2
  local ey = STREAM_SPAWN_Y - FIELD_CY
  local b = ex * dx + ey * dy
  local d = b * b - (ex * ex + ey * ey - rs * rs)
  if d <= 0 then return nil end
  return -b - math.sqrt(d)
end

function streamAddCap(cap)
  cap.seed = love.math.random() * 6.28
  STREAM.caps[#STREAM.caps + 1] = cap
  return cap
end

-- Where a cap is headed: a point on the arc, drifted from where
-- it came in but never past the ends of the field, so it always
-- lands ON the shield.

function streamAimX(x)
  local drift = (love.math.random() * 2 - 1) * STREAM_DRIFT
  local lo = STREAM_MARGIN + STREAM_ROCK_R
  local hi = REF_W - STREAM_MARGIN - STREAM_ROCK_R
  return math.max(lo, math.min(hi, x + drift))
end

-- The line a cap comes down on, as a unit direction: from where
-- it enters toward a point on the field.

function streamAimDir(x, tx)
  local dx = tx - x
  local dy = streamStopY(tx) - STREAM_SPAWN_Y
  local n = math.sqrt(dx * dx + dy * dy)
  return dx / n, dy / n
end

-- A cap comes down at a slant, aimed at the field. Its speed is
-- set from how far it must actually travel to touch, so it
-- takes the fall time it was given whatever line it is on.

function streamSpawnCap(fall)
  local x = streamSpawnX()
  local dx, dy = streamAimDir(x, streamAimX(x))
  local reach = streamReach(x, dx, dy)
  streamAddCap({
    ch = streamPickChar(),
    x = x,
    y = STREAM_SPAWN_Y,
    vx = dx * reach / fall,
    vy = dy * reach / fall,
    fall = fall,
    hostile = false
  })
end

-- A burning rock crosses to a point low on one side, picked
-- fresh each time inside the band where it clears the field.
-- Starting on the FAR side is what makes the line readable: it
-- crosses at least half the width before it gets there.

function streamHostileAim()
  local span = DANGER_AIM_HI - DANGER_AIM_LO
  local y = DANGER_AIM_LO + love.math.random() * span
  if love.math.random() < 0.5 then return 0, y end
  return REF_W, y
end

function streamHostileX(tx)
  local m = STREAM_MARGIN + STREAM_ROCK_R
  local near = REF_W * DANGER_FAR
  local span = REF_W - near - m
  if tx > 0 then return m + love.math.random() * span end
  return near + love.math.random() * span
end

function streamSpawnHostile()
  local tx, ty = streamHostileAim()
  local x = streamHostileX(tx)
  local fall = streamCfg().fall
  local ch = streamFreshChar()
  streamRecall(ch)
  streamAddCap({
    ch = ch,
    x = x,
    y = STREAM_SPAWN_Y,
    vx = (tx - x) / fall,
    vy = (ty - STREAM_SPAWN_Y) / fall,
    hostile = true
  })
end

-- A level earned stops the sky and says so. It used to change
-- two numbers in silence: the only thing a child could see was
-- the gauge emptying, which reads as progress being taken away
-- rather than given. Same screen and same sound as every other
-- game in the set.

function streamGrow()
  STREAM.level = STREAM.level + 1
  STREAM.g = 0
  STREAM.phase = "level"
  SOUND.win()
end

-- A demote keeps the gauge two-thirds full, so a child who just
-- had a bad streak at a comfortable level climbs back quickly.

function streamShrink()
  STREAM.level = STREAM.level - 1
  STREAM.g = math.floor(streamCfg().promote * 2 / 3)
end

-- The top-level win: celebratory tune + firework, then the
-- completion screen (Enter = replay).

function streamWin()
  SOUND.wow()
  fwStart(STREAM)
  STREAM.phase = "done"
end

-- Filling the gauge does not end the level on the spot. It
-- stops the spawner and lets the child clear whatever is still
-- in the sky first -- otherwise the shot that won it is never
-- seen landing, the screen having replaced the beam and the
-- explosion on the very frame of the key press. Nothing scores
-- either way from here, so the sky can be finished at leisure.

function streamFinish(after)
  STREAM.after = after
  STREAM.phase = "finish"
  STREAM.hold = STREAM_FINISH_HOLD
end

-- A clean shot fills the gauge: below lmax, +promote raises the
-- level; at lmax, +promote opens the win screen. It also clears
-- the sunk count, so a child who recovers starts that tally
-- again from nothing.

function streamGaugeUp()
  if not streamScoring() then return end
  local cfg = streamCfg()
  STREAM.sink = 0
  STREAM.g = STREAM.g + 1
  if STREAM.g < cfg.promote then return end
  if STREAM.level < cfg.lmax then
    streamFinish("level")
  else
    streamFinish("done")
  end
end

-- A cap reaching the field drains the gauge, which stops at
-- EMPTY: the next clean shot always moves it, whatever came
-- before. Caps that arrive once it is already empty are counted
-- instead, and `demote` of them lowers the level. At level 1
-- there is nowhere to go, so nothing happens -- no failure
-- state, as before.

function streamGaugeDown()
  if not streamScoring() then return end
  if 0 < STREAM.g then
    STREAM.g = STREAM.g - 1
    return
  end
  STREAM.sink = STREAM.sink + 1
  if STREAM.sink < STREAM_CFG.demote then return end
  STREAM.sink = 0
  if 1 < STREAM.level then streamShrink() end
end

-- A clean shot: the cap leaves the sky, the gauge climbs, and
-- the key is one press closer to leaving review.

function streamHit(cap)
  streamReviewHit(cap.ch)
  STREAM.count = STREAM.count + 1
  cap.dead = true
  streamGaugeUp()
  if streamLive() then streamChime() end
end

-- Anything reaching the field strikes it the same way, whether
-- nobody answered it or the child shot it down onto the shield.
-- The scene drains this list to put a blast where it landed.

function streamStrike(cap)
  cap.dead = true
  STREAM.breaches = STREAM.breaches + 1
  STREAM.struck[#STREAM.struck + 1] = {
    x = cap.x, y = cap.y, ch = cap.ch, seed = cap.seed
  }
  fieldStrike(cap.x)
  SOUND.impact()
end

-- A cap nobody answered: the key goes back into review and the
-- gauge drains.

function streamBreach(cap)
  streamReviewAdd(cap.ch)
  streamStrike(cap)
  streamGaugeDown()
end

-- The cap for this key, or nil. With a free order every cap in
-- the sky is fair, so the LOWEST one is taken: it is the one
-- about to be lost.

function streamFindCap(k)
  local best = nil
  for _, c in ipairs(STREAM.caps) do
    local match = c.ch == k and not c.dead
    if match and (not best or c.y > best.y) then best = c end
  end
  return best
end

-- The cap a wrong press stood in for: the lowest one that is
-- still there to be shot.

function streamStanding()
  local best = nil
  for _, c in ipairs(STREAM.caps) do
    local live = not c.hostile and not c.dead
    if live and (not best or c.y > best.y) then best = c end
  end
  return best
end

-- A wrong press books BOTH keys into review: the one pressed
-- and the cap it stood in for. The pressed key is booked ONLY
-- if the game can put it on a cap. A keyboard reports keys no
-- cap exists for -- select, f5, printscreen, a bare arrow --
-- and booking one makes a falling target no child can answer,
-- which the breach path then books straight back for ever.

function streamWrongPress(k)
  SOUND.reject()
  if STREAM.taught[k] then streamReviewAdd(k) end
  local cap = streamStanding()
  if cap then streamReviewAdd(cap.ch) end
end

function streamOffCanvas(cap)
  local m = STREAM_ROCK_D
  if cap.x < -m or cap.x > REF_W + m then return true end
  return cap.y > REF_H + m
end

-- A burning rock that has been shot. It was never coming for
-- us, so the shot is the thing that puts it on the field: it
-- loses its course, tumbles, and falls onto the shield the
-- child was defending. Nothing more is charged for the crash --
-- the shot has already been paid for -- but the field takes the
-- hit, which is the answer to what firing at it achieved.

function streamDown(cap)
  cap.downed = true
  cap.roll = 0
  cap.vx = cap.vx * DANGER_CRASH_DRAG
  cap.vy = cap.vy * DANGER_CRASH_DRAG
end

function streamTickDowned(cap, dt)
  cap.vy = cap.vy + DANGER_CRASH_G * dt
  cap.roll = cap.roll + DANGER_CRASH_SPIN * dt
end

-- A wreck striking the shield. The shot has already been paid
-- for, so nothing more is charged; otherwise it lands exactly
-- as an unanswered cap does, and reads the same.

function streamCrash(cap)
  streamStrike(cap)
end

-- What reaching the field means: a cap the child never answered
-- is a breach, a rock they shot down is a crash.

function streamLand(cap)
  if cap.downed then
    streamCrash(cap)
  else
    streamBreach(cap)
  end
end

-- A burning rock still on its course is never stopped by the
-- field it was aimed past; it leaves by the edge it was always
-- heading for.

function streamTickCap(cap, dt)
  if cap.downed then streamTickDowned(cap, dt) end
  cap.x = cap.x + cap.vx * dt
  cap.y = cap.y + cap.vy * dt
  if streamOffCanvas(cap) then
    cap.dead = true
    return
  end
  if cap.hostile and not cap.downed then return end
  if streamAtField(cap) then streamLand(cap) end
end

function streamReap()
  local keep = { }
  for _, c in ipairs(STREAM.caps) do
    if not c.dead then keep[#keep + 1] = c end
  end
  STREAM.caps = keep
end

function streamTickCaps(dt)
  for _, c in ipairs(STREAM.caps) do
    if not c.dead then streamTickCap(c, dt) end
  end
  streamReap()
end

-- Is there anything left to shoot? A burning rock is not: it
-- was never ours to hit, so a sky holding only those is empty
-- as far as the child is concerned.

function streamShootable()
  for _, c in ipairs(STREAM.caps) do
    if not c.hostile and not c.dead then return true end
  end
  return false
end

-- A burning rock arrives in the MIDDLE of the gap between two
-- ordinary ones, and only sometimes, so it comes out of the
-- stream's order rather than alongside a cap to shoot.

function streamArmBurn()
  STREAM.burn = nil
  if not STREAM_GAME.danger then return end
  if love.math.random() >= DANGER_CHANCE then return end
  STREAM.burn = STREAM.wait / 2
end

-- A cleared sky shortens the gap, so a burning rock already
-- booked for the middle of it has to move up with it -- or it
-- would arrive after the next ordinary rock instead of between
-- the two.

function streamHurryBurn()
  if not STREAM.burn then return end
  local half = STREAM.wait / 2
  if half < STREAM.burn then STREAM.burn = half end
end

function streamTickBurn(dt)
  if not STREAM.burn then return end
  STREAM.burn = STREAM.burn - dt
  if STREAM.burn > 0 then return end
  STREAM.burn = nil
  streamSpawnHostile()
end

-- One spawn per interval, and the interval is the fall time
-- divided by the level -- which is the same statement as "the
-- level is how many caps are in the sky". Clearing the sky
-- early brings the next one along instead of leaving a child
-- watching nothing for the rest of the interval.

-- The gap to the next cap, jittered either side of the notch's
-- interval. The offset is carried, so the gap absorbs both this
-- cap's and the next one's -- which is what keeps the LANDINGS
-- evenly spaced while the arrivals wander.

function streamArmNext()
  local i = streamCfg().fall / STREAM.level
  local prev = STREAM.jit
  local j = (love.math.random() * 2 - 1) * STREAM_JITTER * i
  STREAM.jit = j
  STREAM.wait = i + j - prev
end

function streamTickSpawn(dt)
  STREAM.wait = STREAM.wait - dt
  local lull = STREAM_REFILL < STREAM.wait
  if lull and not streamShootable() then
    STREAM.wait = STREAM_REFILL
    STREAM.jit = 0
    streamHurryBurn()
  end
  if STREAM.wait > 0 then return end
  streamSpawnCap(streamCfg().fall - STREAM.jit)
  streamArmNext()
  streamArmBurn()
end

-- The finishing stretch: caps still fall and still answer to
-- the gun, but nothing new is sent and nothing scores. It ends
-- once the sky holds nothing left to shoot, after a beat long
-- enough for the last shot to be seen landing.

function streamTickFinish(dt)
  if streamShootable() then
    STREAM.hold = STREAM_FINISH_HOLD
    return
  end
  STREAM.hold = STREAM.hold - dt
  if STREAM.hold > 0 then return end
  if STREAM.after == "done" then
    streamWin()
  else
    streamGrow()
  end
end

function streamUpdate(dt)
  fwUpdate(STREAM, dt)
  fieldTick(dt)
  if not streamLive() then return end
  streamTickCaps(dt)
  if streamFinishing() then
    streamTickFinish(dt)
    return
  end
  streamTickSpawn(dt)
  streamTickBurn(dt)
end

function streamReset()
  STREAM.caps = { }
  STREAM.struck = { }
  STREAM.recent = { }
  STREAM.level = 1
  STREAM.g = 0
  STREAM.sink = 0
  STREAM.count = 0
  STREAM.breaches = 0
  STREAM.lastx = nil
  STREAM.wait = 0
  STREAM.jit = 0
  STREAM.burn = nil
  STREAM.phase = "play"
  STREAM.after = nil
  STREAM.hold = 0
  STREAM.fw = { }
end

function streamEnter(game)
  STREAM_GAME = game
  STREAM.review = { }
  STREAM.order = { }
  streamReset()
  streamBuildChars()
  fieldReset()
  streamPaintSky()
  pastelSnap()
end

-- Three questions the rest of the game asks about the phase.
-- SCORING: the gauge answers and caps keep coming (play alone).
-- LIVE: the sky is running and the gun works, which includes
-- the finishing stretch after the gauge is full. Neither is
-- true on an end screen.

function streamScoring()
  return STREAM.phase == "play"
end

function streamFinishing()
  return STREAM.phase == "finish"
end

function streamLive()
  return streamScoring() or streamFinishing()
end

function streamDone()
  return STREAM.phase == "done"
end

function streamAtLevel()
  return STREAM.phase == "level"
end

function streamReplay()
  streamReset()
end

-- Win-screen keys: Enter replays this notch.

function streamDoneKey(k)
  if k == "return" or k == "kpenter" then
    streamReplay()
  end
end

-- Tab on the level screen. The sky starts clean at the new
-- level, so "now three at a time" is what the child sees rather
-- than whatever happened to be falling when the gauge filled --
-- and nothing that was about to reach the field lands the
-- instant play resumes.

function streamResume()
  STREAM.caps = { }
  STREAM.struck = { }
  STREAM.wait = STREAM_REFILL
  STREAM.jit = 0
  STREAM.burn = nil
  STREAM.after = nil
  STREAM.hold = 0
  STREAM.phase = "play"
end

function streamLevelKey(k)
  if k == "tab" then streamResume() end
end

-- A teacher notch change is difficulty, so it lands at once:
-- the key set and the field colour change on the spot and the
-- progression starts again at level 1. Rocks already in flight
-- keep the speed they were given and still count, so nothing
-- vanishes out from under a child mid-answer.

function streamOnNotch(delta)
  local old = notchGet(STREAM_GAME.id)
  notchShift(STREAM_GAME.id, delta, STREAM_GAME.lo,
    STREAM_GAME.hi)
  if notchGet(STREAM_GAME.id) == old then return end
  streamBuildChars()
  streamPaintSky()
  if not streamScoring() then
    streamReplay()
    return
  end
  STREAM.level = 1
  STREAM.g = 0
  STREAM.sink = 0
  STREAM.recent = { }
end
