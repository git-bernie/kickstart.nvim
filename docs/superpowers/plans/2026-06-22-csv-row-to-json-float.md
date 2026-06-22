# CSV row → JSON float (`<leader>jc`) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `<leader>jc` keymap that renders the CSV/TSV row under the cursor as pretty-printed JSON (keyed by line 1) in a floating window, mirroring `<leader>jx`.

**Architecture:** A single self-contained keymap block appended after the `<leader>jx` block in `after/plugin/keymaps.lua`, inside the existing `if (vim.fn.executable 'jq') == 1 then` guard (opens line 185, closes line 348). A pure-Lua RFC-4180-aware field splitter (`csv_split`) does the parsing; an ordered JSON string is built with `vim.fn.json_encode` per key/value and pretty-printed via `jq .` (no key sorting); the float recipe is duplicated inline from `jx` (no shared helper, per spec).

**Tech Stack:** Lua, Neovim API (`vim.api`, `vim.bo`, `vim.fn`), `jq` (pretty-print, with raw fallback), `lua` CLI (for the splitter unit test only).

## Global Constraints

- Fully independent — no dependency on `csvview.nvim` (not its API, not its enabled state). Copied verbatim from spec.
- All cell values emitted as JSON **strings** (no type inference).
- **Column order preserved** — build JSON in header order, pretty-print with `jq .`, never `--sort-keys`.
- Delimiter by filetype: `tsv` filetype or `.tsv` extension → tab `\t`; otherwise comma `,`.
- Header is **line 1** of the buffer. No `header_lnum` override, no comment-line skipping.
- Do **not** modify the `<leader>jx` block or `lua/custom/plugins/csvview.lua`.
- Lua style (`.stylua.toml`): single quotes, 2-space indent, 160 col. Run `stylua .` before committing.
- No permanent test harness is added to the repo (spec: "verification is live"). The splitter test in Task 1 is an ephemeral `/tmp` script, not committed.

---

### Task 1: `csv_split` field splitter (test-first, ephemeral test)

The only non-trivial logic. Developed test-first as a standalone pure-Lua function so it can be unit-tested with the `lua` CLI, then transplanted into the keymap block in Task 2.

**Files:**
- Create (ephemeral, NOT committed): `/tmp/csv_split_test.lua`

**Interfaces:**
- Produces: `csv_split(line: string, delim: string): string[]` — splits one line into fields. Handles quoted fields (`"a,b"`), escaped quotes (`""` → `"`), and a single-character delimiter. Single-line only. A `"` is treated as a quote only when it appears at the start of a field; quotes elsewhere are literal.

- [ ] **Step 1: Write the failing test**

Create `/tmp/csv_split_test.lua` with the test harness and assertions, but a stub `csv_split` that returns `{}` so the test fails first:

```lua
-- /tmp/csv_split_test.lua  (ephemeral — do not commit)

local function csv_split(line, delim)
  return {} -- STUB: replaced in Step 3
end

local function eq(got, want, name)
  if #got ~= #want then
    error(string.format('%s: length %d ~= %d', name, #got, #want))
  end
  for i = 1, #want do
    if got[i] ~= want[i] then
      error(string.format('%s: field %d = %q, want %q', name, i, got[i], want[i]))
    end
  end
  print('ok - ' .. name)
end

eq(csv_split('a,b,c', ','), { 'a', 'b', 'c' }, 'plain commas')
eq(csv_split('"Smith, John",42', ','), { 'Smith, John', '42' }, 'quoted comma')
eq(csv_split('"He said ""hi""",x', ','), { 'He said "hi"', 'x' }, 'escaped quotes')
eq(csv_split('a\tb\tc', '\t'), { 'a', 'b', 'c' }, 'tab delim')
eq(csv_split('a,,c', ','), { 'a', '', 'c' }, 'empty middle field')
eq(csv_split('a,b,', ','), { 'a', 'b', '' }, 'empty trailing field')
eq(csv_split('', ','), { '' }, 'empty line -> one empty field')
eq(csv_split([[5'2",x]], ','), { [[5'2"]], 'x' }, 'literal quote mid-field')

print('ALL PASS')
```

- [ ] **Step 2: Run test to verify it fails**

Run: `lua /tmp/csv_split_test.lua`
Expected: FAIL — first assertion errors, e.g. `plain commas: length 0 ~= 3`.

- [ ] **Step 3: Write minimal implementation**

Replace the stub `csv_split` in `/tmp/csv_split_test.lua` with the real implementation:

```lua
local function csv_split(line, delim)
  local fields = {}
  local field = {}
  local in_quotes = false
  local i = 1
  local n = #line
  while i <= n do
    local c = line:sub(i, i)
    if in_quotes then
      if c == '"' then
        if line:sub(i + 1, i + 1) == '"' then
          field[#field + 1] = '"'
          i = i + 1
        else
          in_quotes = false
        end
      else
        field[#field + 1] = c
      end
    else
      if c == '"' and #field == 0 then
        in_quotes = true
      elseif c == delim then
        fields[#fields + 1] = table.concat(field)
        field = {}
      else
        field[#field + 1] = c
      end
    end
    i = i + 1
  end
  fields[#fields + 1] = table.concat(field)
  return fields
end
```

- [ ] **Step 4: Run test to verify it passes**

Run: `lua /tmp/csv_split_test.lua`
Expected: PASS — eight `ok - ...` lines followed by `ALL PASS`.

- [ ] **Step 5: No commit**

Nothing to commit — the test script is ephemeral and the verified `csv_split` body is transplanted into the keymap block in Task 2. Keep `/tmp/csv_split_test.lua` until Task 2 is done in case the function needs a fix.

---

### Task 2: `<leader>jc` keymap + float (live verification)

Assemble the full feature in `after/plugin/keymaps.lua` using the `csv_split` verified in Task 1, then verify live against sample files.

**Files:**
- Modify: `after/plugin/keymaps.lua` — insert a new block immediately after line 347 (`end, { desc = 'E[x]tract JSON from log line' })`) and before the `if jq` guard's closing `end` at line 348. The new block must sit inside that `if (vim.fn.executable 'jq') == 1 then` guard.
- Create (ephemeral, NOT committed): `/tmp/jc_sample.csv`, `/tmp/jc_sample.tsv`

**Interfaces:**
- Consumes: `csv_split(line, delim)` from Task 1 (defined as a `local` inside this keymap block).
- Produces: registered normal-mode keymap `<leader>jc`, desc `'[j]son from [c]sv row'`. No exported Lua symbols.

- [ ] **Step 1: Insert the keymap block**

In `after/plugin/keymaps.lua`, after line 347 and before the closing `end` on line 348, insert:

```lua

  -- Show the CSV/TSV row under the cursor as JSON in a float (independent of csvview)
  vim.keymap.set('n', '<leader>jc', function()
    local data_line = vim.api.nvim_get_current_line()
    if data_line:match '^%s*$' then
      vim.notify('No CSV data on this line', vim.log.levels.WARN)
      return
    end

    -- Delimiter: tab for tsv, else comma
    local is_tsv = vim.bo.filetype == 'tsv' or vim.fn.expand '%:e' == 'tsv'
    local delim = is_tsv and '\t' or ','

    -- RFC-4180-aware single-line splitter (verified in plan Task 1)
    local function csv_split(line, d)
      local fields = {}
      local field = {}
      local in_quotes = false
      local i = 1
      local n = #line
      while i <= n do
        local c = line:sub(i, i)
        if in_quotes then
          if c == '"' then
            if line:sub(i + 1, i + 1) == '"' then
              field[#field + 1] = '"'
              i = i + 1
            else
              in_quotes = false
            end
          else
            field[#field + 1] = c
          end
        else
          if c == '"' and #field == 0 then
            in_quotes = true
          elseif c == d then
            fields[#fields + 1] = table.concat(field)
            field = {}
          else
            field[#field + 1] = c
          end
        end
        i = i + 1
      end
      fields[#fields + 1] = table.concat(field)
      return fields
    end

    local headers = csv_split(vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] or '', delim)
    local values = csv_split(data_line, delim)

    -- Build JSON in column order; keys/values escaped via json_encode
    local parts = {}
    local count = math.max(#headers, #values)
    for idx = 1, count do
      local key = headers[idx]
      if key == nil or key == '' then
        key = 'field_' .. idx
      end
      local val = values[idx] or ''
      parts[#parts + 1] = vim.fn.json_encode(key) .. ': ' .. vim.fn.json_encode(val)
    end
    local compact = '{' .. table.concat(parts, ',') .. '}'

    -- Pretty-print preserving order (jq . — NOT --sort-keys); raw fallback
    local formatted = vim.fn.systemlist('echo ' .. vim.fn.shellescape(compact) .. ' | jq .')
    if vim.v.shell_error ~= 0 then
      formatted = { compact }
    end

    -- Float (duplicated from jx recipe, intentionally not shared)
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, formatted)
    vim.bo[buf].filetype = 'json'
    vim.bo[buf].bufhidden = 'wipe'
    vim.bo[buf].modifiable = false

    local width = math.min(math.max(40, #(formatted[1] or '') + 4), math.floor(vim.o.columns * 0.8))
    local height = math.min(#formatted, math.floor(vim.o.lines * 0.7))
    local win = vim.api.nvim_open_win(buf, true, {
      relative = 'cursor',
      width = width,
      height = height,
      col = 2,
      row = 1,
      style = 'minimal',
      border = 'rounded',
      title = ' CSV row as JSON (q/<Esc> to close) ',
      title_pos = 'center',
    })
    local function close_win()
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
    end
    vim.keymap.set('n', 'q', close_win, { buffer = buf, silent = true })
    vim.keymap.set('n', '<Esc>', close_win, { buffer = buf, silent = true })
    vim.api.nvim_create_autocmd('WinLeave', {
      buffer = buf,
      once = true,
      callback = close_win,
    })
  end, { desc = '[j]son from [c]sv row' })
```

- [ ] **Step 2: Format**

Run: `stylua after/plugin/keymaps.lua && stylua --check after/plugin/keymaps.lua`
Expected: no output / exit 0 (file already formatted).

- [ ] **Step 3: Create sample fixtures**

Create `/tmp/jc_sample.csv`:

```
name,age,note,empty_header_test
"Smith, John",42,"He said ""hi""",x
Alice,30,plain note,y,EXTRA1,EXTRA2
Bob,,short
```

Create `/tmp/jc_sample.tsv` (fields separated by real tab characters):

```
name	age	city
Carol	28	"Toronto, ON"
```

- [ ] **Step 4: Live verification — comma file**

Run: `nvim /tmp/jc_sample.csv`
Then, in nvim:
- Put cursor on line 2 (`"Smith, John",42,...`), press `<leader>jc`.
  - Expected float (order preserved, all strings):
    ```json
    {
      "name": "Smith, John",
      "age": "42",
      "note": "He said \"hi\"",
      "empty_header_test": "x"
    }
    ```
  - Confirms: quoted comma not split, escaped `""` → single `"`, order preserved.
- Press `q` — float closes.
- Cursor on line 3 (`Alice,30,plain note,y,EXTRA1,EXTRA2` — more fields than headers), `<leader>jc`.
  - Expected: 4 named keys (`name`/`age`/`note`/`empty_header_test`) then `"field_5": "EXTRA1"`, `"field_6": "EXTRA2"`.
- Cursor on line 4 (`Bob,,short` — fewer fields), `<leader>jc`.
  - Expected: `"name":"Bob"`, `"age":""`, `"note":"short"`, `"empty_header_test":""`.
- Cursor on line 1 (the header), `<leader>jc`.
  - Expected: `header: header` pairs (e.g. `"name":"name"`), no crash.
- `:enew` and on a blank buffer press `<leader>jc` — expect WARN `No CSV data on this line`, no float.
- `:q!`

- [ ] **Step 5: Live verification — tsv file**

Run: `nvim /tmp/jc_sample.tsv`
- Cursor on line 2 (`Carol\t28\t"Toronto, ON"`), `<leader>jc`.
  - Expected: tab-split into 3 fields →
    ```json
    {
      "name": "Carol",
      "age": "28",
      "city": "Toronto, ON"
    }
    ```
  - Confirms: tab delimiter chosen by `.tsv` extension; the comma inside `"Toronto, ON"` stays in one field.
- `:q!`

- [ ] **Step 6: Commit**

```bash
git add after/plugin/keymaps.lua
git commit -m "feat(keymaps): <leader>jc shows CSV/TSV row as JSON float

Self-contained, like <leader>jx. Header from line 1, delimiter by
filetype (tsv->tab else comma), RFC-4180-aware splitter, values as
strings, column order preserved via jq . (no sort).

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

- [ ] **Step 7: Cleanup ephemeral files**

Run: `rm -f /tmp/csv_split_test.lua /tmp/jc_sample.csv /tmp/jc_sample.tsv`

---

## Self-Review

**1. Spec coverage:**
- Keymap on any CSV/TSV buffer, no CsvView dependency → Task 2 (global keymap, no csvview refs). ✓
- Quoted-field correctness → Task 1 tests (quoted comma, escaped quotes, literal mid-field quote). ✓
- JSON output, order preserved, strings only → Task 2 Step 1 (`jq .`, `json_encode`, max-count loop). ✓
- Float UX clone of jx → Task 2 Step 1 (scratch buf, filetype=json, rounded border, q/Esc/WinLeave). ✓
- Delimiter by filetype → Task 2 Step 1 (`is_tsv` check); verified Task 2 Step 5. ✓
- Header = line 1 → Task 2 Step 1 (`nvim_buf_get_lines(0,0,1)`). ✓
- Column mismatch (overflow → field_N, missing → "") → Task 2 Step 1 loop; verified Step 4. ✓
- Cursor-on-header + empty-line edge cases → verified Task 2 Step 4. ✓
- jq-missing fallback → Task 2 Step 1 (`shell_error` → raw compact). ✓
- No refactor of jx, no shared helper → float duplicated inline. ✓

**2. Placeholder scan:** No TBD/TODO; the only stub is the deliberate failing-test stub in Task 1 Step 1, replaced in Step 3. All code blocks complete.

**3. Type consistency:** `csv_split(line, delim)` signature identical in Task 1 and Task 2 (inner param renamed `d` in Task 2 only to avoid shadowing the outer `delim`; behavior identical). `headers`/`values` are `string[]`; keys/values stringified consistently.
