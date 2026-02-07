--https://github.com/nvim-telescope/telescope-file-browser.nvim
return {
  'nvim-telescope/telescope-file-browser.nvim',
  -- keys = {
  --[[ {
      '<leader>zf',
      '<cmd>Telescope file_browser follow_symlinks=true<cr>',
      desc = '[F]ile [B]rowser',
      silent = true,
    }, ]]
  -- Don't totally understand this one because I had to add <cr> to make work without waiting for a keystroke, or something.
  --[[ {
      '<leader>fd',
      '<cmd>Telescope file_browser path=%:p:h follow_symlinks=true<cr>',
      desc = '[F]ile Browser to this [D]ir',
      silent = true,
    }, ]]
  -- },
  config = function()
    vim.keymap.set(
      'n',
      '<leader>se',
      '<cmd>Telescope file_browser follow_symlinks=true prompt_path=true create_from_prompt=false preview=true<cr>',
      { desc = '[S]earch [e]xplorer (file browser)', silent = true }
    )
    --[[ 
    --- the difference is the path=%p:h which opens the file_browser in the current file's directoty. Meh.- 
    ---vim.keymap.set(
      'n',
      '<leader>sE',
      '<cmd>Telescope file_browser path=%:p:h follow_symlinks=true prompt_path=true create_from_prompt=false preview=true<cr>',
      { desc = '[S]earch [E]xplorer here (buffer dir)' }
    ) ]]
  end,
}
