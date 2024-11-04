return {
  'nvim-neotest/neotest',
  dependencies = {
    'V13Axel/neotest-pest',
  },
  config = function()
    require('neotest').setup {
      adapters = {
        require 'neotest-pest',
      },
    }
  end,
}
