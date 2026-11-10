# Work Log — nvim-kickstart

> Chronological record of research, builds, decisions, and deploys.
> Newest entries first. Updated each session.
>
> **Categories:** `research` `build` `deploy` `strategy` `content` `config` `fix` `ops`
>
> Started 2026-11-10, reconstructed from git for Oct–Nov 2026. Older history: `git log` (531 commits since 2022-06-23) and the weekly summaries in `.remember/archive.md`.

---

## Open Threads

### Verify the Claude → kitty tab alert end to end
- **Status:** Built, installed and unit-tested against real tabs (personal + work). The real `Notification` event has not yet been seen to fire it.
- **Started:** 2026-11-10
- **Next Step:** Restart running Claude sessions (or `/hooks` in each). Let one sit idle about a minute: its tab should go red with `🔔`, then clear when you answer.
- **Reference:** `~/work/dotfiles/system-fixes/claude-kitty-tab-alert/README.md`; dotfiles `31844b4`…`5eec12f`

### Unpin nvim-scrollbar from `refactor/v2` (after 2026-11-16)
- **Status:** Waiting on upstream: v2 merges to `main` that day.
- **Started:** 2026-10-23
- **Next Step:** Delete `branch = 'refactor/v2'` in `lua/custom/plugins/scrollbar.lua`, `:Lazy update nvim-scrollbar`, and confirm lazy-lock shows `"branch": "main"`.
- **Reference:** `9aa3049`; memory `todo.md`

### CopilotChat intermittent "Model not found"
- **Status:** Traced to 300 s caching of failed model fetches; root cause unknown. Model is now `claude-sonnet-5.5`.
- **Started:** 2026-10 (week of 10-12)
- **Next Step:** If it recurs on 5.5, capture `:messages` + `:CopilotChatModels` at the moment it happens.
- **Reference:** `lua/custom/plugins/copilot-chat.lua`; `32231de`

---

## 2026-11-10

### `build` bookmarks.nvim with `<leader>b` keymaps
Installed LintaoAmons/bookmarks.nvim (pinned `v4.0.0`, sqlite, snacks picker, `VeryLazy` so signs show at startup). Eleven maps share `<leader>b` with buffer nav (`bn`/`bp` untouched): `bm` mark/rename/toggle, `bo` picker, `bt` tree, `bl`/`bN` lists, `bd` desc, `bg` grep, `bc` commands, `bi` info, `bj`/`bk` next/prev. It avoids `m{a-z}` (Vim marks) and `]b`/`[b` (nvim 0.11+ buffer nav). DB backup is enabled in `setup()` opts; it was first misplaced on the lazy spec, where it was silently ignored. Verified headless: 13 `<leader>b*` maps, all commands exist, `backup.enabled = true`.
- **Commits:** `1fa2182`
- **Artifact:** `lua/custom/plugins/bookmarks.lua`; `.claude/playbook/knowledge/keymap-collision-avoid.md`
- **Status:** Complete, pushed

### `config` blink `<C-k>` digraphs, CopilotChat 5.5 + actions, plugin update
- **blink:** insert-mode `<C-k>` freed for native digraphs; signature help moved to `<C-s>` (`f6b3c2c`).
- **CopilotChat:** model `claude-sonnet-4.6` → `5.5`; visual-mode variants of `co`/`ct`; new `ce` explain, `cf` fix, `cr` review; `auto_insert_mode`; `make tiktoken` only when `make` exists. Removed a duplicated `cr` line during review (`32231de`).
- **tiny-cmdline:** explicit `enabled = true`, which changes nothing; the popup was never actually disabled in HEAD (`af469d0`).
- **Plugin update:** ~30 plugins updated in lazy-lock (`8794022`). Not individually exercised.
- **CLAUDE.md:** `<leader>b` count 2 → 13 and `<leader>c` 13 → 16 (`da774ec`). The 16 is the audit's figure plus 3, not a recount: buffer-local maps (`ca` LSP, `cv` php) don't show at a bare startup.
- **Commits:** `f6b3c2c` `32231de` `af469d0` `8794022` `da774ec`
- **Status:** Complete, pushed. Verified headless: all 10 CopilotChat maps present, blink keymap values, no startup errors.

### `build` Claude Code → kitty tab alert (dotfiles)
"Claude is waiting for your input" popups don't say which tab. A `Notification` hook now turns the session's own kitty tab red with `🔔 <title>` via `kitten @ set-tab-title`/`set-tab-color --match window_id:$KITTY_WINDOW_ID`. Five clear hooks restore it: `UserPromptSubmit`, `PostToolUse`, `PostToolUseFailure`, `PermissionDenied`, `SessionEnd`. Hand-set tab titles are saved and restored. It fails safe outside kitty. After an automated security review it was hardened: private 0700 state dir, no `/tmp` fallback, symlink/owner checks, numeric ids only. Covers work sessions too, since they share `settings.json` and `hooks/` by symlink. Decision: clear on prompt/tool events rather than on tab focus, because glancing at a tab shouldn't drop the reminder.
- **Commits:** dotfiles `31844b4` `f5f46fb` `5eec12f`
- **Artifact:** `~/work/dotfiles/system-fixes/claude-kitty-tab-alert/`; `~/work/dotfiles/.claude/hooks/kitty-tab-alert.sh`
- **Status:** Installed; end-to-end check pending (Open Threads)

## 2026-11-06

### `config` markview keeps tables rendered in Normal mode
Dropped `'n'` from `hybrid_modes`.
- **Commits:** `1d2dd0c`
- **Status:** Complete

## 2026-10-23

### `config` nvim-scrollbar v2 migration
Migrated to the v2 config on the `refactor/v2` branch and removed the hlslens bridge.
- **Commits:** `9aa3049`
- **Status:** Complete; unpin pending (Open Threads)

## 2026-10-20

### `config` systemd-lsp with content-sniffed unit filetype
Added the JFryy systemd-lsp server to `servers` + Mason, with a content-sniffing filetype rule for unit files.
- **Commits:** `dc35862`
- **Status:** Complete
