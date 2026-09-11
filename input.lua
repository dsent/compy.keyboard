-- Input lifecycle and event model.
--
-- The game registers compy.input.hooks.* instead of love.*
-- handlers -- the framework captures love.* into the same
-- hooks, so this only says it out loud -- and its reserved
-- chords and the Alt class are compy.input.shortcuts entries,
-- which run ahead of the hooks.
--
-- OS key repeat is filtered by the isrepeat flag the hooks get
-- as their third argument. setTextInput(true) below is for the
-- device build: the IDE makes the same call at its own boot, so
-- this line matters there and is harmless here (undoing it on
-- exit would be a no-op). Global key repeat is left ON -- the
-- repeats are filtered rather than suppressed, and stopping
-- them would change what scenes see.
--
-- keypressed and textinput have NO guaranteed order between
-- them, and nothing here may depend on which arrives first.
-- So acceptance never asks whether the producing key is held:
-- at the first character of a press that answer differs by
-- build. A character is CLAIMED instead, one per press -- has a
-- character for this key been taken since the key was last down
-- -- and the claim is released by asking the KEYBOARD once a
-- frame (inputTick), never by an event. No grace window, no
-- frame clock.
--
-- Modifier state is asked of the keyboard through Key, which
-- folds each l/r pair the way a combo string does; the key-cap
-- renderer needs it from draw, where there is no event to
-- consult.

-- A chord's trigger is claimed when the chord is taken: Alt+H,
-- then letting go of Alt, leaves H repeating, and those
-- characters are not a typed answer. Claiming twice is free.
local function claimChord(k)
  spendGlyph(k)
end

-- The app's reserved keys, none of which reaches a scene.
--
-- stop_here says the combo is taken. ignore_repeat goes inside
-- it wherever there is an action, since stop_here alone re-runs
-- that action on every OS repeat: a held ctrl+alt+up would ramp
-- the notch every frame. A claim goes OUTSIDE it -- an action
-- fires once per press, a claim stands while the key is down.
--
-- A combo is its modifier set EXACTLY, so a gesture that also
-- tolerates Shift is bound twice, to the same handler value.
-- "alt+*" and "alt+shift+*" are the swallowing classes: every
-- Alt chord without Ctrl is taken, never reaching a scene as a
-- typed target, and their only job is the claim. An exact
-- binding wins over a class, so alt+p / alt+shift+p pause and
-- claim for themselves.
-- Ctrl+Alt+H is a different modifier set, so a different class,
-- and it too is bound twice. It re-arms the active scene's hint
-- through the onHint descriptor entry, the way ctrl+alt+up
-- reaches onNotch. Being a shortcut it is taken in EVERY scene,
-- including the ones that judge key targets.
local function register_reserved()
  local fn = compy.input.fn
  local sc = compy.input.shortcuts.keypressed
  local back = fn.stop_here(fn.ignore_repeat(goBack))
  local notch_up = fn.stop_here(fn.ignore_repeat(function()
    notchAdjust(1)
  end))
  local notch_down = fn.stop_here(fn.ignore_repeat(function()
    notchAdjust(-1)
  end))
  sc["shift+escape"] = back
  sc["alt+shift+escape"] = back
  sc["ctrl+alt+up"] = notch_up
  sc["ctrl+alt+shift+up"] = notch_up
  sc["ctrl+alt+down"] = notch_down
  sc["ctrl+alt+shift+down"] = notch_down
  sc["alt+*"] = fn.stop_here(claimChord)
  sc["alt+shift+*"] = fn.stop_here(claimChord)
  local pause = fn.stop_here(function(k, _, isr)
    claimChord(k)
    if not isr then pauseToggle() end
  end)
  sc["alt+p"] = pause
  sc["alt+shift+p"] = pause
  local rearm = fn.ignore_repeat(hintReenable)
  local hint = fn.stop_here(function(k, sk, isr)
    claimChord(k)
    rearm(k, sk, isr)
  end)
  sc["ctrl+alt+h"] = hint
  sc["ctrl+alt+shift+h"] = hint
end

function inputInit()
  love.keyboard.setTextInput(true)
  GLYPH_CLAIMED = { }
  compy.input.hooks.keypressed = appKeypressed
  compy.input.hooks.keyreleased = appKeyreleased
  compy.input.hooks.textinput = appTextinput
  register_reserved()
end

function goBack()
  if isGameScene(ACTIVE) then
    gotoScene("menu")
  end
end

function notchAdjust(delta)
  local s = SCENES[ACTIVE]
  if s and s.onNotch then s.onNotch(delta) end
end

-- The teacher's hint chord, dispatched like the notch: a scene
-- that teaches answers onHint, and only alt.lua does. It stays
-- inert behind the pause screen, where the notch does not.
function hintReenable()
  if PAUSED then return end
  local s = SCENES[ACTIVE]
  if s and s.onHint then s.onHint() end
end

-- One character per key press reaches a scene. textinput
-- carries no isrepeat of its own, and this is what recognises a
-- repeat without asking whether the key is held.
GLYPH_CLAIMED = { }

-- The key a produced character came from: space, a shifted
-- symbol through SHIFT_MAP inverted, a letter its lowercase
-- key, else itself. It lives here because scene files are
-- lazy-loaded and config.lua's SHIFT_MAP is not.
GLYPH_BASE = { }
for base, sym in pairs(SHIFT_MAP) do
  GLYPH_BASE[sym] = base
end

function glyphBaseKey(ch)
  if ch == " " then return "space" end
  if GLYPH_BASE[ch] then return GLYPH_BASE[ch] end
  if isAlphaChar(ch) then return string.lower(ch) end
  return ch
end

-- The device call RAISES on a string that is not one of LOVE's
-- key constants ("Invalid key constant: ~"), and a produced
-- character is not always a key name -- an IME or dead-key
-- composition can map to nothing this keyboard has.
-- A claim that cannot be polled can never be released, so it is
-- never taken: such a character is accepted, and holding one
-- would repeat it. No scene targets one. Asked once per name,
-- since the answer cannot change.
local POLLABLE = { }
local function pollable(k)
  local known = POLLABLE[k]
  if known == nil then
    known = pcall(Key.any_pressed, k)
    POLLABLE[k] = known
  end
  return known
end

-- Claim this key's glyph for the current press. True means the
-- caller must DROP it: a glyph for this key has already been
-- taken and the key has not been up since.
-- Keypresses do not use this: they have the real isrepeat flag.
function spendGlyph(k)
  if GLYPH_CLAIMED[k] then return true end
  if not pollable(k) then return false end
  GLYPH_CLAIMED[k] = true
  return false
end

-- Claims are released by the DEVICE, once a frame, and by
-- nothing else. keyreleased is not consulted: a release and a
-- trailing repeat character are the same shape on that channel,
-- so clearing at the release would let that character through
-- as a fresh one nobody typed. Asking the keyboard needs no
-- window, no clock and no ordering.
function inputTick()
  for k in pairs(GLYPH_CLAIMED) do
    if not Key.any_pressed(k) then
      GLYPH_CLAIMED[k] = nil
    end
  end
end

-- isr is the hook's isrepeat: a held key is filtered at the
-- source. capslock keeps the exemption it has upstream; under
-- isrepeat nothing can eat a toggle, so its only effect now is
-- that capslock repeats reach capsToggle.
-- Scene input is dropped while the help widget (this repo's
-- overlay) is shown -- the game is frozen behind it.
function appKeypressed(k, _, isr)
  if isr and k ~= "capslock" then return end
  dbgLog("KP " .. k)
  -- A chord that is NOT swallowed still owns its trigger: it
  -- reaches the scene by design, and if its modifier goes up
  -- while the trigger stays down the repeats produce plain
  -- characters.
  if Key.ctrl() or Key.alt() then claimChord(k) end
  if k == "capslock" then capsToggle() end
  if PAUSED then return end
  if helpOverlayShown() then return end
  -- A modifier's own press names no combo, so no class can take
  -- one. Alt+key is a chord whatever the key is, so a modifier
  -- pressed while Alt is held is dropped here, Alt's own press
  -- included -- named rather than polled, since whether
  -- the device already reports a key down inside its own
  -- keypressed is not something to depend on. Ctrl+Alt is a
  -- different modifier set and passes: scenes ignore modifiers,
  -- but the intro finishes its typewriter on any key.
  local alt = Key.alt() or Key.is_alt(k)
  if alt and not Key.ctrl() and Key.is_mod(k) then
    return
  end
  local s = SCENES[ACTIVE]
  if s and s.keypressed then s.keypressed(k) end
end

-- No judgement state here: claims are released by inputTick's
-- poll. The dispatch stays -- bubble.lua judges its hold on
-- this channel.
function appKeyreleased(k)
  dbgLog("KR " .. k)
  local s = SCENES[ACTIVE]
  if s and s.keyreleased then s.keyreleased(k) end
end

-- Judged by the scene, and dropped here while paused or behind
-- help. A character made with Alt or Ctrl held belongs to a
-- chord and is never a target -- only Shift modifies one.
function appTextinput(t)
  if PAUSED then return end
  if Key.alt() then return end
  if Key.ctrl() then return end
  if helpOverlayShown() then return end
  dbgLog("TI " .. t .. " sh=" .. tostring(Key.shift()))
  if isAlphaChar(t) then
    capsReconcile(t, Key.shift())
  end
  local s = SCENES[ACTIVE]
  if s and s.textinput then s.textinput(t) end
end
