-- smear-cursor owns the CURSOR animation (the trailing "smear" effect).
--
-- NOTE: mini.animate (init.lua ~1896) is also loaded and would otherwise
-- animate the cursor too — running both means the cursor is animated twice
-- on every CursorMoved. To avoid that, mini.animate's cursor sub-animation is
-- disabled there (`cursor = { enable = false }`), leaving it to handle only
-- scroll / open / close. If you ever remove this plugin, re-enable
-- mini.animate's cursor animation so cursor motion is still animated.
return {
  'sphamba/smear-cursor.nvim',
  event = 'VeryLazy',
  opts = {},
}
