# 08 - 样本数据生成

## 模块目标

生成演示数据、测试数据、样本数据，用于开发和测试。

---

## 典型任务

- 插入少量演示数据
- 使用 `generate_series()` 批量造数
- 生成时间序列数据
- 生成主外键关联样本
- 生成订单、用户、日志等测试数据
- 生成随机数据

---

## 标准流程

1. 确认目标表（schema、表名）
2. **默认写入测试 schema（如 `test_data`），禁止默认写入 `public`**。只有用户显式指定 schema 时才写入该 schema
3. 检查目标 schema 是否存在。如不存在，将 `CREATE SCHEMA` 作为**单独的前置步骤**，向用户说明并确认后执行（CREATE SCHEMA 是 DDL，受全局确认规则约束）
4. 检查目标表是否存在。如不存在，同样单独确认后创建
5. 确认数量级（几行 / 几百行 / 几千行 / 更多），适用数量级熔断规则
6. 如生成函数或表达式不确定，调用 Context7
7. 请求确认后执行 INSERT
8. 回查行数和样本数据

---

## 最小模板

```sql
-- 前置（单独确认后执行，不要与 INSERT 合并）：
-- CREATE SCHEMA IF NOT EXISTS test_data;

-- 简单插入（以下假设 test_data schema 和目标表已存在）
INSERT INTO test_data.users (name, email, created_at) VALUES
('Alice', 'alice@example.com', now()),
('Bob', 'bob@example.com', now()),
('Charlie', 'charlie@example.com', now());

-- 使用 generate_series 批量生成
INSERT INTO test_data.users (name, email, created_at)
SELECT
    'user_' || i,
    'user_' || i || '@example.com',
    now() - (random() * interval '365 days')
FROM generate_series(1, 1000) AS s(i);

-- 时间序列数据
INSERT INTO test_data.metrics (ts, value)
SELECT
    ts,
    round((random() * 100)::numeric, 2)
FROM generate_series(
    now() - interval '30 days',
    now(),
    interval '1 hour'
) AS s(ts);

-- 主外键关联样本
INSERT INTO test_data.orders (user_id, amount, created_at)
SELECT
    (random() * 99 + 1)::int,
    round((random() * 1000)::numeric, 2),
    now() - (random() * interval '90 days')
FROM generate_series(1, 500) AS s(i);

-- 回查行数
SELECT count(*) FROM test_data.users;

-- 回查样本
SELECT * FROM test_data.users LIMIT 5;
```

---

## Context7 调用指引

当以下情况发生时调用 Context7：

- `generate_series()` 的参数和用法不确定
- `random()` 的行为或替代函数
- 日期 / 时间生成表达式
- INSERT ... SELECT 模式
- 批量插入的性能注意事项

### 推荐查询

- `PostgreSQL generate_series`
- `PostgreSQL random()`
- `PostgreSQL INSERT SELECT`
- `PostgreSQL date time generation`

---

## 风险规则

- **样本数据生成是写入操作，需要确认**
- 默认写入测试 schema 或用户指定的目标
- 不得向疑似生产表随意写入样本数据
- 插入前提醒目标表和预计行数
- 插入后回查行数验证

### 数量级熔断规则

根据插入行数，执行不同级别的检查：

| 数量级 | 要求 |
|--------|------|
| < 10,000 行 | 常规确认：目标表、预计行数 |
| 10,000 ~ 100,000 行 | 增强确认：提醒磁盘写入量级，建议分批插入 |
| > 100,000 行 | **强制熔断**：必须在执行前完成以下全部步骤 |

**超过 100,000 行的强制熔断步骤**：

1. **查 Context7**：检索 `PostgreSQL bulk insert performance` 获取批量写入最佳实践
2. **评估磁盘影响**：提醒用户大事务会产生大量 WAL，可能导致：
   - WAL 磁盘空间急剧增长
   - checkpoint 压力增大
   - 复制延迟（如有备库）
   - 长事务阻塞 autovacuum
3. **建议分批执行**：将大插入拆分为多个小事务（如每批 10,000 行），避免单事务持有过多资源
4. **检查可用空间**：
   ```sql
   -- 检查数据库当前大小
   SELECT pg_size_pretty(pg_database_size(current_database()));
   -- 检查表空间可用情况（需要 OS 层面 df 命令辅助）
   ```
5. **明确告知用户预计影响**后，等待确认

分批插入示例（客户端侧分批，每批独立事务）：

```bash
#!/usr/bin/env bash
set -euo pipefail

# 分批插入 100 万行，每批 10,000 行，每批是独立事务
# set -e 确保任何一批失败后立即停止，不会继续写入后续批次
for batch in $(seq 0 99); do
  psql -X -v ON_ERROR_STOP=1 -Atqc "
    INSERT INTO test_data.large_table (id, value)
    SELECT ${batch} * 10000 + i, random()
    FROM generate_series(1, 10000) AS s(i);
  "
  echo "Batch ${batch}/99 complete"
done
echo "All batches complete"
```

**注意**：不要用 `DO $$ LOOP ... END $$` 做分批——PL/pgSQL 的 DO 块是单事务执行，内部 LOOP 不会在每次迭代之间提交，效果等同于一次性插入全部数据。真正的分批必须在客户端侧循环，让每次 `psql -c` 调用形成独立事务。
