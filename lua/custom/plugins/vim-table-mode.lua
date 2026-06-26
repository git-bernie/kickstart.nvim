return {
  'dhruvasagar/vim-table-mode',
  init = function()
    -- Free <leader>tt for markdown-table-wrap's toggle. vim-table-mode's
    -- "tableize" command (unused) defaults to <leader>tt; park it on <leader>tT
    -- rather than '' (an empty value produces a broken xnoremap at load).
    vim.g.table_mode_tableize_map = '<Leader>tT'
  end,
}
