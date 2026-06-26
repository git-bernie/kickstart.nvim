-- Wraps wide markdown tables to fit the window inside markview.nvim. With 'wrap'
-- on (prose mode) every table is fitted; with 'wrap' off only oversized tables
-- are. Hooked into markview via the markdown_table renderer in markview.lua.
return {
  'gunasekar/markview-smart-tables.nvim',
  dependencies = { 'OXY2DEV/markview.nvim' },
  opts = {
    wrap_width = 0.9, -- max table width: window fraction (<=1) or absolute cols (>1)
    wrap_minwidth = 5, -- min column width before hard-breaking words
  },
}
