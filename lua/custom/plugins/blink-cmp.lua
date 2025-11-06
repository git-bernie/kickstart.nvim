return {
  'saghen/blink.cmp',
  -- optional: provides snippets for the snippet source
  dependencies = {
    'rafamadriz/friendly-snippets',
    'moyiz/blink-emoji.nvim',
    'bydlw98/blink-cmp-env',
    'fang2hou/blink-copilot',
    'allaman/emoji.nvim',
    'saghen/blink.compat',
  },

  -- use a release tag to download pre-built binaries
  version = '1.*',
  -- AND/OR build from source, requires nightly: https://rust-lang.github.io/rustup/concepts/channels.html#working-with-nightly-rust
  -- build = 'cargo build --release',
  -- If you use nix, you can build from source using latest nightly rust with:
  -- build = 'nix run .#build-plugin',

  ---@module 'blink.cmp'
  ---@type blink.cmp.Config
  opts = {
    -- 'default' (recommended) for mappings similar to built-in completions (C-y to accept)
    -- 'super-tab' for mappings similar to vscode (tab to accept)
    -- 'enter' for enter to accept
    -- 'none' for no mappings
    --
    -- All presets have the following mappings:
    -- C-space: Open menu or open docs if already open
    -- C-n/C-p or Up/Down: Select next/previous item
    -- C-e: Hide menu
    -- C-k: Toggle signature help (if signature.enabled = true)
    --
    -- See :h blink-cmp-config-keymap for defining your own keymap
    keymap = { preset = 'default' },

    appearance = {
      -- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
      -- Adjusts spacing to ensure icons are aligned
      nerd_font_variant = 'mono',
      -- sets the fallback highlight groups to nvim-cmp's highlight groups
      -- useful for when your theme doesn't support blink.cmp
      -- will be removed in a future release, assuming themes add support
      use_nvim_cmp_as_default = false,
    },

    -- (Default) Only show the documentation popup when manually triggered
    completion = {
      list = { selection = { preselect = false } },
      accept = {
        -- experimental auto-brackets support
        auto_brackets = {
          enabled = true,
        },
      },
      documentation = { auto_show = true },
      menu = {
        auto_show = function(ctx)
          return vim.fn.getcmdtype() == ':'
        end,
      },
      ghost_text = { enabled = true },
    },
    signature = { enabled = true },

    -- Default list of enabled providers defined so that you can extend it
    -- elsewhere in your config, without redefining it, due to `opts_extend`
    sources = {
      default = { 'lazydev', 'lsp', 'path', 'snippets', 'buffer', 'emoji', 'env', 'copilot' },
      providers = {
        copilot = {
          -- https://github.com/fang2hou/blink-copilot
          name = 'copilot',
          module = 'blink-copilot',
          score_offset = 100,
          async = true,
          opts = {
            -- Local options override global ones
            max_completions = 3, -- Override global max_completions

            -- Final settings:
            -- * max_completions = 3
            -- * max_attempts = 2
            -- * all other options are default
          },
        },
        env = {
          name = 'Env',
          module = 'blink-cmp-env',
          --- @type blink-cmp-env.Options
          opts = {
            item_kind = require('blink.cmp.types').CompletionItemKind.Variable,
            show_braces = false,
            show_documentation_window = true,
          },
        },
        emoji = {
          module = 'blink.compat.source',
          name = 'emoji',
          score_offset = 15, -- Tune by preference
          opts = { insert = true }, -- Insert emoji (default) or complete its name
          should_show_items = function()
            return vim.tbl_contains(
              -- Enable emoji completion only for git commits and markdown.
              -- By default, enabled for all file-types.
              { 'gitcommit', 'markdown', 'text', 'php', 'lua', 'log' },
              vim.o.filetype
            )
          end,
          --[[ -- overwrite kind of suggestion
          transform_items = function(ctx, items)
            local kind = require('blink.cmp.types').CompletionItemKind.Text
            for i = 1, #items do
              items[i].kind = kind
            end
            return items
          end, ]]
        },
        lazydev = {
          name = 'LazyDev',
          module = 'lazydev.integrations.blink',
          -- make lazydev completions top priority (see `:h blink.cmp`)
          score_offset = 100,
        },
      },
    },

    -- (Default) Rust fuzzy matcher for typo resistance and significantly better performance
    -- You may use a lua implementation instead by using `implementation = "lua"` or fallback to the lua implementation,
    -- when the Rust fuzzy matcher is not available, by using `implementation = "prefer_rust"`
    --
    -- See the fuzzy documentation for more information
    fuzzy = { implementation = 'prefer_rust_with_warning' },
  },
  opts_extend = { 'sources.default' },
}
