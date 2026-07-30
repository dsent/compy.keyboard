-- Shared sound palette. Maps gentle game EVENTS to compy.audio
-- samples by meaning, so callers say what happened rather than
-- which sample plays (and the mapping can change in one place).
-- The one "input not accepted" cue is a soft neutral knock --
-- informative, never a scold (see SOUND.reject).

sfx = compy.audio

SOUND = { }

-- Typewriter key tick: the intro's simulated Caps Lock press
-- and each letter of the heading.
function SOUND.typeTick()
  sfx.knock()
end

-- A correct match in the find-key games: a soft toggle blip
-- (correct.ogg grated on repeat; toggle was chosen on device).
function SOUND.match()
  sfx.toggle()
end

-- A round win in the gauge games: win.ogg.
function SOUND.win()
  sfx.win()
end

-- The biggest win, at the top notch: wow.ogg.
function SOUND.wow()
  sfx.wow()
end

-- Input not accepted (a wrong key, or an unmapped menu key): a
-- soft neutral knock -- the same dull "bump" as the typewriter
-- tick, carrying no negative valence. Informative, not a scold;
-- never a buzzer, never a tally.
function SOUND.reject()
  sfx.knock()
end

-- The gun going off in the falling-caps games. It plays on the
-- shot itself, so it is heard whether or not the rock was one
-- worth hitting.
function SOUND.laser()
  sfx.pew()
end

-- Anything reaching the force field: a cap nobody answered, or
-- a burning rock shot down onto it. One event, one sound. It
-- wants the shield resonating under a strike -- a low swell
-- rather than a blow landing on something solid.
function SOUND.impact()
  sfx.blast()
end

-- Entering or leaving the modal pause: a soft toggle blip.
function SOUND.pause()
  sfx.toggle()
end


-- Re-arming the inline Shift hint (Ctrl+Alt+H): a soft toggle
-- blip confirming the teacher chord landed.
function SOUND.hint()
  sfx.toggle()
end
