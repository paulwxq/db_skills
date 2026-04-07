-- ============================================
-- 角色创建模板
-- ============================================

-- 查看现有角色
SELECT rolname, rolsuper, rolcreaterole, rolcreatedb, rolcanlogin, rolreplication
FROM pg_roles
ORDER BY rolname;

-- ----------------------------------------
-- 创建登录角色（用于应用连接）
-- INHERIT 使得通过 GRANT 获得的角色权限自动生效，无需 SET ROLE
-- 如果用 NOINHERIT，则必须 SET ROLE 到目标角色才能使用其权限
-- ----------------------------------------
CREATE ROLE app_user
    LOGIN
    PASSWORD 'secure_password'
    NOSUPERUSER
    NOCREATEDB
    NOCREATEROLE
    INHERIT;

-- ----------------------------------------
-- 创建只读权限角色（不可登录，用于权限承载）
-- ----------------------------------------
CREATE ROLE readonly_role
    NOLOGIN
    NOSUPERUSER
    NOCREATEDB
    NOCREATEROLE;

-- ----------------------------------------
-- 创建读写权限角色
-- ----------------------------------------
CREATE ROLE readwrite_role
    NOLOGIN
    NOSUPERUSER
    NOCREATEDB
    NOCREATEROLE;

-- ----------------------------------------
-- 将权限角色授予登录角色
-- 因为 app_user 使用 INHERIT，授予后权限自动生效
-- 如果 app_user 是 NOINHERIT，则需要执行 SET ROLE readonly_role 才能使用权限
-- ----------------------------------------
GRANT readonly_role TO app_user;

-- ----------------------------------------
-- 验证：角色是否存在及其属性
-- ----------------------------------------
SELECT rolname, rolsuper, rolcreaterole, rolcreatedb, rolcanlogin, rolinherit
FROM pg_roles WHERE rolname = 'app_user';

-- ----------------------------------------
-- 验证：角色成员关系
-- ----------------------------------------
SELECT r.rolname AS granted_role, m.rolname AS member, m.rolinherit
FROM pg_auth_members am
JOIN pg_roles r ON r.oid = am.roleid
JOIN pg_roles m ON m.oid = am.member
WHERE m.rolname = 'app_user';

-- ----------------------------------------
-- 验证：权限是否实际生效
-- 以 app_user 身份检查对目标表的访问权限
-- ----------------------------------------
SELECT has_table_privilege('app_user', 'public.mytable', 'SELECT') AS can_select;
SELECT has_schema_privilege('app_user', 'public', 'USAGE') AS can_use_schema;

-- ----------------------------------------
-- 修改角色密码
-- ----------------------------------------
ALTER ROLE app_user PASSWORD 'new_secure_password';

-- ----------------------------------------
-- 设置角色连接限制
-- ----------------------------------------
ALTER ROLE app_user CONNECTION LIMIT 10;

-- ----------------------------------------
-- 删除角色（需先撤销所有权限和所属对象）
-- ----------------------------------------
-- REASSIGN OWNED BY old_role TO postgres;
-- DROP OWNED BY old_role;
-- DROP ROLE old_role;
