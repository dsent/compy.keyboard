-- props.lua

-- Scenery and props for the games that play on a scene rather
-- than on the keyboard picture. Everything is drawn from
-- primitives: no image assets, so a prop scales to any size,
-- takes its colors from the palette, and costs a handful of
-- draw calls. Shared by Hide, Load the train and Asteroids.

-- A prop is placed by its bottom-left corner and sized by a
-- unit u, so a caller states position and scale in one call.

-- A scene paints its own sky instead of the chrome pastel,
-- which would hang a green or yellow sky over green grass.
--
-- The step is the TEACHER's notch. It has to be: a notch change
-- otherwise moves nothing a teacher can see, since the key set
-- it sets only shows up in the keys that happen to come next.
-- Progression has a carrier of its own on each scene already:
-- how many platforms the train has, how many crates stand on
-- the meadow. So the sky is free to answer the chord.

function skyLevel(step)
  local i = math.min(step, #SKY_RAMP)
  pastelSetTarget(SKY_RAMP[i])
end

-- Rolling hills along the ground line: three flattened
-- ellipses, widest first, so the band reads as depth.

function drawHills(w, y)
  gfx.setColor(HILL[1], HILL[2], HILL[3])
  gfx.ellipse("fill", w * 0.25, y, w * 0.3, 34)
  gfx.ellipse("fill", w * 0.62, y, w * 0.26, 26)
  gfx.ellipse("fill", w * 0.88, y, w * 0.22, 30)
end

-- Meadow: hills along the horizon and a ground strip. The sky
-- is left to the pastel background main already paints, so the
-- level still colors the scene and nothing is filled twice.

function drawMeadow(w, h, groundY)
  drawHills(w, groundY)
  gfx.setColor(GROUND[1], GROUND[2], GROUND[3])
  gfx.rectangle("fill", 0, groundY, w, h - groundY)
end

-- Crate planks: the darker boards over the body. Drawn as one
-- helper so the crate itself stays a short block.

function crateBoards(x, y, u)
  gfx.setColor(WOOD_DARK[1], WOOD_DARK[2], WOOD_DARK[3])
  gfx.rectangle("fill", x, y - 10 * u,
    10 * u, 1.3 * u, 0.5 * u)
  gfx.rectangle("fill", x, y - 5.6 * u, 10 * u, 1 * u)
  gfx.rectangle("fill", x, y - 1.3 * u,
    10 * u, 1.3 * u, 0.5 * u)
  gfx.rectangle("fill", x + 4.2 * u, y - 8.7 * u,
    1.6 * u, 3.1 * u)
  gfx.rectangle("fill", x + 4.2 * u, y - 4.6 * u,
    1.6 * u, 3.3 * u)
end

-- A crate, 10u square, standing on (x, y). A cap slides out
-- from behind whichever of its edges the peek picked.

function drawCrate(x, y, u)
  gfx.setColor(WOOD[1], WOOD[2], WOOD[3])
  gfx.rectangle("fill", x, y - 10 * u, 10 * u, 10 * u, 0.5 * u)
  crateBoards(x, y, u)
end

-- A wheel: dark tyre with a light hub.

function propWheel(x, y, r)
  gfx.setColor(IRON[1], IRON[2], IRON[3])
  gfx.circle("fill", x, y, r)
  gfx.setColor(HUB[1], HUB[2], HUB[3])
  gfx.circle("fill", x, y, r * 0.45)
end

-- Track: two rails over evenly spaced sleepers, drawn across a
-- width from (x, y) at the rail top.

function drawSleepers(x, y, w)
  gfx.setColor(SLEEPER[1], SLEEPER[2], SLEEPER[3])
  for i = 0, math.floor(w / SLEEPER_GAP) do
    gfx.rectangle("fill", x + i * SLEEPER_GAP, y,
      SLEEPER_GAP * 0.4, 9, 1)
  end
end

function drawTrack(x, y, w)
  drawSleepers(x, y + 2, w)
  gfx.setColor(RAIL[1], RAIL[2], RAIL[3])
  gfx.rectangle("fill", x, y, w, 3)
  gfx.rectangle("fill", x, y + 9, w, 3)
end

-- Locomotive, 20u long and 11u tall, standing on (x, y).

function locoBoiler(x, y, u)
  gfx.setColor(BOILER[1], BOILER[2], BOILER[3])
  gfx.rectangle("fill", x + 2 * u, y - 7.5 * u,
    10.4 * u, 4.1 * u, 0.6 * u)
  gfx.setColor(IRON[1], IRON[2], IRON[3])
  gfx.rectangle("fill", x + 0.8 * u, y - 6.2 * u,
    1.4 * u, 2.8 * u, 0.3 * u)
end

function locoCab(x, y, u)
  gfx.setColor(CAB[1], CAB[2], CAB[3])
  gfx.rectangle("fill", x + 11.8 * u, y - 10 * u,
    5.8 * u, 6.6 * u, 0.5 * u)
  gfx.setColor(CAB_GLASS[1], CAB_GLASS[2], CAB_GLASS[3])
  gfx.rectangle("fill", x + 13 * u, y - 8.8 * u,
    3.2 * u, 2.7 * u, 0.3 * u)
end

function locoStack(x, y, u)
  gfx.setColor(IRON[1], IRON[2], IRON[3])
  gfx.rectangle("fill", x + 3.6 * u, y - 10.2 * u,
    2.2 * u, 3 * u, 0.3 * u)
  gfx.rectangle("fill", x + 3 * u, y - 10.8 * u,
    3.4 * u, 1.1 * u, 0.4 * u)
end

function drawLoco(x, y, u)
  gfx.setColor(IRON[1], IRON[2], IRON[3])
  gfx.rectangle("fill", x + 1.4 * u, y - 3.4 * u,
    16.8 * u, 0.9 * u)
  locoBoiler(x, y, u)
  locoCab(x, y, u)
  locoStack(x, y, u)
  propWheel(x + 14.6 * u, y - 2 * u, 1.8 * u)
  propWheel(x + 5.2 * u, y - 1.8 * u, 1.3 * u)
  propWheel(x + 9.2 * u, y - 1.8 * u, 1.3 * u)
end

-- Flat car, 16u long: a clear deck with low end posts, so a
-- cap set on it reads as cargo.

function drawCar(x, y, u)
  gfx.setColor(IRON[1], IRON[2], IRON[3])
  gfx.rectangle("fill", x + 1.2 * u, y - 3.4 * u,
    13.6 * u, 0.9 * u)
  gfx.setColor(WOOD[1], WOOD[2], WOOD[3])
  gfx.rectangle("fill", x + 1.4 * u, y - 5.2 * u,
    13.2 * u, 1.8 * u, 0.3 * u)
  gfx.setColor(WOOD_DARK[1], WOOD_DARK[2], WOOD_DARK[3])
  gfx.rectangle("fill", x + 1.4 * u, y - 6.8 * u,
    0.9 * u, 1.8 * u, 0.2 * u)
  gfx.rectangle("fill", x + 13.7 * u, y - 6.8 * u,
    0.9 * u, 1.8 * u, 0.2 * u)
  propWheel(x + 4.4 * u, y - 2 * u, 1.3 * u)
  propWheel(x + 11.6 * u, y - 2 * u, 1.3 * u)
end

-- Smoke puffs drifting up and BACK from the stack -- back being
-- to the right, since the locomotive faces left. t is the
-- caller's own clock, so the plume never resets.

function smokePuff(x, y, i, t)
  local p = (t * 0.6 + i * 0.33) % 1
  gfx.setColor(SMOKE[1], SMOKE[2], SMOKE[3], 1 - p)
  gfx.circle("fill", x + p * 26, y - p * 40, 3 + p * 9)
end

function drawSmoke(x, y, t)
  for i = 1, 4 do
    smokePuff(x, y, i, t)
  end
end

-- Star field: positions come from the index alone, so the sky
-- is fixed and never wanders. Only the brightness moves, slowly
-- and each star on its own phase, so the sky breathes without
-- anything in it drawing the eye away from the rocks.

function starAt(i, w, h)
  return (i * 73.7) % w, (i * 41.3) % (h * 0.8)
end

function starAlpha(i, t)
  return 0.72 + 0.28 * math.sin(t * 0.8 + i * 1.7)
end

function drawStars(w, h, n)
  local t = love.timer.getTime()
  for i = 1, n do
    local x, y = starAt(i, w, h)
    gfx.setColor(STAR[1], STAR[2], STAR[3], starAlpha(i, t))
    gfx.circle("fill", x, y, (i % 3) * 0.4 + 0.7)
  end
end

-- An asteroid: a twelve-point silhouette. Radius and angle
-- both jitter from the seed, on two frequencies each way, so
-- seeds give different kinds of outline rather than the same
-- blob in different widths. The four diagonal vertices stay on
-- their spokes and never dip under 1.05 r: the cap's corners
-- live under those diagonals, and holding them out is what
-- keeps every corner buried in rock without growing the rock.

function rockJag(seed, i)
  local j = 1.03 + 0.085 * math.sin(seed + i * 2.3)
  return j + 0.045 * math.sin(seed * 3.1 + i * 5.3)
end

function rockPoints(cx, cy, r, seed)
  local pts = { }
  for i = 0, 11 do
    local a = math.pi / 12 + i * math.pi / 6
    local j = rockJag(seed, i)
    if i % 3 == 1 then
      j = math.max(j, 1.05)
    else
      a = a + 0.12 * math.sin(seed * 1.7 + i * 3.7)
    end
    pts[#pts + 1] = cx + math.cos(a) * r * j
    pts[#pts + 1] = cy + math.sin(a) * r * j
  end
  return pts
end

-- The hollow is cut from the CAP's silhouette, not from the
-- outline: an octagon fitted around the cap rectangle, pushed
-- a few jittered pixels past its corners and edges. However
-- the outline falls, the hollow swallows the whole cap, so the
-- letter sits in black on every seed.

HOLLOW_X = { 1, 1, 0, -1, -1, -1, 0, 1 }
HOLLOW_Y = { 0, 1, 1, 1, 0, -1, -1, -1 }
HOLLOW_PAD = { 0.12, 0.06, 0.16, 0.06, 0.12, 0.06, 0.16, 0.06 }

function rockPad(seed, k)
  local w = math.sin(seed * 2.6 + k * 1.9)
  return 0.04 + (HOLLOW_PAD[k] - 0.04) * (0.5 + 0.5 * w)
end

function rockHollow(cx, cy, r, seed)
  local pts = { }
  for k = 1, 8 do
    local p = rockPad(seed, k)
    pts[#pts + 1] = cx + HOLLOW_X[k] * r * (0.61 + p)
    pts[#pts + 1] = cy + HOLLOW_Y[k] * r * (0.51 + p)
  end
  return pts
end

-- The ring of rock around the hollow is shaded facet by facet:
-- each wedge one flat grey, swung by where it faces against
-- the light from ROCK_LIGHT, with a little grain per facet
-- from the seed. Flat facets catching one light are what make
-- it read as stone instead of an outline around a hole.

function rockShade(seed, i)
  local a = math.pi / 6 + i * math.pi / 6
  local d = math.cos(a) * ROCK_LIGHT[1]
    + math.sin(a) * ROCK_LIGHT[2]
  local v = ROCK_BASE + ROCK_SPAN * d
  v = v + ROCK_GRAIN * math.sin(seed * 2.2 + i * 3.9)
  gfx.setColor(v, v, v + ROCK_TINT)
end

-- Facets first, then the hollow in the CAP's own black, so the
-- cap lands in it and stops being a shape: what is left on
-- screen is a letter down in a cavity. Drawing the cap's edge
-- -- a groove, a bevel, a lit lip -- is the one thing that
-- undoes this.

function drawRock(cx, cy, r, seed)
  local pts = rockPoints(cx, cy, r, seed)
  for i = 0, 11 do
    local k = i * 2 + 1
    local n = i == 11 and 1 or k + 2
    rockShade(seed, i)
    gfx.polygon("fill", cx, cy, pts[k], pts[k + 1],
      pts[n], pts[n + 1])
  end
  gfx.setColor(ROCK_CORE[1], ROCK_CORE[2], ROCK_CORE[3])
  gfx.polygon("fill", rockHollow(cx, cy, r, seed))
end

-- A rock coming apart. p runs 0 at the moment of the hit to 1
-- when it is gone. The flash is brief and grows as it fades;
-- the shards are the rock's own outline at a fraction of its
-- size, thrown outward from where it stood.

-- The flash starts WIDER than the cap riding the rock, or the
-- cap drawn over it would swallow the whole thing and the rock
-- would still look like it had simply blinked out.

-- A wreck striking the shield flashes RED and half again as
-- wide as a rock coming apart under the gun. One is the child
-- succeeding, the other is the child's own mistake landing on
-- the thing they were defending, and they should not look
-- alike.

function blastHue(b)
  if b.bad then return COL_RED end
  return { 1, 1, 0.9 }
end

function blastFlash(b, p)
  if p > 0.35 then return end
  local f = 1 - p / 0.35
  local c = blastHue(b)
  local w = 1
  if b.bad then w = 1.35 end
  gfx.setColor(c[1], c[2], c[3], f * f * 0.9)
  gfx.circle("fill", b.x, b.y,
    STREAM_ROCK_R * (1.2 + (1 - f) * 0.9) * w)
end

-- Each shard gets its own speed and size from the seed. Evenly
-- matched ones fly out as a ring, which reads as a shape rather
-- than as something coming apart.

function blastShard(b, i, p)
  local a = b.seed + i / ASTRO_BLAST_SHARDS * 6.28
  local v = 0.75 + 0.5 * math.sin(b.seed * 3 + i * 2.1)
  local reach = 1.9
  if b.bad then reach = 2.9 end
  local d = STREAM_ROCK_R * (0.6 + p * reach * v)
  local r = STREAM_ROCK_R * (0.34 - 0.1 * v) * (1 - p)
  gfx.polygon("fill", rockPoints(b.x + math.cos(a) * d,
    b.y + math.sin(a) * d, r, b.seed + i))
end

function blastAge(b)
  return 1 - b.t / b.span
end

function drawBlast(b)
  local p = blastAge(b)
  blastFlash(b, p)
  gfx.setColor(ROCK_LIT[1], ROCK_LIT[2], ROCK_LIT[3], 1 - p)
  for i = 1, ASTRO_BLAST_SHARDS do
    blastShard(b, i, p)
  end
end

-- The force field. Three points fix it -- an end at each screen
-- margin and the apex in the middle -- and the circle through
-- them is enormous and centred far below the bottom edge, so
-- the arc on screen is one slice of a sphere the screen never
-- shows. The line is cached: it never moves.

FIELD = { hits = { } }
FIELD_HALF = REF_W / 2 - FIELD_MARGIN
FIELD_DROP = FIELD_EDGE_Y - FIELD_APEX_Y
FIELD_CY = FIELD_APEX_Y + (FIELD_HALF * FIELD_HALF
  + FIELD_DROP * FIELD_DROP) / (2 * FIELD_DROP)
FIELD_R = FIELD_CY - FIELD_APEX_Y
FIELD_STEPS = 48
FIELD_LINE = nil

function fieldY(x)
  local dx = x - REF_W / 2
  local under = FIELD_R * FIELD_R - dx * dx
  if under <= 0 then return REF_H end
  return FIELD_CY - math.sqrt(under)
end

function fieldPoints()
  local pts = { }
  local span = REF_W - 2 * FIELD_MARGIN
  for i = 0, FIELD_STEPS do
    local x = FIELD_MARGIN + span * i / FIELD_STEPS
    pts[#pts + 1] = x
    pts[#pts + 1] = fieldY(x)
  end
  return pts
end

function fieldReset()
  FIELD.hits = { }
  FIELD_LINE = fieldPoints()
end

-- The arc is drawn in four passes, widest and faintest first,
-- down to a white core, so it reads as a sheet of energy rather
-- than as a stroked line. The colour is the notch.

function drawFieldArc(col)
  gfx.setColor(col[1], col[2], col[3], 0.10)
  gfx.setLineWidth(FIELD_W + FIELD_GLOW * 2)
  gfx.line(FIELD_LINE)
  gfx.setColor(col[1], col[2], col[3], 0.22)
  gfx.setLineWidth(FIELD_W + FIELD_GLOW)
  gfx.line(FIELD_LINE)
  gfx.setColor(col[1], col[2], col[3], 0.85)
  gfx.setLineWidth(FIELD_W)
  gfx.line(FIELD_LINE)
  gfx.setColor(1, 1, 1, 0.5)
  gfx.setLineWidth(2)
  gfx.line(FIELD_LINE)
  gfx.setLineWidth(1)
end

-- A rock reaching the field lights it where it struck, so a
-- breach is something the child watches the field take.

function fieldStrike(x)
  FIELD.hits[#FIELD.hits + 1] = { x = x, t = FIELD_HIT_T }
end

function fieldTick(dt)
  local keep = { }
  for _, h in ipairs(FIELD.hits) do
    h.t = h.t - dt
    if h.t > 0 then keep[#keep + 1] = h end
  end
  FIELD.hits = keep
end

function fieldBloom(h, col)
  local a = h.t / FIELD_HIT_T
  local r = 26 + (1 - a) * 74
  local y = fieldY(h.x)
  gfx.setColor(col[1], col[2], col[3], a * 0.5)
  gfx.circle("fill", h.x, y, r)
  gfx.setColor(1, 1, 1, a * 0.7)
  gfx.circle("fill", h.x, y, r * 0.35)
end

function drawField(level)
  local col = FIELD_RAMP[level] or FIELD_RAMP[0]
  drawFieldArc(col)
  for _, h in ipairs(FIELD.hits) do
    fieldBloom(h, col)
  end
end

-- A burning rock: a charred, SPIKED body dragging a flame trail
-- back along the line it is travelling. The spikes are a
-- different silhouette rather than a ring around the same one,
-- and the trail draws the path, so a child can see where the
-- rock is going. Nothing here asks anyone to tell red from
-- green, and with the flame taken away the star and the
-- crossing line still say which rock this is.

-- The whole star turns by cap.roll, which only a rock that has
-- been shot down carries: a tumbling silhouette says "knocked
-- out of its course" without a word.

function spikePoints(cap, r)
  local pts = { }
  local roll = cap.roll or 0
  for i = 0, DANGER_SPIKES * 2 - 1 do
    local a = i * math.pi / DANGER_SPIKES + roll
    local out = 1.0
    if i % 2 == 1 then out = 0.44 end
    local j = out - 0.08 + 0.08 * math.sin(cap.seed + i * 1.7)
    pts[#pts + 1] = cap.x + math.cos(a) * r * j
    pts[#pts + 1] = cap.y + math.sin(a) * r * j
  end
  return pts
end

-- Trail colours run hot at the rock and cool into smoke behind
-- it, so the head of the trail says which way it is headed.

function trailColor(f)
  if f < 0.35 then return FLAME end
  if f < 0.7 then return EMBER_LIT end
  return SMOKE_TRAIL
end

function trailPuff(cap, i, n)
  local d = STREAM_ROCK_R * DANGER_TRAIL_GAP * i
  local s = math.sqrt(cap.vx * cap.vx + cap.vy * cap.vy)
  if s <= 0 then s = 1 end
  return cap.x - cap.vx / s * d, cap.y - cap.vy / s * d,
    STREAM_ROCK_R * (0.74 - 0.5 * i / n)
end

function drawTrail(cap)
  local n = DANGER_TRAIL
  for i = n, 1, -1 do
    local x, y, r = trailPuff(cap, i, n)
    local col = trailColor(i / n)
    gfx.setColor(col[1], col[2], col[3], 0.8 * (1 - i / n))
    gfx.circle("fill", x, y, r)
  end
end

-- The star is drawn BRIGHT and the charred core dark, because
-- the cap covers the core: what has to carry the silhouette is
-- the ring of spikes standing out past the cap's edges, and
-- against space those only read if they glow.

-- The glow BREATHES rather than sitting there: a static ring
-- around an object reads as trim, and the whole point of this
-- rock is that it is a different kind of thing. Each one is on
-- its own phase, so a sky of them does not pulse in step.

function burnGlow(cap)
  local t = love.timer.getTime() * 6 + cap.seed
  local p = 0.5 + 0.5 * math.sin(t)
  gfx.setColor(EMBER_LIT[1], EMBER_LIT[2], EMBER_LIT[3],
    0.22 + 0.3 * p)
  gfx.polygon("fill",
    spikePoints(cap, STREAM_ROCK_R * (1.1 + 0.16 * p)))
end

function drawBurning(cap)
  drawTrail(cap)
  burnGlow(cap)
  gfx.setColor(EMBER_LIT[1], EMBER_LIT[2], EMBER_LIT[3])
  gfx.polygon("fill", spikePoints(cap, STREAM_ROCK_R))
  gfx.setColor(EMBER[1], EMBER[2], EMBER[3])
  gfx.polygon("fill",
    spikePoints(cap, STREAM_ROCK_R * 0.8))
end

-- The saucer's three lamps ARE the charge meter: they go out on
-- a shot and light again one by one, so a child sees at a
-- glance whether the gun is ready. frac is 0 to 1.

SHIP_LAMPS = 3

function shipLamp(cx, cy, u, i)
  gfx.circle("fill", cx + (i - 2) * 5.5 * u,
    cy + ((i == 2) and 1 or 0.5) * u, 0.75 * u)
end

function shipLamps(cx, cy, u, frac)
  for i = 1, SHIP_LAMPS do
    if frac >= i / SHIP_LAMPS then
      gfx.setColor(LAMP[1], LAMP[2], LAMP[3])
    else
      gfx.setColor(LAMP_OFF[1], LAMP_OFF[2], LAMP_OFF[3])
    end
    shipLamp(cx, cy, u, i)
  end
end

function drawShip(cx, cy, u, frac)
  gfx.setColor(HULL[1], HULL[2], HULL[3])
  gfx.ellipse("fill", cx, cy, 8 * u, 2.2 * u)
  gfx.setColor(DOME[1], DOME[2], DOME[3])
  gfx.ellipse("fill", cx, cy - 2.4 * u, 3.2 * u, 2.4 * u)
  shipLamps(cx, cy, u, frac)
end

-- The charge glow under the hull brightens with the lamps, so
-- readiness reads as brightness as well as a count. Rings are
-- drawn outward first, so the faintest sits behind.

CHARGE_RINGS = 3

function drawCharge(cx, cy, u, frac)
  for i = CHARGE_RINGS, 1, -1 do
    gfx.setColor(DOME[1], DOME[2], DOME[3],
      frac * 0.3 * (1 - (i - 1) / CHARGE_RINGS))
    gfx.ellipse("fill", cx, cy, (8 + i * 1.6) * u,
      (2.2 + i * 1.1) * u)
  end
end
