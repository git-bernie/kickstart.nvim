-- In .tmux.conf:
-- set -g @plugin 'christoomey/vim-tmux-navigator'
return {
  'christoomey/vim-tmux-navigator',
  cmd = {
    'TmuxNavigateDown',
    'TmuxNavigateLeft',
    'TmuxNavigatePrevious',
    'TmuxNavigateRight',
    'TmuxNavigateUp',
    'TmuxNavigatorProcessList',
  },
  keys = {
    { '<c-h>', '<cmd><C-U>TmuxNavigateLeft<cr>' },
    { '<c-j>', '<cmd><C-U>TmuxNavigateDown<cr>' },
    { '<c-k>', '<cmd><C-U>TmuxNavigateUp<cr>' },
    { '<c-l>', '<cmd><C-U>TmuxNavigateRight<cr>' },
    { '<c-\\>', '<cmd><C-U>TmuxNavigatePrevious<cr>' },
  },
}
