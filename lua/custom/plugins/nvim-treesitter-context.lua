--[[
    https://github.com/nvim-treesitter/nvim-treesitter-context
   [A plugin that shows the semantic context of the currently visible buffer
   [region. Typically this context will be: the current function, if statement
   [blocks, loops, etc.
   ]]

return {
  'nvim-treesitter/nvim-treesitter-context',
  enabled = true,
  -- NOTE: It seems no longer to be enabled automatically?
  opts = {
    enable = true,
  },
  config = function()
    vim.keymap.set('n', '[x', function()
      require('treesitter-context').go_to_context(vim.v.count1)
    end, { silent = true })
  end,
}
