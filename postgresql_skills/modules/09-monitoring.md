# 09 - 监控、会话、锁与性能

## 模块目标

处理当前活动会话、锁等待、累计统计、性能观察。

---

## 典型任务

- 查看活动会话（`pg_stat_activity`）
- 查看长事务
- 查看锁等待（`pg_locks`）
- 查看数据库统计（`pg_stat_database`）
- 查看表统计（`pg_stat_user_tables`）
- 查看索引统计（`pg_stat_user_indexes`）
- 查看 `pg_stat_statements`（需要扩展）
- 查看函数统计

---

## 版本敏感字段

监控和统计视图的字段在不同 PostgreSQL 版本之间有变化。**执行前必须确认服务器主版本号**（见 `01-connection.md` 的 `SHOW server_version_num`）。

以下是本模块涉及的已知版本差异：

| 字段 / 视图 | 最低版本 | 说明 |
|-------------|---------|------|
| `pg_stat_activity.leader_pid` | PG 13 | 并行查询的 leader 进程，PG 12 及以下不存在 |
| `pg_stat_activity.query_id` | PG 14 | 查询指纹 ID，PG 13 及以下不存在 |
| `pg_stat_statements.total_exec_time` | PG 13 | PG 12 及以下使用 `total_time` |
| `pg_stat_statements.mean_exec_time` | PG 13 | PG 12 及以下使用 `mean_time` |
| `pg_stat_activity.wait_event_type` | PG 9.6 | PG 9.5 及以下使用 `waiting` (boolean) |
| `pg_locks.waitstart` | PG 14 | 锁等待开始时间，PG 13 及以下不存在 |

**如果不确定当前版本是否支持某字段，先查 Context7 再使用。**

---

## 标准流程

1. **确认服务器版本号**（如果本次会话尚未确认）
2. 确定需求：当前活动还是历史统计
3. 查看当前活动会话
4. 查看锁等待情况
5. 查看累计统计信息
6. 如涉及 `pg_stat_statements` 但不确定用法，调用 Context7
7. 必要时转入 `10-logging.md` 查看日志

---

## 最小模板

```sql
-- 查看活动会话
SELECT pid, usename, datname, state, query_start,
       now() - query_start AS duration, query
FROM pg_stat_activity
WHERE state != 'idle'
ORDER BY query_start;

-- 查看长事务（超过 5 分钟）
SELECT pid, usename, datname, state,
       now() - xact_start AS xact_duration,
       query
FROM pg_stat_activity
WHERE xact_start IS NOT NULL
  AND now() - xact_start > interval '5 minutes'
ORDER BY xact_start;

-- 查看锁等待
SELECT
    blocked.pid AS blocked_pid,
    blocked.usename AS blocked_user,
    blocked.query AS blocked_query,
    blocking.pid AS blocking_pid,
    blocking.usename AS blocking_user,
    blocking.query AS blocking_query
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

-- 数据库级统计
SELECT datname, numbackends, xact_commit, xact_rollback,
       blks_read, blks_hit,
       round(blks_hit::numeric / nullif(blks_hit + blks_read, 0) * 100, 2) AS cache_hit_ratio
FROM pg_stat_database
WHERE datname = current_database();

-- 表级统计（扫描与更新）
SELECT schemaname, relname,
       seq_scan, seq_tup_read,
       idx_scan, idx_tup_fetch,
       n_tup_ins, n_tup_upd, n_tup_del,
       n_live_tup, n_dead_tup
FROM pg_stat_user_tables
ORDER BY seq_scan DESC
LIMIT 20;

-- 索引使用统计
SELECT schemaname, relname, indexrelname,
       idx_scan, idx_tup_read, idx_tup_fetch
FROM pg_stat_user_indexes
ORDER BY idx_scan DESC
LIMIT 20;

-- pg_stat_statements 查询已拆分为独立模板，包含条件保护：
--   psql -X -f templates/pg-stat-statements.sql
-- 该模板会自动检查扩展安装、预加载状态，不可用时输出诊断信息并跳过查询。
-- 不要在本模板中直接查询 pg_stat_statements。
```

---

## Context7 调用指引

当以下情况发生时调用 Context7：

- `pg_stat_activity` 字段含义不确定
- `pg_locks` 的 locktype / granted 含义
- 统计视图的数据新鲜度和刷新机制
- `pg_stat_statements` 的安装和配置要求
- 性能指标的解读方式

### 推荐查询

- `PostgreSQL pg_stat_activity`
- `PostgreSQL pg_locks`
- `PostgreSQL pg_stat_database`
- `PostgreSQL pg_stat_user_tables`
- `PostgreSQL pg_stat_statements`
- `PostgreSQL monitoring stats`

---

## 风险规则

- 监控查询为只读操作，可直接执行
- 必须明确区分：
  - **当前活动**（`pg_stat_activity`）= 实时快照
  - **累计统计**（`pg_stat_database` 等）= 自上次 reset 以来的累计
  - **日志**（文件）= 服务器写入的记录
- 不要把统计视图误当作日志
- 不要把 `pg_stat_activity` 误当作历史记录

### 模块联动

- **发现慢 SQL 或异常查询后** → 转 `10-logging.md` 查看服务器日志，获取更多上下文（如执行计划详情、错误上下文、自动记录的慢查询日志）。`pg_stat_statements` 只提供聚合统计，日志中可能有单次执行的完整计划和参数
- **发现锁等待或长事务后** → 日志中可能记录了 `log_lock_waits` 产生的等待事件和持续时间
- **发现权限相关异常后** → 转 `05-role-privilege.md` 检查角色和权限配置
- **需要了解表结构或索引设计** → 转 `07-metadata.md` 探查对象定义
