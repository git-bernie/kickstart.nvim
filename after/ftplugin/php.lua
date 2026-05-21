vim.opt_local.makeprg = 'php -l %'
vim.g.lazyvim_php_lsp = 'intelephense'

-- Was BufEnter autocmd in init.lua (pattern *.php, *.ctp)
vim.opt_local.foldmethod = 'expr'
vim.opt_local.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
vim.opt_local.foldlevelstart = 99
vim.opt_local.shiftwidth = 4
vim.opt_local.foldlevel = 5
vim.opt_local.expandtab = true
vim.opt_local.tabstop = 4
vim.opt_local.iskeyword:append '-' -- lua vim.opt_local.iskeyword:remove '-'
vim.opt_local.textwidth = 110 -- NB: 110 works better than 120 on my split screen
vim.opt_local.colorcolumn = { 80, 110 } -- Readability first; ideally 80; soft limit 110
vim.opt_local.commentstring = '// %s' -- nvim runtime switched to /* %s */ in 2024; restore preferred style
vim.api.nvim_set_hl(0, 'Comment', { fg = '#5F8AA8' }) -- Steel blue
