# 05 - 角色与权限管理

## 模块目标

处理角色创建、用户管理、权限授予与撤销、默认权限配置。

---

## 典型任务

- 创建登录角色（用于应用连接）
- 创建业务角色（用于权限承载）
- 授予数据库级权限（CONNECT）
- 授予 schema 级权限（USAGE, CREATE）
- 授予表级权限（SELECT, INSERT, UPDATE, DELETE）
- 撤销权限（REVOKE）
- 配置默认权限（ALTER DEFAULT PRIVILEGES）
- 查询现有角色与权限

---

## 权限继承模型

本 Skill 默认使用 **INHERIT 模式**：

- 登录角色（如 `app_user`）创建时设为 `INHERIT`
- 权限承载角色（如 `readonly_role`）持有具体对象权限
- 通过 `GRANT readonly_role TO app_user`，登录角色自动继承权限承载角色的对象权限，无需 `SET ROLE`

这是 PostgreSQL 最常见的角色权限模式，认知负担最低，适合 Agent 稳定执行。

如果用户明确要求更严格的模型（登录角色不自动继承，必须显式切换），则使用 `NOINHERIT` 并在流程中加入 `SET ROLE` / `RESET ROLE` 步骤。这种模式不是默认选项，且必须向用户说明行为差异。

---

## 标准流程

1. 明确目标是"登录角色"还是"权限承载角色"
2. 查询角色是否已存在
3. 查询现有权限状态
4. 如权限语义不确定（继承、默认权限等），调用 Context7
5. 输出授权计划，请求确认
6. 执行 CREATE ROLE / GRANT / REVOKE
7. **验证权限实际生效**（不能省略）：
   - 查看角色属性：`SELECT rolname, rolinherit FROM pg_roles WHERE rolname = 'app_user';`
   - 查看成员关系：`SELECT * FROM pg_auth_members WHERE member = (SELECT oid FROM pg_roles WHERE rolname = 'app_user');`
   - 验证对象权限：`SELECT has_table_privilege('app_user', 'target_table', 'SELECT');`
   - 如验证结果与预期不符，检查 INHERIT/NOINHERIT 设置和 GRANT 链路

---

## 最小模板

```sql
-- 查看现有角色
SELECT rolname, rolsuper, rolcreaterole, rolcreatedb, rolcanlogin
FROM pg_roles
ORDER BY rolname;

-- 创建登录角色（INHERIT 使 GRANT 的权限自动生效）
CREATE ROLE app_user LOGIN PASSWORD 'secure_password' INHERIT;

-- 创建权限承载角色（不可登录）
CREATE ROLE readonly_role NOLOGIN;

-- 授予数据库连接权限
GRANT CONNECT ON DATABASE mydb TO app_user;

-- 授予 schema 使用权限
GRANT USAGE ON SCHEMA public TO readonly_role;

-- 授予表的只读权限
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly_role;

-- 配置默认权限
-- 注意：不带 FOR ROLE 时只影响当前角色未来创建的对象，不是 schema 级的普遍开关
-- 如果建表角色不是当前角色，必须用 FOR ROLE 指定：
--   ALTER DEFAULT PRIVILEGES FOR ROLE deployer IN SCHEMA public GRANT SELECT ON TABLES TO readonly_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT SELECT ON TABLES TO readonly_role;

-- 将权限角色授予登录角色
-- app_user 设为 INHERIT，所以 readonly_role 的权限自动生效
-- 如果登录角色是 NOINHERIT，则必须 SET ROLE readonly_role 才能使用其权限
GRANT readonly_role TO app_user;

-- 撤销权限
REVOKE INSERT ON ALL TABLES IN SCHEMA public FROM app_user;

-- 查看表级权限
SELECT grantee, table_schema, table_name, privilege_type
FROM information_schema.table_privileges
WHERE table_schema = 'public'
ORDER BY grantee, table_name, privilege_type;
```

---

## Context7 调用指引

当以下情况发生时调用 Context7：

- CREATE ROLE 的选项不确定（LOGIN, NOLOGIN, INHERIT, NOINHERIT 等）
- 角色继承机制不清楚
- ALTER DEFAULT PRIVILEGES 的作用域不确定
- GRANT / REVOKE 的语义不确定
- 预定义角色（predefined roles）的功能不确定
- 需要了解 pg_has_role / has_table_privilege 等函数

### 推荐查询

- `PostgreSQL CREATE ROLE`
- `PostgreSQL ALTER ROLE`
- `PostgreSQL GRANT`
- `PostgreSQL REVOKE`
- `PostgreSQL ALTER DEFAULT PRIVILEGES`
- `PostgreSQL predefined roles`
- `PostgreSQL role inheritance`

---

## 风险规则

- **CREATE ROLE**：需要确认，特别是权限属性
- **GRANT SUPERUSER / CREATEROLE**：高风险，必须确认且说明影响
- **ALTER DEFAULT PRIVILEGES**：影响未来所有新建对象，必须确认
- **REVOKE**：可能影响现有应用访问，必须确认
- **DROP ROLE**：必须确认，需先检查是否有依赖对象
- 查看角色和权限为只读操作，可直接执行
- 始终遵循最小权限原则
- INHERIT/NOINHERIT 模型选择见本模块"权限继承模型"章节
