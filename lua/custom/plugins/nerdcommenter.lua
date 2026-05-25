--[[
-- NERDCommenter - I only want it for the "NERDCommenterSexy" command!
--]]
return {
  'preservim/nerdcommenter',
  keys = {
    { '<leader>cs', mode = { 'n', 'x' }, desc = 'NERDCommenter Sexy' },
  },
  init = function()
    vim.g.NERDCreateDefaultMappings = 1
    vim.g.NERDSpaceDelims = 1
  end,
}
