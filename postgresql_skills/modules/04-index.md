# 04 - 索引管理

## 模块目标

处理索引的创建、查看、删除和使用分析。

---

## 典型任务

- 创建普通索引
- 创建唯一索引
- 创建复合索引
- 创建表达式索引
- 创建部分索引（partial index）
- 并发创建索引（CONCURRENTLY）
- 查看索引定义
- 分析索引使用情况

---

## 标准流程

1. 理解查询模式和使用场景
2. 查看表上现有索引
3. 判断合适的索引类型
4. 如索引语法或行为不确定，调用 Context7
5. 请求确认后执行
6. 回查索引定义
7. 后续结合 `09-monitoring.md` 观察索引使用情况

---

## 最小模板

```sql
-- 查看表上的索引
SELECT indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'public' AND tablename = 'mytable';

-- 创建普通索引
CREATE INDEX idx_mytable_name ON public.mytable (name);

-- 创建唯一索引
CREATE UNIQUE INDEX idx_mytable_email ON public.mytable (email);

-- 创建复合索引
CREATE INDEX idx_mytable_name_created ON public.mytable (name, created_at);

-- 创建部分索引
CREATE INDEX idx_mytable_active ON public.mytable (status) WHERE status = 'active';

-- 并发创建索引（不阻塞写入）
CREATE INDEX CONCURRENTLY idx_mytable_name_conc ON public.mytable (name);

-- 删除索引
DROP INDEX IF EXISTS idx_mytable_name;

-- 查看索引使用统计
SELECT schemaname, relname, indexrelname, idx_scan, idx_tup_read, idx_tup_fetch
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY idx_scan DESC;
```

---

## Context7 调用指引

当以下情况发生时调用 Context7：

- 索引类型选择不确定（btree, hash, gin, gist, brin）
- 部分索引或表达式索引的语法
- CONCURRENTLY 的行为和限制
- 索引创建对锁和性能的影响
- 多列索引的列顺序选择

### 推荐查询

- `PostgreSQL CREATE INDEX`
- `PostgreSQL partial index`
- `PostgreSQL expression index`
- `PostgreSQL CREATE INDEX CONCURRENTLY`
- `PostgreSQL index types`

---

## 风险规则

- **CREATE INDEX**：可能锁表（非 CONCURRENTLY 模式），需要确认
- **CREATE INDEX CONCURRENTLY**：不阻塞写入，但有失败风险，需提醒
- **DROP INDEX**：需要确认
- 不必要的索引会影响写入性能，创建前应评估必要性
- 查看索引定义和统计为只读操作，可直接执行
