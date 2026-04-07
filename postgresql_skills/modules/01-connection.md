# 01 - 连接与环境准备

## 模块目标

处理 PostgreSQL 连接、环境准备、版本确认、连通性验证。

---

## 典型任务

- 检查 `psql` 是否安装
- 检查环境变量是否配置
- 验证数据库连接
- 查看当前数据库和当前用户
- 查看 PostgreSQL 版本

---

## 标准流程

1. 检查 `psql` 是否存在
2. 检查环境变量（PGHOST, PGPORT, PGDATABASE, PGUSER）
3. 执行最小连接测试
4. 输出当前库、当前用户、版本
5. **记录服务器主版本号**（如 12、14、16、17）。后续模块的 SQL 模板和统计视图字段依赖此版本信息。如果版本号未获取，监控和统计模块中的查询可能因字段不存在而报错
6. 如连接失败，转入 `11-troubleshooting.md`

---

## 认证方式检查（建议性，不阻断）

连接前可以检查认证方式是否已就绪。**此步骤是建议性的，不应阻断连接流程。**

推荐优先级（从高到低）：
1. `.pgpass` 文件（最安全，适合持久环境）
2. `PGPASSWORD` 环境变量（便捷，适合临时/CI 场景）
3. 用户在对话中直接提供密码（可接受，Agent 应设为 PGPASSWORD 后使用，不要嵌入命令行）

```bash
# 检查 .pgpass 是否存在
ls -la ~/.pgpass 2>/dev/null || echo "No .pgpass file"

# 检查 PGPASSFILE 是否指定
echo $PGPASSFILE

# 检查 PGPASSWORD 是否已设置（不打印值）
[ -n "$PGPASSWORD" ] && echo "PGPASSWORD is set" || echo "PGPASSWORD is not set"
```

**如果以上都未就绪**：直接尝试连接（可能是 peer/trust 认证）。如果连接因认证失败，向用户说明三种方式并询问偏好，不要反复追问或阻断流程。用户提供密码后，通过 `export PGPASSWORD=...` 设置即可继续。

在持久环境或多用户服务器上，可建议用户创建 `.pgpass` 文件。详见 `rules/safety-rules.md` § 6 和 `11-troubleshooting.md` § 10。

---

## 最小模板

```bash
# 检查 psql 是否存在
which psql

# 检查 psql 版本
psql --version

# 最小连接测试
psql -X -Atqc "SELECT current_database(), current_user;"

# 查看 PostgreSQL 版本（完整字符串）
psql -X -Atqc "SELECT version();"

# 提取服务器主版本号（数字，后续模块依赖此值判断字段可用性）
psql -X -Atqc "SHOW server_version_num;"
# 返回值如 160004 表示 16.4，前两位/三位为主版本：
#   120000+ = PG 12, 130000+ = PG 13, 140000+ = PG 14, ...

# 查看服务器编码和时区
psql -X -Atqc "SHOW server_encoding;"
psql -X -Atqc "SHOW timezone;"
```

---

## Context7 调用指引

当以下情况发生时调用 Context7：

- 不确定 `psql` 参数含义
- 不确定连接参数配置方式（如 SSL、连接字符串格式）
- 不确定版本特性差异
- 需要了解 `pg_hba.conf` 认证方式

### 推荐查询

- `PostgreSQL psql options`
- `PostgreSQL connection parameters`
- `PostgreSQL pg_hba.conf`
- `PostgreSQL SSL connection`

---

## 风险规则

- 连接测试为只读操作，可直接执行
- 不要在命令输出中暴露密码
- 如使用连接字符串，避免在日志中出现密码部分
