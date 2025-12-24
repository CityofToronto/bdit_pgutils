--DROP FUNCTION public.mermaid_dependency_diagram(text, text);

CREATE OR REPLACE FUNCTION public.mermaid_dependency_diagram (
    input_obj text,
    recursive_direciton text,
    simple_diagram boolean
) RETURNS TEXT
    LANGUAGE plpgsql
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$

BEGIN

    IF simple_diagram = False THEN
    
        CREATE TEMP TABLE dependencies ON COMMIT DROP AS
            --every object that has a relationship with some object in the recursive dependency tree (2nd level dependencies)
            SELECT
                dep_schema,
                dep_name,
                ref_schema,
                ref_name
            FROM public.dependent_relations AS deps
            WHERE
                dep_schema || '.' || dep_name IN (
                    SELECT obj_schema || '.' || obj_name
                    FROM public.get_recursive_dependencies(
                        input_obj, recursive_direciton
                    )
                )
                OR ref_schema || '.' || ref_name IN (
                    SELECT obj_schema || '.' || obj_name
                    FROM public.get_recursive_dependencies(
                        input_obj, recursive_direciton
                    )
                );
        
        --relationships between nodes
        CREATE TEMP TABLE mermaid_relations ON COMMIT DROP AS
        SELECT mermaid_relation
        FROM public.dependent_relations AS deps
        WHERE ref_schema || '.' || ref_name IN (
            SELECT obj_schema || '.' || obj_name
            FROM public.get_recursive_dependencies(input_obj, recursive_direciton)
        ) OR dep_schema || '.' || dep_name IN (
            SELECT obj_schema || '.' || obj_name
            FROM public.get_recursive_dependencies(input_obj, recursive_direciton)
        );
        
    ELSEIF simple_diagram = True THEN
        
        CREATE TEMP TABLE dependencies ON COMMIT DROP AS
            --every object that has a relationship with some object in the recursive dependency tree (2nd level dependencies)
            SELECT
                dep_schema,
                dep_name,
                ref_schema,
                ref_name
            FROM public.dependent_relations AS deps
            WHERE
                dep_schema || '.' || dep_name IN (
                    SELECT obj_schema || '.' || obj_name
                    FROM public.get_recursive_dependencies(input_obj, recursive_direciton)
                )
                AND ref_schema || '.' || ref_name IN (
                    SELECT obj_schema || '.' || obj_name
                    FROM public.get_recursive_dependencies(input_obj, recursive_direciton)
                );

        --relationships between nodes
        CREATE TEMP TABLE mermaid_relations ON COMMIT DROP AS
        SELECT mermaid_relation
        FROM public.dependent_relations AS deps
        WHERE ref_schema || '.' || ref_name IN (
            SELECT obj_schema || '.' || obj_name
            FROM public.get_recursive_dependencies(input_obj, recursive_direciton)
        ) AND dep_schema || '.' || dep_name IN (
            SELECT obj_schema || '.' || obj_name
            FROM public.get_recursive_dependencies(input_obj, recursive_direciton)
        );
    
    END IF;

    
    --aggregate subgraphs and relationships into a complete diagram
    RETURN (

    WITH objs AS (
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
    )
    
    SELECT
    '%%{init: {''theme'': ''neutral'', ''flowchart'': {''defaultRenderer'': ''elk''}}}%%' || chr(10) ||
    'flowchart TD' || chr(10) ||
    string_agg('    ' || mermaid_object, chr(10)) AS mermaid_diagram
    FROM (
        --subgraphs for each schema
        SELECT
            'subgraph ' || obj_schema || chr(10) ||
            --TODO: give different shapes to different objects.
            string_agg('        ' || 
                --CASE obj_type
                --    WHEN 'v' THEN lat.full_name || '{{' || lat.full_name || '}}'
                --    WHEN 'm' THEN lat.full_name || '[[' || lat.full_name || ']]'
                --    ELSE lat.full_name
                --END,
                objs.full_name || '[' || objs.obj_name || ']', chr(10)
            ) || chr(10) || '    end' AS mermaid_object
        FROM objs
        GROUP BY obj_schema
        UNION ALL
        --relationships between nodes
        SELECT mermaid_relation
        FROM mermaid_relations
        UNION ALL
        --extra style for the key node
        SELECT '    style '
            || input_obj
            || ' fill:#f9f,stroke:#333,stroke-width:4px,color:black'
    ) AS objects
    );

END;
$BODY$;

ALTER FUNCTION public.mermaid_dependency_diagram(text, text, boolean)
OWNER TO dbadmin;

GRANT EXECUTE ON FUNCTION public.mermaid_dependency_diagram(text, text, boolean) TO PUBLIC;

GRANT EXECUTE ON FUNCTION public.mermaid_dependency_diagram(text, text, boolean) TO bdit_humans;

GRANT EXECUTE ON FUNCTION public.mermaid_dependency_diagram(text, text, boolean) TO dbadmin;


--an overloaded version with some defaults specified
CREATE OR REPLACE FUNCTION public.mermaid_dependency_diagram (
    input_obj text
) RETURNS TEXT
    LANGUAGE sql
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$

SELECT public.mermaid_dependency_diagram(
    input_obj:=input_obj,
    recursive_direciton:='both',
    simple_diagram:='True'
);
$BODY$;

ALTER FUNCTION public.mermaid_dependency_diagram(text)
    OWNER TO dbadmin;

GRANT EXECUTE ON FUNCTION public.mermaid_dependency_diagram(text) TO PUBLIC;

GRANT EXECUTE ON FUNCTION public.mermaid_dependency_diagram(text) TO bdit_humans;

GRANT EXECUTE ON FUNCTION public.mermaid_dependency_diagram(text) TO dbadmin;
