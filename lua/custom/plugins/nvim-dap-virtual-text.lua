return {
  'theHamsta/nvim-dap-virtual-text',
  enabled = true,
  config = function()
    require('nvim-dap-virtual-text').setup {
      enabled = true,
      enabled_commands = true,
      highlight_changed_variables = true,
      highlight_new_as_changed = false,
      all_references = false,
      virt_text_pos = 'eol',
      all_frames = false,
      virt_lines = false,
      virt_text_win_col = nil,
    }
  end,
  dependencies = { 'nvim-dap' },
  event = { 'BufReadPre', 'BufNewFile' },
  lazy = true,
}
