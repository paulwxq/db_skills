-- ============================================
-- pg_stat_statements 查询模板（条件保护 + 版本自适应，可直接 psql -f 执行）
-- ============================================
--
-- 执行方式（从 pg_skills/ 目录）：
--   psql -X -f templates/pg-stat-statements.sql
--
-- 本模板会自动：
--   1. 检查扩展是否可用（已安装、已预加载），不可用时输出诊断信息并跳过
--   2. 检测服务器版本，自动选择正确的字段名（PG 13+ 或 PG 12）

DO $$
DECLARE
    ext_installed boolean;
    ext_available boolean;
    lib_value text;
    pg_ver int;
    time_col text;
    mean_col text;
    rec record;
BEGIN
    -- 检查 1：扩展是否已安装到当前数据库
    SELECT EXISTS(SELECT 1 FROM pg_extension WHERE extname = 'pg_stat_statements')
    INTO ext_installed;

    IF NOT ext_installed THEN
        SELECT EXISTS(SELECT 1 FROM pg_available_extensions WHERE name = 'pg_stat_statements')
        INTO ext_available;

        IF NOT ext_available THEN
            RAISE NOTICE '[pg_stat_statements] 不可用：服务器未编译此扩展';
        ELSE
            RAISE NOTICE '[pg_stat_statements] 未安装：请执行 CREATE EXTENSION pg_stat_statements;（需确认）';
        END IF;
        RETURN;
    END IF;

    -- 检查 2：是否已预加载
    SHOW shared_preload_libraries INTO lib_value;
    IF lib_value NOT LIKE '%pg_stat_statements%' THEN
        RAISE NOTICE '[pg_stat_statements] 未预加载：需要将 pg_stat_statements 加入 shared_preload_libraries 并重启服务器';
        RETURN;
    END IF;

    -- 检查 3：版本自适应字段名
    pg_ver := current_setting('server_version_num')::int;
    IF pg_ver >= 130000 THEN
        time_col := 'total_exec_time';
        mean_col := 'mean_exec_time';
    ELSE
        time_col := 'total_time';
        mean_col := 'mean_time';
    END IF;

    RAISE NOTICE '[pg_stat_statements] 检查通过（PG %，使用字段 %/%）',
        pg_ver, time_col, mean_col;

    -- 查询 1：Top 10 慢查询（按平均执行时间）
    RAISE NOTICE '';
    RAISE NOTICE '=== Top 10 慢查询（按平均执行时间）===';
    RAISE NOTICE '%', format('%-60s %8s %12s %12s %10s', 'query', 'calls', 'total_ms', 'mean_ms', 'rows');
    RAISE NOTICE '%', format('%-60s %8s %12s %12s %10s', '----', '-----', '--------', '-------', '----');
    FOR rec IN EXECUTE format(
        'SELECT left(query, 60) AS query_preview, calls,
                round(%I::numeric, 2) AS total_ms,
                round(%I::numeric, 2) AS mean_ms,
                rows
         FROM pg_stat_statements ORDER BY %I DESC LIMIT 10',
        time_col, mean_col, mean_col
    ) LOOP
        RAISE NOTICE '%', format('%-60s %8s %12s %12s %10s',
            rec.query_preview, rec.calls, rec.total_ms, rec.mean_ms, rec.rows);
    END LOOP;

    -- 查询 2：Top 10 高频查询
    RAISE NOTICE '';
    RAISE NOTICE '=== Top 10 高频查询 ===';
    RAISE NOTICE '%', format('%-60s %8s %12s %10s', 'query', 'calls', 'total_ms', 'rows');
    RAISE NOTICE '%', format('%-60s %8s %12s %10s', '----', '-----', '--------', '----');
    FOR rec IN EXECUTE format(
        'SELECT left(query, 60) AS query_preview, calls,
                round(%I::numeric, 2) AS total_ms,
                rows
         FROM pg_stat_statements ORDER BY calls DESC LIMIT 10',
        time_col
    ) LOOP
        RAISE NOTICE '%', format('%-60s %8s %12s %10s',
            rec.query_preview, rec.calls, rec.total_ms, rec.rows);
    END LOOP;
END $$;
