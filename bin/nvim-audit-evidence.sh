#!/usr/bin/env bash
# nvim-audit-evidence.sh — Phase 1 measurement pass for /nvim-audit.
# Read-only: measures the live Neovim config, writes raw output. Never edits config.
#
# Trust contract: every artifact this script writes must be either correct or
# loudly absent. A wrong number that looks right is worse than a crash, so
# each measurement step's exit status and artifact are checked (see
# record_step below), failures are appended to warnings.txt in $OUT (never
# only to stderr, which the reading agent cannot see after the fact), and the
# script exits non-zero if anything failed.
set -euo pipefail

OUT="${1:-${XDG_CACHE_HOME:-$HOME/.cache}/nvim-audit/$(date +%Y-%m-%d)}"
mkdir -p "$OUT"
export OUT # so Lua blocks run inside nvim can find it via os.getenv("OUT")

NVIM="${NVIM:-nvim}"
command -v jq >/dev/null 2>&1 || {
  echo "FATAL: jq is required to validate JSON artifacts but was not found on PATH." >&2
  exit 1
}

WARNINGS="$OUT/warnings.txt"
: > "$WARNINGS"

FAILURES=0
# Force a non-zero exit if any step failed, but never mask a real crash: if
# the script aborts early (set -e, or an explicit `exit 1` on an
# unrecoverable precondition) the original exit code wins. Only the
# happy-path "everything ran, but N artifacts were bad" case gets promoted
# from 0 to 1 here.
trap 'ec=$?; if [ "$ec" -eq 0 ] && [ "$FAILURES" -gt 0 ]; then exit 1; fi; exit $ec' EXIT

# run_nvim: execute headless nvim and return its real exit status. Stderr is
# NOT merged into stdout (unlike a naive `2>&1`) — a stray warning or Lua
# error on stderr must never land inside a stdout-redirected artifact and
# silently corrupt it. In practice every artifact below is written directly
# from Lua via vim.fn.writefile() (see the comment above the lazy-stats
# block for why), so callers just discard run_nvim's stdout and pass its
# real exit status to record_step.
run_nvim() {
  timeout 120 "$NVIM" --headless "$@" -c 'qa!'
}

# record_step <label> <exit-status> <artifact-path> [json]
# Fails loudly (into $WARNINGS, not just stderr) and counts toward the
# process exit code when: nvim exited non-zero, the artifact is empty or
# missing (e.g. a timeout kill, or a Lua error that aborted the block before
# it ever reached its vim.fn.writefile call), or — when `json` is passed —
# the artifact does not actually parse as JSON. An empty or corrupt artifact
# must never be indistinguishable from "measured and clean".
record_step() {
  local label="$1" status="$2" path="$3" want_json="${4:-}"
  if [ "$status" -ne 0 ]; then
    echo "FAIL: $label — nvim exited $status" | tee -a "$WARNINGS" >&2
    FAILURES=$((FAILURES + 1))
    return 0
  fi
  if [ ! -s "$path" ]; then
    echo "FAIL: $label — artifact is empty: $path" | tee -a "$WARNINGS" >&2
    FAILURES=$((FAILURES + 1))
    return 0
  fi
  if [ "$want_json" = "json" ] && ! jq -e . "$path" >/dev/null 2>&1; then
    echo "FAIL: $label — artifact is not valid JSON: $path" | tee -a "$WARNINGS" >&2
    FAILURES=$((FAILURES + 1))
    return 0
  fi
}

# --- Startup: 5 runs, median. Single runs are noise-dominated by disk cache. ---
# `nvim --startuptime <file>` APPENDS to <file> if it already exists. Without
# the rm below, a second same-day run into the same $OUT would leave the
# previous run's block in each startup-$i.txt, doubling startup-runs.txt to
# 10 lines and quietly turning `NR==3` into "3rd smallest of 10", not the
# median of 5 — a plausible-looking but wrong number.
rm -f "$OUT"/startup-*.txt
: > "$OUT/startup-runs.txt"
for i in 1 2 3 4 5; do
  timeout 120 "$NVIM" --headless --startuptime "$OUT/startup-$i.txt" -c 'qa!' >/dev/null 2>&1 || true
  # Use the marker line, not `tail -1`: some startuptime files end with a
  # trailing blank line, which would make `tail -1` grab "" instead of the
  # "--- NVIM STARTED ---" timing. If run $i failed outright (bad $NVIM,
  # timeout kill) the file may not exist at all; don't let that crash the
  # loop with a raw awk error — just contribute zero lines for this run and
  # let the exact-5-lines assertion below catch and report it clearly.
  awk '/NVIM STARTED/{print $1}' "$OUT/startup-$i.txt" >> "$OUT/startup-runs.txt" 2>/dev/null || true
done

n_runs=$(wc -l < "$OUT/startup-runs.txt" | tr -d ' ')
if [ "$n_runs" -ne 5 ]; then
  msg="FATAL: expected 5 startup timing samples in startup-runs.txt, found $n_runs — at least one of the 5 nvim --startuptime runs failed or produced a file with no '--- NVIM STARTED ---' marker. Refusing to compute a median over the wrong sample size."
  echo "$msg" >&2
  echo "$msg" >> "$WARNINGS"
  exit 1
fi
median_idx=$(( (n_runs + 1) / 2 ))
sort -n "$OUT/startup-runs.txt" | awk -v idx="$median_idx" 'NR==idx {print $1}' > "$OUT/startup-median.txt"

# Slowest 15 entries from the middle run of the 5 (run 3), ranked by
# self-time (the col3 "self:" field on `require(...)` lines, or the col2
# "elapsed:" field on plain phase lines) rather than the col2 "self+sourced"
# cumulative field. Ranking by self+sourced put init.lua itself at #1 with
# ~326ms — the whole config's cumulative cost, not an attributable line item.
# The header/divider lines never match either pattern, so they drop out on
# their own. The rm above guarantees this file holds exactly one run's block.
awk '
  $3 ~ /^[0-9]+\.[0-9]+:$/ { self = $3; sub(/:$/, "", self); print self "\t" $0; next }
  $2 ~ /^[0-9]+\.[0-9]+:$/ { self = $2; sub(/:$/, "", self); print self "\t" $0 }
' "$OUT/startup-3.txt" 2>/dev/null \
  | sort -t "$(printf '\t')" -k1,1 -nr \
  | head -15 \
  | cut -f2- > "$OUT/startup-slowest.txt" || true

# --- Lazy: counts and per-plugin load times. ---
# Note: stats().startuptime is unreliable headless — use startup-median.txt for
# the real number. This is for counts and per-plugin attribution only.
#
# All Lua-computed artifacts below are written with vim.fn.writefile()
# straight to their path in $OUT, never via `print()` + shell stdout
# redirection. This isn't cosmetic: headless nvim routes print()/message
# output to its own STDERR, not stdout (confirmed empirically — `nvim
# --headless -c 'lua print(...)' -c 'qa!' 1>file` leaves file empty; the
# content lands in fd2). The old script's blanket `2>&1` wasn't just merging
# an occasional warning, it was the only reason `print()` output ever
# reached the stdout-redirected file at all. Simply dropping `2>&1` (as a
# literal read of "stop merging stderr into stdout" would suggest) breaks
# every artifact, not just the one warning line. Writing the file directly
# from Lua sidesteps stdio entirely: the artifact can never be corrupted by
# a stray message on either stream, and real stderr (errors, warnings) is
# free to reach the terminal unmerged and un-swallowed.
if run_nvim -c 'lua
  local ok, lazy = pcall(require, "lazy")
  local encoded = "{}"
  if ok then
    local s = lazy.stats()
    encoded = vim.json.encode({ count = s.count, loaded = s.loaded })
  end
  vim.fn.writefile({ encoded }, os.getenv("OUT") .. "/lazy-stats.json")
' > /dev/null; then status=0; else status=$?; fi
record_step "lazy-stats" "$status" "$OUT/lazy-stats.json" json

if run_nvim -c 'lua
  local ok, cfg = pcall(require, "lazy.core.config")
  local out = {}
  if ok then
    for name, p in pairs(cfg.plugins) do
      table.insert(out, {
        name = name,
        lazy = p.lazy and true or false,
        loaded = p._.loaded ~= nil,
        url = p.url,
        time = p._.loaded and p._.loaded.time or nil,
      })
    end
  end
  vim.fn.writefile({ vim.json.encode(out) }, os.getenv("OUT") .. "/lazy-plugins.json")
' > /dev/null; then status=0; else status=$?; fi
record_step "lazy-plugins" "$status" "$OUT/lazy-plugins.json" json

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
# disables swapfile creation and no :write is ever issued. -i NONE also
# disables shada, so opening this real file never gets recorded into
# v:oldfiles — without it, every audit run would pollute the very
# oldfiles-filetypes.txt drift signal the audit itself produces below.
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

# vim.wait(2000) with a flat timeout under-counts silently: an autocmd whose
# lazy registration has not finished within the flat 2s is simply absent
# from the dump, and an under-count reads as "the config is lean" rather
# than "the audit didn't wait long enough". Poll instead: sample the autocmd
# count every 250ms and stop once two consecutive samples agree, capped at
# 10s. The actual elapsed wait is recorded in the artifact so the reader can
# judge whether the sample settled quickly or ran to the cap.
if run_nvim -n -i NONE "$SAMPLE_FILE" -c 'lua
  local events = { "CursorMoved", "CursorMovedI", "CursorHold", "CursorHoldI",
            "TextChanged", "TextChangedI", "BufEnter" }
  local function count_autocmds()
    return #vim.api.nvim_get_autocmds({ event = events })
  end
  local INTERVAL_MS = 250
  local CAP_MS = 10000
  local prev = count_autocmds()
  local waited_ms = 0
  while waited_ms < CAP_MS do
    vim.wait(INTERVAL_MS)
    waited_ms = waited_ms + INTERVAL_MS
    local cur = count_autocmds()
    if cur == prev then break end
    prev = cur
  end
  local a = vim.api.nvim_get_autocmds({ event = events })
  local rows = {}
  for _, x in ipairs(a) do
    table.insert(rows, {
      event = x.event, group = x.group_name, pattern = x.pattern,
      command = x.command, desc = x.desc,
    })
  end
  local encoded = vim.json.encode({ elapsed_ms = waited_ms, capped = waited_ms >= CAP_MS, autocmds = rows })
  vim.fn.writefile({ encoded }, os.getenv("OUT") .. "/hot-autocmds.json")
' > /dev/null; then status=0; else status=$?; fi
record_step "hot-autocmds" "$status" "$OUT/hot-autocmds.json" json

# --- Keymaps: full dump for conflict / dead-target analysis. ---
# A dump of only nvim_get_keymap() (global maps, buffer tagged false for all
# rows) is knowingly partial: this config defines buffer-local maps in
# after/ftplugin/{php,json,markdown}.lua that nvim_get_keymap never sees, so
# a ftplugin-vs-global collision would silently read as "no conflict". Fix:
# after the global dump, also trigger each of those three ftplugins on a
# scratch buffer (setting filetype fires the same FileType autocmd that a
# real file open would, no real file needs to be read) and dump
# nvim_buf_get_keymap(0, mode) for each, tagged with its real scope so a
# downstream reader can tell global from buffer-local and from which
# filetype.
if run_nvim -c 'lua
  local modes = { "n", "v", "x", "o", "i", "t", "s" }
  local out = {}
  for _, mode in ipairs(modes) do
    for _, m in ipairs(vim.api.nvim_get_keymap(mode)) do
      table.insert(out, {
        mode = mode, lhs = m.lhs, rhs = m.rhs,
        desc = m.desc, scope = "global",
        has_callback = m.callback ~= nil,
      })
    end
  end
  for _, ft in ipairs({ "php", "json", "markdown" }) do
    vim.cmd("enew")
    vim.bo.filetype = ft
    for _, mode in ipairs(modes) do
      for _, m in ipairs(vim.api.nvim_buf_get_keymap(0, mode)) do
        table.insert(out, {
          mode = mode, lhs = m.lhs, rhs = m.rhs,
          desc = m.desc, scope = "buffer:" .. ft,
          has_callback = m.callback ~= nil,
        })
      end
    end
    vim.cmd("bwipeout!")
  end
  vim.fn.writefile({ vim.json.encode(out) }, os.getenv("OUT") .. "/keymaps.json")
' > /dev/null; then status=0; else status=$?; fi
record_step "keymaps" "$status" "$OUT/keymaps.json" json

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
#
# If vim.lsp._enabled_configs comes back empty, that's a caveat the reading
# agent must not miss. Merging it into stdout via `2>&1` used to corrupt
# tools.json itself (`WARNING: ...\n[]` is not valid JSON) and, worse, the
# command file told the agent to watch for a stderr warning that never
# survived to be read after the fact. Now: warn() writes to real stderr (for
# a human running the script interactively) AND appends to $OUT/warnings.txt
# (for the reading agent, which only ever sees files under $OUT), and never
# touches the stdout stream that becomes tools.json.
if run_nvim -c 'lua
  local warnings_path = os.getenv("OUT") .. "/warnings.txt"
  local function warn(msg)
    io.stderr:write(msg)
    local f = io.open(warnings_path, "a")
    if f then
      f:write(msg)
      f:close()
    end
  end

  -- Mason installs into a directory that is NOT on the shell PATH (verified:
  -- zero mason entries in $PATH) -- it is prepended to vim.env.PATH by mason
  -- when it loads. In a bare headless run nothing may have triggered that, so
  -- executable() would report every Mason-installed tool as missing purely
  -- because of load order. Prepend it explicitly so the check measures whether
  -- the tool EXISTS, not whether a plugin happened to load first.
  local mason_bin = vim.fn.stdpath("data") .. "/mason/bin"
  if vim.fn.isdirectory(mason_bin) == 1 and not string.find(vim.env.PATH or "", mason_bin, 1, true) then
    vim.env.PATH = mason_bin .. ":" .. (vim.env.PATH or "")
  end

  -- names[n] = { srcs = {...}, command = "<resolved binary>" }
  --
  -- The distinction matters. conform and nvim-lint identify tools by an
  -- INTERNAL NAME that is frequently not the binary: conform calls the SQL
  -- formatter "sql_formatter" while the executable is "sql-formatter". Testing
  -- executable() on the internal name reports a perfectly working tool as
  -- missing. The 2026-08-28 audit shipped exactly that false positive, and it
  -- cost a round of chasing a bug that did not exist.
  local names = {}
  local function add(n, src, cmd)
    if type(n) == "string" and #n > 0 then
      names[n] = names[n] or { srcs = {} }
      names[n].srcs[src] = true
      if type(cmd) == "string" and #cmd > 0 then
        names[n].command = cmd
      end
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
          if type(f) == "string" then
            -- Ask conform for the real command rather than assuming the
            -- formatter name is the binary. See the note on add() above.
            local ok_info, info = pcall(conform.get_formatter_info, f)
            local cmd = ok_info and info and info.command or nil
            add(f, "conform", cmd)
          end
        end
      end
    end
  end

  local ok_lint, lint = pcall(require, "lint")
  if ok_lint then
    for _, ls in pairs(lint.linters_by_ft or {}) do
      if type(ls) == "table" then
        for _, l in ipairs(ls) do
          if type(l) == "string" then
            -- Same identifier-vs-binary problem as conform.
            local ok_l, linter = pcall(function() return lint.linters[l] end)
            local cmd = ok_l and type(linter) == "table" and type(linter.cmd) == "string" and linter.cmd or nil
            add(l, "lint", cmd)
          end
        end
      end
    end
  end

  pcall(require, "lspconfig")
  local enabled_configs = vim.lsp._enabled_configs or {}
  if next(enabled_configs) == nil then
    warn("WARNING: LSP introspection returned no enabled configs (vim.lsp._enabled_configs is empty). The tool liveness check may be incomplete.\n")
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
  for n, entry in pairs(names) do
    local src_list = {}
    for s in pairs(entry.srcs) do table.insert(src_list, s) end
    table.sort(src_list)
    -- Test the resolved command when we have one; fall back to the name.
    local probe = entry.command or n
    table.insert(out, {
      name = n,
      command = entry.command,
      executable = vim.fn.executable(probe) == 1,
      source = table.concat(src_list, ","),
    })
  end
  vim.fn.writefile({ vim.json.encode(out) }, os.getenv("OUT") .. "/tools.json")
' > /dev/null; then status=0; else status=$?; fi
record_step "tools" "$status" "$OUT/tools.json" json

# --- Health: errors and warnings only. ---
# Written from Lua (buffer lines -> vim.fn.writefile), not `-c "w! $OUT/..."`.
# That old form passed an unquoted path through Vim's `-c` cmdline argument
# parser, where embedded spaces would split it into more than one argument
# and a literal `%`/`#` would be expanded by Vim as the current/alternate
# filename -- the one place the read-only, writes-only-inside-$OUT contract
# could escape to an unintended path. vim.fn.writefile takes the path as a
# plain string with no such expansion.
if run_nvim -c 'lua
  vim.cmd("checkhealth")
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  vim.fn.writefile(lines, os.getenv("OUT") .. "/checkhealth.txt")
' > /dev/null; then status=0; else status=$?; fi
record_step "checkhealth" "$status" "$OUT/checkhealth.txt"

# An empty/near-empty checkhealth.txt is an unearned all-clear: if
# :checkhealth failed to populate its buffer for any reason, grepping it for
# ERROR/WARNING yields zero lines, which reads exactly like "checked, no
# issues" instead of "didn't actually check". Assert the file looks like a
# real report (checkhealth's own section dividers are lines of `=`; a
# healthy run has ~15-20 of them) before trusting a grep over it.
divider_count=$(grep -c '^=\{10,\}$' "$OUT/checkhealth.txt" 2>/dev/null || echo 0)
if [ ! -s "$OUT/checkhealth.txt" ] || [ "$divider_count" -lt 3 ]; then
  msg="FAIL: checkhealth.txt does not look like a real checkhealth report (found $divider_count section dividers, expected several) -- refusing to derive health-issues.txt from it."
  echo "$msg" | tee -a "$WARNINGS" >&2
  FAILURES=$((FAILURES + 1))
  : > "$OUT/health-issues.txt"
else
  # NOTE: checkhealth lines are of the form "- ⚠️ WARNING ..." / "- ❌ ERROR ...",
  # never anchored at column 1, so `^\s*(ERROR|WARNING)` matches nothing real.
  # `-w` (whole word) avoids the one false positive this file always contains
  # -- which-key's own "Most of these checks are ... WARNINGS should be
  # treated as a warning" help text, whose plural "WARNINGS" would otherwise
  # match a bare (non-anchored) ERROR|WARNING search.
  grep -Ew '(ERROR|WARNING)' "$OUT/checkhealth.txt" > "$OUT/health-issues.txt" 2>/dev/null || true
fi

# --- Drift signal: what filetypes actually get edited, vs the stated profile. ---
if run_nvim -c 'lua
  local counts = {}
  for _, f in ipairs(vim.v.oldfiles or {}) do
    local ext = f:match("%.([%w_]+)$") or "noext"
    counts[ext] = (counts[ext] or 0) + 1
  end
  local rows = {}
  for k, v in pairs(counts) do table.insert(rows, { ext = k, n = v }) end
  table.sort(rows, function(a, b) return a.n > b.n end)
  local lines = {}
  for i = 1, math.min(#rows, 25) do table.insert(lines, rows[i].n .. "\t" .. rows[i].ext) end
  vim.fn.writefile(lines, os.getenv("OUT") .. "/oldfiles-filetypes.txt")
' > /dev/null; then status=0; else status=$?; fi
record_step "oldfiles-filetypes" "$status" "$OUT/oldfiles-filetypes.txt"

echo "$OUT"
