--[[
--This plugin is not super useful in addition to jq keymaps because it requires the ft to json also.
--]]
return {
  'VPavliashvili/json-nvim',
  ft = { 'json', 'php', 'markdown' }, -- only load for json filetype
  enabled = true,
  config = function()
    -- vim.keymap.set('n', '<leader>jff', '<cmd>JsonFormatFile<cr>')
    -- vim.keymap.set('n', '<leader>jmf', '<cmd>JsonMinifyFile<cr>')
    -- vim.keymap.set('v', '<leader>jfs', "<cmd>'<,'> ! JsonFormatSelection<cr>", { buffer = true, desc = '[json] [f]ormat [s]election' })
  end,
}
