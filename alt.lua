-- Exercise 4: Alt characters. One produced GLYPH is shown as a
-- keycap in the top band; the child makes exactly it on a
-- live-case keyboard (letters follow Caps/Shift; symbols show
-- their shifted label only with Shift held). Acceptance is by
-- the produced glyph (the plastic-screwdriver rule): printable
-- targets match on textinput == target, however produced (Shift
-- or Caps both fine); the non-printing targets (Backspace, Tab,
-- Enter) emit no textinput, so they match on the keypressed key
-- constant. A wrong input knocks (once per target). Same
-- press-count gauge, level-up screen, pastel, and exit hint as
-- Press/Find (findkey.lua); folds the Caps/Shift games. The
-- first few Shift-requiring targets show an inline Shift hint
-- (hints.lua); Ctrl+Alt+H re-arms it.

-- Append a glyph group's targets to a round's master set.
function altAppendGroup(out, g)
  for _, k in ipairs(ALT_GROUPS[g]) do
    out[#out + 1] = k
  end
end

-- Build the master glyph set for a notch (floor..notch union).
function altBuildMaster(out, notch)
  for k = ALT_LO, notch do
    for _, g in ipairs(ALT_NOTCH[k].groups) do
      altAppendGroup(out, g)
    end
  end
end

ALT = {
  burst = nil, fw = { }, hint = 0, htime = 0
}
ALT_CFG = {
  id = "alt", lo = ALT_LO, hi = ALT_HI,
  g = ALT_G, gtop = ALT_GTOP, master = altBuildMaster
}

-- The non-printing key targets (matched via keypressed); every
-- other target is a produced glyph (matched via textinput).
ALT_KEYTARGET = {
  backspace = true, tab = true, ["return"] = true
}

function altIsKeyTarget(item)
  return ALT_KEYTARGET[item] == true
end

-- A target needs Shift to produce iff it is a capital letter or
-- a shifted symbol (its glyph is a SHIFT_MAP value). Lowercase,
-- digits, unshifted punctuation, space, and the non-printing
-- keys do not.
function altNeedsShift(item)
  return isUpperChar(item) or GLYPH_BASE[item] ~= nil
end

-- The physical key a target is produced on, for the success
-- burst and the hint: a non-printing key is itself, space is
-- "space", a capital its lowercase key, a symbol its base key,
-- a letter or digit itself.
function altBaseKey(item)
  if altIsKeyTarget(item) then return item end
  return glyphBaseKey(item)
end

-- The top-band keycap label for a target: a friendly name for
-- the non-printing keys and space, else the glyph itself.
-- A target drawn as a board key (the engraved enlarged cap):
-- the service keys, and space (its cap IS its picture).
function altTargetName(item)
  if item == " " then return "space" end
  if altIsKeyTarget(item) then return item end
  return nil
end

function altDrawTarget(item)
  local name = altTargetName(item)
  if name then
    drawKeycapTarget(name)
    return
  end
  drawTargetCap(item)
end

-- Prefer a Shift-requiring glyph for a level's FIRST target if
-- the hint is armed, so the first character teaches the Shift
-- chord right away. It only chooses among the engine's
-- reserve-filtered candidates, so it never bypasses a mandatory
-- glyph; the lowercase notches (and a mandatory-only reserve
-- with no shifted glyph) make it a no-op. (ALT_CFG.prefer.)
function altPreferShift(st, cands, k)
  if ALT.hint <= 0 then return k end
  if altNeedsShift(k) then return k end
  for _, c in ipairs(cands) do
    if altNeedsShift(c) then return c end
  end
  return k
end
ALT_CFG.prefer = altPreferShift

-- The Shift hint shows while the budget lasts and the current
-- glowing target needs Shift.
function altHintActive()
  return ALT.hint > 0 and gaugeGlowing(ALT)
    and altNeedsShift(gaugeCurrent(ALT))
end

-- Teacher chord (Ctrl+Alt+H): re-arm the hint budget for the
-- next few shifted characters, restart the finger sweep, and
-- play a soft blip. Reached through this scene's onHint entry:
-- the chord is a shortcut, so it never becomes scene input, and
-- its 'h' cannot trail in either -- the shortcut claims it.
function altHintReenable()
  ALT.hint = ALT_HINT_MORE
  ALT.htime = 0
  SOUND.hint()
end

-- The hint budget is armed before gaugeEnter so the first-pick
-- hook (ALT_CFG.prefer) can force-first a shifted target.
function altEnter()
  notchEnterReset("alt")
  ALT.burst = nil
  ALT.fw = { }
  ALT.hint = ALT_HINT_FIRST
  ALT.htime = 0
  gaugeEnter(ALT, ALT_CFG)
end

function altUpdate(dt)
  ALT.htime = ALT.htime + dt
  fwUpdate(ALT, dt)
  if ALT.burst then
    ALT.burst.t = ALT.burst.t - dt
    if ALT.burst.t <= 0 then ALT.burst = nil end
  end
end

-- A correct target: a success burst on its base key, the chime,
-- the gauge advance, the celebration, and one hint spent if the
-- target was being hinted.
function altHit()
  local hinted = altHintActive()
  local r = keyRect(altBaseKey(gaugeCurrent(ALT)))
  if r then
    ALT.burst = { x = r.x + r.w / 2,
      y = r.y + r.h / 2, t = 0.5 }
  end
  SOUND.match()
  gaugeOnCorrect(ALT, ALT_CFG)
  fkCelebrate(ALT)
  if hinted then ALT.hint = ALT.hint - 1 end
end

-- A wrong input: a soft knock and the gauge fumble. The knock
-- fires only on the first wrong of a target (before the fumble
-- flag is set), so several wrong keys read as one miss and a
-- held wrong key (its textinput repeats every frame) cannot
-- knock continuously.
function altWrong()
  if not ALT.fumbled then SOUND.reject() end
  gaugeOnWrong(ALT, ALT_CFG)
end

-- Printable targets are judged here: textinput == the produced
-- glyph, however made. Non-printing targets ignore textinput
-- (keypressed judges them).
--
-- spendGlyph takes one glyph per press and drops the repeats
-- until the keyboard reports the key up: a held wrong key
-- knocks once, a held right key does not bleed a miss onto the
-- next target, and a chord's trailing glyph cannot fumble one.
function altTextinput(ch)
  if spendGlyph(altBaseKey(ch)) then return end
  if fkDone(ALT) then return end
  if not gaugeGlowing(ALT) then return end
  if altIsKeyTarget(gaugeCurrent(ALT)) then return end
  if ch == gaugeCurrent(ALT) then
    altHit()
  else
    altWrong()
  end
end

-- A play keypress: only non-printing key-targets are judged
-- here (printable targets are judged in textinput, since their
-- base key also fires keypressed). A wrong real key knocks; a
-- modifier or capslock never does.
function altPlayKey(k)
  if not gaugeGlowing(ALT) then return end
  if not altIsKeyTarget(gaugeCurrent(ALT)) then return end
  if k == gaugeCurrent(ALT) then
    altHit()
  elseif not Key.is_mod(k) and k ~= "capslock" then
    altWrong()
  end
end

-- On the level-up screen only Tab is handled (no printable
-- replay key, so nothing trails into the next level); any stray
-- glyph there is dropped by altTextinput's fkDone guard anyway.
-- Ctrl+Alt+H is not matched here any more: it is a shortcut
-- (input.lua) that calls onHint below, so this scene sees no
-- chord at all.
function altKeypressed(k)
  if fkDone(ALT) then
    fkDoneKey(ALT, ALT_CFG, k)
    return
  end
  altPlayKey(k)
end

function altOnNotch(delta)
  fkOnNotch(ALT, ALT_CFG, delta)
end

function altDone()
  return fkDone(ALT)
end

-- The base key is "ready" -- pressing it now yields the target
-- -- when the keyboard already makes the target's case/glyph:
-- for a capital that is Caps XOR Shift (capsEffectiveUpper);
-- for a shifted symbol it is Shift held (Caps makes none). So
-- a Caps-Lock capital is ready with no Shift, and the hint must
-- not then point at Shift.
function altHintReady(item)
  if isAlphaChar(item) then return capsEffectiveUpper() end
  return Key.shift()
end

-- The hint's keyboard glows: while the base key is not yet
-- ready (wrong case / no Shift) the Shift keys glow ("Shift");
-- once ready, the base key to press glows. A held Shift stays
-- lit so the chord reads as one gesture (a Caps-made capital is
-- ready with no Shift, so Shift is not lit then).
function altHintDeco(deco)
  if altHintReady(gaugeCurrent(ALT)) then
    if Key.shift() then
      deco.lshift = { bg = COL_WARM_DIM }
      deco.rshift = { bg = COL_WARM_DIM }
    end
    deco[altBaseKey(gaugeCurrent(ALT))] =
      { bg = COL_WARM, glow = COL_GLOW }
  else
    deco.lshift = { bg = COL_WARM, glow = COL_GLOW }
    deco.rshift = { bg = COL_WARM, glow = COL_GLOW }
  end
end

-- The finger points at the key to press next: the left Shift
-- until the base key is ready, then the base key itself.
function altHintFinger()
  local cell = keyRect("lshift")
  if altHintReady(gaugeCurrent(ALT)) then
    cell = keyRect(altBaseKey(gaugeCurrent(ALT)))
  end
  if cell then hintFinger(cell, ALT.htime) end
end

-- No keyboard glow during normal play (the child produces the
-- glyph unaided); the Shift hint's glows while it is active.
function altDeco()
  local deco = { }
  if altHintActive() then altHintDeco(deco) end
  return deco
end

-- The play layer: the produced-glyph target keycap, the win
-- gauge, and the persistent exit hint (drawn only while
-- playing, never under the advance screen).
function altDrawPlay()
  if gaugeGlowing(ALT) then
    altDrawTarget(gaugeCurrent(ALT))
  end
  drawWinGauge(fkGauge(ALT, ALT_CFG))
  fkDrawExitHint()
end

function altDraw()
  local done = altDone()
  drawKeyboard(altDeco())
  if not done then altDrawPlay() end
  if altHintActive() then altHintFinger() end
  if ALT.burst then drawBurst(ALT.burst) end
  drawIndicators(CAPS_STATE.on)
  if done then
    fkDrawEndScreen(ALT, ALT_CFG)
  end
  fwDraw(ALT)
end

registerScene("alt", {
  enter = altEnter,
  update = altUpdate,
  draw = altDraw,
  keypressed = altKeypressed,
  textinput = altTextinput,
  onNotch = altOnNotch,
  onHint = altHintReenable,
  noHint = altDone
})
