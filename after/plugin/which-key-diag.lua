-- which-key trigger diagnostics + watchdog
--
-- WHY THIS EXISTS
-- which-key v3 does not hook the keypress stream. For every key prefix it
-- installs a real, *buffer-local*, `nowait` keymap whose desc is
-- "which-key-trigger"; pressing the prefix invokes that mapping, which opens
-- the popup. Your actual leader mappings are separate global mappings.
--
-- Every time you execute a mapping, which-key calls Triggers.suspend() which
-- DELETES those trigger mappings (otherwise feeding the keys back through
-- nvim_feedkeys would recurse forever), then re-installs them on a deferred
-- timer. If that re-install is ever skipped, the trigger stays gone: your
-- keymaps keep working (they're global and untouched) but no popup appears.
--
-- which-key's own self-heal poll (state.lua) only checks whether the Mode
-- object exists, NOT whether the trigger mappings still exist -- so that state
-- is permanent for the buffer until something forces a rebuild. Hence the
-- watchdog below.
--
-- Commands:
--   :WKDiag  -- report trigger health for the current buffer
--   :WKFix   -- force-rebuild triggers for the current buffer
--
-- Toggles:
--   vim.g.wk_watchdog = false  -- disable the watchdog entirely
--   vim.g.wk_watchdog_notify = false  -- repair silently (still logged to file)

local uv = vim.uv or vim.loop

local POLL_MS = 2000
local STRIKES_TO_REPAIR = 2 -- ~4s of confirmed breakage before repairing

local M = {
  repairs = 0,
  events = {}, -- in-memory ring of recent repairs, shown by :WKDiag
}

local logfile = vim.fn.stdpath 'cache' .. '/which-key-watchdog.log'

---Append a line to the persistent log so evidence survives a restart.
local function log(line)
  pcall(function()
    local fh = io.open(logfile, 'a')
    if fh then
      fh:write(os.date '%Y-%m-%d %H:%M:%S' .. ' ' .. line .. '\n')
      fh:close()
    end
  end)
end

---@return table? Buf, table? Triggers, table? Util, table? State
local function wk()
  if not package.loaded['which-key'] then
    return
  end
  local ok, Buf = pcall(require, 'which-key.buf')
  if not ok then
    return
  end
  return Buf, require 'which-key.triggers', require 'which-key.util', require 'which-key.state'
end

---Find trigger keys which-key believes it registered but that have no live
---mapping. A prefix that is shadowed by a real user mapping is NOT a fault --
---which-key deliberately skips those (see Triggers.is_mapped).
---@param mode table wk.Mode
---@return string[] missing
local function missing_triggers(mode)
  local missing = {}
  for _, node in ipairs(mode.triggers or {}) do
    local km
    pcall(vim.api.nvim_buf_call, mode.buf.buf, function()
      km = vim.fn.maparg(node.keys, mode.mode, false, true)
    end)
    local desc = km and km.desc or nil
    if desc and desc:find('which-key-trigger', 1, true) then
      -- healthy
    elseif km and not vim.tbl_isempty(km) and not (type(km.rhs) == 'string' and (km.rhs == '' or km.rhs:lower() == '<nop>')) then
      -- shadowed by a genuine mapping; which-key skipped it on purpose
    else
      missing[#missing + 1] = node.keys
    end
  end
  return missing
end

---@return table? mode, string? reason
local function current_mode()
  local Buf, _, Util = wk()
  if not Buf then
    return nil, 'which-key not loaded'
  end
  local buf = vim.api.nvim_get_current_buf()
  local entry = Buf.bufs[buf]
  if not entry then
    return nil, 'no which-key state for buffer ' .. buf
  end
  local mapmode = Util.mapmode()
  local mode = entry.modes[mapmode]
  if not mode then
    return nil, 'no which-key state for mode ' .. mapmode
  end
  return mode
end

---Force a full rebuild of triggers for the current buffer.
---@param why string
---@param missing? string[]
function M.repair(why, missing)
  local Buf, Triggers = wk()
  if not Buf then
    return false
  end
  local buf = vim.api.nvim_get_current_buf()
  -- Drop any stale suspend bookkeeping, then rebuild the Mode from scratch.
  for m in pairs(Triggers.suspended) do
    Triggers.suspended[m] = nil
  end
  Buf.clear { buf = buf }
  local mode = Buf.get()
  -- Buf.get() only *schedules* the attach on a deferred timer, so install the
  -- triggers synchronously here -- otherwise we'd report success before the
  -- mappings actually exist.
  if mode then
    Triggers.suspended[mode] = nil
    Triggers.update(mode)
  end

  M.repairs = M.repairs + 1
  local detail = string.format('buf=%d ft=%s missing=%s', buf, vim.bo[buf].filetype, table.concat(missing or {}, ' '))
  table.insert(M.events, 1, os.date '%H:%M:%S' .. ' ' .. why .. ' ' .. detail)
  M.events[11] = nil
  log(why .. ' ' .. detail)
  return true
end

--------------------------------------------------------------------------------
-- Watchdog
--------------------------------------------------------------------------------

local strikes = 0
local timer = uv.new_timer()

local function check()
  if vim.g.wk_watchdog == false then
    return
  end
  local Buf, Triggers, Util, State = wk()
  if not Buf then
    return
  end
  -- Don't interfere while the popup is up, during macros, or mid-suspend churn.
  if State.state ~= nil or Util.in_macro() then
    strikes = 0
    return
  end
  local mode = current_mode()
  if not mode then
    -- No Mode object: which-key's own 50ms poll rebuilds this case.
    strikes = 0
    return
  end
  local missing = missing_triggers(mode)
  if #missing == 0 then
    strikes = 0
    return
  end
  strikes = strikes + 1
  if strikes < STRIKES_TO_REPAIR then
    return
  end
  strikes = 0
  if M.repair('watchdog-repair', missing) and vim.g.wk_watchdog_notify ~= false then
    vim.notify(
      string.format('which-key: restored %d lost trigger(s) [%s]', #missing, table.concat(missing, ' ')),
      vim.log.levels.WARN,
      { title = 'which-key watchdog' }
    )
  end
end

timer:start(POLL_MS, POLL_MS, function()
  vim.schedule(function()
    pcall(check)
  end)
end)

vim.api.nvim_create_autocmd('VimLeavePre', {
  callback = function()
    pcall(function()
      timer:stop()
      timer:close()
    end)
  end,
})

--------------------------------------------------------------------------------
-- Commands
--------------------------------------------------------------------------------

vim.api.nvim_create_user_command('WKFix', function()
  local missing = {}
  local mode = current_mode()
  if mode then
    missing = missing_triggers(mode)
  end
  if M.repair('manual-WKFix', missing) then
    vim.notify(string.format('which-key: triggers rebuilt (%d were missing)', #missing), vim.log.levels.INFO, { title = 'which-key' })
  else
    vim.notify('which-key is not loaded', vim.log.levels.ERROR, { title = 'which-key' })
  end
end, { desc = 'Force-rebuild which-key triggers for the current buffer' })

vim.api.nvim_create_user_command('WKDiag', function()
  local Buf, Triggers, Util, State = wk()
  local out = {}
  local function add(...)
    out[#out + 1] = string.format(...)
  end

  if not Buf then
    vim.notify('which-key is not loaded', vim.log.levels.ERROR, { title = 'which-key' })
    return
  end

  local buf = vim.api.nvim_get_current_buf()
  add('buffer   : %d  ft=%s  bt=%s', buf, vim.bo[buf].filetype, vim.bo[buf].buftype)
  add('mapmode  : %s', Util.mapmode())
  add('timeout  : %s  timeoutlen=%d', tostring(vim.o.timeout), vim.o.timeoutlen)
  add('in_macro : %s', tostring(Util.in_macro()))
  add('state    : %s', State.state and 'ACTIVE (popup open)' or 'idle')
  add('suspended: %d mode(s)', vim.tbl_count(Triggers.suspended))
  add('registered triggers (all buffers): %d', vim.tbl_count(Triggers._triggers))

  -- The headline check: is the leader trigger actually live in this buffer?
  local leader = vim.g.mapleader == ' ' and '<Space>' or (vim.g.mapleader or '<Space>')
  local km = vim.fn.maparg(leader, 'n', false, true)
  local leader_ok = km and km.desc and km.desc:find('which-key-trigger', 1, true)
  add ''
  add('leader %s : %s', leader, leader_ok and 'OK (which-key-trigger, buffer=' .. tostring(km.buffer) .. ')' or 'MISSING -- popup will not open')

  local mode, reason = current_mode()
  if not mode then
    add ''
    add('no Mode object: %s', reason)
  else
    local missing = missing_triggers(mode)
    add('expected triggers for this buffer/mode: %d', #(mode.triggers or {}))
    if #missing == 0 then
      add 'all triggers live: OK'
    else
      add('MISSING %d trigger(s): %s', #missing, table.concat(missing, ' '))
      add('  -> run :WKFix (the watchdog will also repair within ~%ds)', (POLL_MS * STRIKES_TO_REPAIR) / 1000)
    end
  end

  add ''
  add('watchdog : %s  repairs this session: %d', vim.g.wk_watchdog == false and 'DISABLED' or 'on', M.repairs)
  add('log file : %s', logfile)
  if #M.events > 0 then
    add 'recent repairs:'
    for _, e in ipairs(M.events) do
      add('  %s', e)
    end
  end

  vim.notify(table.concat(out, '\n'), vim.log.levels.INFO, { title = 'which-key diagnostics' })
end, { desc = 'Report which-key trigger health for the current buffer' })

return M
