# Neovim Configuration Playbook

This playbook contains reusable knowledge and procedures for working with this Neovim configuration. **Claude should check this playbook when working on Neovim customizations.**

## How to Use

When starting a task, ask Claude:
- "Check the playbook for..." or "Based on our playbook..."
- "Do we have a runbook for...?"
- "What do we know about...?" (for knowledge topics)

## Runbooks (How to do things)

| Runbook | Use When |
|---------|----------|
| [add-telescope-hidden-variant](runbooks/add-telescope-hidden-variant.md) | Adding a hidden-files variant of a Telescope picker |
| [debug-keymap-conflict](runbooks/debug-keymap-conflict.md) | Two keymaps fighting for the same key |

## Knowledge (How things work)

| Topic | Description |
|-------|-------------|
| [noice-message-routing](knowledge/noice-message-routing.md) | How Noice routes messages to views, filters, and the split/notify/skip options |
| [mini-sessions](knowledge/mini-sessions.md) | MiniSessions per-project setup, cwd-based paths, autoread/autowrite |
| [telescope-hidden-files](knowledge/telescope-hidden-files.md) | How to search hidden/ignored files in Telescope pickers |

## Adding New Entries

Use the templates:
- `runbooks/_template.md` - For procedures ("how to do X")
- `knowledge/_template.md` - For understanding ("how X works")

## Quick Reference

### Key Files
- `init.lua` - Main config (~1900 lines), plugin setup via lazy.nvim
- `after/plugin/keymaps.lua` - Custom keymaps (~30KB)
- `lua/custom/plugins/*.lua` - One file per plugin

### Common Patterns
- Leader key: `<space>`
- Uppercase variants often mean "with hidden files" (e.g., `<leader>sf` vs `<leader>sF`)
- `g<` recalls last message output (useful with Noice)
