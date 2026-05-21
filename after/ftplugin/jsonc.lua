-- treesitter-based folding (was BufEnter autocmd in init.lua, pattern *.jsonc)
vim.opt_local.foldmethod = 'expr'
vim.opt_local.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
vim.opt_local.foldlevelstart = 99
