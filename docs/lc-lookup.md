# lc-lookup — LoanConnect picker for lender/partner/product IDs

Companion to [`lc-codec`](lc-codec.md). Where lc-codec answers *"what does this
encoded ID decode to?"*, lc-lookup answers *"what's Spring Financial's
lender_id?"* — fast fuzzy lookup over a JSON snapshot of the lookup tables.

```
                 ┌────────────────────────┐
   :LcLookupRefresh ──▶  bin/lc-lookup.php  ──▶  <project>/.nvim/lookup-cache/*.json
                 │   (PDO → MySQL)        │             │
                 └────────────────────────┘             ▼
                                                ┌──────────────────┐
   <leader>xL  ─────────────▶  lua/lc-lookup ◀──┤  snacks.picker   │
                                                └──────────────────┘
```

## Why a JSON cache, not a live DB query

Lender/partner tables change on the order of weeks, but you look up IDs
many times a day. Querying live for every lookup adds VPN/SSH-tunnel
round-trips to your editor and breaks the picker when the network is
flaky. A snapshot refreshed on demand is offline-capable, sub-100ms, and
the JSON files are even greppable from the shell.

For *ad-hoc* queries against changing data — scratchpad-style — use
[vim-dadbod-ui](#dadbod-ui-companion-setup) instead. The same `.nvim.lua`
configures both.

## Setup (recommended path: project-local `.nvim.lua`)

The cleanest setup puts everything in one file at the LoanConnect repo
root. Credentials live next to the project they belong to, scoped to
this nvim session, and a single source feeds both `lc-lookup` and
`vim-dadbod-ui`. Kickstart auto-sources `.nvim.lua` from the project
root (`exrc` is on by default) — first time you open nvim there it
prompts you to `:trust` the file.

### 1. Drop in `.nvim.lua`

A ready-to-edit template lives at
[`lc-lookup.nvim.lua.example`](lc-lookup.nvim.lua.example) in this
directory. Copy it into the LoanConnect repo and adjust the `pass`
invocation, DSN host/port, and DBs to match your setup:

```bash
cp ~/.config/nvim-kickstart/docs/lc-lookup.nvim.lua.example /path/to/loanconnect/.nvim.lua
```

Then add `.nvim.lua` and `.nvim/` to the LoanConnect repo's
`.gitignore` so credentials and cached snapshots never get committed.

What the file does, in brief:

```lua
-- Pull the password from your secret store at startup.
vim.env.LC_DB_PASS = vim.trim(vim.fn.system 'pass loanconnect/db')

-- vim.env.X mutates nvim's process env → child processes inherit it.
-- That's how `vim.system { ..., 'lc-lookup.php', ... }` sees these.
vim.env.LC_DB_DSN  = 'mysql:host=127.0.0.1;port=3306;dbname=loanconnect;...'
vim.env.LC_DB_USER = 'readonly'

-- Project-scoped manifest + cache.
local here = vim.fn.fnamemodify(vim.fn.expand '<sfile>', ':p:h')
vim.env.LC_LOOKUP_MANIFEST = here .. '/.nvim/lookup-manifest.json'
vim.env.LC_LOOKUP_CACHE    = here .. '/.nvim/lookup-cache'

-- Same credentials wire up vim-dadbod-ui.
vim.g.dbs = { loanconnect_prod_ro = '...' }
```

### 2. Write the manifest

Create `<loanconnect>/.nvim/lookup-manifest.json` declaring which tables
to dump and the SQL for each. Adjust SQL to match the actual schema:

```json
{
  "tables": {
    "lenders": {
      "sql": "SELECT id, name FROM lenders WHERE active = 1 ORDER BY name"
    },
    "partners": {
      "sql": "SELECT id, name FROM partners ORDER BY name"
    },
    "products": {
      "sql": "SELECT id, name, lender_id FROM products ORDER BY name"
    }
  }
}
```

The picker autodetects id/label columns from the first row's keys
(`id`/`ID`/`uuid` for ID; `name`/`label`/`title`/`display_name`/`company_name` for
label), so as long as your `SELECT` aliases columns into those names, you
don't need to change Lua code to add a new lookup type.

### 3. First refresh

From inside the LoanConnect project, in nvim:

```vim
:LcLookupCheck            " smoke-test the connection
:LcLookupRefresh          " populate the cache
```

…or from the shell at the project root:

```bash
~/.config/nvim-kickstart/bin/lc-lookup.php check
~/.config/nvim-kickstart/bin/lc-lookup.php dump-all
```

(The shell variant only sees the project-scoped manifest if you `cd`
into the project so direnv-style env loading kicks in, OR if you set
`LC_LOOKUP_MANIFEST` explicitly in your shell.)

## Daily use

| Keymap | Command | What it does |
|---|---|---|
| `<leader>xL` | `:LcLookup` | category picker → row picker |
| `<leader>xll` | `:LcLookup lenders` | lenders directly |
| `<leader>xlp` | `:LcLookup partners` | partners directly |
| `<leader>xlr` | `:LcLookup products` | products directly |
| `<leader>xlR` | `:LcLookupRefresh` | async refresh of all cached tables |
| — | `:LcLookupRefresh lenders` | async refresh of one table |
| — | `:LcLookupCheck` | print server version / db / time |

On row select, the ID is yanked to register `c` AND the system clipboard
(`+`), and a notification confirms the choice. Same convention as
`lc-cyber`.

## Dadbod-UI companion setup

`vim-dadbod-ui` is enabled in `lua/custom/plugins/dadbod.lua` and
toggled with `<leader>td`. It does *not* know about LoanConnect
connections — `vim.g.dbs` from your `.nvim.lua` is what populates the
drawer. Keeping the connections in `.nvim.lua` rather than the kickstart
plugin file means no credentials in dotfiles git history.

The example template wires `vim.g.dbs` from the same `LC_DB_USER` /
`LC_DB_PASS` that `lc-lookup` reads, so rotating the password is a
one-line change.

## Refreshing on a schedule (optional)

If you want the cache to stay fresh without thinking about it, add a
cron entry. Cron doesn't see your interactive shell env, so spell out
the manifest path and pull the password inline:

```cron
0 */2 * * * \
  LC_DB_PASS="$(pass loanconnect/db)" \
  LC_LOOKUP_MANIFEST=$HOME/projects/loanconnect/.nvim/lookup-manifest.json \
  LC_LOOKUP_CACHE=$HOME/projects/loanconnect/.nvim/lookup-cache \
  $HOME/.config/nvim-kickstart/bin/lc-lookup.php dump-all >>/tmp/lc-lookup.log 2>&1
```

…or a systemd timer if you prefer. The DSN/user can come from a global
`~/.config/lc-lookup/connection.json` to avoid duplicating them in the
crontab — see [Alternative setups](#alternative-setups) below.

## Alternative setups

Use these only if the project-local `.nvim.lua` flow doesn't fit.

### Global env vars

Set `LC_DB_DSN` / `LC_DB_USER` / `LC_DB_PASS` in your shell profile or
`direnv` `.envrc`. Works fine for one-machine, one-project setups.
Watch out: `vim.system` inherits env *at nvim launch time*, so changes
in your shell after nvim is already running won't propagate without
restarting nvim.

### Global `~/.config/lc-lookup/connection.json`

```json
{ "dsn": "mysql:host=127.0.0.1;port=3306;dbname=loanconnect;charset=utf8mb4",
  "user": "readonly",
  "pass": "..." }
```

`chmod 600` it — the script refuses to read world-readable connection
files. Useful when many tools (cron, ad-hoc scripts, CI) need the same
DSN. Project-local `.nvim.lua` env vars take precedence over this file
when both are present.

## Why both lc-lookup and dadbod-ui

|  | lc-lookup | dadbod-ui |
|---|---|---|
| **Use case** | "what's the ID of X?" | "give me the last 50 applications by lender Y" |
| **Latency** | ms (local JSON) | DB round-trip per query |
| **Network needed** | only on refresh | every query |
| **Where SQL lives** | manifest, never typed | scratchpad, typed each time |
| **Result UX** | snacks.picker fuzzy | tabbed text buffer |

They compose: lc-lookup tells you `lender_id = 42`, then `<leader>td`
opens dadbod and you run `SELECT * FROM applications WHERE lender_id =
42 LIMIT 100`.

## Files

| Path | Role | Per-machine? |
|---|---|---|
| `bin/lc-lookup.php` | standalone PDO dumper (no Laravel) | no — committed |
| `lua/lc-lookup.lua` | picker module (snacks.picker, vim.ui.select fallback) | no — committed |
| `after/plugin/lc-lookup-keymaps.lua` | keymaps + `:LcLookup*` commands | no — committed |
| `docs/lc-lookup.nvim.lua.example` | drop-in template for project `.nvim.lua` | no — committed |
| `<project>/.nvim.lua` | project-local credentials + paths | **yes — gitignored** |
| `<project>/.nvim/lookup-manifest.json` | which tables, what SQL | **yes — gitignored** |
| `<project>/.nvim/lookup-cache/*.json` | dumped table snapshots | **yes — gitignored** |

Optional global fallbacks (only if you skip `.nvim.lua`):

| Path | Role |
|---|---|
| `~/.config/lc-lookup/manifest.json` | shared manifest for cron / multi-tool use |
| `~/.config/lc-lookup/connection.json` | shared DSN (chmod 600) |
| `~/.cache/lc-lookup/*.json` | shared cache |
