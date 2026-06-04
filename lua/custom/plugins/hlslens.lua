-- Inline `[N/M]` indicator at the search match nearest the cursor.
-- https://github.com/kevinhwang91/nvim-hlslens
return {
  'kevinhwang91/nvim-hlslens',
  keys = {
    { '/', mode = 'n' },
    { '?', mode = 'n' },
    { 'n', mode = 'n' },
    { 'N', mode = 'n' },
    { '*', mode = 'n' },
    { '#', mode = 'n' },
    { 'g*', mode = 'n' },
    { 'g#', mode = 'n' },
  },
  config = function()
    require('hlslens').setup {
      nearest_only = true, -- only annotate the match closest to the cursor
      calm_down = true, -- fade the lens when cursor moves away from matches
      nearest_float_when = 'never', -- inline virt-text only, no floating window
    }

    -- Mute the lens highlight so it reads as decoration, not UI
    vim.api.nvim_set_hl(0, 'HlSearchLens', { link = 'Comment', default = true })
    vim.api.nvim_set_hl(0, 'HlSearchLensNear', { link = 'Comment', default = true })

    -- Trigger the lens immediately after `/foo<CR>` or `?foo<CR>` — hlslens
    -- doesn't hook this on its own, so without this autocmd the lens only
    -- appears once you press n/N to navigate.
    vim.api.nvim_create_autocmd('CmdlineLeave', {
      group = vim.api.nvim_create_augroup('bernie_hlslens', { clear = true }),
      pattern = { '/', '?' },
      callback = function()
        -- Skip if the search was aborted (Esc / Ctrl-C) — abort sets v:event.abort
        if vim.v.event and vim.v.event.abort then
          return
        end
        vim.schedule(function()
          require('hlslens').start()
        end)
      end,
    })

    local kopts = { noremap = true, silent = true }
    vim.keymap.set('n', 'n', [[<Cmd>execute('normal! ' . v:count1 . 'n')<CR><Cmd>lua require('hlslens').start()<CR>]], kopts)
    vim.keymap.set('n', 'N', [[<Cmd>execute('normal! ' . v:count1 . 'N')<CR><Cmd>lua require('hlslens').start()<CR>]], kopts)
    vim.keymap.set('n', '*', [[*<Cmd>lua require('hlslens').start()<CR>]], kopts)
    vim.keymap.set('n', '#', [[#<Cmd>lua require('hlslens').start()<CR>]], kopts)
    vim.keymap.set('n', 'g*', [[g*<Cmd>lua require('hlslens').start()<CR>]], kopts)
    vim.keymap.set('n', 'g#', [[g#<Cmd>lua require('hlslens').start()<CR>]], kopts)
  end,
}
