DECLARE v_curr record;

BEGIN
FOR v_curr IN
(
    --find dependent objects
    SELECT obj_schema, obj_name, obj_type
    FROM (
        WITH RECURSIVE recursive_deps(obj_schema, obj_name, obj_type, depth) AS
        (
            SELECT
                p_view_schema,
                p_view_name,
                null::varchar,
                0
            UNION
            SELECT
                dep_schema::varchar,
                dep_name::varchar,
                dep_type::varchar,
                recursive_deps.depth + 1
            FROM
                (
                    SELECT
                        ref_nsp.nspname AS ref_schema,
                        ref_cl.relname AS ref_name,
                        rwr_cl.relkind AS dep_type,
                        rwr_nsp.nspname AS dep_schema,
                        rwr_cl.relname AS dep_name
                    FROM pg_depend dep
                    JOIN pg_class ref_cl ON dep.refobjid = ref_cl.oid
                    JOIN pg_namespace ref_nsp ON ref_cl.relnamespace = ref_nsp.oid
                    JOIN pg_rewrite rwr ON dep.objid = rwr.oid
                    JOIN pg_class rwr_cl ON rwr.ev_class = rwr_cl.oid
                    JOIN pg_namespace rwr_nsp ON rwr_cl.relnamespace = rwr_nsp.oid
                    WHERE
                        dep.deptype = 'n'
                        AND dep.classid = 'pg_rewrite'::regclass
                ) AS deps
            JOIN recursive_deps ON
                deps.ref_schema = recursive_deps.obj_schema
                AND deps.ref_name = recursive_deps.obj_name
            WHERE (
                deps.ref_schema != deps.dep_schema
                OR deps.ref_name != deps.dep_name)
            )
        SELECT obj_schema, obj_name, obj_type, depth
        FROM recursive_deps
        WHERE depth > 0
    ) t
    GROUP BY obj_schema, obj_name, obj_type
    ORDER BY max(depth) DESC
) loop

--save comments on dependencies
INSERT INTO public.deps_saved_ddl(deps_view_schema, deps_view_name, deps_ddl_to_run)
SELECT
    p_view_schema,
    p_view_name,
    'COMMENT ON ' ||
    CASE
        WHEN c.relkind = 'v' THEN 'VIEW'
        WHEN c.relkind = 'm' THEN 'MATERIALIZED VIEW'
        else ''
    END || ' ' || n.nspname || '.' || c.relname || ' IS ''' || replace(d.description, '''', '''''') || ''';'
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
JOIN pg_description d on
    d.objoid = c.oid
    AND d.objsubid = 0
WHERE
    n.nspname = v_curr.obj_schema
    AND c.relname = v_curr.obj_name
    AND d.description is not null;

--save comments on dependency columns
INSERT INTO public.deps_saved_ddl(deps_view_schema, deps_view_name, deps_ddl_to_run)
SELECT
    p_view_schema,
    p_view_name,
    'COMMENT ON COLUMN ' || n.nspname || '.' || c.relname || '.' || a.attname
    || ' IS ''' || replace(d.description, '''', '''''') || ''';' AS deps_ddl_to_run
FROM pg_class AS c
JOIN pg_attribute AS a ON c.oid = a.attrelid
JOIN pg_namespace AS n ON n.oid = c.relnamespace
JOIN pg_description AS d ON
    d.objoid = c.oid
    AND d.objsubid = a.attnum
WHERE
    n.nspname = v_curr.obj_schema
    AND c.relname = v_curr.obj_name
    AND d.description IS NOT NULL;

--save permissions on object
INSERT INTO public.deps_saved_ddl(deps_view_schema, deps_view_name, deps_ddl_to_run)
SELECT
    p_view_schema,
    p_view_name,
    'GRANT ' || privilege_type || ' ON ' || table_schema || '.'
    || table_name || ' TO ' || grantee AS deps_ddl_to_run
FROM information_schema.role_table_grants
WHERE
    table_schema = v_curr.obj_schema
    AND table_name = v_curr.obj_name;

--save create statements
IF v_curr.obj_type = 'v' THEN
    INSERT INTO public.deps_saved_ddl(deps_view_schema, deps_view_name, deps_ddl_to_run)
    SELECT
        p_view_schema,
        p_view_name,
        'CREATE VIEW ' || v_curr.obj_schema || '.' || v_curr.obj_name || ' AS '
        || definition AS deps_ddl_to_run
    FROM information_schema.views
    WHERE
        table_schema = v_curr.obj_schema
        AND table_name = v_curr.obj_name;

ELSIF v_curr.obj_type = 'm' THEN

    --save mat view definition
    INSERT INTO public.deps_saved_ddl(deps_view_schema, deps_view_name, deps_ddl_to_run)
    SELECT
        p_view_schema,
        p_view_name,
        'CREATE MATERIALIZED VIEW ' || v_curr.obj_schema || '.' || v_curr.obj_name
        || ' AS ' || definition AS deps_ddl_to_run
    FROM pg_matviews
    WHERE
        schemaname = v_curr.obj_schema
        AND matviewname = v_curr.obj_name;
END IF;

EXECUTE 'DROP ' ||
  CASE
    WHEN v_curr.obj_type = 'v' THEN 'VIEW'
    WHEN v_curr.obj_type = 'm' THEN 'MATERIALIZED VIEW'
  END || ' ' || v_curr.obj_schema || '.' || v_curr.obj_name;

END loop;

END;
