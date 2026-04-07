# Safety Rules

## 1. 默认允许直接执行的动作

以下动作通常是安全的，可直接执行无需额外确认：

- 检查 `psql` 是否可用
- 检查 PostgreSQL 版本
- 检查当前数据库和当前用户
- 列出 schema
- 列出表
- 查看字段结构
- 查看索引定义
- 查看注释
- 查看活动会话（`pg_stat_activity`）
- 查看当前锁（`pg_locks`）
- 查看日志参数
- 读取有限行数的样本数据
- 查看统计视图
- 查看数据库 / 表 / 索引大小

---

## 2. 必须确认的动作

以下动作在执行前**必须**获得用户确认。即使用户在对话中表达了"直接执行"的意愿，Agent 仍然必须在执行前列出变更内容和影响范围，等待用户对该具体操作的确认。这条规则没有例外。

### DDL 操作

- CREATE DATABASE
- DROP DATABASE
- ALTER DATABASE OWNER
- CREATE SCHEMA
- DROP SCHEMA
- CREATE TABLE
- ALTER TABLE（结构变更）
- DROP TABLE
- CREATE INDEX
- DROP INDEX

### DCL 操作

- CREATE ROLE
- ALTER ROLE
- DROP ROLE
- GRANT
- REVOKE
- ALTER DEFAULT PRIVILEGES

### 存储操作

- CREATE TABLESPACE
- ALTER TABLE SET TABLESPACE
- ALTER INDEX SET TABLESPACE

### 数据写入

- 大规模样本数据插入
- 批量 INSERT / UPDATE / DELETE

---

## 3. 默认禁止直接执行的动作

以下动作在没有明确确认的情况下默认禁止：

- 在未知或疑似生产环境执行 destructive 操作
- 授予 SUPERUSER 权限
- 授予广泛的角色管理权限
- 无审查地修改全局默认权限
- 无确认地大范围变更对象 ownership
- 无确认地在 tablespace 之间迁移大量对象
- 在生产环境随意启用高开销日志配置

---

## 4. 环境敏感性判断

如果环境可能是生产环境，必须更加保守。

生产环境信号包括：

- 存在真实业务数据
- 存在真实业务 schema 命名
- 用户语言暗示生产用途
- 使用高权限账号
- 涉及正在进行的运维事故

**当不确定时，默认假设环境是重要环境。**

---

## 5. 样本数据规则

- 默认写入测试 schema 或用户显式指定的目标
- 插入前必须确认目标表
- 大批量数据必须明确数量级
- 不得随意向生产表写入样本数据

---

## 6. 认证凭据安全

PostgreSQL 支持多种免交互认证方式，安全性从高到低：

| 方式 | 适用场景 | 安全性 | 说明 |
|------|---------|--------|------|
| `.pgpass` / `PGPASSFILE` | 持久环境、多用户服务器、生产运维 | 高 | 凭据存储在权限受控的文件中，不暴露于进程环境 |
| `PGPASSWORD` 环境变量 | CI/CD、容器、临时脚本 | 中 | 便捷，但在某些系统中可通过 `/proc/<pid>/environ` 或 `ps e` 被其他用户读取 |
| 命令行中嵌入密码 | 不推荐 | 低 | 会出现在 shell 历史和进程列表中 |

**默认建议**：

- 如果环境中已配置 `.pgpass` 或 `PGPASSFILE`，优先使用
- `PGPASSWORD` 环境变量完全可接受，不需要强制用户改用 `.pgpass`
- 用户在对话中直接提供密码也可接受，Agent 应通过 `export PGPASSWORD=...` 设置后使用
- **禁止**在命令行参数中嵌入密码（会出现在 shell 历史和进程列表中）
- **禁止**在输出、日志或对话回显中明文打印密码

**认证检查是建议性的，不应阻断连接流程。** 如果所有免密方式都未就绪，直接尝试连接；认证失败时向用户说明可选方式，不要反复追问。

---

## 7. 确认时的信息要求

请求确认时，必须清楚说明：

- 将要变更什么
- 影响哪些对象
- 存在什么风险
- 如何验证结果
