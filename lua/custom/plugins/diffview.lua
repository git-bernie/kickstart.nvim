-- diffview.nvim — tabbed git diff viewer + file history browser
-- https://github.com/sindrets/diffview.nvim
--
-- Most-used flow: `<leader>gf` on any file opens a panel listing every commit
-- that touched it; arrow through them to see each commit's diff against its
-- parent — strictly more useful than fugitive's `:0Gclog` + `:Gvdiffsplit!`
-- for "walk this file's history."
return {
  'sindrets/diffview.nvim',
  cmd = {
    'DiffviewOpen',
    'DiffviewClose',
    'DiffviewToggleFiles',
    'DiffviewFocusFiles',
    'DiffviewRefresh',
    'DiffviewFileHistory',
  },
  keys = {
    { '<leader>gd', '<cmd>DiffviewOpen<cr>', desc = 'Diffview: open (working tree vs HEAD)' },
    { '<leader>gD', '<cmd>DiffviewClose<cr>', desc = 'Diffview: close' },
    { '<leader>gf', '<cmd>DiffviewFileHistory %<cr>', desc = 'Diffview: file history (current file)' },
    { '<leader>gF', '<cmd>DiffviewFileHistory<cr>', desc = 'Diffview: file history (all)' },
  },
  opts = {
    enhanced_diff_hl = true,
    view = {
      merge_tool = {
        layout = 'diff3_mixed',
        disable_diagnostics = true,
      },
    },
  },
}
