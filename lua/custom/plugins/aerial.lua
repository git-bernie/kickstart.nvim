-- Custom action for jump-and-close behavior
local jump_and_close = {
  desc = 'Jump to symbol and close',
  callback = function()
    require('aerial').select()
    require('aerial').close()
  end,
}

-- Toggle between normal and wide aerial window (matches Neo-tree's `e` key)
local toggle_widen = {
  desc = 'Toggle widen aerial window',
  callback = function()
    local winid = vim.api.nvim_get_current_win()
    if vim.w[winid].aerial_widened then
      vim.api.nvim_win_set_width(winid, vim.w[winid].aerial_prev_width)
      vim.w[winid].aerial_widened = false
    else
      vim.w[winid].aerial_prev_width = vim.api.nvim_win_get_width(winid)
      local wide = math.min(80, math.floor(vim.o.columns * 0.5))
      vim.api.nvim_win_set_width(winid, wide)
      vim.w[winid].aerial_widened = true
    end
  end,
}

return {
  'stevearc/aerial.nvim',
  enabled = true,

  opts = {
    backends = { 'treesitter', 'lsp', 'markdown', 'asciidoc', 'man', 'php', 'vue' },
    filter_kind = false,
    -- filter_kind = {
    --   'Class',
    --   'Constructor',
    --   'Enum',
    --   'Function',
    --   'Interface',
    --   'Module',
    --   'Method',
    --   'Struct',
    -- },
    -- default_direction = 'prefer_left',
    default_direction = 'float',
    -- NB: not sure difference btw edge and window
    -- placement = 'window', -- edge, window
    placement = 'edge', -- edge, window
    close_on_select = false, -- <CR> keeps window open, <C-CR> or o closes
    --   window - aerial window will display symbols for the buffer in the window from which it was opened
    attach_mode = 'window',
    --   global - aerial window will display symbols for the current window
    -- attach_mode = 'global',
    close_automatic_events = {},
    keymaps = {
      -- <CR> = jump and stay (default behavior with close_on_select = false)
      -- <C-CR> / o = jump and close (ignores close_on_select setting)
      ['<C-CR>'] = jump_and_close,
      ['o'] = jump_and_close,
      ['e'] = toggle_widen,
    },
  },
  -- Optional dependencies
  dependencies = {
    'nvim-treesitter/nvim-treesitter',
    'nvim-tree/nvim-web-devicons',
  },
  keys = {
    { '<leader>ta', '<cmd>AerialToggle left<CR>', desc = '[T]oggle [A]erial' },
  },
}
