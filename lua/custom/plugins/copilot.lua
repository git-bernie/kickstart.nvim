return {
  'zbirenbaum/copilot.lua',
  dependencies = {
    'copilotlsp-nvim/copilot-lsp', -- (optional) for NES functionality
  },
  lazy = false, -- Load eagerly to avoid RPC errors on startup
  config = function()
    require('copilot').setup {
      suggestion = {
        auto_trigger = true,
        keymap = {
          accept = '<M-y>', -- Use Alt+y to accept inline suggestions
          accept_word = false,
          accept_line = false,
          next = '<M-]>',
          prev = '<M-[>',
          dismiss = '<C-]>',
        },
      },
      nes = {
        enabled = false,
        keymap = {
          accept_and_goto = '<leader>p',
          accept = false,
          dismiss = '<Esc>',
        },
      },
    }

    vim.api.nvim_create_autocmd('User', {
      pattern = 'BlinkCmpMenuOpen',
      callback = function()
        vim.b.copilot_suggestion_hidden = true
      end,
    })
    vim.api.nvim_create_autocmd('User', {
      pattern = 'BlinkCmpMenuClose',
      callback = function()
        vim.b.copilot_suggestion_hidden = false
      end,
    })

    -- Auto-restart Copilot when it dies (check periodically on CursorHold)
    local copilot_restart_cooldown = 0
    vim.api.nvim_create_autocmd('CursorHold', {
      callback = function()
        -- Rate limit: only check every 30 seconds
        local now = vim.loop.now()
        if now - copilot_restart_cooldown < 30000 then
          return
        end

        local ok, client = pcall(require, 'copilot.client')
        if ok and client then
          local is_running = client.is_running and client.is_running()
          if not is_running then
            copilot_restart_cooldown = now
            -- Silently restart Copilot
            pcall(function()
              require('copilot.command').restart()
            end)
          end
        end
      end,
    })
  end,
}
