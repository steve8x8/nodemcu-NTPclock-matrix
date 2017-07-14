local modname = ...
local M = {}
_G[modname] = M

function M.getDomino(digit)
  local domino = {}
  local a = (digit % 2 == 1) and 1 or 0
  local b = (digit >= 2) and 1 or 0
  local c = (digit >= 4) and 1 or 0
  local d = (digit >= 6) and 1 or 0
  local e = (digit >= 8) and 1 or 0
  domino = { {b, d, c}, {e, a, e}, {c, d, b} }
  return domino
end

return M
