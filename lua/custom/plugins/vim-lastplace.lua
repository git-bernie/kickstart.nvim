return {
  'farmergreg/vim-lastplace',
  enabled = true,
  config = function()
    vim.g.lastplace_ignore_buftype = 'quickfix,nopreview'
    vim.g.lastplace_ignore_filetype = 'gitcommit,gitrebase,svn,hgcommit'
  end,
}
