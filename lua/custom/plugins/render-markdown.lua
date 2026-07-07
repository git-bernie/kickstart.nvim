return {
  'MeanderingProgrammer/render-markdown.nvim',
  -- Disabled: markview.nvim + markview-smart-tables is the active renderer (it
  -- wraps wide tables). Kept as a one-line fallback — set this to true and
  -- disable markview.lua to switch back. Two in-buffer renderers must not both run.
  enabled = false,
  dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-mini/mini.nvim' }, -- if you use the mini.nvim suite
  -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-mini/mini.icons' }, -- if you use standalone mini plugins
  -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' }, -- if you prefer nvim-web-devicons
  ---@module 'render-markdown'
  ---@type render.md.UserConfig
  opts = {
    latex = { enabled = false },
    file_types = { 'markdown', 'vimwiki' },
    only_render_image_at_cursor = true,
  },
  init = function()
    vim.treesitter.language.register('markdown', 'vimwiki')
  end,
  config = function(_, opts)
    require('render-markdown').setup(opts)

    -- Soften the inline `code` highlight. The tokyonight default is a loud
    -- blue block (fg #7aa2f7 on bg #414868). Reassert on ColorScheme so it
    -- survives theme reloads and render-markdown's own highlight setup
    -- (this autocmd is registered after setup, so it runs last and wins).
    --
    -- NOTE: this whole plugin is disabled, so the styling below is dormant. The
    -- LIVE inline-code softening for the active renderer is in markview.lua
    -- (MarkviewInlineCode). Keep the two in sync if you change the magenta.
    local function inline_code_hl()
      -- Tokyonight inline-`code` styling. fg-only (no block) reads calmly for
      -- something this frequent; magenta harmonizes with the cool palette.
      --   magenta #bb9af7 (current) · cyan #7dcfff · blue #7aa2f7 · orange #ff9e64
      --   faint block alt: fg = '#c0caf5', bg = '#24283b'
      local style = { fg = '#bb9af7', bg = 'NONE' }
      -- render-markdown's overlay group...
      vim.api.nvim_set_hl(0, 'RenderMarkdownCodeInline', style)
      -- ...and the treesitter group beneath it, which tokyonight gives a blue
      -- block (bg #414868). Without clearing this too, the block shows through
      -- whenever the overlay has no background of its own.
      vim.api.nvim_set_hl(0, '@markup.raw.markdown_inline', style)
    end
    vim.api.nvim_create_autocmd('ColorScheme', { callback = inline_code_hl })
    inline_code_hl()
  end,
}
