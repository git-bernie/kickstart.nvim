-- Disabled: redundant with CopilotChat.nvim (copilot-chat.lua), which provides
-- the same chat interface and is better maintained. ChatGPT.nvim also requires
-- a separate OpenAI API key.
return {
  'jackMort/ChatGPT.nvim',
  enabled = false,
  event = 'VeryLazy',
  config = function()
    require('chatgpt').setup()
  end,
  dependencies = {
    'MunifTanjim/nui.nvim',
    'nvim-lua/plenary.nvim',
    'folke/trouble.nvim', -- optional
    'nvim-telescope/telescope.nvim',
  },
}
