
CREATE OR REPLACE VIEW dbadmin.tables_and_views AS
SELECT
    obj_type,
    obj_schema,
    obj_name,
    total_size,
    total_size_bytes,
    obj_size,
    obj_size_bytes,
    owner,
    obj_comment,
    is_partition,
    columns
FROM
    dbadmin.all_objects
WHERE
    obj_type IN ('TABLE', 'VIEW', 'MATERIALIZED VIEW');

ALTER VIEW dbadmin.tables_and_views owner TO dbadmin;
GRANT SELECT ON TABLE dbadmin.tables_and_views TO bdit_humans;

COMMENT ON VIEW dbadmin.tables_and_views
IS 'A view of database objects filtered to only tables, views and materialized view.';
