-- ============================================
-- 元数据查询模板（psql -v 可执行）
-- ============================================
--
-- 本模板使用 psql -v 变量，用于批量执行或脚本化场景。
-- 如果只需单次查询，建议直接在 SQL 中写入具体值（更简单、不易出错）。
-- 详见 rules/execution-conventions.md § 2.1
--
-- ┌─────────────────────────────────────────────────────────┐
-- │ 必填变量                                                │
-- │   schema_name  — 目标 schema（字符串，传入时需自带引号）  │
-- │   table_name   — 目标表（字符串，传入时需自带引号）       │
-- └─────────────────────────────────────────────────────────┘
--
-- 标识符限制：
--   本模板适用于未加引号的简单小写标识符（如 public、users）。
--   对于大小写敏感或含特殊字符的标识符（如 "MyTable"、"user-data"），
--   请改用 psql 元命令（\d+ "MyTable"）或在 SQL 中手动加双引号引用。
--
-- 文件执行：
--   psql -X -v schema_name="'public'" -v table_name="'mytable'" -f metadata.sql
--
-- 单条直接执行（不需要 -v，更推荐）：
--   psql -X -Atqc "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';"

-- 列出非系统 schema
SELECT schema_name
FROM information_schema.schemata
WHERE schema_name NOT IN ('pg_catalog', 'information_schema', 'pg_toast')
ORDER BY schema_name;

-- 列出指定 schema 下的表
SELECT table_name, table_type
FROM information_schema.tables
WHERE table_schema = :'schema_name'
ORDER BY table_name;

-- 查看表的列定义
SELECT
    column_name,
    data_type,
    character_maximum_length,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = :'schema_name' AND table_name = :'table_name'
ORDER BY ordinal_position;

-- 查看主键列
SELECT kcu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
WHERE tc.table_schema = :'schema_name'
    AND tc.table_name = :'table_name'
    AND tc.constraint_type = 'PRIMARY KEY'
ORDER BY kcu.ordinal_position;

-- 查看外键关系
SELECT
    tc.constraint_name,
    kcu.column_name,
    ccu.table_schema AS foreign_schema,
    ccu.table_name AS foreign_table,
    ccu.column_name AS foreign_column
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage ccu
    ON tc.constraint_name = ccu.constraint_name
WHERE tc.table_schema = :'schema_name'
    AND tc.table_name = :'table_name'
    AND tc.constraint_type = 'FOREIGN KEY';

-- 查看所有约束
SELECT
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
WHERE tc.table_schema = :'schema_name'
    AND tc.table_name = :'table_name'
ORDER BY tc.constraint_type, tc.constraint_name;

-- 查看索引
SELECT indexname, indexdef
FROM pg_indexes
WHERE schemaname = :'schema_name' AND tablename = :'table_name'
ORDER BY indexname;

-- 查看表注释
SELECT obj_description(c.oid) AS table_comment
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = :'schema_name' AND c.relname = :'table_name';

-- 查看列注释
SELECT
    a.attname AS column_name,
    col_description(a.attrelid, a.attnum) AS column_comment
FROM pg_attribute a
JOIN pg_class c ON c.oid = a.attrelid
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = :'schema_name' AND c.relname = :'table_name'
    AND a.attnum > 0 AND NOT a.attisdropped
ORDER BY a.attnum;

-- 查看表大小
-- 使用 format() + %I 安全引用标识符，可处理大小写敏感的对象名
SELECT
    pg_size_pretty(pg_total_relation_size(format('%I.%I', :'schema_name', :'table_name')::regclass)) AS total_size,
    pg_size_pretty(pg_relation_size(format('%I.%I', :'schema_name', :'table_name')::regclass)) AS table_size,
    pg_size_pretty(pg_indexes_size(format('%I.%I', :'schema_name', :'table_name')::regclass)) AS index_size;

-- 查看 schema 下所有表的大小
SELECT
    tablename,
    pg_size_pretty(pg_total_relation_size(format('%I.%I', schemaname, tablename)::regclass)) AS total_size
FROM pg_tables
WHERE schemaname = :'schema_name'
ORDER BY pg_total_relation_size(format('%I.%I', schemaname, tablename)::regclass) DESC;
