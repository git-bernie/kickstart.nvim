-- leap (replacement for sneak?)
-- https://github.com/ggandor/leap.nvim
return {
  'ggandor/leap.nvim',
  enabled = true,
  -- Optional dependency
  opts = {
    -- disable auto-jumping to the first match
    -- safe_labels = '',
  },
  keys = {
    { 's', '<Plug>(leap-forward)', noremap = false, desc = '[s]neak (Leap)', mode = { 'n', 'x', 'o' } },
    -- { 'ss', '<Plug>(leap-forward)', noremap = false, desc = '[s]neak (Leap)', mode = { 'n', 'x', 'o' } },
    { 'gs', '<Plug>(leap-forward)', noremap = false, desc = '[s]neak (Leap)', mode = { 'n', 'x', 'o' } },
    { 'S', '<Plug>(leap-backward)', noremap = false, desc = '[S]neak (Leap) backwards', mode = { 'n', 'x', 'o' } },
    --[{ 'gs', '<Plug>(leap-from-window)', noremap = false, desc = '[gs]neak from window', mode = { 'n', 'x', 'o' } },]]
  },
  config = function()
    require('leap.user').set_repeat_keys(';', ',')
  end,
}
