CREATE OR REPLACE VIEW dbadmin.functions AS
SELECT
    obj_type,
    obj_schema,
    obj_name,
    owner,
    obj_comment,
    function_arguments,
    function_return
FROM
    dbadmin.all_objects
WHERE
    obj_type IN ('WINDOW FUNCTION', 'FUNCTION', 'AGGREGATE FUNCTION', 'PROCEDURE');

ALTER VIEW dbadmin.functions owner TO dbadmin;

GRANT SELECT ON TABLE dbadmin.functions TO bdit_humans;

COMMENT ON VIEW dbadmin.functions
IS 'A view of database objects filtered to only functions and procedures.';
