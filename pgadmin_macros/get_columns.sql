/*
Query to get columns with datatypes, comments, sample for a schema.table (or view/mat view).

Usage:
Set PGadmin Macro to the below select query.
Highlighted text (schema_name.table_name) will be populated into $SELECTION$
*/

WITH row_sample AS (
    SELECT
        (xpath('name(/*)', col))[1]::text AS attname,
        left(array_to_string(xpath('//text()', col), ','), 80) AS "Sample"
    FROM (
        SELECT unnest(xpath('/row/*',
            query_to_xml('SELECT * FROM $SELECTION$ LIMIT 1', FALSE, TRUE, '')
        )) AS col
    ) sub
)

SELECT
    a.attname AS column_name,
    d.description AS "Comments",
    pg_catalog.format_type(a.atttypid, a.atttypmod) as "Datatype",
    row_sample."Sample" 
FROM pg_class AS c
JOIN pg_attribute AS a ON c.oid = a.attrelid
JOIN pg_namespace AS n ON n.oid = c.relnamespace
LEFT JOIN pg_description AS d ON
    d.objoid = c.oid
    AND d.objsubid = a.attnum
LEFT JOIN row_sample USING (attname)
WHERE
    n.nspname = split_part('$SELECTION$', '.', 1)::character varying COLLATE "C"
    AND c.relname = split_part('$SELECTION$', '.', 2)::character varying COLLATE "C"
    AND a.attisdropped = false
    AND a.attnum >= 1
ORDER BY a.attnum;
