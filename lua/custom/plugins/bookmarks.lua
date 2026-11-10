-- with lazy.nvim
return {
  'LintaoAmons/bookmarks.nvim',
  -- pin the plugin at specific version for stability
  -- backup your bookmark sqlite db when there are breaking changes (major version change)
  tag = 'v4.0.0',
  -- VeryLazy (not keys-only) so gutter signs for saved bookmarks appear without a keypress.
  event = 'VeryLazy',
  -- Shares <leader>b with buffer nav (<leader>bn / <leader>bp in init.lua) -- don't reuse n/p.
  -- Native ]b/[b are buffer nav in nvim 0.11+, and m{a-z} are Vim marks, so neither is used here.
  keys = {
    { '<leader>bm', '<cmd>BookmarksMark<cr>', mode = { 'n', 'v' }, desc = 'Bookmark: [m]ark / rename / toggle line' },
    { '<leader>bo', '<cmd>BookmarksGoto<cr>', desc = 'Bookmark: [o]pen picker (active list)' },
    { '<leader>bt', '<cmd>BookmarksTree<cr>', desc = 'Bookmark: [t]ree view' },
    { '<leader>bl', '<cmd>BookmarksLists<cr>', desc = 'Bookmark: pick active [l]ist' },
    { '<leader>bN', '<cmd>BookmarksNewList<cr>', desc = 'Bookmark: [N]ew list' },
    { '<leader>bd', '<cmd>BookmarksDesc<cr>', desc = 'Bookmark: [d]escription' },
    { '<leader>bg', '<cmd>BookmarksGrep<cr>', desc = 'Bookmark: [g]rep bookmarked files' },
    { '<leader>bc', '<cmd>BookmarksCommands<cr>', desc = 'Bookmark: [c]ommand picker' },
    { '<leader>bi', '<cmd>BookmarksInfoCurrentBookmark<cr>', desc = 'Bookmark: [i]nfo under cursor' },
    { '<leader>bj', '<cmd>BookmarksGotoNext<cr>', desc = 'Bookmark: next (line order)' },
    { '<leader>bk', '<cmd>BookmarksGotoPrev<cr>', desc = 'Bookmark: prev (line order)' },
  },
  dependencies = {
    { 'kkharji/sqlite.lua' },
    -- picker backend (choose one):
    { 'folke/snacks.nvim' }, -- default picker backend
    -- {"nvim-telescope/telescope.nvim"}, -- set picker.picker_backend = "telescope" to use
  },
  config = function()
    local opts = { backup = { enabled = true } } -- check the "./lua/bookmarks/default-config.lua" file for all the options
    require('bookmarks').setup(opts) -- you must call setup to init sqlite db
  end,
}

-- run :BookmarksInfo to see the running status of the plugin
