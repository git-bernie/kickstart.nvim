-- Use the w, e, b motions like a spider. Move by subwords and skip insignificant punctuation.
-- A lua implementation of CamelCaseMotion, with extra consideration of punctuation.
-- Works in normal, visual, and operator-pending mode. Supports counts and dot-repeat.

-- if foo:find("%d") and foo == bar then print("[foo] has" .. bar) end
-- local myVariableName = FOO_BAR_BAZ
return {
  'chrisgrieser/nvim-spider',
  lazy = true,
  skipInsignificantPunctuation = true,
  vim.keymap.set({ 'n', 'o', 'x' }, 'w', "<cmd>lua require('spider').motion('w')<CR>", { desc = 'Spider-w' }),
  vim.keymap.set({ 'n', 'o', 'x' }, 'e', "<cmd>lua require('spider').motion('e')<CR>", { desc = 'Spider-e' }),
  vim.keymap.set({ 'n', 'o', 'x' }, 'b', "<cmd>lua require('spider').motion('b')<CR>", { desc = 'Spider-b' }),
}
