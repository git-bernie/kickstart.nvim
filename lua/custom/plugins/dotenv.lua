--[[ Run Dotenv to load up manually ]]
return {
  'ellisonleao/dotenv.nvim',
  enabled = true,
  opts = {
    enable_on_load = false,
    verbose = true,
    -- envvars is really a shell file with export so it does not work well
    file_name = { '.env', 'env-*' },
  },
}

--[[ return {
  'tpope/vim-dotenv',
} ]]
