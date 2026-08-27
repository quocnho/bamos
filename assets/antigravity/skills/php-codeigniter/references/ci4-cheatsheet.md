# CodeIgniter 4 — tham chiếu nhanh

## spark CLI
- `php spark serve` — dev server (mặc định port 8080)
- `php spark routes` — liệt kê routes
- `php spark make:controller Name --restful` — controller RESTful
- `php spark make:model Name`
- `php spark make:migration CreateXxx` / `php spark migrate` / `migrate:rollback` / `migrate:refresh`
- `php spark make:seeder XxxSeeder` / `php spark db:seed XxxSeeder`
- `php spark cache:clear` / `php spark env` / `php spark version`

## Cấu hình quan trọng (app/Config/)
- `Database.php` — kết nối DB (`default` group: hostname, database, username, password, DBDriver)
- `Routes.php` — định nghĩa route
- `App.php` — `baseURL` (bắt buộc đúng), `defaultLocale`, `timezone`
- `Filters.php` — middleware (auth, csrf, cors)
- `autoload.php` — `$helpers` (url, form, security), `$psr4` (namespace)

## Model
```php
<?php
namespace App\Models;
use CodeIgniter\Model;

class Product extends Model
{
    protected $table         = 'products';
    protected $primaryKey    = 'id';
    protected $allowedFields = ['name', 'price', 'stock', 'status'];
    protected $useTimestamps = true;
    protected $useSoftDeletes = true;
    protected $returnType    = 'array'; // hoặc 'object'
}
```

## Validation inline
```php
$rules = [
    'name'  => 'required|min_length[3]|max_length[100]',
    'email' => 'required|valid_email|is_unique[users.email,id,{id}]',
    'price' => 'required|numeric|greater_than[0]',
];
```

## Query Builder mẫu
```php
$db = \Config\Database::connect();
$rows = $db->table('products')
    ->where('status', 1)
    ->like('name', $keyword)
    ->orderBy('created_at', 'DESC')
    ->limit(20)
    ->get()
    ->getResult();
```

## Security lưu ý
- Luôn dùng Query Builder hoặc prepared statement (không nối chuỗi SQL).
- Bật CSRF filter cho POST route trong `app/Config/Filters.php`.
- `esc($var)` trong view để chống XSS.
