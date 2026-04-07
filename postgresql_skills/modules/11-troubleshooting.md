# 11 - 故障排查

## 模块目标

处理常见 PostgreSQL 操作故障的诊断与排查。

---

## 标准排查模式

对每个问题按以下结构处理：

1. **现象**：观察到了什么
2. **可能原因**：常见原因列表
3. **排查步骤**：逐步检查
4. **Context7 主题**：如需查文档的推荐主题

---

## 常见故障

### 1. psql 不存在

**现象**：`which psql` 无输出或报错

**可能原因**：
- PostgreSQL 客户端未安装
- `psql` 不在 PATH 中

**排查步骤**：
1. `which psql`
2. `find / -name psql -type f 2>/dev/null | head -5`
3. 检查 PATH 环境变量
4. 建议安装 PostgreSQL 客户端

---

### 2. 无法连接数据库

**现象**：`psql` 报连接错误

**可能原因**：
- 环境变量未设置或错误
- PostgreSQL 服务未运行
- 防火墙阻断
- `pg_hba.conf` 不允许连接
- SSL 配置问题

**排查步骤**：
1. 检查环境变量 `echo $PGHOST $PGPORT $PGDATABASE $PGUSER`
2. 检查服务状态 `pg_isready -h $PGHOST -p $PGPORT`
3. 检查网络连通 `nc -zv $PGHOST $PGPORT`
4. 查看错误信息中的具体原因
5. 如涉及 pg_hba.conf，查 Context7

**Context7 主题**：`PostgreSQL pg_hba.conf`, `PostgreSQL connection troubleshooting`

---

### 3. 密码认证失败

**现象**：`FATAL: password authentication failed for user "xxx"`

**可能原因**：
- 密码错误
- 用户不存在
- `pg_hba.conf` 要求的认证方式与提供的不匹配

**排查步骤**：
1. 确认用户名拼写
2. 确认密码是否正确
3. 查看 `pg_hba.conf` 认证方式
4. 检查是否存在该角色：`SELECT rolname FROM pg_roles WHERE rolname = 'xxx';`

---

### 4. 权限不足

**现象**：`ERROR: permission denied for ...`

**可能原因**：
- 当前角色缺少必要权限
- schema 级 USAGE 权限缺失
- 表级权限缺失
- 默认权限未配置

**排查步骤**：
1. 确认当前用户：`SELECT current_user;`
2. 查看角色属性：`SELECT * FROM pg_roles WHERE rolname = current_user;`
3. 查看表级权限：查 `information_schema.table_privileges`
4. 查看 schema 权限：`\dn+`（或查 pg_catalog）
5. 如涉及默认权限，查 Context7

**Context7 主题**：`PostgreSQL GRANT`, `PostgreSQL ALTER DEFAULT PRIVILEGES`

---

### 5. 对象不存在

**现象**：`ERROR: relation "xxx" does not exist`

**可能原因**：
- 表名拼写错误
- 未指定 schema（不在 search_path 中）
- 对象在其他 schema 中
- 对象尚未创建

**排查步骤**：
1. 检查 search_path：`SHOW search_path;`
2. 在所有 schema 中搜索对象：
   ```sql
   SELECT schemaname, tablename FROM pg_tables WHERE tablename = 'xxx';
   ```
3. 确认 schema 前缀是否正确
4. 确认是否需要用引号（大小写敏感问题）

---

### 6. 扩展未启用

**现象**：`ERROR: relation "pg_stat_statements" does not exist` 等

**可能原因**：
- 扩展未安装
- 扩展未在当前数据库中创建
- 需要预加载配置（如 shared_preload_libraries）

**排查步骤**：
1. 查看可用扩展：`SELECT * FROM pg_available_extensions WHERE name = 'pg_stat_statements';`
2. 查看已安装扩展：`SELECT * FROM pg_extension;`
3. 如未创建：`CREATE EXTENSION pg_stat_statements;`（需确认）
4. 如需预加载，查看 `shared_preload_libraries` 参数

**Context7 主题**：`PostgreSQL pg_stat_statements setup`, `PostgreSQL shared_preload_libraries`

---

### 7. 看不到统计信息

**现象**：统计视图返回空或全零

**可能原因**：
- `track_activities` 未启用
- `track_counts` 未启用
- 统计收集器未运行
- 数据库刚启动，尚无累计数据

**排查步骤**：
1. 检查参数：
   ```sql
   SHOW track_activities;
   SHOW track_counts;
   ```
2. 查看是否有活动连接产生统计
3. 确认查看的是正确的数据库

**Context7 主题**：`PostgreSQL monitoring stats configuration`, `PostgreSQL track_activities`

---

### 8. 找不到日志文件

**现象**：不知道日志在哪里

**排查步骤**：
1. 查看日志参数：
   ```sql
   SHOW logging_collector;
   SHOW log_directory;
   SHOW log_filename;
   SHOW data_directory;
   ```
2. 如 log_directory 是相对路径，基于 data_directory 拼接
3. 用 shell 检查目录是否存在和文件列表
4. 尝试 `SELECT pg_current_logfile();`

**Context7 主题**：`PostgreSQL log_directory`, `PostgreSQL logging_collector`

---

### 9. 版本差异导致字段不存在

**现象**：`ERROR: column "xxx" does not exist`，但 SQL 是从模板或文档中复制的

**关键识别特征**：
- 错误指向的是系统视图（`pg_stat_activity`、`pg_stat_statements`、`pg_locks` 等）的字段
- SQL 语法本身没有拼写错误
- 在其他环境能正常执行

**可能原因**：
- SQL 模板基于较新版本编写，当前服务器版本较老
- 统计视图字段在不同主版本间有增减

**排查步骤**：
1. 确认当前版本：
   ```sql
   SHOW server_version_num;
   ```
2. 对照 `09-monitoring.md` 的"版本敏感字段"表，检查报错字段的最低版本要求
3. 常见的版本替换关系：
   - `total_exec_time` / `mean_exec_time` → PG 12 使用 `total_time` / `mean_time`
   - `leader_pid` → PG 12 及以下不存在，移除该字段
   - `query_id` → PG 13 及以下不存在，移除该字段
   - `waitstart` → PG 13 及以下不存在，移除该字段
4. 如果不确定当前版本的字段列表，查 Context7：如 `PostgreSQL 12 pg_stat_statements columns`

**Context7 主题**：`PostgreSQL pg_stat_statements`, `PostgreSQL pg_stat_activity columns`

---

### 10. SQL 执行失败

**现象**：SQL 报语法错误或执行错误

**排查步骤**：
1. 仔细阅读错误信息
2. 检查语法是否正确
3. 检查对象名、类型名是否正确
4. 检查权限
5. 如语法不确定，调用 Context7 查询正确语法
6. 检查 PostgreSQL 版本是否支持该语法（参考第 9 条）

---

### 11. 认证未配置（无 .pgpass、无 PGPASSWORD）

**现象**：`psql` 提示输入密码或认证失败，且 `.pgpass` 和 `PGPASSWORD` 均未配置

**处理原则**：认证问题不应阻断流程。按以下顺序尝试解决：

**步骤 1：直接尝试连接**（可能是 peer/trust 认证，无需密码）

**步骤 2：如果认证失败，向用户说明三种方式**：
- 在对话中提供密码，Agent 通过 `export PGPASSWORD=...` 设置后继续
- 用户自行设置 `PGPASSWORD` 环境变量
- 用户创建 `.pgpass` 文件（适合长期使用）

**步骤 3：如果用户选择创建 .pgpass**，提供以下指引：

```bash
# 创建 .pgpass 文件
# 格式：hostname:port:database:username:password
# 使用 * 作为通配符
echo 'localhost:5432:*:myuser:mypassword' >> ~/.pgpass

# 必须设置权限为 0600，否则 PostgreSQL 会忽略该文件
chmod 0600 ~/.pgpass
```

**不要做的事**：
- 不要因为 `.pgpass` 不存在就反复询问用户
- 不要强制用户必须创建 `.pgpass` 才能继续
- 不要在命令行参数中嵌入密码

---

## 通用排查原则

- 先读错误信息，不要跳过
- 先检查最常见的原因
- 先做只读排查，不要急于修改
- 不确定时查 Context7
- 排查结果要明确总结：问题原因 + 建议操作
