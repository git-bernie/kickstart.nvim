local ls = require 'luasnip'
local s = ls.snippet
local i = ls.insert_node
local t = ls.text_node
local c = ls.choice_node
local fmt = require('luasnip.extras.fmt').fmt
local rep = require('luasnip.extras').rep

return {
  -- Script opening: <?php, autoload, the use statements every Capsule
  -- script needs. Drop this in first, then expand more snippets below it.
  -- Trigger: illhead
  s(
    'illhead',
    t {
      '<?php',
      '',
      "require 'vendor/autoload.php';",
      '',
      'use Illuminate\\Database\\Capsule\\Manager as Capsule;',
      'use Illuminate\\Support\\Collection;',
      '',
    }
  ),

  -- phpdotenv loader. The "unsafe" variant uses putenv() so getenv()
  -- works — that "unsafe" is about thread-safety, irrelevant for CLI.
  -- One-time setup:  composer require vlucas/phpdotenv
  -- Trigger: illenv
  s(
    'illenv',
    t {
      "// 'unsafe' = uses putenv() so getenv() works; fine for CLI.",
      '\\Dotenv\\Dotenv::createUnsafeImmutable(__DIR__)->load();',
    }
  ),

  -- Illuminate Capsule bootstrap (sqlite) — returns a typed Connection
  -- so callers get full LSP/PHPStan support on ->table(), ->select(), etc.
  -- Trigger: illsqlite
  s(
    'illsqlite',
    fmt(
      [[
function bootstrap_db(string $dbFile): \Illuminate\Database\Connection
{{
    $capsule = new \Illuminate\Database\Capsule\Manager;
    $capsule->addConnection([
        'driver'   => 'sqlite',
        'database' => $dbFile,
        'prefix'   => '',
    ]);
    return $capsule->getConnection();
}}
]],
      {}
    )
  ),

  -- Illuminate Capsule bootstrap (mysql, env-driven). Set DB_HOST, DB_PORT,
  -- DB_USERNAME, DB_PASSWORD in your environment (or .env loaded externally).
  -- Trigger: illmysql
  s(
    'illmysql',
    fmt(
      [[
function bootstrap_db(): \Illuminate\Database\Connection
{{
    $capsule = new \Illuminate\Database\Capsule\Manager;
    $capsule->addConnection([
        'driver'    => 'mysql',
        'host'      => getenv('DB_HOST') ?: '127.0.0.1',
        'port'      => (int) (getenv('DB_PORT') ?: 3306),
        'database'  => getenv('{db_env}') ?: '{db_default}',
        'username'  => getenv('DB_USERNAME'),
        'password'  => getenv('DB_PASSWORD'),
        'charset'   => 'utf8mb4',
        'collation' => 'utf8mb4_unicode_ci',
        'prefix'    => '',
    ]);
    return $capsule->getConnection();
}}
]],
      {
        db_env     = i(1, 'DB_DATABASE'),
        db_default = i(2, 'my_db'),
      }
    )
  ),

  -- Illuminate Capsule bootstrap (pgsql, env-driven). Set DB_HOST, DB_PORT,
  -- DB_USERNAME, DB_PASSWORD in your environment (or .env loaded externally).
  -- Trigger: illpgsql
  s(
    'illpgsql',
    fmt(
      [[
function bootstrap_db(): \Illuminate\Database\Connection
{{
    $capsule = new \Illuminate\Database\Capsule\Manager;
    $capsule->addConnection([
        'driver'   => 'pgsql',
        'host'     => getenv('DB_HOST') ?: '127.0.0.1',
        'port'     => (int) (getenv('DB_PORT') ?: 5432),
        'database' => getenv('{db_env}') ?: '{db_default}',
        'username' => getenv('DB_USERNAME'),
        'password' => getenv('DB_PASSWORD'),
        'charset'  => 'utf8',
        'prefix'   => '',
        'schema'   => '{schema}',
        'sslmode'  => '{sslmode}',
    ]);
    return $capsule->getConnection();
}}
]],
      {
        db_env     = i(1, 'DB_DATABASE'),
        db_default = i(2, 'my_db'),
        schema     = i(3, 'public'),
        sslmode    = c(4, { t 'prefer', t 'require', t 'disable' }),
      }
    )
  ),

  -- Bulk-lookup / data-enrichment idiom:
  --   pluck input keys -> single whereIn -> keyBy for O(1) joining.
  -- Trigger: illbulkjoin
  s(
    'illbulkjoin',
    fmt(
      [[
$lookup = ${conn}->table('{table}')
    ->whereIn('{key}', ${source}->pluck('{input_key}')->filter()->unique())
    ->get(['{key2}', '{cols}'])
    ->keyBy('{key3}');
]],
      {
        conn      = i(1, 'db'),
        table     = i(2, 'table_name'),
        key       = i(3, 'key_col'),
        source    = i(4, 'rows'),
        input_key = i(5, 'input_key'),
        key2      = rep(3),
        cols      = i(6, 'other_col'),
        key3      = rep(3),
      }
    )
  ),

  -- PhpSpreadsheet: load an .xlsx into a plain row-array.
  -- Trigger: xlsxread
  s(
    'xlsxread',
    t {
      'function load_xlsx(string $path): array',
      '{',
      "    $reader = \\PhpOffice\\PhpSpreadsheet\\IOFactory::createReader('Xlsx')->setReadDataOnly(true);",
      '',
      '    return $reader->load($path)->getActiveSheet()->toArray();',
      '}',
    }
  ),
}
