return {
  'greggh/claude-code.nvim',
  dependencies = { 'nvim-lua/plenary.nvim' },
  keys = {
    { '<leader>cc', desc = 'Claude Code' },
    { '<leader>cC', desc = 'Claude Code (continue)' },
    { '<leader>cV', desc = 'Claude Code (verbose)' },
  },
  opts = {
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
        terminal = '<C-o>',
        variants = {
          continue = '<leader>cC',
          verbose = '<leader>cV',
        },
      },
    },
  },
}
