-- astro.lua

-- Asteroids. Caps ride rocks down from the top edge in a steady
-- stream and the saucer below shoots the one whose key is
-- pressed, in any order. Every rock in the sky is there to be
-- shot -- no burning ones cross it -- which makes this the
-- plain form of the falling-caps stream.
--
-- This file only names the game, declares its notch bounds and
-- its sky, and registers the scene; the behaviour is all
-- astrocore.lua's and stream.lua's.

ensureFile("astrocore.lua")

ASTRO_SCENE = { id = "astro", lo = -2, hi = 2, danger = false,
  ramp = SPACE_RAMP }

function astroSceneEnter()
  astroEnter(ASTRO_SCENE)
end

registerScene("astro", {
  enter = astroSceneEnter,
  update = astroUpdate,
  draw = astroDraw,
  keypressed = astroKeypressed,
  onNotch = astroOnNotch,
  noHint = astroDone,
  timed = true
})
