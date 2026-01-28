-- fugitive
-- https://github.com/tpope/vim-fugitive
return {
  'tpope/vim-fugitive',
  lazy = false,
  keys = {
    { '<leader>gh', ':Git log --oneline -- %<CR>', desc = 'Git history (file)' },
    { '<leader>ge', ':Gedit<CR>', desc = 'Git edit (working copy)' },
    { '<leader>gl', ':0Gclog<CR>', desc = 'Git log (file versions)' },
  },
}
