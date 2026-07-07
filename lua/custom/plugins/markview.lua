-- markview.nvim — the active in-buffer markdown renderer. markview-smart-tables
-- wraps wide tables to fit the window (handles GFM `:-:` separators and emoji
-- cleanly, where markdown-table-wrap.nvim failed). render-markdown.nvim is kept
-- disabled as a one-line fallback (see render-markdown.lua). hybrid_modes reveals
-- raw markdown under the cursor so editing still works.
return {
  'OXY2DEV/markview.nvim',
  lazy = false,
  dependencies = {
    'saghen/blink.cmp',
    'gunasekar/markview-smart-tables.nvim',
  },
  opts = {
    preview = {
      -- render the whole buffer, but show raw markdown on the line/block under
      -- the cursor in these modes (so you can read AND edit in place)
      hybrid_modes = { 'n', 'v', 'V', 'i' },
    },
    -- hand pipe-table rendering to smart-tables so wide tables wrap to fit
    renderers = {
      markdown_table = function(buffer, item)
        require('markview-smart-tables').render(buffer, item)
      end,
    },
  },
  config = function(_, opts)
    require('markview').setup(opts)

    -- Soften the inline `code` highlight. markview's default is a loud chip: a
    -- blended background block for something this frequent. We want fg-only
    -- (calmer) in a muted purple that still reads as "code" but harmonizes with
    -- the cool tokyonight palette — the same intent as the render-markdown.lua
    -- fallback's inline_code_hl (that file is disabled, so its version is
    -- dormant; this is the live one for the active renderer).
    --
    -- Two groups matter, and BOTH must lose their background or a chip remains:
    --   1. MarkviewInlineCode — markview's overlay group.
    --   2. @markup.raw.markdown_inline — the treesitter group BENEATH it, which
    --      tokyonight paints as a blue block (bg #414868). markview renders with
    --      hl_mode 'combine', so without clearing this the block bleeds through
    --      even when the overlay has bg = NONE.
    --
    -- markview recomputes these on VimEnter/ColorScheme via highlights.setup(),
    -- so a one-shot set would be clobbered on the next theme event. Re-assert on
    -- those events. vim.schedule defers our set to after markview's synchronous
    -- highlight creation, so ours wins regardless of autocmd registration order.
    --   muted purple #9d7cd8 (current) · magenta #bb9af7 (louder) · cyan #7dcfff
    --   faint-chip alt: fg = '#c0caf5', bg = '#24283b'
    local function soften_inline_code()
      local style = { fg = '#9d7cd8', bg = 'NONE' }
      vim.api.nvim_set_hl(0, 'MarkviewInlineCode', style)
      vim.api.nvim_set_hl(0, '@markup.raw.markdown_inline', style)
    end
    vim.api.nvim_create_autocmd({ 'ColorScheme', 'VimEnter' }, {
      callback = function()
        vim.schedule(soften_inline_code)
      end,
    })
    vim.schedule(soften_inline_code)
  end,
}
