-- keyboard: the program a 4-6 year-old launches to meet the
-- keyboard. One program: a typewriter intro, a mini-game menu,
-- and the mini-games. main.lua defines update/draw and loads
-- the scenes once here at boot; the keyboard/text callbacks are
-- compy.input hooks and shortcuts, registered in input.lua.

gfx = love.graphics

-- Debug logging. When DEBUG is on, diagnostics go to a log file
-- in the save dir (read via adb), not an on-screen overlay.
-- update/draw also run under pcall, so a thrown frame is logged
-- and recovered (the outer gfx.pop still runs, no stack leak)
-- instead of freezing or crashing, so the app stays runnable
-- while the problem is captured. Set DEBUG = false to ship.

DEBUG = false
DBG_LOG = "keyboard-debug.log"
DBG_FRAME = 0
DBG_LASTERR = nil

function dbgLog(msg)
  if not DEBUG then 
    return 
  end
  local line = DBG_FRAME .. " " .. msg
  print("[KBD] " .. line)
  pcall(love.filesystem.append, DBG_LOG, line .. "\n")
end

-- Log a thrown error once (deduped) so a per-frame throw does
-- not spam the log.

function dbgLogErr(where, err)
  if err == DBG_LASTERR then return end
  DBG_LASTERR = err
  dbgLog(where .. " ERR @ " .. tostring(ACTIVE)
    .. ": " .. tostring(err))
end

-- Reset the log + record the save dir (pcall'd at boot so a
-- restricted filesystem can never block startup). Read logs via
-- `adb logcat | grep KBD` -- the save dir is not pullable under
-- Android scoped storage.

function dbgBoot()
  love.filesystem.write(DBG_LOG, "=== boot ===\n")
  dbgLog("save dir " .. love.filesystem.getSaveDirectory())
end

-- Shared infrastructure plus the two scenes needed at boot
-- (intro, menu). Mini-games are lazy-loaded on first entry.

dofile("config.lua")
dofile("pastel.lua")
dofile("locale.lua")
dofile("layout.lua")
dofile("sound.lua")
dofile("keyboard_view.lua")
dofile("indicators.lua")
dofile("notch.lua")
dofile("gauge.lua")
dofile("scene.lua")
dofile("input.lua")
dofile("help.lua")
dofile("pause.lua")
dofile("firework.lua")
dofile("findkey.lua")
dofile("hints.lua")
dofile("intro.lua")
dofile("menu.lua")

-- Games present in this build (lazy-loaded). Adding a slice
-- registers its file here; the menu picks it up structurally.

SCENE_FILE.press = "press.lua"
SCENE_FILE.find = "find.lua"
SCENE_FILE.astro = "astro.lua"
SCENE_FILE.alt = "alt.lua"
SCENE_FILE.words = "words.lua"
SCENE_FILE.bubble = "bubble.lua"
SCENE_FILE.hide = "hide.lua"
SCENE_FILE.train = "train.lua"

notchInit()
inputInit()

-- Suppress the system pointer: relative mode keeps it off the
-- screen edges so the Android nav/status bars never reveal.
-- The keyboard uses no mouse.
-- Relative mode is REAL device state: it outlives the run and
-- lands in whatever the project exits to, and the runner does
-- not put it back, so this restores what it found.
-- compy.before_exit fires on every stop path including Ctrl+Esc
-- but NOT on a raise -- so a run that ends by raising leaves
-- the mode on, and the next run restores that faithfully.
-- TODO(root-access): replace with trackpad disable on entry.

POINTER_RELATIVE_WAS = love.mouse.getRelativeMode()
love.mouse.setRelativeMode(true)
compy.before_exit = function()
  love.mouse.setRelativeMode(POINTER_RELATIVE_WAS)
end
if DEBUG then pcall(dbgBoot) end
gotoScene("intro")

-- Hold ticks until the first frame is drawn, and cap dt, so a
-- slow boot or GC spike never leaks into the first update or
-- fast-forwards an animation (e.g. the intro typing) at once.
-- DREW_ONCE flips true at the end of the first love.draw.

DREW_ONCE = false
MAX_DT = 0.1

function updateStep(dt)
  if not DREW_ONCE then 
    return 
  end
  if dt > MAX_DT then dt = MAX_DT 
  end
  pastelTick(dt)
  if PAUSED then 
    return 
  end
  if helpOverlayShown() then 
    return 
  end
  sceneUpdate(dt)
end

-- inputTick releases claims whose key the keyboard reports up.
-- It runs HERE, not in updateStep, which returns early before
-- the first draw, while paused, and while the help widget
-- (this repo's overlay) is shown -- and showing it is a HELD
-- Alt+H, so a claim would outlive its key in ordinary use.
function love.update(dt)
  DBG_FRAME = DBG_FRAME + 1
  inputTick()
  if not DEBUG then
    return updateStep(dt)
  end
  local ok, err = pcall(updateStep, dt)
  if not ok
  then dbgLogErr("UPDATE", err)
  end
end

-- Draw in the 960x540 reference canvas, scaled uniformly and
-- centered to the real resolution. Nothing scrolls.

function drawStep()
  sceneDraw()
  if PAUSED then
    drawPauseOverlay()
  else
    drawHelpLayer()
  end
end

function love.draw()
  pastelDrawBg()
  local w, h = gfx.getDimensions()
  local s = math.min(w / REF_W, h / REF_H)
  gfx.push()
  gfx.translate((w - REF_W * s) / 2, (h - REF_H * s) / 2)
  gfx.scale(s, s)
  if not DEBUG then
    drawStep()
  else
    local ok, err = pcall(drawStep)
    if not ok then dbgLogErr("DRAW", err) end
  end
  gfx.pop()
  DREW_ONCE = true
end
