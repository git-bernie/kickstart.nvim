-- Wraps wide markdown table cells to fit the window and redraws the Unicode
-- table in place. Augments render-markdown.nvim, which has no max-width / no
-- window-fit of its own. render-markdown's own pipe_table renderer is disabled
-- (see render-markdown.lua) so the two do not fight over the same lines.
-- Toggle in a markdown buffer with <leader>tt (after/ftplugin/markdown.lua).
return {
  'ice345/markdown-table-wrap.nvim',
  ft = { 'markdown', 'vimwiki' },
  opts = {
    max_col_width = 36, -- two columns fit within an 80-col budget
    max_width_ratio = 0.9, -- fraction of window width a table may occupy
    min_col_width = 8,
    inline_mode = 'replace', -- hide source, draw wrapped table over it
    auto_preview = true, -- render automatically on entering a table
  },
}
