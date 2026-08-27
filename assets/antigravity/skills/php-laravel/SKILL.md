---
name: php-laravel
description: >-
  Use this skill when working on PHP projects built with Laravel (11/12+).
  Covers the standard Laravel workflow: artisan commands, migrations, Eloquent,
  factories and seeders, queues, events, caching, testing (Pest/phpunit),
  formatting (Pint), debugging with xdebug, and common pitfalls.
  Activate when the user asks to build, debug, refactor, test, or extend a
  Laravel application, or when the project contains artisan, composer.json,
  or app/Http/Controllers.
---

# Laravel Development

Laravel project workflows for this machine (PHP 8.3+, Composer via devenv or system php).

## Project conventions

- Run every PHP command through the project environment: `devenv shell` is already active when the terminal is inside a direnv-allowed project (see the `devenv-direnv` skill). Prefer `php artisan` over raw `php` when inside a Laravel project.
- If `vendor/` is missing, run `composer install` first.
- The `.env` file holds secrets — never print its contents or commit it. Validate config with `php artisan config:cache` only when you know `.env` is complete.

## Standard workflow

### 1. Understand the app before editing
- Routes: `php artisan route:list --path=<prefix>` (add `-v` for middleware).
- Models/controllers: inspect `app/Models`, `app/Http/Controllers`.
- Run `php artisan about` for a project overview.
- Check `composer.json` for the Laravel version and packages before suggesting APIs.

### 2. Scaffolding (artisan make:*)
```
php artisan make:model Product -mfsc        # model + migration + factory + seeder + controller
php artisan make:controller Api/ProductController --api
php artisan make:migration create_orders_table --table=orders
php artisan make:request StoreProductRequest
php artisan make:observer ProductObserver
php artisan make:job ProcessPayment --sync
php artisan make:event OrderShipped
php artisan make:notification OrderShipped
```
Prefer `-mfs` flags instead of generating files one by one.

### 3. Migrations & schema
- Write migrations with `Schema::table`/`Schema::create` and always define `foreignId()->constrained()->cascadeOnDelete()` for FKs.
- Run: `php artisan migrate` (dev), `php artisan migrate:fresh --seed` only when data loss is acceptable.
- Never edit an already-migrated migration for changes that affect production; create a new one.

### 4. Eloquent best practices
- Use `Model::query()` and scopes (`scopeFilter`, `scopeSearch`) instead of conditional `where` chains in controllers.
- Eager-load relations: `with(['user', 'items.variant'])` to avoid N+1; confirm with `Model::with(...)->...->toSql()` or Laravel Debugbar if present.
- For heavy lists use `->paginate()` (or `->cursorPaginate()` for large datasets).
- Mass assignment: fill `$fillable`/`$guarded` properly; never disable `$guarded = []` without a reason.
- Use `firstOrCreate`/`updateOrCreate` for idempotent writes.

### 5. Factories & seeders
- `php artisan make:factory ProductFactory --model=Product`, then `php artisan db:seed` / `db:seed --class=ProductSeeder`.
- Use real faker locales when generating Vietnamese data: `fake()->locale('vi_VN')` where supported by faker.

### 6. Queues & jobs (when the app uses queues)
- Queue driver is usually `database` or `redis` — check `.env`. Start a worker with `php artisan queue:work` (or `queue:listen` in dev).
- Jobs: `handle()` only; keep them idempotent; `ShouldQueue` for long tasks; `->onQueue('high')` when needed.
- Failed jobs: `php artisan queue:failed` / `queue:retry all` / `queue:flush`.

### 7. Testing (Pest preferred, phpunit supported)
- Feature tests under `tests/Feature`, unit under `tests/Unit`.
- Typical flow: `RefreshDatabase` → arrange → act → assert.
- Run: `php artisan test` (or `./vendor/bin/pest`). For a single file: `php artisan test --filter=ProductTest`.

### 8. Formatting & static analysis
- Format changed files with Pint: `./vendor/bin/pint --dirty` (or `pint` on the file path).
- Run static analysis when present: `./vendor/bin/phpstan analyse` or `./vendor/bin/psalm`.

## Debugging

- Xdebug + the `xdebug.php-debug` extension are installed. Use the IDE's "Listen for Xdebug" launch config; the debugger connects on port 9003 by default.
- Check `storage/logs/laravel.log` for exceptions; tail with `tail -f storage/logs/laravel.log`.
- Common gotchas:
  - "Class not found" after adding a package → `composer dump-autoload`.
  - Config cache stale after editing `.env`/config → `php artisan config:clear` (dev) or `config:cache` (prod).
  - Views stale → `php artisan view:clear`.
  - 419 Page Expired → CSRF token missing; add `@csrf` or `csrf_token()`.

## References

- [artisan-cheatsheet.md](./references/artisan-cheatsheet.md) — full artisan command reference for common operations.
