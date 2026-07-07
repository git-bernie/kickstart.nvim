-- image.nvim — renders real images in the terminal via kitty's graphics
-- protocol. Two jobs here:
--   1. Inline image rendering inside markdown/norg buffers (the `ft` trigger).
--   2. Neo-tree file previews — neo-tree lists this repo in its `dependencies`
--      and calls image.nvim to "hijack" preview buffers whose file matches
--      `hijack_file_patterns` below (see neo-tree.lua).
--
-- PDF SAFETY (why this was once disabled): image.nvim only touches files
-- matching `hijack_file_patterns`, and PDF is deliberately NOT in the list. So
-- previewing a .pdf in neo-tree never reaches image.nvim — it falls through to
-- neo-tree's custom `pdf_safe_preview` (pdftotext → buffer). That is the fix for
-- the old "preview errors with PDFs" that got this dependency removed.
--
-- Backend/processor requirements (all present on this box):
--   • kitty terminal (graphics protocol)         — kitty 0.47+
--   • ImageMagick CLI (`convert` + `identify`)    — magick_cli falls back to
--     these when the IM7 `magick` binary is absent, so IM6 works. No luarock.
return {
  '3rd/image.nvim',
  ft = { 'markdown', 'norg' },
  opts = {
    backend = 'kitty',
    processor = 'magick_cli', -- shells out to ImageMagick; no `magick` luarock needed
    -- Only these extensions are ever rendered as images. PDF is intentionally
    -- excluded so neo-tree's pdftotext preview handles it instead.
    hijack_file_patterns = { '*.png', '*.jpg', '*.jpeg', '*.gif', '*.webp', '*.avif' },
  },
}
