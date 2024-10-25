--[[
👍
🐪
 😉
]]
return {
  'allaman/emoji.nvim',
  enabled = true,
  version = '1.0.0', -- optionally pin to a tag
  ft = { 'markdown', 'text', 'php' }, -- adjust to your needs
  dependencies = {
    -- optional for nvim-cmp integration
    'hrsh7th/nvim-cmp',
    -- optional for telescope integration
    'nvim-telescope/telescope.nvim',
  },
  opts = {
    -- default is false
    -- enable_cmp_integration = true,
    -- optional if your plugin installation directory
    -- is not vim.fn.stdpath("data") .. "/lazy/
    -- plugin_path = vim.fn.expand '$HOME/plugins/',
  },
  config = function(_, opts)
    require('emoji').setup(opts)
    -- optional for telescope integration
    local ts = require('telescope').load_extension 'emoji'
    vim.keymap.set('n', '<leader>se', ts.emoji, { desc = '[S]earch [E]moji' })

    --[[ require('cmp').setup {
      sources = {
        { name = 'emoji' }, -- Added plugin cmp-buffer
      },
    } ]]
    -- pcall(require('telescope').load_extension, 'emoji')
  end,
}
