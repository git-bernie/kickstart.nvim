# laravel.nvim with Docker Compose

## What it does

`adalessa/laravel.nvim` adds Laravel-aware pickers and navigation to Neovim:

| Keymap | Action |
|--------|--------|
| `<leader>ll` | Main Laravel picker |
| `<leader>la` | Artisan command picker |
| `<leader>lr` | Routes picker (jump to controller) |
| `<leader>lm` | Make generators picker |
| `<leader>lc` | All commands picker |
| `gf` | Laravel-aware go-to-file (resolves view names, etc.) |

## Environment Configuration (per project)

The plugin stores environment config at:
```
~/.local/share/nvim/laravel/config.json
```

### First-time setup

Run inside Neovim with a PHP file open:
```
:lua Laravel.commands.run("env:configure")
```
Pick **docker-compose**. The config window closes automatically on save.

### Fix the container/service name

The default service name is `app` (Laravel Sail convention). For projects
that use a different service name, edit the config directly:
```
:lua Laravel.commands.run("env:configure:open")
```

Change every `"app"` in the `map` arrays to your actual Docker Compose
**service name** (not the container name). Example for the `services` project:

```json
{
  "/home/bernie/code/projects/services": {
    "map": {
      "php": ["docker", "compose", "exec", "-it", "php", "php"],
      "composer": ["docker", "compose", "exec", "-it", "php", "composer"],
      "npm": ["docker", "compose", "exec", "-it", "php", "npm"],
      "yarn": ["docker", "compose", "exec", "-it", "php", "yarn"]
    },
    "path": "/home/bernie/code/projects/services",
    "name": "services-php"
  }
}
```

> **Service name vs container name:** `docker compose exec` uses the service
> name from `docker-compose.yml` (e.g. `php`), not the `container_name`
> value (e.g. `services-php`).

## Picker behaviour

Commands that require arguments (e.g. `config:show {key}`, `route:show {route}`)
will fail with "Not enough arguments" when run from the picker — this is expected.
Use the picker for zero-argument commands (`route:list`, `migrate:status`, etc.)
and run argument-requiring commands manually.

## Project support

| Project | Environment | Service name |
|---------|-------------|--------------|
| `services` | docker-compose | `php` |
| `loanconnect-laravel` | Homestead (Vagrant) | ❌ not supported |

## Plugin file

`lua/custom/plugins/laravel.lua` — lazy-loads on `ft=php`, `ft=blade`,
`BufEnter composer.json`, and the `:Laravel` command.
Picker provider set to `snacks`.
