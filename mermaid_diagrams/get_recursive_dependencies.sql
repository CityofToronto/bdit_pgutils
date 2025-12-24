--DROP FUNCTION IF EXISTS public.get_recursive_dependencies;

CREATE OR REPLACE FUNCTION public.get_recursive_dependencies (
    input_obj text,
    recursive_direction text
) RETURNS TABLE(oid oid, obj_schema name, obj_name name) 
    LANGUAGE plpgsql
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000
AS $BODY$

BEGIN

    IF recursive_direction = 'down' THEN 
        RETURN QUERY
        SELECT t.oid, t.obj_schema, t.obj_name
            FROM (
                WITH RECURSIVE recursive_deps(oid, obj_schema, obj_name, depth) AS
                (
                    SELECT
                        pg_class.oid,
                        pg_namespace.nspname,
                        pg_class.relname,
                        0 AS depth
                    FROM pg_class
                    JOIN pg_namespace ON pg_class.relnamespace = pg_namespace.oid
                    WHERE
                        pg_namespace.nspname = split_part(input_obj, '.', 1)
                        AND pg_class.relname = split_part(input_obj, '.', 2)
    
                    UNION
                    SELECT
                        deps.dep_oid,
                        deps.dep_schema::varchar,
                        deps.dep_name::varchar,
                        recursive_deps.depth + 1
                    FROM
                        (
                            SELECT dep_oid, ref_schema, ref_name, dep_schema, dep_name
                            FROM public.dependent_relations
                        ) AS deps
                    JOIN recursive_deps ON
                        deps.ref_schema = recursive_deps.obj_schema
                        AND deps.ref_name = recursive_deps.obj_name
                    WHERE
                        depth < 20
                        AND NOT (
                            deps.ref_schema = deps.dep_schema
                            AND deps.ref_name = deps.dep_name
                        )
                )
    
                SELECT rd.oid, rd.obj_schema, rd.obj_name, rd.depth
                FROM recursive_deps AS rd
                WHERE depth >= 0
            ) AS t
        GROUP BY t.oid, t.obj_schema, t.obj_name
        ORDER BY max(depth) DESC;
    ELSEIF recursive_direction = 'up' THEN
        RETURN QUERY
        SELECT t.oid, t.obj_schema, t.obj_name
            FROM (
                WITH RECURSIVE recursive_deps(oid, obj_schema, obj_name, depth) AS
                (
                    SELECT
                        pg_class.oid,
                        pg_namespace.nspname,
                        pg_class.relname,
                        0 AS depth
                    FROM pg_class
                    JOIN pg_namespace ON pg_class.relnamespace = pg_namespace.oid
                    WHERE
                        pg_namespace.nspname = split_part(input_obj, '.', 1)
                        AND pg_class.relname = split_part(input_obj, '.', 2)
    
                    UNION
                    SELECT
                        deps.dep_oid,
                        deps.ref_schema::varchar,
                        deps.ref_name::varchar,
                        recursive_deps.depth + 1
                    FROM
                        (
                            SELECT dep_oid, ref_schema, ref_name, dep_schema, dep_name
                            FROM public.dependent_relations
                        ) AS deps
                    JOIN recursive_deps ON
                        deps.dep_schema = recursive_deps.obj_schema
                        AND deps.dep_name = recursive_deps.obj_name
                    WHERE
                        depth < 20
                        AND NOT (
                            deps.ref_schema = deps.dep_schema
                            AND deps.ref_name = deps.dep_name
                        )
                )
    
                SELECT rd.oid, rd.obj_schema, rd.obj_name, rd.depth
                FROM recursive_deps AS rd
                WHERE depth >= 0
            ) AS t
        GROUP BY t.oid, t.obj_schema, t.obj_name
        ORDER BY max(depth) DESC;
    ELSEIF recursive_direction = 'both' THEN
        RETURN QUERY
        SELECT * FROM public.get_recursive_dependencies(input_obj, 'down')
        UNION
        SELECT * FROM public.get_recursive_dependencies(input_obj, 'up');
    END IF;

    END;

$BODY$;

/*Examples:
SELECT public.get_recursive_dependencies('miovision_validation.valid_legs_view', 'down')
SELECT public.get_recursive_dependencies('miovision_validation.valid_legs_view', 'up')
SELECT public.get_recursive_dependencies('miovision_validation.valid_legs_view', 'both')
*/
