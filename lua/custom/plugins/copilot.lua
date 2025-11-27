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
    require('copilot').setup {}
  end,
}
