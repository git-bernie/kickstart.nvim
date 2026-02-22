# Habit: Work on master, tag for stability

## Trigger

Starting a new session or considering whether to create a branch for this nvim config repo.

## Action

- Work directly on `master`. No monthly branches.
- Commit often with conventional commit messages (`feat:`, `fix:`, etc.).
- Tag stable states: `git tag stable-YYYY-MM` when things feel solid.
- Only create a branch for big multi-day experiments (e.g., swapping core plugins).

## Why

Monthly branches added ceremony without benefit for a single-person config repo. Merges were always fast-forwards, and uncommitted changes caused friction when switching branches. Tags provide the same safety net without the overhead.

## Example

```bash
# Normal workflow: commit directly on master
git add after/ftplugin/markdown.lua
git commit -m "feat(markdown): add treesitter-based folding"
git push

# After a productive session, tag it
git tag stable-2026-02
git push origin stable-2026-02

# If something breaks, compare or restore
git diff stable-2026-02
git checkout stable-2026-02 -- path/to/broken/file
```
