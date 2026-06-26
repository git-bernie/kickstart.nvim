# Markdown Readability & Width Implementation Plan

> **STATUS (2026-06-26): Task 1 (Pillar 2) was implemented and then REVERTED.**
> The `markdown-table-wrap.nvim` approach was abandoned after live testing —
> see the **Outcome** section of the design spec
> (`2026-06-26-markdown-readability-width-design.md`) for the four reasons.
> Pillar 1 (authoring rules) shipped to `~/.claude/CLAUDE.md`; Pillar 3 (PDF)
> pre-existing. Task 1 below is retained as a record, not as work to do.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make wide markdown tables readable in Neovim (and keep them readable in PDF) by fixing how Claude authors markdown and by adding an in-editor wide-table wrapping fallback.

**Architecture:** Hybrid. Pillar 1 adds authoring rules to the global `~/.claude/CLAUDE.md` so Claude prefers a record layout over over-wide tables. Pillar 2 adds `markdown-table-wrap.nvim` to this repo as a viewer fallback that wraps any wide table to the window, disables only `render-markdown.nvim`'s table renderer to avoid double-drawing, and rebinds `<leader>tt` from vim-table-mode's unused "tableize" to the new wrap toggle. Pillar 3 (PDF) is already solved by the existing `md2pdf` tooling and needs no code.

**Tech Stack:** Neovim ≥ 0.10, Lua, lazy.nvim, `ice345/markdown-table-wrap.nvim`, `MeanderingProgrammer/render-markdown.nvim`, `dhruvasagar/vim-table-mode`, stylua.

## Global Constraints

- Neovim ≥ 0.10 (required by `markdown-table-wrap.nvim`).
- `stylua --check .` must pass: 160 char width, 2-space indent, single quotes preferred (`.stylua.toml`).
- Lua strings use single quotes to match the codebase.
- Do **not** auto-commit dotfiles (`~/.claude/...`); stage Pillar 1 for Bernie's next dotfiles batch (Bernie's standing rule).
- nvim-repo commits go on branch `feat/markdown-readability-width` (already checked out).

---

### Task 1: nvim wide-table viewer fallback (Pillar 2)

This is one cohesive deliverable: the plugin, the render-markdown table-renderer disable, the vim-table-mode keymap move, and the `<leader>tt` toggle binding only make sense together. Verification is manual in nvim plus stylua.

**Files:**
- Create: `lua/custom/plugins/markdown-table-wrap.lua`
- Modify: `lua/custom/plugins/render-markdown.lua` (add `pipe_table = { enabled = false }` to `opts`)
- Modify: `lua/custom/plugins/vim-table-mode.lua` (add `init` that moves `g:table_mode_tableize_map`)
- Modify: `after/ftplugin/markdown.lua` (add buffer-local `<leader>tt` keymap)
- Test fixture (scratch, not committed): `/tmp/claude-1000/-home-bernie--config-nvim-kickstart/7a687ba3-4369-41d1-bd16-b92ecee6b2f4/scratchpad/wide-table-test.md`

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces: a markdown buffer-local normal-mode mapping `<leader>tt` → `:MarkdownTableTogglePreview`; the user command `:MarkdownTableTogglePreview` (provided by the plugin); `<leader>tT` now triggers vim-table-mode tableize.

- [ ] **Step 1: Create the plugin spec file**

Create `lua/custom/plugins/markdown-table-wrap.lua`:

```lua
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
```

- [ ] **Step 2: Disable render-markdown's table renderer**

In `lua/custom/plugins/render-markdown.lua`, add `pipe_table = { enabled = false },` inside `opts`. After the edit `opts` reads:

```lua
  opts = {
    latex = { enabled = false },
    file_types = { 'markdown', 'vimwiki' },
    only_render_image_at_cursor = true,
    -- markdown-table-wrap.nvim owns pipe tables; disable this renderer so the
    -- two do not double-draw the same lines.
    pipe_table = { enabled = false },
  },
```

- [ ] **Step 3: Move vim-table-mode's tableize off `<leader>tt`**

Replace the entire contents of `lua/custom/plugins/vim-table-mode.lua` with:

```lua
return {
  'dhruvasagar/vim-table-mode',
  init = function()
    -- Free <leader>tt for markdown-table-wrap's toggle. vim-table-mode's
    -- "tableize" command (unused) defaults to <leader>tt; park it on <leader>tT
    -- rather than '' (an empty value produces a broken xnoremap at load).
    vim.g.table_mode_tableize_map = '<Leader>tT'
  end,
}
```

- [ ] **Step 4: Bind `<leader>tt` to the wrap toggle (markdown buffers only)**

In `after/ftplugin/markdown.lua`, add the following after the `<BS>` "Go back" mapping (around line 37):

```lua
-- Toggle wide-table wrapping (markdown-table-wrap.nvim). Buffer-local because
-- the :MarkdownTableTogglePreview command only exists in markdown buffers.
vim.keymap.set('n', '<leader>tt', '<cmd>MarkdownTableTogglePreview<CR>', { buffer = true, desc = '[T]oggle [t]able wrap', silent = true })
```

- [ ] **Step 5: Format check**

Run: `stylua --check .`
Expected: exits 0, no diff reported. If it reports the new/edited files, run `stylua .` and re-check.

- [ ] **Step 6: Install the plugin**

Run: `nvim --headless "+Lazy! sync" +qa`
Expected: completes without error; `markdown-table-wrap.nvim` appears installed. Then confirm it is on disk:
Run: `ls ~/.local/share/nvim/lazy/ | grep -i table`
Expected: lists `markdown-table-wrap.nvim` (and `vim-table-mode`).

- [ ] **Step 7: Create the wide-table test fixture**

Write this to the scratchpad path (not committed):
`/tmp/claude-1000/-home-bernie--config-nvim-kickstart/7a687ba3-4369-41d1-bd16-b92ecee6b2f4/scratchpad/wide-table-test.md`

```markdown
# Wide table test

| Lender Name | Interest Rate APR | Minimum Credit Score | Maximum Loan Amount | Funding Time | Notes Column Here |
|-------------|-------------------|----------------------|---------------------|--------------|-------------------|
| Fairstone Financial Services | 19.99% | 560 | $50,000 | 1-3 business days | Established lender |
| Spring Financial Group | 9.99% | 600 | $35,000 | same day funding | Online only product |

Some prose after the table to confirm prose still soft-wraps normally and the table no longer overflows the window edge when this file is opened.
```

- [ ] **Step 8: Manual verification in nvim**

Open the fixture: `nvim <scratchpad>/wide-table-test.md`

Verify, in order:
1. The table renders **wrapped to the window** (cells break onto multiple lines; no content runs off the right edge). Expected: PASS — wrapped Unicode table.
2. render-markdown does **not** also draw its own separate table grid (no doubled/overlapping table). Expected: PASS — single table.
3. Press `<leader>tt`. Expected: the wrapped preview toggles off (raw pipe source shows), press again to toggle back on.
4. `:messages` is free of errors from the plugins. Expected: clean.
5. The prose paragraph below the table still soft-wraps at the window edge (prose mode unaffected). Expected: PASS.

If any check fails, stop and diagnose before committing (use superpowers:systematic-debugging).

- [ ] **Step 9: Regression check on existing keymaps**

In the open markdown buffer:
1. `<leader>tw` still toggles `wrap` (existing mapping). Expected: PASS.
2. `<leader>tp` still toggles prose mode. Expected: PASS.
3. `<leader>tT` triggers vim-table-mode tableize on a selected CSV-ish block (the moved mapping). Expected: tableize runs (or at minimum does not error / is no longer on `tt`).

- [ ] **Step 10: Commit**

```bash
git add lua/custom/plugins/markdown-table-wrap.lua lua/custom/plugins/render-markdown.lua lua/custom/plugins/vim-table-mode.lua after/ftplugin/markdown.lua lazy-lock.json
git commit -m "feat(markdown): wrap wide tables in-editor via markdown-table-wrap.nvim

Add ice345/markdown-table-wrap.nvim to wrap wide table cells to the window
(max_col_width 36 for an 80-col budget). Disable render-markdown's pipe_table
renderer so the two do not double-draw. Move vim-table-mode tableize from
<leader>tt to <leader>tT and bind <leader>tt to :MarkdownTableTogglePreview
(buffer-local in markdown).

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

Note: only stage `lazy-lock.json` if `Lazy sync` changed it AND the diff is limited to adding the new plugin pin. If the lock file has unrelated pre-existing changes, commit `lazy-lock.json` separately or leave it — do not bundle unrelated pin churn into this commit.

---

### Task 2: Authoring rules in global CLAUDE.md (Pillar 1)

Separate deliverable in a different repo (`~/.claude/`), so it is its own task and is **staged, not committed** here per Bernie's dotfiles rule.

**Files:**
- Modify: `~/.claude/CLAUDE.md` (add a "Markdown Width & Tables" subsection under `## Preferences`)

**Interfaces:**
- Consumes: nothing.
- Produces: standing authoring guidance Claude reads each session.

- [ ] **Step 1: Add the rules subsection**

Append this subsection under the `## Preferences` section of `~/.claude/CLAUDE.md` (after the existing "Python Learning Mode" subsection):

```markdown
### Markdown Width & Tables

When generating markdown (which Bernie reads in Neovim, secondarily as PDF),
keep it readable at an **80-column** budget. Follow unless told otherwise this
session.

- **Tables only when they fit.** Use a markdown table only when it is **≤4
  columns** *and* renders within ~80 columns with terse cells. Otherwise use a
  **record layout**: a bold label or small heading per row, then `field: value`
  bullets. Record layout wraps cleanly in Neovim and PDF and has no width limit.

  ```markdown
  ### Fairstone
  - **Rate:** 19.99%
  - **Min score:** 560
  - **Max amount:** $50,000
  ```

- **Terse cells.** No multi-sentence content in a table cell (~15 chars target);
  push explanation to prose or footnotes *below* the table.
- **Don't hard-wrap prose.** One paragraph = one line; Bernie's Neovim prose
  mode soft-wraps it. Tables are the only width-governed element.
- **Escalation for unavoidable wide tables:** the PDF path (`md2pdf`) wraps
  cells, and Neovim wraps them via `<leader>tt`
  (`markdown-table-wrap.nvim`). See
  `~/.claude/playbook/knowledge/pdf-conversion.md` ("Wide tables").
```

- [ ] **Step 2: Stage for the dotfiles batch (do not commit)**

Run: `git -C ~/.claude add CLAUDE.md && git -C ~/.claude status --short CLAUDE.md`
Expected: shows `M  CLAUDE.md` staged. Leave it staged; tell Bernie it is ready for his next dotfiles batch commit. Do **not** run `git commit` in the dotfiles repo.

---

## Self-Review

**1. Spec coverage:**
- Pillar 1 (authoring rules, 80-col, table-vs-record, terse cells, no hard-wrap prose, escalation pointer) → Task 2. ✓
- Pillar 2 (plugin, disable render-markdown pipe_table, free `<leader>tt`, `max_col_width=36`, toggle) → Task 1. ✓
- Pillar 3 (PDF) → reference only, no task, as designed. ✓
- Cross-repo rollout (nvim commit on branch; dotfiles staged not committed) → Task 1 Step 10 + Task 2 Step 2. ✓
- Verification (Lazy sync, wide-table renders wrapped, toggle, no regression, stylua) → Task 1 Steps 5–9. ✓

**2. Placeholder scan:** No TBD/TODO/"handle edge cases"/"similar to". All code shown verbatim. ✓

**3. Type/name consistency:** Command `:MarkdownTableTogglePreview` used consistently in plugin opts context, ftplugin keymap, and commit message. `g:table_mode_tableize_map` value `<Leader>tT` consistent between vim-table-mode.lua and the regression check. `max_col_width = 36` consistent with spec. ✓

---

## Notes

- TDD note: nvim config has no unit-test harness; "tests" here are concrete manual nvim verifications plus the `stylua --check` CI gate, which is the appropriate ground-truth for this change.
- If Step 8 check 2 shows a doubled table, re-confirm Step 2 actually disabled `pipe_table` and that `:Lazy reload render-markdown.nvim` (or a restart) picked it up.
