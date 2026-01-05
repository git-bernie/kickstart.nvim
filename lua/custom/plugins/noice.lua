--[[ Highly experimental plugin that completely replaces the UI for messages, 
cmdline and the popupmenu. 

For config help, see: https://github.com/folke/noice.nvim/wiki/Configuration-Recipes

Noice can be super annoying particularly because I have not figured out 
how to consistently see the result of :! /bin/bash etc. type comands.

`NOTE: g<` is super useful. Also <leader>ty disables Noice.

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
    cmdline = {
      --[[
      --
  --------------------------------------------------------------------------------
  View             Backend    Description
  ---------------- ---------- ----------------------------------------------------
  notify           notify     nvim-notify with level=nil, replace=false,
                              merge=false

  split            split      horizontal split

  vsplit           split      vertical split

  popup            popup      simple popup

  mini             mini       minimal view, by default bottom right, right-aligned

  cmdline          popup      bottom line, similar to the classic cmdline

  cmdline_popup    popup      fancy cmdline popup, with different styles according
                              to the cmdline mode

  cmdline_output   split      split used by config.presets.cmdline_output_to_split

  messages         split      split used for :messages

  confirm          popup      popup used for confirm events

  hover            popup      popup used for lsp signature help and hover

  popupmenu        nui.menu   special view with the options used to render the
                              popupmenu when backend is nui
      --]]
      view = 'cmdline_popup', -- change to `cmdline` to get classic cmd line
      -- view = 'cmdline', -- change to `cmdline` to get classic cmd line
      -- view = 'cmdline_output',
      -- view = 'popupmenu',
      opts = {
        position = {
          row = '50%',
          col = '50%',
        },
        size = {
          -- width = 60,
          width = 70,
          height = 'auto',
        },
        border = {
          style = 'rounded',
          padding = { 0, 1 },
        },
        win_options = {
          winhighlight = 'Normal:Normal,FloatBorder:FloatBorder,CursorLine:Visual,Search:None',
        },
      },
    },
    views = { -- The "notify" view handles general notifications
      notify = {
        position = {
          -- row = 0, -- Position from the top (0 is the top edge)
          row = '50%', -- Position from the top (0 is the top edge)
          col = '50%', -- Position from the left (100% is the right edge)
        },
        size = {
          width = 'auto',
          height = 'auto',
          max_width = 80, -- Optional: set a maximum width for readability
        },
        -- Optional: ensure messages stack downwards (top_down = true) or upwards (top_down = false)
        -- If you want the latest message at the absolute top, set top_down = false
        top_down = false,
      },
      -- You can also configure other views like cmdline_popup, etc.
      cmdline_popup = {
        position = {
          row = '50%',
          col = '50%',
        },
      },
      popmenu = {
        relative = 'editor',
        position = {
          row = '50%',
          col = '50%',
        },
      },
      popup = {
        relative = 'editor',
        position = {
          row = '50%',
          col = '50%',
        },
        win_options = {
          winhighlight = {
            Normal = 'NormalFloat',
            FloatBorder = 'FloatBorder',
          },
        },
      },
    },
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
        filter = { event = 'msg_showmode', kind = '', find = 'written' },
        opts = { skip = true },
        win_options = {
          winhighlight = 'Normal:Normal,FloatBorder:FloatBorder,CursorLine:Visual,Search:None',
        },
      },
      -- Route shell command output (identified by `msg_show` and a minimum height) to a split view.
      { -- Alternately, :Noice disable
        view = 'split',
        filter = {
          event = 'msg_show',
          -- min_height = 1, -- Adjust this value as needed
          min_height = 5, -- Adjust this value as needed
          -- min_height = 1, -- 1 means always make a split.
          -- min_height = 5, -- 5 means if >= 5 lines then make a split. Remember to use `g<`
        },
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
    -- { '<Leader>sl', '<cmd>NoiceLast<CR>', desc = '[S]elect Noice [L]ast', mode = 'n', silent = true, noremap = true },
    -- { '<Leader>sll', '<cmd>NoiceHistory<CR>', desc = '[S]elect [L]ike [L]ast NoiceHistory', mode = 'n', silent = true, noremap = true },
    -- { '<Leader>LL', '<cmd>Noice dismiss<CR>', desc = 'Dismiss notification', mode = 'n', silent = true, noremap = true },
    -- { '<Leader>ty', '<cmd>Noice disable<CR>', desc = '[T]oggle (?) AnNo[y]ance Disable', mode = 'n', silent = false, noremap = true },
    -- { '<Leader>tyy', '<cmd>Noice enable<CR>', desc = '[T]oggle (?) AnNo[y]ance Enable', mode = 'n', silent = false, noremap = true },
    -- { '<Leader>n', '<cmd>Noice dismiss<CR>', desc = '[N]oice dismiss', mode = 'n', silent = false, noremap = true },
    -- { '<Leader>nd', '<cmd>Noice dismiss<CR>', desc = '[N]oice [D]ismiss', mode = 'n', silent = false, noremap = true },
    -- { '<Leader>ne', '<cmd>Noice enable<CR>', desc = '[N]oice enable', mode = 'n', silent = false, noremap = true },
    -- { '<Leader>nx', '<cmd>Noice disable<CR>', desc = '[N]oice [X]Disable', mode = 'n', silent = false, noremap = true },
    { '<esc>', '<cmd>Noice dismiss<CR>', desc = 'Noic[ESC] dismiss!!!', mode = 'n', silent = false, noremap = true },
    { '<Leader>LL', "<cmd>lua require('notify').dismiss()<CR>", desc = 'Dismiss notification', mode = 'n', silent = false, noremap = true },
    { '<Leader>nh', '<cmd>Noice history<CR>', desc = '[N]oice [H]istory', mode = 'n', silent = true, noremap = true },
    { '<Leader>nl', '<cmd>NoiceLast<CR>', desc = '[N]oice [L]ast', mode = 'n', silent = true, noremap = true },
  },
}
