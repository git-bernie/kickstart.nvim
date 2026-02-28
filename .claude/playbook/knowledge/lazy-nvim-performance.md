# lazy.nvim Performance Patterns & Anti-Patterns

## Overview
Guide to optimizing Neovim startup with lazy.nvim. These patterns were discovered during a comprehensive audit of 116+ plugins that reduced startup from 3,067ms to 278ms (91% improvement).

## Anti-Patterns (Things That Defeat Lazy Loading)

### 1. `keys = function()` with top-level `require()`
**The Problem:** lazy.nvim evaluates the `keys` function at startup to discover keybindings. If the function calls `require()` at the top, it forces the plugin to load eagerly.

```lua
-- BAD: require() runs at startup just to discover keybindings
keys = function(_, keys)
  local dap = require('dap')       -- Forces dap to load NOW
  local dapui = require('dapui')   -- Forces dapui to load NOW
  return {
    { '<F5>', dap.continue, desc = 'Continue' },
    { '<F7>', dapui.toggle, desc = 'Toggle UI' },
  }
end,

-- GOOD: Static table with deferred require() inside callbacks
keys = {
  { '<F5>', function() require('dap').continue() end, desc = 'Continue' },
  { '<F7>', function() require('dapui').toggle() end, desc = 'Toggle UI' },
},
```

### 2. `vim.keymap.set()` in Lua table constructors
**The Problem:** Calls inside a table constructor execute as side effects when the file is `require()`d.

```lua
-- BAD: This keymap runs at parse time, before the plugin loads
return {
  'some/plugin',
  vim.keymap.set('n', '<leader>x', function() ... end),  -- Runs NOW
  opts = {},
}

-- GOOD: Use lazy.nvim's keys spec instead
return {
  'some/plugin',
  keys = {
    { '<leader>x', function() ... end, desc = 'Do thing' },
  },
  opts = {},
}
```

### 3. `require()` in `opts` tables
**The Problem:** Values in the `opts` table are evaluated when the spec is parsed.

```lua
-- BAD: require runs at spec parse time
opts = {
  keybinds = {
    ['ov'] = require('ranger-nvim').OPEN_MODE.vsplit,  -- Forces load
  },
},

-- GOOD: Use config function instead (runs after plugin loads)
config = function()
  require('ranger-nvim').setup {
    keybinds = {
      ['ov'] = require('ranger-nvim').OPEN_MODE.vsplit,  -- Safe here
    },
  }
end,
```

### 4. `opts = {}` on plugins without `setup()`
**The Problem:** lazy.nvim auto-calls `require('plugin').setup(opts)`. If the plugin has no `setup()` function, this errors.

```lua
-- BAD: Plugin doesn't have setup(), causes "Failed to run config" error
return { 'some/completion-source', opts = {} }

-- GOOD: No opts needed for plugins that self-register
return { 'some/completion-source' }
```

Affected examples: `gitignore.nvim`, `cmp-dotenv`, `telescope-env`.

### 5. Missing lazy triggers with `defaults.lazy = true`
**The Problem:** With `defaults.lazy = true`, a plugin with no trigger never loads.

```lua
-- BAD: With defaults.lazy = true, this NEVER loads
return { 'tpope/vim-sleuth' }

-- GOOD: Add appropriate trigger
return { 'tpope/vim-sleuth', event = 'BufReadPost' }
```

## Choosing the Right Lazy Trigger

| Trigger | When to use | Examples |
|---------|-------------|---------|
| `event = 'BufReadPost'` | Must work when file opens | gitsigns, treesitter, lspconfig, vim-sleuth, vim-lastplace |
| `event = 'InsertEnter'` | Only needed in insert mode | blink.cmp, better-escape, copilot-cmp |
| `event = 'VimEnter'` | Needs to be visible early | which-key, mini.nvim (statusline) |
| `event = 'VeryLazy'` | Visual/aesthetic, not critical | smear-cursor, neoscroll, lualine, vim-devicons, nvim-notify |
| `event = 'LspAttach'` | Only useful with LSP running | workspace-diagnostics, lsp-file-operations |
| `cmd = { ... }` | Invoked via commands only | FzfLua, ToggleTerm, Telescope (extensions), Neogen |
| `keys = { ... }` | Invoked via keybindings | ranger, digraph-picker, debug (F5, F7) |
| `ft = { ... }` | Filetype-specific | lazydev (lua), log-highlight (log), jsonpath (json) |
| `lazy = false` | MUST load at startup | Colorscheme, snacks.nvim (dashboard/indent), copilot (RPC) |

## Structural Optimizations

### Split monolithic plugin configs
If a plugin has both critical and non-critical modules (like mini.nvim), defer the non-critical ones:

```lua
config = function()
  -- Critical: load immediately
  require('mini.ai').setup { n_lines = 500 }
  require('mini.surround').setup()
  require('mini.statusline').setup { use_icons = true }

  -- Non-critical: defer to VeryLazy
  vim.api.nvim_create_autocmd('User', {
    pattern = 'VeryLazy',
    callback = function()
      require('mini.animate').setup { resize = { enable = false } }
      require('mini.sessions').setup { ... }
      require('mini.map').setup()
      -- etc.
    end,
  })
end,
```

### Disable unused built-in plugins
In lazy.nvim's `performance.rtp.disabled_plugins`:
```lua
disabled_plugins = {
  'gzip', 'netrwPlugin', 'tarPlugin',
  'tohtml', 'tutor', 'zipPlugin',
}
```
Saves ~15-25ms. Safe if you use neo-tree instead of netrw.

### Set `defaults.lazy = true`
Flips the default so all plugins are lazy unless they opt out. Forces you to be intentional about loading, but catches accidental eager loading of every new plugin you add.

### Removing mason-lspconfig: name translation gotcha
When removing `mason-lspconfig` in favor of Neovim 0.11's native `vim.lsp.config()` + `vim.lsp.enable()`, you lose the **LSP-name → Mason-package-name translation layer**. Mason's registry uses hyphenated names, not LSP config names:

| LSP config name | Mason package name |
|----------------|--------------------|
| `lua_ls` | `lua-language-server` |
| `bashls` | `bash-language-server` |
| `jsonls` | `json-lsp` |
| `html` | `html-lsp` |
| `yamlls` | `yaml-language-server` |
| `ansiblels` | `ansible-language-server` |
| `pyright` | `pyright` (same) |
| `clangd` | `clangd` (same) |

If you use `mason-tool-installer`, replace `vim.tbl_keys(servers)` with explicit Mason package names:
```lua
-- BAD: passes LSP names like "lua_ls" — mason can't find them
local ensure_installed = vim.tbl_keys(servers or {})

-- GOOD: use Mason's own package names
local ensure_installed = {
  'lua-language-server', 'bash-language-server', 'json-lsp',
  'html-lsp', 'yaml-language-server', 'pyright', 'clangd',
  'stylua',  -- formatters/linters use their own names
}
```

### Trim verbose lazy.nvim defaults
Only specify values that differ from lazy.nvim's built-in defaults. Removing ~188 lines of redundant config (root, git, rocks, pkg, dev, install, headless, diff, checker, readme, state, profiling) cut an additional ~570ms off startup — every table literal is parsed and allocated at init time.

## Verification Commands

```bash
# Measure startup time
nvim --headless --startuptime /tmp/nvim-startup.log +'qall!' && tail -3 /tmp/nvim-startup.log

# Find top self-time offenders
awk '$3+0 > 5' /tmp/nvim-startup.log | sort -k3 -rn | head -20

# Check for startup errors
nvim --headless -c "lua vim.defer_fn(function() vim.cmd([[messages]]) vim.cmd([[qa!]]) end, 3000)" 2>&1

# Check lazy plugin status (in Neovim)
:Lazy
```

## Performance Audit Results (Feb 2026)

| Phase | Headless Startup |
|-------|-----------------|
| Before any optimization | ~3,067ms |
| Phase 1 (blink, telescope, schemastore, 11 plugins) | ~2,400ms |
| Phase 2 (defaults.lazy, mini split, debug fix, 20+ plugins) | ~850ms |
| Phase 3 (trim defaults, upstream fixes, guess-indent) | **~278ms** |

**Total reduction: 91% (3,067ms → 278ms)**

Key savings:
- `defaults.lazy = true`: ~200ms (60+ plugins deferred)
- mini.nvim VeryLazy split: ~40-60ms
- debug.lua keys anti-pattern fix: ~37ms
- fzf-lua, vim-devicons, notify, ranger, digraph-picker defers: ~100ms
- Built-in plugins disabled: ~15-25ms
- Trim ~188 lines of redundant lazy.nvim defaults: ~570ms
- Replace vim-sleuth with guess-indent.nvim: minor
