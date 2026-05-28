CREATE OR REPLACE VIEW dbadmin.all_objects AS

SELECT
    CASE cls.relkind
        WHEN 'r' THEN 'TABLE'
        WHEN 'p' THEN 'TABLE'
        WHEN 'i' THEN 'INDEX'
        WHEN 'I' THEN 'INDEX' --Partitioned index
        WHEN 'S' THEN 'SEQUENCE'
        WHEN 'v' THEN 'VIEW'
        WHEN 'c' THEN 'TYPE'
        WHEN 'm' THEN 'MATERIALIZED VIEW'
        ELSE cls.relkind::TEXT
    END AS obj_type,
    nsp.nspname AS obj_schema,
    cls.relname AS obj_name,
    pg_size_pretty(pg_total_relation_size(cls.oid)) as total_size,
    pg_total_relation_size(cls.oid) as total_size_bytes,
    pg_size_pretty(pg_relation_size(cls.oid)) as obj_size,
    pg_relation_size(cls.oid) as obj_size_bytes,
    rol.rolname as owner,
    obj_description(cls.oid) as obj_comment,
    cls.relispartition AS is_partition,
    string_agg(
        pg_attribute.attname, ', ' ORDER BY pg_attribute.attnum
    ) AS columns,
    NULL AS function_arguments,
    NULL AS function_return
FROM
    pg_class AS cls
    JOIN pg_roles AS rol ON rol.oid = cls.relowner
    JOIN pg_namespace AS nsp ON nsp.oid = cls.relnamespace
    JOIN pg_catalog.pg_attribute
        ON cls.oid = pg_attribute.attrelid
        AND pg_attribute.attnum > 0
        AND NOT pg_attribute.attisdropped
WHERE
    nsp.nspname NOT LIKE 'pg_toast%'
GROUP BY
    cls.relkind,
    nsp.nspname,
    cls.relname,
    rol.rolname,
    cls.relispartition,
    cls.oid

UNION

SELECT
    CASE pg_proc.prokind
        WHEN 'w' THEN 'WINDOW FUNCTION'
        WHEN 'f' THEN 'FUNCTION'
        WHEN 'a' THEN 'AGGREGATE FUNCTION'
        WHEN 'p' THEN 'PROCEDURE'
        ELSE pg_proc.prokind::text
    END AS obj_type,
    pg_namespace.nspname AS obj_schema,
    format('%I(%s)', pg_proc.proname, oidvectortypes(pg_proc.proargtypes)) AS obj_name,
    NULL AS total_size,
    NULL AS total_size_bytes,
    NULL AS obj_size,
    NULL AS obj_size_bytes,
    r.rolname AS owner,
    pg_description.description AS obj_comment,
    NULL AS is_partition,
    NULL AS columns,
    pg_get_function_identity_arguments(pg_proc.oid) AS function_arguments,
    pg_get_function_result(pg_proc.oid) AS function_return
FROM pg_proc
JOIN pg_namespace ON (pg_proc.pronamespace = pg_namespace.oid)
JOIN pg_catalog.pg_roles r ON r.oid = pg_proc.proowner
LEFT JOIN pg_catalog.pg_description
    ON pg_description.objoid = pg_proc.oid
    AND pg_description.objsubid = 0
ORDER BY
    obj_schema,
    obj_type,
    obj_name;

ALTER VIEW dbadmin.all_objects OWNER TO dbadmin;
GRANT SELECT ON TABLE dbadmin.all_objects TO bdit_humans;

COMMENT ON VIEW dbadmin.all_objects
IS 'A view of all database objects, useful for purge.';
