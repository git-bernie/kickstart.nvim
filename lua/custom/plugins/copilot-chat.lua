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
      -- { 'zbirenbaum/copilot.lua' },
    },
    -- build = 'make tiktoken',
    build = vim.fn.executable 'make' == 1 and 'make tiktoken' or nil,
    opts = {
      -- See Configuration section for options
      -- model = 'claude-sonnet-4.6', -- retired from Copilot by 2026-10
      model = 'claude-sonnet-5.5',
      -- model = 'gpt-4o',
      auto_insert_mode = true,
    },
    keys = {
      { '<leader>co', '<cmd>CopilotChat<cr>', mode = 'n', desc = '[C]opilotChat [O]pen' },
      { '<leader>co', ':CopilotChat<cr>', mode = 'v', desc = '[C]opilotChat [O]pen (selection)' },
      { '<leader>ct', '<cmd>CopilotChatToggle<cr>', mode = 'n', desc = '[C]opilotChat [T]oggle' },
      { '<leader>ct', ':CopilotChatToggle<cr>', mode = 'v', desc = '[C]opilotChat [T]oggle (selection)' },
      { '<leader>ce', '<cmd>CopilotChatExplain<cr>', mode = 'n', desc = '[C]opilotChat [E]xplain' },
      { '<leader>ce', ':CopilotChatExplain<cr>', mode = 'v', desc = '[C]opilotChat [E]xplain (selection)' },
      { '<leader>cf', '<cmd>CopilotChatFix<cr>', mode = 'n', desc = '[C]opilotChat [F]ix' },
      { '<leader>cf', ':CopilotChatFix<cr>', mode = 'v', desc = '[C]opilotChat [F]ix (selection)' },
      { '<leader>cr', '<cmd>CopilotChatReview<cr>', mode = 'n', desc = '[C]opilotChat [R]eview' },
      { '<leader>cr', ':CopilotChatReview<cr>', mode = 'v', desc = '[C]opilotChat [R]eview (selection)' },
    },
  },
}
