-- ~/.config/nvim/after/ftplugin/markdown.lua

-- Follow markdown links with <CR>, resolve relative to current file
vim.keymap.set('n', '<CR>', function()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]

  -- Find markdown link: [text](path)
  for link in line:gmatch('%[.-%]%((.-)%)') do
    local escaped = link:gsub('([%(%)%.%%%+%-%*%?%[%]%^%$])', '%%%1')
    local pattern = '%[.-%]%(' .. escaped .. '%)'
    local start_pos, end_pos = line:find(pattern)
    if start_pos and col >= start_pos - 1 and col <= end_pos then
      local current_dir = vim.fn.expand('%:p:h')
      local target = current_dir .. '/' .. link
      target = target:gsub('#.*$', '')  -- Remove anchor

      if vim.fn.filereadable(target) == 1 then
        vim.cmd('edit ' .. vim.fn.fnameescape(target))
      else
        vim.notify('File not found: ' .. target, vim.log.levels.WARN)
      end
      return
    end
  end
end, { buffer = true, silent = true, desc = 'Follow markdown link' })

-- Go back with <BS>
vim.keymap.set('n', '<BS>', ':edit #<CR>', { buffer = true, silent = true, desc = 'Go back' })

-- NOTE: This does not work!
-- Function to select the treesitter text object
local select_ts_textobject = function(query_string)
  -- This uses the select module from nvim-treesitter-textobjects
  require('nvim-treesitter-textobjects.select').select_textobject(query_string)
end

-- Define buffer-local keymaps for markdown files
-- Use 'x' for visual mode, 'o' for operator-pending mode (e.g., after 'd', 'c', 'y')
vim.keymap.set({ 'n', 'x', 'o' }, ']]', function()
  select_ts_textobject '@class.outer'
end, { buffer = true, desc = 'Select outer class (Markdown)' })

vim.keymap.set({ 'n', 'x', 'o' }, '[[', function()
  select_ts_textobject '@class.inner'
end, { buffer = true, desc = 'Select inner class (Markdown)' })
