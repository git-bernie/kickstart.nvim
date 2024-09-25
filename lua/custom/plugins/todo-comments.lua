-- Todo matches on any text that starts with one of your defined keywords (or alt) followed by a colon:
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
-- NOTE:
-- TBD:
-- qqq:
-- QQQ:
-- QQ:
-- STEP:
return {
  'folke/todo-comments.nvim',
  dependencies = { 'nvim-lua/plenary.nvim' },
  opts = {
    keywords = {
      QQQ = { icon = ' ', color = 'hint', alt = { 'DEV', 'FYI', 'QQQ', 'QQ', 'qqq', 'ZZZ', 'STEP', 'STEPS' } },
      HACK = { alt = { 'TBD' } },
    },
  },
}
