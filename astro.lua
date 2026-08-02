-- astro.lua

-- Asteroids. Caps ride rocks down from the top edge and the
-- saucer below shoots the one whose key is pressed, in any
-- order. On the upper notches a burning rock sometimes crosses
-- the sky on a line that misses the shield: that one is left
-- alone, and shooting it is the mistake -- the notch table's
-- `danger` schedule says how often (config.lua).
--
-- This file only names the game, declares its notch bounds and
-- its sky, and registers the scene; the behaviour is all
-- astrocore.lua's and stream.lua's.

ensureFile("astrocore.lua")

ASTRO_SCENE = { id = "astro", lo = -2, hi = 2,
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
  noHint = astroIdle,
  timed = true
})
