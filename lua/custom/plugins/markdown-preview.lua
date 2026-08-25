--[[ return {
  'iamcco/markdown-preview.nvim',
  cmd = { 'MarkdownPreviewToggle', 'MarkdownPreview', 'MarkdownPreviewStop' },
  ft = { 'markdown' },
  build = function()
    vim.fn['mkdp#util#install']()
  end,
} ]]

-- install with yarn or npm
return {
  'iamcco/markdown-preview.nvim',
  enabled = true,
  cmd = { 'MarkdownPreviewToggle', 'MarkdownPreview', 'MarkdownPreviewStop' },
  build = 'cd app && yarn install',
  init = function()
    vim.g.mkdp_filetypes = { 'markdown' }

    -- Default is 1: a BufHidden autocmd closes the browser preview the moment
    -- you leave the markdown buffer. Keep the page open so it stays readable
    -- while you work elsewhere; :MarkdownPreviewStop (or <leader>tm) closes it.
    vim.g.mkdp_auto_close = 0
  end,
  ft = { 'markdown' },
}
