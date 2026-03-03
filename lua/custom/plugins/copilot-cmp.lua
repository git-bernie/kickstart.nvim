-- Disabled: nvim-cmp adapter for Copilot, superseded by the native blink.cmp
-- source (giuxtaposition/blink-cmp-copilot) configured in init.lua. Running
-- both would result in duplicate Copilot completions.
return {
  'zbirenbaum/copilot-cmp',
  enabled = false,
  event = 'InsertEnter',
  dependencies = 'zbirenbaum/copilot.lua',
  config = function()
    require('copilot_cmp').setup()
  end,
}
