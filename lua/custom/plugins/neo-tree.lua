--[[
For awesome recipes @see https://github.com/nvim-neo-tree/neo-tree.nvim/wiki/Recipes#commands

## The `filesystem.follow_current_file` option is replaced with a table, please move to `filesystem.follow_current_file.enabled`.
sessionoptions blank,buffers,curdir,folds,help,tabpages,winsize,terminal

FIX: Custom 'filter_and_refresh' command auto-refreshes after filtering (was: had to press "R" manually).
Remember that C-x is for clearing the filter.

]]

-- Shared PDF-preview helpers, used by both the file_open_requested handler and
-- the pdf_safe_preview command below (previously duplicated in each).
--
-- Uses pdftotext (poppler-utils). The command is passed as a LIST to systemlist
-- so no shell is involved — paths with spaces, quotes or $ are safe.
local function pdf_to_text_lines(path)
  if vim.fn.executable 'pdftotext' ~= 1 then
    return { 'pdftotext not found — install poppler-utils to preview PDFs as text.' }
  end
  local output = vim.fn.systemlist { 'pdftotext', '-layout', path, '-' }
  if vim.v.shell_error ~= 0 then
    -- Encrypted / malformed PDF, etc. Show the reason instead of dumping raw
    -- shell noise or an empty buffer.
    local msg = (#output > 0) and table.concat(output, ' ') or 'unknown error'
    return { 'Could not read PDF (pdftotext exit ' .. vim.v.shell_error .. '): ' .. msg }
  end
  if #output == 0 then
    return { '(PDF produced no extractable text — it may be image-only/scanned.)' }
  end
  return output
end

-- Build a read-only scratch buffer holding the PDF's extracted text.
local function make_pdf_text_buffer(path, name_prefix)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].bufhidden = 'wipe'
  -- bufhidden=wipe frees the name on hide, but a second live preview of the
  -- same file would collide (E95); pcall keeps that cosmetic failure harmless.
  pcall(vim.api.nvim_buf_set_name, buf, name_prefix .. vim.fn.fnamemodify(path, ':t'))
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, pdf_to_text_lines(path))
  vim.bo[buf].modifiable = false
  return buf
end

return {
  'nvim-neo-tree/neo-tree.nvim',
  enabled = true,
  branch = 'v3.x',
  -- version = '*',
  dependencies = {
    -- image.nvim previews raster images (png/jpg/gif/webp/avif) inline via
    -- kitty's graphics protocol. Config + PDF-safety notes live in image.lua.
    -- PDFs are excluded from image.nvim's hijack patterns, so they fall through
    -- to the custom pdf_safe_preview below (no more PDF preview errors).
    '3rd/image.nvim',
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
        -- Images preview via image.nvim; PDFs route to pdf_safe_preview (text).
        ['P'] = { 'pdf_safe_preview', desc = 'Preview (images inline, PDFs as text)' },
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
            local buf = make_pdf_text_buffer(path, 'PDF Preview: ')
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
          local buf = make_pdf_text_buffer(path, 'PDF: ')
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
            title = ' PDF Preview (q/<Esc> to close) ',
            title_pos = 'center',
          })
          -- Press q or <Esc> to close (matches the other custom floats)
          local function close_win()
            if vim.api.nvim_win_is_valid(win) then
              vim.api.nvim_win_close(win, true)
            end
          end
          vim.keymap.set('n', 'q', close_win, { buffer = buf, silent = true })
          vim.keymap.set('n', '<Esc>', close_win, { buffer = buf, silent = true })
        else
          -- Non-PDF: turn on the image.nvim hijack for this preview. neo-tree
          -- normally carries use_image_nvim/use_float on the native
          -- toggle_preview mapping's `config` block, and preview.config is
          -- copied from state.config (preview.lua). Because we intercept P with
          -- this custom command, we must set those flags on state.config
          -- ourselves — otherwise preview.config.use_image_nvim is nil and
          -- images render as plain text (preview.lua:366 never hijacks).
          -- use_float matches neo-tree's own image-preview default (kitty
          -- graphics position cleanly in a float).
          state.config = vim.tbl_extend('force', state.config or {}, {
            use_image_nvim = true,
            use_float = true,
          })
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
