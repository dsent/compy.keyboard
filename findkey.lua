-- Shared scene core for the untimed find-key drills (Press the
-- key, Find the key). It drives the press-count learning engine
-- (gauge.lua), the keycap target, the chime + burst, the
-- firework (firework.lua), the level-up screen, and the
-- persistent Shift+Esc hint. Each scene owns a state table (st:
-- pulse, burst, fw, plus the gauge fields) and a cfg
-- ({ id, notch, lo, hi, g, gtop }); the only per-scene
-- difference is the keyboard decoration the scene passes to
-- fkDraw (Press glows the target key; Find passes none).

function fkEnter(st, cfg)
  notchEnterReset(cfg.id)
  st.pulse = 0
  st.burst = nil
  st.wrong = nil
  st.fw = { }
  gaugeEnter(st, cfg)
end

function fkUpdate(st, cfg, dt)
  st.pulse = st.pulse + dt
  fwUpdate(st, dt)
  if st.burst then
    st.burst.t = st.burst.t - dt
    if st.burst.t <= 0 then st.burst = nil end
  end
  if st.wrong then
    st.wrong.t = st.wrong.t - dt
    if st.wrong.t <= 0 then st.wrong = nil end
  end
end

-- A round win plays win.ogg; a top-notch win plays wow.ogg and
-- launches the firework.
function fkCelebrate(st)
  if st.event == "levelup" then
    SOUND.win()
  elseif st.event == "win" then
    SOUND.wow()
    fwStart(st)
  end
end

function fkHit(st, cfg, k)
  local r = keyRect(k)
  if r then
    st.burst = { x = r.x + r.w / 2,
      y = r.y + r.h / 2, t = 0.5 }
  end
  SOUND.match()
  gaugeOnCorrect(st, cfg)
  fkCelebrate(st)
end

function fkDone(st)
  return st.phase == "done"
end

-- Tab on the level-up screen (gauge games): below the top step
-- up into a fresh level; at the top, another review level at
-- the same one (endless). Learning is kept. A scene whose
-- progression is its own rather than the notch (Hide's
-- rotation, Load the train's platforms) advances it here.
function fkAdvance(st, cfg)
  st.fw = { }
  st.burst = nil
  if cfg.advance then
    cfg.advance(st, cfg)
  elseif gaugeAtTop(st, cfg) then
    -- another review level at the same top notch
    gaugeStartLevel(st, cfg)
  else
    gaugeOnNotch(st, cfg, 1)
  end
end

-- The gauge games' Tab label: step up a level, or keep playing
-- the endless review level at the top.
function fkLevelTabLabel(st, cfg)
  if gaugeAtTop(st, cfg) then
    return STR.tab_more
  end
  return STR.tab_level
end

-- Level-up screen key (gauge games): Tab only -- the gauge
-- always moves forward, so there is no Enter/R replay.
function fkDoneKey(st, cfg, k)
  if k == "tab" then
    fkAdvance(st, cfg)
  end
end

-- A wrong key: knock + pink glow only on the FIRST wrong of a
-- target (so several wrong keys before the right one are one
-- miss), then the gauge fumble (it floors the token's count).
function fkWrong(st, cfg, k)
  if not st.fumbled then
    SOUND.reject()
    st.wrong = { key = k, t = 0.3 }
  end
  gaugeOnWrong(st, cfg)
end

function fkKeypressed(st, cfg, k)
  if fkDone(st) then
    fkDoneKey(st, cfg, k)
    return
  end
  if not gaugeGlowing(st) then return end
  if k == gaugeCurrent(st) then
    fkHit(st, cfg, k)
  elseif not isMod(k) and k ~= "capslock" then
    fkWrong(st, cfg, k)
  end
end

-- A teacher notch change that lands a fresh round also clears
-- scene-owned visuals (a firework/burst from a just-shown win
-- screen), which the gauge cannot reach.
function fkOnNotch(st, cfg, delta)
  local before = notchGet(cfg.id)
  gaugeOnNotch(st, cfg, delta)
  if notchGet(cfg.id) ~= before then
    st.fw = { }
    st.burst = nil
  end
end

-- Subtle exit affordance during play: a light chip behind dark
-- text so Shift+Esc stays legible over any pastel background.
-- Anchored left but clear of the clipped left edge (x >= 6).
function fkDrawExitHint()
  local font = getFont(FONT_HINT)
  local txt = STR.back_hint
  local y = REF_H - font:getHeight() - 8
  local w = font:getWidth(txt) + 12
  gfx.setColor(COL_KEY[1], COL_KEY[2], COL_KEY[3], 0.7)
  gfx.rectangle("fill", 6, y - 3, w, font:getHeight() + 6, 5)
  gfx.setFont(font)
  gfx.setColor(COL_TEXT)
  gfx.print(txt, 12, y)
end

-- Hunt's completion screen: a calm compliment with Enter/R to
-- replay and Shift+Esc to return to the menu.
function fkDrawDoneScreen()
  gfx.setColor(COL_OVERLAY)
  gfx.rectangle("fill", 0, 0, REF_W, REF_H)
  drawBandText(STR.good_job, { 140, 220 },
    getFont(FONT_HEAD), COL_WARM)
  drawKeyHint("return", STR.replay, { 306, 346 }, COL_TEXT)
  drawBandText(STR.back_hint, { 356, 396 },
    getFont(FONT_STATUS), COL_DIM)
end

-- The gauge games' level-up screen: only the compliment and the
-- Tab cue. The replay/exit lines were dropped -- children were
-- bailing via the Shift+Esc line shown here; the play screen
-- keeps its own persistent exit hint.
function fkDrawLevelScreen(tabLabel)
  gfx.setColor(COL_OVERLAY)
  gfx.rectangle("fill", 0, 0, REF_W, REF_H)
  drawBandText(STR.good_job, { 196, 276 },
    getFont(FONT_HEAD), COL_WARM)
  drawKeyHint("tab", tabLabel, { 300, 336 }, COL_TEXT)
end

-- The brief wrong-key pink glow, but never over an existing
-- decoration (e.g. a fresh target glow on the same key after a
-- DROP reshuffle).
function fkWrongDeco(st, deco)
  local w = st.wrong
  if w and not deco[w.key] then
    deco[w.key] = { glow = COL_PINK }
  end
end

-- The shared draw skeleton. deco is the per-key keyboard
-- decoration (Press glows the target key; Find passes { }); a
-- brief pink glow marks the last wrong key. The keycap target
-- shows while a target is live in either game. overlay is an
-- optional scene painter called over the board (Bubble draws
-- its bubble there); the gauge games pass none.
function fkDraw(st, cfg, deco, overlay)
  local glow = gaugeGlowing(st)
  local done = fkDone(st)
  fkWrongDeco(st, deco)
  drawKeyboard(deco)
  if overlay then overlay() end
  if glow then drawKeycapTarget(gaugeCurrent(st)) end
  if st.burst then drawBurst(st.burst) end
  if not done then drawWinGauge(st.hits, st.goal) end
  drawIndicators(CAPS_STATE.on)
  if done then
    fkDrawLevelScreen(fkLevelTabLabel(st, cfg))
  end
  fwDraw(st)
  if not done then fkDrawExitHint() end
end
