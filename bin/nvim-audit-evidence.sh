#!/usr/bin/env bash
# nvim-audit-evidence.sh — Phase 1 measurement pass for /nvim-audit.
# Read-only: measures the live Neovim config, writes raw output. Never edits config.
set -euo pipefail

OUT="${1:-${XDG_CACHE_HOME:-$HOME/.cache}/nvim-audit/$(date +%Y-%m-%d)}"
mkdir -p "$OUT"

NVIM="${NVIM:-nvim}"
run_nvim() { timeout 120 "$NVIM" --headless "$@" -c 'qa!' 2>&1 || true; }

# --- Startup: 5 runs, median. Single runs are noise-dominated by disk cache. ---
: > "$OUT/startup-runs.txt"
for i in 1 2 3 4 5; do
  timeout 120 "$NVIM" --headless --startuptime "$OUT/startup-$i.txt" -c 'qa!' >/dev/null 2>&1 || true
  # Use the marker line, not `tail -1`: some startuptime files end with a
  # trailing blank line, which would make `tail -1` grab "" instead of the
  # "--- NVIM STARTED ---" timing.
  awk '/NVIM STARTED/{print $1}' "$OUT/startup-$i.txt" >> "$OUT/startup-runs.txt"
done
sort -n "$OUT/startup-runs.txt" | awk 'NR==3 {print $1}' > "$OUT/startup-median.txt"

# Slowest 15 entries from the median-ish run (run 3) for attribution.
sort -k2 -nr "$OUT/startup-3.txt" 2>/dev/null | head -15 > "$OUT/startup-slowest.txt" || true

# --- Lazy: counts and per-plugin load times. ---
# Note: stats().startuptime is unreliable headless — use startup-median.txt for
# the real number. This is for counts and per-plugin attribution only.
run_nvim -c 'lua
  local ok, lazy = pcall(require, "lazy")
  if not ok then print("{}") return end
  local s = lazy.stats()
  print(vim.json.encode({ count = s.count, loaded = s.loaded }))
' > "$OUT/lazy-stats.json"

run_nvim -c 'lua
  local ok, cfg = pcall(require, "lazy.core.config")
  if not ok then print("[]") return end
  local out = {}
  for name, p in pairs(cfg.plugins) do
    table.insert(out, {
      name = name,
      lazy = p.lazy and true or false,
      loaded = p._.loaded ~= nil,
      url = p.url,
      time = p._.loaded and p._.loaded.time or nil,
    })
  end
  print(vim.json.encode(out))
' > "$OUT/lazy-plugins.json"

# --- Hot autocmds: fire constantly, so they are where in-editor lag lives. ---
# Many hot autocmds (notably CursorHold work — see biscuits.lua / commit
# 07dc16a) register lazily on FileType or on plugin load, not at nvim
# startup. Enumerating them against a headless nvim with no buffer open
# misses those entirely. So before enumerating, open a real, substantial
# source file of a filetype this config targets (php/lua/py/sh/md) to
# trigger that lazy registration. The path is discovered at runtime — never
# hardcoded to this machine — by searching common project roots, skipping
# vendor/generated noise and picking the largest candidate in a sane size
# band; falls back to this repo's own init.lua if nothing is found. The
# chosen file is recorded for reproducibility. It is only ever *read*: -n
# disables swapfile creation and no :write is ever issued.
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SAMPLE_FILE=""
SAMPLE_SIZE=0
for root in "$HOME/work" "$HOME/code" "$HOME/projects"; do
  [ -d "$root" ] || continue
  while read -r size path; do
    if [ "$size" -gt "$SAMPLE_SIZE" ]; then
      SAMPLE_SIZE="$size"
      SAMPLE_FILE="$path"
    fi
  done < <(find "$root" -maxdepth 5 \
      \( -name .git -o -name node_modules -o -name vendor -o -name .cache \
         -o -name storage -o -name dist -o -name build \) -prune -o \
      -type f \( -iname '*.php' -o -iname '*.lua' -o -iname '*.py' \
                 -o -iname '*.sh' -o -iname '*.md' \) \
      -printf '%s %p\n' 2>/dev/null \
    | grep -viE '_ide_helper|/\.[^/]*$' \
    | awk '$1 > 800 && $1 < 150000')
done
SAMPLE_FILE="${SAMPLE_FILE:-$REPO_ROOT/init.lua}"
echo "$SAMPLE_FILE" > "$OUT/hot-autocmds-sample.txt"

run_nvim -n "$SAMPLE_FILE" -c 'lua
  vim.wait(2000)
  local a = vim.api.nvim_get_autocmds({
    event = { "CursorMoved", "CursorMovedI", "CursorHold", "CursorHoldI",
              "TextChanged", "TextChangedI", "BufEnter" },
  })
  local out = {}
  for _, x in ipairs(a) do
    table.insert(out, {
      event = x.event, group = x.group_name, pattern = x.pattern,
      command = x.command, desc = x.desc,
    })
  end
  print(vim.json.encode(out))
' > "$OUT/hot-autocmds.json"

# --- Keymaps: full dump for conflict / dead-target analysis. ---
run_nvim -c 'lua
  local out = {}
  for _, mode in ipairs({ "n", "v", "x", "o", "i", "t", "s" }) do
    for _, m in ipairs(vim.api.nvim_get_keymap(mode)) do
      table.insert(out, {
        mode = mode, lhs = m.lhs, rhs = m.rhs,
        desc = m.desc, buffer = false,
        has_callback = m.callback ~= nil,
      })
    end
  end
  print(vim.json.encode(out))
' > "$OUT/keymaps.json"

# --- Tool liveness: configured-but-absent is the recurring failure mode here
# --- (sqlfluff, April 2026). Static config reading cannot catch it.
#
# Two corrections vs. a naive version of this check, both confirmed against
# this live config before writing this script:
#
# 1. Mason's *package* name is frequently not the binary it puts on PATH
#    (html-lsp -> vscode-html-language-server, json-lsp ->
#    vscode-json-language-server, delve -> dlv, xmlformatter -> xmlformat).
#    Checking executable(package.name) directly gave 4 false "missing"
#    verdicts on packages that are in fact installed and working. The fix is
#    to read the real exposed names off each package's `spec.bin` keys.
#
# 2. vim.lsp.get_clients({}) is empty in headless nvim with no buffer opened
#    -- nothing has attached, so this would silently check zero LSP servers,
#    which is exactly the case this whole block exists to catch. Also, the
#    LSP plugin here (neovim/nvim-lspconfig) is lazy-loaded on
#    event = 'BufReadPost', which never fires headless with no file arg, so
#    its config() (which calls vim.lsp.enable() per server) never runs
#    either -- `require('lspconfig')` is what forces that lazy load. After
#    that, the *configured* servers live in vim.lsp._enabled_configs
#    (internal but stable across 0.11/0.12), not in get_clients().
#    A few servers (html/jsonls/yamlls here) resolve their real binary via a
#    `cmd = function(dispatchers, config) ... end` at attach time; calling
#    that function would start the real LSP process as a side effect, which
#    a read-only audit must never do, so those are intentionally left
#    unresolved here -- in this config they are also Mason packages, so
#    correction #1 above already covers their real binary names.
run_nvim -c 'lua
  local names = {}
  local function add(n, src)
    if type(n) == "string" and #n > 0 then
      names[n] = names[n] or {}
      names[n][src] = true
    end
  end

  local ok_mr, mr = pcall(require, "mason-registry")
  if ok_mr then
    for _, p in ipairs(mr.get_installed_packages()) do
      local bins = (p.spec and p.spec.bin) or {}
      if next(bins) then
        for bin in pairs(bins) do add(bin, "mason") end
      else
        add(p.name, "mason")
      end
    end
  end

  local ok_cf, conform = pcall(require, "conform")
  if ok_cf then
    for _, fts in pairs(conform.formatters_by_ft or {}) do
      if type(fts) == "table" then
        for _, f in ipairs(fts) do
          if type(f) == "string" then add(f, "conform") end
        end
      end
    end
  end

  local ok_lint, lint = pcall(require, "lint")
  if ok_lint then
    for _, ls in pairs(lint.linters_by_ft or {}) do
      if type(ls) == "table" then
        for _, l in ipairs(ls) do
          if type(l) == "string" then add(l, "lint") end
        end
      end
    end
  end

  pcall(require, "lspconfig")
  local enabled_configs = vim.lsp._enabled_configs or {}
  if next(enabled_configs) == nil then
    io.stderr:write("WARNING: LSP introspection returned no enabled configs (vim.lsp._enabled_configs is empty). The tool liveness check may be incomplete.\n")
  end
  for name in pairs(enabled_configs) do
    local ok_cfg, cfg = pcall(function() return vim.lsp.config[name] end)
    local cmd = ok_cfg and cfg and cfg.cmd
    if type(cmd) == "table" and type(cmd[1]) == "string" then
      add(cmd[1], "lsp:" .. name)
    end
    -- else: cmd is a function (resolved only at attach) -- intentionally
    -- not invoked; see comment above the Lua block.
  end

  local out = {}
  for n, srcs in pairs(names) do
    local src_list = {}
    for s in pairs(srcs) do table.insert(src_list, s) end
    table.sort(src_list)
    table.insert(out, {
      name = n,
      executable = vim.fn.executable(n) == 1,
      source = table.concat(src_list, ","),
    })
  end
  print(vim.json.encode(out))
' > "$OUT/tools.json"

# --- Health: errors and warnings only. ---
run_nvim -c 'checkhealth' -c "w! $OUT/checkhealth.txt" > /dev/null || true
# NOTE: checkhealth lines are of the form "- ⚠️ WARNING ..." / "- ❌ ERROR ...",
# never anchored at column 1, so `^\s*(ERROR|WARNING)` matches nothing real.
# `-w` (whole word) avoids the one false positive this file always contains
# -- which-key's own "Most of these checks are ... WARNINGS should be
# treated as a warning" help text, whose plural "WARNINGS" would otherwise
# match a bare (non-anchored) ERROR|WARNING search.
grep -Ew '(ERROR|WARNING)' "$OUT/checkhealth.txt" > "$OUT/health-issues.txt" 2>/dev/null || true

# --- Drift signal: what filetypes actually get edited, vs the stated profile. ---
run_nvim -c 'lua
  local counts = {}
  for _, f in ipairs(vim.v.oldfiles or {}) do
    local ext = f:match("%.([%w_]+)$") or "noext"
    counts[ext] = (counts[ext] or 0) + 1
  end
  local rows = {}
  for k, v in pairs(counts) do table.insert(rows, { ext = k, n = v }) end
  table.sort(rows, function(a, b) return a.n > b.n end)
  for i = 1, math.min(#rows, 25) do print(rows[i].n .. "\t" .. rows[i].ext) end
' > "$OUT/oldfiles-filetypes.txt"

echo "$OUT"
