/*
Function to return column names for a single table in a variety of formats
including as a properlly fluffed SELECT statement with an automatically
generated alias (first letter of each word in table name ('_' as delimeter))

Usage:
Option 1: Set PGadmin Macro SQL to: the following:
--$SELECTION$ = schema_name.table_name (eg. gis_core.centreline_latest)
SELECT * FROM public.get_column_info_table('$SELECTION$');

Option 2: Set PGadmin Macro to the body of the below function,
replacing `sch_table_name` with `$SELECTION$`.
- This method will work across databases, but it won't automatically
use the latest version.

*/

DROP FUNCTION public.get_column_info_table(text);
CREATE OR REPLACE FUNCTION public.get_column_info_table(IN sch_table_name text) --$SELECTION$ = schema_name.table_name

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

--$SELECTION$ = schema_name.table_name
WITH table_prefix AS (
    SELECT 
        oid, 
        string_agg(
            LEFT(prefix, 1), --first letter of each word in table name
            ''
        ) AS table_alias
    FROM (
        SELECT
            pg_class.oid AS oid,
            pg_class.relname,
            UNNEST( --array to lines
                        regexp_split_to_array(
                            pg_class.relname, --extract table name from schema.relname
                            '_'
                        )
            ) prefix
        FROM pg_namespace
        JOIN pg_catalog.pg_class
            ON pg_class.relnamespace = pg_namespace.oid
            AND pg_class.relkind IN ('r', 'v', 'm') --tables, views, mat views
        WHERE
            pg_namespace.nspname = split_part(sch_table_name, '.', 1)
            AND pg_class.relname = split_part(sch_table_name, '.', 2)
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

ALTER FUNCTION public.get_column_info_table OWNER TO dbadmin;