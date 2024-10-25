return {

  'kristijanhusak/vim-dadbod-ui',
  enabled = false,
  dependencies = {
    { 'tpope/vim-dadbod', lazy = true },
    { 'kristijanhusak/vim-dadbod-completion', ft = { 'sql', 'mysql', 'plsql', 'mysql' }, lazy = true }, -- Optional
  },
  cmd = {
    'DBUI',
    'DBUIToggle',
    'DBUIAddConnection',
    'DBUIFindBuffer',
  },
  init = function()
    -- Your DBUI configuration
    vim.g.db_ui_use_nerd_fonts = 1
    vim.g.db_ui_save_location = os.getenv 'HOME' .. '/.config/nvim/db_ui_queries'

    -- NOTE: temporarily remarking to see if is causing cmp weirdness
    --[[ require('cmp').setup {
      sources = {
        { name = 'buffer' }, -- Added plugin cmp-buffer
        { name = 'vim-dadbod-completion', priority = 700 },
      },
    } ]]
  end,
}
