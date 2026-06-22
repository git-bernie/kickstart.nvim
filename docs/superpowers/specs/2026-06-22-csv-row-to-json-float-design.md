# CSV row → JSON float (`<leader>jc`)

**Date:** 2026-06-22
**Status:** Approved (design)

## Summary

Add a keymap, `<leader>jc`, that inspects the CSV/TSV row under the cursor and
pops up a floating window showing that single row as pretty-printed JSON, keyed
by the header row. It mirrors the existing `<leader>jx` ("Extract JSON from log
line") feature in both UX and philosophy: a self-contained, dependency-light
helper that works on any buffer.

This is the CSV analogue of `jx`. Where `jx` finds JSON embedded in a log line
and reformats it, `jc` turns a CSV record into JSON so a single wide row can be
read as a vertical `heading: value` list.

## Motivation

Reading a single record in a wide CSV is painful horizontally. CsvView's border
mode aligns columns visually, but for one row you still scan left-to-right across
many columns. A vertical `heading: value` view (as JSON) makes one record
legible at a glance and is copy-pasteable.

## Goals

- One keymap (`<leader>jc`) that works on any CSV/TSV buffer without requiring
  `:CsvViewEnable` first.
- Correct handling of quoted CSV fields (commas inside quotes, escaped `""`).
- Output as pretty-printed JSON, column order preserved, all values as strings.
- Same float UX as `jx`: cursor-anchored, rounded border, `q`/`<Esc>`/`WinLeave`
  to close, `filetype=json` for highlighting, non-modifiable scratch buffer.

## Non-goals (YAGNI)

- Markdown or plain-text output formats.
- Type inference (numbers/booleans stay strings — faithful, no mangled zip codes).
- Delimiter sniffing beyond filetype heuristic.
- `header_lnum` override / using a header line other than line 1.
- Comment-line skipping (`#`, `//`).
- Reusing CsvView's internal parser or any CsvView API — `jc` is fully
  independent, like `jx`.
- Refactoring `jx`'s float-window code into a shared helper. The float recipe is
  duplicated inline in `jc` for now (deliberate; revisit later if a third
  consumer appears).

## Design

### Location

A single new keymap block in `after/plugin/keymaps.lua`, placed next to the
existing `<leader>jx` block (around line 347). Self-contained: no changes to
`jx`, no changes to `lua/custom/plugins/csvview.lua`.

### Behavior

1. Read **line 1** of the buffer as the header row.
2. Read the **current line** as the data row.
3. Choose the delimiter by filetype: `tsv` (or `.tsv` extension) → tab `\t`,
   otherwise comma `,`.
4. Split both lines using a small RFC-4180-aware splitter (see below).
5. Zip header fields with data fields into ordered `heading: value` pairs.
6. Build a JSON object string in column order, escaping each key and value via
   `vim.fn.json_encode`. Pretty-print by piping through `jq .` (NOT
   `--sort-keys`, so column order is preserved). If `jq` is unavailable or
   errors, fall back to the raw compact JSON string.
7. Display the result in a floating window (clone of the `jx` float recipe).

### Components (all local to the new keymap block)

- **`csv_split(line, delim)`** — the field splitter. The only non-trivial logic.
  Walks the string character by character:
  - Outside quotes: a `delim` ends the current field; a `"` at the start of a
    field begins a quoted field.
  - Inside quotes: `""` is a literal quote; a lone `"` ends the quoted section.
  - Returns a list of field strings with surrounding quotes removed and escaped
    quotes collapsed.
  - Single-line only (no multi-line quoted fields — out of scope).
- **`<leader>jc` keymap body** — orchestrates: read lines → pick delimiter →
  split → zip → encode → pretty-print → open float. Contains its own inline copy
  of the float-window creation/close logic.

### Data handling decisions

- **Values are strings.** Every cell is emitted as a JSON string. Lossless and
  never guesses a type wrong.
- **Column order preserved.** JSON built in header order; pretty-printed with
  `jq .` (no key sorting).
- **Column-count mismatch handled gracefully:**
  - More data fields than headers → extra fields get synthetic keys `field_N`
    (1-indexed by field position, e.g. `field_5`).
  - Fewer data fields than headers → missing trailing fields become `""`.
  - Never errors on ragged rows.

### Edge cases

- **Cursor on line 1 (the header row):** produces `header: header` pairs.
  Harmless and faithful; no special-casing.
- **Empty line, or a line that splits to nothing meaningful:** notify
  `"No CSV data on this line"` (WARN) and bail, mirroring `jx`'s
  "No valid JSON found" behavior.
- **`jq` missing:** fall back to the raw compact JSON string (still valid JSON,
  just unformatted).

### Float window (duplicated from `jx`, not shared)

- Scratch buffer (`nvim_create_buf(false, true)`), `bufhidden = 'wipe'`,
  `modifiable = false`, `filetype = 'json'`.
- `nvim_open_win` with `relative = 'cursor'`, `border = 'rounded'`,
  `style = 'minimal'`, centered title `" CSV row as JSON (q/<Esc> to close) "`.
- Width/height computed from content, clamped to a fraction of the editor size
  (same formula as `jx`).
- Close on `q`, `<Esc>`, and `WinLeave` (once).

## Testing

No Lua unit-test harness exists in this config, so verification is live, by
running the keymap against sample rows and inspecting the float / pasted output:

1. Clean comma row — basic `heading: value` mapping correct, order preserved.
2. Row with a `"quoted, comma"` field — comma inside quotes not split.
3. Row with an escaped `""` quote inside a quoted field — collapses to one `"`.
4. A `.tsv` file — tab delimiter chosen, fields split on tab.
5. Short (ragged) row — missing trailing fields become `""`.
6. Long row (more fields than headers) — extra fields keyed `field_N`.
7. Cursor on line 1 — `header: header` pairs (sanity, no crash).
8. Empty line — clean WARN notify, no float, no error.

Results shown to the user before the work is called done.

## Future extensions (explicitly deferred)

- Markdown table / plain-text output, selectable per invocation.
- Optional type inference behind a flag.
- A count prefix to use a different header line (`2<leader>jc`).
- Extracting the float recipe into a shared helper once a third consumer exists.
