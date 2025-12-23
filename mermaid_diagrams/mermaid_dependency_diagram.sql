--DROP FUNCTION public.mermaid_dependency_diagram(text, text);

CREATE OR REPLACE FUNCTION public.mermaid_dependency_diagram (
    input_obj text
) RETURNS TEXT
    LANGUAGE sql
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$

    WITH dependencies AS (
        --every object that has a relationship with some object in the recursive dependency tree (2nd level dependencies)
        SELECT
            dep_schema,
            dep_name,
            ref_schema,
            ref_name
        FROM public.dependent_relations AS deps
        WHERE
            (dep_schema || '.' || dep_name IN (
                SELECT obj_schema || '.' || obj_name
                FROM public.get_recursive_dependencies(
                    split_part(input_obj, '.', 1),
                    split_part(input_obj, '.', 2)
                )
            )
            OR ref_schema || '.' || ref_name IN (
                SELECT obj_schema || '.' || obj_name
                FROM public.get_recursive_dependencies(
                    split_part(input_obj, '.', 1),
                    split_part(input_obj, '.', 2)
                )
            ))
            AND NOT (
                dep_name = ref_name
                AND dep_schema = ref_schema
            )
    )

    --aggregate subgraphs and relationships into a complete diagram
    SELECT
    '%%{init: {''theme'': ''neutral'', ''flowchart'': {''defaultRenderer'': ''elk''}}}%%' || chr(10) ||
    'flowchart TD' || chr(10) ||
    string_agg('    ' || mermaid_object, chr(10)) AS mermaid_diagram
    FROM (
        --subgraphs for each schema
        SELECT
            'subgraph ' || obj_schema || chr(10) ||
            --more work needed to give different shapes to different objects.
            string_agg('        ' || 
                --CASE obj_type
                --    WHEN 'v' THEN lat.full_name || '{{' || lat.full_name || '}}'
                --    WHEN 'm' THEN lat.full_name || '[[' || lat.full_name || ']]'
                --    ELSE lat.full_name
                --END,
                objs.full_name || '[' || objs.obj_name || ']', chr(10)
            ) || chr(10) || '    end' AS mermaid_object
        FROM (
            SELECT DISTINCT
                dep_schema AS obj_schema,
                dep_schema || '.' || dep_name AS full_name,
                dep_name AS obj_name
            FROM dependencies
            UNION
            SELECT DISTINCT
                ref_schema AS obj_schema,
                ref_schema || '.' || ref_name AS full_name,
                ref_name AS obj_name
            FROM dependencies
        ) AS objs
        GROUP BY obj_schema
        UNION ALL
        --relationships between nodes
        SELECT mermaid_relation
        FROM public.dependent_relations AS deps
        WHERE dep_schema || '.' || dep_name IN (
            SELECT obj_schema || '.' || obj_name
            FROM public.get_recursive_dependencies(
                    split_part(input_obj, '.', 1),
                    split_part(input_obj, '.', 2)
                )
        ) AND NOT (
            deps.ref_schema = deps.dep_schema
            AND deps.ref_name = deps.dep_name
        )
        UNION ALL
        SELECT '    style '
            || input_obj
            || ' fill:#f9f,stroke:#333,stroke-width:4px,color:black'
    ) AS objects

$BODY$;
