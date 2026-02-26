-- Todo matches on any text that starts with one of your defined keywords (or alt) followed by a colon:
-- NB: This default setting: highlights.comments_only = true, -- uses treesitter to match keywords in comments only

-- Try :TodoTelescope cwd=~/projects/foobar
-- Try :TodoQuickFix
-- Try :TodoTelescope

-- COMMENT:
-- DEV:
-- E.G.:
-- EG:
-- EX:
-- feat:
-- fix:
-- FIXME:
-- HACK:
-- IE:
-- NOTE:
-- OPTIMIZE:
-- PERF:
-- QQ:
-- QQQ:
-- qqq:
-- STEP:
-- STEPS:
-- TBD:
-- TEST:
-- TODO:
-- WARN:
-- WARNING:
-- WIP:
-- XXX:
-- ZZZ:

return {
  'folke/todo-comments.nvim',
  dependencies = { 'nvim-lua/plenary.nvim' },
  opts = {
    signs = true,
    signs_priority = 8,
    keywords = {
      -- QQQ: this is qqq
      QQQ = {
        icon = ' ',
        color = 'hint',
        alt = { 'DEV', 'QQQ', 'QQ', 'qqq', 'ZZZ' },
      },
      -- HACK is a built-in keyword, we just add more alts to it
      -- HACK: this a hack...
      -- QUESTION: something
      -- ANSWER: yada
      -- Q: another Q
      -- A: yada yada
      HACK = { alt = { 'TBD', 'WIP', 'WTF', 'DEPRECATED', 'Q', 'QUESTION', 'A', 'ANSWER' } },
      -- NOTE is a built-in keyword, we just add more alts to it
      -- Add to 'NOTE'
      -- NOTE: etc.
      NOTE = {
        alt = {
          'COMMENT',
          'E.G.',
          'EG',
          'EX',
          'EXPLANATION',
          'FYI',
          'I.E.',
          'IE',
          'INFO',
          'NB',
          'NEW',
          'OLD',
          'PAGE',
          'SAFER',
          'STEP',
          'STEPS',
          'feat',
          'fix',
        },
      },
      --fix(something): you fucker.
      --FIX(something): you fucker.
      -- PERF: this PERF, PERFORMANCE, OPTIMIZE, etc.
      -- TEST: this is a test!
      TEST = {},
      -- TODO: color = info
      TODO = { alt = { 'SQL' } },
      -- FIX: this is red!
      FIX = { alt = { 'PROBLEM', 'OMG', 'HOLYSHIT', 'OHFRAK', 'BUG', 'FIXME', 'BS' } },
    },
    exclude = {},
  },

  -- Jump to next/previous keyword -- using ]w/[w instead of ]t/[t which conflicts with 'jump to next matching tag'
  keys = {
    {
      ']w',
      function()
        require('todo-comments').jump_next()
      end,
      desc = 'Next todo comment',
    },
    {
      '[w',
      function()
        require('todo-comments').jump_prev()
      end,
      desc = 'Previous todo comment',
    },
  },
}
