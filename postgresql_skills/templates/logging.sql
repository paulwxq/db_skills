-- ============================================
-- 日志参数查询模板
-- ============================================

-- ----------------------------------------
-- 查看所有日志相关参数
-- ----------------------------------------
SELECT name, setting, unit, short_desc
FROM pg_settings
WHERE name IN (
    'logging_collector',
    'log_destination',
    'log_directory',
    'log_filename',
    'log_file_mode',
    'log_rotation_age',
    'log_rotation_size',
    'log_truncate_on_rotation',
    'log_min_messages',
    'log_min_error_statement',
    'log_min_duration_statement',
    'log_statement',
    'log_duration',
    'log_line_prefix',
    'log_timezone',
    'log_connections',
    'log_disconnections',
    'log_lock_waits',
    'log_temp_files',
    'log_autovacuum_min_duration'
)
ORDER BY name;

-- ----------------------------------------
-- 关键日志定位参数
-- ----------------------------------------

-- data_directory（日志目录可能是相对路径）
SHOW data_directory;

-- 日志目录
SHOW log_directory;

-- 日志文件名模式
SHOW log_filename;

-- 日志目的地
SHOW log_destination;

-- logging_collector 是否启用
SHOW logging_collector;

-- ----------------------------------------
-- 当前日志文件（PostgreSQL 10+）
-- ----------------------------------------
SELECT pg_current_logfile();
SELECT pg_current_logfile('csvlog');

-- ----------------------------------------
-- 慢查询日志阈值
-- ----------------------------------------
SHOW log_min_duration_statement;

-- ----------------------------------------
-- 语句日志级别
-- ----------------------------------------
SHOW log_statement;
