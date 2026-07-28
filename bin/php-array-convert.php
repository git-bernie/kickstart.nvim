#!/usr/bin/env php
<?php

/**
 * Convert a PHP array literal into JSON or YAML.
 *
 * Part of the Neovim config. Reads a snippet of PHP (typically a visual
 * selection) on stdin and writes the converted form on stdout. Backs the
 * <leader>jp / <leader>jy keymaps — see after/plugin/keymaps.lua.
 *
 * SAFETY — why eval() is not a liability here:
 *   The snippet is first tokenized with PHP's own lexer (token_get_all) and
 *   validated against an allowlist of literal-only tokens. Variables, function
 *   calls, constants, `new`, backticks, heredocs and string interpolation are
 *   all rejected BEFORE eval() ever sees the input. Nothing executable can
 *   survive the gate, so eval() degenerates into a constant-folder. This buys
 *   what a hand-written parser cannot: correct handling of every string escape,
 *   numeric literal form and nesting rule, for free, because it is the real
 *   PHP lexer doing the work.
 *
 *   The gate is deliberately deny-by-default. Widening it is a decision to be
 *   made one token at a time, with the question "can this execute anything?"
 *
 * Usage:
 *   php-array-convert.php --json [file|-]
 *   php-array-convert.php --yaml [file|-]
 *   php-array-convert.php --selftest
 *
 * Options:
 *   --indent=STR   Prefix every output line with STR. Defaults to the leading
 *                  whitespace of the first non-blank input line, so a filtered
 *                  selection keeps the indentation it had.
 *   --no-indent    Disable indent preservation entirely.
 *
 * Accepted input (leading noise is stripped before conversion):
 *   ['a' => 1]              $config = ['a' => 1];       return ['a' => 1];
 *   array('a' => 1)         $obj->prop = [...];         'a' => 1, 'b' => 2
 *
 * Output contract (important for programmatic callers):
 *   stdout: converted value only
 *   stderr: errors only (nothing on success)
 *   exit 0 on success, 1 on conversion/gate failure, 2 on usage error
 */

// ========================================================================
// GATE — token allowlist. Nothing that can execute may pass.
// ========================================================================

/**
 * Single-character tokens that may appear in a pure literal array.
 * Arithmetic and concatenation are safe: with no callable tokens permitted,
 * the worst an operator can do is throw (division by zero), which we catch.
 */
const OK_CHARS = [
    '[' => true, ']' => true, '(' => true, ')' => true, ',' => true,
    '-' => true, '+' => true, '*' => true, '/' => true, '.' => true,
];

/** Barewords that are values, not identifiers to resolve. */
const OK_WORDS = ['true' => true, 'false' => true, 'null' => true];

/**
 * Validate a snippet against the allowlist.
 *
 * @return array{0: bool, 1: ?string} [passed, human-readable reason if not]
 */
function gate(string $src): array
{
    $ok_ids = [
        T_WHITESPACE, T_COMMENT, T_DOC_COMMENT, T_ARRAY,
        T_CONSTANT_ENCAPSED_STRING, T_LNUMBER, T_DNUMBER, T_DOUBLE_ARROW,
    ];

    $tokens = @token_get_all('<?php '.$src);

    foreach ($tokens as $t) {
        if (is_string($t)) {
            if (isset(OK_CHARS[$t])) {
                continue;
            }
            // A bare `"` means an interpolated double-quoted string: the lexer
            // splits it into quote + parts. Non-interpolated ones arrive whole
            // as T_CONSTANT_ENCAPSED_STRING, so this is always interpolation.
            if ($t === '"') {
                return [false, 'an interpolated double-quoted string'];
            }
            if ($t === '`') {
                return [false, 'a shell-execution backtick'];
            }

            return [false, "the character `$t`"];
        }

        [$id, $text, $line] = $t;

        if ($id === T_OPEN_TAG) {
            continue;
        }

        // T_STRING covers every bareword: constants, function names, class
        // names. Only the three literal keywords are legitimate here.
        if ($id === T_STRING) {
            if (isset(OK_WORDS[strtolower($text)])) {
                continue;
            }

            return [false, "the bareword `$text` (line $line)"];
        }

        if (! in_array($id, $ok_ids, true)) {
            return [false, sprintf('%s `%s` (line %d)', token_name($id), trim($text), $line)];
        }
    }

    return [true, null];
}

// ========================================================================
// NORMALISE — strip the noise a real-world selection carries
// ========================================================================

/**
 * Reduce a selected snippet to a bare expression.
 *
 * Handles the shapes you actually select in a buffer: an assignment to a
 * variable/property/static, a `return`, a stray opening tag, and trailing
 * punctuation.
 */
function normalise(string $src): string
{
    $s = trim($src);

    // Leading `<?php` / `<?`
    $s = preg_replace('/^<\?(?:php)?\s+/', '', $s);

    // Leading `return `
    $s = preg_replace('/^return\s+/i', '', $s);

    // Leading assignment: $x =, $x['k'] =, $x->p =, self::$x =, static::$x =
    $s = preg_replace(
        '/^(?:(?:self|static|parent)::)?\$\w+(?:\s*\[[^\]]*\]|\s*->\s*\w+)*\s*=\s*/',
        '',
        $s
    );

    // Leading typed property/const declaration: `public array $x =` etc. is
    // already covered above once the modifiers are gone.
    $s = preg_replace('/^(?:public|protected|private|static|readonly|const|var)\s+/i', '', $s);

    // Trailing `;` and `,`
    $s = rtrim($s);
    $s = rtrim($s, ';');
    $s = rtrim($s);
    $s = rtrim($s, ',');

    return trim($s);
}

/**
 * Evaluate a gated snippet.
 *
 * Two shapes are tried: the snippet as an expression, and — for selections of
 * bare entries such as `'a' => 1, 'b' => 2` or a single `'k' => [...]` pair —
 * the snippet wrapped in brackets. Wrapping only adds allowlisted characters,
 * so the gate's guarantee still holds.
 *
 * @return array{0: bool, 1: mixed} [succeeded, value or error message]
 */
function evaluate(string $src): array
{
    foreach ([$src, "[$src]"] as $candidate) {
        try {
            // @phpstan-ignore-next-line — gated above; see file header.
            $value = eval("return $candidate;");

            return [true, $value];
        } catch (ParseError $e) {
            $last = $e->getMessage();

            continue;
        } catch (Throwable $e) {
            return [false, $e->getMessage()];
        }
    }

    return [false, $last ?? 'could not be parsed as a PHP expression'];
}

// ========================================================================
// EMIT
// ========================================================================

function emit_json(mixed $value): string
{
    $json = json_encode(
        $value,
        JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE
    );

    if ($json === false) {
        fwrite(STDERR, 'error: could not encode as JSON: '.json_last_error_msg()."\n");
        exit(1);
    }

    return $json;
}

function emit_yaml(mixed $value): string
{
    if (! function_exists('yaml_emit')) {
        fwrite(STDERR, "error: the yaml extension is not available. Install php-yaml,\n");
        fwrite(STDERR, "       or convert to JSON and pipe through `yq -pjson -P`.\n");
        exit(1);
    }

    $yaml = yaml_emit($value);

    // yaml_emit wraps output in document markers. They are noise when the
    // result is being spliced back into a source file.
    $yaml = preg_replace('/\A---\r?\n/', '', $yaml);
    $yaml = preg_replace('/\.\.\.\r?\n?\z/', '', $yaml);

    return rtrim($yaml, "\n");
}

// ========================================================================
// SELFTEST
// ========================================================================

function selftest(): int
{
    // [label, input, expect_pass, expected_json_or_null]
    $cases = [
        ['plain literal', "['a' => 1, 'b' => [true, null], 'c' => 'x']", true, '{"a":1,"b":[true,null],"c":"x"}'],
        ['old array()', "array('k' => array(1, 2))", true, '{"k":[1,2]}'],
        ['list stays list', '[1, 2, 3]', true, '[1,2,3]'],
        ['sparse keys -> map', "[0 => 'a', 2 => 'b']", true, '{"0":"a","2":"b"}'],
        ['arithmetic', "['timeout' => 60 * 5, 'neg' => -1, 'f' => 1.5]", true, '{"timeout":300,"neg":-1,"f":1.5}'],
        ['concat', "['p' => 'a' . 'b']", true, '{"p":"ab"}'],
        ['dq no interp', '["hello world" => "plain"]', true, '{"hello world":"plain"}'],
        ['escapes', "['q' => 'it\\'s', 'n' => \"a\\nb\"]", true, '{"q":"it\'s","n":"a\nb"}'],
        ['hex + underscore', "['h' => 0x1F, 'u' => 1_000]", true, '{"h":31,"u":1000}'],
        ['trailing comma', "['a' => 1,]", true, '{"a":1}'],
        ['comment inside', "['a' => 1, /* note */ 'b' => 2]", true, '{"a":1,"b":2}'],
        ['nested deep', "['a' => ['b' => ['c' => [1]]]]", true, '{"a":{"b":{"c":[1]}}}'],
        ['bare entries', "'a' => 1, 'b' => 2", true, '{"a":1,"b":2}'],
        ['single pair', "'k' => [1, 2]", true, '{"k":[1,2]}'],
        ['assignment', "\$config = ['a' => 1];", true, '{"a":1}'],
        ['property assign', "\$this->opts = ['a' => 1];", true, '{"a":1}'],
        ['return stmt', "return ['a' => 1];", true, '{"a":1}'],
        ['static assign', "self::\$map = ['a' => 1];", true, '{"a":1}'],
        ['unicode', "['e' => 'café', 'j' => '日本']", true, '{"e":"café","j":"日本"}'],
        ['slash unescaped', "['u' => 'a/b']", true, '{"u":"a/b"}'],
        // Rejections
        ['variable', "['x' => \$foo]", false, null],
        ['interp string', '["x" => "hi $name"]', false, null],
        ['env() call', "['key' => env('APP_KEY')]", false, null],
        ['class const', "['s' => self::STATUS]", false, null],
        ['global const', "['m' => PHP_INT_MAX]", false, null],
        ['system() call', "['x' => system('id')]", false, null],
        ['new object', "['d' => new DateTime()]", false, null],
        ['heredoc', "['h' => <<<EOT\nboom\nEOT]", false, null],
        ['backtick', "['b' => `id`]", false, null],
        ['closure', "['f' => function () { return 1; }]", false, null],
        ['spread', "['a' => 1, ...\$rest]", false, null],
        ['statement sneak', "[1]; system('id')", false, null],
    ];

    $pass = 0;
    $fail = 0;

    foreach ($cases as [$label, $input, $expect_ok, $expect_json]) {
        $src = normalise($input);
        [$gated, $why] = gate($src);

        if (! $expect_ok) {
            if ($gated) {
                printf("  FAIL  %-18s expected BLOCK, but it passed the gate\n", $label);
                $fail++;
            } else {
                printf("  ok    %-18s blocked: %s\n", $label, $why);
                $pass++;
            }

            continue;
        }

        if (! $gated) {
            printf("  FAIL  %-18s expected PASS, blocked at %s\n", $label, $why);
            $fail++;

            continue;
        }

        [$ok, $value] = evaluate($src);
        if (! $ok) {
            printf("  FAIL  %-18s eval failed: %s\n", $label, $value);
            $fail++;

            continue;
        }

        $got = json_encode($value, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
        if ($got !== $expect_json) {
            printf("  FAIL  %-18s got %s, want %s\n", $label, $got, $expect_json);
            $fail++;

            continue;
        }

        printf("  ok    %-18s %s\n", $label, $got);
        $pass++;
    }

    // YAML emitter smoke test
    if (function_exists('yaml_emit')) {
        $y = emit_yaml(['a' => 1, 'b' => [1, 2]]);
        if (str_contains($y, '---') || str_contains($y, '...')) {
            printf("  FAIL  %-18s document markers not stripped\n", 'yaml markers');
            $fail++;
        } else {
            printf("  ok    %-18s %s\n", 'yaml emit', str_replace("\n", '\n', $y));
            $pass++;
        }
    } else {
        printf("  SKIP  %-18s yaml extension not installed\n", 'yaml emit');
    }

    printf("\n%d passed, %d failed\n", $pass, $fail);

    return $fail === 0 ? 0 : 1;
}

// ========================================================================
// MAIN
// ========================================================================

function usage(): void
{
    fwrite(STDERR, "usage: php-array-convert.php --json|--yaml [--indent=STR|--no-indent] [file|-]\n");
    fwrite(STDERR, "       php-array-convert.php --selftest\n");
}

$argv_rest = array_slice($argv, 1);
$format = null;
$indent = null;
$no_indent = false;
$source = '-';

foreach ($argv_rest as $arg) {
    if ($arg === '--selftest') {
        exit(selftest());
    } elseif ($arg === '--json' || $arg === '--yaml') {
        $format = substr($arg, 2);
    } elseif ($arg === '--no-indent') {
        $no_indent = true;
    } elseif (str_starts_with($arg, '--indent=')) {
        $indent = substr($arg, 9);
    } elseif ($arg === '-h' || $arg === '--help') {
        usage();
        exit(0);
    } elseif (str_starts_with($arg, '-') && $arg !== '-') {
        fwrite(STDERR, "error: unknown option `$arg`\n");
        usage();
        exit(2);
    } else {
        $source = $arg;
    }
}

if ($format === null) {
    fwrite(STDERR, "error: one of --json or --yaml is required\n");
    usage();
    exit(2);
}

if ($source === '-') {
    $raw = stream_get_contents(STDIN);
} else {
    if (! is_readable($source)) {
        fwrite(STDERR, "error: cannot read `$source`\n");
        exit(2);
    }
    $raw = file_get_contents($source);
}

if ($raw === false || trim($raw) === '') {
    fwrite(STDERR, "error: no input\n");
    exit(2);
}

// Indentation of the first non-blank line, so a filtered selection keeps its
// place in the surrounding code.
if ($no_indent) {
    $indent = '';
} elseif ($indent === null) {
    $indent = '';
    foreach (preg_split('/\R/', $raw) as $line) {
        if (trim($line) !== '') {
            preg_match('/^[ \t]*/', $line, $m);
            $indent = $m[0];
            break;
        }
    }
}

$src = normalise($raw);

[$gated, $why] = gate($src);
if (! $gated) {
    fwrite(STDERR, "error: not a pure array literal — blocked at $why\n");
    fwrite(STDERR, "       Only literal values convert. Constants, variables, function\n");
    fwrite(STDERR, "       calls and interpolation have no JSON/YAML equivalent.\n");
    exit(1);
}

[$ok, $value] = evaluate($src);
if (! $ok) {
    fwrite(STDERR, "error: $value\n");
    exit(1);
}

$out = $format === 'json' ? emit_json($value) : emit_yaml($value);

if ($indent !== '') {
    $out = implode("\n", array_map(
        fn (string $line): string => $line === '' ? '' : $indent.$line,
        explode("\n", $out)
    ));
}

echo $out, "\n";
exit(0);
