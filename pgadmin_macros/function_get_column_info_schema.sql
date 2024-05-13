/*
Function to return column names for every table/view/matview in a schema.
Copy results to VS Code to take advantage of search/highlighting.

Usage:
Option 1: Set PGadmin Macro SQL to: the following:
--$SELECTION$ = schema_name (eg. rescu)
SELECT * FROM public.get_column_info_schema('$SELECTION$');

Option 2: Set PGadmin Macro to the body of the below function,
replacing `sch_name` with `$SELECTION$`.
- This method will work across databases, but it won't automatically
use the latest version.
*/



DROP FUNCTION public.get_column_info_schema(text);
CREATE OR REPLACE FUNCTION public.get_column_info_schema(IN sch_name text) --$SELECTION$ = schema_name

RETURNS TABLE (
    columns_new_line TEXT,
    columns_no_new_line TEXT,
    columns_no_alias TEXT,
    table_schema TEXT,
    tbl_name TEXT,
    table_alias TEXT,
    table_comment TEXT
) AS
$$

--$SELECTION$ = schema_name
WITH table_prefix AS (
    SELECT
        oid, 
        string_agg(
            LEFT(word, 1), --first letter of each word in table name
            ''
            ORDER BY rn
        ) AS table_alias
    FROM (
        SELECT
            pg_class.oid AS oid,
            pg_class.relname,
            table_name.word,
            table_name.rn
        FROM pg_namespace
        JOIN pg_catalog.pg_class
            ON pg_class.relnamespace = pg_namespace.oid
            AND pg_class.relkind IN ('r', 'v', 'm'), --tables, views, mat views
        LATERAL (
            SELECT
                regexp_split_to_table,
                ordinality
            FROM regexp_split_to_table(
                pg_class.relname, --extract table name from schema.relname
                '_'
            ) WITH ORDINALITY
        ) AS table_name(word, rn)
        WHERE
            pg_namespace.nspname = sch_name
    ) AS prefix
    GROUP BY oid
)

SELECT 
    string_agg(
        concat(table_prefix.table_alias || '.', pg_attribute.attname), ',' || chr(10)
        ORDER BY pg_attribute.attnum
    ) AS columns_new_line,
    string_agg(
        concat(table_prefix.table_alias || '.', pg_attribute.attname), ', '
        ORDER BY pg_attribute.attnum
    ) AS columns_no_new_line,
    string_agg(
        pg_attribute.attname, ', ' ORDER BY pg_attribute.attnum
    ) AS columns_no_alias,
    pg_namespace.nspname::text AS table_schema,
    pg_class.relname::text AS tbl_name,
    table_prefix.table_alias::text,
    pg_description.description AS table_comment
FROM pg_catalog.pg_namespace
JOIN pg_catalog.pg_class
    ON pg_class.relnamespace = pg_namespace.oid
    AND pg_class.relkind IN ('r', 'v', 'm') --tables, views, mat views
JOIN pg_catalog.pg_attribute
    ON pg_class.oid = pg_attribute.attrelid
    AND pg_attribute.attnum > 0
    AND NOT attisdropped
LEFT JOIN pg_catalog.pg_description
    ON pg_description.objoid = pg_class.oid
    AND pg_description.objsubid = 0
JOIN table_prefix ON table_prefix.oid = pg_class.oid
GROUP BY
    pg_namespace.nspname, 
    pg_class.relname,
    table_prefix.table_alias,
    pg_description.description
ORDER BY pg_class.relname;
$$
LANGUAGE SQL;

ALTER FUNCTION public.get_column_info_schema OWNER TO dbadmin;