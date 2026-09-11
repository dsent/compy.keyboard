-- Effective Caps Lock tracker and the three lock decals.
-- LOVE 11.5 has no lock-state API, so effective Caps is an
-- estimate: it starts off, flips on each capslock keypress
-- edge, and is re-derived from every alphabetic textinput as
-- (produced letter is uppercase) XOR (a Shift key is held).

CAPS_STATE = { on = false }

function capsToggle()
  CAPS_STATE.on = not CAPS_STATE.on
end

function isAlphaChar(t)
  return #t == 1 and t:match("%a") ~= nil
end

function isUpperChar(t)
  return t == string.upper(t) and t ~= string.lower(t)
end

-- Reconcile from one produced letter and the Shift state its
-- caller read when textinput fired. That state is asked of the
-- keyboard, so a Shift released inside the same event batch can
-- read as already up -- accepted, since the next letter fixes
-- the estimate.
function capsReconcile(letter, shift_held)
  local up = isUpperChar(letter)
  CAPS_STATE.on = (up ~= shift_held)
end

-- Physical lock-decal labels mirroring the Compy keyboard;
-- like the keycap labels, they are not localized.
IND_LABELS = { "Num", "Caps", "Scrl" }

function indChipColor(i, caps_on, nudge)
  if i == 2 then
    if nudge then return COL_WARM end
    if caps_on then return COL_IND_ON end
  end
  return COL_DIM
end

function indDrawChip(label, rect, color)
  local font = getFont(FONT_COUNT)
  gfx.setColor(color)
  gfx.rectangle("line", rect.x, rect.y, rect.w, rect.h, 4)
  gfx.setFont(font)
  local ty = rect.y + (rect.h - font:getHeight()) / 2
  gfx.printf(label, rect.x, ty, rect.w, "center")
end

-- Three decals anchored bottom-right of the status band,
-- below the keyboard's right edge, in order Num, Caps, Scroll.
function drawIndicators(caps_on, nudge)
  local cw, ch, gap = 56, 30, 6
  local total = 3 * cw + 2 * gap
  local x0 = (KB.x + KB.w) - total
  local y = STATUS_Y0 + (STATUS_Y1 - STATUS_Y0 - ch) / 2
  for i = 1, 3 do
    local cx = x0 + (i - 1) * (cw + gap)
    local rect = { x = cx, y = y, w = cw, h = ch }
    indDrawChip(IND_LABELS[i], rect,
      indChipColor(i, caps_on, nudge))
  end
end
