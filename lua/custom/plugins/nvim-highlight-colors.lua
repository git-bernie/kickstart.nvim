-- Highlight hex colors, e.g. '#FFFFFF'
-- https://github.com/brenoprata10/nvim-highlight-colors
return {
  'brenoprata10/nvim-highlight-colors',

  opts = {
    ---@usage 'background'|'foreground'|'virtual'
    render = 'background',

    enable_hex = true,

    enable_named_colors = true,

    enable_tailwind = true,
    -- Exclude filetypes or buftypes from highlighting e.g. 'exclude_buftypes = {'text'}'
    exclude_filetypes = {},
    exclude_buftypes = {},
  },
}
