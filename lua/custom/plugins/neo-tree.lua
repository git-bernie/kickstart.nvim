--[[
For awesome recipes @see https://github.com/nvim-neo-tree/neo-tree.nvim/wiki/Recipes#commands

## The `filesystem.follow_current_file` option is replaced with a table, please move to `filesystem.follow_current_file.enabled`.
sessionoptions blank,buffers,curdir,folds,help,tabpages,winsize,terminal

FIX: Custom 'filter_and_refresh' command auto-refreshes after filtering (was: had to press "R" manually).
Remember that C-x is for clearing the filter.

]]
return {
  'nvim-neo-tree/neo-tree.nvim',
  enabled = true,
  branch = 'v3.x',
  -- version = '*',
  dependencies = {
    -- '3rd/image.nvim', -- Disabled: causes preview errors with PDFs
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons', -- not strictly required, but recommended
    'MunifTanjim/nui.nvim',
  },
  cmd = 'Neotree',
  keys = {
    { '\\', ':Neotree reveal<CR>', desc = 'NeoTree reveal', silent = true },
    { '<leader>tl', ':Neotree position=left<CR>', desc = 'Neo[T]ree position=[L]eft', silent = true },
    { '<leader>tf', ':Neotree float<CR>', desc = 'Neo[T]ree [F]loat', silent = true },
    { '<leader>tc', ':Neotree current<CR>', desc = 'Neo[T]ree [C]urrent', silent = true },
  },
  opts = {
    auto_restore_session_experimental = true,
    use_libuv_file_watcher = true,
    close_if_last_window = true, -- misspelled in lua/kickstart/plugins/neo-tree.lua
    window = {
      mappings = {
        -- Disable image.nvim for preview - causes errors with PDFs
        ['P'] = { 'pdf_safe_preview', desc = 'Preview (PDFs as text)' },
      },
    },
    -- Custom preview for PDFs - convert to text instead of opening external viewer
    event_handlers = {
      {
        -- After creating a file/folder, move cursor to it
        event = 'file_added',
        handler = function(destination)
          vim.defer_fn(function()
            vim.cmd('Neotree reveal_file=' .. vim.fn.fnameescape(destination))
          end, 100)
        end,
      },
      {
        event = 'file_open_requested',
        handler = function(args)
          local path = args.path
          local ext = path:match '%.(%w+)$'
          if ext and ext:lower() == 'pdf' then
            -- For preview, convert PDF to text in a scratch buffer
            local buf = vim.api.nvim_create_buf(false, true)
            vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
            vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
            vim.api.nvim_buf_set_name(buf, 'PDF Preview: ' .. vim.fn.fnamemodify(path, ':t'))
            local output = vim.fn.systemlist('pdftotext -layout "' .. path .. '" -')
            vim.api.nvim_buf_set_lines(buf, 0, -1, false, output)
            vim.api.nvim_buf_set_option(buf, 'modifiable', false)
            vim.cmd 'vsplit'
            vim.api.nvim_win_set_buf(0, buf)
            return { handled = true }
          end
        end,
      },
    },
    commands = {
      -- Custom preview that handles PDFs as text instead of launching Okular
      pdf_safe_preview = function(state)
        local node = state.tree:get_node()
        local path = node:get_id()
        local ext = path:match '%.(%w+)$'
        if ext and ext:lower() == 'pdf' then
          -- Convert PDF to text and show in a float window
          local buf = vim.api.nvim_create_buf(false, true)
          vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
          vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
          vim.api.nvim_buf_set_name(buf, 'PDF: ' .. vim.fn.fnamemodify(path, ':t'))
          local output = vim.fn.systemlist('pdftotext -layout "' .. path .. '" -')
          vim.api.nvim_buf_set_lines(buf, 0, -1, false, output)
          vim.api.nvim_buf_set_option(buf, 'modifiable', false)
          -- Open in a float window
          local width = math.floor(vim.o.columns * 0.6)
          local height = math.floor(vim.o.lines * 0.8)
          local win = vim.api.nvim_open_win(buf, true, {
            relative = 'editor',
            width = width,
            height = height,
            col = math.floor((vim.o.columns - width) / 2),
            row = math.floor((vim.o.lines - height) / 2),
            style = 'minimal',
            border = 'rounded',
            title = ' PDF Preview (q to close) ',
            title_pos = 'center',
          })
          -- Press q to close
          vim.api.nvim_buf_set_keymap(buf, 'n', 'q', ':close<CR>', { noremap = true, silent = true })
        else
          -- Use normal preview for non-PDFs
          require('neo-tree.sources.common.preview').toggle(state)
        end
      end,
      -- Open file with system default application (xdg-open)
      system_open = function(state)
        local node = state.tree:get_node()
        local path = node:get_id()
        vim.fn.jobstart({ 'xdg-open', path }, { detach = true })
      end,
      -- Smart open: use system viewer for binary files, neovim for text
      smart_open = function(state)
        local node = state.tree:get_node()
        local path = node:get_id()
        local ext = path:match '%.(%w+)$'
        local binary_exts = { pdf = true, png = true, jpg = true, jpeg = true, gif = true, mp4 = true, mp3 = true, zip = false, tar = false, gz = false }
        if ext and binary_exts[ext:lower()] then
          vim.fn.jobstart({ 'xdg-open', path }, { detach = true })
        else
          require('neo-tree.sources.filesystem.commands').open(state)
        end
      end,
      -- Open file and close Neo-tree (like Aerial's o/<C-CR>)
      open_and_close = function(state)
        local node = state.tree:get_node()
        local path = node:get_id()
        local ext = path:match '%.(%w+)$'
        local binary_exts = { pdf = true, png = true, jpg = true, jpeg = true, gif = true, mp4 = true, mp3 = true, zip = true, tar = true, gz = true }
        if ext and binary_exts[ext:lower()] then
          vim.fn.jobstart({ 'xdg-open', path }, { detach = true })
        else
          require('neo-tree.sources.filesystem.commands').open(state)
        end
        require('neo-tree.command').execute { action = 'close' }
      end,
      -- Custom filter command that auto-refreshes after filtering
      filter_and_refresh = function(state)
        local fs_commands = require 'neo-tree.sources.filesystem.commands'
        fs_commands.filter_on_submit(state)
        -- Poll until filter popup closes, then call refresh directly
        local timer = vim.uv.new_timer()
        if not timer then
          return
        end
        timer:start(
          100,
          100,
          vim.schedule_wrap(function()
            if vim.fn.mode() == 'n' then
              timer:stop()
              timer:close()
              fs_commands.refresh(state)
            end
          end)
        )
      end,
    },
    filesystem = {
      hijack_netrw_behavior = 'open_default',
      -- "open_current",
      -- "disabled",
      window = {
        mappings = {
          ['\\'] = 'close_window',
          ['<CR>'] = { 'smart_open', desc = 'Smart open (system viewer for PDFs)' },
          ['O'] = { 'system_open', desc = 'Open with system viewer' },
          ['P'] = { 'pdf_safe_preview', desc = 'Preview (PDFs as text)' },
          ['<C-CR>'] = { 'open_and_close', desc = 'Open and close tree' },
          ['f'] = 'filter_and_refresh', -- Use custom command instead of default filter
        },
      },
      follow_current_file = {
        enabled = true,
      },
    },
    -- I like this setting, but I also like to see the tree in the state I left it.
    -- follow_current_file = true,
    buffers = {
      enabled = true,
      show_unloaded = true,
    },
  },
}
