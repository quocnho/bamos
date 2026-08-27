# Laravel Artisan — tham chiếu nhanh

Chỉ dùng khi cần danh sách lệnh đầy đủ; các lệnh chính đã nằm trong SKILL.md.

## Routing
- `php artisan route:list` — liệt kê route
- `php artisan route:list --path=api --except-vendor`
- `php artisan route:cache` / `route:clear`

## Config & cache
- `php artisan config:cache` / `config:clear`
- `php artisan cache:clear`
- `php artisan view:clear`
- `php artisan optimize:clear` — xoá toàn bộ cache (config, route, view, event, compiled)

## Database
- `php artisan migrate` / `migrate:fresh` / `migrate:rollback --step=1`
- `php artisan migrate:status`
- `php artisan db:seed` / `db:seed --class=UserSeeder`
- `php artisan db:show` / `db:table` (Laravel 11+)

## Tinker (REPL)
- `php artisan tinker` — thử nghiệm nhanh model/query:
  - `App\Models\User::first()`
  - `DB::table('orders')->where('status','pending')->count()`
  - `Cache::put('k', 1, now()->addHour())`

## Queues
- `php artisan queue:work` / `queue:listen` / `queue:restart`
- `php artisan queue:failed` / `queue:retry all` / `queue:flush`
- `php artisan schedule:list` / `schedule:run` / `schedule:work`

## Auth / Sanctum / Filament
- `php artisan make:filament-user` (nếu dùng Filament)
- `php artisan vendor:publish --tag=...` — publish vendor assets

## Env
- Xem `.env.example` trước khi tạo `.env`
- `php artisan key:generate` — sau khi tạo `.env`
