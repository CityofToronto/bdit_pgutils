--DROP VIEW gwolofs.dependent_relations;

CREATE OR REPLACE VIEW gwolofs.dependent_relations AS (
    SELECT DISTINCT
        rwr_cl.oid AS dep_oid,
        ref_nsp.nspname AS ref_schema,
        ref_cl.relname AS ref_name,
        rwr_cl.relkind AS dep_type,
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
);
