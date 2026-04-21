-- ┌─────────────────────────────────────────────────────────────────────┐
-- │ prose.lua — soft-wrap "word processor" mode for Neovim             │
-- │                                                                     │
-- │ Gives markdown (and optionally other filetypes) a writing-friendly │
-- │ feel: visual soft wrap at word boundaries, no hard newlines         │
-- │ inserted, j/k move by display line, and undo breaks at sentence    │
-- │ punctuation and Enter so `u` undoes one sentence or list item      │
-- │ instead of a whole paragraph.                                       │
-- │                                                                     │
-- │ Auto-enabled:  after/ftplugin/markdown.lua                         │
-- │ Manual toggle: <leader>tp  (works in any buffer)                   │
-- │ Statusline:    lualine_a shows "PROSE" when active (init.lua)      │
-- │                                                                     │
-- │ Inspired by:                                                        │
-- │   • vim-pencil (preservim/vim-pencil) — undo-point-on-punctuation  │
-- │     technique originated here. Pencil also handles hard-wrap mode, │
-- │     autoformat blacklisting in tables/code, and conceal toggling.  │
-- │   • wrapping.nvim (andrewferrier/wrapping.nvim) — auto-detects     │
-- │     soft vs hard wrap per file via line-length heuristics.          │
-- │                                                                     │
-- │ This module intentionally stays minimal: soft wrap only, no hard   │
-- │ wrap mode, no auto-detection. Toggle off with <leader>tp when      │
-- │ editing tables or fenced code blocks.                               │
-- └─────────────────────────────────────────────────────────────────────┘

local M = {}

--- Enable prose mode for the current buffer.
--- Sets soft wrap, disables hard wrapping, remaps j/k to display lines,
--- and creates insert-mode undo break points at sentence punctuation.
function M.enable()
  local buf = vim.api.nvim_get_current_buf()
  vim.b.prose_mode = true

  -- Soft wrap at word boundaries (no mid-word breaks)
  vim.opt_local.wrap = true
  vim.opt_local.linebreak = true
  vim.opt_local.breakindent = true -- indented lines stay visually indented

  -- Disable hard wrapping — no newlines inserted as you type
  vim.opt_local.textwidth = 0
  vim.opt_local.formatoptions:remove 't' -- don't auto-wrap text
  vim.opt_local.formatoptions:remove 'c' -- don't auto-wrap comments

  -- Cleaner visual appearance for prose
  vim.opt_local.colorcolumn = ''
  vim.opt_local.relativenumber = false
  vim.opt_local.number = true

  -- j/k move by display line so navigation feels natural on wrapped text
  local opts = { buffer = buf, silent = true }
  vim.keymap.set('n', 'j', 'gj', opts)
  vim.keymap.set('n', 'k', 'gk', opts)
  vim.keymap.set('v', 'j', 'gj', opts)
  vim.keymap.set('v', 'k', 'gk', opts)

  -- Undo break points on sentence punctuation (technique from vim-pencil).
  -- Without this, `u` in normal mode undoes everything typed since entering
  -- insert mode — potentially an entire paragraph. With these, `u` undoes
  -- back to the last sentence boundary, which is far more intuitive for prose.
  -- <C-g>u creates an undo break point without leaving insert mode.
  for _, char in ipairs { '.', '!', '?', ',', ';', ':' } do
    vim.keymap.set('i', char, char .. '<C-g>u', { buffer = buf, silent = true })
  end

  -- Undo break point on Enter — the natural boundary between list items,
  -- paragraphs, and headings. In soft-wrap prose mode you rarely press Enter
  -- mid-sentence, so each Enter marks a meaningful undo checkpoint. This
  -- covers markdown lists (- item), numbered lists, and paragraph breaks
  -- without needing to detect specific patterns like ' - '.
  vim.keymap.set('i', '<CR>', '<CR><C-g>u', { buffer = buf, silent = true })
end

--- Disable prose mode for the current buffer, restoring code-oriented defaults.
function M.disable()
  local buf = vim.api.nvim_get_current_buf()
  vim.b.prose_mode = false

  vim.opt_local.wrap = false
  vim.opt_local.linebreak = false
  vim.opt_local.breakindent = false
  vim.opt_local.colorcolumn = '120'
  vim.opt_local.relativenumber = true

  -- Remove buffer-local j/k overrides
  pcall(vim.keymap.del, 'n', 'j', { buffer = buf })
  pcall(vim.keymap.del, 'n', 'k', { buffer = buf })
  pcall(vim.keymap.del, 'v', 'j', { buffer = buf })
  pcall(vim.keymap.del, 'v', 'k', { buffer = buf })

  -- Remove insert-mode undo break points
  for _, char in ipairs { '.', '!', '?', ',', ';', ':' } do
    pcall(vim.keymap.del, 'i', char, { buffer = buf })
  end
  pcall(vim.keymap.del, 'i', '<CR>', { buffer = buf })
end

--- Toggle prose mode on/off for the current buffer.
function M.toggle()
  if vim.b.prose_mode then
    M.disable()
    vim.notify('Prose mode OFF', vim.log.levels.INFO)
  else
    M.enable()
    vim.notify('Prose mode ON', vim.log.levels.INFO)
  end
end

--- Returns 'PROSE' if prose mode is active in the current buffer, nil otherwise.
--- Used by lualine_a in init.lua to override the mode display.
function M.mode_label()
  if vim.b.prose_mode then
    return 'PROSE'
  end
  return nil
end

return M
