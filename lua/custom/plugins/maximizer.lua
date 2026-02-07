-- Built-in maximize toggle — no plugin, instant.
-- Uses winrestcmd() to save/restore exact split sizes.
-- Previous plugin: 0x00-ketsu/maximizer.nvim

local saved_layout = nil

local function toggle_maximize()
  if saved_layout then
    vim.cmd(saved_layout)
    saved_layout = nil
  else
    saved_layout = vim.fn.winrestcmd()
    vim.cmd 'wincmd _ | wincmd |'
  end
end

vim.keymap.set('n', '<leader>z', toggle_maximize, { desc = 'Maximi[Z]er (Use tz)', silent = true })
vim.keymap.set('n', '<leader>tz', toggle_maximize, { desc = '[T]oggle Maximi[Z]er', silent = true })

return {}
