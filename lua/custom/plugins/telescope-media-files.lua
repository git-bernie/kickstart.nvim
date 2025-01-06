return {
  'nvim-telescope/telescope-media-files.nvim',
  enabled = true,
  extensions = {
    media_files = {
      -- filetypes whitelist
      -- defaults to {"png", "jpg", "mp4", "webm", "pdf"}
      filetypes = { 'png', 'webp', 'jpg', 'jpeg', 'pdf' },
      -- find command (defaults to `fd`)
      find_cmd = 'rg',
    },
  },
}
