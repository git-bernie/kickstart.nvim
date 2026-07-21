# `/nvim-audit` — Design

**Date:** 2026-07-21
**Status:** Approved, ready for implementation plan

## What this is

A reusable slash command that reviews this Neovim config across five dimensions — performance, correctness, keymap/UX efficiency, tool coverage for real work, and currency with the wider Neovim ecosystem — and writes a dated report. It measures before it reasons, and it never edits the config.

The config drifts constantly (126 plugin files, 31 disabled, ~3000 lines across `init.lua` and `after/plugin/keymaps.lua`), so the review is inherently recurring. Encoding it once as a command means each run is cheap and the reports are diffable against each other.

## Contract

- **Location:** `.claude/commands/nvim-audit.md`, committed to this repo.
- **Read-only.** Runs commands and writes exactly one file: `docs/nvim-audit-YYYY-MM-DD.md`. Never edits `init.lua`, plugin files, or keymaps.
- Findings that warrant an edit include the exact diff, unapplied.
- Raw command output is written to the scratchpad so every finding can cite its evidence and the reasoning is checkable.

**Why report-only:** an audit that both diagnoses and edits across 126 plugin files has a bad failure mode — it "fixes" something unnoticed, and weeks later a keymap silently doesn't work. Separating diagnosis from action also makes the report a durable artifact to diff against next run, which is where the value compounds.

## Phase 1 — Evidence gathering

Specified as literal commands so every run collects the same measurements.

**Startup**
- `nvim --headless --startuptime` × 5; report median and slowest 15 entries.
- Five runs because a single run is noise-dominated by disk cache.

**Lazy stats**
- `require('lazy').stats()` — total vs loaded-at-startup, per-plugin load time.
- Catches plugins that claim lazy-loading but load eagerly.

**In-editor responsiveness**
- Enumerate every `CursorMoved` / `CursorHold` / `TextChanged` autocmd and every `BufEnter` hook — these fire constantly and are where lag actually lives. Prior art: the biscuits fix in `07dc16a`.
- Open a large real PHP file from `~/work`; time treesitter and LSP attach.

**Keymap reality**
- Full `:map` dump from headless nvim, parsed for conflicts, dead targets (maps pointing at disabled plugins), and leader groups missing from which-key.

**Health**
- `:checkhealth`, filtered to errors and warnings.

**Tool liveness**
- `vim.fn.executable()` for every LSP, formatter, and linter referenced anywhere in the config.
- Configured-but-absent is the recurring failure mode here (sqlfluff, April 2026). Static reading cannot catch it — the config looks perfect.

**Drift signal**
- `:oldfiles` filetype histogram, for cross-checking the work profile.

## Phase 2 — Ecosystem currency

Guards against the config being good on its own terms while three years behind. A kickstart fork is especially exposed: upstream keeps modernizing, this fork diverged.

**Local ground truth first** — free, offline, unhallucinatable:
- `:help news` ships inside the installed nvim; it is the authoritative 0.12 changelog.
- `:checkhealth vim.deprecated` and any `vim.deprecate()` warnings the config triggers.

**Then external:**
- **Version currency** — is 0.12.2 still current; what landed since.
- **Built-ins that may obsolete plugins** — `vim.pack` vs lazy.nvim, `vim.lsp.config`/`enable` vs mason-lspconfig wiring, native commenting, `vim.lsp.completion`, native snippets. For each, ask whether the built-in covers *this config's actual usage*. A built-in existing is not by itself an argument for switching.
- **Plugin health sweep — load-bearing plugins only.** Roughly 15, not all ~95: the LSP stack, treesitter, completion (`blink.cmp`), the pickers (telescope, snacks), lazy.nvim itself, and anything else whose failure would stop work. Abandonment only really hurts where the plugin is load-bearing; a stale colorscheme is not a finding. This is the check that would have caught nvim-treesitter's archival in advance.
- **Kickstart upstream drift** — what upstream changed since the fork that would be worth adopting.

**Sourcing requirement.** This is the phase most prone to confident, plausible, wrong claims — asserting a built-in exists, or misdescribing what `vim.pack` does. Every ecosystem claim must cite a fetched primary source (release notes, `news.txt`, the plugin's own repo) with the URL in the report. Anything unsourceable is stated as "worth checking", never asserted. **An uncited claim in this section is a bug in the audit.**

**Cost discipline.** Metadata only — the repo endpoint's `archived` flag and `pushed_at`, nothing more. Never clone a repo, never fetch repository contents, never walk a tree or issue list. A "has this been abandoned" question is answerable from two fields; anything beyond that is the audit wandering. With the sweep scoped to ~15 load-bearing plugins this phase is a handful of fetches, not a crawl.

The report records the nvim version and research date so a subsequent run can skip the ecosystem work entirely if nothing has moved.

## Report structure

Findings are tiered by **how much they should be trusted**, not by topic. Mixing evidence quality within a topic devalues the measured facts.

**Verified** — backed by a measurement or cited source from this run. Evidence shown inline: the startuptime line, the `executable()` result, the URL.

**Judgment call** — reasoned from the config, not measured. Architecture opinions, redundancy, whether a plugin earns its keep.

**Experimental** — frequency-weighted keymap ergonomics (see below), explicitly flagged as inference rather than measurement. Each run also checks which of the previous run's experimental suggestions were adopted, and drops any declined twice — so the tier earns or loses credibility over time instead of repeating itself.

Within each tier, findings are ordered by impact, name `file:line`, and include a ready-to-apply diff where the fix is mechanical.

## Keymap review standard

Two checks, deliberately held to different standards:

**Hard check (→ Verified)** — consistency and discoverability. Mnemonic coherence (does `<leader>s*` always mean search?), every leader group documented in which-key, no orphan or dead maps, no shadowed defaults that would be missed. These are checkable facts from the `:map` dump.

**Advisory (→ Experimental)** — frequency-weighted reach: are the most-used operations on the cheapest keys, and is prime real estate spent on things never invoked? Real frequency data would require keylogging that does not exist here, so this can only be proxied from leader-group population, git history as a signal of active work, and the stated work profile. Marked experimental for exactly this reason.

Prior art to build on rather than rediscover: `docs/search-keymaps-audit.md`.

## Work profile

An editable block inside the command file, since the config records what tooling exists but never what work it is for:

- PHP / Laravel — `services`, `loanconnect-laravel`
- CakePHP 2 monolith
- SQL / dadbod
- Markdown-heavy documentation
- Python (learning)
- Lua — this config, and increasingly as a general embedded/scripting language elsewhere
- Bash / shell scripting — eternal and omnipresent; the one that never drops off
- Multi-repo git

Coverage is checked in both directions: gaps in tooling for work actually done, and plugins serving work no longer done. The profile is then cross-checked against the `:oldfiles` filetype histogram, and drift is flagged — so it self-corrects rather than quietly going stale, which is the usual death of a hardcoded list.

## Existing material to reference, not rebuild

- `.claude/playbook/knowledge/lazy-nvim-performance.md`
- `.claude/playbook/knowledge/window-maximize-performance.md`
- `.claude/playbook/runbooks/debug-keymap-conflict.md`
- `.claude/playbook/runbooks/nvim-major-version-upgrade.md`
- `docs/search-keymaps-audit.md`

## Out of scope

- Applying any fix automatically.
- Cloning or scanning plugin repository contents. Health checks are metadata-only.
- Health-checking non-load-bearing plugins.
- Interactive interviewing at runtime — re-answering the same questions quarterly is the friction that would stop the audit being run.
- Refactoring the config as part of the audit.
