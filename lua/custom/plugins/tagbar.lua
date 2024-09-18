return {
  'preservim/tagbar',
  config = function()
    vim.keymap.set('n', '<leader>tt', '<cmd>TagbarToggle<CR>', { desc = '[T]agbar[[T]oggle', silent = true, noremap = true })
    -- vim.g.tagbar_left = true
    -- vim.g.tagbar_right = true
    vim.g.tagbar_position = 'leftabove vertical' -- default is botright vertical
    vim.g.tagbar_expand = true
    vim.g.tagbar_type_php = {
      kinds = {
        'n:namespaces',
        'p:properties',
        'd:constants',
        'c:classes',
        't:traits',
        'f:functions',
        'm:methods',
      },
    }
  end,
}
