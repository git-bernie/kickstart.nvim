-- LoanConnect lookup-table picker (lenders, partners, products, ...).
--
-- Backend: bin/lc-lookup.php — dumps tables defined in
-- ~/.config/lc-lookup/manifest.json to JSON files in ~/.cache/lc-lookup/.
-- This module reads those JSON files and feeds snacks.picker.
--
-- Usage:
--   :LcLookup                 -- pick a table, then a row
--   :LcLookup lenders         -- jump straight to lenders
--   :LcLookupRefresh          -- async dump-all
--   :LcLookupRefresh lenders  -- async dump one
--
-- On row select: yanks "<id>" into register `c` and the system clipboard,
-- and notifies the chosen row. Same convention as lc-cyber.lua.

local M = {}

local script_path = vim.fn.stdpath 'config' .. '/bin/lc-lookup.php'

local function cache_dir()
  local override = vim.env.LC_LOOKUP_CACHE
  if override and override ~= '' then
    return override
  end
  local xdg = vim.env.XDG_CACHE_HOME
  if xdg and xdg ~= '' then
    return xdg .. '/lc-lookup'
  end
  return vim.fn.expand '~/.cache/lc-lookup'
end

---Read a cached lookup file and return its decoded payload, or nil + error.
---@param table_name string
---@return table|nil payload
---@return string|nil err
local function read_cache(table_name)
  local path = cache_dir() .. '/' .. table_name .. '.json'
  local fd = io.open(path, 'r')
  if not fd then
    return nil, 'no cache for "' .. table_name .. '" — run :LcLookupRefresh ' .. table_name
  end
  local raw = fd:read '*a'
  fd:close()
  local ok, decoded = pcall(vim.json.decode, raw)
  if not ok or type(decoded) ~= 'table' or type(decoded.rows) ~= 'table' then
    return nil, 'cache for "' .. table_name .. '" is malformed (' .. path .. ')'
  end
  return decoded, nil
end

---List available cached tables (filenames in cache dir).
---@return string[]
local function list_cached_tables()
  local dir = cache_dir()
  local out = {}
  for name, _ in vim.fs.dir(dir) do
    local stem = name:match '^(.+)%.json$'
    if stem then
      table.insert(out, stem)
    end
  end
  table.sort(out)
  return out
end

---Yank a value to register `c` and the system clipboard, with a notification.
---@param value string
---@param label string
local function yank_with_notify(value, label)
  vim.fn.setreg('c', value)
  vim.fn.setreg('+', value)
  vim.notify(string.format('%s = %s  (yanked to "c and clipboard)', label, value), vim.log.levels.INFO)
end

---Pick from a table's rows. Each row should have at least an id-ish and label-ish field;
---we autodetect them. Pass `field_id` / `field_label` in opts to override.
---@param table_name string
---@param opts? { field_id?: string, field_label?: string }
function M.pick(table_name, opts)
  opts = opts or {}
  local payload, err = read_cache(table_name)
  if not payload then
    vim.notify(err, vim.log.levels.ERROR)
    return
  end

  local rows = payload.rows
  if #rows == 0 then
    vim.notify('lc-lookup: "' .. table_name .. '" cache is empty', vim.log.levels.WARN)
    return
  end

  -- Autodetect id / label columns from the first row's keys, unless overridden.
  local sample = rows[1]
  local field_id = opts.field_id
  local field_label = opts.field_label
  if not field_id then
    for _, k in ipairs { 'id', 'ID', 'uuid' } do
      if sample[k] ~= nil then
        field_id = k
        break
      end
    end
  end
  if not field_label then
    for _, k in ipairs { 'name', 'label', 'title', 'display_name', 'company_name' } do
      if sample[k] ~= nil then
        field_label = k
        break
      end
    end
  end
  if not field_id or not field_label then
    vim.notify(
      ('lc-lookup: cannot autodetect id/label columns in "%s" (have: %s). Pass field_id/field_label.'):format(
        table_name,
        table.concat(vim.tbl_keys(sample), ', ')
      ),
      vim.log.levels.ERROR
    )
    return
  end

  local items = {}
  for _, row in ipairs(rows) do
    local id_str = tostring(row[field_id])
    local label_str = tostring(row[field_label] or '')
    table.insert(items, {
      id = id_str,
      label = label_str,
      text = id_str .. '  ' .. label_str, -- snacks.picker fuzzy-matches on `text`
      row = row,
    })
  end

  local refreshed = payload.refreshed_at and (' (refreshed ' .. payload.refreshed_at .. ')') or ''
  local title = ('lc-lookup: %s — %d rows%s'):format(table_name, #rows, refreshed)

  local ok, snacks = pcall(require, 'snacks')
  if not ok or not snacks.picker then
    -- Fallback: vim.ui.select. Always works, no plugin dependency.
    local choices = vim.tbl_map(function(it)
      return it.text
    end, items)
    vim.ui.select(choices, { prompt = title }, function(_, idx)
      if idx then
        yank_with_notify(items[idx].id, table_name .. '.' .. items[idx].label)
      end
    end)
    return
  end

  snacks.picker.pick {
    title = title,
    items = items,
    format = function(item)
      return {
        { ('%-8s '):format(item.id), 'Number' },
        { item.label, 'Identifier' },
      }
    end,
    confirm = function(picker, item)
      picker:close()
      if item then
        yank_with_notify(item.id, table_name .. '.' .. item.label)
      end
    end,
  }
end

---Pick a table first, then a row.
function M.pick_any()
  local tables = list_cached_tables()
  if #tables == 0 then
    vim.notify('lc-lookup: no cached tables in ' .. cache_dir() .. '. Run :LcLookupRefresh', vim.log.levels.WARN)
    return
  end
  if #tables == 1 then
    return M.pick(tables[1])
  end
  vim.ui.select(tables, { prompt = 'lc-lookup: which table?' }, function(choice)
    if choice then
      M.pick(choice)
    end
  end)
end

---Async refresh via `bin/lc-lookup.php`. Notifies on completion.
---@param table_name? string  nil => dump-all
function M.refresh(table_name)
  local cmd = { script_path }
  if table_name and table_name ~= '' then
    table.insert(cmd, 'dump')
    table.insert(cmd, table_name)
  else
    table.insert(cmd, 'dump-all')
  end

  vim.notify('lc-lookup: refreshing ' .. (table_name or 'all tables') .. ' ...', vim.log.levels.INFO)

  vim.system(cmd, { text = true }, function(out)
    vim.schedule(function()
      if out.code == 0 then
        vim.notify('lc-lookup: refresh OK\n' .. (out.stderr or ''):gsub('%s+$', ''), vim.log.levels.INFO)
      else
        vim.notify('lc-lookup: refresh FAILED (exit ' .. out.code .. ')\n' .. (out.stderr or out.stdout or ''), vim.log.levels.ERROR)
      end
    end)
  end)
end

---Smoke-test the DB connection synchronously.
function M.check()
  local result = vim.system({ script_path, 'check' }, { text = true }):wait()
  if result.code == 0 then
    vim.notify('lc-lookup check: ' .. (result.stderr or ''):gsub('%s+$', ''), vim.log.levels.INFO)
  else
    vim.notify('lc-lookup check FAILED:\n' .. (result.stderr or result.stdout or ''), vim.log.levels.ERROR)
  end
end

return M
