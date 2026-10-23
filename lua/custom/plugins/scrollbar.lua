-- Thin scrollbar column with diagnostic / git / search marks.
-- https://github.com/petertriho/nvim-scrollbar
-- v2 config. Search marks come from the native `/` `?` search, so the v1
-- nvim-hlslens bridge is gone (hlslens.lua still owns the inline lens).
return {
  'petertriho/nvim-scrollbar',
  -- v2 lands on main 2026-11-16; drop this line after the cutover.
  branch = 'refactor/v2',
  event = { 'BufReadPost', 'BufNewFile' },
  dependencies = {
    'lewis6991/gitsigns.nvim',
  },
  config = function()
    require('scrollbar').setup {
      -- Keyed tables add to v2's defaults (a list would replace them).
      exclude = {
        buftypes = { terminal = true, nofile = true, prompt = true, quickfix = true },
        filetypes = {
          help = true,
          dashboard = true,
          ['neo-tree'] = true,
          NvimTree = true,
          lazy = true,
          mason = true,
          TelescopePrompt = true,
          snacks_picker_list = true,
          aerial = true,
          fugitive = true,
          qf = true,
          noice = true,
          minimap = true,
          trouble = true,
        },
      },
      providers = {
        cursor = false, -- the thumb already shows position; second cursor mark is noise
        diagnostic = true,
        gitsigns = true,
        search = true,
      },
      -- Hide Warn/Info/Hint marks — lua_ls floods init.lua with missing-fields
      -- and undefined-field findings. Matches the existing diagnostic philosophy
      -- at init.lua:1214 where underline is also restricted to ERROR severity.
      -- Warnings remain available via vim.diagnostic.open_float() and :Trouble.
      marks = {
        Warn = false,
        Info = false,
        Hint = false,
      },
      scrollbar = {
        visibility = 'active', -- hide in inactive splits
        thumb = {
          hide_if_all_visible = true, -- no thumb when whole buffer fits on screen
          blend = 30, -- transparency: 0 opaque, 100 invisible
        },
      },
    }
  end,
}
