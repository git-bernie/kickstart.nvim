return {
  'ibhagwan/fzf-lua',
  -- optional for icon support
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  config = function()
    -- Strip ?:toggle-preview from FZF_DEFAULT_OPTS so we can type ? literally
    -- Use ctrl-/ for toggle-preview instead
    local fzf_opts = vim.env.FZF_DEFAULT_OPTS or ''
    fzf_opts = fzf_opts:gsub('%?:toggle%-preview,?', '')
    vim.env.FZF_DEFAULT_OPTS = fzf_opts

    require('fzf-lua').setup {
      keymap = {
        -- For builtin previewer (Neovim-style keys)
        builtin = {
          ['<C-p>'] = 'toggle-preview',
        },
        -- For fzf native previewers like bat/cat (fzf-style keys)
        fzf = {
          ['ctrl-p'] = 'toggle-preview',
        },
      },
      git = {
        branches = {
          sort_branches = '-committerdate',
        },
      },
    }
  end,
  opts = {},
}
