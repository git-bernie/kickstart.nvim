-- Resolve which claude binary to launch based on CLAUDE_CONFIG_DIR.
-- Matches the wrappers in ~/bin/claude-{work,personal} which set that env var.
local function resolve_command()
  local cfg = os.getenv 'CLAUDE_CONFIG_DIR'
  if not cfg or cfg == '' then
    return nil
  end
  local home = os.getenv 'HOME' or ''
  if cfg == home .. '/.contexts/work/.claude' then
    return 'claude-work'
  elseif cfg == home .. '/.claude' then
    return 'claude-personal'
  end
  return nil
end

local cached_command = nil

local function ensure_command(cb)
  local cmd = resolve_command() or cached_command
  if cmd then
    require('claude-code').config.command = cmd
    cb()
    return
  end
  vim.ui.select({ 'claude-work', 'claude-personal', 'claude' }, {
    prompt = 'CLAUDE_CONFIG_DIR not set — pick Claude context:',
  }, function(choice)
    if not choice then
      return
    end
    cached_command = choice
    require('claude-code').config.command = choice
    cb()
  end)
end

local function toggle()
  ensure_command(function()
    vim.cmd 'ClaudeCode'
  end)
end

return {
  'greggh/claude-code.nvim',
  dependencies = { 'nvim-lua/plenary.nvim' },
  keys = {
    { '<leader>cc', toggle, desc = 'Claude Code', mode = { 'n', 't' } },
    { '<C-.>', toggle, desc = 'Claude Code Toggle', mode = { 'n', 't' } },
  },
  opts = {
    command = resolve_command() or 'claude',
    window = {
      position = 'vsplit', -- botright, topleft, vertical/vsplit
      split_ratio = 0.5,
    },
    git = {
      use_git_root = true,
    },
    command_variants = {
      continue = '--continue',
      resume = '--resume',
      verbose = '--verbose',
    },
    keymaps = {
      toggle = {
        normal = false, -- owned by the wrapper above so the picker fallback fires
        -- terminal = '<C-o>',
        terminal = '<C-\\>',
        variants = {
          continue = '<leader>cC',
          verbose = '<leader>cV',
          resume = '<leader>cR',
        },
      },
    },
  },
}
