/*
Query to get columns with datatypes and comments for a schema.table (or view/mat view).

Usage:
Set PGadmin Macro to the below select query.
Highlighted text (schema_name.table_name) will be populated into $SELECTION$
*/

SELECT
    a.attname AS column_name,
    d.description AS "Comments",
    pg_catalog.format_type(a.atttypid, a.atttypmod) as "Datatype"
FROM pg_class AS c
JOIN pg_attribute AS a ON c.oid = a.attrelid
JOIN pg_namespace AS n ON n.oid = c.relnamespace
LEFT JOIN pg_description AS d ON
    d.objoid = c.oid
    AND d.objsubid = a.attnum
WHERE
    n.nspname = split_part('$SELECTION$', '.', 1)::character varying COLLATE "C"
    AND c.relname = split_part('$SELECTION$', '.', 2)::character varying COLLATE "C"
    AND attisdropped = false
    AND attnum >= 1;
