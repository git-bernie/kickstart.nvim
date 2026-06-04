-- Thin scrollbar column with diagnostic / git / search marks.
-- https://github.com/petertriho/nvim-scrollbar
-- Bridges to nvim-hlslens so search matches appear as marks in the scrollbar.
return {
  'petertriho/nvim-scrollbar',
  event = { 'BufReadPost', 'BufNewFile' },
  dependencies = {
    'kevinhwang91/nvim-hlslens',
    'lewis6991/gitsigns.nvim',
  },
  config = function()
    require('scrollbar').setup {
      handle = {
        hide_if_all_visible = true, -- no handle when whole buffer fits on screen
        blend = 30, -- transparency: 0 opaque, 100 invisible
      },
      excluded_buftypes = { 'terminal', 'nofile', 'prompt', 'quickfix' },
      excluded_filetypes = {
        'help',
        'dashboard',
        'neo-tree',
        'NvimTree',
        'lazy',
        'mason',
        'TelescopePrompt',
        'snacks_picker_list',
        'aerial',
        'fugitive',
        'qf',
        'noice',
        'minimap',
        'trouble',
      },
      handlers = {
        cursor = false, -- the handle already shows position; second cursor mark is noise
        diagnostic = true,
        gitsigns = true,
        handle = true,
        search = true, -- wired below via scrollbar.handlers.search
      },
      -- Mute Warn/Info/Hint marks — lua_ls floods init.lua with missing-fields
      -- and undefined-field findings. Matches the existing diagnostic philosophy
      -- at init.lua:1214 where underline is also restricted to ERROR severity.
      -- Warnings remain available via vim.diagnostic.open_float() and :Trouble.
      marks = {
        Warn = { text = { '', '' } },
        Info = { text = { '', '' } },
        Hint = { text = { '', '' } },
      },
      show_in_active_only = true, -- hide in inactive splits
      throttle_ms = 100,
    }

    -- Wire hlslens → scrollbar. Re-passes the hlslens options so scrollbar's
    -- internal hlslens.setup() doesn't wipe nearest_only / calm_down.
    require('scrollbar.handlers.search').setup {
      nearest_only = true,
      calm_down = true,
      nearest_float_when = 'never',
    }
  end,
}
