-- ============================================
-- 监控查询模板
-- ============================================
--
-- 版本要求：本模板中的查询基于 PG 13+ 编写。
-- 在旧版本上执行前，请参考以下已知差异：
--   [PG 12] pg_stat_statements: total_time / mean_time（非 total_exec_time / mean_exec_time）
--   [PG 12] pg_stat_activity: 无 leader_pid
--   [PG 13-] pg_stat_activity: 无 query_id（PG 14+）
--   [PG 13-] pg_locks: 无 waitstart（PG 14+）
-- 如果不确定当前版本的字段可用性，先执行 SHOW server_version_num;

-- ----------------------------------------
-- 活动会话
-- ----------------------------------------

-- 查看非 idle 的活动会话
SELECT pid, usename, datname, state, query_start,
       now() - query_start AS duration,
       left(query, 100) AS query_preview
FROM pg_stat_activity
WHERE state != 'idle'
ORDER BY query_start;

-- 查看所有连接（含 idle）
SELECT state, count(*)
FROM pg_stat_activity
GROUP BY state
ORDER BY count DESC;

-- ----------------------------------------
-- 长事务
-- ----------------------------------------

-- 超过 5 分钟的事务
SELECT pid, usename, datname, state,
       now() - xact_start AS xact_duration,
       left(query, 100) AS query_preview
FROM pg_stat_activity
WHERE xact_start IS NOT NULL
  AND now() - xact_start > interval '5 minutes'
ORDER BY xact_start;

-- ----------------------------------------
-- 锁等待
-- ----------------------------------------

-- 查看阻塞关系
SELECT
    blocked.pid AS blocked_pid,
    blocked.usename AS blocked_user,
    left(blocked.query, 80) AS blocked_query,
    blocking.pid AS blocking_pid,
    blocking.usename AS blocking_user,
    left(blocking.query, 80) AS blocking_query
FROM pg_locks bl
JOIN pg_stat_activity blocked ON bl.pid = blocked.pid
JOIN pg_locks kl ON bl.locktype = kl.locktype
    AND bl.database IS NOT DISTINCT FROM kl.database
    AND bl.relation IS NOT DISTINCT FROM kl.relation
    AND bl.page IS NOT DISTINCT FROM kl.page
    AND bl.tuple IS NOT DISTINCT FROM kl.tuple
    AND bl.transactionid IS NOT DISTINCT FROM kl.transactionid
    AND bl.classid IS NOT DISTINCT FROM kl.classid
    AND bl.objid IS NOT DISTINCT FROM kl.objid
    AND bl.objsubid IS NOT DISTINCT FROM kl.objsubid
    AND bl.pid != kl.pid
JOIN pg_stat_activity blocking ON kl.pid = blocking.pid
WHERE NOT bl.granted
  AND kl.granted;

-- ----------------------------------------
-- 数据库统计
-- ----------------------------------------

-- 数据库级概览
SELECT datname,
       numbackends,
       xact_commit,
       xact_rollback,
       blks_read,
       blks_hit,
       round(blks_hit::numeric / nullif(blks_hit + blks_read, 0) * 100, 2) AS cache_hit_pct,
       tup_returned,
       tup_fetched,
       tup_inserted,
       tup_updated,
       tup_deleted
FROM pg_stat_database
WHERE datname = current_database();

-- ----------------------------------------
-- 表统计
-- ----------------------------------------

-- 表扫描与行操作统计
SELECT schemaname, relname,
       seq_scan, seq_tup_read,
       idx_scan, idx_tup_fetch,
       n_tup_ins, n_tup_upd, n_tup_del,
       n_live_tup, n_dead_tup,
       last_vacuum, last_autovacuum,
       last_analyze, last_autoanalyze
FROM pg_stat_user_tables
ORDER BY seq_scan DESC
LIMIT 20;

-- ----------------------------------------
-- 索引统计
-- ----------------------------------------

-- 索引使用情况
SELECT schemaname, relname, indexrelname,
       idx_scan, idx_tup_read, idx_tup_fetch
FROM pg_stat_user_indexes
ORDER BY idx_scan DESC
LIMIT 20;

-- 未使用的索引
SELECT schemaname, relname, indexrelname, idx_scan
FROM pg_stat_user_indexes
WHERE idx_scan = 0
ORDER BY schemaname, relname;

-- ----------------------------------------
-- pg_stat_statements 已拆分为独立模板：pg-stat-statements.sql
-- 该模板包含前置检查和条件保护，可安全执行
-- ----------------------------------------
