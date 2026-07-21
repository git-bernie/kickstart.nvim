# /nvim-audit Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a `/nvim-audit` slash command that measures this Neovim config, checks it against the current Neovim ecosystem, and writes a dated, evidence-tiered report — without editing the config.

**Architecture:** Two pieces with different natures. `bin/nvim-audit-evidence.sh` is a deterministic measurement pass that shells out to headless nvim and writes raw output files. `.claude/commands/nvim-audit.md` orchestrates: runs the script, does the ecosystem research, reasons over the evidence, and writes the report. Measurement is verifiable and debuggable on its own; reasoning is not, so they stay separate.

**Tech Stack:** Bash, `nvim --headless` (0.12.2), Lua via `-c 'lua ...'`, GitHub REST API (metadata only), Claude Code slash command markdown.

## Global Constraints

- **Read-only on config.** Nothing in this feature may edit `init.lua`, `lua/`, `after/`, or any plugin file. The only writes are `docs/nvim-audit-YYYY-MM-DD.md` and files under the evidence output directory.
- **Evidence directory** is passed as `$1` to the script; default `${XDG_CACHE_HOME:-$HOME/.cache}/nvim-audit/<date>`.
- **Every nvim invocation** uses `timeout 120` and `--headless`, and ends with `-c 'qa!'`.
- **Ecosystem claims require a cited primary source** with URL in the report. Unsourceable → "worth checking", never asserted.
- **Plugin health checks are metadata-only** (`archived`, `pushed_at`) and limited to load-bearing plugins. Never clone, never fetch repo contents, never walk trees or issues.
- **Report tiers** are exactly: `Verified`, `Judgment call`, `Experimental`.
- **Markdown output** follows the user's 80-column convention: no hard-wrapped prose, tables only when ≤4 columns and terse.
- Shell scripts are `#!/usr/bin/env bash` with `set -euo pipefail`, and `chmod +x`.

---

## File Structure

- **Create:** `bin/nvim-audit-evidence.sh` — Phase 1 measurement. Writes one raw output file per measurement into the evidence dir. No interpretation.
- **Create:** `.claude/commands/nvim-audit.md` — the slash command. Orchestration, Phase 2 research, work profile, report template.
- **Create:** `docs/nvim-audit.md` — reference doc, matching the `docs/lc-codec.md` / `docs/lc-lookup.md` convention.
- **Modify:** `CLAUDE.md` — add the script to the "Vendored Tools" list.

The script has no dependency on the command file. The command file depends only on the script's output filenames, which are fixed and listed in Task 4's Interfaces block.

---

### Task 1: Evidence script skeleton and startup timing

**Files:**
- Create: `bin/nvim-audit-evidence.sh`

**Interfaces:**
- Produces: executable script taking optional `$1` = output dir; echoes the resolved output dir on the last line of stdout. Creates `startup-1..5.txt`, `startup-runs.txt`, `startup-median.txt`, and `startup-slowest.txt` in that dir.

- [ ] **Step 1: Create the script with skeleton and startup measurement**

```bash
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
  # Match the STARTED line, not `tail -1` — nvim writes a trailing blank line,
  # so tail silently yields an empty median. Verified 2026-07-21.
  awk '/NVIM STARTED/{print $1}' "$OUT/startup-$i.txt" >> "$OUT/startup-runs.txt"
done
sort -n "$OUT/startup-runs.txt" | awk 'NR==3 {print $1}' > "$OUT/startup-median.txt"

# Slowest 15 entries from the median-ish run (run 3) for attribution.
sort -k2 -nr "$OUT/startup-3.txt" 2>/dev/null | head -15 > "$OUT/startup-slowest.txt" || true

echo "$OUT"
```

- [ ] **Step 2: Make it executable and run it**

```bash
chmod +x bin/nvim-audit-evidence.sh
./bin/nvim-audit-evidence.sh /tmp/nvim-audit-test
```

Expected: prints `/tmp/nvim-audit-test`. Takes ~20 seconds (5 nvim starts).

- [ ] **Step 3: Verify the output is real, not empty**

```bash
cat /tmp/nvim-audit-test/startup-median.txt
wc -l /tmp/nvim-audit-test/startup-slowest.txt
```

Expected: median is a number in the 200–400 range (measured baseline on this config: ~254ms). `startup-slowest.txt` has 15 lines. If median is empty or `0`, the `--startuptime` file is not being written — check that `$OUT` exists and nvim is on PATH.

- [ ] **Step 4: Commit**

```bash
git add bin/nvim-audit-evidence.sh
git commit -m "feat(audit): evidence script with startup timing"
```

---

### Task 2: Lazy stats and hot autocmds

**Files:**
- Modify: `bin/nvim-audit-evidence.sh` (append before the final `echo "$OUT"`)

**Interfaces:**
- Consumes: `run_nvim()` and `$OUT` from Task 1.
- Produces: `lazy-stats.json`, `lazy-plugins.json`, `hot-autocmds.json` in `$OUT`.

- [ ] **Step 1: Append the lazy stats and autocmd measurement**

Insert immediately before the final `echo "$OUT"` line:

```bash
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
```

- [ ] **Step 2: Run and verify each file parses as JSON with real content**

```bash
./bin/nvim-audit-evidence.sh /tmp/nvim-audit-test
for f in lazy-stats lazy-plugins hot-autocmds; do
  echo "--- $f"
  jq -e 'if type=="array" then length else .count end' /tmp/nvim-audit-test/$f.json
done
```

Expected, measured against this config on 2026-07-21:
- `lazy-stats.json` → `count` around 144, `loaded` around 53
- `lazy-plugins.json` → array of ~144 entries
- `hot-autocmds.json` → array of ~16 entries

If any file is empty or `jq` errors, the most likely cause is a Lua error printing to the same stream — run the `run_nvim` block manually without redirection to see the message.

- [ ] **Step 3: Commit**

```bash
git add bin/nvim-audit-evidence.sh
git commit -m "feat(audit): capture lazy stats and hot autocmds"
```

---

### Task 3: Keymaps, tool liveness, health, and drift signal

**Files:**
- Modify: `bin/nvim-audit-evidence.sh` (append before the final `echo "$OUT"`)

**Interfaces:**
- Consumes: `run_nvim()` and `$OUT` from Task 1.
- Produces: `keymaps.json`, `tools.json`, `checkhealth.txt`, `oldfiles-filetypes.txt` in `$OUT`.

- [ ] **Step 1: Append keymap and tool-liveness measurement**

Insert immediately before the final `echo "$OUT"`:

```bash
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
run_nvim -c 'lua
  local names = {}
  local function add(n) if type(n) == "string" and #n > 0 then names[n] = true end end

  local ok_mr, mr = pcall(require, "mason-registry")
  if ok_mr then
    for _, p in ipairs(mr.get_installed_packages()) do add(p.name) end
  end

  local ok_cf, conform = pcall(require, "conform")
  if ok_cf then
    for _, fts in pairs(conform.formatters_by_ft or {}) do
      if type(fts) == "table" then for _, f in ipairs(fts) do add(f) end end
    end
  end

  local ok_lint, lint = pcall(require, "lint")
  if ok_lint then
    for _, ls in pairs(lint.linters_by_ft or {}) do
      if type(ls) == "table" then for _, l in ipairs(ls) do add(l) end end
    end
  end

  for _, c in ipairs(vim.lsp.get_clients({})) do
    local cmd = c.config and c.config.cmd
    if type(cmd) == "table" then add(cmd[1]) end
  end

  local out = {}
  for n in pairs(names) do
    table.insert(out, { name = n, executable = vim.fn.executable(n) == 1 })
  end
  print(vim.json.encode(out))
' > "$OUT/tools.json"

# --- Health: errors and warnings only. ---
run_nvim -c 'checkhealth' -c "w! $OUT/checkhealth.txt" > /dev/null || true
grep -E '^\s*(ERROR|WARNING)' "$OUT/checkhealth.txt" > "$OUT/health-issues.txt" 2>/dev/null || true

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
```

- [ ] **Step 2: Run and verify**

```bash
./bin/nvim-audit-evidence.sh /tmp/nvim-audit-test
jq length /tmp/nvim-audit-test/keymaps.json
jq -r '.[] | select(.executable==false) | .name' /tmp/nvim-audit-test/tools.json
head -10 /tmp/nvim-audit-test/oldfiles-filetypes.txt
wc -l /tmp/nvim-audit-test/health-issues.txt
```

Expected:
- `keymaps.json` → around 409 entries (measured baseline).
- The `executable==false` list is the payload finding — it may legitimately be empty.
- `oldfiles-filetypes.txt` → tab-separated `count<TAB>ext`, descending, with `lua`, `php`, `md` expected near the top.
- `health-issues.txt` may have zero lines; that is a pass, not a failure.

Known caveat to leave as-is: `checkhealth` in headless mode does not exercise every plugin's health function identically to an interactive run. The report must describe this file as indicative, not exhaustive.

- [ ] **Step 3: Commit**

```bash
git add bin/nvim-audit-evidence.sh
git commit -m "feat(audit): capture keymaps, tool liveness, health, oldfiles drift"
```

---

### Task 4: The slash command

**Files:**
- Create: `.claude/commands/nvim-audit.md`

**Interfaces:**
- Consumes: `bin/nvim-audit-evidence.sh`, which produces exactly these files in its output dir — `startup-median.txt`, `startup-slowest.txt`, `lazy-stats.json`, `lazy-plugins.json`, `hot-autocmds.json`, `keymaps.json`, `tools.json`, `checkhealth.txt`, `health-issues.txt`, `oldfiles-filetypes.txt`.
- Produces: `docs/nvim-audit-YYYY-MM-DD.md`.

- [ ] **Step 1: Write the command file**

```markdown
---
description: Audit this Neovim config for performance, correctness, keymap UX, tool coverage, and ecosystem currency
---

Audit this Neovim config and write a report. **Do not edit any config file.**
The only file you create is the report.

## Work profile

What this config exists to support. Check coverage in both directions: gaps in
tooling for work actually done, and plugins serving work no longer done.

- PHP / Laravel — `services`, `loanconnect-laravel`
- CakePHP 2 monolith
- SQL / dadbod
- Markdown-heavy documentation
- Python (learning)
- Lua — this config, and as a general embedded/scripting language elsewhere
- Bash / shell scripting — eternal and omnipresent
- Multi-repo git

Cross-check this list against `oldfiles-filetypes.txt`. If the histogram
disagrees with the profile, flag the drift — the profile is meant to
self-correct, not quietly go stale. Note that shell work is structurally
under-counted by the histogram (short edits, scattered files), so a low `.sh`
count is not evidence that bash tooling does not matter.

## Phase 1 — Measure

Run the evidence script and read every file it produces:

    ./bin/nvim-audit-evidence.sh

It prints the output directory on its last line. Read the files from there.
Do not re-derive these numbers by reading config source; the measurements are
the ground truth and the config is the hypothesis.

## Phase 2 — Ecosystem currency

Guards against the config being good on its own terms while years behind.

**Local first — free, offline, and impossible to hallucinate:**
- `:help news` ships inside the installed nvim. Read it for what changed.
- `checkhealth vim.deprecated` output, and any `vim.deprecate()` warnings.

**Then external, only for what local cannot answer:**
- Is the installed nvim version still current? What landed since?
- Built-ins that may obsolete plugins here: `vim.pack` vs lazy.nvim,
  `vim.lsp.config`/`enable` vs mason-lspconfig wiring, native commenting,
  `vim.lsp.completion`, native snippets. For each, ask whether the built-in
  covers *this config's actual usage*. A built-in existing is not by itself
  an argument for switching.
- Kickstart upstream drift: what changed upstream worth adopting.
- Health of **load-bearing plugins only** — roughly 15: the LSP stack,
  treesitter, `blink.cmp`, the pickers (telescope, snacks), lazy.nvim, and
  anything else whose failure would stop work.

**Hard limits on Phase 2:**
- Plugin health is **metadata only**: the `archived` flag and `pushed_at`.
  Never clone a repo, fetch repo contents, walk a tree, or read issues.
  "Is this abandoned" is answerable from two fields.
- Do not health-check non-load-bearing plugins. A stale colorscheme is not
  a finding.
- **Every ecosystem claim must cite a fetched primary source with its URL.**
  Anything you cannot source is stated as "worth checking", never asserted.
  An uncited claim in this section is a bug in this audit.
- If the installed nvim version and the last report's researched version
  match and that report is recent, say so and skip the external work.

## Report

Write `docs/nvim-audit-YYYY-MM-DD.md`. Record the nvim version and the
ecosystem-research date near the top so the next run can skip Phase 2.

Tier findings by **how much they should be trusted**, not by topic. Topics mix
evidence quality, and a wrong guess sitting next to a measured fact makes the
fact look like a guess too.

**Verified** — backed by a measurement or a cited source from this run. Show
the evidence inline: the startuptime line, the `executable()` result, the URL.

**Judgment call** — reasoned from the config, not measured. Architecture
opinions, redundancy, whether a plugin earns its keep.

**Experimental** — frequency-weighted keymap ergonomics: are the most-used
operations on the cheapest keys, and is prime real estate spent on things
never invoked? There is no keylogging here, so this is proxied from
leader-group population, git history as a signal of active work, and the work
profile. Mark it plainly as inference. Also check which of the previous
report's experimental suggestions were adopted, and drop any declined twice.

Within each tier, order by impact, name `file:line`, and where a fix is
mechanical include the exact diff — **unapplied**.

## Keymap standard

Two checks, held to deliberately different standards:

- **Hard check → Verified.** From `keymaps.json`: mnemonic coherence (does
  `<leader>s*` always mean search?), leader groups missing from which-key,
  orphan maps, maps whose target plugin is disabled, shadowed defaults.
  These are checkable facts.
- **Advisory → Experimental.** Ergonomic reach, as described above.

Prior art to build on rather than rediscover: `docs/search-keymaps-audit.md`.

## Existing knowledge — reference, do not rebuild

- `.claude/playbook/knowledge/lazy-nvim-performance.md`
- `.claude/playbook/knowledge/window-maximize-performance.md`
- `.claude/playbook/runbooks/debug-keymap-conflict.md`
- `.claude/playbook/runbooks/nvim-major-version-upgrade.md`

## Out of scope

- Applying any fix.
- Refactoring the config.
- Cloning or scanning plugin repository contents.
```

- [ ] **Step 2: Verify the command is registered**

```bash
ls -l .claude/commands/nvim-audit.md
```

Expected: the file exists. In an interactive Claude Code session, `/nvim-audit`
should appear in the slash-command list. A restart of the session may be
required for a newly added command to be picked up.

- [ ] **Step 3: Commit**

```bash
git add .claude/commands/nvim-audit.md
git commit -m "feat(audit): add /nvim-audit slash command"
```

---

### Task 5: Reference doc and CLAUDE.md entry

**Files:**
- Create: `docs/nvim-audit.md`
- Modify: `CLAUDE.md` (the "Vendored Tools" bullet list)

**Interfaces:**
- Consumes: the script and command from Tasks 1–4.

- [ ] **Step 1: Write the reference doc**

Create `docs/nvim-audit.md`:

```markdown
# nvim-audit

Periodic health review of this Neovim config. Run `/nvim-audit` in Claude Code.

## What it checks

Five dimensions: startup and in-editor performance, correctness (health,
tool liveness), keymap and UX efficiency, tool coverage against the stated
work profile, and currency with the wider Neovim ecosystem.

## Parts

- `bin/nvim-audit-evidence.sh` — measurement pass. Deterministic, read-only,
  runnable on its own. Takes an optional output directory; defaults to
  `~/.cache/nvim-audit/<date>`. Prints the directory it used.
- `.claude/commands/nvim-audit.md` — the command. Runs the script, does the
  ecosystem research, writes the report.
- `docs/nvim-audit-YYYY-MM-DD.md` — the report from each run.

Measurement is split from reasoning so a bad number can be debugged without
re-running the whole audit.

## Contract

The audit never edits config. Findings that warrant an edit ship as an exact
diff in the report, unapplied.

## Report tiers

Findings are tiered by how much they should be trusted, not by topic:

- **Verified** — backed by a measurement or cited source, shown inline.
- **Judgment call** — reasoned from the config, not measured.
- **Experimental** — keymap ergonomics, inferred rather than measured. Each
  run checks whether the last run's experimental suggestions were adopted, so
  the tier earns or loses credibility instead of repeating itself.

## Cadence

Quarterly is about right. The ecosystem phase is the slow part and is skipped
when the nvim version has not moved since the last report.

## Running the measurement alone

    ./bin/nvim-audit-evidence.sh /tmp/audit-check
    jq -r '.[] | select(.executable==false) | .name' /tmp/audit-check/tools.json

That second command answers "is anything I have configured actually missing
from PATH" without involving Claude at all.
```

- [ ] **Step 2: Add the script to CLAUDE.md's Vendored Tools list**

Append this bullet to the existing "Vendored Tools" list in `CLAUDE.md`:

```markdown
- **`bin/nvim-audit-evidence.sh`** — read-only measurement pass for the config health audit (startup timing, lazy stats, hot autocmds, keymap dump, tool liveness, health, oldfiles drift). Writes raw output to `~/.cache/nvim-audit/<date>` by default. Driven by the `/nvim-audit` slash command. Full reference: [`docs/nvim-audit.md`](docs/nvim-audit.md).
```

- [ ] **Step 3: Verify the doc links resolve**

```bash
ls docs/nvim-audit.md bin/nvim-audit-evidence.sh .claude/commands/nvim-audit.md
grep -n "nvim-audit" CLAUDE.md
```

Expected: all three files listed, and one new `CLAUDE.md` line referencing them.

- [ ] **Step 4: Commit**

```bash
git add docs/nvim-audit.md CLAUDE.md
git commit -m "docs(audit): reference doc and CLAUDE.md entry for nvim-audit"
```

---

### Task 6: End-to-end trial run

**Files:**
- Creates: `docs/nvim-audit-<today>.md` (the first real report)

- [ ] **Step 1: Run the full command**

In an interactive session, run `/nvim-audit`.

- [ ] **Step 2: Check the report against its own rules**

This is the acceptance test for the whole feature. The report must satisfy:

- Every **Verified** finding shows its evidence inline (a number, a filename, or a URL).
- Every **ecosystem** claim carries a source URL. Any uncited assertion is a bug — fix the command's wording, not just the report.
- No config file was modified: `git status` shows only the new report.
- Findings name `file:line`.
- The nvim version and research date appear near the top.

- [ ] **Step 3: Confirm read-only contract held**

```bash
git status --porcelain
```

Expected: only `docs/nvim-audit-<today>.md` as untracked. **Any modification to `init.lua`, `lua/`, or `after/` is a contract violation** — revert it and fix the command file's constraints.

- [ ] **Step 4: Commit the first report**

```bash
git add docs/nvim-audit-*.md
git commit -m "docs(audit): first nvim config audit report"
```

---

## Self-Review Notes

**Spec coverage:** Phase 1 measurements → Tasks 1–3. Phase 2 ecosystem → Task 4's command file. Report tiering → Task 4. Work profile with drift cross-check → Task 4. Keymap two-standard split → Task 4. Read-only contract → Global Constraints and Task 6 Step 3. Existing-material references → Task 4. Out-of-scope items → Task 4.

**Deviation from spec, deliberate:** the spec put Phase 1 commands inside the command file. This plan extracts them to `bin/nvim-audit-evidence.sh`. Reason: a measurement pass written as prose cannot be run or tested independently, and the repo already has the `bin/` standalone-tool convention. The spec's intent — same commands every run, diffable reports — is better served by a script.

**Baselines are measured, not assumed.** The expected values in verification steps (254ms startup, 144 plugins / 53 loaded, 409 keymaps, 16 hot autocmds) were measured on this config on 2026-07-21. They will drift; treat a mismatch as a signal to look, not as a failure.
