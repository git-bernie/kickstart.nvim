-- leap (replacement for sneak?)
-- https://github.com/ggandor/leap.nvim
return {
  -- 'ggandor/leap.nvim',
  -- change the url to `https://codeberg.org/andyg/leap.nvim`.
  -- 'andyg/leap.nvim',
  url = 'https://codeberg.org/andyg/leap.nvim',
  enabled = true,
  -- Optional dependency
  keys = {
    { 's', '<Plug>(leap-forward)', noremap = false, desc = '[s]neak (Leap)', mode = { 'n', 'x', 'o' } },
    -- { 'ss', '<Plug>(leap-forward)', noremap = false, desc = '[s]neak (Leap)', mode = { 'n', 'x', 'o' } },
    -- { 'gs', '<Plug>(leap-forward)', noremap = false, desc = '[s]neak (Leap)', mode = { 'n', 'x', 'o' } },
    { 'S', '<Plug>(leap-backward)', noremap = false, desc = '[S]neak (Leap) backwards', mode = { 'n', 'x', 'o' } },
    --[{ 'gs', '<Plug>(leap-from-window)', noremap = false, desc = '[gs]neak from window', mode = { 'n', 'x', 'o' } },]]
  },
  config = function(_, opts)
    require('leap').setup(opts)
    require('leap.user').set_repeat_keys(';', ',')
  end,
}
