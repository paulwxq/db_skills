# 10 - 日志

## 模块目标

处理 PostgreSQL 日志参数查看、日志目录定位、日志文件查看。

**重要：日志模块与监控模块是不同的概念，不要混淆。**

---

## 典型任务

- 查看日志相关参数配置
- 查看 log_directory 和 log_filename
- 识别 logging_collector 是否启用
- 用 shell 查看日志文件
- 区分日志、统计视图、活动会话

---

## 关键区分

| 概念 | 来源 | 说明 |
|------|------|------|
| 日志（log） | 服务器写入文件 | 由 logging_collector 控制 |
| 活动会话 | `pg_stat_activity` | 当前实时状态 |
| 累计统计 | `pg_stat_database` 等 | 自 reset 以来的累计 |

**`pg_stat_activity` 不是日志。统计视图不是日志。**

---

## 标准流程

1. 先查看日志相关参数
2. 确认 logging_collector 是否启用
3. 确定日志目录和文件命名模式
4. **快速定位当前日志文件**：执行 `SELECT pg_current_logfile();`（PG 10+）。如果返回结果，可直接用 shell 查看该文件，跳过手动拼接路径的步骤
5. 如 `pg_current_logfile()` 返回 NULL 或不可用，根据 `data_directory` + `log_directory` + `log_filename` 手动定位
6. 用 shell 查看日志文件内容
7. 如参数含义不清楚，调用 Context7

---

## 最小模板

```sql
-- 查看日志相关参数
SELECT name, setting, unit, short_desc
FROM pg_settings
WHERE name IN (
    'logging_collector',
    'log_destination',
    'log_directory',
    'log_filename',
    'log_rotation_age',
    'log_rotation_size',
    'log_min_duration_statement',
    'log_statement',
    'log_line_prefix',
    'log_timezone'
)
ORDER BY name;

-- 查看 data_directory（日志目录可能是相对路径）
SHOW data_directory;

-- 查看日志目录
SHOW log_directory;

-- 查看日志文件名模式
SHOW log_filename;

-- 查看当前日志文件（PostgreSQL 10+）
SELECT pg_current_logfile();
```

```bash
# 用 shell 列出日志目录中的文件（需要知道路径）
ls -lt /var/log/postgresql/ | head -20

# 查看最近日志的尾部
tail -100 /var/log/postgresql/postgresql-17-main.log
```

---

## Context7 调用指引

当以下情况发生时调用 Context7：

- logging_collector 的行为和配置
- log_destination 的可选值（stderr, csvlog, syslog, jsonlog）
- log_filename 的格式化方式
- log_min_duration_statement 的含义
- log_statement 的级别（none, ddl, mod, all）
- csvlog 的字段定义
- 各日志参数对性能的影响

### 推荐查询

- `PostgreSQL logging_collector`
- `PostgreSQL log_destination`
- `PostgreSQL log_directory`
- `PostgreSQL log_filename`
- `PostgreSQL csvlog`
- `PostgreSQL log_min_duration_statement`
- `PostgreSQL log_statement`

---

## 风险规则

- 查看日志参数为只读操作，可直接执行
- 查看日志文件内容为只读操作，但需要文件系统权限
- **不要随意建议在生产环境启用高开销日志配置**（如 `log_statement = 'all'`）
- 修改日志参数涉及服务器配置变更，需要确认
- 部分参数修改需要 reload 或 restart，需要提醒
