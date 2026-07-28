# php-array-convert — PHP array literal → JSON / YAML

Select a PHP array in a buffer, press a key, and it becomes JSON or YAML in
place. Useful for lifting a Laravel/CakePHP config block into a `.json`
fixture, an API payload, a `docker-compose` snippet, or a ticket comment.

```
   visual selection            ┌──────────────────────────┐
   ['a' => 1, 'b' => [2]]  ──▶ │ bin/php-array-convert.php │ ──▶ {"a":1,"b":[2]}
                               │  token gate → eval        │
        <leader>jp / <leader>jy└──────────────────────────┘     replaces selection
```

## Files

- `bin/php-array-convert.php` — the converter. Standalone; no Composer, no
  framework, no autoloader.
- `after/plugin/keymaps.lua` — the `<leader>jp` / `<leader>jy` keymaps.

## Default keymaps

Both are **visual mode only** (`x`), and both **replace the selection**.
`u` undoes the conversion like any other edit.

- **`<leader>jp`** — selected PHP array → JSON
- **`<leader>jy`** — selected PHP array → YAML

Select whole lines (`V`) — the tool reads the selected lines, not a
character range.

## Why `eval()` is safe here

The obvious way to read a PHP array literal is `eval`, and the obvious
objection is that `eval` runs arbitrary code. Both are true. The resolution
is to make sure nothing runnable ever reaches it.

Before evaluating, the snippet is tokenised with **PHP's own lexer**
(`token_get_all`) and every token is checked against an allowlist of
literal-only tokens. Variables, function calls, constants, `new`, backticks,
heredocs and string interpolation are all rejected at that gate. What
survives cannot execute — no callable token exists in the stream — so `eval`
degenerates into a constant-folder.

This is why the tool is ~350 lines instead of the ~250-line recursive-descent
parser the safe-looking alternative would have required. Using the real lexer
means every string escape, numeric literal form and nesting rule is handled
correctly for free, because it is the same code PHP itself uses.

**The gate is deny-by-default.** Widening it is a deliberate decision, made
one token at a time, answering "can this execute anything?" Arithmetic
(`+ - * / .`) is allowed precisely because with no callable tokens permitted,
the worst an operator can do is throw.

## What converts, and what does not

**Converts**

- `['a' => 1, 'b' => [true, null]]` — modern syntax
- `array('k' => array(1, 2))` — legacy syntax
- `['timeout' => 60 * 5]` → `300` — arithmetic is constant-folded
- `['p' => 'a' . 'b']` → `"ab"` — literal concatenation
- `['h' => 0x1F, 'u' => 1_000]` — hex and underscore-separated numbers
- `"plain double quotes"`, `'it\'s'`, `"a\nb"` — all escapes
- Trailing commas, `/* comments */`

Leading noise is stripped automatically, so you can select sloppily:
`$config = [...];`, `$this->opts = [...];`, `return [...];`,
`self::$map = [...];`, or a bare fragment like `'a' => 1, 'b' => 2`.

**Rejected — by design**

- `$foo` — a variable has no value at conversion time
- `"hi $name"` — interpolation is a runtime operation
- `env('APP_KEY')`, `config('x')`, `system('id')` — function calls
- `self::STATUS`, `PHP_INT_MAX` — constants
- `new DateTime()`, closures, `...$spread`, heredocs, backticks

The rejections are the point, not a limitation. `PHP_INT_MAX` has no JSON
equivalent; silently baking in `9223372036854775807` would misrepresent what
the source said. When a snippet is rejected you get the offending token and
its line, and **the buffer is left untouched**.

## Behaviour notes

- **Indentation is preserved.** The leading whitespace of the first non-blank
  selected line is applied to every output line, so the result sits where the
  array sat. Override with `--indent=STR`, disable with `--no-indent`.
- **Lists stay lists.** `[1, 2, 3]` → `[1,2,3]`, while a sparse or non-
  sequential array such as `[0 => 'a', 2 => 'b']` correctly becomes an object
  `{"0":"a","2":"b"}` — that is PHP's array/map ambiguity surfacing, not a bug.
- **YAML sequences are not indented under their key** (`b:\n- 1`). That is
  `yaml_emit`'s house style and is valid YAML. Pipe through `yq -P` if you
  want the indented form.
- **YAML document markers** (`---` / `...`) are stripped, since the output is
  usually being spliced into an existing file.

## Output contract (CRITICAL)

Programmatic callers depend on this:

- **stdout:** converted value only
- **stderr:** errors only (nothing on success)
- **exit 0** success · **exit 1** gate/conversion failure · **exit 2** usage

The keymap relies on this contract. It runs the converter via `vim.system`
and rewrites the buffer **only on exit 0** — deliberately *not* as a
`:'<,'>!cmd` filter like the neighbouring `jq`/`yq` maps. A filter replaces
the selection with whatever the command emitted, so a rejected snippet would
be silently deleted. That failure mode is unacceptable when the whole point
of the gate is to refuse input.

## Quick verification

```bash
# 33-case suite: conversions, escapes, and every rejection class
./bin/php-array-convert.php --selftest

# One-off from the shell
echo "['a' => 1, 'b' => [2, 3]]" | ./bin/php-array-convert.php --json
echo "['a' => 1]" | ./bin/php-array-convert.php --yaml

# Rejection: prints to stderr, exits 1, emits nothing on stdout
echo "['k' => env('APP_KEY')]" | ./bin/php-array-convert.php --json
```

## Requirements

- `php` on `PATH` (8.0+; uses `str_contains`, `str_starts_with`, match-free
  but modern string helpers). Verified against PHP 8.3.
- The **`yaml` extension** for `--yaml` only. If missing, the tool says so and
  points at `yq -pjson -P` as the fallback. JSON needs nothing extra —
  `json_encode` is always compiled in.

The keymaps are registered only when `php` is executable, matching the
`jq`/`yq` guards in `after/plugin/keymaps.lua`.

## Related

- [`lc-codec`](lc-codec.md) — the other standalone PHP helper in `bin/`
- `<leader>jx` — extract JSON from a log line into a float
- `<leader>jc` — show the CSV/TSV row under the cursor as JSON
- `<leader>yj` / `<leader>yk` — pretty-print JSON through `jq`
- `<leader>yq`, `:JsonToYaml` — JSON → YAML through `yq`
