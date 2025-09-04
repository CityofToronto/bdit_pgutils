-- DROP FUNCTION gwolofs.get_recursive_dependencies(text, text);

CREATE OR REPLACE FUNCTION gwolofs.get_recursive_dependencies (
    sch_name text,
    obj_name text
) RETURNS TABLE(oid oid, obj_schema character varying, obj_name character varying, obj_type character varying) 
    LANGUAGE sql
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000
AS $BODY$

    SELECT oid, obj_schema, obj_name, obj_type
        FROM (
            WITH RECURSIVE recursive_deps(oid, obj_schema, obj_name, obj_type, depth) AS
            (
                SELECT
                    0::oid,
                    get_recursive_dependencies.sch_name::character varying COLLATE "C",
                    get_recursive_dependencies.obj_name::character varying COLLATE "C",
                    null::varchar,
                    0
                UNION
                SELECT
                    deps.dep_oid,
                    deps.dep_schema::varchar,
                    deps.dep_name::varchar,
                    deps.dep_type::varchar,
                    recursive_deps.depth + 1
                FROM
                    (
                        SELECT dep_oid, ref_schema, ref_name, dep_type, dep_schema, dep_name
                        FROM gwolofs.dependent_relations
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
            
            SELECT oid, obj_schema, obj_name, obj_type, depth
            FROM recursive_deps
            WHERE depth >= 0
        ) AS t
        GROUP BY t.oid, t.obj_schema, t.obj_name, t.obj_type
        ORDER BY max(depth) DESC

$BODY$;
