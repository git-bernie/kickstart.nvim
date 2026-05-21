-- vim-dadbod-ui: SQL scratchpad + drawer. Connections are NOT defined here —
-- declare them per-project in `.nvim.lua` (auto-sourced; see docs/lc-lookup.md).
-- Saved queries live under stdpath('state') so they're per-machine, not in dotfiles.
return {
  'kristijanhusak/vim-dadbod-ui',
  dependencies = {
    { 'tpope/vim-dadbod', lazy = true },
    { 'kristijanhusak/vim-dadbod-completion', ft = { 'sql', 'mysql', 'plsql' }, lazy = true },
  },
  -- Eager-load after UI is ready (~5ms): `:help dadbod` and `:help vim-dadbod-ui`
  -- work without first invoking a command. cmd-based lazy-loading buys nothing
  -- here — dadbod is single-digit ms to source.
  event = 'VeryLazy',
  keys = {
    { '<leader>td', '<cmd>DBUIToggle<cr>', desc = '[t]oggle [d]B UI' },
  },
  init = function()
    vim.g.db_ui_use_nerd_fonts = 1
    vim.g.db_ui_save_location = vim.fn.stdpath 'state' .. '/db_ui_queries'
    vim.g.db_ui_show_database_icon = 1
    vim.g.db_ui_force_echo_notifications = 0
    vim.g.db_ui_win_position = 'left'
    vim.g.db_ui_winwidth = 40
  end,
}
