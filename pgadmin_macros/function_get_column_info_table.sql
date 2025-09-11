/*
Query to return column names for a single table in a variety of formats
including as a properlly fluffed SELECT statement with an automatically
generated alias (first letter of each word in table name ('_' as delimeter))

Usage:
Set PGadmin Macro to the below select query. This method is preferred vs a function because it will work across databases.

Can be used on:
schema name: miovision_api
schema.table: miovision_api.intersection

*/

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
            AND pg_class.relkind IN ('r', 'v', 'm', 'f', 'p'), --tables, views, mat views, foreign table, partitioned table
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
            pg_namespace.nspname LIKE '%' || split_part('$SELECTION$', '.', 1) || '%'
            AND pg_class.relname LIKE  '%' || split_part('$SELECTION$', '.', 2) || '%'
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
    CASE pg_class.relkind
        WHEN 'r' THEN 'ordinary table'
        WHEN 'v' THEN 'view'
        WHEN 'm' THEN 'materialized view'
        WHEN 'f' THEN 'foreign table'
        WHEN 'p' THEN 'partitioned table'
    END AS obj_type,
    pg_namespace.nspname::text AS obj_schema,
    pg_class.relname::text AS obj_name,
    table_prefix.table_alias::text,
    pg_description.description AS obj_comment,
    pg_size_pretty(pg_total_relation_size(pg_class.oid)) AS total_relation_size_pretty,
    pg_total_relation_size(pg_class.oid) AS total_relation_size
FROM pg_catalog.pg_namespace
JOIN pg_catalog.pg_class
    ON pg_class.relnamespace = pg_namespace.oid
    AND pg_class.relkind IN ('r', 'v', 'm', 'f', 'p') --tables, views, mat views
JOIN pg_catalog.pg_attribute
    ON pg_class.oid = pg_attribute.attrelid
    AND pg_attribute.attnum > 0
    AND NOT attisdropped
LEFT JOIN pg_catalog.pg_description
    ON pg_description.objoid = pg_class.oid
    AND pg_description.objsubid = 0
JOIN table_prefix ON table_prefix.oid = pg_class.oid
GROUP BY
    pg_class.oid,
    pg_namespace.nspname, 
    pg_class.relname,
    pg_class.relkind,
    table_prefix.table_alias,
    pg_description.description

UNION
SELECT
    null AS columns_new_line,
    null AS columns_no_new_line,
    pg_get_function_identity_arguments(pg_proc.oid) AS columns_no_alias,
    'function' AS obj_type,
    pg_namespace.nspname AS obj_schema,
    format('%I(%s)', pg_proc.proname, oidvectortypes(pg_proc.proargtypes)) AS obj_name,
    null AS table_alias,
    pg_description.description AS obj_comment,
    pg_size_pretty(pg_total_relation_size(pg_proc.oid)) AS total_relation_size_pretty,
    pg_total_relation_size(pg_proc.oid) AS total_relation_size
FROM pg_proc
JOIN pg_namespace ON (pg_proc.pronamespace = pg_namespace.oid)
LEFT JOIN pg_catalog.pg_description
    ON pg_description.objoid = pg_proc.oid
    AND pg_description.objsubid = 0
WHERE
    pg_namespace.nspname LIKE '%' || split_part('$SELECTION$', '.', 1) || '%'
    AND pg_proc.proname LIKE  '%' || split_part('$SELECTION$', '.', 2) || '%'
ORDER BY obj_name;
