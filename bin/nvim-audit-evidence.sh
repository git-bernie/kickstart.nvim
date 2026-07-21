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

echo "$OUT"
