return {
  'saghen/blink.cmp',
  enabled = true,
  build = 'cargo build --release',
  version = '1.*',
  -- optional: provides snippets for the snippet source
  dependencies = {
    { 'giuxtaposition/blink-cmp-copilot' },
    {
      'bydlw98/blink-cmp-sshconfig',
      -- requires: +sudo snap install astral-uv --classic
      build = 'make',
    },
  },
  opts = {
    snippets = {
      preset = 'default',
    },
    sources = {
      default = {
        'lsp',
        'path',
        'snippets',
        'buffer',
        'copilot',
        'sshconfig',
      },
      per_filetype = {
        lua = { inherit_defaults = true, 'lazydev' },
      },
      providers = {
        lazydev = {
          name = 'LazyDev',
          module = 'lazydev.integrations.blink',
          score_offset = 100, -- show at a higher priority than lsp
        },
        copilot = {
          name = 'copilot',
          module = 'blink-cmp-copilot',
          score_offset = 100,
          async = true,
        },
        sshconfig = {
          name = 'SshConfig',
          module = 'blink-cmp-sshconfig',
        },
      },
    },
  },
}
