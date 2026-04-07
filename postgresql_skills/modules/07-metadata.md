# 07 - 元数据探查

## 模块目标

处理数据库对象结构的查询和探查：schema、表、列、约束、索引、注释、大小。

---

## 典型任务

- 列出 schema
- 列出表
- 查看列定义
- 查看主键
- 查看外键
- 查看索引
- 查看注释
- 查看表 / 索引大小
- 查看对象依赖

---

## 标准流程

1. **如果用户未指定 schema**，先确认 search_path 和对象位置：
   ```bash
   # 查看当前 search_path
   psql -X -Atqc "SHOW search_path;"
   # 在所有 schema 中搜索该对象（覆盖表、视图、物化视图、外部表）
   psql -X -Atqc "
     SELECT n.nspname AS schema, c.relname AS name,
            CASE c.relkind
              WHEN 'r' THEN 'table'
              WHEN 'v' THEN 'view'
              WHEN 'm' THEN 'materialized view'
              WHEN 'f' THEN 'foreign table'
              WHEN 'p' THEN 'partitioned table'
            END AS type
     FROM pg_class c
     JOIN pg_namespace n ON n.oid = c.relnamespace
     WHERE c.relname = 'target_name'
       AND c.relkind IN ('r','v','m','f','p')
       AND n.nspname NOT IN ('pg_catalog','information_schema','pg_toast');
   "
   ```
   如果只存在于一个 schema，使用该 schema；如果存在于多个 schema，向用户确认
2. 列出 schema（定位范围）
3. 列出目标 schema 下的对象
4. 查看字段与约束
5. 查看索引与大小
6. 如用户需要数据样本，转 `08-sample-data.md`

---

## 方式选择：psql 元命令 vs SQL 查询

元数据探查有两种方式，**默认优先使用 psql 元命令**。

### psql 元命令（首选）

优势：
- 短命令，不易拼错
- 直接查 `pg_catalog`，在大型数据库上远快于 `information_schema`
- 输出自适应 PostgreSQL 版本，无需关心版本差异
- 一条命令包含列、类型、约束、索引、注释、大小等综合信息

```bash
# 列出 schema
psql -X -c "\dn+"

# 列出表
psql -X -c "\dt+ public.*"

# 查看表的完整结构（列、类型、约束、索引、注释、大小）
psql -X -c "\d+ public.mytable"

# 列出索引
psql -X -c "\di+ public.*"

# 列出角色
psql -X -c "\du+"

# 列出数据库
psql -X -c "\l+"

# 列出外键
psql -X -c "\d+ public.mytable"
# 外键信息包含在 \d+ 的输出中

# 查看函数
psql -X -c "\df+ public.*"

# 查看视图
psql -X -c "\dv+ public.*"

# 查看序列
psql -X -c "\ds+ public.*"
```

### SQL 查询（备选：需要结构化输出或精确字段控制时使用）

当以下情况时，改用 SQL 查询：
- 需要 Agent 程序化解析输出（元命令输出是人类可读格式，不适合机器解析）
- 需要精确控制返回字段（如只要列名和类型，不要其他信息）
- 需要跨表 join 或聚合（如一次查出所有表的大小排序）
- 需要查询元命令不直接覆盖的信息（如对象依赖关系）

---

## 最小模板（psql 元命令版）

```bash
# 快速探查一张表的全部结构信息（列、类型、默认值、约束、索引、注释、大小）
psql -X -c "\d+ public.mytable"

# 列出 schema 下所有表及大小
psql -X -c "\dt+ public.*"

# 列出所有非系统 schema
psql -X -c "\dn"
```

## 最小模板（SQL 版 — 结构化输出场景）

```sql
-- 列出非系统 schema
SELECT schema_name
FROM information_schema.schemata
WHERE schema_name NOT IN ('pg_catalog', 'information_schema', 'pg_toast')
ORDER BY schema_name;

-- 列出 schema 下的表（用 pg_tables 替代 information_schema.tables，更快）
SELECT tablename, tableowner
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;

-- 查看表的列定义
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'mytable'
ORDER BY ordinal_position;

-- 查看主键
SELECT kcu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
WHERE tc.table_schema = 'public'
  AND tc.table_name = 'mytable'
  AND tc.constraint_type = 'PRIMARY KEY'
ORDER BY kcu.ordinal_position;

-- 查看外键
SELECT
    tc.constraint_name,
    kcu.column_name,
    ccu.table_name AS foreign_table,
    ccu.column_name AS foreign_column
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
  ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage ccu
  ON tc.constraint_name = ccu.constraint_name
WHERE tc.table_schema = 'public'
  AND tc.table_name = 'mytable'
  AND tc.constraint_type = 'FOREIGN KEY';

-- 查看索引
SELECT indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'public' AND tablename = 'mytable';

-- 查看表注释
SELECT obj_description(c.oid) AS table_comment
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public' AND c.relname = 'mytable';

-- 查看列注释
SELECT a.attname AS column_name,
       col_description(a.attrelid, a.attnum) AS column_comment
FROM pg_attribute a
JOIN pg_class c ON c.oid = a.attrelid
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public' AND c.relname = 'mytable'
  AND a.attnum > 0 AND NOT a.attisdropped
ORDER BY a.attnum;

-- 查看表大小（含索引）
-- 使用 format('%I.%I', ...) 安全引用标识符
SELECT
    pg_size_pretty(pg_total_relation_size(format('%I.%I', 'public', 'mytable')::regclass)) AS total_size,
    pg_size_pretty(pg_relation_size(format('%I.%I', 'public', 'mytable')::regclass)) AS table_size,
    pg_size_pretty(pg_indexes_size(format('%I.%I', 'public', 'mytable')::regclass)) AS index_size;

-- 查看 schema 下所有表的大小排序
SELECT
    tablename,
    pg_size_pretty(pg_total_relation_size(format('%I.%I', schemaname, tablename)::regclass)) AS total_size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(format('%I.%I', schemaname, tablename)::regclass) DESC;
```

---

## Context7 调用指引

当以下情况发生时调用 Context7：

- psql 元命令的具体行为不确定（如 `\d+` 在不同版本间的输出差异）
- information_schema 与 pg_catalog 的选择不确定
- 系统 catalog 字段含义不确定
- 对象依赖查询方式不确定
- 高级元数据查询（如分区信息、继承信息）

### 推荐查询

- `PostgreSQL psql meta-commands`
- `PostgreSQL information_schema`
- `PostgreSQL pg_catalog`
- `PostgreSQL pg_class`
- `PostgreSQL pg_constraint`
- `PostgreSQL pg_depend`
- `PostgreSQL pg_total_relation_size`

---

## 风险规则

- 元数据探查为只读操作，可直接执行
- 如需查看样本数据，限制行数（如 LIMIT 10）
- 注意区分"结构信息"和"实际数据"
