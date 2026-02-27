-- Telescope emoji picker (completion is handled by blink-emoji.nvim in init.lua)
return {
  'allaman/emoji.nvim',
  version = '1.0.0',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-telescope/telescope.nvim',
  },
  keys = {
    {
      '<leader>sE',
      function()
        require('telescope').load_extension('emoji').emoji()
      end,
      desc = '[S]earch [E]moji',
    },
  },
  opts = {},
}
