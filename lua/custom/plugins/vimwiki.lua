return {
  'vimwiki/vimwiki',
  enabled = true,
  init = function() -- init not config() because it needs vimiwiki_list bfore loading
    vim.g.vimwiki_list = {
      {
        path = '~/work/vimwiki/',
        syntax = 'markdown',
        ext = '.md',
      },
    }
  end,
}
