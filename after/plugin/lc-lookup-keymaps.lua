-- LoanConnect lookup-table picker keymaps and commands.
-- Backend: lua/lc-lookup.lua → bin/lc-lookup.php (vendored, PDO, no Laravel).
-- See docs/lc-lookup.md for setup (manifest + connection).

local lc = require 'lc-lookup'

-- Picker entry-points
vim.keymap.set('n', '<leader>xL', lc.pick_any, { desc = 'LC [L]ookup picker (pick table, then row)' })
vim.keymap.set('n', '<leader>xll', function()
  lc.pick 'lenders'
end, { desc = 'LC lookup: [l]enders' })
vim.keymap.set('n', '<leader>xlp', function()
  lc.pick 'partners'
end, { desc = 'LC lookup: [p]artners' })
vim.keymap.set('n', '<leader>xlr', function()
  lc.pick 'products'
end, { desc = 'LC lookup: p[r]oducts' })

-- Refresh + connection check
vim.keymap.set('n', '<leader>xlR', function()
  lc.refresh()
end, { desc = 'LC lookup: [R]efresh all caches' })

-- Generic user commands. Tab-complete from cached tables (or manifest names if cache is empty).
local function complete_tables()
  local cache = (vim.env.LC_LOOKUP_CACHE ~= '' and vim.env.LC_LOOKUP_CACHE)
    or (vim.env.XDG_CACHE_HOME ~= '' and (vim.env.XDG_CACHE_HOME .. '/lc-lookup'))
    or vim.fn.expand '~/.cache/lc-lookup'
  local out = {}
  for name, _ in vim.fs.dir(cache) do
    local stem = name:match '^(.+)%.json$'
    if stem then
      table.insert(out, stem)
    end
  end
  return out
end

vim.api.nvim_create_user_command('LcLookup', function(args)
  if args.args == '' then
    lc.pick_any()
  else
    lc.pick(args.args)
  end
end, {
  nargs = '?',
  complete = complete_tables,
  desc = 'LoanConnect lookup picker',
})

vim.api.nvim_create_user_command('LcLookupRefresh', function(args)
  lc.refresh(args.args ~= '' and args.args or nil)
end, {
  nargs = '?',
  complete = complete_tables,
  desc = 'Refresh LoanConnect lookup cache (one table or all)',
})

vim.api.nvim_create_user_command('LcLookupCheck', function()
  lc.check()
end, { desc = 'Check LoanConnect DB connection' })
