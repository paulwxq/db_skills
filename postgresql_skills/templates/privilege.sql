-- ============================================
-- 授权模板
-- ============================================

-- ----------------------------------------
-- 数据库级权限
-- ----------------------------------------

-- 授予连接权限
GRANT CONNECT ON DATABASE mydb TO app_user;

-- 撤销公共连接权限（安全加固）
REVOKE CONNECT ON DATABASE mydb FROM PUBLIC;

-- ----------------------------------------
-- Schema 级权限
-- ----------------------------------------

-- 授予 schema 使用权限
GRANT USAGE ON SCHEMA myschema TO readonly_role;

-- 授予 schema 创建对象权限
GRANT USAGE, CREATE ON SCHEMA myschema TO readwrite_role;

-- ----------------------------------------
-- 表级权限
-- ----------------------------------------

-- 授予只读权限（现有表）
GRANT SELECT ON ALL TABLES IN SCHEMA myschema TO readonly_role;

-- 授予读写权限（现有表）
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA myschema TO readwrite_role;

-- 授予序列使用权限（现有序列）
GRANT USAGE ON ALL SEQUENCES IN SCHEMA myschema TO readwrite_role;

-- ----------------------------------------
-- 默认权限（未来新建的对象自动授权）
-- ----------------------------------------
--
-- 关键语义：ALTER DEFAULT PRIVILEGES 不带 FOR ROLE 时，只影响"当前执行此命令的角色"
-- 以后创建的对象。它不是 schema 级的普遍开关。
--
-- 常见陷阱：如果用 admin_role 执行了 ALTER DEFAULT PRIVILEGES，但实际建表的是
-- app_deploy_role，则 app_deploy_role 创建的表不会继承这些默认权限。
--
-- 如果需要影响特定角色创建的对象，必须使用 FOR ROLE：
--   ALTER DEFAULT PRIVILEGES FOR ROLE app_deploy_role IN SCHEMA myschema
--   GRANT SELECT ON TABLES TO readonly_role;

-- 默认只读权限（仅影响当前角色未来创建的表）
ALTER DEFAULT PRIVILEGES IN SCHEMA myschema
GRANT SELECT ON TABLES TO readonly_role;

-- 如果建表角色不是当前角色，需要显式指定 FOR ROLE：
-- ALTER DEFAULT PRIVILEGES FOR ROLE app_deploy_role IN SCHEMA myschema
-- GRANT SELECT ON TABLES TO readonly_role;

-- 默认读写权限
ALTER DEFAULT PRIVILEGES IN SCHEMA myschema
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO readwrite_role;

-- 默认序列权限
ALTER DEFAULT PRIVILEGES IN SCHEMA myschema
GRANT USAGE ON SEQUENCES TO readwrite_role;

-- ----------------------------------------
-- 撤销权限
-- ----------------------------------------

-- 撤销表级权限
REVOKE INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA myschema FROM app_user;

-- 撤销默认权限
ALTER DEFAULT PRIVILEGES IN SCHEMA myschema
REVOKE SELECT ON TABLES FROM readonly_role;

-- ----------------------------------------
-- 查看权限
-- ----------------------------------------

-- 查看表级权限
SELECT grantee, table_schema, table_name, privilege_type
FROM information_schema.table_privileges
WHERE table_schema = 'myschema'
ORDER BY grantee, table_name, privilege_type;

-- 查看角色的成员关系
SELECT
    r.rolname AS role,
    m.rolname AS member
FROM pg_auth_members am
JOIN pg_roles r ON r.oid = am.roleid
JOIN pg_roles m ON m.oid = am.member
ORDER BY r.rolname, m.rolname;

-- 查看默认权限
-- 重点关注 owner 列：该默认权限只对该 owner 未来创建的对象生效
SELECT
    pg_catalog.pg_get_userbyid(defaclrole) AS owner,
    defaclnamespace::regnamespace AS schema,
    defaclobjtype AS object_type,
    defaclacl AS default_acl
FROM pg_default_acl;
-- 验证：确认 owner 是否是实际建表的角色。如果不是，默认权限不会生效。
