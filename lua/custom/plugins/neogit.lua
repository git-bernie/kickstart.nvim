--[[ 
-- @see https://github.com/NeogitOrg/neogit
:Neogit             " Open the status buffer in a new tab
:Neogit cwd=<cwd>   " Use a different repository path
:Neogit cwd=%:p:h   " Uses the repository of the current file
:Neogit kind=<kind> " Open specified popup directly
:Neogit commit      " Open commit popup

--]]
return {
  'NeogitOrg/neogit',
  lazy = true,
  dependencies = {
    'nvim-lua/plenary.nvim', -- required
    'sindrets/diffview.nvim', -- optional - Diff integration

    -- Only one of these is needed.
    'nvim-telescope/telescope.nvim', -- optional
    'ibhagwan/fzf-lua', -- optional
    'echasnovski/mini.pick', -- optional
    'folke/snacks.nvim', -- optional
  },
  cmd = 'Neogit',
  keys = {
    { '<leader>ng', '<cmd>Neogit<cr>', desc = 'Show [N]eo[g]it UI' },
  },
  config = function()
    require('neogit').setup {
      integrations = {
        diffview = true,
      },
      -- tab (default), replace, split, split_above, split_above_all, split_below,
      -- split_below_all, vsplit, floating, auto (vsplit if window would have 80 cols, otherwise split)
      -- kind = 'split',
      kind = 'tab',
    }
  end,
}
