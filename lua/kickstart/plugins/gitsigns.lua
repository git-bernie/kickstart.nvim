-- Adds git related signs to the gutter, as well as utilities for managing changes
-- NOTE: gitsigns is already included in init.lua but contains only the base
-- config. This will add also the recommended keymaps.

return {
  {
    'lewis6991/gitsigns.nvim',
    opts = {
      current_line_blame_opts = {
        virt_text_pos = 'eol', -- 'eol' | 'overlay' | 'right_align'
        ignore_whitespace = true,
      },
      on_attach = function(bufnr)
        local gitsigns = require 'gitsigns'

        local function map(mode, l, r, opts)
          opts = opts or {}
          opts.buffer = bufnr
          vim.keymap.set(mode, l, r, opts)
        end

        -- Navigation
        map('n', ']c', function()
          if vim.wo.diff then
            vim.cmd.normal { ']c', bang = true }
          else
            -- gitsigns.nav_hunk('next', { preview = true, foldopen = true })
            -- gitsigns.nav_hunk { direction = 'next' }
            gitsigns.nav_hunk 'next'
          end
        end, { desc = 'Jump to next git [c]hange' })

        map('n', '[c', function()
          if vim.wo.diff then
            vim.cmd.normal { '[c', bang = true }
          else
            -- gitsigns.nav_hunk { direction = 'last' }
            gitsigns.nav_hunk 'last'
          end
        end, { desc = 'Jump to previous git [c]hange' })

        -- Actions
        -- visual mode
        map('v', '<leader>hs', function()
          gitsigns.stage_hunk { vim.fn.line '.', vim.fn.line 'v' }
        end, { desc = 'stage git hunk' })

        map('v', '<leader>hr', function()
          gitsigns.reset_hunk { vim.fn.line '.', vim.fn.line 'v' }
        end, { desc = 'reset git hunk' })

        -- normal mode
        map('n', '<leader>is', gitsigns.stage_hunk, { desc = 'g[I]tsigns [s]tage hunk' })
        map('n', '<leader>ir', gitsigns.reset_hunk, { desc = 'g[I]tsigns [r]eset hunk' })
        map('n', '<leader>iS', gitsigns.stage_buffer, { desc = 'g[I]tsigns [S]tage buffer' })
        -- map('n', '<leader>hu', gitsigns.undo_stage_hunk, { desc = 'git [u]ndo stage hunk' })
        map('n', '<leader>iR', gitsigns.reset_buffer, { desc = 'g[I]tsigns [R]eset buffer' })
        map('n', '<leader>ip', gitsigns.preview_hunk, { desc = 'g[I]tsigns [p]review hunk' })
        map('n', '<leader>iB', gitsigns.blame, { desc = 'g[I]tsigns [B]lame' })
        map('n', '<leader>ib', gitsigns.blame_line, { desc = 'g[I]tsigns [b]lame line' })
        map('n', '<leader>id', gitsigns.diffthis, { desc = 'g[I]tsigns [d]iff against index' })
        --[[ map('n', '<leader>hN', function()
          gitsigns.nav_hunk { 'next' }
        end, { desc = '[H]unk [N]ext (gitsigns.nav_hunk Use ]c instead.' }) ]]
        --[[ map('n', '<leader>hP', function()
          gitsigns.nav_hunk 'prev'
        end, { desc = '[H]unk [P]revious (gitsigns.nav_hunk. Use [c instead' }) ]]
        map('n', '<leader>iD', function()
          -- gitsigns.diffthis { against = '@'}
          -- gitsigns.diffthis { against = '~' }
          gitsigns.diffthis() -- default against the index, ('~1') for last commit
          -- `~` = previous commit (HEAD~)
          -- `@` = current commit (HEAD)
        end, { desc = 'g[I]tsigns [D]iff against previous commit (~)' })

        -- Toggles
        map('n', '<leader>tb', gitsigns.toggle_current_line_blame, { desc = '[T]oggle gitsigns show [b]lame line' })
        map('n', '<leader>iD', gitsigns.preview_hunk_inline, { desc = '[T]oggle gitsigns show [D]eleted' })
        map('n', '<leader>ti', gitsigns.toggle_signs, { desc = '[T]oggle g[I]tsigns' })
      end,
    },
  },
}
