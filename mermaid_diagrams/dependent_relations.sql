--DROP VIEW dbadmin.dependent_relations;

CREATE OR REPLACE VIEW dbadmin.dependent_relations AS (

    WITH fkey_constraints AS (
        SELECT
            con1.oid,
            --we don't have any cases with multiple attributes in a foreign key relationship, but if we did it may mess something up here.
            UNNEST(con1.conkey) AS parent,
            UNNEST(con1.confkey) AS child,
            con1.confrelid,
            con1.conrelid,
            con1.conname
        FROM pg_constraint AS con1
        WHERE con1.contype = 'f'
    )

    --view/mat view relationships
    SELECT DISTINCT
        ref_cl.oid AS ref_oid,
        ref_nsp.nspname AS ref_schema,
        ref_cl.relname AS ref_name,
        rwr_cl.oid AS dep_oid,
        rwr_nsp.nspname AS dep_schema,
        rwr_cl.relname AS dep_name,
        ref_nsp.nspname || '.' || ref_cl.relname ||
        --longer lines for inter-schema dependencies
        CASE WHEN ref_nsp.nspname != rwr_nsp.nspname THEN ' ----> ' ELSE ' --> ' END
        || rwr_nsp.nspname || '.' || rwr_cl.relname AS mermaid_relation
    FROM pg_depend AS dep
    JOIN pg_class AS ref_cl ON dep.refobjid = ref_cl.oid
    JOIN pg_namespace AS ref_nsp ON ref_cl.relnamespace = ref_nsp.oid
    JOIN pg_rewrite AS rwr ON dep.objid = rwr.oid
    JOIN pg_class AS rwr_cl ON rwr.ev_class = rwr_cl.oid
    JOIN pg_namespace AS rwr_nsp ON rwr_cl.relnamespace = rwr_nsp.oid
    WHERE
        dep.deptype = 'n'
        AND dep.classid = 'pg_rewrite'::regclass
        AND ref_cl.oid != rwr_cl.oid

    UNION

    --foreign key relationships
    SELECT
        ref_cl.oid AS ref_oid,
        ref_nsp.nspname AS ref_schema,
        ref_cl.relname AS ref_name,
        dep_cl.oid AS dep_oid,
        dep_nsp.nspname AS dep_schema,
        dep_cl.relname AS dep_name,
        ref_nsp.nspname || '.' || ref_cl.relname ||
        --longer lines for inter-schema dependencies
        CASE WHEN ref_nsp.nspname != dep_nsp.nspname THEN ' ----> ' ELSE ' --> ' END
        --label the foreign key relationship on the connecting line
        || '|' || conname || chr(10) || att2.attname || '->' || att.attname || '|'
        || dep_nsp.nspname || '.' || dep_cl.relname  AS mermaid_relation
    FROM fkey_constraints AS con
    JOIN pg_attribute AS att
        ON att.attrelid = con.confrelid
        AND att.attnum = con.child
    JOIN pg_class AS ref_cl
        ON ref_cl.oid = con.confrelid
    JOIN pg_attribute AS att2
        ON att2.attrelid = con.conrelid
        AND att2.attnum = con.parent
    JOIN pg_class AS dep_cl
        ON dep_cl.oid = con.conrelid
    JOIN pg_namespace AS ref_nsp
        ON ref_cl.relnamespace = ref_nsp.oid
    JOIN pg_namespace AS dep_nsp
        ON dep_cl.relnamespace = dep_nsp.oid
);