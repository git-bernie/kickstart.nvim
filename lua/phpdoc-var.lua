-- PHPDoc @var generator for the variable on the current line (intelephense-backed).
--
-- Usage:
--   :lua require('phpdoc-var').annotate()
--   (mapped to <leader>cv in after/ftplugin/php.lua — normal mode, PHP buffers)
--
-- What it does: with the cursor anywhere on a `$x = ...;` line, asks
-- intelephense (via textDocument/hover) for the inferred type of the assignment
-- target, then inserts `/** @var Type $x */` on the line above — shortening any
-- namespaced class to its basename and adding a `use ...;` when one is missing.
--
-- Backend: the running `intelephense` LSP client. No external script.
--
-- Known limits (v1, by design):
--   * Hover position uses a byte column ~= UTF-16 char column. Correct for
--     ASCII code (the norm); non-ASCII text BEFORE the variable on the line
--     could misplace the request by a few columns.
--   * If a short class name already resolves to a DIFFERENT class via an
--     existing `use`, that type is kept fully-qualified inline (no bad import).
--   * If the type can't be parsed, falls back to `/** @var mixed $x */` plus a
--     warning notification, so you get an editable scaffold rather than silence.

local M = {}

---Find the assignment-target variable on `line`.
---Prefers `$name =` (the LHS of an assignment); falls back to the first `$name`.
---@param line string
---@return string|nil name  Variable name without the leading `$`
---@return integer|nil col   0-indexed byte column of the `$`
local function find_variable(line)
  -- Leftmost `$name` immediately followed by `=` (but not `==`, `=>`).
  local s = line:find '%$[%w_]+%s*=[^=>]'
  if not s then
    -- Fall back to the first `$name` anywhere on the line.
    s = line:find '%$[%w_]+'
  end
  if not s then
    return nil, nil
  end
  local name = line:sub(s):match '^%$([%w_]+)'
  return name, s - 1 -- 0-indexed column of the `$`
end

---Extract the type string preceding `$name` from an intelephense hover payload.
---Hover renders a ```php``` fence whose content looks like `Type $name`.
---@param hover table|nil  LSP Hover result
---@param name string
---@return string|nil type  e.g. "int", "App\\Models\\User", "string[]", "A|B"
local function parse_hover_type(hover, name)
  if not hover or not hover.contents then
    return nil
  end
  local contents = hover.contents
  -- contents may be a MarkupContent {kind, value}, a string, or a list.
  local text
  if type(contents) == 'table' and contents.value then
    text = contents.value
  elseif type(contents) == 'string' then
    text = contents
  elseif type(contents) == 'table' then
    local parts = {}
    for _, c in ipairs(contents) do
      parts[#parts + 1] = type(c) == 'table' and (c.value or '') or tostring(c)
    end
    text = table.concat(parts, '\n')
  end
  if not text or text == '' then
    return nil
  end

  -- Pull the first ```php ... ``` fenced block; else use the raw text.
  local fenced = text:match '```php%s*(.-)%s*```' or text:match '```%s*(.-)%s*```' or text
  -- Look for `<type> $name` on any line of the fence.
  for chunk in vim.gsplit(fenced, '\n', { plain = true }) do
    local ty = chunk:match('^%s*(.-)%s+%$' .. name .. '%s*$')
    if ty and ty ~= '' then
      return ty
    end
  end
  return nil
end

---Collect the `use` imports already present near the top of the buffer.
---@return table<string,string>  map of shortName(lower) -> FQN (no leading `\`)
---@return integer               0-indexed line AFTER the last `use` (insert point)
---@return integer               0-indexed fallback insert point (after namespace/php header)
local function scan_header(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, 200, false)
  local imports = {}
  local last_use = nil -- 0-indexed line of the last `use ...;`
  local after_namespace = nil
  local after_header = 0 -- after `<?php` / `declare(...)`
  for i, line in ipairs(lines) do
    local idx = i - 1 -- 0-indexed
    local fqn = line:match '^%s*use%s+([%w_\\]+)%s*;'
    if fqn then
      fqn = fqn:gsub('^\\', '')
      local short = fqn:match '([%w_]+)$'
      if short then
        imports[short:lower()] = fqn
      end
      last_use = idx
    elseif line:match '^%s*namespace%s+[%w_\\]+%s*;' then
      after_namespace = idx + 1
    elseif line:match '^%s*<%?php' or line:match '^%s*declare%s*%(' then
      after_header = idx + 1
    elseif line:match '^%s*class%s' or line:match '^%s*interface%s' or line:match '^%s*trait%s' then
      break -- stop at the first type declaration; imports live above it
    end
  end
  local use_insert = (last_use ~= nil) and (last_use + 1) or (after_namespace or after_header)
  return imports, use_insert, (after_namespace or after_header)
end

---Shorten a type string and compute the `use` statements it needs.
---@param ty string                       raw type, e.g. "App\\Models\\User[]|null"
---@param imports table<string,string>    existing shortName(lower) -> FQN
---@return string                         shortened type for the docblock
---@return string[]                       new `use FQN;` lines to insert
local function shorten_and_import(ty, imports)
  local new_uses = {}
  local seen = {}
  -- Match any backslash-qualified name (leading `\` optional, >=1 separator).
  local shortened = ty:gsub('\\?[%w_]+[%w_\\]*', function(token)
    if not token:find '\\' then
      return token -- built-in / already-short: leave as-is, no import
    end
    local fqn = token:gsub('^\\', '')
    local short = fqn:match '([%w_]+)$'
    if not short then
      return token
    end
    local key = short:lower()
    local existing = imports[key]
    if existing and existing ~= fqn then
      return token -- short name taken by a different class: keep FQN inline
    end
    if not existing and not seen[fqn] then
      seen[fqn] = true
      new_uses[#new_uses + 1] = 'use ' .. fqn .. ';'
      imports[key] = fqn -- reserve within this call too
    end
    return short
  end)
  return shortened, new_uses
end

---Main entry point: annotate the variable on the current line.
function M.annotate()
  local bufnr = vim.api.nvim_get_current_buf()
  local win = vim.api.nvim_get_current_win()
  local row = vim.api.nvim_win_get_cursor(win)[1] - 1 -- 0-indexed assignment line
  local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ''

  local name, col = find_variable(line)
  if not name then
    vim.notify('phpdoc-var: no $variable found on this line', vim.log.levels.WARN)
    return
  end

  local clients = vim.lsp.get_clients { bufnr = bufnr, name = 'intelephense' }
  if #clients == 0 then
    vim.notify('phpdoc-var: intelephense is not attached to this buffer', vim.log.levels.WARN)
    return
  end
  local client = clients[1]

  local params = {
    textDocument = vim.lsp.util.make_text_document_params(bufnr),
    position = { line = row, character = col + 1 }, -- point at the name char, not `$`
  }

  client:request('textDocument/hover', params, function(err, result)
    local ty = (not err) and parse_hover_type(result, name) or nil

    local imports, use_insert = scan_header(bufnr)
    local new_uses = {}
    if ty then
      ty, new_uses = shorten_and_import(ty, imports)
    else
      ty = 'mixed'
      vim.notify('phpdoc-var: could not infer a type; inserted `mixed` scaffold', vim.log.levels.WARN)
    end

    local indent = line:match '^%s*' or ''
    local docblock = indent .. '/** @var ' .. ty .. ' $' .. name .. ' */'

    -- Idempotent: replace an existing @var docblock directly above, if present.
    local prev = vim.api.nvim_buf_get_lines(bufnr, row - 1, row, false)[1]
    local replace = prev ~= nil and prev:match '^%s*/%*%*.-@var.-%*/%s*$' ~= nil

    -- Insert docblock first (lower in the file), then `use` lines above it, so
    -- neither shifts the other's target line before it is written.
    if replace then
      vim.api.nvim_buf_set_lines(bufnr, row - 1, row, false, { docblock })
    else
      vim.api.nvim_buf_set_lines(bufnr, row, row, false, { docblock })
    end
    if #new_uses > 0 then
      vim.api.nvim_buf_set_lines(bufnr, use_insert, use_insert, false, new_uses)
    end
  end, bufnr)
end

return M
