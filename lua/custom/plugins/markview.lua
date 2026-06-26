-- markview.nvim — the active in-buffer markdown renderer. markview-smart-tables
-- wraps wide tables to fit the window (handles GFM `:-:` separators and emoji
-- cleanly, where markdown-table-wrap.nvim failed). render-markdown.nvim is kept
-- disabled as a one-line fallback (see render-markdown.lua). hybrid_modes reveals
-- raw markdown under the cursor so editing still works.
return {
  'OXY2DEV/markview.nvim',
  lazy = false,
  dependencies = {
    'saghen/blink.cmp',
    'gunasekar/markview-smart-tables.nvim',
  },
  opts = {
    preview = {
      -- render the whole buffer, but show raw markdown on the line/block under
      -- the cursor in these modes (so you can read AND edit in place)
      hybrid_modes = { 'n', 'v', 'V', 'i' },
    },
    -- hand pipe-table rendering to smart-tables so wide tables wrap to fit
    renderers = {
      markdown_table = function(buffer, item)
        require('markview-smart-tables').render(buffer, item)
      end,
    },
  },
}
