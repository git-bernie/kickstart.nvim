# Habit: After Fixing Issue

## Trigger

After debugging and fixing any non-trivial issue in Neovim config.

## Action

1. **Document in system-fixes** (`~/work/dotfiles/system-fixes/`)
   - Create folder with kebab-case name
   - Add README.md with: symptom, debugging steps, root cause, solution
   - Update index

2. **Add to playbook** if it's a reusable pattern:
   - Knowledge: if it explains how something works
   - Runbook: if it's a repeatable procedure
   - Habit: if it's a behavior to remember

3. **Commit both repos** if applicable

## Why

Future-you will encounter similar issues. Having documentation means:
- Faster resolution next time
- Understanding of root cause, not just the fix
- Searchable knowledge base

## Example

Fixed "shell output invisible" in Noice:
1. Created `system-fixes/neovim-noice-sessions/` with full debugging story
2. Added `knowledge/noice-message-routing.md` for reusable understanding
3. Added this habit to remember the pattern
