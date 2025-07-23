--[[ https://github.com/EmranMR/tree-sitter-blade/discussions/19#discussion-5400675 ]]
return {
  'EmranMR/tree-sitter-blade',
  enabled = false,
  config = function()
    ---@class parser_config
    local parser_config = require('nvim-treesitter.parsers').get_parser_configs()
    parser_config.blade = {
      install_info = {
        url = 'https://github.com/EmranMR/tree-sitter-blade',
        files = { 'src/parser.c' },
        branch = 'main',
      },
      filetype = 'blade',
      vim.filetype.add {
        pattern = {
          ['.*%.blade%.php'] = 'blade',
        },
      },
    }
    -- require('nvim-treesitter.configs').setup(opts)
  end,
}
