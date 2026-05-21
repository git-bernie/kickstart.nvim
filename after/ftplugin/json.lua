-- in after/ftplugin/json.lua

-- show json path in the winbar
if vim.fn.exists '+winbar' == 1 then
  vim.opt_local.winbar = "%{%v:lua.require'jsonpath'.get()%}"
end

-- send json path to clipboard
vim.keymap.set('n', 'y<C-p>', function()
  vim.fn.setreg('+', require('jsonpath').get())
end, { desc = 'copy json path', buffer = true })

-- treesitter-based folding (was BufEnter autocmd in init.lua)
vim.opt_local.foldmethod = 'expr'
vim.opt_local.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
vim.opt_local.foldlevelstart = 99
