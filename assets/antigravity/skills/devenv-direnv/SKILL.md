---
name: devenv-direnv
description: >-
  Use this skill when working with Nix-based development environments powered
  by devenv and direnv: creating or editing devenv.nix, adding languages,
  packages, env vars, scripts, processes, and services (mysql, postgres, redis),
  and managing direnv allow/reload. Activate when the user asks about devenv,
  direnv, .envrc, entering a dev shell, or when devenv.nix/.envrc are present.
---

# devenv + direnv Workflows

Reproducible dev environments. `devenv` and `direnv` are installed system-wide (modules/packages.nix, modules/shell.nix). This machine's dev stacks: PHP (Laravel/CodeIgniter), MySQL, TypeScript/Node, PWA, Flutter, Python.

## How it fits together

- `direnv` loads `.envrc` when you `cd` into a project → typically runs `devenv shell` (or `nix-direnv`).
- `devenv` reads `devenv.nix` (+ `devenv.lock` + `devenv.yaml`) and builds an isolated shell: tools, env vars, services, scripts.
- The IDE's direnv extension (mkhl.direnv) restarts language servers automatically when the environment changes.

## First-time project setup

```bash
# 1. Khởi tạo (chạy một lần):
devenv init            # tạo devenv.nix, devenv.yaml, devenv.lock
# hoặc tự viết devenv.nix + echo "use devenv" > .envrc

# 2. Kích hoạt:
direnv allow           # chấp nhận .envrc (sau khi sửa .envrc cần allow lại)
```

## devenv.nix — cấu hình theo stack

### PHP + Laravel / CodeIgniter
```nix
{ pkgs, ... }:
{
  languages.php = {
    enable = true;
    version = "8.3";                       # hoặc "8.4"
    extensions = [ "pdo" "pdo_mysql" "gd" "intl" "zip" "opcache" "xdebug" ];
    ini = ''
      memory_limit = 1G
      xdebug.mode = debug
      xdebug.client_port = 9003
      xdebug.start_with_request = yes
    '';
  };
  languages.mysql.enable = true;           # chạy MySQL local
  packages = [ pkgs.composer ];
  scripts.artisan.exec = "php artisan $@"; # devenv run artisan migrate
}
```
Notes: after enabling `languages.mysql`, the DB starts with `devenv up` (or `devenv services up`); connection defaults are in `.devenv/` env (see `devenv info`). For CodeIgniter, `php spark` works the same way via scripts or direct call.

### Node / TypeScript / PWA
```nix
{
  languages.javascript = {
    enable = true;
    pnpm.enable = true;   # hoặc npm.enable / yarn.enable / bun.enable
    corepack.enable = true;
  };
  languages.typescript.enable = true;
}
```
PWA/static sites: run `pnpm dev` from `devenv shell`; ports are project-local.

### Flutter
```nix
{
  languages.dart.enable = true;            # cài Flutter SDK qua devenv
  # Nếu cần build Linux: thêm toolchain
  packages = [ pkgs.gcc pkgs.cmake pkgs.ninja pkgs.gtk3 pkgs.pkg-config ];
}
```
Android SDK: `languages.android.enable = true` (heavy — only when needed; `flutter doctor` will tell you).

### Python
```nix
{
  languages.python = {
    enable = true;
    version = "3.12";
    uv.enable = true;                      # hoặc venv.enable = true
  };
}
```

### Services (MySQL, Postgres, Redis...)
```nix
{
  services.mysql.enable = true;
  # services.postgres.enable = true;
  # services.redis.enable = true;
  # services.php-fpm = { ... }  (khi cần)
}
```
Start: `devenv up` (all processes + services) or `devenv services up`. Check status: `devenv services status`. Database credentials are printed by `devenv info` / in `.devenv/state/`.

## Daily commands

- `devenv shell` — enter the shell manually (direnv already does this).
- `devenv up` — run processes & services in foreground.
- `devenv run <script>` — run a script defined in `devenv.nix` (`scripts.*`) without entering the shell.
- `devenv test` — run `enterTest` if defined.
- `devenv gc` / `devenv gc --all` — garbage-collect old devenv generations.
- `devenv info` — show resolved environment info (versions, env vars, services).

## direnv tips

- `.envrc` content is normally just: `use devenv`.
- After editing `.envrc` or `devenv.nix`: `direnv reload` (or `direnv allow` if the file changed checksum).
- The IDE direnv extension shows the environment status in the status bar; if language servers act stale, run `direnv reload`.
- `direnv status` to debug why a directory isn't loading.

## Common gotchas

- **Slow first load** — devenv builds in the nix store; subsequent loads are fast. Use `nix-direnv` (already enabled) for cached rebuilds.
- **devenv.lock out of date** — after editing devenv.nix, allow devenv to update the lock (it prompts) or run `devenv update`.
- **Missing extension in PHP** — add to `languages.php.extensions` and `direnv reload`; never `apt`-install inside the shell.
- **Port conflicts** — two devenv projects both wanting MySQL: change port via `services.mysql.settings` / `languages.mysql.initialDatabases` config or use different services.
- **Flutter/Android heavy builds** — prefer `languages.dart.enable` only; enable Android SDK per-project when strictly needed.
- Never run `nix-collect-garbage` while a devenv shell is active if you rely on old generations — run `devenv gc` instead.
