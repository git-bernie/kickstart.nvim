--[[ gb
https://github.com/junegunn/vim-easy-align
Quite a powerful plugin.. ga starts it off...
]]
return {
  'junegunn/vim-easy-align',
  enabled = false,
  config = function()
    vim.cmd 'xmap ga <Plug>(EasyAlign)'
    vim.cmd 'nmap ga <Plug>(EasyAlign)'
  end,
}
