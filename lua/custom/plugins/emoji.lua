-- Telescope emoji picker (completion is handled by blink-emoji.nvim in init.lua)
return {
  'allaman/emoji.nvim',
  enabled = true, -- disable if you only need completion, not Telescope picker
  version = '1.0.0',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-telescope/telescope.nvim',
  },
  config = function()
    require('emoji').setup()
    local ts = require('telescope').load_extension 'emoji'
    vim.keymap.set('n', '<leader>se', ts.emoji, { desc = '[S]earch [E]moji' })
  end,
}
