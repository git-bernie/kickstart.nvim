-- Migrated 2026-05-25 to main branch (nvim-treesitter ecosystem migration).
-- The old `textobjects = { select = {...}, move = {...} }` block in the
-- treesitter spec is gone on main; mappings are now explicit vim.keymap.set
-- calls into the textobjects.select / textobjects.move modules.

return {
  'nvim-treesitter/nvim-treesitter-textobjects',
  branch = 'main',
  event = 'BufReadPost',
  config = function()
    local select = require 'nvim-treesitter-textobjects.select'
    local move = require 'nvim-treesitter-textobjects.move'

    -- '%' jumps to matching block start/end (was: textobjects.select.keymaps)
    vim.keymap.set({ 'x', 'o' }, '%', function()
      select.select_textobject('@block.outer', 'textobjects')
    end, { desc = 'TS: select block.outer' })

    -- Forward jumps to next start
    vim.keymap.set({ 'n', 'x', 'o' }, ']]', function()
      move.goto_next_start('@function.outer', 'textobjects')
    end, { desc = 'TS: next function start' })
    vim.keymap.set({ 'n', 'x', 'o' }, ']b', function()
      move.goto_next_start('@block.outer', 'textobjects')
    end, { desc = 'TS: next block start' })
    vim.keymap.set({ 'n', 'x', 'o' }, ']e', function()
      move.goto_next_start('@class.outer', 'textobjects')
    end, { desc = 'TS: next class start' })

    -- Forward jumps to next end
    vim.keymap.set({ 'n', 'x', 'o' }, '][', function()
      move.goto_next_end('@function.outer', 'textobjects')
    end, { desc = 'TS: next function end' })
    vim.keymap.set({ 'n', 'x', 'o' }, ']B', function()
      move.goto_next_end('@block.outer', 'textobjects')
    end, { desc = 'TS: next block end' })

    -- Backward jumps to previous start
    vim.keymap.set({ 'n', 'x', 'o' }, '[[', function()
      move.goto_previous_start('@function.outer', 'textobjects')
    end, { desc = 'TS: prev function start' })
    vim.keymap.set({ 'n', 'x', 'o' }, '[b', function()
      move.goto_previous_start('@block.outer', 'textobjects')
    end, { desc = 'TS: prev block start' })
    vim.keymap.set({ 'n', 'x', 'o' }, '[e', function()
      move.goto_previous_start('@class.outer', 'textobjects')
    end, { desc = 'TS: prev class start' })

    -- Backward jumps to previous end
    vim.keymap.set({ 'n', 'x', 'o' }, '[]', function()
      move.goto_previous_end('@function.outer', 'textobjects')
    end, { desc = 'TS: prev function end' })
    vim.keymap.set({ 'n', 'x', 'o' }, '[B', function()
      move.goto_previous_end('@block.outer', 'textobjects')
    end, { desc = 'TS: prev block end' })
  end,
}
