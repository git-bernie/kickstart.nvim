--[[ return {
  'github/copilot.vim',
  enabled = true,
  cmd = 'Copilot',
  event = 'BufWinEnter',
  init = function()
    vim.g.copilot_no_maps = true
  end,
  config = function()
    -- Block the normal Copilot suggestions
    vim.api.nvim_create_augroup('github_copilot', { clear = true })
    vim.api.nvim_create_autocmd({ 'FileType', 'BufUnload' }, {
      group = 'github_copilot',
      callback = function(args)
        vim.fn['copilot#On' .. args.event]()
      end,
    })
    vim.fn['copilot#OnFileType']()
  end,
} ]]

return {
  'zbirenbaum/copilot.lua',
  dependencies = {
    'copilotlsp-nvim/copilot-lsp', -- (optional) for NES functionality
  },
  cmd = 'Copilot',
  event = 'InsertEnter', -- Lazy Loading
  config = function()
    require('copilot').setup {
      suggestion = {
        auto_trigger = true,
        keymap = {
          -- accept = '<Tab>', -- Use <Tab> to accept inline suggestions
          -- accept = '<C-y>', -- Alternative: Use Ctrl+y to accept inline suggestions
          -- You can still map C-y if you prefer, but Tab is standard for ghost text
          -- accept = '<M-l>', -- Use Alt+l to accept inline suggestions (much better than <Tab>)
          accept = '<M-y>', -- Use Alt+y to accept inline suggestions (much better than <Tab>)
          accept_word = false,
          accept_line = false,
          next = '<M-]>',
          prev = '<M-[>',
          dismiss = '<C-]>',
        },
      },
      nes = {
        enabled = false,
        keymap = {
          accept_and_goto = '<leader>p',
          accept = false,
          dismiss = '<Esc>',
        },
      },

      vim.api.nvim_create_autocmd('User', {
        pattern = 'BlinkCmpMenuOpen',
        callback = function()
          vim.b.copilot_suggestion_hidden = true
        end,
      }),
      vim.api.nvim_create_autocmd('User', {
        pattern = 'BlinkCmpMenuClose',
        callback = function()
          vim.b.copilot_suggestion_hidden = false
        end,
      }),
    }
  end,
}
