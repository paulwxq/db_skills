-- ============================================
-- 连接校验 SQL 模板
-- ============================================

-- 最小连接测试
SELECT current_database(), current_user;

-- 查看 PostgreSQL 版本
SELECT version();

-- 查看服务器编码
SHOW server_encoding;

-- 查看时区
SHOW timezone;

-- 查看最大连接数
SHOW max_connections;

-- 查看当前连接数
SELECT count(*) AS current_connections FROM pg_stat_activity;

-- 查看当前用户权限属性
SELECT
    rolname,
    rolsuper,
    rolcreaterole,
    rolcreatedb,
    rolcanlogin,
    rolreplication
FROM pg_roles
WHERE rolname = current_user;
