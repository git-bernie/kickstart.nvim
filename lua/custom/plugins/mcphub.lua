-- - In CopilotChat, use @filesystem__read_file, @filesystem__write_file, @fetch__fetch etc.
return {
  'ravitemer/mcphub.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
  },
  enabled = false,
  build = 'bundled_build.lua',
  cmd = 'MCPHub',
  keys = {
    { '<leader>mh', '<cmd>MCPHub<cr>', desc = '[M]CP [H]ub' },
  },
  config = function()
    require('mcphub').setup {
      use_bundled_binary = true,
      extensions = {
        copilotchat = {
          enabled = true,
          convert_tools_to_functions = true,
          convert_resources_to_functions = true,
          add_mcp_prefix = false,
        },
      },
    }
  end,
}
