-- zen-mode.nvim — constrained-measure reading mode for prose.
--
-- WHY 88 COLUMNS: typography puts the comfortable measure for continuous prose
-- at 45-75 characters (Bringhurst's ideal is 66), degrading past ~90. The
-- mechanism is the RETURN SWEEP: reading is saccades of ~7-9 chars, and the
-- error-prone move is the long jump back to the start of the next line. Longer
-- lines -> more wrong-line landings -> silent re-reading and lost place.
--
-- Measured 2026-09-15: kitty windows here run 104-105 columns, so prose.lua's
-- soft wrap (wrap + linebreak, textwidth=0 -> wraps at WINDOW width) was
-- producing ~104-character lines. Over the comfortable range, but only by ~16
-- columns -- which is why this is an on-demand toggle rather than an automatic
-- hijack of every markdown buffer.
--
-- Toggle: <leader>tz   (mirrors prose.lua's <leader>tp convention)
-- To make it automatic, add `require('zen-mode').toggle()` to
-- after/ftplugin/markdown.lua. Deliberately not done by default.
--
-- Part of: ~/work/dotfiles/system-fixes/markdown-reading-ergonomics/
return {
  'folke/zen-mode.nvim',
  opts = {
    window = {
      backdrop = 1, -- 1 = don't dim the surround; we want normal colours
      width = 88, -- the measure. See above.
      height = 1, -- full height
      options = {
        number = true, -- keep the "where am I" gutter cue (see prose.lua)
        relativenumber = false,
        cursorline = false,
        signcolumn = 'no',
        list = false,
      },
    },
    plugins = {
      -- Leave global options alone so lualine (and its PROSE indicator,
      -- wired up in init.lua) stays visible.
      options = { enabled = false },
      twilight = { enabled = false },
      gitsigns = { enabled = false },
      tmux = { enabled = false },
      -- MUST stay off: zen-mode's kitty integration rescales the terminal
      -- font, which would fight the font settings in kitty.conf.
      kitty = { enabled = false },
    },
  },
  keys = {
    { '<leader>tz', '<cmd>ZenMode<cr>', desc = '[T]oggle [Z]en (88-col prose measure)' },
  },
}
