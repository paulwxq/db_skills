-- ============================================
-- 样本数据生成模板
-- ============================================
--
-- 默认目标 schema：test_data
-- 规则：样本数据必须写入测试 schema 或用户显式指定的目标，禁止默认写入 public
--
-- 前置条件（必须在执行本模板前单独确认并完成）：
--   1. 目标 schema 已存在（如不存在，需单独确认后执行 CREATE SCHEMA IF NOT EXISTS test_data;）
--   2. 目标表已创建
-- 本模板不包含 DDL，仅包含 INSERT 语句。

-- ----------------------------------------
-- 简单插入
-- ----------------------------------------
INSERT INTO test_data.users (name, email, created_at) VALUES
('Alice', 'alice@example.com', now()),
('Bob', 'bob@example.com', now()),
('Charlie', 'charlie@example.com', now());

-- ----------------------------------------
-- 使用 generate_series 批量生成用户
-- ----------------------------------------
INSERT INTO test_data.users (name, email, created_at)
SELECT
    'user_' || i,
    'user_' || i || '@example.com',
    now() - (random() * interval '365 days')
FROM generate_series(1, 1000) AS s(i);

-- ----------------------------------------
-- 时间序列数据（每小时一条，30天）
-- ----------------------------------------
INSERT INTO test_data.metrics (ts, value)
SELECT
    ts,
    round((random() * 100)::numeric, 2)
FROM generate_series(
    now() - interval '30 days',
    now(),
    interval '1 hour'
) AS s(ts);

-- ----------------------------------------
-- 带状态的订单数据
-- ----------------------------------------
INSERT INTO test_data.orders (user_id, amount, status, created_at)
SELECT
    (random() * 99 + 1)::int AS user_id,
    round((random() * 1000)::numeric, 2) AS amount,
    (ARRAY['pending', 'completed', 'cancelled'])[floor(random() * 3 + 1)::int] AS status,
    now() - (random() * interval '90 days')
FROM generate_series(1, 500) AS s(i);

-- ----------------------------------------
-- 带分类的产品数据
-- ----------------------------------------
INSERT INTO test_data.products (name, category, price, created_at)
SELECT
    'product_' || i,
    (ARRAY['electronics', 'books', 'clothing', 'food', 'toys'])[floor(random() * 5 + 1)::int],
    round((random() * 500 + 1)::numeric, 2),
    now() - (random() * interval '180 days')
FROM generate_series(1, 200) AS s(i);

-- ----------------------------------------
-- 验证插入结果
-- ----------------------------------------

-- 查看行数
SELECT count(*) FROM test_data.users;

-- 查看样本
SELECT * FROM test_data.users ORDER BY created_at DESC LIMIT 5;
