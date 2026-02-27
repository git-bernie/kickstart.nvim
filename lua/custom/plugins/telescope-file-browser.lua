--https://github.com/nvim-telescope/telescope-file-browser.nvim
return {
  'nvim-telescope/telescope-file-browser.nvim',
  keys = {
    {
      '<leader>se',
      '<cmd>Telescope file_browser follow_symlinks=true prompt_path=true create_from_prompt=false preview=true<cr>',
      desc = '[S]earch [e]xplorer (file browser)',
      silent = true,
    },
  },
}
