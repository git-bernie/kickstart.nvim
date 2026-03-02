--[[
-- NERDCommenter - I only want it for the "NERDCommenterSexy" command!
--]]
return {
  'preservim/nerdcommenter',
  event = 'BufReadPost',
  init = function()
    vim.g.NERDCreateDefaultMappings = 1
    vim.g.NERDSpaceDelims = 1
  end,
}
