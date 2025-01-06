--[[ Highly experimental plugin that completely replaces the UI for messages, 
cmdline and the popupmenu. 

For config help, see: https://github.com/folke/noice.nvim/wiki/Configuration-Recipes
]]
return {
  'folke/noice.nvim',
  enabled = true,
  event = 'VeryLazy',
  -- add any options here
  --[[ lsp = {
    -- override markdown rendering so that **cmp** and other plugins use **Treesitter**
    override = {
      ['vim.lsp.util.convert_input_to_markdown_lines'] = true,
      ['vim.lsp.util.stylize_markdown'] = true,
      ['cmp.entry.get_documentation'] = true, -- requires hrsh7th/nvim-cmp
    },
  },
  -- you can enable a preset for easier configration
  presets = {
    bottom_search = true, -- use a classic bottom cmdline for search
    command_palette = true, -- position the cmdline and popupmenu together
    long_message_to_split = true, -- long messages will be sent to a split
    inc_rename = false, -- enables an input dialog for inc-rename.nvim
    lsp_doc_border = true, -- add a border to hover docs and signature help
  }, ]]
  opts = {
    -- add any options here
    lsp = {
      -- override markdown rendering so that **cmp** and other plugins use **Treesitter*falsfalsfalsfalseeee*
      override = {
        ['vim.lsp.util.convert_input_to_markdown_lines'] = true,
        ['vim.lsp.util.stylize_markdown'] = true,
        ['cmp.entry.get_documentation'] = true, -- requires hrsh7th/nvim-cmp
      },
    },
    -- you can enable a preset for easier configration
    presets = {
      bottom_search = false, -- use a classic bottom cmdline for search
      -- command_palette = true, -- position the cmdline and popupmenu together
      command_palette = true, -- position the cmdline and popupmenu together
      long_message_to_split = true, -- long messages will be sent to a split
      inc_rename = false, -- enables an input dialog for inc-rename.nvim
      lsp_doc_border = false, -- add a border to hover docs and signature help
    },

    -- https://github.com/folke/noice.nvim/wiki/Configuration-Recipes#show-recording-messages
    routes = {
      {
        view = 'notify',
        filter = { event = 'msg_showmode' },
      },
    },
  },
  dependencies = {
    -- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
    'MunifTanjim/nui.nvim',
    -- OPTIONAL:
    --   `nvim-notify` is only needed, if you want to use the notification view.
    --   If not available, we use `mini` as the fallback
    'rcarriga/nvim-notify',
  },
  keys = {
    { '<Leader>sl', '<cmd>NoiceLast<CR>', desc = '[S]elect Noice [L]ast', mode = 'n', silent = true, noremap = true },
    { '<Leader>sll', '<cmd>NoiceHistory<CR>', desc = '[S]elect [L]ike [L]ast NoiceHistory', mode = 'n', silent = true, noremap = true },
    -- { '<Leader>LL', '<cmd>Noice dismiss<CR>', desc = 'Dismiss notification', mode = 'n', silent = true, noremap = true },
    { '<Leader>LL', "<cmd>lua require('notify').dismiss()<CR>", desc = 'Dismiss notification', mode = 'n', silent = true, noremap = true },
  },
}
