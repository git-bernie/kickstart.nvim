# Markdown Readability & Width — Design Spec

**Date:** 2026-06-26
**Status:** Approved direction (hybrid), pending spec review
**Author:** Bernie + Claude (brainstorming session)

## Problem

Claude-generated markdown is read primarily in Neovim and secondarily as
PDF-from-markdown. Prose already reads fine — `prose.lua` enables soft-wrap
(`wrap + linebreak + breakindent`) for markdown, and `j/k` move by display
line. **Tables are the only real pain:**

- In markdown, every table row is **one logical line**. Soft-wrap only inserts
  *visual* breaks at the screen edge; it cannot break *inside* a cell while
  preserving the column grid. So the wrap machinery that rescues prose is
  structurally useless for tables.
- `render-markdown.nvim` (enabled) draws tables with box characters but renders
  each column at its **content** width — it has `min_width` and cell *styling*
  (padded/trimmed/raw/overlay), but **no max-width and no window-fit**. Wide
  tables overflow the screen.
- The PDF path inherits the same overflow (historically clipped silently).

## Decision

**Hybrid (option D):** fix the *source* (how Claude authors markdown) for the
common case, and harden the *fallbacks* (nvim viewer, PDF) so any table that
slips through — or arrives from another tool / legacy file — still reads.

Locked parameters:

- **Width budget:** 80 columns.
- **Rules location:** global `~/.claude/CLAUDE.md`, applied always unless the
  user says otherwise in-session.
- **nvim table-wrap toggle keymap:** `<leader>tt`.
- **`max_col_width`:** 36 (so two columns fit side-by-side within 80).

Out of scope: code-block / long-URL overflow (those can't wrap; minor, accept
horizontal scroll); switching the renderer to `markview.nvim`.

---

## Pillar 1 — Authoring rules (the source fix; highest leverage)

Add a short, imperative section to global `~/.claude/CLAUDE.md`. Phrased as
"follow unless told otherwise this session." Content:

- **80-column budget.** Any generated table must render within ~80 columns
  (single-space padding).
- **Table-vs-record decision.** Use a markdown table only when it is **≤4
  columns** *and* fits the 80-col budget with terse cells. Otherwise emit a
  **record layout** — a bold label / small heading per row followed by
  `field: value` bullets. Record layout wraps perfectly in nvim and PDF and has
  no width ceiling.

  Record-layout example:

  ```markdown
  ### Fairstone
  - **Rate:** 19.99%
  - **Min score:** 560
  - **Max amount:** $50,000
  - **Funding:** 1–3 days
  ```

- **Terse cells.** No multi-sentence content in a cell. Keep cells short
  (~15 chars target); push explanation to prose or footnotes *below* the table.
- **Don't hard-wrap prose.** One paragraph = one line; rely on prose-mode
  soft-wrap. Hard-wrapping only creates ragged re-flow on edit and helps
  nothing. Tables are the **only** width-governed element.
- **Escalation pointer.** When a wide table is genuinely unavoidable, note that
  the PDF path (`md2pdf`) wraps cells, and the nvim path has `<leader>tt`.

This is the only change that costs nothing at read time, because it fixes the
artifact at creation.

## Pillar 2 — nvim viewer fallback (this repo)

Catches wide tables Pillar 1 didn't author (other tools, legacy files, the rare
one Claude lets through). Uses `ice345/markdown-table-wrap.nvim` — pure Lua,
Neovim ≥ 0.10, wraps cell content to fit the window and redraws the Unicode
table in place. It is purpose-built to augment `render-markdown.nvim`.

### Changes

1. **New plugin:** `lua/custom/plugins/markdown-table-wrap.lua`

   ```lua
   return {
     'ice345/markdown-table-wrap.nvim',
     ft = { 'markdown', 'vimwiki' },
     opts = {
       max_col_width = 36,     -- two columns fit within 80
       max_width_ratio = 0.9,  -- fraction of window width
       min_col_width = 8,
       inline_mode = 'replace',
       auto_preview = true,
     },
   }
   ```

2. **Disable render-markdown's table renderer only** (it must not fight the new
   plugin). In `lua/custom/plugins/render-markdown.lua`, add to `opts`:

   ```lua
   pipe_table = { enabled = false },
   ```

   Everything else render-markdown does (headings, code, inline styling, the
   softened inline-`code` highlight) is unchanged.

3. **Free `<leader>tt` from vim-table-mode.** It currently owns `<leader>tt`
   via its default `g:table_mode_tableize_map` (the "tableize" command Bernie
   doesn't use). Park it on `<leader>tT` rather than empty-string (empty string
   produces a broken `xnoremap`). In `lua/custom/plugins/vim-table-mode.lua`:

   ```lua
   return {
     'dhruvasagar/vim-table-mode',
     init = function()
       -- Free <leader>tt for markdown-table-wrap; tableize is unused.
       vim.g.table_mode_tableize_map = '<Leader>tT'
     end,
   }
   ```

   (Tagbar's `<leader>tt` binding is dead code — `enabled = false` — so no
   action needed there.)

4. **Bind the toggle**, buffer-local in `after/ftplugin/markdown.lua` (scoped to
   markdown, where the command exists):

   ```lua
   vim.keymap.set('n', '<leader>tt', '<cmd>MarkdownTableTogglePreview<CR>',
     { buffer = true, desc = '[T]oggle [t]able wrap', silent = true })
   ```

## Pillar 3 — PDF (already solved; reference only)

No build. `~/work/dotfiles/system-fixes/md2pdf/style.css` + the `md2pdf` wrapper
already wrap wide tables: `overflow-wrap: anywhere` scoped to `th/td`, 9pt table
font, padding tuning, with a documented escalation path (right-align numeric
columns → landscape `@page` → restructure) and the `nowrap`+`anywhere`
anti-pattern called out. Pillar 1's rules reference this as the PDF escalation;
`~/.claude/playbook/knowledge/pdf-conversion.md` already documents it.

---

## Cross-repo rollout

- **This nvim repo:** Pillar 2 (new plugin file, render-markdown edit,
  vim-table-mode edit, ftplugin keymap). Commit normally on the working branch.
- **dotfiles (`~/.claude/...`):** Pillar 1 (global `CLAUDE.md` edit). Per
  Bernie's "dotfiles commit in batches, don't branch / don't auto-commit single
  files" rule, **stage the edit and leave it for his next dotfiles batch** — do
  not commit it automatically.

## Verification

1. **Pillar 2 install:** `:Lazy sync`, open a markdown file with a deliberately
   wide table (6+ cols or long cells). Confirm the table redraws wrapped within
   the window, and render-markdown no longer draws its own table grid.
2. **Toggle:** `<leader>tt` toggles the wrapped preview on/off in a markdown
   buffer. `:checkhealth` / `:messages` clean.
3. **No regression:** `<leader>tT` now triggers tableize (moved); `<leader>tw`
   (wrap), `<leader>tp` (prose) still work; non-table markdown rendering
   (headings, code) unchanged.
4. **Pillar 1:** in a fresh session, ask Claude to produce a wide dataset;
   confirm it emits a record layout (not an overflowing table) and any table it
   does emit fits ~80 cols.
5. **stylua:** `stylua --check .` passes (CI gate).

## Success criteria

- Wide tables in nvim are readable without horizontal scrolling (wrapped to
  window) via the viewer fallback.
- New Claude-authored markdown rarely produces an over-wide table at all —
  wide data comes back as record layout.
- PDF path continues to wrap (already true via `md2pdf`).
- No existing keymaps or markdown rendering regress.

---

## Outcome (2026-06-26)

Final decision after implementation + live testing:

- **Pillar 1 — SHIPPED.** Authoring rules added to global `~/.claude/CLAUDE.md`
  ("Markdown Width & Tables"). This is the high-leverage win and applies to both
  work and personal sessions (both resolve to `~/.claude/CLAUDE.md`).
- **Pillar 3 — pre-existing.** `md2pdf` already wraps wide tables; no change.
- **Pillar 2 — REJECTED.** `ice345/markdown-table-wrap.nvim` was implemented,
  then removed. It fought real content at every turn:
  1. `auto_preview` mode glitches the header and forces window `nowrap`, which
     kills prose-mode soft-wrap (`inline.lua` sets `wrap=false`).
  2. With `inline_disable_wrap = false` (to keep prose wrap), the soft-wrapped
     source rows nudge the overlay → header-row misalignment.
  3. Re-enabling render-markdown's `pipe_table` for a nice default view →
     double-draw fragments when toggling the wrap overlay.
  4. Float mode avoided the double-draw, but the parser rejects valid GFM
     center-align separators: `is_separator_cell` strips colons then requires
     `>= 3` dashes, so `:-:` (one dash) → "no valid Markdown table separator
     row found." Real docs (e.g. `billing-and-commissions.md`) use `:-:`.
  Additionally, emoji in cells drift only when the plugin *wraps* them
  (render-markdown renders emoji fine), but emoji were not the deciding factor.

## Update (2026-06-26) — Pillar 2 solved via markview

After rejecting `markdown-table-wrap.nvim`, the fallback option was trialed and
**adopted**: `OXY2DEV/markview.nvim` + `gunasekar/markview-smart-tables.nvim`.
Tested live on the real stress doc `billing-and-commissions.md` (which combines
`:-:` separators, emoji, and wide tables). It cleared all four walls that beat
the standalone plugin:

- **`:-:` center-align separators render** — markview parses via treesitter
  (spec-compliant), so the tables that gave "no valid separator" now render.
- **Emoji columns stay aligned** when wrapped (✅/⚠️ vs `—` line up).
- **Prose soft-wrap and wrapped tables coexist** — `wrap` stays on; with wrap on,
  smart-tables fits every table to the window while prose still wraps.
- **No double-draw** — markview is the sole in-buffer renderer.

`hybrid_modes = {n,v,V,i}` reveals raw markdown under the cursor for editing.
render-markdown is kept **installed but `enabled = false`** as a one-line
fallback. Config: `lua/custom/plugins/markview.lua`,
`markview-smart-tables.lua`, and `render-markdown.lua` (disabled). Wide-data
authoring rules (Pillar 1) still apply — markview makes wide tables *readable*,
the rules keep them *rare*.
