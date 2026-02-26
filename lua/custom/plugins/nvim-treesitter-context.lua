--[[
    https://github.com/nvim-treesitter/nvim-treesitter-context
   [A plugin that shows the semantic context of the currently visible buffer
   [region. Typically this context will be: the current function, if statement
   [blocks, loops, etc.
   ]]

return {
  'nvim-treesitter/nvim-treesitter-context',
  dependencies = { 'nvim-treesitter/nvim-treesitter' }, -- installed in init.lua
  event = 'BufReadPost',
  opts = {
    enable = true,
    max_lines = 0, -- no limit
    multiline_threshold = 20,
    multiwindow = true,
    trim_scope = 'outer', -- inner, outer
  },
  keys = {
    {
      '[x',
      function()
        require('treesitter-context').go_to_context(vim.v.count1)
      end,
      desc = 'To [C]ontext (count1) TreesitterContext',
    },
    {
      '<leader>tx',
      function()
        require('treesitter-context').toggle()
      end,
      desc = '[T]oggle TSConte[x]t',
    },
  },
}
