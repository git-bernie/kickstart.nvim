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
run_nvim -c 'lua
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

echo "$OUT"
