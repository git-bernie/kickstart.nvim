--[[ return {
  {
    'CopilotC-Nvim/CopilotChat.nvim',
    enabled = true,
    dependencies = {
      -- Use only one Copilot provider. Uncomment the one you use:
      { 'zbirenbaum/copilot.lua' },
      -- { 'github/copilot.vim' },
      { 'nvim-lua/plenary.nvim', branch = 'master' }, -- Required for curl, log, and async functions
    },
    build = (vim.fn.has 'macunix' == 1 or vim.fn.has 'unix' == 1) and 'make tiktoken' or nil,
    keys = {
      { '<leader>co', '<cmd>CopilotChat<cr>', desc = '[C]opilot ChatGPT [O]pen' },
    },
    opts = function(_, opts)
      local file_glob_function = require 'custom.copilotchat_file_glob'
      opts.functions = vim.tbl_deep_extend('force', require 'CopilotChat.config.functions', file_glob_function)
      opts.auto_insert_mode = true
      return opts
    end,
    -- To lazy load, see :h CopilotChat for available commands
  },
}
]]

return {
  {
    'CopilotC-Nvim/CopilotChat.nvim',
    enabled = true,
    dependencies = {
      { 'nvim-lua/plenary.nvim', branch = 'master' },
    },
    build = 'make tiktoken',
    opts = {
      -- See Configuration section for options
    },
    keys = {
      { '<leader>co', '<cmd>CopilotChat<cr>', desc = '[C]opilotChat [O]pen' },
      { '<leader>ct', '<cmd>CopilotChatToggle<cr>', desc = '[C]opilotChat [T]oggle' },
    },
  },
}
