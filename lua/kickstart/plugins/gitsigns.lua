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
            gitsigns.nav_hunk { direction = 'next' }
          end
        end, { desc = 'Jump to next git [c]hange' })

        map('n', '[c', function()
          if vim.wo.diff then
            vim.cmd.normal { '[c', bang = true }
          else
            gitsigns.nav_hunk { direction = 'last' }
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
        map('n', '<leader>hs', gitsigns.stage_hunk, { desc = 'gitsigns [s]tage hunk' })
        map('n', '<leader>hr', gitsigns.reset_hunk, { desc = 'gitsigns [r]eset hunk' })
        map('n', '<leader>hS', gitsigns.stage_buffer, { desc = 'gitsigns [S]tage buffer' })
        -- map('n', '<leader>hu', gitsigns.undo_stage_hunk, { desc = 'git [u]ndo stage hunk' })
        map('n', '<leader>hR', gitsigns.reset_buffer, { desc = 'gitsigns [R]eset buffer' })
        map('n', '<leader>hp', gitsigns.preview_hunk, { desc = 'gitsigns [p]review hunk' })
        map('n', '<leader>hB', gitsigns.blame, { desc = 'gitsigns [B]lame' })
        map('n', '<leader>hb', gitsigns.blame_line, { desc = 'gitsigns [b]lame line' })
        map('n', '<leader>hd', gitsigns.diffthis, { desc = 'gitsigns [d]iff against index' })
        --[[ map('n', '<leader>hN', function()
          gitsigns.nav_hunk { 'next' }
        end, { desc = '[H]unk [N]ext (gitsigns.nav_hunk Use ]c instead.' }) ]]
        --[[ map('n', '<leader>hP', function()
          gitsigns.nav_hunk 'prev'
        end, { desc = '[H]unk [P]revious (gitsigns.nav_hunk. Use [c instead' }) ]]
        map('n', '<leader>hD', function()
          -- gitsigns.diffthis { against = '@'}
          gitsigns.diffthis { against = '~' }
          -- `~` = previous commit (HEAD~)
          -- `@` = current commit (HEAD)
        end, { desc = 'gitsigns [D]iff against previous commit (~)' })

        -- Toggles
        map('n', '<leader>tb', gitsigns.toggle_current_line_blame, { desc = '[T]oggle gitsigns show [b]lame line' })
        map('n', '<leader>tD', gitsigns.preview_hunk_inline, { desc = '[T]oggle gitsigns show [D]eleted' })
        map('n', '<leader>ht', gitsigns.toggle_signs, { desc = 'gitsigns [h]unk [t]oggle' })
        map('n', '<leader>tg', gitsigns.toggle_signs, { desc = '[t]oggle [g]itsigns' })
      end,
    },
  },
}
