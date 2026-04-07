# PostgreSQL Encyclopedia Skill

一个面向 Agent 的 PostgreSQL 百科型 Skill。

它不是 PostgreSQL 官方文档的复制品，而是一套用于 **连接、探查、管理、监控、排障** 的操作手册、执行规则和文档路由规范。

## 核心思路

- 用 **Skill** 管理流程、规则和安全边界
- 用 **Context7** 查询 PostgreSQL 官方文档细节
- 用本地 **psql / shell** 执行实际操作

## 依赖条件

### 本地工具

- `psql` 客户端
- shell 执行能力

### 文档工具

- Context7 MCP

### PostgreSQL 连接

建议通过环境变量提供连接信息：

- `PGHOST`
- `PGPORT`
- `PGDATABASE`
- `PGUSER`
- `PGPASSWORD`

默认使用 `psql -X` 避免加载本地 `.psqlrc`。

## 目录结构

```text
pg_skills/
├─ README.md                 # 本文件
├─ SKILL.md                  # Skill 总纲（含 YAML frontmatter）
├─ rules/
│  ├─ safety-rules.md        # 安全规则
│  ├─ context7-routing.md    # Context7 调用规则
│  └─ execution-conventions.md # 执行约定
├─ modules/
│  ├─ 01-connection.md       # 连接与环境
│  ├─ 02-database-admin.md   # 数据库管理
│  ├─ 03-schema-table.md     # Schema / Table / Constraint
│  ├─ 04-index.md            # 索引管理
│  ├─ 05-role-privilege.md   # 角色与权限
│  ├─ 06-tablespace.md       # 表空间
│  ├─ 07-metadata.md         # 元数据探查
│  ├─ 08-sample-data.md      # 样本数据生成
│  ├─ 09-monitoring.md       # 监控与性能
│  ├─ 10-logging.md          # 日志
│  └─ 11-troubleshooting.md  # 故障排查
└─ templates/
   ├─ connection.sql         # 连接校验 SQL
   ├─ metadata.sql           # 元数据查询模板
   ├─ create-role.sql        # 角色创建模板
   ├─ privilege.sql          # 授权模板
   ├─ sample-data.sql        # 样本数据模板
   ├─ monitoring.sql              # 监控查询模板（不含 pg_stat_statements）
   ├─ pg-stat-statements.sql     # pg_stat_statements 专用模板（含条件保护）
   └─ logging.sql                # 日志参数查询模板
```

## 适用范围

- 开发环境数据库管理
- 测试环境探查与调试
- 运维辅助分析

## 不适用场景

- 无授权的生产变更
- 无确认的 destructive 操作
- 替代 DBA 专业判断
