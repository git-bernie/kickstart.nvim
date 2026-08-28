return {
  'benoror/gpg.nvim',
  -- Disabled: prefer the gpg CLI (`gpg -c file` for symmetric / password-per-file,
  -- `gpg -e -r <key> file` for public-key). This plugin only does public-key
  -- encrypt-to-self, despite its README claiming "symmetric". Flip `enabled`
  -- back to true to reactivate; the event trigger below is already correct.
  enabled = false,
  -- The plugin's whole mechanism is BufReadPre/BufWritePre autocmds on *.gpg,
  -- so it must load on the buffer read itself. Lazy-loading on `ft` never
  -- fired: Neovim assigns no filetype to *.gpg, and FileType is too late for
  -- BufReadPre anyway. NOTE: only *.gpg is handled -- not .asc/.pgp.
  event = { 'BufReadPre *.gpg', 'BufNewFile *.gpg' },
  config = function()
    -- Syncs GPG with your current TTY terminal
    vim.g.gpg_update_tty = true
    -- Primes the gpg-agent background daemon
    vim.g.gpg_prime_agent = true
  end,
}
