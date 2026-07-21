---
description: Audit this Neovim config for performance, correctness, keymap UX, tool coverage, and ecosystem currency
---

Audit this Neovim config and write a report. **Do not edit any config file.**
The only file you create is the report.

## Work profile

What this config exists to support. Check coverage in both directions: gaps in
tooling for work actually done, and plugins serving work no longer done.

- PHP / Laravel — `services`, `loanconnect-laravel`
- CakePHP 2 monolith
- SQL / dadbod
- Markdown-heavy documentation
- Python (learning)
- Lua — this config, and as a general embedded/scripting language elsewhere
- Bash / shell scripting — eternal and omnipresent
- Multi-repo git

Cross-check this list against `oldfiles-filetypes.txt`. If the histogram
disagrees with the profile, flag the drift — the profile is meant to
self-correct, not quietly go stale. Note that shell work is structurally
under-counted by the histogram (short edits, scattered files), so a low `.sh`
count is not evidence that bash tooling does not matter.

## Phase 1 — Measure

Run the evidence script and read every file it produces:

    ./bin/nvim-audit-evidence.sh

It prints the output directory on its last line. Read the files from there:
`startup-median.txt`, `startup-slowest.txt`, `startup-runs.txt`,
`startup-1.txt` through `startup-5.txt`, `lazy-stats.json`,
`lazy-plugins.json`, `hot-autocmds.json`, `hot-autocmds-sample.txt`,
`keymaps.json`, `tools.json`, `checkhealth.txt`, `health-issues.txt`,
`oldfiles-filetypes.txt`. Do not re-derive these numbers by reading config
source; the measurements are the ground truth and the config is the
hypothesis.

`hot-autocmds-sample.txt` records which source file was open when hot
autocmds were enumerated — a hot-autocmd measurement is only interpretable
alongside that filename, so state it next to the measurement in the report.

`tools.json` entries carry a `source` field (`mason`, `conform`, `lint`,
`lsp:<name>`, or a comma-joined combination) showing where each tool was
discovered — use it to say *why* a tool is expected to exist, not just
whether it does.

If the script's stderr contains the LSP-introspection warning ("no enabled
configs"), treat that as a caveat that must be stated in the report — the LSP
half of tool liveness is incomplete for that run, not all-clear.

## Phase 2 — Ecosystem currency

Guards against the config being good on its own terms while years behind.

**Local first — free, offline, and impossible to hallucinate:**
- `:help news` ships inside the installed nvim. Read it for what changed.
- `checkhealth vim.deprecated` output, and any `vim.deprecate()` warnings.

**Then external, only for what local cannot answer:**
- Is the installed nvim version still current? What landed since?
- Built-ins that may obsolete plugins here: `vim.pack` vs lazy.nvim,
  `vim.lsp.config`/`enable` vs mason-lspconfig wiring, native commenting,
  `vim.lsp.completion`, native snippets. For each, ask whether the built-in
  covers *this config's actual usage*. A built-in existing is not by itself
  an argument for switching.
- Kickstart upstream drift: what changed upstream worth adopting.
- Health of **load-bearing plugins only** — roughly 15: the LSP stack,
  treesitter, `blink.cmp`, the pickers (telescope, snacks), lazy.nvim, and
  anything else whose failure would stop work.

**Hard limits on Phase 2:**
- Plugin health is **metadata only**: the `archived` flag and `pushed_at`.
  Never clone a repo, fetch repo contents, walk a tree, or read issues.
  "Is this abandoned" is answerable from two fields.
- Do not health-check non-load-bearing plugins. A stale colorscheme is not
  a finding.
- **Every ecosystem claim must cite a fetched primary source with its URL.**
  Anything you cannot source is stated as "worth checking", never asserted.
  An uncited claim in this section is a bug in this audit.
- If the installed nvim version and the last report's researched version
  match AND the last report's ecosystem-research date is within 30 days of
  today, say so and skip the external work — print both the prior report's
  date and the nvim version it relied on so the reader can verify the skip
  was justified, not asserted. If either check fails (version moved, or the
  prior report is 30+ days old), do the external work.

## Report

Write `docs/nvim-audit-YYYY-MM-DD.md`. Record the nvim version and the
ecosystem-research date near the top so the next run can skip Phase 2.

Tier findings by **how much they should be trusted**, not by topic. Topics mix
evidence quality, and a wrong guess sitting next to a measured fact makes the
fact look like a guess too.

**Verified** — backed by a measurement or a cited source from this run. Show
the evidence inline: the startuptime line, the `executable()` result, the URL.

**Judgment call** — reasoned from the config, not measured. Architecture
opinions, redundancy, whether a plugin earns its keep.

**Experimental** — frequency-weighted keymap ergonomics: are the most-used
operations on the cheapest keys, and is prime real estate spent on things
never invoked? There is no keylogging here, so this is proxied from
leader-group population, git history as a signal of active work, and the work
profile. Mark it plainly as inference. Also check which of the previous
report's experimental suggestions were adopted, and drop any declined twice.

Within each tier, order by impact, name `file:line`, and where a fix is
mechanical include the exact diff — **unapplied**.

## Keymap standard

Two checks, held to deliberately different standards:

- **Hard check → Verified.** From `keymaps.json`: mnemonic coherence (does
  `<leader>s*` always mean search?), leader groups missing from which-key,
  orphan maps, maps whose target plugin is disabled, shadowed defaults.
  These are checkable facts.
- **Advisory → Experimental.** Ergonomic reach, as described above.

Prior art to build on rather than rediscover: `docs/search-keymaps-audit.md`.

## Existing knowledge — reference, do not rebuild

- `.claude/playbook/knowledge/lazy-nvim-performance.md`
- `.claude/playbook/knowledge/window-maximize-performance.md`
- `.claude/playbook/runbooks/debug-keymap-conflict.md`
- `.claude/playbook/runbooks/nvim-major-version-upgrade.md`

## Out of scope

- Applying any fix.
- Refactoring the config.
- Cloning or scanning plugin repository contents.
