# Noice Cmdline Cursor Issue (Substitution Only)

## Status: Open / Unresolved / WONTFIX upstream

## Problem

In Kitty terminal, Noice's fake cursor renders **over** the last character instead of **after** it, but **only for substitution commands** (`:%s/xxx/yyy/g`).

**Works correctly:**
- `/search` - cursor after last character
- `:echo test` - cursor after last character

**Broken:**
- `:%s/foo/bar/g` - cursor covers last character

This is a known issue: https://github.com/folke/noice.nvim/issues/735 (closed as NOT_PLANNED)

## Root Cause

Noice uses `ui_attach` to render the cmdline UI with a "fake cursor". The combination of:
- Substitution command (`%s/`)
- `inccommand = 'split'` (live preview)
- Noice's fake cursor rendering

...causes the cursor positioning to be off by one character. The issue is specific to how Noice handles the substitution preview interaction.

See: https://github.com/folke/noice.nvim/discussions/596

## Attempted Fixes (All Failed)

| Fix | Result |
|-----|--------|
| `sidescrolloff = 4` in cmdline win_options | No effect |
| `NoiceCursor = { reverse = true }` | Shows two cursors (fake + real) |
| `NoiceCursor = { blend = 50-80 }` | No visible change |
| `NoiceCursor = { underline = true }` | Still block cursor |
| `NoiceCursor = { fg/bg explicit colors }` | No effect |
| `Cursor = { fg/bg explicit colors }` | No effect |
| `NoiceHiddenCursor = { blend = 100 }` | Real cursor still visible |
| `cmdline = { enabled = false }` | `:` becomes invisible |
| `view = 'cmdline'` (classic) | Same cursor issue |
| `format = { cmdline = { view = 'cmdline' } }` | No effect |
| `bottom_search = true`, `command_palette = false` | No effect |
| Disable blink.cmp cmdline | No effect (wasn't the cause) |

## Current Workaround

None. Living with the annoyance. The substitution command is functional, just visually awkward.

**Not worth trying:**
- Disabling `inccommand` - loses valuable live preview feature
- Disabling Noice entirely - loses all notification/message features

## Why Highlight Changes Don't Work

The NoiceCursor/Cursor highlight groups don't affect the substitution cmdline cursor. The fake cursor rendering for substitution mode appears to bypass these highlights entirely.

## Related

- Terminal: Kitty
- Plugin: folke/noice.nvim
- Neovim setting: `inccommand = 'split'`
- Upstream issue: https://github.com/folke/noice.nvim/issues/735 (WONTFIX)
