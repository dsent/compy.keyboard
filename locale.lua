-- All localizable, user-facing text lives here. Gameplay
-- teaches Latin typing, but every message a child or teacher
-- reads is drawn from a per-locale string table. The COMPY
-- heading and the physical keycap labels are NOT here: the
-- heading is a fixed Latin wordmark and the keycaps mirror the
-- physical Compy keyboard.
--
-- STR points at the active locale. Locale detection can later
-- choose a different LOCALE entry; for now it is English.

LOCALE = { }

LOCALE.en = {
  welcome = "Welcome! Watch the keyboard type.",
  prompt = "Press Enter",
  menu_title = "Choose a game",
  good_job = "Good job!",
  tab_level = "→ next level",
  replay = "→ play again",
  to_menu = "→ back to the menu",
  help_hint = "Hold Alt+H for help",
  back_hint = "Shift+Esc → menu",
  paused = "Paused",
  games = {
    press = "Press the key",
    find = "Find the key",
    astro = "Asteroids",
    alt = "Alt characters",
    words = "Words & phrases",
    bubble = "Blow the bubble",
    hide = "Hide and seek",
    train = "Load the train"
  },
  help = {
    press = "Press the key that glows.\n\n"
      .. "Shift+Esc  back to the menu\n"
      .. "Ctrl+Alt+↑/↓  change difficulty",
    find = "Find the key shown above, then press it.\n\n"
      .. "Shift+Esc  back to the menu\n"
      .. "Ctrl+Alt+↑/↓  change difficulty",
    alt = "Make the letter or symbol shown above.\n\n"
      .. "Hold Shift for capitals and symbols.\n"
      .. "Shift+Esc  back to the menu\n"
      .. "Ctrl+Alt+↑/↓  change difficulty",
    words = "Type the word or phrase shown above.\n\n"
      .. "Hold Shift for a capital.\n"
      .. "Shift+Esc  back to the menu\n"
      .. "Ctrl+Alt+↑/↓  change difficulty",
    bubble = "Hold the key that glows to blow up the "
      .. "bubble.\nLet go while the bubble fits the ring.\n\n"
      .. "Shift+Esc  back to the menu\n"
      .. "Ctrl+Alt+↑/↓  change difficulty",
    hide = "Keys hide behind the crates. One peeks out\n"
      .. "at a time, and you may press any of them,\n"
      .. "shown or hidden. Take as long as you like.\n\n"
      .. "Shift+Esc  back to the menu\n"
      .. "Ctrl+Alt+↑/↓  change difficulty",
    train = "Press the key floating over the platform.\n"
      .. "It rides down as cargo, and a full train\n"
      .. "leaves. Take as long as you like.\n\n"
      .. "Shift+Esc  back to the menu\n"
      .. "Ctrl+Alt+↑/↓  change difficulty",
    astro = "Shoot the falling rocks by typing their\n"
      .. "keys, in any order, before they reach the\n"
      .. "shield. The gun reloads after every shot,\n"
      .. "and a miss reloads slower.\n"
      .. "Burning rocks fly PAST the shield --\n"
      .. "let them go; shooting one costs you.\n\n"
      .. "Alt+P  pause\n"
      .. "Shift+Esc  back to the menu\n"
      .. "Ctrl+Alt+↑ faster   Ctrl+Alt+↓ slower"
  }
}

STR = LOCALE.en
