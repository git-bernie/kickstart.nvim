-- treesitter-based folding + 2-space indent (was BufEnter autocmd in init.lua)
vim.opt_local.foldmethod = 'expr'
vim.opt_local.foldlevelstart = 99
vim.opt_local.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
vim.opt_local.shiftwidth = 2
