-- danger.lua

-- Dangerous Asteroids. The same stream, with burning rocks
-- crossing it: a charred spiked body dragging a flame trail,
-- travelling a straight diagonal to a point low on the far side
-- that passes OUTSIDE the force field. They were never aimed at
-- us, they visibly miss, and shooting one only wastes the shot,
-- so leaving them alone follows from what the child sees rather
-- than from a colour rule someone has to teach.
--
-- The stream, the gauge, the review, the notch and the scene
-- are shared; this file names the game, declares its own notch
-- id so progress in the two variants is kept apart, and turns
-- the burning rocks on.

ensureFile("astrocore.lua")

DANGER_SCENE = { id = "danger", lo = -2, hi = 2, danger = true,
  ramp = SPACE_RAMP }

function dangerEnter()
  astroEnter(DANGER_SCENE)
end

registerScene("danger", {
  enter = dangerEnter,
  update = astroUpdate,
  draw = astroDraw,
  keypressed = astroKeypressed,
  onNotch = astroOnNotch,
  noHint = astroIdle,
  timed = true
})
