# Context7 Routing Rules

## 1. 调用 Context7 的触发条件

当以下任一情况发生时，Agent 必须先调用 Context7 查询官方文档：

1. SQL 语法不确定
2. PostgreSQL 参数含义不确定
3. 系统视图字段含义不确定
4. 角色 / 权限继承机制不确定
5. 日志参数作用不确定
6. 高级特性行为不确定（如 partition、tablespace、concurrent index）
7. 不同 PostgreSQL 版本之间可能存在差异
8. Skill 模块中只有提纲，没有详细解释

---

## 2. Query 书写建议

查询时遵守以下原则：

- **查询要具体**：不要问"PostgreSQL 权限"，要问"PostgreSQL GRANT SELECT ON TABLE"
- **尽量带版本**：如 `PostgreSQL 17 CREATE ROLE`
- **一次只问一个概念**：不要把多个问题合并为一条查询
- **优先查官方文档主题**：优先使用 PostgreSQL 官方文档术语
- **高风险动作先查语法，再执行**

### 推荐查询示例

```
PostgreSQL CREATE DATABASE
PostgreSQL ALTER DATABASE
PostgreSQL DROP DATABASE
PostgreSQL CREATE TABLE
PostgreSQL ALTER TABLE
PostgreSQL CREATE INDEX
PostgreSQL CREATE INDEX CONCURRENTLY
PostgreSQL CREATE ROLE
PostgreSQL ALTER ROLE
PostgreSQL GRANT
PostgreSQL REVOKE
PostgreSQL ALTER DEFAULT PRIVILEGES
PostgreSQL CREATE TABLESPACE
PostgreSQL pg_stat_activity columns
PostgreSQL pg_locks
PostgreSQL pg_stat_statements
PostgreSQL logging_collector
PostgreSQL log_destination
PostgreSQL log_directory
PostgreSQL log_filename
PostgreSQL information_schema columns
PostgreSQL partitioning
PostgreSQL generated columns
PostgreSQL role inheritance
PostgreSQL predefined roles
```

---

## 3. Context7 结果使用原则

- 优先使用官方文档结果
- 只提取本次任务所需片段
- 不将整篇文档复制进输出
- 如果结果不够明确，缩小问题范围再次查询
- 总结关键信息供用户参考，不做大段文档转储

---

## 4. 各模块常见 Context7 查询主题

### 连接

- PostgreSQL psql options
- PostgreSQL connection parameters
- PostgreSQL SSL connection

### 数据库管理

- PostgreSQL CREATE DATABASE
- PostgreSQL ALTER DATABASE
- PostgreSQL DROP DATABASE
- PostgreSQL pg_database_size

### Schema / Table / Constraint

- PostgreSQL CREATE SCHEMA
- PostgreSQL CREATE TABLE
- PostgreSQL ALTER TABLE
- PostgreSQL CHECK constraint
- PostgreSQL FOREIGN KEY
- PostgreSQL generated columns
- PostgreSQL partitioning

### 索引

- PostgreSQL CREATE INDEX
- PostgreSQL partial index
- PostgreSQL expression index
- PostgreSQL concurrent index creation

### 角色与权限

- PostgreSQL CREATE ROLE
- PostgreSQL GRANT
- PostgreSQL REVOKE
- PostgreSQL ALTER DEFAULT PRIVILEGES
- PostgreSQL predefined roles
- PostgreSQL role inheritance

### 表空间

- PostgreSQL CREATE TABLESPACE
- PostgreSQL ALTER TABLE SET TABLESPACE
- PostgreSQL pg_tablespace_size

### 元数据

- PostgreSQL information_schema
- PostgreSQL pg_catalog
- PostgreSQL pg_class
- PostgreSQL pg_constraint
- PostgreSQL pg_depend

### 样本数据

- PostgreSQL generate_series
- PostgreSQL random()
- PostgreSQL INSERT SELECT patterns

### 监控

- PostgreSQL pg_stat_activity
- PostgreSQL pg_locks
- PostgreSQL pg_stat_database
- PostgreSQL pg_stat_user_tables
- PostgreSQL pg_stat_statements

### 日志

- PostgreSQL logging_collector
- PostgreSQL log_destination
- PostgreSQL log_directory
- PostgreSQL log_filename
- PostgreSQL csvlog

---

## 5. 不应使用 Context7 的情况

- 纯本地操作问题（如 shell 命令、文件权限）
- 已在 Skill 模板中完整提供的简单 SQL
- 用户已明确给出完整语法
- 不涉及 PostgreSQL 特定语义的通用编程问题
