--[[

=====================================================================
==================== READ THIS BEFORE CONTINUING ====================
=====================================================================
========                                    .-----.          ========
========         .----------------------.   | === |          ========
========         |.-""""""""""""""""""-.|   |-----|          ========
========         ||                    ||   | === |          ========
========         ||   KICKSTART.NVIM   ||   |-----|          ========
========         ||                    ||   | === |          ========
========         ||                    ||   |-----|          ========
========         ||:Tutor              ||   |:::::|          ========
========         |'-..................-'|   |____o|          ========
========         `"")----------------(""`   ___________      ========
========        /::::::::::|  |::::::::::\  \ no mouse \     ========
========       /:::========|  |==hjkl==:::\  \ required \    ========
========      '""""""""""""'  '""""""""""""'  '""""""""""'   ========
========                                                     ========
=====================================================================
=====================================================================

What is Kickstart?

  Kickstart.nvim is *not* a distribution.

  Kickstart.nvim is a starting point for your own configuration.
    The goal is that you can read every line of code, top-to-bottom, understand
    what your configuration is doing, and modify it to suit your needs.

    Once you've done that, you can start exploring, configuring and tinkering to
    make Neovim your own! That might mean leaving Kickstart just the way it is for a while
    or immediately breaking it into modular pieces. It's up to you!

    If you don't know anything about Lua, I recommend taking some time to read through
    a guide. One possible example which will only take 10-15 minutes:
      - https://learnxinyminutes.com/docs/lua/

    After understanding a bit more about Lua, you can use `:help lua-guide` as a
    reference for how Neovim integrates Lua.
    - :help lua-guide
    - (or HTML version): https://neovim.io/doc/user/lua-guide.html

Kickstart Guide:

  TODO: The very first thing you should do is to run the command `:Tutor` in Neovim.

    If you don't know what this means, type the following:
      - <escape key>
      - :
      - Tutor
      - <enter key>

    (If you already know the Neovim basics, you can skip this step.)

  Once you've completed that, you can continue working through **AND READING** the rest
  of the kickstart init.lua.

  Next, run AND READ `:help`.
    This will open up a help window with some basic information
    about reading, navigating and searching the builtin help documentation.

    This should be the first place you go to look when you're stuck or confused
    with something. It's one of my favorite Neovim features.

    MOST IMPORTANTLY, we provide a keymap "<space>sh" to [s]earch the [h]elp documentation,
    which is very useful when you're not exactly sure of what you're looking for.

  I have left several `:help X` comments throughout the init.lua
    These are hints about where to find more information about the relevant settings,
    plugins or Neovim features used in Kickstart.

   NOTE: Look for lines like this

    Throughout the file. These are for you, the reader, to help you understand what is happening.
    Feel free to delete them once you know what you're doing, but they should serve as a guide
    for when you are first encountering a few different constructs in your Neovim config.

If you experience any errors while trying to install kickstart, run `:checkhealth` for more info.

I hope you enjoy your Neovim journey,
- TJ

P.S. You can delete this when you're done too. It's your config now! :)
--]]

-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- disable automatic conversion of emoji characters to full-width? Might resolve some issues with
-- emoji-icon-theme and cmp?
vim.g.emoji = 0
-- Set to true if you have a Nerd Font installed and selected in the terminal
vim.g.have_nerd_font = true

-- [[ Bernie's Setting Option to allow .nvimrc or .nvim.lua ]]
vim.opt.exrc = true

-- [[ Setting options ]]
-- See `:help vim.opt`
-- NOTE: You can change these options as you wish!
--  For more options, you can see `:help option-list`

-- Always too little too late
vim.opt.backup = true

-- Append backup files with timestamp
--https://toddknutson.bio/posts/how-to-enable-neovim-undo-backup-and-swap-files-when-switching-linux-groups/
vim.api.nvim_create_autocmd('BufWritePre', {
  callback = function()
    local extension = '~' .. vim.fn.strftime '%Y-%m-%d-%H%M%S'
    vim.o.backupext = extension
  end,
})

vim.api.nvim_create_autocmd({ 'WinEnter', 'BufEnter', 'WinResized' }, {
  callback = function()
    vim.o.scroll = math.floor(0.33 * vim.fn.winheight(0))
  end,
})

vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWinEnter' }, {
  pattern = { '*.json', '*.jsonc' },
  callback = function()
    vim.opt_local.foldmethod = 'indent'
    vim.opt_local.foldlevelstart = 3
  end,
})

if vim.fn.isdirectory(vim.env.HOME .. '/.backupdir') == 0 then
  -- vim.fn.mkdir(vim.env.HOME .. '/.backupdir')
  if vim.fn.mkdir(vim.env.HOME .. '/.backupdir') ~= true then
    print 'Could not create backupdir'
    vim.fn.mkdir(vim.fn.expand '~/tmp')
  end
end
vim.opt.backupdir = { vim.env.HOME .. '/.backupdir', vim.fn.expand '~/tmp', '/tmp/' }

vim.opt.backupskip = { '*.csv' }

-- Make line numbers default
vim.opt.number = true
-- You can also add relative line numbers, to help with jumping.
--  Experiment for yourself to see if you like it!
vim.opt.relativenumber = true

-- Enable mouse mode, can be useful for resizing splits for example!
vim.opt.mouse = 'a'

-- Don't show the mode, since it's already in the status line
vim.opt.showmode = false

-- Sync clipboard between OS and Neovim.
--  Schedule the setting after `UiEnter` because it can increase startup-time.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
vim.schedule(function()
  vim.opt.clipboard = 'unnamedplus'
end)

-- Enable break indent
vim.opt.breakindent = true

-- Save undo history
if vim.fn.isdirectory(vim.env.HOME .. '/.undodir') == 0 then
  if vim.fn.mkdir(vim.env.HOME .. '/.undodir') ~= true then
    print 'Could not create undodir'
    vim.fn.mkdir(vim.fn.expand '~/tmp/.undodir')
  end
end
vim.opt.undodir = vim.env.HOME .. '/.undodir'
vim.opt.undofile = true

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Keep signcolumn on by default
vim.opt.signcolumn = 'yes'

-- Decrease update time
vim.opt.updatetime = 250

-- Decrease mapped sequence wait time
-- Displays which-key popup sooner
vim.opt.timeoutlen = 300

-- Configure how new splits should be opened
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Sets how neovim will display certain whitespace characters in the editor.
--  See `:help 'list'`
--  and `:help 'listchars'`
vim.opt.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }
-- vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣', eol = '↲' }

-- Preview substitutions live, as you type!
vim.opt.inccommand = 'split'

-- Show which line your cursor is on
vim.opt.cursorline = true

-- Minimal number of screen lines to keep above and below the cursor.
-- vim.opt.scrolloff = 10
vim.opt.scrolloff = 6

-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`

-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Diagnostic keymaps
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- TIP: Disable arrow keys in normal mode
-- vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
-- vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
-- vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
-- vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--
--  See `:help wincmd` for a list of all window commands
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- terminal bindings - these seem to already be there
-- vim.keymap.set('t', '<C-h>', '<C-\\><C-N><C-w>h', { desc = 'Move focus to the left window' })
-- tmap <C-h> <C-\><C-N><C-h>
-- tmap <C-l> <C-\><C-N><C-l>
-- tmap <C-j> <C-\><C-N><C-j>
-- tmap <C-k> <C-\><C-N><C-k>

-- [[ Bernie's proto-macros ]]
vim.keymap.set('n', 'sasa', 'bhylep', { desc = 'Do search for wrapping character at beginning and past at end' })
vim.keymap.set('ca', 'evv', 'e ~/.vimrc.27Aug24', { desc = 'Edit .vimrc' })
-- original: 'rg --vimgrep -uu '
vim.cmd [[ set grepprg=rg\ --vimgrep\ --no-heading\ --smart-case\ -uu\ --search-zip\ ]]
-- Problems with typing these in command mode....
-- vim.keymap.set('c', 'Et', '<cmd>:bot split | term<CR>', { desc = 'Open [T]erminal Below' })
-- vim.keymap.set('c', 'Etv', '<cmd>:vert split | term<CR>', { desc = 'Open [T]erminal Vert' })

-- https://stackoverflow.com/questions/2921752/limiting-search-scope-for-code-in-vim
-- v i { <ESC> /\%Vsearch-term

-- [[ Bernie's buffer-scoped things ]]
--
-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.highlight.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- [[ Install `lazy.nvim` plugin manager ]]
--    See `:help lazy.nvim.txt` or https://github.com/folke/lazy.nvim for more info
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
  if vim.v.shell_error ~= 0 then
    error('Error cloning lazy.nvim:\n' .. out)
  end
end ---@diagnostic disable-next-line: undefined-field
vim.opt.rtp:prepend(lazypath)

-- [[ Configure and install plugins ]]
--
--  To check the current status of your plugins, run
--    :Lazy
--
--  You can press `?` in this menu for help. Use `:q` to close the window
--
--  To update plugins you can run
--    :Lazy update

-- Missing required fields in type \``LazyConfig\: `root`, `defaults`, `spec`, `local_spec`, `lockfile`, `git`, `pkg`, `rocks`, `dev`, `install`, `headless`, `diff`, `checker`, `change_detection`, `performance`, `readme`, `state`, `profiling`, `debug``
-- ---@diagnostic disable-next-line: missing-fields
require('lazy').setup {
  -- A bunch of new required fields
  -- root = {},
  -- defaults = {},
  -- spec = {},
  -- local_spec = {},
  -- lockfile = {},
  -- git = {},
  -- pkg = {},
  -- rocks = {},
  -- dev = {},
  -- install = {},
  -- headless = {},
  -- diff = {},
  -- checker = {},
  -- change_detection = {},
  -- performance = {},
  -- readme = {},
  -- state = {},
  -- profiling = {},
  debug = {},

  root = vim.fn.stdpath 'data' .. '/lazy', -- directory where plugins will be installed
  defaults = {
    -- Set this to `true` to have all your plugins lazy-loaded by default.
    -- Only do this if you know what you are doing, as it can lead to unexpected behavior.
    lazy = false, -- should plugins be lazy-loaded?
    -- It's recommended to leave version=false for now, since a lot the plugin that support versioning,
    -- have outdated releases, which may break your Neovim install.
    version = nil, -- always use the latest git commit
    -- version = "*", -- try installing the latest stable version for plugins that support semver
    -- default `cond` you can use to globally disable a lot of plugins
    -- when running inside vscode for example
    cond = nil, ---@type boolean|fun(self:LazyPlugin):boolean|nil
  },
  -- leave nil when passing the spec as the first argument to setup()
  spec = nil, ---@type LazySpec
  local_spec = true, -- load project specific .lazy.lua spec files. They will be added at the end of the spec.
  lockfile = vim.fn.stdpath 'config' .. '/lazy-lock.json', -- lockfile generated after running update.
  ---@type number? limit the maximum amount of concurrent tasks
  concurrency = jit.os:find 'Windows' and (vim.uv.available_parallelism() * 2) or nil,
  git = {
    -- defaults for the `Lazy log` command
    -- log = { "--since=3 days ago" }, -- show commits from the last 3 days
    log = { '-8' }, -- show the last 8 commits
    timeout = 120, -- kill processes that take more than 2 minutes
    url_format = 'https://github.com/%s.git',
    -- lazy.nvim requires git >=2.19.0. If you really want to use lazy with an older version,
    -- then set the below to false. This should work, but is NOT supported and will
    -- increase downloads a lot.
    filter = true,
    -- rate of network related git operations (clone, fetch, checkout)
    throttle = {
      enabled = false, -- not enabled by default
      -- max 2 ops every 5 seconds
      rate = 2,
      duration = 5 * 1000, -- in ms
    },
    -- Time in seconds to wait before running fetch again for a plugin.
    -- Repeated update/check operations will not run again until this
    -- cooldown period has passed.
    cooldown = 0,
  },
  pkg = {
    enabled = true,
    cache = vim.fn.stdpath 'state' .. '/lazy/pkg-cache.lua',
    -- the first package source that is found for a plugin will be used.
    sources = {
      'lazy',
      'rockspec', -- will only be used when rocks.enabled is true
      'packspec',
    },
  },
  rocks = {
    enabled = true,
    root = vim.fn.stdpath 'data' .. '/lazy-rocks',
    server = 'https://nvim-neorocks.github.io/rocks-binaries/',
    -- use hererocks to install luarocks?
    -- set to `nil` to use hererocks when luarocks is not found
    -- set to `true` to always use hererocks
    -- set to `false` to always use luarocks
    hererocks = nil,
  },
  dev = {
    -- Directory where you store your local plugin projects. If a function is used,
    -- the plugin directory (e.g. `~/projects/plugin-name`) must be returned.
    ---@type string | fun(plugin: LazyPlugin): string
    path = '~/projects',
    ---@type string[] plugins that match these patterns will use your local versions instead of being fetched from GitHub
    patterns = {}, -- For example {"folke"}
    fallback = false, -- Fallback to git when local plugin doesn't exist
  },
  install = {
    -- install missing plugins on startup. This doesn't increase startup time.
    missing = true,
    -- try to load one of these colorschemes when starting an installation during startup
    colorscheme = { 'habamax' },
  },
  ui = {
    -- a number <1 is a percentage., >1 is a fixed size
    size = { width = 0.8, height = 0.8 },
    wrap = true, -- wrap the lines in the ui
    -- The border to use for the UI window. Accepts same border values as |nvim_open_win()|.
    border = 'none',
    -- The backdrop opacity. 0 is fully opaque, 100 is fully transparent.
    backdrop = 60,
    title = nil, ---@type string only works when border is not "none"
    title_pos = 'center', ---@type "center" | "left" | "right"
    -- Show pills on top of the Lazy window
    pills = true, ---@type boolean
    icons = {
      cmd = ' ',
      config = '',
      event = ' ',
      favorite = ' ',
      ft = ' ',
      init = ' ',
      import = ' ',
      keys = ' ',
      lazy = '󰒲 ',
      loaded = '●',
      not_loaded = '○',
      plugin = ' ',
      runtime = ' ',
      require = '󰢱 ',
      source = ' ',
      start = ' ',
      task = '✔ ',
      list = {
        '●',
        '➜',
        '★',
        '‒',
      },
    },
    -- leave nil, to automatically select a browser depending on your OS.
    -- If you want to use a specific browser, you can define it here
    browser = nil, ---@type string?
    throttle = 1000 / 30, -- how frequently should the ui process render events
    custom_keys = {
      -- You can define custom key maps here. If present, the description will
      -- be shown in the help menu.
      -- To disable one of the defaults, set it to false.

      ['<localleader>l'] = {
        function(plugin)
          require('lazy.util').float_term({ 'lazygit', 'log' }, {
            cwd = plugin.dir,
          })
        end,
        desc = 'Open lazygit log',
      },

      ['<localleader>i'] = {
        function(plugin)
          Util.notify(vim.inspect(plugin), {
            title = 'Inspect ' .. plugin.name,
            lang = 'lua',
          })
        end,
        desc = 'Inspect Plugin',
      },

      ['<localleader>t'] = {
        function(plugin)
          require('lazy.util').float_term(nil, {
            cwd = plugin.dir,
          })
        end,
        desc = 'Open terminal in plugin dir',
      },
    },
  },
  -- Output options for headless mode
  headless = {
    -- show the output from process commands like git
    process = true,
    -- show log messages
    log = true,
    -- show task start/end
    task = true,
    -- use ansi colors
    colors = true,
  },
  diff = {
    -- diff command <d> can be one of:
    -- * browser: opens the github compare view. Note that this is always mapped to <K> as well,
    --   so you can have a different command for diff <d>
    -- * git: will run git diff and open a buffer with filetype git
    -- * terminal_git: will open a pseudo terminal with git diff
    -- * diffview.nvim: will open Diffview to show the diff
    cmd = 'git',
  },
  checker = {
    -- automatically check for plugin updates
    enabled = false,
    concurrency = nil, ---@type number? set to 1 to check for updates very slowly
    notify = true, -- get a notification when new updates are found
    frequency = 3600, -- check for updates every hour
    check_pinned = false, -- check for pinned packages that can't be updated
  },
  change_detection = {
    -- automatically check for config file changes and reload the ui
    enabled = true,
    notify = true, -- get a notification when changes are found
  },
  performance = {
    cache = {
      enabled = true,
    },
    reset_packpath = true, -- reset the package path to improve startup time
    rtp = {
      reset = true, -- reset the runtime path to $VIMRUNTIME and your config directory
      ---@type string[]
      paths = {}, -- add any custom paths here that you want to includes in the rtp
      ---@type string[] list any plugins you want to disable here
      disabled_plugins = {
        -- "gzip",
        -- "matchit",
        -- "matchparen",
        -- "netrwPlugin",
        -- "tarPlugin",
        -- "tohtml",
        -- "tutor",
        -- "zipPlugin",
      },
    },
  },
  -- lazy can generate helptags from the headings in markdown readme files,
  -- so :help works even for plugins that don't have vim docs.
  -- when the readme opens with :help it will be correctly displayed as markdown
  readme = {
    enabled = true,
    root = vim.fn.stdpath 'state' .. '/lazy/readme',
    files = { 'README.md', 'lua/**/README.md' },
    -- only generate markdown helptags for plugins that don't have docs
    skip_if_doc_exists = true,
  },
  state = vim.fn.stdpath 'state' .. '/lazy/state.json', -- state info for checker and other things
  -- Enable profiling of lazy.nvim. This will add some overhead,
  -- so only enable this when you are debugging lazy.nvim
  profiling = {
    -- Enables extra stats on the debug tab related to the loader cache.
    -- Additionally gathers stats about all package.loaders
    loader = false,
    -- Track each new require in the Lazy profiling tab
    require = false,
  },

  -- NOTE: Plugins can be added with a link (or for a github repo: 'owner/repo' link).
  'tpope/vim-sleuth', -- Detect tabstop and shiftwidth automatically

  -- NOTE: Plugins can also be added by using a table,
  -- with the first argument being the link and the following
  -- keys can be used to configure plugin behavior/loading/etc.
  --
  -- Use `opts = {}` to force a plugin to be loaded.
  --

  -- Here is a more advanced example where we pass configuration
  -- options to `gitsigns.nvim`. This is equivalent to the following Lua:
  --    require('gitsigns').setup({ ... })
  --
  -- See `:help gitsigns` to understand what the configuration keys do
  { -- Adds git related signs to the gutter, as well as utilities for managing changes
    'lewis6991/gitsigns.nvim',
    opts = {
      signs = {
        add = { text = '+' },
        change = { text = '~' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
        untracked = { text = '┆' },
      },
    },
  },

  -- NOTE: Plugins can also be configured to run Lua code when they are loaded.
  --
  -- This is often very useful to both group configuration, as well as handle
  -- lazy loading plugins that don't need to be loaded immediately at startup.
  --
  -- For example, in the following configuration, we use:
  --  event = 'VimEnter'
  --
  -- which loads which-key before all the UI elements are loaded. Events can be
  -- normal autocommands events (`:help autocmd-events`).
  --
  -- Then, because we use the `config` key, the configuration only runs
  -- after the plugin has been loaded:
  --  config = function() ... end

  { -- Useful plugin to show you pending keybinds.
    'folke/which-key.nvim',
    event = 'VimEnter', -- Sets the loading event to 'VimEnter'
    opts = {
      icons = {
        -- set icon mappings to true if you have a Nerd Font
        mappings = vim.g.have_nerd_font,
        -- If you are using a Nerd Font: set icons.keys to an empty table which will use the
        -- default whick-key.nvim defined Nerd Font icons, otherwise define a string table
        keys = vim.g.have_nerd_font and {} or {
          Up = '<Up> ',
          Down = '<Down> ',
          Left = '<Left> ',
          Right = '<Right> ',
          C = '<C-…> ',
          M = '<M-…> ',
          D = '<D-…> ',
          S = '<S-…> ',
          CR = '<CR> ',
          Esc = '<Esc> ',
          ScrollWheelDown = '<ScrollWheelDown> ',
          ScrollWheelUp = '<ScrollWheelUp> ',
          NL = '<NL> ',
          BS = '<BS> ',
          Space = '<Space> ',
          Tab = '<Tab> ',
          F1 = '<F1>',
          F2 = '<F2>',
          F3 = '<F3>',
          F4 = '<F4>',
          F5 = '<F5>',
          F6 = '<F6>',
          F7 = '<F7>',
          F8 = '<F8>',
          F9 = '<F9>',
          F10 = '<F10>',
          F11 = '<F11>',
          F12 = '<F12>',
        },
      },

      -- Document existing key chains
      spec = {
        { '<leader>c', group = '[C]ode', mode = { 'n', 'x' } },
        { '<leader>d', group = '[D]ocument' },
        { '<leader>r', group = '[R]ename' },
        { '<leader>s', group = '[S]earch' },
        { '<leader>w', group = '[W]orkspace' },
        { '<leader>t', group = '[T]oggle' },
        { '<leader>g', group = '[G]it' },
        { '<leader>y', group = '[Y]ours' },
        { '<leader>f', group = '[F]ile or [F]zf' },
        { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } },
      },
    },
    -- See `:help which-key` for more information
    keys = {
      {
        '<leader>?',
        function()
          require('which-key').show { global = false }
        end,
        desc = 'Buffer Local Keymaps (which-key)',
      },
    },
  },

  -- NOTE: Plugins can specify dependencies.
  --
  -- The dependencies are proper plugin specifications as well - anything
  -- you do for a plugin at the top level, you can do for a dependency.
  --
  -- Use the `dependencies` key to specify the dependencies of a particular plugin

  { -- Fuzzy Finder (files, lsp, etc)
    'nvim-telescope/telescope.nvim',
    event = 'VimEnter',
    branch = '0.1.x',
    dependencies = {
      'nvim-lua/plenary.nvim',
      { -- If encountering errors, see telescope-fzf-native README for installation instructions
        'nvim-telescope/telescope-fzf-native.nvim',

        -- `build` is used to run some command when the plugin is installed/updated.
        -- This is only run then, not every time Neovim starts up.
        build = 'make',

        -- `cond` is a condition used to determine whether this plugin should be
        -- installed and loaded.
        cond = function()
          return vim.fn.executable 'make' == 1
        end,
      },
      { 'nvim-telescope/telescope-ui-select.nvim' },

      -- Useful for getting pretty icons, but requires a Nerd Font.
      { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },

      -- live-grep-args
      {
        'nvim-telescope/telescope-live-grep-args.nvim',

        -- This will not install any breaking changes.
        -- For major updates, this must be adjusted manually.
        version = '^1.0.0',
      },
    },
    config = function()
      -- Telescope is a fuzzy finder that comes with a lot of different things that
      -- it can fuzzy find! It's more than just a "file finder", it can search
      -- many different aspects of Neovim, your workspace, LSP, and more!
      --
      -- The easiest way to use Telescope, is to start by doing something like:
      --  :Telescope help_tags
      --
      -- After running this command, a window will open up and you're able to
      -- type in the prompt window. You'll see a list of `help_tags` options and
      -- a corresponding preview of the help.
      --
      -- Two important keymaps to use while in Telescope are:
      --  - Insert mode: <c-/>
      --  - Normal mode: ?
      --
      -- This opens a window that shows you all of the keymaps for the current
      -- Telescope picker. This is really useful to discover what Telescope can
      -- do as well as how to actually do it!

      -- [[ Configure Telescope ]]
      -- See `:help telescope` and `:help telescope.setup()`
      require('telescope').setup {
        -- You can put your default mappings / updates / etc. in here
        --  All the info you're looking for is in `:help telescope.setup()`
        --
        -- defaults = {
        --   mappings = {
        --     i = { ['<c-enter>'] = 'to_fuzzy_refine' },
        --   },
        -- },
        -- pickers = {}
        extensions = {
          ['ui-select'] = {
            require('telescope.themes').get_dropdown(),
          },
        },
      }

      -- Enable Telescope extensions if they are installed
      pcall(require('telescope').load_extension, 'fzf')
      pcall(require('telescope').load_extension, 'ui-select')
      pcall(require('telescope').load_extension, 'live_grep_args')
      pcall(require('telescope').load_extension, 'media_files')
      -- pcall(require('telescope').load_extension, 'emoji')

      -- See `:help telescope.builtin`
      local builtin = require 'telescope.builtin'
      vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
      vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
      vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
      -- A bad idea because C-p is used so much
      -- vim.keymap.set('n', '<leader>cp', builtin.find_files, { desc = '[S]earch [F]iles' })
      vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
      -- vim.keymap.set('n', '<leader>sc', builtin.current_buffer_tags, { desc = '[S]earch [C]urrent Buffer Tags' })
      vim.keymap.set('n', '<leader>sc', builtin.lsp_document_symbols, { desc = '[S]earch [C]urrent Buffer Tags (lsp_document_symbols)' })
      vim.keymap.set('n', '<leader>sm', builtin.man_pages, { desc = '[S]earch [M]an pages' })
      vim.keymap.set('n', '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
      vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
      vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
      vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })

      -- vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
      vim.keymap.set('n', '<leader>s.', function()
        builtin.oldfiles { only_cwd = true, prompt_title = 'Cwd: Recent Files' }
      end, { desc = '[S]earch Recent Files ("." for repeat)' })

      vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })

      -- Some additional Telescope keymaps I like to preserve for muscle memory
      vim.keymap.set('n', '<leader>gb', builtin.git_branches, { desc = '[G]it [B]ranches' })
      vim.keymap.set('n', '<leader>gs', builtin.git_status, { desc = '[G]it [S]tatus' })
      -- vim.keymap.set('n', '<leader>yb', builtin.buffers, { desc = '[Y]o Find existing buffers', silent = false })
      vim.keymap.set('n', '<leader>yg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
      vim.keymap.set('n', '<leader>yh', builtin.command_history, { desc = '[S]earch [C]command [H]istory' })
      vim.keymap.set('n', '<leader>s:', builtin.command_history, { desc = '[S]earch [:]Command [H]istory' })
      --vim.keymap.set('n', '<leader>yo', builtin.current_buffer_tags, { desc = '[Y]o [O]utline (Buffer Tags)' })
      vim.keymap.set('n', '<leader>yo', builtin.lsp_document_symbols, { desc = '[Y]o [O]utline (lsp_document_symbols)' })
      -- I would like to make '<leader>ys' in lua but I don't know how to make the prompt stay open.
      vim.keymap.set('n', '<leader>ys', ':Telescope find_files hidden=true no_ignore=true search_dirs=~', { desc = '[Y]o [S]earch search_dirs=~' })
      vim.keymap.set('n', '<A-p>', function()
        builtin.find_files { prompt_title = '[F]ind [F]iles (hidden, no_ignore)', hidden = true, no_ignore = true, follow = true }
      end, {})
      -- C-p habit. Sometimes removing <C-p> because neo-tree uses it as regular up/down; but j/k works fine.
      vim.keymap.set('n', '<C-p>', builtin.find_files, { desc = '[S]earch [F]iles (use <leader>sf)' })
      --[[ vim.keymap.set('n', '<leader>yy', function()
        builtin.find_files { prompt_title = 'F[Y]nd [Y]er Files (hidden, noignore)', hidden = true, no_ignore = true }
      end, {}) ]]

      vim.keymap.set('n', '<leader>gc', function()
        builtin.git_bcommits {
          prompt_title = '[G]it Buffer [c]ommits',
        }
      end, { desc = '[G]it [B]uffer [c]ommits' })

      vim.keymap.set('n', '<leader>gC', function()
        builtin.git_commits {
          prompt_title = '[G]it Directory [C]ommits',
        }
      end, { desc = '[G]it Directory [C]ommits' })

      -- Slightly advanced example of overriding default behavior and theme
      vim.keymap.set('n', '<leader>/', function()
        -- You can pass additional configuration to Telescope to change the theme, layout, etc.
        builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
          winblend = 10,
          previewer = false,
        })
      end, { desc = '[/] Fuzzily search in current buffer' })

      -- It's also possible to pass additional configuration options.
      --  See `:help telescope.builtin.live_grep()` for information about particular keys
      vim.keymap.set('n', '<leader>s/', function()
        builtin.live_grep {
          grep_open_files = true,
          prompt_title = 'Live Grep in Open Files',
        }
      end, { desc = '[S]earch [/] in Open Files' })

      -- Shortcut for searching your Neovim configuration files
      vim.keymap.set('n', '<leader>sn', function()
        builtin.find_files { cwd = vim.fn.stdpath 'config' }
      end, { desc = '[S]earch [N]eovim files' })
    end,
  },

  -- LSP Plugins
  {
    -- `lazydev` configures Lua LSP for your Neovim config, runtime and plugins
    -- used for completion, annotations and signatures of Neovim apis
    'folke/lazydev.nvim',
    ft = 'lua',
    opts = {
      library = {
        -- Load luvit types when the `vim.uv` word is found
        { path = 'luvit-meta/library', words = { 'vim%.uv' } },
      },
    },
  },
  { 'Bilal2453/luvit-meta', lazy = true },
  {
    -- Main LSP Configuration
    'neovim/nvim-lspconfig',
    dependencies = {
      -- Automatically install LSPs and related tools to stdpath for Neovim
      { 'williamboman/mason.nvim', config = true }, -- NOTE: Must be loaded before dependants
      'williamboman/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',

      -- Useful status updates for LSP.
      -- NOTE: `opts = {}` is the same as calling `require('fidget').setup({})`
      { 'j-hui/fidget.nvim', opts = {} },

      -- Allows extra capabilities provided by nvim-cmp
      'hrsh7th/cmp-nvim-lsp',
    },
    config = function()
      -- Brief aside: **What is LSP?**
      --
      -- LSP is an initialism you've probably heard, but might not understand what it is.
      --
      -- LSP stands for Language Server Protocol. It's a protocol that helps editors
      -- and language tooling communicate in a standardized fashion.
      --
      -- In general, you have a "server" which is some tool built to understand a particular
      -- language (such as `gopls`, `lua_ls`, `rust_analyzer`, etc.). These Language Servers
      -- (sometimes called LSP servers, but that's kind of like ATM Machine) are standalone
      -- processes that communicate with some "client" - in this case, Neovim!
      --
      -- LSP provides Neovim with features like:
      --  - Go to definition
      --  - Find references
      --  - Autocompletion
      --  - Symbol Search
      --  - and more!
      --
      -- Thus, Language Servers are external tools that must be installed separately from
      -- Neovim. This is where `mason` and related plugins come into play.
      --
      -- If you're wondering about lsp vs treesitter, you can check out the wonderfully
      -- and elegantly composed help section, `:help lsp-vs-treesitter`

      --  This function gets run when an LSP attaches to a particular buffer.
      --    That is to say, every time a new file is opened that is associated with
      --    an lsp (for example, opening `main.rs` is associated with `rust_analyzer`) this
      --    function will be executed to configure the current buffer
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
        callback = function(event)
          -- NOTE: Remember that Lua is a real programming language, and as such it is possible
          -- to define small helper and utility functions so you don't have to repeat yourself.
          --
          -- In this case, we create a function that lets us more easily define mappings specific
          -- for LSP related items. It sets the mode, buffer and description for us each time.
          local map = function(keys, func, desc, mode)
            mode = mode or 'n'
            vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
          end

          -- Jump to the definition of the word under your cursor.
          --  This is where a variable was first declared, or where a function is defined, etc.
          --  To jump back, press <C-t>.
          map('gd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')
          -- map('gV', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition', { 'v' })

          map('gV', '<cmd>vertical wincmd ]<cr>', '[G]oto Definition [V]ertical Split')

          -- Find references for the word under your cursor.
          map('gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')

          -- Jump to the implementation of the word under your cursor.
          --  Useful when your language has ways of declaring types without an actual implementation.
          map('gI', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')

          -- Jump to the type of the word under your cursor.
          --  Useful when you're not sure what type a variable is and you want to see
          --  the definition of its *type*, not where it was *defined*.
          map('<leader>D', require('telescope.builtin').lsp_type_definitions, 'Type [D]efinition')

          -- Fuzzy find all the symbols in your current document.
          --  Symbols are things like variables, functions, types, etc.
          map('<leader>ds', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')

          -- Fuzzy find all the symbols in your current workspace.
          --  Similar to document symbols, except searches over your entire project.
          map('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')

          -- Rename the variable under your cursor.
          --  Most Language Servers support renaming across files, etc.
          map('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')

          -- Execute a code action, usually your cursor needs to be on top of an error
          -- or a suggestion from your LSP for this to activate.
          map('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction', { 'n', 'x' })

          -- WARN: This is not Goto Definition, this is Goto Declaration.
          --  For example, in C this would take you to the header.
          map('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

          -- The following two autocommands are used to highlight references of the
          -- word under your cursor when your cursor rests there for a little while.
          --    See `:help CursorHold` for information about when this is executed
          --
          -- When you move your cursor, the highlights will be cleared (the second autocommand).
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
            local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
            vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.document_highlight,
            })

            vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.clear_references,
            })

            vim.api.nvim_create_autocmd('LspDetach', {
              group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
              callback = function(event2)
                vim.lsp.buf.clear_references()
                vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
              end,
            })
          end

          -- The following code creates a keymap to toggle inlay hints in your
          -- code, if the language server you are using supports them
          --
          -- This may be unwanted, since they displace some of your code
          if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
            map('<leader>th', function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
            end, '[T]oggle Inlay [H]ints')
          end
        end,
      })

      -- LSP servers and clients are able to communicate to each other what features they support.
      --  By default, Neovim doesn't support everything that is in the LSP specification.
      --  When you add nvim-cmp, luasnip, etc. Neovim now has *more* capabilities.
      --  So, we create new capabilities with nvim cmp, and then broadcast that to the servers.
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities = vim.tbl_deep_extend('force', capabilities, require('cmp_nvim_lsp').default_capabilities())

      -- Enable the following language servers
      --  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
      --
      --  Add any additional override configuration in the following tables. Available keys are:
      --  - cmd (table): Override the default command used to start the server
      --  - filetypes (table): Override the default list of associated filetypes for the server
      --  - capabilities (table): Override fields in capabilities. Can be used to disable certain LSP features.
      --  - settings (table): Override the default settings passed when initializing the server.
      --        For example, to see the options for `lua_ls`, you could go to: https://luals.github.io/wiki/settings/
      local servers = {
        clangd = {},
        -- gopls = {},
        -- pyright = {},
        -- rust_analyzer = {},
        -- ... etc. See `:help lspconfig-all` for a list of all the pre-configured LSPs
        --
        -- Some languages (like typescript) have entire language plugins that can be useful:
        --    https://github.com/pmizio/typescript-tools.nvim
        --
        -- But for many setups, the LSP (`tsserver`) will work just fine
        -- tsserver = {},
        intelephense = { -- FIXME: No idea whether this is working or can work.
          capabilities = capabilities,
          config = function()
            -- print 'i am here'
          end,
          init_options = {},
          settings = {
            intelephense = {
              environment = {
                phpVersion = '8.3.0', -- default 8.3.0, semver
                -- includePaths = { 'app', 'vendor/mailchimp', 'vendor/laravel', },
              },
              format = {
                enable = true, -- default, but JIC
              },
              client = {
                autoCloseDocCommentDoSuggest = true,
                -- diagnosticsIgnoreErrorFeature = true, -- not a real setting, from coc-intelephense
              },
              files = {
                maxSize = 16000000,
                associations = {
                  '*.blade.php',
                  '*.php',
                  '*.phtml',
                  '*.ctp',
                },
              },
              stubs = {
                '_ide_helper.php',
                '_ide_helper_models',
                -- {{{
                'bcmath',
                'bz2',
                'calendar',
                'Core',
                'ctype',
                'curl',
                'date',
                'dba',
                'dom',
                'enchant',
                'exif',
                'FFI',
                'fileinfo',
                'filter',
                'ftp',
                'gd',
                'gettext',
                'gmp',
                'hash',
                'iconv',
                'igbinary',
                'imagick',
                'imap',
                'intl',
                'json',
                'ldap',
                'libxml',
                'mbstring',
                'memcached',
                'msgpack',
                'mysqli',
                'mysqlnd',
                'oci8',
                'odbc',
                'openssl',
                'pcntl',
                'pcre',
                'PDO',
                'PDO_ODBC',
                'pdo_dblib',
                'pdo_mysql',
                'pdo_pgsql',
                'pdo_snowflake',
                'pdo_sqlite',
                'pgsql',
                'Phar',
                'posix',
                'pspell',
                'random',
                'readline',
                'recode',
                'redis',
                'Reflection',
                'session',
                'shmop',
                'SimpleXML',
                'snmp',
                'soap',
                'sockets',
                'sodium',
                'SPL',
                'sqlite3',
                'standard',
                'sysvmsg',
                'sysvsem',
                'sysvshm',
                'tidy',
                'tokenizer',
                'xdebug',
                'xml',
                'xmlreader',
                'xmlrpc',
                'xmlwriter',
                'xsl',
                'yaml',
                'Zend OPcache',
                'zip',
                'zlib',
                -- }}}
              },
              phpdoc = {
                propertyTemplate = {
                  summary = '${SYMBOL_NAME} - ${SYMBOL_TYPE}',
                  description = '',
                  tags = {
                    '@property ${SYMBOL_TYPE} ${SYMBOL_NAME}',
                  },
                },
                functionTemplate = {
                  summary = '${SYMBOL_NAME}() - ${SYMBOL_TYPE}',
                  description = '',
                  tags = {
                    '@param ${SYMBOL_TYPE} ${SYMBOL_NAMESPACE} ${SYMBOL_NAME}',
                    '@return ${SYMBOL_TYPE} ${SYMBOL_NAME}',
                  },
                },
                classTemplate = {
                  description = '${SYMBOL_TYPE} Class description',
                  summary = '',
                  tags = {
                    '@package ${SYMBOL_NAME}',
                    '@author',
                    '@version',
                    '@access public',
                    '@see',
                  },
                },
                varTemplate = { -- this does not exist, but would be nice if it did
                  tags = {
                    '@var ${SYMBOL_TYPE} ${SYMBOL_NAME}',
                  },
                },
              },
              -- root_dir = require('lspconfig').util.root_pattern('composer.json', '.git', 'package.json'),
            },
          },
          -- root_dir = function() return vim.loop.cwd() end,
          -- root_dir = function() return vim.loop.cwd() end,
        },

        lua_ls = {
          -- cmd = {...},
          -- filetypes = { ...},
          -- capabilities = {},
          settings = {
            Lua = {
              completion = {
                callSnippet = 'Replace',
              },
              -- You can toggle below to ignore Lua_LS's noisy `missing-fields` warnings
              -- diagnostics = { disable = { 'missing-fields' } },
            },
          },
        },
      }

      -- Ensure the servers and tools above are installed
      --  To check the current status of installed tools and/or manually install
      --  other tools, you can run
      --    :Mason
      --
      --  You can press `g?` for help in this menu.
      require('mason').setup()

      -- You can add other tools here that you want Mason to install
      -- for you, so that they are available from within Neovim.
      local ensure_installed = vim.tbl_keys(servers or {})
      vim.list_extend(ensure_installed, {
        'stylua', -- Used to format Lua code
        -- 'intelephense',
        -- 'bash',
        'bashls',
      })
      require('mason-tool-installer').setup { ensure_installed = ensure_installed }

      -- See https://github.com/williamboman/mason-lspconfig.nvim
      require('mason-lspconfig').setup {
        --@type string[]
        ensure_installed = {}, -- added in 4feb2025 to quiet the diagnostic
        --@type boolean
        automatic_installation = false, -- added in 4feb2025 to quiet the diagnostic
        handlers = {
          function(server_name)
            local server = servers[server_name] or {}
            -- This handles overriding only values explicitly passed
            -- by the server configuration above. Useful when disabling
            -- certain features of an LSP (for example, turning off formatting for tsserver)

            -- print('server_name: ' .. server_name)
            server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
            -- return require('lspconfig')[server_name].setup(server)
            require('lspconfig')[server_name].setup(server)
          end,
        },
      }
    end,
  },

  { -- Autoformat
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    keys = {
      {
        '<leader>yf',
        --'<leader>f',
        function()
          require('conform').format { async = true, lsp_format = 'fallback', lsp_fallback = true, timeout_ms = 500 }
        end,
        mode = '',
        desc = '[F]ormat buffer',
      },
    },
    opts = {
      notify_on_error = false,
      format_on_save = function(bufnr)
        -- Disable "format_on_save lsp_fallback" for languages that don't
        -- have a well standardized coding style. You can add additional
        -- languages here or re-enable it for the disabled ones.
        -- I don't want to save on php because I will lose easy Git blame
        -- results on all files. Otherwise I would.
        -- FIXME Disable this only on the loanconnect project.
        local disable_filetypes = { c = true, cpp = true, php = false, javascript = true }
        local lsp_format_opt
        if disable_filetypes[vim.bo[bufnr].filetype] then
          lsp_format_opt = 'never'
        else
          lsp_format_opt = 'fallback'
        end
        return {
          timeout_ms = 500,
          lsp_format = lsp_format_opt,
        }
      end,
      formatters_by_ft = {
        lua = { 'stylua' },
        -- Conform can also run multiple formatters sequentially
        -- python = { "isort", "black" },
        --
        -- You can use 'stop_after_first' to run the first available formatter from the list
        javascript = { 'prettierd', 'prettier', stop_after_first = true },
        -- I added below then removed as did not seem to help
        --php = { 'pint', 'php-cs-fixer', stop_after_first = false },
        --php = { 'pint', 'php-cs-fixer', 'phpcbf', stop_after_first = false },
        --php = { 'php-cs-fixer', 'pint', 'phpcbf', stop_after_first = true },
        blade = { 'blade-formatter' },
        markdown = { 'cbfmt', 'markdown-toc', 'markdownlint', stop_after_first = false },
        sql = { 'sqlfmt' },
        -- yaml = { 'ymlfmt', stop_after_first = false },
      },
      formatters = {
        ['php-cs-fixer'] = {
          command = 'php-cs-fixer',
          args = {
            'fix',
            '--rules=@PSR12', -- other presets availabled
            '$FILENAME',
          },
          stdin = false,
        },
      },
    },
  },

  { -- Autocompletion
    'hrsh7th/nvim-cmp',
    -- event = 'InsertEnter',
    event = { 'InsertEnter', 'TextChanged' },
    dependencies = {
      -- Snippet Engine & its associated nvim-cmp source
      {
        'L3MON4D3/LuaSnip',
        build = (function()
          -- Build Step is needed for regex support in snippets.
          -- This step is not supported in many windows environments.
          -- Remove the below condition to re-enable on windows.
          -- if vim.fn.has 'win32' == 1 or vim.fn.executable 'make' == 0 then
          --   return
          -- end
          return 'make install_jsregexp'
        end)(),
        dependencies = {
          -- `friendly-snippets` contains a variety of premade snippets.
          --    See the README about individual language/framework/plugin snippets:
          --    https://github.com/rafamadriz/friendly-snippets
          'rafamadriz/friendly-snippets',
          config = function()
            require('luasnip.loaders.from_vscode').lazy_load()
            -- See https://github.com/ianchesal/dotfiles/commit/2e81e58f6958efcce20ed2398d481e338669ff00
            -- NOTE: I cannot define my own snippets. Not sure why. Duplicated config for now.
            -- require('luasnip.loaders.from_vscode').lazy_load { paths = vim.fn.stdpath 'config' .. 'lua/snippets/' }
            require('luasnip.loaders.from_vscode').lazy_load { paths = vim.fn.stdpath 'config' .. '/lua/snippets/' }
          end,
        },
      },

      -- Adds other completion capabilities.
      --  nvim-cmp does not ship with all sources by default. They are split
      --  into multiple repos for maintenance purposes.
      'saadparwaiz1/cmp_luasnip',
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-buffer', -- source for text in buffer
      'hrsh7th/cmp-path',
      -- 'FelipeLema/cmp-async-path',
      -- 'hrsh7th/cmp-cmdline',
      'hrsh7th/cmp-omni',
    },
    config = function()
      -- See `:help cmp` 2025-02-06 18:57 57
      local cmp = require 'cmp'
      local luasnip = require 'luasnip'
      require('luasnip.loaders.from_vscode').lazy_load()
      -- See https://github.com/ianchesal/dotfiles/commit/2e81e58f6958efcce20ed2398d481e338669ff00
      -- NOTE: I cannot define my own snippets. Not sure why. Duplicated config for now.
      -- require('luasnip.loaders.from_vscode').lazy_load { paths = vim.fn.stdpath 'config' .. '/snippets/' }
      -- require('luasnip.loaders.from_vscode').lazy_load { paths = vim.fn.stdpath 'config' .. '/lua/snippets/' }
      -- luasnip.config.setup {}

      cmp.setup {
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        -- https://github.com/CopilotC-Nvim/CopilotChat.nvim?tab=readme-ov-file
        -- If you are on neovim < 0.11.0, you also might want to add noinsert and popup to your completeopt to make the chat completion behave well.
        completion = { 'InsertEnter,TextChanged', completeopt = 'menu,menuone,noinsert,noselect,popup' },
        -- completion = { 'InsertEnter,TextChanged', completeopt = 'menu,menuone,noinsert,noselect' },
        -- completion = { completeopt = 'menu,menuone,popup,preview,noinsert,noselect' },
        -- completion = { completeopt = 'menu,menuone,noinsert' },

        -- For an understanding of why these mappings were
        -- chosen, you will need to read `:help ins-completion`
        --
        -- No, but seriously. Please read `:help ins-completion`, it is really good!
        -- print 'I am just about to start cmp.mapping....',
        mapping = cmp.mapping.preset.insert {
          -- Select the [n]ext item
          ['<C-n>'] = cmp.mapping.select_next_item { behavior = cmp.SelectBehavior.Select },
          -- Select the [p]revious item
          ['<C-p>'] = cmp.mapping.select_prev_item { behavior = cmp.SelectBehavior.Select },

          -- Scroll the documentation window [b]ack / [f]orward
          ['<C-b>'] = cmp.mapping.scroll_docs(-5),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),

          --  This will auto-import if your LSP supports it.
          --  This will expand snippets if the LSP sent a snippet.
          ['<C-y>'] = cmp.mapping.confirm { select = true },

          -- If you prefer more traditional completion keymaps,
          -- you can uncomment the following lines
          --['<CR>'] = cmp.mapping.confirm { select = true },
          --['<Tab>'] = cmp.mapping.select_next_item(),
          --['<S-Tab>'] = cmp.mapping.select_prev_item(),
          --
          -- Manually trigger a completion from nvim-cmp.
          --  Generally you don't need this, because nvim-cmp will display
          --  completions whenever it has completion options available.
          ['<C-Space>'] = cmp.mapping.complete {},
          -- Set by nvim-cmp but here for completeness: ['<C-e>'] = cmp.mapping.abort(),

          -- Think of <c-l> as moving to the right of your snippet expansion.
          --  So if you have a snippet that's like:
          --  function $name($args)
          --    $body
          --  end
          --
          -- <c-l> will move you to the right of each of the expansion locations.
          -- <c-h> is similar, except moving you backwards.
          ['<C-l>'] = cmp.mapping(function()
            if luasnip.expand_or_locally_jumpable() then
              luasnip.expand_or_jump()
            end
          end, { 'i', 's' }),
          ['<C-h>'] = cmp.mapping(function()
            if luasnip.locally_jumpable(-1) then
              luasnip.jump(-1)
            end
          end, { 'i', 's' }),

          -- For more advanced Luasnip keymaps (e.g. selecting choice nodes, expansion) see:
          --    https://github.com/L3MON4D3/LuaSnip?tab=readme-ov-file#keymaps
        },
        sources = {
          {
            name = 'lazydev',
            -- set group index to 0 to skip loading LuaLS completions as lazydev recommends it
            group_index = 0,
          },
          -- { name = 'luasnip', priority = 40 },
          { name = 'luasnip', priority = 30 },

          { name = 'nvim_lsp' },
          { name = 'path', option = { label_trailing_slash = true, trailing_slash = true } },
          { name = 'buffer' }, -- Moved these to plugins/dadbod.lua
          { name = 'omni', option = { disable_omnifuncs = { 'v:lua.vim.lsp.omnifunc' } } }, -- cmp-omni
          --[[ {
            name = 'async_path',
            option = {
              trailing_path = true,
            },
          }, ]]
          -- { name = 'dotenv' },
          -- { name = 'vim-dadbod-completion', priority = 700 },
          -- { name = 'emoji' },
        },
      }
    end,
  },
  { -- You can easily change to a different colorscheme.
    -- Change the name of the colorscheme plugin below, and then
    -- change the command in the config to whatever the name of that colorscheme is.
    --
    -- If you want to see what colorschemes are already installed, you can use `:Telescope colorscheme`.
    -- 'folke/tokyonight.nvim',
    -- 'ellisonleao/gruvbox.nvim',
    -- 'craftzdog/solarized-osaka',
    'lifepillar/vim-gruvbox8',
    priority = 1000, -- Make sure to load this before all the other start plugins.
    init = function()
      -- Load the colorscheme here.
      -- Like many other themes, this one has different styles, and you could load
      -- any other, such as 'tokyonight-storm', 'tokyonight-moon', or 'tokyonight-day'.
      -- vim.cmd.colorscheme 'tokyonight-night'
      --vim.cmd.colorscheme 'tokyonight-storm'
      -- We will keep any tokyo* because of neo-tree working best with it
      -- https://github.com/LazyVim/LazyVim/issues/2527
      --vim.cmd.colorscheme 'tokyonight'
      vim.cmd.colorscheme 'tokyonight-storm'
      -- vim.cmd.colorscheme 'solarized-osaka-storm'
      --vim.cmd.colorscheme 'catppuccin-frappe'
      --vim.cmd.colorscheme 'github-dark-tritanopia'
      --vim.cmd.colorscheme 'gruvbox8'

      -- You can configure highlights by doing something like:
      vim.cmd.hi 'Comment gui=none'
    end,
  },

  -- Highlight todo, notes, etc in comments
  { 'folke/todo-comments.nvim', event = 'VimEnter', dependencies = { 'nvim-lua/plenary.nvim' }, opts = { signs = false } },
  {
    'nvim-lualine/lualine.nvim',
    -- lazy = false,
    event = 'VeryLazy',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    options = { theme = 'gruvbox' },
    --[[ sections = {
      lualine_z = { 'branch', 'location', 'selectioncount' },
    }, ]]
    --[[ opts = function()
      return {
        section = {
          lualine_z = { 'branch', 'location', 'selectioncount' },
        },
      }
    end, ]]
    opts = function()
      return {
        sections = {
          -- lualine_b = { 'branch', 'diff', 'diagnostics', { max_length = 20 } },
          -- lualine_b = { 'branch', 'diagnostics', { max_length = 20 } },
          lualine_b = { 'branch' },
          -- lualine_b = {'branch', 'diff', 'diagnostics'},
          lualine_x = { 'aerial', 'filetype' },
          lualine_z = { 'location', 'selectioncount', 'searchcount' },
        },
      }
    end,
  },
  { -- Collection of various small independent plugins/modules
    'echasnovski/mini.nvim',
    config = function()
      -- Better Around/Inside textobjects
      --
      -- Examples:
      --  - va)  - [V]isually select [A]round [)]paren
      --  - yinq - [Y]ank [I]nside [N]ext [Q]uote
      --  - ci'  - [C]hange [I]nside [']quote
      require('mini.ai').setup { n_lines = 500 }

      require('mini.align').setup()

      -- Add/delete/replace surroundings (brackets, quotes, etc.)
      --
      -- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
      -- - sd'   - [S]urround [D]elete [']quotes
      -- - sr)'  - [S]urround [R]eplace [)] [']
      -- Enabled - now leap/sneak uses 'gs'
      require('mini.surround').setup()

      -- require('mini.starter').setup()

      -- Simple and easy statusline.
      --  You could remove this setup call if you don't like it,
      --  and try some other statusline plugin
      local statusline = require 'mini.statusline'
      -- set use_icons to true if you have a Nerd Font
      statusline.setup { use_icons = vim.g.have_nerd_font }

      -- You can configure sections in the statusline by overriding their
      -- default behavior. For example, here we set the section for
      -- cursor location to LINE:COLUMN
      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.section_location = function()
        return '%2l:%-2v'
      end

      --*mini.files* Navigate and manipulate file system
      -- I forget about it and forget how it works...
      -- require('mini.files').setup()

      -- Adds some cool stuff in addition to fugitive.
      -- require('mini.git').setup()

      -- require('mini.diff').setup()

      require('mini.sessions').setup {
        autowrite = true,
        directory = '',
      }

      require('mini.ai').setup()

      require('mini.map').setup()

      require('mini.splitjoin').setup()

      require('mini.jump').setup()

      require('mini.animate').setup()

      require('mini.bufremove').setup()

      -- require('mini.visits').setup()

      -- ... and there is more!
      --  Check out: https://github.com/echasnovski/mini.nvim
      require('mini.extra').setup()
    end,
  },
  { -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    main = 'nvim-treesitter.configs', -- Sets main module to use for opts
    -- [[ Configure Treesitter ]] See `:help nvim-treesitter`
    opts = {
      ensure_installed = { 'bash', 'c', 'diff', 'html', 'lua', 'luadoc', 'markdown', 'markdown_inline', 'query', 'vim', 'vimdoc', 'php', 'javascript' },
      -- Autoinstall languages that are not installed
      auto_install = true,
      highlight = {
        enable = true,
        -- Some languages depend on vim's regex highlighting system (such as Ruby) for indent rules.
        --  If you are experiencing weird indenting issues, add the language to
        --  the list of additional_vim_regex_highlighting and disabled languages for indent.
        additional_vim_regex_highlighting = { 'ruby' },
      },
      indent = { enable = true, disable = { 'ruby' } },
    },
    -- There are additional nvim-treesitter modules that you can use to interact
    -- with nvim-treesitter. You should go explore a few and see what interests you:
    --
    --    - Incremental selection: Included, see `:help nvim-treesitter-incremental-selection-mod`
    --    - Show your current context: https://github.com/nvim-treesitter/nvim-treesitter-context
    --    - Treesitter + textobjects: https://github.com/nvim-treesitter/nvim-treesitter-textobjects
  },

  -- The following two comments only work if you have downloaded the kickstart repo, not just copy pasted the
  -- init.lua. If you want these files, they are in the repository, so you can just download them and
  -- place them in the correct locations.

  -- NOTE: Next step on your Neovim journey: Add/Configure additional plugins for Kickstart
  --
  --  Here are some example plugins that I've included in the Kickstart repository.
  --  Uncomment any of the lines below to enable them (you will need to restart nvim).
  --
  require 'kickstart.plugins.debug',
  require 'kickstart.plugins.indent_line',
  require 'kickstart.plugins.lint',
  require 'kickstart.plugins.autopairs',
  -- require 'kickstart.plugins.neo-tree', -- Adding myself. See lua/custom/plugins/neo-tree.lua for configuration
  require 'kickstart.plugins.gitsigns', -- adds gitsigns recommend keymaps

  -- NOTE: The import below can automatically add your own plugins, configuration, etc from `lua/custom/plugins/*.lua`
  --    This is the easiest way to modularize your config.
  --
  --  Uncomment the following line and add your plugins to `lua/custom/plugins/*.lua` to get going.
  --    For additional information, see `:help lazy.nvim-lazy.nvim-structuring-your-plugins`
  { import = 'custom.plugins' },
}

-- NOTE: Now I put them in after/plugin/keymaps.lua
-- Keep my keymaps here to keep init.lua smaller.
-- require 'lua.custom.keymaps.keymaps'

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et fdm=marker fmr={{{,}}}
