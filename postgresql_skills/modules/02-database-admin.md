# 02 - 数据库创建与管理

## 模块目标

处理数据库级管理任务：列出、创建、删除数据库，修改属性。

---

## 典型任务

- 列出所有数据库
- 创建数据库
- 删除数据库
- 修改数据库 owner
- 查看数据库大小
- 查看数据库级权限

---

## 标准流程

1. 查看现有数据库列表
2. 检查目标数据库是否已存在
3. 如需创建，明确 owner / encoding / locale / template
4. 如参数不确定，调用 Context7
5. 请求确认后执行
6. 回查数据库列表验证结果

---

## 最小模板

```sql
-- 列出所有数据库
SELECT datname, pg_catalog.pg_get_userbyid(datdba) AS owner,
       pg_encoding_to_char(encoding) AS encoding
FROM pg_database
ORDER BY datname;

-- 查看数据库大小
SELECT datname, pg_size_pretty(pg_database_size(datname)) AS size
FROM pg_database
ORDER BY pg_database_size(datname) DESC;

-- 创建数据库（示例）
CREATE DATABASE mydb OWNER myuser ENCODING 'UTF8';

-- 修改数据库 owner
ALTER DATABASE mydb OWNER TO newowner;

-- 删除数据库
DROP DATABASE mydb;
```

---

## Context7 调用指引

当以下情况发生时调用 Context7：

- 不确定 CREATE DATABASE 的可选参数（locale, template, tablespace 等）
- 不确定 ALTER DATABASE 的可用选项
- 不确定 DROP DATABASE 的行为限制（如活动连接）
- 需要了解 encoding / locale 的兼容性

### 推荐查询

- `PostgreSQL CREATE DATABASE`
- `PostgreSQL ALTER DATABASE`
- `PostgreSQL DROP DATABASE`
- `PostgreSQL pg_database_size`

---

## 风险规则

- **CREATE DATABASE**：需要确认 owner、encoding、template
- **DROP DATABASE**：高风险，必须确认，且需确认无活动连接
- **ALTER DATABASE OWNER**：需要确认新 owner
- 列出数据库和查看大小为只读操作，可直接执行
