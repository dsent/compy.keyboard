-- Press-count learning engine for the untimed find-key drills
-- (Press, Find, Alt, Bubble, Hide, Load the train). Every
-- target token -- a physical key for Press/Find, a produced
-- glyph for Alt -- carries a learning record in
-- st.learn[token] = { n, last }:
--   n     its first-try press count (n == 0 means MANDATORY: a
--         new token not yet cleared first-try),
--   last  st.lturn (a global clock) when it was last shown.
-- Availability is the current notch's set (gaugeAvail), so a
-- token outside it is simply never drawn while its record
-- survives. The gauge fills with first-try hits this level to
-- st.goal; filling it opens a level screen, learning
-- PRESERVED. A miss never fills the gauge and only floors the
-- token's count, so a learned token never falls back to
-- mandatory. There is no auto demotion (teacher-only down), no
-- inter-target pause.
--
-- cfg holds { id, lo, hi, g, gtop, notch?, master?, prefer? }
-- plus the seams a scene needs when the shape of a level is its
-- own rather than the engine's:
--   sky      paint the background instead of the chrome pastel,
--   goal     the gauge goal for this level,
--   fill     put the level's target(s) in play,
--   atTop    is this the last level (celebration, not step-up),
--   reset    a teacher notch change landed; drop progression.
-- A drill that supplies none of them behaves exactly as before,
-- with the notch itself acting as the progression.

function gaugeAtTop(st, cfg)
  if cfg.atTop then return cfg.atTop(st, cfg) end
  return notchGet(cfg.id) >= cfg.hi
end

-- Where this level sits on the game's ladder, for the gauge's
-- segments: which rung, and how many there are. For a drill the
-- ladder is the notch range; a scene whose progression is its
-- own says so.

function gaugeRung(st, cfg)
  if cfg.rung then return cfg.rung(st, cfg) end
  return notchGet(cfg.id) - cfg.lo + 1
end

function gaugeRungs(st, cfg)
  if cfg.rungs then return cfg.rungs(st, cfg) end
  return cfg.hi - cfg.lo + 1
end

function gaugeAddGroup(out, g)
  for _, k in ipairs(KEYSETS[g]) do
    out[#out + 1] = k
  end
end

-- The available token list at the current notch: cfg.master
-- builds it for glyph targets (Alt); otherwise union the notch
-- ladder groups (Press/Find) over floor..notch.
function gaugeAvail(cfg)
  local out = { }
  local notch = notchGet(cfg.id)
  if cfg.master then
    cfg.master(out, notch)
    return out
  end
  for k = cfg.lo, notch do
    for _, g in ipairs(cfg.notch[k].add) do
      gaugeAddGroup(out, g)
    end
  end
  return out
end

-- Seed a learning record (n = 0 mandatory) for every newly
-- available token. Tokens already learned keep their counts, so
-- a notch change never resets progress.
function gaugeSeed(st, cfg)
  for _, k in ipairs(gaugeAvail(cfg)) do
    if not st.learn[k] then
      st.learn[k] = { n = 0, last = 0 }
    end
  end
end

function gaugeCurrent(st)
  return st.cur
end

function gaugeGlowing(st)
  return st.phase == "glow"
end

-- The count of available mandatory (n == 0) tokens, for the
-- reserve rule below.
function gaugeMandatory(st, list)
  local m = 0
  for _, k in ipairs(list) do
    if st.learn[k].n == 0 then m = m + 1 end
  end
  return m
end

-- Presses left in this level. A game whose gauge counts
-- something larger than a press -- Load the train counts
-- departed trains -- reports its press budget in st.plan and
-- its presses in st.spent, so the reserve rule below keeps
-- measuring presses against new tokens.
function gaugeLeft(st)
  if st.plan then return st.plan - st.spent end
  return st.goal - st.hits
end

-- Reserve: once the remaining budget is down to the mandatory
-- count, only mandatory tokens may be drawn, so new tokens come
-- first while there is still room for them.
function gaugeReserve(st, list)
  local mand = gaugeMandatory(st, list)
  return mand > 0 and gaugeLeft(st) <= mand
end

-- A token is unavailable if it is the one just answered or one
-- a scene is already holding in play (Hide's rotation).
function gaugeTaken(st, k, avoid)
  if k == avoid then return true end
  if st.hold and st.hold[k] then return true end
  return false
end

function gaugeCollect(st, list, reserve, avoid)
  local out = { }
  for _, k in ipairs(list) do
    local ok = (not reserve) or st.learn[k].n == 0
    if ok and not gaugeTaken(st, k, avoid) then
      out[#out + 1] = k
    end
  end
  return out
end

-- Candidates for the next target: avoid an immediate repeat
-- unless it is the only choice (e.g. a lone reserved item), and
-- fall back to the whole set rather than to nothing.
function gaugeCandidates(st, list)
  local reserve = gaugeReserve(st, list)
  local out = gaugeCollect(st, list, reserve, st.cur)
  if #out > 0 then return out end
  out = gaugeCollect(st, list, reserve, nil)
  if #out > 0 then return out end
  return list
end

-- Selection weight: rises with how long ago the token was shown
-- (spacing) and with low press count (GAUGE_LOWN_BIAS), so new
-- and rusty tokens come up more often.
function gaugeWeight(st, k)
  local e = st.learn[k]
  local age = st.lturn - e.last + 1
  return age * (1 + GAUGE_LOWN_BIAS / (e.n + 1))
end

function gaugePick(st, list)
  local total = 0
  for _, k in ipairs(list) do
    total = total + gaugeWeight(st, k)
  end
  local r = love.math.random() * total
  for _, k in ipairs(list) do
    r = r - gaugeWeight(st, k)
    if r <= 0 then return k end
  end
  return list[#list]
end

-- Record that a token has just been put in play: its recency is
-- bumped and the learning clock advances.
function gaugeMark(st, k)
  st.learn[k].last = st.lturn
  st.lturn = st.lturn + 1
end

-- Draw one token into play under the standard rules. A scene
-- holding several at once (Hide's rotation) calls this per
-- member rather than going through gaugeNext.
function gaugeTake(st, cfg)
  local k = gaugePick(st, gaugeCandidates(st, gaugeAvail(cfg)))
  gaugeMark(st, k)
  return k
end

-- Pick and show the next target: bump its recency, advance the
-- clock, and enter the glow phase. On a level's FIRST target,
-- cfg.prefer may swap the pick among the RESERVE-FILTERED
-- candidates (Alt's Shift-hint force-first), so it can never
-- bypass mandatory-first, before recency is recorded once.
function gaugeNext(st, cfg)
  local cands = gaugeCandidates(st, gaugeAvail(cfg))
  local k = gaugePick(st, cands)
  if st.fresh and cfg.prefer then
    k = cfg.prefer(st, cands, k)
  end
  st.fresh = false
  st.cur = k
  gaugeMark(st, k)
  st.fumbled = false
  st.phase = "glow"
end

-- The background for this level: a scene that owns its own sky
-- paints it, and everything else takes the chrome pastel for
-- the current notch.
function gaugePaint(st, cfg)
  if cfg.sky then
    cfg.sky(st, cfg)
    return
  end
  pastelLevel(notchGet(cfg.id) - cfg.lo)
end

-- STRETCH the goal up to the mandatory count so the gauge can
-- never fill while a new token is uncleared (the reserve
-- guarantee, robust to a teacher notch bump mid-level). cfg.g
-- is only a review floor.
function gaugeStretch(st, cfg, goal)
  local mand = gaugeMandatory(st, gaugeAvail(cfg))
  if goal < mand then return mand end
  return goal
end

function gaugeGoal(st, cfg)
  if cfg.goal then return cfg.goal(st, cfg) end
  local g = cfg.g
  if gaugeAtTop(st, cfg) then g = cfg.gtop end
  return gaugeStretch(st, cfg, g)
end

-- Put the level's target(s) in play. A single-target drill
-- glows one; a scene holding several supplies its own filler.
function gaugeFill(st, cfg)
  if cfg.fill then
    cfg.fill(st, cfg)
    return
  end
  gaugeNext(st, cfg)
end

-- Start a fresh level: reset the gauge, seed new tokens, set
-- the goal, paint the background and put the targets in play.
-- st.fresh lets prefer bias the first pick (Alt's Shift-hint
-- force-first).
function gaugeStartLevel(st, cfg)
  st.hits = 0
  st.event = nil
  gaugeSeed(st, cfg)
  st.goal = gaugeGoal(st, cfg)
  st.fresh = true
  gaugePaint(st, cfg)
  gaugeFill(st, cfg)
end

-- Enter the game from the menu: a clean learning slate, snap
-- the background to what the first level paints.
function gaugeEnter(st, cfg)
  st.learn = { }
  st.lturn = 0
  st.plan = nil
  gaugeStartLevel(st, cfg)
  pastelSnap()
end

-- The gauge filled: below the top notch a level-up cue, at the
-- top the celebration. The advance screen (phase "done") waits
-- for Tab; the notch itself moves on Tab, never here.
function gaugeWin(st, cfg)
  if gaugeAtTop(st, cfg) then
    st.event = "win"
  else
    st.event = "levelup"
  end
  st.phase = "done"
end

-- A correct key. First-try (no wrong press this presentation):
-- count the press, fill the gauge, win at the goal. After a
-- fumble: just advance -- no count, no fill (so a fumbled new
-- token stays mandatory and returns). Either way the next
-- glows at once (no inter-target pause).
function gaugeOnCorrect(st, cfg)
  if not st.fumbled then
    local e = st.learn[st.cur]
    e.n = e.n + 1
    st.hits = st.hits + 1
    if st.hits >= st.goal then
      gaugeWin(st, cfg)
      return
    end
  end
  gaugeNext(st, cfg)
end

-- The first wrong key for a target: mark the presentation
-- fumbled (so several wrong keys read as one miss) and floor
-- token's count: a mandatory token (n == 0) stays mandatory; a
-- learned token never falls below 1. Later wrong keys no-op.
function gaugeOnWrong(st, cfg)
  if st.fumbled then return end
  st.fumbled = true
  local e = st.learn[st.cur]
  if e.n > 0 then
    e.n = math.max(1, e.n - 1)
  end
end

-- Teacher chord: shift the notch within bounds and, if it
-- changed, start a fresh level. Learning is PRESERVED
-- (availability moves). A scene whose progression is separate
-- from the notch drops it here through cfg.reset, since the
-- level it earned was earned against the old difficulty. A
-- no-op shift is ignored.
function gaugeOnNotch(st, cfg, delta)
  local old = notchGet(cfg.id)
  notchShift(cfg.id, delta, cfg.lo, cfg.hi)
  if notchGet(cfg.id) == old then return end
  if cfg.reset then cfg.reset(st, cfg) end
  gaugeStartLevel(st, cfg)
end
