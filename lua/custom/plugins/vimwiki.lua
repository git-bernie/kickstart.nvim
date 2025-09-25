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
    vim.g.vimwiki_global_ext = 0
    -- I want to use markdown syntax for vimwiki and especially all tagbar to work...
    vim.g.vimwiki_filetypes = { 'markdown' }
  end,
}
