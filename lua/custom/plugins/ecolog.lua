-- ecolog2.nvim: LSP client for the `ecolog-lsp` binary (successor to ecolog.nvim's beta branch).
-- Completion arrives via LSP, so blink.cmp's built-in `lsp` source picks it up; no blink source needed.
-- Binary lookup order: Mason -> PATH -> ~/.cargo/bin.
return {
  'ph1losof/ecolog2.nvim',
  lazy = false,
  build = 'cargo install ecolog-lsp',
  keys = {
    { '<leader>sv', '<cmd>Ecolog list<cr>', desc = '[S]earch en[v] variables' },
    { '<leader>sV', '<cmd>Ecolog files select<cr>', desc = '[S]elect active .en[V] file(s)' },
  },
  opts = {
    lsp = {
      -- Off: in Laravel it flags env() default args ('mysql') and config() keys as undefined vars.
      features = { diagnostics = false },
    },
  },
}
