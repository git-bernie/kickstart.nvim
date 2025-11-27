return {
  'bmewburn/vscode-intelephense',
  enabled = true, -- Let's not enable via Mason
  config = function()
    -- print 'reading intelephense.lua'
    local php_version = '8.3.0' -- default
    local include_paths = { 'app', 'lib', 'vendor' }

    -- See and set in .nvim.lua in project root_dir.
    if type(vim.g.local_php_version) == 'string' and vim.g.local_php_version ~= '' then
      php_version = vim.g.local_php_version
    end
    -- print('local php_version now ' .. tostring(php_version))

    if type(vim.g.local_include_paths) == 'table' then
      include_paths = vim.g.local_include_paths
    end
    local ok, inspected = pcall(vim.inspect, include_paths)
    -- print('local include_paths now ' .. (ok and inspected or 'error inspecting include_paths'))

    vim.lsp.config('intelephense', {
      -- vim.lsp.config().intelephense.setup {
      -- require('lspconfig').intelephense.setup {
      settings = {
        intelephense = {
          docs = {
            description = [[
          https://intelephense.com/

          `intelephense` can be installed via `npm`:
          ```sh
          npm install -g intelephense
          ```
          
        ```lua
        -- See https://github.com/bmewburn/intelephense-docs/blob/master/installation.md#initialisation-options
        init_options = {
          storagePath = …, -- Optional absolute path to storage dir. Defaults to os.tmpdir().
          globalStoragePath = …, -- Optional absolute path to a global storage dir. Defaults to os.homedir().
          licenceKey = …, -- Optional licence key or absolute path to a text file containing the licence key.
          clearCache = …, -- Optional flag to clear server state. State can also be cleared by deleting {storagePath}/intelephense
        }
        -- See https://github.com/bmewburn/intelephense-docs
        settings = {
          intelephense = {
            files = {
              maxSize = 1000000;
            };
          };
        }
        ```
        ]],
          },
          environment = {
            phpVersion = php_version, -- default 8.3.0, semver
            -- includePaths = { 'app', 'vendor/mailchimp', 'vendor/laravel', },
            -- includePaths = { 'app', 'lib', 'lib/Cake/**' },
            includePaths = include_paths,
          },
          format = {
            enable = true, -- default, but JIC
          },
          client = {
            autoCloseDocCommentDoSuggest = true,
            -- diagnosticsIgnoreErrorFeature = true, -- not a real setting, from coc-intelephense
          },
          files = {
            maxSize = 2e7, -- 20000000,
            associations = {
              '*.blade.php',
              '*.php',
              '*.phtml',
              '*.ctp',
            },
          },
          stubs = {
            '_ide_helper.php',
            '_ide_helper_models',
            'bcmath',
            'bz2',
            'calendar',
            'Core',
            'ctype',
            'curl',
            'date',
            'dba',
            'dom',
            'enchant',
            'exif',
            'FFI',
            'fileinfo',
            'filter',
            'ftp',
            'gd',
            'gettext',
            'gmp',
            'hash',
            'iconv',
            'igbinary',
            'imagick',
            'imap',
            'intl',
            'json',
            'ldap',
            'libxml',
            'mbstring',
            'memcached',
            'msgpack',
            'mysqli',
            'mysqlnd',
            'oci8',
            'odbc',
            'openssl',
            'pcntl',
            'pcre',
            'PDO',
            'PDO_ODBC',
            'pdo_dblib',
            'pdo_mysql',
            'pdo_pgsql',
            'pdo_snowflake',
            'pdo_sqlite',
            'pgsql',
            'Phar',
            'posix',
            'pspell',
            'random',
            'readline',
            'recode',
            'redis',
            'Reflection',
            'session',
            'shmop',
            'SimpleXML',
            'snmp',
            'soap',
            'sockets',
            'sodium',
            'SPL',
            'sqlite3',
            'standard',
            'sysvmsg',
            'sysvsem',
            'sysvshm',
            'tidy',
            'tokenizer',
            'xdebug',
            'xml',
            'xmlreader',
            'xmlrpc',
            'xmlwriter',
            'xsl',
            'yaml',
            'Zend OPcache',
            'zip',
            'zlib',
          },
          phpdoc = {
            propertyTemplate = {
              summary = '${SYMBOL_NAME} - ${SYMBOL_TYPE}',
              description = '',
              tags = {
                '@property ${SYMBOL_TYPE} ${SYMBOL_NAME}',
              },
            },
            functionTemplate = {
              summary = '${SYMBOL_NAME}() - ${SYMBOL_TYPE}',
              description = '',
              tags = {
                '@param ${SYMBOL_TYPE} ${SYMBOL_NAMESPACE} ${SYMBOL_NAME}',
                '@return ${SYMBOL_TYPE} ${SYMBOL_NAME}',
              },
            },
            classTemplate = {
              description = '${SYMBOL_TYPE} Class description',
              summary = '',
              tags = {
                '@package ${SYMBOL_NAME}',
                '@author',
                '@version',
                '@access public',
                '@see',
              },
            },
            varTemplate = { -- this does not exist, but would be nice if it did
              tags = {
                '@var ${SYMBOL_TYPE} ${SYMBOL_NAME}',
              },
            },
          },
          -- root_dir = require('lspconfig').util.root_pattern('composer.json', '.git', 'package.json'),
        },
      },

      -- Attach capabilities from the completion engine (blink.cmp) to the LSP client
      capabilities = vim.lsp.protocol.make_client_capabilities(),
    })
  end,
  --cmd = { 'intelephense', '--stdio' },
}
