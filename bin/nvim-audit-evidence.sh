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

echo "$OUT"
