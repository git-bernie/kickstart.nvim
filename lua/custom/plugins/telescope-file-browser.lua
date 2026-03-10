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
    {
      '<leader>sE',
      function()
        local dir = vim.fn.input('Directory: ', '~/', 'dir')
        if dir ~= '' then
          require('telescope').extensions.file_browser.file_browser {
            path = vim.fn.expand(dir),
            follow_symlinks = true,
            prompt_path = true,
            create_from_prompt = false,
            preview = true,
          }
        end
      end,
      desc = '[S]earch [E]xplorer in directory (type a path)',
    },
  },
}
