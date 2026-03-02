-- fugitive
-- https://github.com/tpope/vim-fugitive
return {
  'tpope/vim-fugitive',
  cmd = { 'G', 'Git', 'Gedit', 'Gdiffsplit', 'Gread', 'Gwrite', 'Ggrep', 'GMove', 'GDelete', 'GBrowse', 'GRemove', 'GRename', 'Glgrep', 'Gclog' },
  keys = {
    { '<leader>gh', ':Git log --oneline -- %<CR>', desc = 'Git history (file)' },
    { '<leader>ge', ':Gedit<CR>', desc = 'Git edit (working copy)' },
    { '<leader>gl', ':0Gclog<CR>', desc = 'Git log (file versions)' },
  },
}
