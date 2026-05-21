local ls = require 'luasnip'
local s = ls.snippet
local f = ls.function_node

local function date(fmt)
  return f(function()
    return os.date(fmt)
  end)
end

return {
  s('date', date '%Y-%m-%d'),
  s('time', date '%H:%M:%S'),
  s('now', date '%Y-%m-%d %H:%M:%S'),
  s('ddate', date '%A, %B %-d %Y'),

  s(
    'uuid',
    f(function()
      return vim.trim(vim.fn.system 'uuidgen')
    end)
  ),

  s(
    'fname',
    f(function()
      return vim.fn.expand '%:t'
    end)
  ),

  s(
    'fpath',
    f(function()
      return vim.fn.expand '%:p'
    end)
  ),
}
