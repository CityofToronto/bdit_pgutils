CREATE OR REPLACE VIEW dbadmin.schemas AS
SELECT
    pg_namespace.nspname AS schema_name,
    SUM(pg_relation_size(pg_class.oid)) AS schema_size,
    pg_size_pretty(SUM(pg_relation_size(pg_class.oid))) AS schema_size_pretty,
    pg_roles.rolname as owner,
    obj_description(pg_namespace.oid) as obj_comment
FROM pg_catalog.pg_class
JOIN pg_catalog.pg_namespace ON pg_class.relnamespace = pg_namespace.oid
JOIN pg_roles ON pg_roles.oid = pg_namespace.nspowner
GROUP BY
    pg_namespace.nspname,
    pg_namespace.oid,
    pg_roles.rolname
ORDER BY
    schema_name;

ALTER VIEW dbadmin.schemas OWNER TO dbadmin;
GRANT SELECT ON TABLE dbadmin.schemas TO bdit_humans;

COMMENT ON VIEW dbadmin.schemas
IS 'A view of database schemas, useful for purge.';
