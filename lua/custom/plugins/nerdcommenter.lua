--[[
-- NERDCommenter - I only want it for the "NERDCommenterSexy" command!
--]]
return {
  'preservim/nerdcommenter',
  cmd = { 'NERDCommenterSexy', 'NERDCommenterToggle', 'NERDCommenterComment' },
  init = function()
    vim.g.NERDCreateDefaultMappings = 1
    vim.g.NERDSpaceDelims = 1
  end,
}
