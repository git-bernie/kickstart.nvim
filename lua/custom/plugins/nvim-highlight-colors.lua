-- Highlight hex colors, e.g. '#FFFFFF'
-- https://github.com/brenoprata10/nvim-highlight-colors
return {
  'brenoprata10/nvim-highlight-colors',
  enabled = true,

  opts = {
    ---@usage 'background'|'foreground'|'virtual'
    render = 'background',

    enable_hex = true,

    enable_short_hex = true,

    enable_rgb = true,

    enable_named_colors = true,

    enable_tailwind = true,

    enable_var_usage = true,

    -- Exclude filetypes or buftypes from highlighting e.g. 'exclude_buftypes = {'text'}'
    exclude_filetypes = {},

    exclude_buftypes = { 'nofile', 'help', 'prompt' },
  },

  -- FIXME: TODO Not working, breaks other stuff, obviously wrong...
  --[[ config = function()
    require('cmp').setup {
      formatting = {
        format = require('nvim-highlight-colors').format,
        fields = {},
        expandable_indicator = true,
      },
    }
  end, ]]
}
