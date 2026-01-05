-- Example using Lazy.nvim
return {
  'mfussenegger/nvim-dap',
  dependencies = {
    'rcarriga/nvim-dap-ui',
    'williamboman/mason.nvim',
    'jay-babu/mason-nvim-dap.nvim',
  },
  config = function()
    local dap = require 'dap'
    local dapui = require 'dapui'

    -- Setup mason-nvim-dap to automatically install the adapter
    require('mason-nvim-dap').setup {
      ensure_installed = { 'php-debug-adapter' },
      automatic_installation = true,
    }

    -- Configure DAP UI
    dapui.setup()

    -- Link DAP events to DAP UI
    dap.listeners.before.attach.dapui_config = function()
      dapui.open()
    end
    dap.listeners.before.launch.dapui_config = function()
      dapui.open()
    end
    dap.listeners.before.event_terminated.dapui_config = function()
      dapui.close()
    end
    dap.listeners.before.event_exited.dapui_config = function()
      dapui.close()
    end

    -- ... additional keymaps (see step 3) ...

    dap.configurations.php = {
      name = 'Launch currently open script',
      type = 'php',
      request = 'launch',
      port = 9003,
      program = '${file}',
      host = '192.168.10.10',
      address = 'http://192.168.10.10',
      hostName = 'http://192.168.10.10',
    }
    -- Dap and DapUI keymaps
    -- vim.keymap.set('n', '<F5>', dap.continue, { desc = 'Debug: Continue' })
    -- vim.keymap.set('n', '<F6>', dap.next, { desc = 'Debug: Step Over' })
    -- vim.keymap.set('n', '<F7>', dap.step_into, { desc = 'Debug: Step Into' })
    -- vim.keymap.set('n', '<F8>', dap.step_out, { desc = 'Debug: Step Out' })
    -- vim.keymap.set('n', '<F9>', dap.toggle_breakpoint, { desc = 'Debug: Toggle Breakpoint' })
    -- vim.keymap.set('n', '<F10>', dap.repl.toggle, { desc = 'Debug: Toggle REPL' })
    -- vim.keymap.set('n', '<F11>', dapui.toggle, { desc = 'Debug: Toggle UI' })
  end,
}
