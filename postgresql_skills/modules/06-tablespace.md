# 06 - 表空间管理

## 模块目标

处理 tablespace 相关任务：创建、查看、对象迁移。

---

## 典型任务

- 判断是否需要 tablespace
- 创建 tablespace
- 查看 tablespace 列表与大小
- 给表或索引指定 tablespace
- 迁移表或索引到其他 tablespace

---

## 标准流程

1. 确认用户是否明确要求 tablespace 操作（默认不主动使用）
2. 提醒 tablespace 涉及文件系统路径和 OS 权限
3. 查看当前 tablespace 列表
4. 如语法或风险不确定，调用 Context7
5. 请求确认后执行
6. 回查验证

---

## 最小模板

```sql
-- 列出 tablespace
SELECT spcname, pg_catalog.pg_get_userbyid(spcowner) AS owner,
       pg_size_pretty(pg_tablespace_size(spcname)) AS size
FROM pg_tablespace
ORDER BY spcname;

-- 创建 tablespace（需要超级用户权限）
CREATE TABLESPACE fast_ssd LOCATION '/data/fast_ssd';

-- 创建表时指定 tablespace
CREATE TABLE myschema.mytable (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY
) TABLESPACE fast_ssd;

-- 迁移表到其他 tablespace
ALTER TABLE myschema.mytable SET TABLESPACE fast_ssd;

-- 迁移索引到其他 tablespace
ALTER INDEX myschema.idx_name SET TABLESPACE fast_ssd;
```

---

## Context7 调用指引

当以下情况发生时调用 Context7：

- CREATE TABLESPACE 语法和权限要求
- tablespace 与数据库 / 表 / 索引的关联关系
- SET TABLESPACE 的行为和影响（锁、数据移动）
- 默认 tablespace 的设置方式

### 推荐查询

- `PostgreSQL CREATE TABLESPACE`
- `PostgreSQL ALTER TABLE SET TABLESPACE`
- `PostgreSQL ALTER INDEX SET TABLESPACE`
- `PostgreSQL pg_tablespace_size`
- `PostgreSQL default_tablespace`

---

## 风险规则

- **所有 tablespace 操作默认视为高风险**
- CREATE TABLESPACE 需要超级用户权限和文件系统路径权限
- SET TABLESPACE 会移动数据文件，可能需要表锁，可能耗时较长
- 不要主动建议使用 tablespace，除非用户明确要求
- 执行前必须提醒涉及的文件系统层面影响
