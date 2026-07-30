-- Mini-game menu. A calm numbered list in the fixed spec order,
-- derived structurally from the scenes registered in this
-- build: an id is listed iff its scene is registered, so
-- omit-not-disable is guaranteed by construction. The digit is
-- the id's fixed position in MENU_ORDER. Shift+Esc is ignored
-- here (the menu is the program's top level).

-- The digit that opens an entry. Ten games exhaust the row, so
-- the tenth answers to 0, as numbered lists have always done.

function menuDigit(n)
  if n == 10 then return "0" end
  return "" .. n
end

function menuLabel(it)
  return menuDigit(it.n) .. ". " .. STR.games[it.id]
end

function menuItems()
  local items = { }
  for i, id in ipairs(MENU_ORDER) do
    if sceneAvailable(id) then
      items[#items + 1] = { n = i, id = id }
    end
  end
  return items
end

-- Where entry i sits: down the first column, then the second.
-- The block is centred in the keyboard band, so a shorter list
-- does not leave the lower half of the canvas empty.

function menuColumnW()
  return REF_W / MENU_COLS
end

function menuTop(rows)
  local band = KBAND_Y1 - KBAND_Y0
  return KBAND_Y0 + (band - rows * MENU_STEP) / 2
end

function menuSlot(i, rows)
  local col = math.floor((i - 1) / rows)
  local row = (i - 1) % rows
  return col * menuColumnW(), menuTop(rows) + row * MENU_STEP
end

-- Entries are printed from a common left edge rather than
-- centred one by one, so the digits form a column a child can
-- scan. The edge comes from the widest label, which leaves the
-- block itself centred in its column.

function menuIndent(items)
  local font = getFont(FONT_MENU_ITEM)
  local w = 0
  for _, it in ipairs(items) do
    local lw = font:getWidth(menuLabel(it))
    if w < lw then w = lw end
  end
  return (menuColumnW() - w) / 2
end

function menuDrawList()
  gfx.setFont(getFont(FONT_MENU_ITEM))
  local items = menuItems()
  local rows = math.ceil(#items / MENU_COLS)
  local indent = menuIndent(items)
  for i, it in ipairs(items) do
    local x, y = menuSlot(i, rows)
    gfx.setColor(COL_TEXT)
    gfx.print(menuLabel(it), x + indent, y)
  end
end

function menuDraw()
  drawBandText(STR.menu_title, HEADER_BAND,
    getFont(FONT_MENU), COL_DIM)
  menuDrawList()
end

function menuKeypressed(k)
  local n = tonumber(k)
  if not n then return end
  if n == 0 then n = 10 end
  local id = MENU_ORDER[n]
  if id and sceneAvailable(id) then
    gotoScene(id)
  end
end

registerScene("menu", {
  draw = menuDraw,
  keypressed = menuKeypressed
})
