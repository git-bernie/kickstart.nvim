--- Highlight and navigate TODO/FIXME/HACK/NOTE comments.
--- Keywords match text followed by a colon (e.g. TODO: fix this).
--- Default: highlights.comments_only = true (treesitter-aware).
---
--- Commands: :TodoTelescope, :TodoQuickFix, :TodoTelescope cwd=~/projects/foo

return {
  'folke/todo-comments.nvim',
  event = { 'BufReadPost', 'BufNewFile' },
  dependencies = { 'nvim-lua/plenary.nvim' },
  opts = {
    signs = true,
    signs_priority = 8,
    keywords = {
      -- Custom keyword (hint color)
      QQQ = { icon = ' ', color = 'hint', alt = { 'DEV', 'QQ', 'qqq', 'ZZZ' } },

      -- Built-in keywords with extra alts
      FIX = { alt = { 'PROBLEM', 'OMG', 'BUG', 'FIXME', 'BS' } },
      HACK = { alt = { 'TBD', 'WIP', 'WTF', 'DEPRECATED', 'Q', 'QUESTION', 'A', 'ANSWER' } },
      TODO = { alt = { 'SQL' } },
      TEST = {},
      NOTE = {
        alt = {
          'COMMENT', 'E.G.', 'EG', 'EX', 'EXPLANATION', 'FYI',
          'I.E.', 'IE', 'INFO', 'NB', 'NEW', 'OLD',
          'PAGE', 'SAFER', 'STEP', 'STEPS', 'feat', 'fix',
        },
      },
    },
  },

  -- ]w / [w to jump (avoids ]t/[t conflict with tag jumping)
  keys = {
    { ']w', function() require('todo-comments').jump_next() end, desc = 'Next todo comment' },
    { '[w', function() require('todo-comments').jump_prev() end, desc = 'Previous todo comment' },
  },
}
