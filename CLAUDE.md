# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a heavily customized fork of **kickstart.nvim** - a Neovim configuration. The main `init.lua` (~1,900 lines) is the heart of the config, with plugins organized in `lua/custom/plugins/` (100+ plugin files).

## Key Commands

```bash
# Format Lua code (required before commits)
stylua .

# Check formatting (CI runs this)
stylua --check .

# In Neovim - check plugin status
:Lazy

# In Neovim - validate dependencies
:checkhealth
```

## Architecture

### Plugin Organization

- **`init.lua`** - Main config: options, keymaps, autocmds, and lazy.nvim setup
- **`lua/kickstart/plugins/`** - Core kickstart plugins (debug, autopairs, gitsigns, etc.)
- **`lua/custom/plugins/`** - Custom plugins (one file per plugin, auto-imported by lazy.nvim)
- **`after/plugin/keymaps.lua`** - Extensive custom keymaps (~30KB)
- **`after/ftplugin/{filetype}.lua`** - Filetype-specific settings (php.lua, json.lua, markdown.lua, etc.)

### Adding a New Plugin

Create `lua/custom/plugins/{name}.lua` returning a plugin spec:
```lua
return {
  'owner/plugin-name',
  event = 'VimEnter',        -- lazy load trigger
  keys = { ... },            -- or lazy load on keypress
  opts = { ... },            -- configuration
}
```

Lazy.nvim auto-imports all files in `lua/custom/plugins/` via `{ import = 'custom.plugins' }` in init.lua.

### Key Mapping Conventions

- **Leader:** `<space>`
- **Leader groups:** `<leader>c` (code), `<leader>d` (document), `<leader>f` (file/fzf), `<leader>g` (git), `<leader>s` (search), `<leader>t` (toggle), `<leader>w` (workspace)
- **Window navigation:** `<C-hjkl>`

### Project-Local Config

Files named `.nvim.lua` or `.nvimrc` in project root are automatically sourced at startup for per-project settings.

## Formatting

Uses `.stylua.toml`: 160 char width, 2-space indent, single quotes preferred. GitHub Actions checks formatting on PRs.

## Branch Info

- Current branch: `jan-2026`
- Main branch for PRs: `master`

## Jira CLI (acli) with Markdown

When updating Jira issue descriptions or comments with formatted content, use the markdown-to-ADF workflow.

### Available Tools

**`md2adf`** - Convert markdown to Atlassian Document Format (ADF) JSON
```bash
md2adf file.md                    # from file
echo '# Heading' | md2adf         # from stdin
```

**`jira-update-desc`** - Update a Jira issue description from markdown
```bash
jira-update-desc ISSUE-KEY file.md          # from file
echo '# Description' | jira-update-desc ISSUE-KEY   # from stdin
```

**`jira-add-comment`** - Add a comment to a Jira issue from markdown
```bash
jira-add-comment ISSUE-KEY file.md          # from file
echo '# Comment' | jira-add-comment ISSUE-KEY       # from stdin
```

### Why These Scripts Exist

The `acli` command's `--description-file` flag does NOT work with raw ADF JSON. You must use `--from-json` with a payload like:

```json
{
  "issues": ["ISSUE-KEY"],
  "description": { "version": 1, "type": "doc", "content": [...] }
}
```

The `jira-update-desc` script handles this automatically.

### Notes

- `jira-update-desc` uses `acli` with `--from-json` (required for ADF descriptions)
- `jira-add-comment` uses the REST API directly (acli doesn't handle ADF for comments)
- Both scripts read JIRA_API_TOKEN from `.env` files (project first, then nvim config)

### Plain Text Alternative

For simple updates without formatting, plain text works directly:
```bash
acli jira workitem edit --key ISSUE-KEY --description "Plain text description" --yes
```

### Viewing Issues

```bash
acli jira workitem view ISSUE-KEY
```
