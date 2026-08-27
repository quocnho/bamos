---
name: php-codeigniter
description: >-
  Use this skill when working on PHP projects built with CodeIgniter 4 (or 3).
  Covers the CodeIgniter workflow: spark CLI, app structure (Controllers,
  Models, Views, Database/Migrations/Seeds), routes, validation, services,
  helpers, and environment configuration. Activate when the project contains
  app/Config/Routes.php, spark, or system/ directories, or when the user says
  "CodeIgniter".
---

# CodeIgniter Development

CodeIgniter 4 project workflows for this machine (PHP 8.3+).

## Project structure (CI4)

- `app/Controllers/` — controllers; `app/Models/` — models; `app/Views/` — views.
- `app/Database/Migrations/` — migrations; `app/Database/Seeds/` — seeders.
- `app/Config/` — config files: `Routes.php`, `Database.php`, `Services.php`, `Validation.php`.
- `writable/` — logs, cache, session, uploads (must be writable).
- `public/` — document root; entry `public/index.php`.

## Standard workflow

### 1. Understand the app
- Routes: read `app/Config/Routes.php` (CI4 auto-routing is off by default; routes are explicit).
- List routes: `php spark routes`.
- Check environment: `app/Config/Boot/` or `.env`; `ENVIRONMENT` is set from `.env` (`CI_ENVIRONMENT`).

### 2. spark CLI (equivalent of artisan)
```
php spark serve --port=8080        # dev server
php spark make:controller Products --restful
php spark make:model Product
php spark make:migration CreateProducts
php spark make:seeder ProductSeeder
php spark migrate                  # chạy migration
php spark migrate:rollback
php spark db:seed ProductSeeder
php spark routes
php spark cache:clear
```

### 3. Controllers & routing
- Extend `BaseController`; return views via `return view('products/index', $data)`.
- Route example: `$routes->resource('products')` for RESTful CRUD, or
  `$routes->get('products', 'Products::index')` for explicit routes.
- For API controllers use `CodeIgniter\RESTful\ResourceController`.

### 4. Models & queries
- Extend `Model`; set `$table`, `$primaryKey`, `$allowedFields` (whitelist — required for insert/update).
- Use the Query Builder: `$this->where('status', 1)->orderBy('id','DESC')->findAll(20)`.
- Pagination: `$model->paginate(10)` + `$pager->links()` in the view.
- Use `$model->escape()` / prepared binds for user input: `$db->query('SELECT * FROM products WHERE id = ?', [$id])`.
- `withDeleted()` to include soft-deleted rows; `onlyDeleted()` for deleted only.

### 5. Validation
- Define rules in `app/Config/Validation.php` or inline:
  `$this->validate(['email' => 'required|valid_email|is_unique[users.email]'])`.
- In controller: `if (!$this->validate($rules)) { return redirect()->back()->withInput()->with('errors', $this->validator->getErrors()); }`
- Display errors in view with `validation_list_errors()` or `session()->getFlashdata('errors')`.

### 6. Migrations & seeds
- Migration files extend `CodeIgniter\Database\Migration`; use `$this->forge->addField(...)`, `$this->forge->addKey('id', true)`, `$this->forge->createTable('products')`.
- Seeds extend `CodeIgniter\Database\Seeder`; call `$this->db->table('products')->insert($rows)` or the model.

### 7. Services, helpers & libraries
- Register shared services in `app/Config/Services.php`; access via `service('name')`.
- Helpers: `helper('url')`, `helper('form')` in controller or `app/Config/autoload.php` `$helpers`.
- Email: `$email = \Config\Services::email();` — configure SMTP in `app/Config/Email.php`.

## Debugging

- Logs: `writable/logs/` (`log_message('error', '...')` in code).
- Enable debug toolbar in dev: `app/Config/Toolbar.php` (default on in development) — shows queries, timing, memory.
- Check `.env` settings: `database.default.*` for DB connection; `app.baseURL` must match the served URL.
- 404 on valid route → check `app.baseURL`, route case-sensitivity, and `public/.htaccess` (Apache) or `public/index.php` rewrite (Nginx).
- Stale cache after config changes → `php spark cache:clear`.

## References

- [ci4-cheatsheet.md](./references/ci4-cheatsheet.md) — lệnh spark & cấu hình quan trọng.
