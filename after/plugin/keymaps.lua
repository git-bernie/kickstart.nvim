--[ Bernie's Keymaps ]]
-- vim: set fdm=marker:
-- htps://www.reddit.com/r/neovim/comments/15ey6iu/any_reason_vimkeymapset_will_not_work_in/
-- print 'Loading after/keymap/keymaps.lua'

-- vim.keymap.set('n', '<Space>xyy', ':lua print("Hello, world!")<CR>', { desc = 'Print "Hello, world!' })
-- cabbrev evv e ~/.vimrc

-- Override the default C-] with LSP definition, but preserve tag jump in help buffers
vim.keymap.set('n', '<C-]>', function()
  if vim.bo.filetype == 'help' then
    vim.cmd('tag ' .. vim.fn.expand '<cword>')
  else
    vim.lsp.buf.definition()
    vim.cmd 'normal! zz'
  end
end, { noremap = true, silent = true })

-- the | normal! zi will toggle the folding in the diff view
vim.keymap.set('n', '<Space>gv', '<cmd>Gvdiffsplit | normal! zi<CR>', { desc = '[G][V]diffsplit Open a vertical diffsplit' })
vim.keymap.set('n', '<Space>cd', '<cmd>cd %:p:h<CR>', { desc = '[C]hange [D]irectory to the current file' })
vim.keymap.set('n', '<Space>lcd', '<cmd>lcd %:p:h<CR>', { desc = '[L]ocal [C]hange [D]irectory to the current file' })
--- Let me have "oo" and "OO" do what I want
-- Problem: oo and OO slow down "o" and "O" so find a better mapping
-- map ]<Space> o<esc>
-- map ]<Space> o<esc>
--  [[ Normal mode mappings]]
vim.keymap.set('n', '[<Leader>', 'O<esc>', { desc = 'Add a line above and return to normal mode' })
vim.keymap.set('n', ']<Leader>', 'o<esc>', { desc = 'Add a line below and return to normal mode' })
-- vim.keymap.set('v', '<Leader>1f', vim.lsp.buf.format, { desc = '[1] visual line [F]ormat' })
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
  '<leader>/g',
  function()
    require('telescope').extensions.live_grep_args.live_grep_args { prompt_title = '/Find [G]rep using live_grep_args ("word" -- *.php)' }
  end,
  -- ":lua require('telescope').extensions.live_grep_args.live_grep_args({prompt_title = '/Find [G]rep using live_grep_args (\"word\" -- *.php)'})<cr>",
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

vim.keymap.set('n', '<leader>tW', function()
  local set = vim.opt
  -- local diffoptstable = set.diffopt:get()
  local diffoptstable = set.diffopt:get()
  local __ = vim.fn.printf

  -- print('before ' .. vim.inspect(diffoptstable))
  ---@diagnostic disable-next-line: undefined-field
  -- if string.find(table, 'iwhiteall', 1, true) then
  local found_at = nil
  for i, value in ipairs(diffoptstable) do
    if value == 'iwhiteall' then
      -- print(__('%d found iwhiteall as a value', i))
      found_at = i
      break
      -- table.remove(diffoptstable, i)
    else
      -- print 'did not find iwhiteall as a value)'
      -- table.insert(diffoptstable, 'iwhiteall')
    end
  end

  -- print('found_at is now ' .. (found_at or 'nil'))

  if found_at == nil then
    -- add
    -- table.insert(diffoptstable, 'iwhiteall')
    -- table.insert(vim.opt.diffopt, 'iwhiteall')
    -- print 'Will try to insert iwhiteall...'
    -- table.insert(vim.opt.diffopt, 'iwhitInieall')
    vim.opt.diffopt:append 'iwhiteall'
  else
    -- print(__('Will try to remove whiteall from position #%s', tostring(found_at)))
    -- table.remove(vim.opt.diffopt, found_at)
    -- table.remove(vim.opt.diffopt, found_at)
    vim.opt.diffopt:remove 'iwhiteall'
  end
  -- print('afterwards: ' .. vim.inspect(vim.opt.diffopt:get()))
  print(vim.inspect(vim.opt.diffopt:get()))
end, { desc = '[T]oggle i[W]hiteall vim.opt.diffopt:append()/remove() iwhiteall' })

-- FIXME: set inv{option} to toggle instead?
vim.keymap.set('n', '<leader>tN', function()
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
-- See nvim-treesitter-context
-- vim.keymap.set('n', '<leader>tx', '<cmd>TSContext toggle<CR>', { desc = '[T]oggle TSConte[x]t', silent = false })
--

-- See settings in init.lua for MiniSessions config
-- ms already taken by minimap
vim.keymap.set('n', '<leader>mk', function()
  require('mini.sessions').write('Session.vim', { force = { write = true } })
end, { desc = [[[M]a[k]e Session via .write('Session.vim')]], silent = false })

vim.keymap.set('n', '<leader>md', function()
  require('mini.sessions').delete('Session.vim', { force = { write = true } })
end, { desc = [[[M]ake Session [D]elete via .delete('Session.vim')]], silent = false })

vim.keymap.set('n', '<leader>mR', function()
  require('mini.sessions').read('Session.vim', { force = { write = true } })
end, { desc = [[[M]iniSessions [R]ead .read('Session.vim')]], silent = false })

--
-- Example v2 encoding "QjRpxuZGJKDxLUV1RFh8CPjYEf_t9y_8FYgc2DCXuVc"
vim.api.nvim_create_user_command('DecodeV2', function(opts)
  local start_line = opts.line1
  local end_line = opts.line2
  local selected_lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)

  for _, line in ipairs(selected_lines) do
    print(line)
  end
end, { range = true })

vim.keymap.set('n', '<leader>v2', function()
  local sqlite = require 'sqlite'
  local db = sqlite.open '/home/bernie/Downloads-work/id_encodedids.db'
  if not db then
    print 'Error opening database'
    return
  else
    print 'Opened the database'
  end
end)

-- E.g. "LenderUpdate.1759824438.2ndLoan":
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
    print('unxitime: ' .. tostring(num) .. ' ' .. os.date('%c %z', num))
  else
    print(string.format('invalid unixtime %s', num))
  end
end, { desc = '[Y]our [d]ate from unixtime cword' })

if (vim.fn.executable 'jq') == 1 then
  -- E15: Invalid expression: "<80><fd>h. ! jq --sort-keys^M"
  -- NOTE: By default jq produces 'pretty'. `jq -c` is --copmact-output
  vim.keymap.set('n', '<leader>yj', '<cmd>. ! jq --sort-keys<cr>', { desc = '[y] [j]son pretty print' })
  vim.keymap.set('v', '<leader>yj', "<cmd>'<,'> ! jq --sort-keys<cr>", { buffer = true, desc = '[y] [j]son pretty print' })
  -- Sometems it is best not sorted.
  vim.keymap.set('n', '<leader>yk', '<cmd>. ! jq<cr>', { desc = '[y] [k] json pretty print, no sort' })
  vim.keymap.set('v', '<leader>yk', "<cmd>'<,'> ! jq<cr>", { buffer = true, desc = '[y] [k] json pretty print, no sort' })

  -- Rarely used but might be dug up in a pinch
  -- vim.keymap.set('n', '<leader>yjc', '<cmd>. ! jq --compact-output<cr>', { desc = '[y] [j]son [c]ompact-output' })
  -- vim.keymap.set('v', '<leader>yjc', "<cmd>'<,'> ! jq --compact-output<cr>", { buffer = true, desc = '[y] [j]son [c]ompact output' })g;
  -- jl for  backwords compatibility

  vim.keymap.set('n', '<leader>jl', '<cmd>. ! jq --sort-keys<cr>', { desc = '[y] [j]son pretty print' })
  vim.keymap.set('v', '<leader>jl', "<cmd>'<,'> ! jq --sort-keys<cr>", { buffer = true, desc = '[y] [j]son pretty print' })
end

-- Not as useful as jq but sometimes needed, if just to remember how to use yq
if (vim.fn.executable 'yq') == 1 then
  -- E15: Invalid expression: "<80><fd>h. ! jq --sort-keys^M "
  -- NOTE: -p, --input-format string [auto|a|yaml|y|json|j|props|p|csv|c|tsv|t|xml|x|base64|uri|toml|lua|l|ini|i] parse format for input. (default "auto")
  -- NOTE: -P is --prettyPrint
  vim.keymap.set('n', '<leader>yq', "<cmd>. ! yq -pjson -P 'sort_keys(..)'<cr>", { desc = "[y] [q] -pjson -P 'sort_keys(..)' ..." })
  vim.keymap.set('v', '<leader>yq', "<cmd>'<,'> ! yq -pjson -P 'sort_keys(..)'<cr>", { buffer = true, desc = "[y] [q] -pjson -P 'sort_keys(..)' ..." })
  -- Assuming we have yq available
  -- E.g. command! JsonToYaml %!yq -P
  -- command! JsonToYaml setf yaml
  vim.api.nvim_create_user_command('JsonToYaml', function()
    -- Save current buffer content, convert, and replace
    vim.cmd '%!yq -pjson -P'
    -- vim.cmd 'setf yaml' -- Set filetype to yaml
  end, { desc = 'Convert current buffer from JSON to YAML' })
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
vim.keymap.set('n', '<C-w>Q', 'ZQ<CR>', { desc = '[C-w] [Q]uit without saving!' })

vim.keymap.set('n', 'gcp', ':norm yygccp<CR>', { silent = true, expr = false, desc = 'Copy and comment current line and paste below' })
vim.keymap.set('n', 'gcP', ':norm yygccP<CR>', { silent = true, expr = false, desc = 'Copy and comment current line and paste above' })

vim.keymap.set('n', '<leader>st', '<cmd>split +term<CR>', { desc = '[S]plit [T]erminal (split)' })
vim.keymap.set('n', '<leader>sv', '<cmd>vsplit +term<CR>', { desc = '[S]plit [v]ertical terminal (vsplit)' })

vim.keymap.set('n', '<leader>tw', '<cmd>set wrap!<CR>', { desc = '[T]oggle [w]rap', silent = false })

-- TODO: this is best put ins csvview.lua
vim.keymap.set('n', '<leader>tv', '<cmd>CsvViewToggle<CR>', { desc = '[T]oggle Cs[v]ViewEnable', silent = false })

-- Keymaps for MiniMap which are strangely useful
vim.keymap.set('n', '<Leader>mc', MiniMap.close, { desc = '[m]inimap [c]lose' })
vim.keymap.set('n', '<Leader>mf', MiniMap.toggle_focus, { desc = '[m]inimap [f]ocus' })
vim.keymap.set('n', '<Leader>mo', MiniMap.open, { desc = '[m]inimap [o]pen' })
vim.keymap.set('n', '<Leader>mr', MiniMap.refresh, { desc = '[m]inimap [r]efresh' })
vim.keymap.set('n', '<Leader>ms', MiniMap.toggle_side, { desc = '[m]inimap [s]ide' })
vim.keymap.set('n', '<Leader>mt', MiniMap.toggle, { desc = '[m]inimap [t]oggle' })

-- vim.keymap.set('n', '<leader>gr', [[<cmd>:Git reflog --format='%C(yellow)%h%C(reset) %gs %C(green)%ad%C(reset)'<CR>]], { desc = '[G]it [r]eflog' })
vim.keymap.set('n', '<leader>gR', [[<cmd>:Git reflog --date=iso<CR>]], { desc = '[G]it [r]eflog --date=iso' })
vim.keymap.set(
  'n',
  '<leader>gr',
  [[<cmd>:Git for-each-ref --sort=committerdate refs/heads/ --format='%(HEAD) %(align:35)%(color:yellow)%(refname:short)%(color:reset)%(end) - %(color:red)%(objectname:short)%(color:reset) - %(align:40)%(contents:subject)%(end) - %(authorname) (%(color:green)%(committerdate:relative)%(color:reset))'<CR>]],
  { desc = '[G]it for-each-[r]eflog...' }
)
--[=[ vim.keymap.set(
  'n',
  '<leader>gr',
  [[<cmd>:Git for-each-ref --sort=committerdate refs/heads/ --format='%(HEAD) %(align:35)%(color:yellow)%(refname:short)%(color:reset)%(end) - %(color:red)%(objectname:short)%(color:reset) - %(align:40)%(contents:subject)%(end) - %(authorname) (%(color:green)%(committerdate:relative)%(color:reset))'<CR>]],
  { desc = '[G]it [r]eflog' }
) ]=]

--[[ FzfLua keymaps ]]
vim.keymap.set('n', '<leader>fb', [[<cmd>lua require('fzf-lua').git_branches()<cr>]], { desc = '[G]it [b]ranches (FzfLua)' })
vim.keymap.set('n', '<leader>gt', [[<cmd>lua require('fzf-lua').git_tags()<cr>]], { desc = '[G]it [T]ags (FzfLua)' })
vim.keymap.set('n', '<leader>fs', [[<cmd>lua require('fzf-lua').git_status()<cr>]], { desc = '[F]zfLua [S]tatus' })
vim.keymap.set('n', '<leader>fc', [[<cmd>lua require('fzf-lua').git_bcommits()<cr>]], { desc = '[F]zfLua Git Buffer [C]ommits' })
vim.keymap.set('n', '<leader>fC', [[<cmd>lua require('fzf-lua').git_commits()<cr>]], { desc = '[F]zfLua Git (Directory) [C]ommits' })
--[[ FzfLua has so many interesting methods: also available grep_cWORD]]
vim.keymap.set('n', '<leader>fw', [[<cmd>lua require('fzf-lua').grep_cword()<cr>]], { desc = '[F]zfLua c[w]ord' })
-- running out of f!
-- vim.keymap.set('n', '<leader>b/', [[<cmd>lua require('fzf-lua').grep_curbuf()<cr>]], { desc = 'FzfLua grep_cur[b/]uf' })
-- vim.keymap.set('n', '<leader>f/', [[<cmd>lua require('fzf-lua').grep_curbuf()<cr>]], { desc = '[F]zfLua [/] grep_curbuf' })

vim.keymap.set('n', '<leader>/b', function()
  require('fzf-lua').grep_curbuf { prompt = 'Grep Cur Buff> ', winopts = { title = 'Grep Current Buffer' } }
end, { desc = 'FzfLua grep_cur[/b]uf' })
vim.keymap.set('n', '<leader>/f', function()
  require('fzf-lua').grep_project { prompt = 'Grep Project> ', winopts = { title = 'Grep Project' } }
end, { desc = '[F]zfLua [/] grep_project' })

vim.keymap.set('n', '<leader>fl', [[<cmd>lua require('fzf-lua').grep({resume=true})<cr>]], { desc = '[F]zfLua [l] grep last (resume=true)' })
vim.keymap.set('n', '<leader>fz', [[<cmd>FzfLua<cr>]], { desc = ':[F][z]fLua see all FzfLua methods' })
vim.keymap.set('n', '<leader>fF', [[<cmd>FzfLua files<cr>]], { desc = ':[f]zfLua [F]iles' })
vim.keymap.set('n', '<leader>FF', [[<cmd>FzfLua files<cr>]], { desc = ':[f]zfLua [F]iles' })
vim.keymap.set('n', '<leader>/g', function()
  require('fzf-lua').live_grep { hidden = false, prompt = 'Live Grep> ', winopts = { title = 'Live Grep' } }
end, { desc = 'FzfLua live_[/g]rep ( -- to specify globs)' })
vim.keymap.set('n', '<leader>fd', [[<cmd>lua require('fzf-lua').diagnostics_document()<cr>]], { desc = '[F]zfLua live_[d]iagnostics_document)' })
vim.keymap.set('n', '<leader>fD', [[<cmd>lua require('fzf-lua').diagnostics_workspace()<cr>]], { desc = '[F]zfLua live_[D]iagnostics_workspace)' })
vim.keymap.set('n', '<leader>fm', function()
  require('telescope').extensions.media_files.media_files()
end, { desc = 'Find media files' })
vim.keymap.set(
  'n',
  '<leader>fh',
  [[<cmd>lua require('fzf-lua').live_grep({hidden = true})<cr>]],
  { desc = '[F]zfLua live_[g]rep show [h]idden ( -- to specify globs)' }
)

require('fzf-lua').setup {
  keymap = {
    fzf = {
      ['ctrl-q'] = 'select-all+accept',
    },
  },
}
vim.keymap.set({ 'n', 'v', 'i' }, '<C-x><C-f>', function()
  require('fzf-lua').complete_path()
end, { silent = true, desc = 'Fuzzy complete path' })
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

-- Usage:
-- copyPath('full')
-- copyPath('name')
-- copyPath('absolute')
-- You should probably learn how to use % a bit better!
local function copyPath(type)
  local modifiers = {
    full = '%', -- relative path
    name = '%:t', -- filename only
    absolute = '%:p', -- absolute path
  }
  local filepath = vim.fn.expand(modifiers[type] or '%')
  vim.fn.setreg('+', '"' .. filepath .. '"')
  vim.notify(filepath)
end

-- E.g. "after/plugin/keymaps.lua"
-- vim.keymap.set('n', '<leader>cf', copyFullPath, { desc = '[c]opy [f]ull path' })
vim.keymap.set('n', '<leader>yp', function()
  copyPath 'full'
end, { desc = '[y]ank [p]ath %' })
vim.keymap.set('n', '<leader>yP', function()
  copyPath 'absolute'
end, { desc = '[y]ank absolute [P]ath %:p' })
vim.keymap.set('n', '<leader>yn', function()
  copyPath 'name'
end, { desc = '[y]ank file[n]ame %:t' })
-- vim.keymap.set('n', 'sap', [[:norm sa<cmd>lua require'utils'.sudo_write()<CR>]], { silent = true })

vim.api.nvim_create_user_command('Format', function(args)
  local range = nil
  if args.count ~= -1 then
    local end_line = vim.api.nvim_buf_get_lines(0, args.line2 - 1, args.line2, true)[1]
    range = {
      start = { args.line1, 0 },
      ['end'] = { args.line2, end_line:len() },
    }
  end
  require('conform').format { async = true, lsp_format = 'fallback', range = range }
end, { range = true })

-- Helper function to open fugitive and jump to the current file
local function open_fugitive_and_jump_to_file()
  -- Get the current file's path relative to git root
  local current_file = vim.fn.expand '%:t'
  if current_file == '' then
    current_file = nil
  end

  -- Open fugitive
  vim.cmd 'G'

  -- If we had a file, search for it in the fugitive buffer
  if current_file then
    vim.schedule(function()
      -- Search for the filename (case sensitive, no wrap, start from top)
      vim.fn.cursor(1, 1)
      local found = vim.fn.search(current_file, 'cW')
      if found == 0 then
        -- If not found, stay at the top
        vim.fn.cursor(1, 1)
      end
    end)
  end
end

vim.keymap.set('n', '<leader>gg', open_fugitive_and_jump_to_file, { silent = false, desc = '[G]oto:Fu[G]itive' })

-- Toggle fugitive with <leader>GG. Keymap chosen to be like <leader>gg
-- and not to conflict with other mappings.
vim.keymap.set('n', '<leader>GG', function()
  -- Check if fugitive buffer is already open in a window
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype == 'fugitive' then
      vim.api.nvim_win_close(win, false)
      return
    end
  end
  -- Not open, so open it and jump to current file
  open_fugitive_and_jump_to_file()
end, { silent = false, desc = '[G]it Toggle fugitive' })
-- vim.api.nvim_set_keymap('n', '-', [[<cmd>lua require('window-picker').pick_window()<CR>]], { desc = 'pick[-]window', silent = true, noremap = true })

-- TreeSJ
vim.keymap.set('n', '<leader>tj', function()
  require('treesj').toggle()
end, { desc = '[T]oggle TreeS[J] split/join' })

-- Noice
vim.keymap.set('c', '<S-Enter>', function()
  require('noice').redirect(vim.fn.getcmdline())
end, { desc = 'Redirect Cmdline' })

-- Define a function to toggle Noice
local function toggle_noice()
  if vim.g.noice_enabled == nil or vim.g.noice_enabled == true then
    vim.cmd 'Noice disable'
    vim.g.noice_enabled = false
    vim.notify('Noice disabled', vim.log.levels.INFO)
  else
    vim.cmd 'Noice enable'
    vim.g.noice_enabled = true
    vim.notify('Noice enabled', vim.log.levels.INFO)
  end
end

-- More common than toggle line numbers see: tN
vim.keymap.set('n', '<leader>tn', toggle_noice, { desc = 'Toggle Noice enable/disable', silent = false })

-- Initialize the global variable to true when Noice is first loaded
vim.g.noice_enabled = true

local picker = require 'window-picker'
-- vim.keymap.set('n', ',w', function()
vim.keymap.set('n', ',w', function()
  local picked_window_id = picker.pick_window {
    include_current_win = true,
  } or vim.api.nvim_get_current_win()
  vim.api.nvim_set_current_win(picked_window_id)
end, { desc = 'Pick a window' })

vim.keymap.set('n', '-', function()
  local picked_window_id = picker.pick_window {
    include_current_win = true,
  } or vim.api.nvim_get_current_win()
  vim.api.nvim_set_current_win(picked_window_id)
end, { desc = 'Pick a window' })

vim.api.nvim_set_keymap('n', '<leader>sx', '', {
  noremap = true,
  callback = function()
    -- for _, client in ipairs(vim.lsp.buf_get_clients()) do
    for _, client in ipairs(vim.lsp.get_clients()) do
      require('workspace-diagnostics').populate_workspace_diagnostics(client, 0)
    end
  end,
})

-- https://vi.stackexchange.com/questions/39947/nvim-vim-o-cmdheight-0-looses-the-recording-a-macro-messages
vim.cmd [[ autocmd RecordingEnter * set cmdheight=1 ]]
vim.cmd [[ autocmd RecordingLeave * set cmdheight=0 ]]

if IsLaravelInComposer() then
  vim.cmd [[ autocmd BufWritePost *.php silent !./vendor/bin/pint %:p ]]
end

-- Abbreviations E.g.
-- insert mode xbd inserts strftime "%b %d", i.e. Jan 01
-- :ab[breviate] lists all abbreviations
-- :ab x<CR> shows abbreviations starting with x...
-- :verbose ab[breviate] xbd shows where it was defined (but says it was done by lua...)

--[[ @see https://pubs.opengroup.org/onlinepubs/009696799/functions/strftime.html {{{
  %a Replaced by the locale's abbreviated weekday name. [ tm_wday]
  %A Replaced by the locale's full weekday name. [ tm_wday]
  %b Replaced by the locale's abbreviated month name. [ tm_mon]
  %B Replaced by the locale's full month name. [ tm_mon]
  %c Replaced by the locale's appropriate date and time representation. (See the Base Definitions volume of IEEE Std 1003.1-2001, <time.h>.) %C Replaced by the year divided by 100 and truncated to an integer, as a decimal number [00,99]. [ tm_year]
  %d Replaced by the day of the month as a decimal number [01,31]. [ tm_mday]
  %D Equivalent to %m / %d / %y. [ tm_mon, tm_mday, tm_year]
  %e Replaced by the day of the month as a decimal number [1,31]; a single digit is preceded by a space. [ tm_mday]
  %F Equivalent to %Y - %m - %d (the ISO 8601:2000 standard date format). [ tm_year, tm_mon, tm_mday]
  %g Replaced by the last 2 digits of the week-based year (see below) as a decimal number [00,99]. [ tm_year, tm_wday, tm_yday]
  %G Replaced by the week-based year (see below) as a decimal number (for example, 1977). [ tm_year, tm_wday, tm_yday]
  %h Equivalent to %b. [ tm_mon]
  %H Replaced by the hour (24-hour clock) as a decimal number [00,23]. [ tm_hour]
  %I Replaced by the hour (12-hour clock) as a decimal number [01,12]. [ tm_hour]
  %j Replaced by the day of the year as a decimal number [001,366]. [ tm_yday]
  %m Replaced by the month as a decimal number [01,12]. [ tm_mon]
  %M Replaced by the minute as a decimal number [00,59]. [ tm_min]
  %n Replaced by a <newline>.
  %p Replaced by the locale's equivalent of either a.m. or p.m. [ tm_hour]
  %r Replaced by the time in a.m. and p.m. notation; [CX] [Option Start]  in the POSIX locale this shall be equivalent to %I : %M : %S %p. [Option End] [ tm_hour, tm_min, tm_sec]
  %R Replaced by the time in 24-hour notation ( %H : %M ). [ tm_hour, tm_min]
  %S Replaced by the second as a decimal number [00,60]. [ tm_sec]
  %t Replaced by a <tab>.
  %T Replaced by the time ( %H : %M : %S ). [ tm_hour, tm_min, tm_sec]
  %u Replaced by the weekday as a decimal number [1,7], with 1 representing Monday. [ tm_wday]
  %U Replaced by the week number of the year as a decimal number [00,53]. The first Sunday of January is the first day of week 1; days in the new year before this are in week 0. [ tm_year, tm_wday, tm_yday]
  %V Replaced by the week number of the year (Monday as the first day of the week) as a decimal number [01,53]. If the week containing 1 January has four or more days in the new year, then it is considered week 1. Otherwise, it is the last week of the previous year, and the next week is week 1. Both January 4th and the first Thursday of January are always in week 1. [ tm_year, tm_wday, tm_yday]
  %w Replaced by the weekday as a decimal number [0,6], with 0 representing Sunday. [ tm_wday]
  %W Replaced by the week number of the year as a decimal number [00,53]. The first Monday of January is the first day of week 1; days in the new year before this are in week 0. [ tm_year, tm_wday, tm_yday]
  %x Replaced by the locale's appropriate date representation. (See the Base Definitions volume of IEEE Std 1003.1-2001, <time.h>.)
  %X Replaced by the locale's appropriate time representation. (See the Base Definitions volume of IEEE Std 1003.1-2001, <time.h>.)
  %y Replaced by the last two digits of the year as a decimal number [00,99]. [ tm_year]
  %Y Replaced by the year as a decimal number (for example, 1997). [ tm_year]
  %z Replaced by the offset from UTC in the ISO 8601:2000 standard format ( +hhmm or -hhmm ), or by no characters if no timezone is determinable. For example, "-0430" means 4 hours 30 minutes behind UTC (west of Greenwich). [CX] [Option Start]  If tm_isdst is zero, the standard time offset is used. If tm_isdst is greater than zero, the daylight savings time offset is used. If tm_isdst is negative, no characters are returned. [Option End] [ tm_isdst]
  %Z Replaced by the timezone name or abbreviation, or by no bytes if no timezone information exists. [ tm_isdst]
  %% Replaced by %.
}}}--]]

--[[ 
xabd  Thu Apr 24
xd    24Apr2025
xdate 2025-04-24
xdc   Thu 24 Apr 2025 09:42:02 AM PDT
xdd   Thu 24Apr2025 
xdt   Thursday April 24, 2025 09:38:25 PDT 
]]
vim.cmd 'iab <expr> xabd (strftime("%a %b %d"))'
vim.cmd 'iab <expr> xd (strftime("%d%b%Y"))'
vim.cmd 'iab <expr> xdate (strftime("%Y-%m-%d"))'
vim.cmd 'iab <expr> xdc (strftime("%c %Z"))'
vim.cmd 'iab <expr> xdd (strftime("%a %d%b%Y"))'
vim.cmd 'iab <expr> xdt (strftime("%A %B %e, %Y %T %Z"))'

-- These are just typos or misspellings that I make often
vim.cmd 'iab funciton function'
vim.cmd 'iab teh the'

--- Lookup a user by encoded ID from the local SQLite database.
---@param db_path string
---@param encoded_id string
local function lookup_user_by_id(db_path, encoded_id)
  local sqlite = require 'sqlite'
  local db = sqlite:open(db_path) -- Open the database file
  if not db then
    -- vim.api.nvim_err_writeln 'Failed to open database'
    vim.api.nvim_echo({ string.format('Failed to open database %s', db_path) }, true, { err = true })
    return nil
  end

  local function trim_quotes(s)
    return (s:gsub('^([\'"])(.-)%1$', '%2'))
  end

  -- Use db:sql to execute a query and get results as a Lua table
  -- The plugin handles parsing the results
  -- local query = string.format('SELECT * FROM users WHERE id = %d', user_id)
  -- local query = string.format('SELECT * FROM id_encodedids WHERE encoded_idv1 = "%s" or encoded_idv2 = "%s"', encoded_id, encoded_id)
  print(string.format('looking for %s', encoded_id))

  local query = 'SELECT * FROM id_encodedids WHERE encoded_idv1 = :encoded_id or encoded_idv2 = :encoded_id'
  -- local query = 'SELECT coalesce(encoded_idv1, encoded_idv2) as found FROM id_encodedids WHERE encoded_idv1 = :encoded_id or encoded_idv2 = :encoded_id'
  local result = db:eval(query, { encoded_id = encoded_id })

  db:close() -- Close the database connection

  if type(result) == 'table' and #result > 0 then
    -- Assuming 'users' table has columns like 'id', 'name', 'email'
    -- if result and #result > 0 then
    -- Assuming 'users' table has columns like 'id', 'name', 'email'
    return result[1] -- Returns the first matching row
  else
    return nil -- No user found
  end
end

--- Lookup a user by encoded ID from the local SQLite database.
-- Usage: :LookupUserID [id]
-- If [id] is provided, it is used as the lookup key.
-- If no argument is given, the word under the cursor (<cWORD>) is used.
-- The found ID is saved to register "z" and the input is saved to register "y".
-- Prints a message with the result.
-- Example usage (e.g., mapped to a command)
-- "mZwjmdZwe1S5uhHMdR9CVGqv3gQS1lzvOAd_r_pYRdY" 1000000000
-- "1706b0559e4a8c8b7e1f486b590cbc5e8afef5d250a94c"
-- @param args table: User command arguments (optional, may contain .args as the ID string)

vim.api.nvim_create_user_command('LookupUserID', function(args)
  local id = (args and args.args) or '' -- args.args is the raw string of all args
  if not id or id == '' then
    -- Try cWORD
    id = tostring(vim.fn.expand '<cWORD>')
    print 'No user ID provided. Trying <cWORD>'
    if not id or id == '' then
      print 'No user ID found in <cWORD> either. Aborting.'
      return
    end
  end

  -- trim matching quotes
  local function trim_quotes(s)
    return (s:gsub('^([\'"/,])(.-)%1$', '%2'))
  end

  id = trim_quotes(id)

  -- trim leading/trailing characters
  local function trim_quotes_and_slashes(s)
    return (s:gsub('^[/"\',]+', ''):gsub('[/"\',]+$', ''))
  end

  id = trim_quotes_and_slashes(id)

  if id then
    vim.fn.setreg('y', tostring(id), 'c')
    local user = lookup_user_by_id('/home/bernie/Downloads-work/id_encodedids.db', id)
    -- local db = sqlite.open '/home/bernie/Downloads-work/id_encodedids.db'
    if user then
      -- print(string.format('Found user: ID: %s, Name: %s, Email: %s', user.id, user.name, user.email))
      vim.fn.setreg('z', tostring(user.id), 'c')
      print(string.format('Found user ID: %s (saved to "z)', user.id))
    else
      print(string.format('User with ID %s not found.', id))
    end
  else
    print 'Invalid user ID provided.'
  end
end, { nargs = '?', complete = 'expression' })

--[[ Neovide ]]
if vim.g.neovide then
  vim.keymap.set({ 'n', 'v' }, '<C-+>', ':lua vim.g.neovide_scale_factor = vim.g.neovide_scale_factor + 0.1<CR>')
  vim.keymap.set({ 'n', 'v' }, '<C-->', ':lua vim.g.neovide_scale_factor = vim.g.neovide_scale_factor - 0.1<CR>')
  vim.keymap.set({ 'n', 'v' }, '<C-0>', ':lua vim.g.neovide_scale_factor = 1<CR>') -- Reset to default
end

--- Generate a function annotation using Neogen for the function at or under the cursor.
--- This command uses the 'neogen' plugin to create documentation comments.
function CommentFunctionUnderCursor()
  require('neogen').generate { type = 'func' }
end

vim.api.nvim_create_user_command(
  'CommentFunction',
  CommentFunctionUnderCursor,
  { desc = 'Generate function annotation using Neogen for function under cursor' }
)

vim.api.nvim_create_user_command('BrowserSync', function()
  vim.fn.system "browser-sync start --server --files '*.html,*.xhtml,*.css,*.js'"
end, {})
