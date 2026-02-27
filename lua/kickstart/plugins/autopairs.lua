-- autopairs
-- https://github.com/windwp/nvim-autopairs

return {
  'windwp/nvim-autopairs',
  event = 'InsertEnter',
  -- Optional dependency
  dependencies = { 'hrsh7th/nvim-cmp' },
  config = function()
    local npairs = require 'nvim-autopairs'

    npairs.setup {}

    -- Disable backtick pairing entirely - more trouble than it's worth
    -- (causes issues with ``` code fences and cursor movement)
    npairs.remove_rule '`'

    -- If you want to automatically add `(` after selecting a function or method
    local cmp_autopairs = require 'nvim-autopairs.completion.cmp'
    local cmp = require 'cmp'
    cmp.event:on('confirm_done', cmp_autopairs.on_confirm_done())
  end,
}
