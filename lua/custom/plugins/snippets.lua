return {
  'norcalli/snippets.nvim',
  enabled = false,
  config = function()
    require('snippets').use_suggested_mappings()
  end,
}
