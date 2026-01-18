return {
  'greggh/claude-code.nvim',
  dependencies = { 'nvim-lua/plenary.nvim' },
  keys = {
    { '<leader>ac', [[<cmd>ClaudeCode<cr>]], desc = 'Claude Code' },
    { '<leader>cC', [[<cmd>ClaudeCodeContinue<cr>]], desc = 'Claude Code (continue)' },
    { '<leader>cV', [[<cmd>ClaudeCodeVerbose<cr>]], desc = 'Claude Code (verbose)' },
    { '<C-.>', [[<cmd>ClaudeCode<cr>]], desc = 'Claude Code Toggle', mode = { 'n', 't' } },
  },
  opts = {
    window = {
      position = 'vsplit', -- botright, topleft, vertical/vsplit
      split_ratio = 0.5,
    },
    git = {
      use_git_root = true,
    },
    command_variants = {
      continue = '--continue',
      resume = '--resume',
      verbose = '--verbose',
    },
    keymaps = {
      toggle = {
        normal = '<leader>cc',
        -- terminal = '<C-o>',
        terminal = '<C-\\>',
        variants = {
          continue = '<leader>cC',
          verbose = '<leader>cV',
        },
      },
    },
  },
}
