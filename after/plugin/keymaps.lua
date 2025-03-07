--[ Bernie's Keymaps ]]
-- htps://www.reddit.com/r/neovim/comments/15ey6iu/any_reason_vimkeymapset_will_not_work_in/
-- print 'Loading after/keymap/keymaps.lua'

-- vim.keymap.set('n', '<Space>xyy', ':lua print("Hello, world!")<CR>', { desc = 'Print "Hello, world!' })
-- cabbrev evv e ~/.vimrc

vim.keymap.set('n', '<Space>gv', '<cmd>Gvdiffsplit<CR>', { desc = '[G][V]diffsplit Open a vertical diffsplit' })
vim.keymap.set('n', '<Space>cd', '<cmd>cd %:p:h<CR>', { desc = '[C]hange [D]irectory to the current file' })
vim.keymap.set('n', '<Space>lcd', '<cmd>lcd %:p:h<CR>', { desc = '[L]ocal [C]hange [D]irectory to the current file' })
--- Let me have "oo" and "OO" do what I want
-- Problem: oo and OO slow down "o" and "O" so find a better mapping
-- map ]<Space> o<esc>
-- map ]<Space> o<esc>
--  [[ Normal mode mappings]]
vim.keymap.set('n', '[<Leader>', 'O<esc>', { desc = 'Add a line above and return to normal mode' })
vim.keymap.set('n', ']<Leader>', 'o<esc>', { desc = 'Add a line below and return to normal mode' })
vim.keymap.set('v', '<Leader>1f', vim.lsp.buf.format, { desc = '[1] visual line [F]ormat' })
vim.keymap.set('c', '<c-a>', '<home>', { silent = false })
vim.keymap.set('c', '<c-b>', '<left>', { silent = false })
vim.keymap.set('c', '<c-e>', '<end>', { silent = false })
vim.keymap.set('c', '<c-h>', '<backspace>', { silent = false })
-- c-d usually does something else less necessary? tab handles old c-d
vim.keymap.set('c', '<c-d>', '<delete>', { silent = false, desc = 'delete in the commandline' })
--  telescope.command_history() will do this now
vim.keymap.set('c', '<c-f>', '<right>', { silent = false })

-- insert mode
vim.keymap.set('i', '<c-f>', '<right>', { silent = false })
vim.keymap.set('i', '<c-b>', '<left>', { silent = false })
vim.keymap.set('i', '<c-d>', '<delete>', { silent = false })
vim.keymap.set('i', '<c-h>', '<backspace>', { silent = false })
vim.keymap.set('i', '<c-a>', '<home>', { silent = false })
vim.keymap.set('i', '<c-e>', '<end>', { silent = false })

vim.keymap.set('n', ']j', '<cmd>cnext<cr>', { desc = ':cnext' })
vim.keymap.set('n', '[j', '<cmd>cprevious<cr>', { desc = ':cprevious' })
vim.keymap.set('n', '<a-j>', '<cmd>cnext<cr>', { desc = ':cnext' })
vim.keymap.set('n', '<a-k>', '<cmd>cprevious<cr>', { desc = ':cprevious' })
-- 's' causes lots of grief
-- vim.keymap.set('n', 's', '<cmd>WhichKey<cr>', { desc = '[s]how which key mappings for cmd mode' })
vim.keymap.set('n', '<Leader>wk', '<cmd>WhichKey<cr>', { desc = 'Sho[W] [W]hich key mappings for cmd mode' })
vim.keymap.set('i', 'jk', '<esc>', { desc = '[jk] to escape' })

--  [[ normal mode: ripgrep with args ]]
vim.keymap.set(
  'n',
  '<leader>fg',
  ":lua require('telescope').extensions.live_grep_args.live_grep_args({prompt_title = '[F]ind [G]rep using live_grep_args (\"word\" -tpphp)'})<cr>",
  {}
)

-- [[  commandline: ripgrep with args ]]
-- NOTE: every time I press rg quickly in command mode, this would trigger the command.
-- Not what I wanted.
--[[ vim.keymap.set(
  'c',
  'rg',
  ":lua require('telescope').extensions.live_grep_args.live_grep_args({prompt_title = '[R]ip[G]rep using live_grep_args (\"word\" -tpphp)'})<cr>",
  {}
) ]]

vim.keymap.set('n', '<leader>tn', function()
  local set = vim.opt_local
  ---@diagnostic disable-next-line: undefined-field
  if set.number:get() and set.relativenumber:get() then
    set.relativenumber = false
    set.number = false
  else
    set.number = true
    set.relativenumber = true
  end
end, { desc = '[t]oggle [n]umber and relative number' })

vim.keymap.set('n', '<leader>tm', '<cmd>MarkdownPreviewToggle<CR>', { desc = '[T]oggle [m]arkdown preview', silent = false })
--  e.g. 1726513513, 1726513523
vim.keymap.set('n', '<leader>yd', function()
  local unixtime = vim.fn.expand '<cword>'

  -- local num = nil
  -- find the sequential numbers at start of string or end of string
  local _, _, num = string.find(unixtime, '^([%d]+)')

  if num == nil or num == '' then
    _, _, num = string.find(unixtime, '([%d]+)$')
  end

  if num == nil or num == '' then
    _, _, num = string.find(unixtime, '([%d]+)')
  end

  local get_date = function(val)
    return os.date('%c', val)
  end

  if pcall(get_date, num) then
    print('num is ' .. tostring(num) .. ' ' .. os.date('%c', num))
  else
    print(string.format('invalid unixtime %s', num))
  end
end, { desc = '[y] [d]ate from unixtime cword' })

if (vim.fn.executable 'jq') == 1 then
  -- E15: Invalid expression: "<80><fd>h. ! jq --sort-keys^M"
  vim.keymap.set('n', '<leader>yj', '<cmd>. ! jq --sort-keys<cr>', { desc = '[y] [j]son pretty print' })
  vim.keymap.set('v', '<leader>yj', "<cmd>'<,'> ! jq --sort-keys<cr>", { buffer = true, desc = '[y] [j]son pretty print' })
  -- jl for  backwords compatibility
  vim.keymap.set('n', '<leader>jl', '<cmd>. ! jq --sort-keys<cr>', { desc = '[y] [j]son pretty print' })
  vim.keymap.set('v', '<leader>jl', "<cmd>'<,'> ! jq --sort-keys<cr>", { buffer = true, desc = '[y] [j]son pretty print' })
end

vim.keymap.set('n', '<leader>^', '<cmd>:vsplit<bar>bp<cr>', { noremap = true, desc = 'Vertical split and switch to previous buffer' })
--local current_line = vim.api.nvim_get_current_line()
--local json = vim.fn.json_decode(current_line)
--local output = vim.fn.systemlist { 'jq', '-s' }, { input = json, capture_output = true, text = true }

-- https://stackoverflow.com/questions/4256697/vim-search-and-highlight-but-do-not-jump
vim.keymap.set('n', '*', '*``', { noremap = true, silent = true, desc = '(*) search, highlight, and stay on current search result' })

vim.keymap.set('n', '#', '#``', { noremap = true, silent = true, desc = '(#) search, highlight, and stay on current search result' })

vim.keymap.set('n', '||', '<cmd>lua MiniFiles.open()<CR>', { desc = '[||] Open MiniFiles' })
vim.keymap.set('n', '<C-w>V', '<cmd>vertical new<CR>', { desc = '[C-w] [V]ertical split new' })

vim.keymap.set('n', 'gcp', ':norm yygccp<CR>', { silent = true, expr = false, desc = 'Copy and comment current line and paste below' })
vim.keymap.set('n', 'gcP', ':norm yygccP<CR>', { silent = true, expr = false, desc = 'Copy and comment current line and paste above' })

vim.keymap.set('n', '<leader>st', '<cmd>split +term<CR>', { desc = '[S]plit [T]erminal (split)' })
vim.keymap.set('n', '<leader>sv', '<cmd>vsplit +term<CR>', { desc = '[S]plit [v]ertical terminal (vsplit)' })

vim.keymap.set('n', '<leader>tw', '<cmd>set wrap!<CR>', { desc = '[T]oggle [w]rap', silent = false })

-- Keymaps for MiniMap which are strangely useful
vim.keymap.set('n', '<Leader>mc', MiniMap.close, { desc = '[m]inimap [c]lose' })
vim.keymap.set('n', '<Leader>mf', MiniMap.toggle_focus, { desc = '[m]inimap [f]ocus' })
vim.keymap.set('n', '<Leader>mo', MiniMap.open, { desc = '[m]inimap [o]pen' })
vim.keymap.set('n', '<Leader>mr', MiniMap.refresh, { desc = '[m]inimap [r]efresh' })
vim.keymap.set('n', '<Leader>ms', MiniMap.toggle_side, { desc = '[m]inimap [s]ide' })
vim.keymap.set('n', '<Leader>mt', MiniMap.toggle, { desc = '[m]inimap [t]oggle' })

--[[
-- TODO:
-- https://stackoverflow.com/questions/916875/yank-file-name-path-of-current-buffer-in-vim
-- :let @" = expand("%")
-- then paste with ""p or :reg ?
-- or better to clipboard:
-- :let @+ = expand("%") or :let @+=@%
-- after/plugin/keymaps.lua
-- C-r "  "after/plugin/keymaps.lua""
--]]

-- https://www.reddit.com/r/neovim/comments/1858n12/custom_keymap_to_copy_current_filepath_to/
local function copyFullPath()
  local filepath = vim.fn.expand '%'
  -- double quotes for spaces in path?
  vim.fn.setreg('+', '"' .. filepath .. '"') -- write to clippoard
end
-- E.g. "after/plugin/keymaps.lua"
vim.keymap.set('n', '<leader>cf', copyFullPath, { desc = '[c]opy [f]ull path' })
vim.keymap.set('n', 'sap', [[:norm sa<cmd>lua require'utils'.sudo_write()<CR>]], { silent = true })

-- https://vi.stackexchange.com/questions/39947/nvim-vim-o-cmdheight-0-looses-the-recording-a-macro-messages
vim.cmd [[ autocmd RecordingEnter * set cmdheight=1 ]]
vim.cmd [[ autocmd RecordingLeave * set cmdheight=0 ]]
-- Abbreviations E.g.
-- insert mode xbd inserts strftime "%b %d", i.e. Jan 01
-- :ab[breviate] lists all abbreviations
-- :ab x<CR> shows abbreviations starting with x...
-- :verbose ab[breviate] xbd shows where it was defined (but says it was done by lua...)
vim.cmd 'iab <expr> xabd (strftime("%a %b %d"))'
-- vim.cmd 'iab <expr> xd (strftime("%a %b %d"))'
vim.cmd 'iab <expr> xdate (strftime("%Y-%m-%d"))'
vim.cmd 'iab <expr> xdt (strftime("%c"))'
vim.cmd 'iab <expr> xdd (strftime("%a %d%b%Y"))'
vim.cmd 'iab <expr> xd (strftime("%d%b%Y"))'

-- These are just typos or misspellings that I make often
vim.cmd 'iab funciton function'
vim.cmd 'iab teh the'
