CREATE OR REPLACE FUNCTION public.deps_save_and_drop_dependencies_dryrun(
    p_view_schema IN VARCHAR,
    p_view_name IN VARCHAR,
    dryrun BOOLEAN default True
)
RETURNS VOID
LANGUAGE plpgsql
    VOLATILE
    PARALLEL UNSAFE
    COST 100
AS
$$
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

DELETE FROM public.deps_saved_ddl
WHERE
    deps_view_schema = v_curr.obj_schema
    AND deps_view_name = v_curr.obj_name;

IF v_curr.obj_type = 'v' THEN
    INSERT INTO public.deps_saved_ddl(deps_view_schema, deps_view_name, deps_ddl_to_run)
    --save view create statements
    SELECT
        p_view_schema,
        p_view_name,
        'CREATE VIEW ' || v_curr.obj_schema || '.' || v_curr.obj_name || ' AS '
        || definition AS deps_ddl_to_run
    FROM pg_views
    WHERE
        schemaname = v_curr.obj_schema
        AND viewname = v_curr.obj_name;

    --save view owners 
    INSERT INTO public.deps_saved_ddl(deps_view_schema, deps_view_name, deps_ddl_to_run)
    SELECT
        p_view_schema,
        p_view_name,
        'ALTER VIEW ' || v_curr.obj_schema || '.' || v_curr.obj_name || ' OWNER TO '
        || viewowner || ';' AS deps_ddl_to_run
    FROM pg_views
    WHERE
        schemaname = v_curr.obj_schema
        AND viewname = v_curr.obj_name;

ELSIF v_curr.obj_type = 'm' THEN

    INSERT INTO public.deps_saved_ddl(deps_view_schema, deps_view_name, deps_ddl_to_run)
    --save mat view definition
    SELECT
        p_view_schema,
        p_view_name,
        'CREATE MATERIALIZED VIEW ' || v_curr.obj_schema || '.' || v_curr.obj_name
        || ' AS ' || definition AS deps_ddl_to_run
    FROM pg_matviews
    WHERE
        schemaname = v_curr.obj_schema
        AND matviewname = v_curr.obj_name;
    
    --save index/unique index: 
    INSERT INTO public.deps_saved_ddl(deps_view_schema, deps_view_name, deps_ddl_to_run)
    SELECT
        p_view_schema,
        p_view_name,
        indexdef || ';' AS deps_ddl_to_run
    FROM pg_indexes
    WHERE
        schemaname = v_curr.obj_schema
        AND tablename = v_curr.obj_name;

    --save mat view owner: 
    INSERT INTO public.deps_saved_ddl(deps_view_schema, deps_view_name, deps_ddl_to_run)
    SELECT
        p_view_schema,
        p_view_name,
        'ALTER MATERIALIZED VIEW ' || v_curr.obj_schema || '.' || v_curr.obj_name
        || ' OWNER TO ' || matviewowner || ';' AS deps_ddl_to_run
    FROM pg_matviews
    WHERE
        schemaname = v_curr.obj_schema
        AND matviewname = v_curr.obj_name;

END IF;

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
    'GRANT ' || public.priviliges_from_acl(s[2])
    || ' ON ' || nspname || '.' || relname || ' TO ' || 
    COALESCE(NULLIF(s[1], ''), 'public') || ';' AS deps_ddl_to_run
FROM pg_class AS c
JOIN pg_namespace AS n ON n.oid = c.relnamespace
JOIN pg_roles AS r ON r.oid = c.relowner,
UNNEST(COALESCE(relacl::text[], format('{%s=arwdDxt/%s}', rolname, rolname)::text[])) acl, 
    regexp_split_to_array(acl, '=|/') s
WHERE
    nspname = v_curr.obj_schema
    AND relname = v_curr.obj_name;

IF dryrun IS FALSE THEN
    EXECUTE 'DROP ' ||
    CASE
        WHEN v_curr.obj_type = 'v' THEN 'VIEW'
        WHEN v_curr.obj_type = 'm' THEN 'MATERIALIZED VIEW'
    END || ' ' || v_curr.obj_schema || '.' || v_curr.obj_name || ';';
END IF;

END loop;

END;
$$;

ALTER FUNCTION public.deps_save_and_drop_dependencies_dryrun(VARCHAR, VARCHAR, BOOLEAN) OWNER TO bdit_admins;
GRANT EXECUTE ON FUNCTION public.deps_save_and_drop_dependencies_dryrun(VARCHAR, VARCHAR, BOOLEAN) TO bdit_humans;

COMMENT ON FUNCTION public.deps_save_and_drop_dependencies_dryrun(VARCHAR, VARCHAR, BOOLEAN) IS 
    '''This version of the function is meant for testing. Use with dryrun = False (default). 
    Use this function when you need to drop+edit+recreate a table or (mat) view with dependencies.
    This function will recursively iterate through an objects dependencies and save:
    - definition of view/mat view
    - object owner
    - index/unique index (only applies to mat views)
    - object comments
    - column comments
    - any permissions
    - DROP the dependency
    Then, after dropping, editing, and restoring the original object, use the function 
    public.deps_restore_dependencies(VARCHAR, VARCHAR) to recreate the dependencies. 
    You can also use `dryrun = True` to not drop the dependencies, if you want to check
    the entries in `public.deps_saved_ddl` first. In that case you will have to delete the records.
    
    Example with dryrun = True;
    SELECT public.deps_save_and_drop_dependencies_dryrun(''miovision_api''::text COLLATE pg_catalog."C", ''volumes_15min''::text COLLATE pg_catalog."C");
    --examine the create statements: 
    SELECT * FROM public.deps_saved_ddl WHERE deps_view_schema = ''miovision_api'' AND deps_view_name = ''volumes_15min'' ORDER BY deps_id;
    '''
