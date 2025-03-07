return {
  'fei6409/log-highlight.nvim',
  --[[ config = function()
    require('log-highlight').setup {}
  end, ]]
  opts = {
    -- glob patterns for log files (not sure if () will work)
    pattern = {
      'tracker.log.*',
      '*access*.log.*',
      '*error*.log.*',
    },
  },
}
