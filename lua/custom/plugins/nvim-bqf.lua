-- `URL`: https://github.com/kevinhwang91/nvim-bqf
--[[
|-------------+----------------------------------------------------------+---------|
| Function    | Action                                                   | Def Key |
|-------------+----------------------------------------------------------+---------|
| open        | open the item under the cursor                           | <CR>    |
| openc       | open the item, and close quickfix window                 | o       |
| drop        | use drop to open the item, and close quickfix window     | O       |
| tabdrop     | use tab drop to open the item, and close quickfix window |
| tab         | open the item in a new tab                               | t       |
| tabb        | open the item in a new tab, but stay in quickfix window  | T       |
| tabc        | open the item in a new tab, and close quickfix window    | <C-t>   |
| split       | open the item in horizontal split                        | <C-x>   |
| vsplit      | open the item in vertical split                          | <C-v>   |
| prevfile    | go to previous file under the cursor in quickfix window  | <C-p>   |
| nextfile    | go to next file under the cursor in quickfix window      | <C-n>   |
| prevhist    | cycle to previous quickfix list in quickfix window       | <       |
| nexthist    | cycle to next quickfix list in quickfix window           | >       |
| lastleave   | go to last selected item in quickfix window              | '"      |
| stoggleup   | toggle sign and move cursor up                           | <S-Tab> |
| stoggledown | toggle sign and move cursor down                         | <Tab>   |
| stogglevm   | toggle multiple signs in visual mode                     | <Tab>   |
| stogglebuf  | toggle signs for same buffers under the cursor           | '<Tab>  |
| sclear      | clear the signs in current quickfix list                 | z<Tab>  |
| pscrollup   | scroll up half-page in preview window                    | <C-b>   |
| pscrolldown | scroll down half-page in preview window                  | <C-f>   |
| pscrollorig | scroll back to original position in preview window       | zo      |
| ptogglemode | toggle preview window between normal and max size        | zp      |
| ptoggleitem | toggle preview for a quickfix list item                  | p       |
| ptoggleauto | toggle auto-preview when cursor moves                    | P       |
| filter      | create new list for signed items                         | zn      |
| filterr     | create new list for non-signed items                     | zN      |
| fzffilter   | enter fzf mode                                           | zf      |
|-------------+----------------------------------------------------------+---------|
]]
return {
  'kevinhwang91/nvim-bqf',
  opts = {
    ft = { 'qf' },
    preview = {
      auto_preview = false,
    },
  },

  --[[ keys = {
    { '<leader>tq', ':BqfToggle', desc = '[T]oggle B[q]f', mode = { 'n', 'x', 'o' } },
  }, ]]

  dependencies = {
    'junegunn/fzf',
    build = function()
      vim.fn['fzf#install']()
    end,
    config = function() end,
  },
}
