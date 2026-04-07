# db_skills

面向 AI Agent 的数据库操作 Skill 集合，配合 [Context7](https://github.com/upstash/context7) MCP 实现数据库管理自动化。

## 核心思路

```
Agent = Skill（流程 + 规则 + 安全边界）+ Context7（官方文档实时检索）+ 本地 CLI（实际执行）
```

- **Skill** 定义任务分类、执行流程、安全规则和最小模板
- **Context7** 在需要时动态检索数据库官方文档（精确语法、参数、版本差异）
- **本地 CLI** 执行实际操作（如 `psql`、`gpcli` 等）

Skill 不复制官方文档，而是在需要细节时通过 Context7 按需查询，确保信息始终准确且不过时。

## 项目状态

| Skill | 状态 | 说明 |
|-------|------|------|
| PostgreSQL | v1 完成 | 连接、管理、元数据、权限、监控、日志、排障 11 个模块 |
| Greenplum | 规划中 | 基于 PostgreSQL 扩展，将增加分布策略、扩缩容等模块 |
| Neo4j | 规划中 | 图数据库操作 Skill |

## 目录结构

```text
db_skills/
├── postgresql_skills/          # PostgreSQL Skill v1
│   ├── SKILL.md                # Skill 总纲（含 YAML frontmatter，供 Agent 加载）
│   ├── README.md               # Skill 说明
│   ├── rules/                  # 执行规则
│   │   ├── safety-rules.md     # 安全策略
│   │   ├── context7-routing.md # Context7 调用规则
│   │   └── execution-conventions.md  # 执行约定
│   ├── modules/                # 11 个功能模块
│   │   ├── 01-connection.md
│   │   ├── 02-database-admin.md
│   │   ├── 03-schema-table.md
│   │   ├── 04-index.md
│   │   ├── 05-role-privilege.md
│   │   ├── 06-tablespace.md
│   │   ├── 07-metadata.md
│   │   ├── 08-sample-data.md
│   │   ├── 09-monitoring.md
│   │   ├── 10-logging.md
│   │   └── 11-troubleshooting.md
│   └── templates/              # 可复用 SQL 模板
│       ├── connection.sql
│       ├── create-role.sql
│       ├── logging.sql
│       ├── metadata.sql
│       ├── monitoring.sql
│       ├── pg-stat-statements.sql
│       ├── privilege.sql
│       └── sample-data.sql
├── docs/                       # 设计文档
└── README.md                   # 本文件
```

## Skill 架构设计

每个数据库 Skill 遵循统一的分层架构：

```
┌─────────────────────────────────────┐
│  SKILL.md（总纲）                    │
│  - 身份定义、任务分类、默认规则        │
├──────────┬──────────┬───────────────┤
│  rules/  │ modules/ │  templates/   │
│  安全规则  │ 功能模块  │  SQL 模板     │
│  文档路由  │ 执行流程  │  复用脚本     │
│  执行约定  │ 最小模板  │              │
├──────────┴──────────┴───────────────┤
│  Context7（按需查询官方文档）          │
└─────────────────────────────────────┘
```

### 设计原则

1. **先探查，后变更** — 默认先查看现状，再执行变更
2. **安全优先** — 高风险动作（DDL、DCL、大批量写入）必须确认
3. **变更必验证** — 每次变更后回查确认
4. **最小权限** — 权限操作遵循最小权限原则
5. **文档按需查询** — 不在 Skill 中复制官方文档，通过 Context7 动态检索

### 工作流程

```
接收请求 → 分类任务 → 探查现状 → 评估风险
  → 需要文档细节？→ Context7 查询
  → 高风险？→ 向用户确认
  → 执行 → 验证 → 总结输出
```

## 与 Context7 的配合

Skill 定义了何时以及如何调用 Context7：

- **触发条件**：语法不确定、参数含义不明、版本差异、系统视图字段等
- **查询规则**：具体、带版本、一次一个概念
- **结果使用**：只提取任务所需片段，不做大段文档转储

详见各 Skill 的 `rules/context7-routing.md`。

## 应用场景

- 开发 / 测试环境的数据库管理与探查
- CI/CD 中自动化数据库操作（配合 Agent + MCP）
- 数据库运维辅助分析
- 通过 AI Agent 完成数据库 MCP 服务的工作

## 依赖

- 本地数据库客户端工具（如 `psql`）
- Context7 MCP 服务
- AI Agent 运行环境（Claude Code、Copilot CLI 等）
