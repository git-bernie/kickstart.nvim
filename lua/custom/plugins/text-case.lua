--[[ An all in one plugin for converting text case in Neovim. It converts a piece of text 
to an indicated string case and also is capable of bulk replacing texts without changing cases
-- snake_case, camelCase, PascalCase, kebab-case, SCREAMING_SNAKE_CASE, Title Case, Sentence case, lowercase, UPPERCASE
-- NOTE: which-key will be activated by 'ga' for more info
-- gas: to snake_case
-- gac: to camelCase
-- ...and many more
]]
return {
  'johmsalas/text-case.nvim',
  dependencies = { 'nvim-telescope/telescope.nvim' },
  config = function()
    require('textcase').setup {}
    require('telescope').load_extension 'textcase'
  end,
  keys = {
    'ga', -- Default invocation prefix
    { 'ga.', '<cmd>TextCaseOpenTelescope<CR>', mode = { 'n', 'x' }, desc = 'Telescope' },
  },
  cmd = {
    -- NOTE: The Subs command name can be customized via the option "substitude_command_name"
    'Subs',
    'TextCaseOpenTelescope',
    'TextCaseOpenTelescopeQuickChange',
    'TextCaseOpenTelescopeLSPChange',
    'TextCaseStartReplacingCommand',
  },
  -- If you want to use the interactive feature of the `Subs` command right away, text-case.nvim
  -- has to be loaded on startup. Otherwise, the interactive feature of the `Subs` will only be
  -- available after the first executing of it or after a keymap of text-case.nvim has been used.
  lazy = false,
}
