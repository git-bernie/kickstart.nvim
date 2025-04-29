--[[
-- NERDCommenter - I only want it for the "NERDCommenterSexy" command!
--]]
return {
  'preservim/nerdcommenter',
  enabled = true,
  init = function()
    vim.g.NERDCreateDefaultMappings = 1
    vim.g.NERDSpaceDelims = 1
  end,
}
