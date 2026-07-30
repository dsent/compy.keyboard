-- astrocore.lua

-- The scene both Asteroids variants play on: the star field,
-- the force field the rocks come down to, the saucer sheltering
-- under it and the gun that shoots them. The cap stream, the
-- gauge, the review and the notch are stream.lua's; this file
-- owns what the child sees and the trigger they pull.
--
-- The gun reloads after EVERY shot and nothing fires while it
-- does, so the game cannot be won by hammering every key. A
-- blank costs longer than a hit, which turns hammering into a
-- permanent reload and makes looking first the cheaper move.
-- The charge shows on the ship as three lamps and a glow, so it
-- is read without words.
--
-- Neither variant loads the other: each declares its own scene
-- descriptor and hands it to astroEnter.

ensureFile("stream.lua")

-- charge: seconds left before the gun is ready; full: how long
-- the current reload runs, so the lamps fill over it. bolt: the
-- rock being hit and how long the beam still shows. shake: the
-- ship recoiling from a rock the field had to stop.

GUN = { charge = 0, full = ASTRO_RELOAD_HIT, bolt = nil,
  bursts = { }, blasts = { }, shake = 0 }

ASTRO_SHIP_Y = ASTRO_GROUND_Y - 4 * ASTRO_SHIP_U

function astroEnter(game)
  GUN.charge = 0
  GUN.full = ASTRO_RELOAD_HIT
  GUN.bolt = nil
  GUN.bursts = { }
  GUN.blasts = { }
  GUN.shake = 0
  streamEnter(game)
end

function astroReady()
  return GUN.charge <= 0
end

function astroChargeFrac()
  return 1 - GUN.charge / GUN.full
end

-- Every shot starts a reload; a blank one runs longer.

function astroReload(time)
  GUN.charge = time
  GUN.full = time
end

-- The beam aims at where the rock stood when the trigger went,
-- not at where it has travelled to since, so it always points
-- at the rock it struck.

function astroBolt(cap)
  GUN.bolt = { x = cap.x, y = cap.y, t = ASTRO_BOLT_T }
  SOUND.laser()
end

function astroBurstAt(cap)
  GUN.bursts[#GUN.bursts + 1] = {
    x = cap.x, y = cap.y, t = BANG_T
  }
end

-- A rock shot clean comes apart where it stood, rather than
-- blinking out. The cap it carried is kept with the wreckage so
-- the letter can pop over it as it fades.

function astroBlastAt(cap)
  GUN.blasts[#GUN.blasts + 1] = {
    x = cap.x, y = cap.y, ch = cap.ch,
    seed = cap.seed, t = ASTRO_BLAST_T
  }
end

function astroShoot(cap)
  astroBolt(cap)
  astroBlastAt(cap)
  astroReload(ASTRO_RELOAD_HIT)
  streamHit(cap)
end

function astroBlank()
  astroReload(ASTRO_RELOAD_MISS)
end

-- Shooting a burning rock. It was going to miss, so the shot is
-- what brings it down: it tumbles out of its course and falls
-- onto the shield, which is the clearest possible answer to why
-- it should have been left alone. The shot also costs a drained
-- gauge, a knock and the long blank reload.
--
-- One rock costs once. Firing at the wreck again still wastes
-- the reload, but the gauge is not drained twice for the same
-- mistake; a LATER rock carrying the same key is a new one and
-- charges again.

function astroShootPast(cap)
  astroBolt(cap)
  astroBurstAt(cap)
  astroReload(ASTRO_RELOAD_MISS)
  SOUND.reject()
  if cap.spent then return end
  cap.spent = true
  streamDown(cap)
  streamGaugeDown()
end

function astroKeypressed(k)
  if streamDone() then
    streamDoneKey(k)
    return
  end
  if not astroReady() then return end
  local cap = streamFindCap(k)
  if cap and cap.hostile then
    astroShootPast(cap)
  elseif cap then
    astroShoot(cap)
  elseif not isMod(k) and k ~= "capslock" then
    astroBlank()
    streamWrongPress(k)
  end
end

function astroTickGun(dt)
  GUN.charge = math.max(0, GUN.charge - dt)
  GUN.shake = math.max(0, GUN.shake - dt)
  if not GUN.bolt then return end
  GUN.bolt.t = GUN.bolt.t - dt
  if GUN.bolt.t <= 0 then GUN.bolt = nil end
end

function astroTickBursts(dt)
  for i = #GUN.bursts, 1, -1 do
    local b = GUN.bursts[i]
    b.t = b.t - dt
    if b.t <= 0 then table.remove(GUN.bursts, i) end
  end
end

function astroTickBlasts(dt)
  for i = #GUN.blasts, 1, -1 do
    local b = GUN.blasts[i]
    b.t = b.t - dt
    if b.t <= 0 then table.remove(GUN.blasts, i) end
  end
end

-- A rock the field has to stop shoves the saucer under it; the
-- stream has already booked the breach, so this only reacts to
-- its tally of them moving.

function astroUpdate(dt)
  local before = STREAM.breaches
  streamUpdate(dt)
  if before < STREAM.breaches then
    GUN.shake = ASTRO_SHAKE_T
  end
  astroTickGun(dt)
  astroTickBursts(dt)
  astroTickBlasts(dt)
end

function astroOnNotch(delta)
  GUN.bolt = nil
  GUN.bursts = { }
  GUN.blasts = { }
  streamOnNotch(delta)
end

function astroDone()
  return streamDone()
end

-- Drawing

function astroShipX()
  local p = GUN.shake / ASTRO_SHAKE_T
  return REF_W / 2 + math.sin(p * 24) * p * ASTRO_SHAKE_PX
end

function astroCapCell(cap)
  return {
    x = cap.x - STREAM_CAP_W / 2,
    y = cap.y - STREAM_CAP / 2,
    w = STREAM_CAP_W,
    h = STREAM_CAP
  }
end

function astroDrawCap(cap, color, alpha, scale)
  drawKeycap(astroCapCell(cap), {
    name = cap.ch,
    unit = STREAM_CAP / KB_STD_H,
    color = color,
    alpha = alpha,
    scale = scale
  })
end

-- A rock with its cap on top. A burning one is drawn by its own
-- shape and its own trail, so the two classes differ in kind
-- rather than in trim, and only the hostile one is marked.

function astroDrawRock(cap)
  if cap.hostile then
    drawBurning(cap)
  else
    drawRock(cap.x, cap.y, STREAM_ROCK_R, cap.seed)
  end
  astroDrawCap(cap, CAP_LABEL, 1)
end

function astroDrawStream()
  for _, c in ipairs(STREAM.caps) do
    astroDrawRock(c)
  end
end

-- The letter that got away stays readable: the ring expands
-- AROUND the cap and the cap is drawn over it, so the glyph
-- just booked into review is never hidden by its own burst.

function astroDrawGone(g)
  local a = g.t / STREAM_GONE_T
  gfx.setColor(COL_RED[1], COL_RED[2], COL_RED[3], a)
  gfx.setLineWidth(4)
  gfx.circle("line", g.x, g.y,
    STREAM_ROCK_R + (1 - a) * 46)
  gfx.setLineWidth(1)
  astroDrawCap(g, COL_RED, a)
end

function astroDrawLost()
  for _, g in ipairs(STREAM.gone) do
    astroDrawGone(g)
  end
end

-- The wreckage, then the cap over it: the letter grows and
-- fades out of its own explosion, so what the child cleared is
-- what they are left looking at.

-- The cap clears in the first half of the blast, so the letter
-- is read and then gone rather than sitting over the wreckage
-- for the whole of it.

function astroDrawBlast(b)
  local p = 1 - b.t / ASTRO_BLAST_T
  drawBlast(b)
  if p >= 0.5 then return end
  astroDrawCap(b, CAP_LABEL, 1 - p * 2, 1 + p * 0.8)
end

function astroDrawBlasts()
  for _, b in ipairs(GUN.blasts) do
    astroDrawBlast(b)
  end
end

-- The beam from the ship to the rock it struck.

function astroDrawBolt(sx)
  gfx.setColor(BOLT[1], BOLT[2], BOLT[3],
    GUN.bolt.t / ASTRO_BOLT_T)
  gfx.setLineWidth(4)
  gfx.line(sx, ASTRO_SHIP_Y, GUN.bolt.x, GUN.bolt.y)
  gfx.setLineWidth(1)
end

function astroDrawBursts()
  for _, b in ipairs(GUN.bursts) do
    drawBang(b)
  end
end

function astroDrawShip(sx)
  local frac = astroChargeFrac()
  drawCharge(sx, ASTRO_SHIP_Y, ASTRO_SHIP_U, frac)
  drawShip(sx, ASTRO_SHIP_Y, ASTRO_SHIP_U, frac)
end

-- The field is drawn OVER the rocks, so a rock that reaches it
-- is stopped by a surface in front of it rather than sinking
-- behind a line. The recoil offset is worked out once and
-- handed to both the ship and the beam, so the two cannot
-- drift apart.

function astroDrawScene()
  local sx = astroShipX()
  drawStars(REF_W, REF_H, ASTRO_STARS)
  astroDrawStream()
  drawField(streamColorLevel())
  astroDrawBlasts()
  astroDrawLost()
  astroDrawBursts()
  if GUN.bolt then astroDrawBolt(sx) end
  astroDrawShip(sx)
end

-- The gauge is the only score on screen. A running tally of
-- rocks destroyed is a number to chase, which is not what these
-- games ask a child to do.

function astroDraw()
  if astroDone() then
    fkDrawDoneScreen()
    fwDraw(STREAM)
    return
  end
  astroDrawScene()
  drawWinGauge(STREAM.g, streamCfg().promote,
    GAUGE_SPACE_INK)
  fwDraw(STREAM)
  fkDrawExitHint()
end
