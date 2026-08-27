---
name: mysql-database
description: >-
  Use this skill when working with MySQL/MariaDB databases: schema design,
  migrations, queries, performance tuning (indexes, EXPLAIN), transactions,
  backups/restores, and when using the mysql MCP server or the SQLTools
  extension. Activate when the user asks to write SQL, fix slow queries,
  design tables, or debug database issues in PHP/Laravel/CodeIgniter projects.
---

# MySQL / MariaDB Workflows

Practical MySQL for this machine (devenv services or system DB, usually MySQL 8 / MariaDB 10.11+).

## Connecting

- Via CLI: `mysql -u root -p` (or the project's `.env` credentials).
- Via MCP: the `mysql` MCP server (see `agy mcp list`; enable with `agy mcp enable mysql` after setting credentials in `~/.gemini/config/mcp_config.json`). Prefer MCP for read-only inspections during AI-assisted work; never run destructive statements without explicit user approval.
- In the IDE: SQLTools / Database Client extensions connect via the project's `.env` when configured.

## Schema design rules of thumb

- Every table needs an integer/bigint primary key; use `UNSIGNED BIGINT` for large tables.
- Foreign keys: define with `ON DELETE CASCADE` only where appropriate; keep referential integrity explicit.
- Use `DATETIME`/`TIMESTAMP` consistently; prefer `TIMESTAMP` + `ON UPDATE CURRENT_TIMESTAMP` for `updated_at`.
- Avoid `ENUM` when the value set changes often; use lookup tables or `VARCHAR` + `CHECK` (MySQL 8.0.16+).
- Store money as `DECIMAL(19,4)` — never `FLOAT`/`DOUBLE`.
- Use `utf8mb4` + `utf8mb4_unicode_ci` (or `utf8mb4_0900_ai_ci` on MySQL 8) for full Unicode including Vietnamese.

## Writing queries

- Always bind parameters; never interpolate user input into SQL.
- Prefer explicit columns over `SELECT *` (except quick inspections).
- For paging large datasets prefer keyset pagination:
  `WHERE id > ? ORDER BY id ASC LIMIT 20` instead of `LIMIT 20 OFFSET 10000`.
- Use `INSERT ... ON DUPLICATE KEY UPDATE` or `INSERT IGNORE` for idempotent writes.

## Performance

1. **Find slow queries**: `SHOW FULL PROCESSLIST;` or enable the slow query log:
   `SET GLOBAL slow_query_log = ON; SET GLOBAL long_query_time = 0.2;`
2. **Explain a query**:
   `EXPLAIN ANALYZE SELECT ...;` (MySQL 8.0.18+) — shows actual execution time per step.
   Look for: `type` = ALL (full scan), missing `key` (index), `rows` much larger than result.
3. **Indexing basics**:
   - Index columns used in `WHERE`, `JOIN ... ON`, `ORDER BY`, and `GROUP BY`.
   - Composite index order matters: leftmost prefix rule (e.g. `(status, created_at)` helps `WHERE status=? ORDER BY created_at`).
   - Avoid indexing low-cardinality columns alone (e.g. boolean flags).
   - `SHOW INDEX FROM table;` to inspect; `DROP INDEX`/`ADD INDEX` to adjust.
4. **Common fixes**:
   - Full scan → add index; still slow → check `EXPLAIN` for wrong index choice (`FORCE INDEX` only as last resort).
   - `filesort`/`temporary` → align `ORDER BY` with the index.
   - Sargable conditions: avoid `WHERE YEAR(created_at) = 2026` — use range `created_at >= '2026-01-01' AND created_at < '2027-01-01'`.

## Transactions & locking

- `START TRANSACTION; ... COMMIT;` / `ROLLBACK;` — keep transactions short.
- Read committed is the default on MySQL 8/InnoDB — good balance for web apps.
- For batch updates in Laravel jobs, chunk results: `Model::where(...)->chunkById(500, fn($rows) => ...)` to avoid long locks.

## Backups & restores

- Logical backup: `mysqldump -u root -p --single-transaction --routines --triggers dbname > backup.sql`
- Restore: `mysql -u root -p dbname < backup.sql`
- Check storage: `SELECT table_schema, ROUND(SUM(data_length+index_length)/1024/1024,1) AS mb FROM information_schema.tables GROUP BY table_schema;`

## Common gotchas

- **"Too many connections"** → check `SHOW VARIABLES LIKE 'max_connections';` and app connection pool settings.
- **"Lock wait timeout exceeded"** → long transaction elsewhere; inspect `SELECT * FROM information_schema.innodb_trx;`.
- **Incorrect string value (utf8mb4)** → table/column charset not utf8mb4; alter column charset.
- **Slow in dev, fast in prod (or vice versa)** → missing index vs cache warm; run `EXPLAIN ANALYZE` on the exact query.
- Never run `DROP DATABASE`, `TRUNCATE`, or `UPDATE ... WHERE` without `LIMIT`/backup during AI-assisted sessions without explicit user confirmation.
