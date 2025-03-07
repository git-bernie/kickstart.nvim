return {
  'bmewburn/vscode-intelephense',
  enabled = false, -- enabled via Mason
  config = function()
    print 'here here here'
  end,
  --cmd = { 'intelephense', '--stdio' },
  settings = {
    filetypes = { 'php', 'blade' },
    intelephense = {
      root_dir = function()
        return vim.loop.cwd()
      end,
      -- intelephense.files.maxSize
      files = {
        maxSize = 15000000,
        associations = {
          ['*.ctp'] = 'php',
        },
      },
      stubs = {
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
        'mcrypt',
        'memcache',
        'memcached',
        'msgpack',
        'mysqli',
        'oci8',
        'odbc',
        'openssl',
        'pcntl',
        'pcre',
        'PDO',
        'PDO_ODBC',
        'pdo_dblib',
        'pdo_ibm',
        'pdo_mysql',
        'pdo_pgsql',
        'pdo_snowflake',
        'pdo_sqlite',
        'pgsql',
        'Phar',
        'posix',
        'pspell',
        'readline',
        'recode',
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
        'superglobals',
        'sysvmsg',
        'sysvsem',
        'sysvshm',
        'tidy',
        'tokenizer',
        'wddx',
        'xml',
        'xmlreader',
        'xmlrpc',
        'xmlwriter',
        'xsl',
        'Zend OPcache',
        'zip',
        'zlib',
      },
    },
  },
}
