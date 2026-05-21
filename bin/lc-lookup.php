#!/usr/bin/env php
<?php

/**
 * Standalone lookup-table dumper for LoanConnect (and similar) MySQL data.
 *
 * Companion to bin/lc-codec.php. Reads a manifest of "table-name => SELECT SQL"
 * entries and writes each result set as JSON into a cache directory. The
 * Neovim side (lua/lc-lookup.lua) reads those JSON files and feeds a picker.
 *
 * Why standalone (no Laravel): same reason as lc-codec.php — the lookup
 * picker has to work from any machine that can reach the DB, without
 * cloning the loanconnect repo. If you need Eloquent accessors / model
 * mutators, make a parallel artisan command in the LoanConnect project.
 *
 * Usage:
 *   lc-lookup.php list                            # list tables in manifest
 *   lc-lookup.php dump <table> [--out=<dir>]      # dump one table
 *   lc-lookup.php dump-all [--out=<dir>]          # dump all tables
 *   lc-lookup.php check                           # smoke-test the connection
 *
 * Connection (first match wins):
 *   1. $LC_DB_DSN  (full PDO DSN, e.g. "mysql:host=127.0.0.1;port=3306;dbname=loanconnect")
 *      with $LC_DB_USER / $LC_DB_PASS for credentials
 *   2. $LC_DB_HOST / $LC_DB_PORT / $LC_DB_NAME / $LC_DB_USER / $LC_DB_PASS
 *   3. ~/.config/lc-lookup/connection.json — { "dsn": "...", "user": "...", "pass": "..." }
 *      (chmod 600 it; this script refuses to read world-readable connection files)
 *
 * Manifest:
 *   ~/.config/lc-lookup/manifest.json — see docs/lc-lookup.md for format.
 *   Override with $LC_LOOKUP_MANIFEST.
 *
 * Cache (default --out):
 *   $XDG_CACHE_HOME/lc-lookup/ (falls back to ~/.cache/lc-lookup/)
 *   Override with $LC_LOOKUP_CACHE.
 *
 * Output contract (programmatic callers):
 *   stdout: nothing in dump modes (writes files); JSON listing in `list` mode
 *   stderr: errors and progress
 *   exit 0 on success, 1 on connection/SQL failure, 2 on usage error
 */
const VERSION = '1.0.0';

function fatal(string $msg, int $code = 1): never
{
    fwrite(STDERR, "lc-lookup: $msg\n");
    exit($code);
}

function info(string $msg): void
{
    fwrite(STDERR, "lc-lookup: $msg\n");
}

function home_dir(): string
{
    $home = getenv('HOME') ?: posix_getpwuid(posix_getuid())['dir'] ?? null;
    if (! $home) {
        fatal('cannot determine home directory');
    }

    return $home;
}

function config_dir(): string
{
    $xdg = getenv('XDG_CONFIG_HOME');

    return $xdg ? "$xdg/lc-lookup" : home_dir().'/.config/lc-lookup';
}

function default_cache_dir(): string
{
    if ($override = getenv('LC_LOOKUP_CACHE')) {
        return $override;
    }
    $xdg = getenv('XDG_CACHE_HOME');

    return $xdg ? "$xdg/lc-lookup" : home_dir().'/.cache/lc-lookup';
}

function manifest_path(): string
{
    return getenv('LC_LOOKUP_MANIFEST') ?: config_dir().'/manifest.json';
}

function load_manifest(): array
{
    $path = manifest_path();
    if (! is_readable($path)) {
        fatal("manifest not found: $path (see docs/lc-lookup.md)", 2);
    }
    $raw = file_get_contents($path);
    $data = json_decode($raw, true);
    if (! is_array($data) || ! isset($data['tables']) || ! is_array($data['tables'])) {
        fatal("manifest malformed: expected top-level { \"tables\": { ... } } in $path", 2);
    }
    foreach ($data['tables'] as $name => $entry) {
        if (! is_array($entry) || empty($entry['sql'])) {
            fatal("manifest entry '$name' missing 'sql' field", 2);
        }
    }

    return $data['tables'];
}

function load_connection(): array
{
    // Mode 1: explicit DSN env
    if ($dsn = getenv('LC_DB_DSN')) {
        return [
            'dsn' => $dsn,
            'user' => getenv('LC_DB_USER') ?: null,
            'pass' => getenv('LC_DB_PASS') ?: null,
        ];
    }

    // Mode 2: per-component env
    $host = getenv('LC_DB_HOST');
    $name = getenv('LC_DB_NAME');
    if ($host && $name) {
        $port = getenv('LC_DB_PORT') ?: '3306';

        return [
            'dsn' => "mysql:host=$host;port=$port;dbname=$name;charset=utf8mb4",
            'user' => getenv('LC_DB_USER') ?: null,
            'pass' => getenv('LC_DB_PASS') ?: null,
        ];
    }

    // Mode 3: connection.json file
    $path = config_dir().'/connection.json';
    if (is_readable($path)) {
        // Refuse to read world-readable files — this holds passwords.
        $perms = fileperms($path) & 0o777;
        if ($perms & 0o077) {
            fatal(sprintf('connection.json is mode %04o; chmod 600 it', $perms), 2);
        }
        $cfg = json_decode(file_get_contents($path), true);
        if (! is_array($cfg) || empty($cfg['dsn'])) {
            fatal('connection.json malformed: needs at least { "dsn": "..." }', 2);
        }

        return [
            'dsn' => $cfg['dsn'],
            'user' => $cfg['user'] ?? null,
            'pass' => $cfg['pass'] ?? null,
        ];
    }

    fatal('no connection configured. Set LC_DB_DSN or LC_DB_HOST/LC_DB_NAME, or create '.config_dir().'/connection.json (chmod 600)', 2);
}

function connect(): PDO
{
    $cfg = load_connection();
    try {
        $pdo = new PDO($cfg['dsn'], $cfg['user'], $cfg['pass'], [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES => false,
            PDO::ATTR_TIMEOUT => 5,
        ]);

        return $pdo;
    } catch (PDOException $e) {
        fatal('connection failed: '.$e->getMessage());
    }
}

function ensure_dir(string $dir): void
{
    if (is_dir($dir)) {
        return;
    }
    if (! @mkdir($dir, 0o755, true) && ! is_dir($dir)) {
        fatal("cannot create cache dir: $dir");
    }
}

function dump_table(PDO $pdo, string $name, array $entry, string $outDir): int
{
    $sql = $entry['sql'];
    info("dumping '$name' ...");
    $start = microtime(true);
    try {
        $rows = $pdo->query($sql)->fetchAll();
    } catch (PDOException $e) {
        fatal("query failed for '$name': ".$e->getMessage());
    }
    $payload = [
        'table' => $name,
        'refreshed_at' => date('c'),
        'source_sql' => $sql,
        'row_count' => count($rows),
        'rows' => $rows,
    ];
    $path = "$outDir/$name.json";
    $tmp = "$path.tmp";
    if (file_put_contents($tmp, json_encode($payload, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT)) === false) {
        fatal("cannot write $tmp");
    }
    // Atomic move so a partial write never replaces a good cache file.
    if (! rename($tmp, $path)) {
        fatal("cannot rename $tmp -> $path");
    }
    $elapsed = sprintf('%.2fs', microtime(true) - $start);
    info(sprintf('  -> %d rows in %s (%s)', count($rows), $elapsed, $path));

    return count($rows);
}

function parse_opts(array $argv): array
{
    $opts = ['out' => null];
    $rest = [];
    for ($i = 1; $i < count($argv); $i++) {
        $a = $argv[$i];
        if (str_starts_with($a, '--out=')) {
            $opts['out'] = substr($a, 6);
        } else {
            $rest[] = $a;
        }
    }

    return [$opts, $rest];
}

function usage(int $code = 2): never
{
    $version = VERSION;
    fwrite(STDERR, <<<TXT
        lc-lookup.php v$version — dump MySQL lookup tables to JSON for snacks.picker

        usage:
          lc-lookup.php list
          lc-lookup.php dump <table> [--out=<dir>]
          lc-lookup.php dump-all [--out=<dir>]
          lc-lookup.php check

        env:
          LC_DB_DSN / LC_DB_HOST / LC_DB_NAME / LC_DB_USER / LC_DB_PASS
          LC_LOOKUP_MANIFEST  (default: ~/.config/lc-lookup/manifest.json)
          LC_LOOKUP_CACHE     (default: ~/.cache/lc-lookup)


        TXT);
    exit($code);
}

[$opts, $args] = parse_opts($argv);
$cmd = $args[0] ?? null;

switch ($cmd) {
    case 'list':
        $tables = load_manifest();
        echo json_encode([
            'manifest' => manifest_path(),
            'tables' => array_keys($tables),
        ], JSON_PRETTY_PRINT)."\n";
        exit(0);

    case 'check':
        $pdo = connect();
        $stmt = $pdo->query('SELECT VERSION() AS v, DATABASE() AS db, NOW() AS now');
        $row = $stmt->fetch();
        info(sprintf('OK: MySQL %s, db=%s, server-time=%s', $row['v'], $row['db'] ?? 'NULL', $row['now']));
        exit(0);

    case 'dump':
        if (empty($args[1])) {
            usage();
        }
        $tables = load_manifest();
        $name = $args[1];
        if (! isset($tables[$name])) {
            fatal("unknown table '$name'. Available: ".implode(', ', array_keys($tables)), 2);
        }
        $outDir = $opts['out'] ?: default_cache_dir();
        ensure_dir($outDir);
        $pdo = connect();
        dump_table($pdo, $name, $tables[$name], $outDir);
        exit(0);

    case 'dump-all':
        $tables = load_manifest();
        $outDir = $opts['out'] ?: default_cache_dir();
        ensure_dir($outDir);
        $pdo = connect();
        $total = 0;
        foreach ($tables as $name => $entry) {
            $total += dump_table($pdo, $name, $entry, $outDir);
        }
        info("done. $total rows total across ".count($tables).' tables.');
        exit(0);

    default:
        usage();
}
