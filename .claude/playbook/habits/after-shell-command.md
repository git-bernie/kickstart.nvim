# Habit: After Shell Command

## Trigger

After running `:!` commands in Neovim (`:!ls`, `:!env`, etc.)

## Action

Remember: **`g<` recalls the output** if you close the split or need to see it again.

A notification reminder appears automatically after shell commands.

## Why

Shell output goes to a Noice split which is ephemeral - closing it loses the content. But Vim's built-in `g<` command recalls the last message output.

This is easy to forget, hence the automatic reminder.

## Example

```
:!env                    # Output appears in split
:q                       # Close split (output "gone")
g<                       # Output reappears!
```
