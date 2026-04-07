~~~md
# PostgreSQL Encyclopedia Skill

一个面向 Agent 的 PostgreSQL 百科型 Skill。  
它不是 PostgreSQL 官方文档的复制品，而是一套用于 **连接、探查、管理、监控、排障** 的操作手册、执行规则和文档路由规范。

本 Skill 的核心思路是：

- 用 **Skill** 管理流程、规则和安全边界
- 用 **Context7** 查询 PostgreSQL 官方文档细节
- 用本地 **psql / shell** 执行实际操作

---

## 1. 设计目标

这个 Skill 的目标不是“记住所有 PostgreSQL 知识”，而是让 Agent 能够稳定地完成下面这些任务：

- 连接 PostgreSQL 并验证环境
- 查询数据库、schema、表、字段、索引等元数据
- 创建数据库、schema、表、索引
- 创建角色、用户并进行权限管理
- 处理 tablespace 相关操作
- 生成样本数据或测试数据
- 查询活动会话、锁、统计信息
- 查看日志配置并定位日志文件
- 对常见错误进行排障分析
- 在不确定语法或语义时，自动通过 Context7 查询官方文档

---

## 2. 为什么需要这个 Skill

如果直接把 PostgreSQL 全部知识塞给 Agent，会出现几个问题：

- 内容太多，难维护
- PostgreSQL 版本变化后容易过时
- Agent 容易把“规则”和“文档细节”混在一起
- 高风险动作缺乏明确边界
- 查询、管理、监控、日志、权限等任务没有统一流程

因此，本 Skill 采用分层方式：

### Skill 负责
- 任务分类
- 执行顺序
- 风险规则
- 最小模板
- Context7 调用指引

### Context7 负责
- PostgreSQL 官方文档检索
- 精确语法
- 参数说明
- 系统视图定义
- 高级特性和版本差异

### psql / shell 负责
- 执行 SQL
- 调用 PostgreSQL 元命令
- 查看日志文件
- 输出实际结果

---

## 3. Skill 的定位

这个仓库中的 Skill 应该被理解为：

- PostgreSQL 操作手册
- Agent 执行规范
- PostgreSQL 百科型提纲
- 风险控制层
- 文档路由层

它**不是**：

- PostgreSQL 官方文档全集
- 通用数据库驱动
- 无限制自动化脚本
- 无确认就能执行危险动作的工具包

---

## 4. 适用范围

本 Skill 适用于以下场景：

### 4.1 数据库连接与环境校验
- 检查 `psql` 是否可用
- 检查 PostgreSQL 版本
- 检查当前数据库和当前用户
- 检查连接是否正常

### 4.2 数据库对象管理
- 创建数据库
- 删除数据库
- 创建 schema
- 创建表
- 修改表
- 删除表
- 创建索引
- 删除索引

### 4.3 权限与角色管理
- 创建登录角色
- 创建权限角色
- GRANT / REVOKE
- 默认权限配置
- 最小权限原则实施

### 4.4 元数据探查
- 列出 schema
- 列出表
- 查看字段结构
- 查看主键、外键、索引、注释
- 查看对象大小

### 4.5 样本数据生成
- 生成演示数据
- 生成测试数据
- 批量造数
- 生成时间序列样本

### 4.6 监控与排障
- 查看活动会话
- 查看锁等待
- 查看统计信息
- 查看日志配置
- 定位日志目录
- 分析连接失败、权限问题、对象不存在等错误

---

## 5. 设计原则

### 5.1 先探查，后变更
默认先查看现状，再执行变更。

### 5.2 先分类，再执行
必须先识别任务属于哪个模块，然后进入相应流程。

### 5.3 复杂细节交给 Context7
Skill 不保存全部语法细节，而在需要时调用 Context7 获取 PostgreSQL 官方文档。

### 5.4 高风险动作必须确认
涉及删除、授权、默认权限、tablespace 迁移、大批量写入等操作时，必须确认。

### 5.5 变更后必须验证
执行任何写操作后，都要回查验证。

### 5.6 默认最小权限
权限相关操作必须遵循最小权限原则。

---

## 6. 依赖条件

要让这个 Skill 正常工作，建议具备以下条件：

### 6.1 本地工具
- `psql`
- shell 执行能力
- 访问 PostgreSQL 所需的客户端环境

### 6.2 文档工具
- Context7 MCP

### 6.3 PostgreSQL 连接方式
建议通过环境变量提供连接信息：

- `PGHOST`
- `PGPORT`
- `PGDATABASE`
- `PGUSER`
- `PGPASSWORD`

推荐默认使用：

```bash
psql -X
~~~

这样可以避免加载本地 `.psqlrc`，减少不可预期行为。

------

## 7. 目录结构

建议目录如下：

```text
postgresql-skill/
├─ README.md
├─ skill.md
├─ rules/
│  ├─ safety-rules.md
│  ├─ context7-routing.md
│  └─ execution-conventions.md
├─ modules/
│  ├─ 01-connection.md
│  ├─ 02-database-admin.md
│  ├─ 03-schema-table.md
│  ├─ 04-index.md
│  ├─ 05-role-privilege.md
│  ├─ 06-tablespace.md
│  ├─ 07-metadata.md
│  ├─ 08-sample-data.md
│  ├─ 09-monitoring.md
│  ├─ 10-logging.md
│  └─ 11-troubleshooting.md
└─ templates/
   ├─ connection.sql
   ├─ metadata.sql
   ├─ create-role.sql
   ├─ privilege.sql
   ├─ sample-data.sql
   ├─ monitoring.sql
   └─ logging.sql
```

------

## 8. 核心文件说明

### `skill.md`

整个 Skill 的总纲。
定义：

- Skill 身份
- 任务范围
- 默认执行规则
- Context7 调用规则
- 安全策略
- 各模块工作流

### `rules/safety-rules.md`

定义：

- 哪些动作默认允许直接执行
- 哪些动作必须确认
- 哪些动作默认禁止直接执行
- 样本数据写入边界
- 生产环境谨慎策略

### `rules/context7-routing.md`

定义：

- 什么情况下必须调用 Context7
- 如何构造 Context7 查询
- 如何使用 Context7 返回的文档片段
- 如何避免把 Skill 变成文档仓库

### `rules/execution-conventions.md`

定义：

- 默认执行顺序
- `psql` 使用规范
- 结果输出规则
- 失败处理规范
- 变更后的回查要求

### `modules/*.md`

每个模块对应一个主题领域，负责：

- 模块目标
- 典型任务
- 标准流程
- 最小模板
- Context7 调用提示
- 风险规则

### `templates/*.sql`

存放复用性较强的 SQL 模板。

------

## 9. Skill 的工作方式

当 Agent 接到用户请求后，应按以下顺序运行：

### 第一步：识别任务类型

判断当前请求属于：

- connection
- database admin
- schema/table
- index
- role/privilege
- tablespace
- metadata
- sample data
- monitoring
- logging
- troubleshooting

### 第二步：进入对应模块

读取相应模块的目标、流程和模板。

### 第三步：判断是否需要 Context7

如果当前任务涉及以下情况，则必须调用 Context7：

- 精确 SQL 语法不确定
- 参数行为不确定
- 系统视图含义不确定
- 权限语义不确定
- 日志参数不确定
- 高级特性行为不确定
- 版本差异可能影响行为

### 第四步：执行前探查

对变更型任务，先检查当前对象状态。

### 第五步：风险判断与确认

如涉及高风险动作，则说明计划、影响、风险，并请求确认。

### 第六步：执行

使用 `psql` / shell 执行。

### 第七步：验证

回查对象、权限、统计或数据状态。

### 第八步：总结

说明做了什么、成功与否、如何验证、是否仍有不确定项。

------

## 10. Context7 的使用方式

本 Skill 的一个重要设计目标是：**不复制 PostgreSQL 全部文档，而是通过 Context7 动态检索。**

因此，Agent 必须学会把 Context7 当作以下内容的来源：

- SQL 语法说明
- 参数定义
- 系统 catalog / 视图字段解释
- 权限语义
- tablespace 行为
- logging 行为
- monitoring 行为
- 高级特性和版本差异

### 推荐查询示例

- PostgreSQL CREATE DATABASE
- PostgreSQL CREATE ROLE
- PostgreSQL ALTER DEFAULT PRIVILEGES
- PostgreSQL pg_stat_activity
- PostgreSQL pg_locks
- PostgreSQL logging_collector
- PostgreSQL CREATE TABLESPACE
- PostgreSQL partial index
- PostgreSQL generated columns

### 使用规则

- 查询要具体
- 尽量带 PostgreSQL 版本
- 一次只问一个概念
- 只提取当前任务需要的内容
- 不把整篇官方文档复制进 Skill

------

## 11. 安全边界

本 Skill 默认采取保守策略。

### 一般可直接执行的动作

- 查看版本
- 查看当前数据库 / 用户
- 查看 schema、表、字段、索引
- 查看会话和锁
- 查看统计信息
- 查看日志参数
- 查看少量样本数据

### 必须确认的动作

- 创建数据库
- 删除数据库
- 创建 / 删除 schema
- 创建 / 删除表
- 创建 / 删除索引
- 创建 / 修改 / 删除角色
- GRANT / REVOKE
- 修改默认权限
- 创建 tablespace
- 移动表或索引到 tablespace
- 大批量样本数据写入

### 默认禁止直接执行的动作

- 未确认就删除数据库 / 表 / schema
- 未确认就授予高权限
- 未确认就修改广泛默认权限
- 未确认就执行高影响存储迁移
- 未确认就在疑似生产环境做 destructive 操作

------

## 12. 推荐的默认输出风格

Skill 驱动的 Agent 应尽量做到：

- 说明当前属于哪个模块
- 说明先检查什么
- 说明为什么要调用 Context7
- 说明为什么需要确认
- 说明执行了什么
- 说明如何验证
- 说明哪里仍然不确定

不要：

- 无提示直接执行危险操作
- 猜测 PostgreSQL 语法
- 把日志、统计视图、活动会话混为一谈
- 输出无关的大段文档内容

------

## 13. 示例：Agent 该如何使用这个 Skill

### 示例 1：用户要求“帮我看 public 下有哪些表”

Agent 应：

1. 路由到 metadata 模块
2. 直接执行只读探查
3. 无需确认
4. 列出表名并总结

### 示例 2：用户要求“帮我创建一个 appdb 数据库”

Agent 应：

1. 路由到 database-admin 模块
2. 先检查数据库是否已存在
3. 如果语法或参数不确定，查 Context7
4. 说明将创建数据库、可能的参数和风险
5. 请求确认
6. 执行
7. 回查数据库列表验证结果

### 示例 3：用户要求“给某个用户只读权限”

Agent 应：

1. 路由到 role-privilege 模块
2. 识别是登录角色还是权限角色
3. 查看现有角色和权限状态
4. 如有默认权限或继承疑问，查 Context7
5. 说明授权范围和风险
6. 请求确认
7. 执行 grant
8. 回查权限

### 示例 4：用户要求“看下为什么数据库变慢”

Agent 应：

1. 路由到 monitoring 模块
2. 先看活动会话和锁
3. 再看累计统计
4. 如果涉及 `pg_stat_statements` 但不确定，查 Context7
5. 必要时再进入 logging 模块
6. 明确区分当前活动、累计统计、日志文件

------

## 14. 开发建议

实现这个 Skill 时，不要一开始就追求“大而全”。
建议路线：

### 第一阶段

先完成：

- `skill.md`
- `rules/`
- `01-connection.md`
- `07-metadata.md`
- `05-role-privilege.md`
- `09-monitoring.md`

### 第二阶段

再补：

- database admin
- schema/table
- index
- logging
- troubleshooting

### 第三阶段

再补：

- tablespace
- sample data
- 更多模板文件

这样更容易验证整个设计是否有效。

------

## 15. 对 Codex 的实现要求

如果由 Codex 实现本 Skill，建议遵守以下要求：

1. 不要复制 PostgreSQL 官方文档全文
2. 只写操作手册型内容
3. 每个模块必须包含：
   - 模块目标
   - 典型任务
   - 标准流程
   - 最小模板
   - Context7 调用指引
   - 风险规则
4. 所有高风险动作都必须写确认要求
5. 所有变更动作都必须写验证步骤
6. 所有复杂语法都尽量路由到 Context7，而不是在 Skill 内展开成长篇细节

------

## 16. 总结

这个 Skill 的真正价值，不是“知道多少 PostgreSQL 知识”，而是让 Agent 形成一种稳定、可靠、可控的工作方式：

- 先分类
- 先探查
- 需要时查官方文档
- 高风险动作先确认
- 执行后做验证
- 输出清晰结论

它应该像一个谨慎的 PostgreSQL 操作员，而不是一个随意猜测 SQL 的脚本生成器。

如果设计得当，这个 Skill 可以成为：

- PostgreSQL Agent 的统一操作脑
- Skill 与 Context7 协同的标准样板
- 后续扩展到 MySQL / Neo4j / SQL Server Skill 的模板

```
如果你愿意，我下一步可以继续把 `rules/context7-routing.md` 写成正式版。
```