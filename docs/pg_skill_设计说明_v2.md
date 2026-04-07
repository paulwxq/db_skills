下面是可直接交给 Codex 的完整初稿。

------

# PostgreSQL 百科型 Skill + Context7 协同设计文档

## 1. 文档目的

本文档用于指导实现一个面向 Agent 的 **PostgreSQL 百科型 Skill**。

这个 Skill 的目标不是把 PostgreSQL 官方文档全部搬进来，而是把它设计成一个：

- 提纲型知识入口
- 操作流程手册
- 风险控制规则集
- Context7 文档调用指引
- `psql` 执行规范集合

最终效果是：

- Agent 能在本地使用 `psql` 执行 PostgreSQL 相关操作
- Agent 能根据 Skill 判断当前任务属于哪一类
- Agent 遇到具体语法、参数、系统视图等细节问题时，自动调用 Context7 获取官方文档
- Skill 本身保持轻量、稳定、可维护

------

# 2. 总体设计思想

## 2.1 核心思路

Skill 不负责存储全部知识，Skill 负责：

1. 定义任务分类
2. 定义执行步骤
3. 提供最小模板
4. 约束危险动作
5. 指导何时调用 Context7
6. 指导如何用 `psql` 执行任务

Context7 负责：

1. 提供 PostgreSQL 官方文档级知识
2. 提供语法说明
3. 提供参数说明
4. 提供系统视图说明
5. 提供版本差异说明
6. 提供高级特性说明

`psql` 负责：

1. 执行 SQL
2. 执行元命令
3. 输出结果
4. 配合 shell 查看日志文件

------

## 2.2 为什么这样设计

因为如果把所有知识都写进 Skill，会有几个问题：

- 内容过于庞大
- 维护成本很高
- 版本升级后容易过时
- Agent 难以区分“操作规则”和“背景知识”
- Skill 会变成文档仓库，而不是操作手册

因此更合理的方式是：

- Skill = 目录、方法论、SOP、最小模板
- Context7 = 文档后援
- `psql` = 执行器

------

## 2.3 设计目标

这个 Skill 需要支持以下几类任务：

1. 数据库连接与探查
2. 数据库创建与管理
3. Schema / Table / Constraint 管理
4. Index 管理
5. Role / User / Privilege 管理
6. Tablespace 管理
7. Metadata 探查
8. Sample Data 生成
9. Monitoring / Sessions / Locks / Performance
10. Logging / Troubleshooting

------

# 3. 目标用户与使用场景

## 3.1 目标用户

- 需要让 Agent 辅助操作 PostgreSQL 的开发者
- 希望通过 Agent 完成数据库管理、探查、分析的人
- 希望减少重复查询文档的人
- 希望用 Skill + Context7 替代“全文档硬编码”的工程实践者

## 3.2 典型使用场景

### 场景 1：查询元数据

用户问：

- 某个 schema 下有哪些表
- 某个表有哪些字段
- 某个表的主键、外键、索引是什么

### 场景 2：创建数据库对象

用户要求：

- 创建数据库
- 创建 schema
- 创建表
- 创建索引
- 创建角色与授权

### 场景 3：性能与监控分析

用户要求：

- 查看当前活动会话
- 查看锁等待
- 查看慢 SQL
- 查看统计信息

### 场景 4：日志与排障

用户要求：

- 查看日志配置
- 查找日志文件
- 分析连接失败
- 分析权限问题
- 分析对象不存在问题

------

# 4. 整体架构

## 4.1 分层架构

```text
User
  ↓
Agent
  ↓
PostgreSQL Skill
  ├─ 执行规则
  ├─ 风险规则
  ├─ Context7 调用规则
  └─ 最小模板
  ↓
├─ Context7 MCP（查官方文档）
└─ psql / shell（执行操作）
```

------

## 4.2 各层职责

### Agent

负责：

- 接收用户请求
- 识别任务类型
- 读取 Skill 规则
- 决定先探查还是先执行
- 决定是否调用 Context7
- 调用 `psql` / shell

### Skill

负责：

- 定义标准流程
- 提供模块索引
- 定义最小模板
- 定义安全规则
- 定义 Context7 查询提示

### Context7

负责：

- 提供 PostgreSQL 官方文档内容
- 补足语法、参数、系统视图等细节

### psql / shell

负责：

- 真正执行 SQL
- 执行 shell 命令
- 查看日志文件
- 输出执行结果

------

# 5. 对 Skill 的总体要求

## 5.1 Skill 的定位

Skill 应被设计为：

- 轻量
- 模块化
- 可扩展
- 可维护
- 可被 Agent 稳定遵循

而不是：

- PostgreSQL 文档全集
- 大量知识堆砌
- 纯 SQL 样例仓库
- 只告诉命令、不告诉流程

------

## 5.2 Skill 的原则

### 原则 1：先分类再执行

Agent 必须先判断任务属于哪个模块。

### 原则 2：先探查再变更

对变更型操作，默认先检查现状。

### 原则 3：先查提纲，细节再查 Context7

Skill 提供路径，Context7 提供细节。

### 原则 4：高风险动作必须确认

删除、授权、改默认权限、表空间迁移等都必须确认。

### 原则 5：结果必须回查

执行变更后必须验证结果。

------

# 6. 建议的 Skill 目录结构

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

# 7. skill.md 总纲初稿

下面是建议直接写入 `skill.md` 的内容骨架。

------

## 7.1 Skill 名称

**PostgreSQL Encyclopedia Skill**

------

## 7.2 Skill 目标

本 Skill 用于指导 Agent 使用本地 `psql` 和 shell 工具完成 PostgreSQL 的查询、探查、管理、监控、排障等任务。

本 Skill 不复制 PostgreSQL 全部官方文档，只提供：

- 操作提纲
- 执行流程
- 最小模板
- 风险规则
- Context7 查询指引

对于复杂语法、版本差异、系统视图字段、参数说明、高级特性说明，应优先通过 Context7 查询官方文档。

------

## 7.3 Skill 适用范围

本 Skill 适用于以下任务：

- PostgreSQL 连接与连通性检查
- 数据库与 schema 管理
- 数据表、约束、索引管理
- 用户、角色、权限管理
- 表空间管理
- 元数据探查
- 样本数据生成
- 监控、锁、活动会话分析
- 日志定位与排障

------

## 7.4 Skill 默认执行原则

1. 默认先识别任务类型，再进入对应模块
2. 默认先探查现状，再执行变更
3. 默认优先使用最小权限原则
4. 默认不把密码打印到输出中
5. 默认通过环境变量连接 PostgreSQL
6. 默认使用 `psql -X`
7. 遇到不确定的 SQL 语法、参数、系统视图定义、高级特性时，优先调用 Context7
8. 对高风险动作必须先明确影响范围，再请求确认
9. 所有变更动作执行后都必须回查验证

------

## 7.5 连接约定

默认使用以下环境变量：

- `PGHOST`
- `PGPORT`
- `PGDATABASE`
- `PGUSER`
- `PGPASSWORD`

默认连接测试命令示例：

```bash
psql -X -Atqc "select current_database(), current_user;"
```

------

## 7.6 模块路由

当用户请求属于以下类型时，按对应模块处理：

- 连接问题 → `01-connection.md`
- 建库删库 → `02-database-admin.md`
- 建 schema / 建表 / 约束 → `03-schema-table.md`
- 索引 → `04-index.md`
- 用户 / 权限 → `05-role-privilege.md`
- 表空间 → `06-tablespace.md`
- 元数据 / 表结构 → `07-metadata.md`
- 测试数据 / 样本数据 → `08-sample-data.md`
- 性能 / 会话 / 锁 → `09-monitoring.md`
- 日志 / 日志参数 → `10-logging.md`
- 故障排查 → `11-troubleshooting.md`

------

## 7.7 Context7 使用规则

当出现下列情况时，Agent 必须调用 Context7：

1. 需要精确 SQL 语法
2. 需要理解 PostgreSQL 某个系统视图字段
3. 需要确认版本差异
4. 需要确认日志、监控、角色、权限相关参数或语义
5. 需要确认高级特性行为，例如：
   - partition
   - tablespace
   - alter default privileges
   - concurrent index creation
   - pg_stat_statements
6. Skill 中只有提纲，没有详细解释

------

## 7.8 高风险动作确认规则

以下动作默认必须确认：

- create database
- drop database
- create schema
- drop schema
- create table
- drop table
- create index
- drop index
- create role
- alter role
- drop role
- grant
- revoke
- alter default privileges
- create tablespace
- alter table set tablespace
- 大规模样本数据写入

------

# 8. rules 目录内容设计

------

## 8.1 safety-rules.md 初稿

### 默认允许直接执行的动作

- 连接测试
- 查看版本
- 查看 schema
- 查看表结构
- 查看元数据
- 查看活动会话
- 查看日志参数
- 查看样本数据（有限行数）

### 默认需要确认的动作

- 任何写操作
- 任何授权操作
- 任何删改操作
- 任何对象迁移
- 任何大批量插入
- 任何影响生产日志配置的建议

### 默认禁止直接执行的动作

- 无确认删除数据库
- 无确认删除表
- 无确认授权超级权限
- 无确认修改默认权限
- 无确认进行表空间迁移
- 无确认在疑似生产环境执行 destructive 操作

### 样本数据规则

- 默认写入测试 schema 或显式指定的目标
- 默认先确认目标表
- 默认要求控制数量级

------

## 8.2 context7-routing.md 初稿

### Context7 触发条件

当以下任一情况发生时，必须先查 Context7：

1. SQL 语法不确定
2. 参数含义不确定
3. 系统视图字段不确定
4. 角色权限继承机制不确定
5. 日志参数作用不确定
6. 高级特性行为不确定
7. 不同 PostgreSQL 版本之间可能存在差异

### Query 书写建议

尽量使用以下形式：

- `PostgreSQL CREATE ROLE current version`
- `PostgreSQL ALTER DEFAULT PRIVILEGES`
- `PostgreSQL pg_stat_activity columns`
- `PostgreSQL logging_collector`
- `PostgreSQL CREATE TABLESPACE`
- `PostgreSQL concurrent create index`

### Context7 结果使用原则

- 优先使用官方文档结果
- 只提取本次任务所需片段
- 不复制整篇文档到 Skill
- 如果结果不够明确，应继续缩小问题范围再查

------

## 8.3 execution-conventions.md 初稿

### 执行前规则

- 先分类任务
- 先判断是否为高风险动作
- 先检查对象是否存在
- 先决定是否需要查 Context7

### 执行时规则

- 统一使用 `psql -X`
- 默认避免打印敏感信息
- 输出尽量结构化、简洁
- 如是变更操作，应先给出执行计划

### 执行后规则

- 必须回查结果
- 必须说明执行成功或失败
- 若失败，应归类到排障模块

------

# 9. modules 目录设计

下面给出每个模块建议内容。

------

## 9.1 01-connection.md

### 模块目标

处理连接、环境准备、版本确认、连通性验证。

### 典型任务

- 检查 `psql` 是否安装
- 检查环境变量是否可用
- 验证数据库连接
- 查看当前库和当前用户
- 查看 PostgreSQL 版本

### 标准流程

1. 检查 `psql` 是否存在
2. 检查环境变量
3. 执行最小连接测试
4. 如连接失败，进入 troubleshooting

### 最小模板

```bash
which psql
psql --version
psql -X -Atqc "select current_database(), current_user;"
psql -X -Atqc "select version();"
```

### Context7 调用指引

当以下情况发生时调用：

- 不确定 `psql` 参数含义
- 不确定连接参数配置方式
- 不确定版本特性差异

------

## 9.2 02-database-admin.md

### 模块目标

处理数据库级管理任务。

### 典型任务

- 列出数据库
- 创建数据库
- 删除数据库
- 修改 owner
- 查看数据库大小

### 标准流程

1. 查看现有数据库
2. 检查目标数据库是否存在
3. 如需创建，明确 owner / encoding / template
4. 如语法不确定，调用 Context7
5. 执行后回查

### 最小模板

```sql
select datname from pg_database order by datname;
```

### Context7 调用指引

- create database 语法
- alter database 选项
- drop database 行为
- encoding / locale / template 说明

------

## 9.3 03-schema-table.md

### 模块目标

处理 schema、table、column、constraint 相关任务。

### 典型任务

- 创建 schema
- 创建表
- 修改表
- 删除表
- 增加约束
- 增加注释
- identity / generated 列

### 标准流程

1. 先查 schema / table 是否存在
2. 生成 DDL
3. 若复杂约束语法不确定，调用 Context7
4. 执行
5. 通过 metadata 模块回查

### Context7 调用指引

- create schema
- create table
- alter table
- check constraint
- foreign key
- generated columns
- partitioning

------

## 9.4 04-index.md

### 模块目标

处理索引相关任务。

### 典型任务

- 创建普通索引
- 创建唯一索引
- 创建复合索引
- 创建表达式索引
- 创建部分索引
- 查看索引定义
- 分析索引使用情况

### 标准流程

1. 明确查询模式
2. 判断索引类型
3. 如索引语法或行为不确定，调用 Context7
4. 创建索引
5. 回查定义
6. 后续结合 monitoring 模块观察使用情况

### Context7 调用指引

- create index
- concurrent index creation
- partial index
- expression index
- multicolumn index

------

## 9.5 05-role-privilege.md

### 模块目标

处理角色、用户、权限管理。

### 典型任务

- 创建登录角色
- 创建业务角色
- grant connect
- grant usage
- grant select / insert / update / delete
- revoke
- alter default privileges
- 查询现有角色与权限

### 标准流程

1. 先明确目标是“登录角色”还是“权限角色”
2. 查询角色是否已存在
3. 如权限语义不确定，调用 Context7
4. 执行 create role / grant / revoke
5. 回查角色和权限

### Context7 调用指引

- create role
- alter role
- grant
- revoke
- role inheritance
- alter default privileges
- predefined roles

------

## 9.6 06-tablespace.md

### 模块目标

处理 tablespace 相关任务。

### 典型任务

- 判断是否需要 tablespace
- 创建 tablespace
- 给表或索引指定 tablespace
- 查看 tablespace 使用情况

### 标准流程

1. 先判断用户是否明确要求 tablespace
2. 提示其涉及文件系统路径与权限
3. 如语法或风险不确定，调用 Context7
4. 执行
5. 回查

### 风险提示

tablespace 相关操作默认视为高风险。

### Context7 调用指引

- create tablespace
- alter table set tablespace
- alter index set tablespace
- tablespace size and ownership

------

## 9.7 07-metadata.md

### 模块目标

处理元数据探查任务。

### 典型任务

- 列出 schema
- 列出表
- 查询列定义
- 查询主键、外键
- 查询索引
- 查询注释
- 查询表大小
- 查询对象依赖

### 标准流程

1. 先列出 schema
2. 再定位对象
3. 再看字段与约束
4. 再看索引与大小
5. 如用户还需要数据样本，转 sample-data 模块

### 最小模板

可放少量通用 `information_schema` 查询模板。

### Context7 调用指引

- information_schema columns
- pg_catalog tables
- constraint catalogs
- relation size
- dependency catalogs

------

## 9.8 08-sample-data.md

### 模块目标

生成演示数据、测试数据、样本数据。

### 典型任务

- 插入少量演示数据
- 使用 `generate_series()` 批量造数
- 生成时间序列数据
- 生成主外键关联样本
- 生成订单、用户、日志等测试数据

### 标准流程

1. 确认目标表
2. 确认数量级
3. 默认建议用于测试 schema
4. 如表达式或函数不确定，调用 Context7
5. 插入后回查

### Context7 调用指引

- generate_series
- random
- insert select
- date/time generation patterns

------

## 9.9 09-monitoring.md

### 模块目标

处理会话、锁、统计、性能观察。

### 典型任务

- 查看活动会话
- 查看长事务
- 查看锁等待
- 查看数据库统计
- 查看表/索引统计
- 查看 `pg_stat_statements`

### 标准流程

1. 先看当前活动
2. 再看锁
3. 再看累计统计
4. 若需要慢 SQL 分析，再看扩展或日志

### Context7 调用指引

- pg_stat_activity
- pg_locks
- monitoring stats
- pg_stat_database
- pg_stat_user_tables
- pg_stat_statements

------

## 9.10 10-logging.md

### 模块目标

处理日志参数、日志位置、日志查看。

### 典型任务

- 查看日志配置
- 查看 log_directory
- 查看 log_filename
- 识别 logging collector 配置
- 用 shell 查日志文件
- 区分日志与统计视图

### 标准流程

1. 先查看日志参数
2. 再定位日志目录
3. 再决定是否查看文件
4. 若参数含义不清楚，调用 Context7

### Context7 调用指引

- logging_collector
- log_destination
- log_directory
- log_filename
- csvlog
- stderr logging

------

## 9.11 11-troubleshooting.md

### 模块目标

处理常见故障与排障。

### 典型问题

- psql 不存在
- 无法连接数据库
- 密码认证失败
- 权限不足
- 对象不存在
- 扩展未启用
- 看不到统计信息
- 找不到日志文件
- SQL 执行失败

### 标准结构

每个故障条目按以下格式写：

- 现象
- 常见原因
- 排查步骤
- 可能需要查的 Context7 主题

------

# 10. templates 目录建议

------

## connection.sql

放连接校验 SQL。

## metadata.sql

放 schema、table、column、constraint、index 查询模板。

## create-role.sql

放创建角色模板。

## privilege.sql

放授权模板。

## sample-data.sql

放 `generate_series()`、随机数据模板。

## monitoring.sql

放 `pg_stat_activity`、`pg_locks` 等模板。

## logging.sql

放查看日志参数的 SQL 模板。

------

# 11. 给 Codex 的直接任务说明

下面这段可以直接发给 Codex。

------

## 实现任务

请实现一个 PostgreSQL Encyclopedia Skill，要求如下：

### 目标

实现一个面向 Agent 的 Skill，用于指导 Agent 使用本地 `psql` 执行 PostgreSQL 相关任务，并在需要时调用 Context7 获取官方文档。

### 设计要求

1. Skill 不复制 PostgreSQL 全部官方文档
2. Skill 只提供：
   - 模块提纲
   - 执行流程
   - 最小模板
   - 安全规则
   - Context7 路由规则
3. 所有复杂语法和高级特性，都通过 Context7 动态补充
4. 所有高风险动作必须要求确认
5. 所有变更动作都必须回查验证

### 文件要求

请创建如下目录与文件：

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

### 模块写作规范

每个 `modules/*.md` 文件必须包含：

1. 模块目标
2. 典型任务
3. 标准流程
4. 最小模板
5. Context7 调用指引
6. 风险规则

### 风格要求

- 用中文写
- 风格偏操作手册
- 不要写成长篇教科书
- 不要复制官方文档大段内容
- 只保留关键知识与行动指南

### 特别要求

请在 `skill.md` 中清楚写出：

- 什么时候调用 Context7
- 什么时候只允许探查不允许执行
- 什么时候必须确认
- 如何区分日志、统计视图、活动会话

------

# 12. 最后的建议

你的这个思路是对的，而且很工程化。

最关键的点有两个：

第一，**Skill 不要变成文档仓库**。
第二，**Context7 的调用条件一定要写得足够明确**。

否则 Agent 很容易出现两种问题：

- 要么什么都不查，直接猜
- 要么什么都查，效率很差

所以真正好的设计，不是“知识尽量多”，而是“流程清晰，调用边界清晰”。

