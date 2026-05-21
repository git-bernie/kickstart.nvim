return {
  'zbirenbaum/copilot.lua',
  lazy = false, -- Load eagerly to avoid RPC errors on startup
  config = function()
    require('copilot').setup {
      -- Inline ghost text disabled: blink-cmp-copilot handles completions via
      -- the blink menu. Running both would double-call the Copilot API and
      -- produce conflicting UX (ghost text + menu item for the same suggestion).
      suggestion = { enabled = false },
      panel = { enabled = false },
    }

    -- Auto-restart Copilot when it dies (check periodically on CursorHold)
    local copilot_restart_cooldown = 0
    vim.api.nvim_create_autocmd('CursorHold', {
      callback = function()
        local now = vim.uv.now()
        if now - copilot_restart_cooldown < 30000 then
          return
        end

        local ok, client = pcall(require, 'copilot.client')
        if ok and client then
          local is_running = client.is_running and client.is_running()
          if not is_running then
            copilot_restart_cooldown = now
            pcall(function()
              require('copilot.command').restart()
            end)
          end
        end
      end,
    })
  end,
}
