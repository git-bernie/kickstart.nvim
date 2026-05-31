return {
  'rachartier/tiny-cmdline.nvim',
  event = 'VeryLazy',
  init = function()
    vim.o.cmdheight = 0
  end,
  opts = {
    width = { value = '70%', min = 40, max = 120 },
    position = { x = '50%', y = '50%' },
    on_reposition = function(...)
      local ok, tc = pcall(require, 'tiny-cmdline')
      if ok and tc.adapters and tc.adapters.blink then
        tc.adapters.blink(...)
      end
    end,
  },
}
