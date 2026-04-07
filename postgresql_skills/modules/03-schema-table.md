# 03 - Schema / Table / Constraint 管理

## 模块目标

处理 schema、table、column、constraint 的创建、修改和删除。

---

## 典型任务

- 创建 / 删除 schema
- 创建表（含字段、类型、约束）
- 修改表结构（增删列、改类型）
- 添加主键、外键、唯一约束、检查约束
- 添加注释（COMMENT）
- 使用 identity / generated 列
- 创建分区表

---

## 标准流程

1. 检查目标 schema 是否存在
2. 检查目标 table 是否存在
3. 明确字段定义与约束
4. 如涉及复杂语法（分区、generated 列等），调用 Context7
5. 请求确认后执行
6. 通过元数据查询回查（转 `07-metadata.md`）

---

## 最小模板

```sql
-- 创建 schema
CREATE SCHEMA IF NOT EXISTS myschema;

-- 创建表
CREATE TABLE myschema.mytable (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 添加列
ALTER TABLE myschema.mytable ADD COLUMN email TEXT;

-- 添加约束
ALTER TABLE myschema.mytable ADD CONSTRAINT uq_email UNIQUE (email);

-- 添加注释
COMMENT ON TABLE myschema.mytable IS '用户主表';
COMMENT ON COLUMN myschema.mytable.name IS '用户名称';

-- 删除表
DROP TABLE IF EXISTS myschema.mytable;
```

---

## Context7 调用指引

当以下情况发生时调用 Context7：

- 复杂 CREATE TABLE 语法（分区表、继承表）
- generated columns 语法
- ALTER TABLE 的各类变更影响不确定
- CHECK constraint 表达式语法
- FOREIGN KEY 的 ON DELETE / ON UPDATE 行为
- 数据类型选择不确定

### 推荐查询

- `PostgreSQL CREATE TABLE`
- `PostgreSQL ALTER TABLE`
- `PostgreSQL CHECK constraint`
- `PostgreSQL FOREIGN KEY`
- `PostgreSQL generated columns`
- `PostgreSQL partitioning`
- `PostgreSQL data types`

---

## 风险规则

- **CREATE TABLE**：需要确认结构设计
- **ALTER TABLE**：可能导致表锁、数据重写，需要确认
- **DROP TABLE**：高风险，必须确认
- **DROP SCHEMA CASCADE**：极高风险，必须确认且说明影响范围
- 约束变更可能影响应用写入，需要提醒
