# Execution Conventions

## 1. 执行前规则

- 先分类任务，确定属于哪个模块
- 先判断是否为高风险动作
- 先检查目标对象是否存在
- 先决定是否需要查 Context7
- 对变更操作，先输出执行计划

---

## 2. psql 使用规范

### 基本约定

- 统一使用 `psql -X` 避免加载 `.psqlrc`
- 默认避免在命令中嵌入密码
- 优先通过环境变量连接

### 输出格式选择

| 场景 | 推荐格式 |
|------|----------|
| 机器解析 | `psql -X -Atqc` |
| 用户直接阅读 | `psql -X -c` |
| Tab 分隔输出 | `psql -X -F $'\t' -Atqc` |
| 扩展显示（单行详细） | `psql -X -xc` |

### 常用参数说明

- `-X`：不加载 `.psqlrc`
- `-A`：unaligned 输出
- `-t`：只输出行数据（无表头和行数统计）
- `-q`：quiet 模式
- `-c`：执行单条命令
- `-F`：字段分隔符

---

## 2.1 参数化查询：直接拼值 vs psql -v

### 默认方式：直接在 SQL 中写入具体值

Agent 日常执行时，优先使用**直接拼入具体值**的单条命令。这是最简单、最不容易出错的方式：

```bash
psql -X -Atqc "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';"
```

不需要变量替换时，不要引入 `-v`。

### 仅在以下场景使用 psql -v

- 执行 `templates/*.sql` 文件（这些文件设计为 `-v` 驱动）
- 同一条查询需要对多组参数重复执行
- 需要将参数从 shell 脚本传入 psql

### psql -v 正确写法

`psql -v` 设置的是 psql 内部变量，在 SQL 中通过 `:'varname'` 引用（展开为带引号的字符串字面量）。

**关键规则：shell 层传入的值必须自带 SQL 单引号。**

```bash
# 正确 — shell 双引号内包裹 SQL 单引号
psql -X -v schema_name="'public'" -v table_name="'users'" -f metadata.sql

# 正确 — 等效写法
psql -X -v schema_name=\'public\' -v table_name=\'users\' -f metadata.sql
```

SQL 文件中的引用方式：

```sql
-- :'schema_name' 会展开为 'public'（带引号的字符串字面量）
SELECT * FROM information_schema.tables WHERE table_schema = :'schema_name';
```

### 常见错误

```bash
# 错误 — 缺少内层单引号，psql 变量值为 public（无引号），SQL 报语法错
psql -X -v schema_name="public" -f metadata.sql

# 错误 — SQL 中用 :schema_name 而非 :'schema_name'，变量被当作标识符而非字符串
SELECT * FROM information_schema.tables WHERE table_schema = :schema_name;
```

### 标识符安全：format('%I', ...)

当 SQL 中需要动态引用对象名（schema、表名、列名）时，使用 `format()` 的 `%I` 占位符安全引用标识符。这能正确处理大小写敏感和含特殊字符的合法标识符：

```sql
-- 安全：自动为需要引号的标识符加双引号
format('%I.%I', 'public', 'MyTable')   -- 结果: public."MyTable"
format('%I.%I', 'public', 'users')     -- 结果: public.users（小写无需引号，不会画蛇添足）

-- 不安全：简单拼接，大小写敏感标识符会解析错误
'public' || '.' || 'MyTable'           -- 结果: public.MyTable（缺引号，会被解析为 public.mytable）
```

**规则：在构造包含动态对象名的 SQL 时（无论是否使用 `-v`），始终使用 `format('%I', ...)` 引用标识符部分。**

### 决策规则

| 场景 | 推荐方式 |
|------|----------|
| 单次执行、值已知 | 直接在 SQL 中写具体值 |
| 执行 templates/*.sql 文件 | 使用 `psql -v` |
| shell 脚本批量执行 | 使用 `psql -v` |
| 不确定引号规则时 | **不要用 `-v`，直接拼值** |
| 对象名可能大小写敏感或含特殊字符 | 使用 `format('%I', ...)` |

---

## 3. 执行时规则

- 变更操作应先给出执行计划
- 不在输出中打印敏感信息（密码、连接字符串中的密码）
- 输出尽量结构化、简洁
- 单步执行，不要一次提交多个不相关的变更

---

## 4. 执行后规则

- **必须回查结果**
  - 创建对象后，查询对象是否存在
  - 授权后，查询权限是否生效
  - 插入数据后，查看行数或样本
  - 修改参数后，查看当前值
- 必须说明执行成功或失败
- 若失败，应归类到排障模块（`11-troubleshooting.md`）

---

## 5. 变更操作的标准流程

```
1. 检查目标对象当前状态
2. 输出执行计划（做什么、影响什么）
3. 如为高风险动作，请求确认
4. 执行变更
5. 回查验证结果
6. 总结变更结果
```

---

## 6. 错误处理

- 捕获错误信息
- 分类错误类型
- 检查相关状态
- 判断是否需要查 Context7
- 不要盲目重试高风险动作
- 说明可能原因和安全的下一步

---

## 7. 输出规范

- 说明当前属于哪个模块
- 说明先检查了什么
- 说明为什么调用 Context7（如果调用了）
- 说明为什么需要确认（如果需要）
- 说明执行了什么
- 说明如何验证的
- 说明哪里仍然不确定
