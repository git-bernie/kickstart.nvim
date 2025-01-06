-- Todo matches on any text that starts with one of your defined keywords (or alt) followed by a colon:
-- NB: This default setting: highlights.comments_only = true, -- uses treesitter to match keywords in comments only

-- Try :TodoTelescope cwd=~/projects/foobar
-- Try :TodoQuickFix
-- Try :TodoTelescope

-- TODO:
-- HACK:
-- WARN:
-- WARNING:
-- PERF:
-- NOTE:
-- TEST:
-- FIXME:
-- ZZZ:
-- XXX:
-- OPTIMIZE:
-- FIX:
-- DEV:
-- TBD:
-- qqq:
-- QQQ:
-- QQ:
-- STEP:
-- STEPS:
-- COMMENT:
-- EG:
-- E.G.:
-- EX:
-- IE:
-- WIP:
return {
  'folke/todo-comments.nvim',
  dependencies = { 'nvim-lua/plenary.nvim' },
  opts = {
    keywords = {
      QQQ = {
        icon = ' ',
        color = 'hint',
        alt = { 'DEV', 'QQQ', 'QQ', 'qqq', 'ZZZ' },
      },
      -- Add to 'HACK'
      HACK = { alt = { 'TBD', 'WIP', 'WTF' } },
      -- Add to 'NOTE'
      NOTE = { alt = { 'NB', 'INFO', 'FYI', 'STEP', 'STEPS', 'COMMENT', 'EG', 'E.G.', 'EX', 'IE', 'I.E.', 'PAGE', 'EXPLANATION', 'OLD', 'NEW' } },
      -- Add to 'TODO'
      TODO = { alt = { 'SQL' } },
    },
    exclude = {},
  },

  -- Jump to next keyword -- I changed this to use ]w instead of ]t which conflicts with 'jump to next matching tag'
  vim.keymap.set('n', ']w', function()
    require('todo-comments').jump_next()
  end, { desc = 'Next todo comment' }),

  -- Jump to previous keyword
  vim.keymap.set('n', '[w', function()
    require('todo-comments').jump_prev()
  end, { desc = 'Previous todo comment' }),

  --[[ -- You can also specify a list of valid jump keywords
    vim.keymap.set("n", "]t", function()
      require("todo-comments").jump_next({keywords = { "ERROR", "WARNING" }})
    end, { desc = "Next error/warning todo comment" }), ]]
}
