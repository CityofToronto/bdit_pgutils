--for testing: 
--rescu

DROP FUNCTION get_column_info_schema(text);
CREATE OR REPLACE FUNCTION get_column_info_schema(IN sch_name text) --$SELECTION$ = schema_name

RETURNS TABLE (
    columns_new_line TEXT,
    columns_no_new_line TEXT,
    columns_no_alias TEXT,
    table_schema TEXT,
    tbl_name TEXT,
    table_alias TEXT
) AS
$$

WITH table_prefix AS (
    SELECT 
        p.table_name, 
        string_agg(
            LEFT(p.prefix, 1), --first letter of each word in table name
            ''
        ) AS table_alias
    FROM (
        SELECT 
            t.table_name,
            UNNEST( --array to lines
                        regexp_split_to_array(
                            t.table_name, --extract table name from schema.table_name
                            '_'
                        )
            ) prefix
        FROM information_schema.tables AS t
        WHERE t.table_schema = sch_name
    ) AS p
    GROUP BY p.table_name
)

SELECT 
    string_agg(
        concat(p.table_alias || '.', c.column_name), 
        ',' || chr(10)
        ORDER BY ordinal_position
    ) AS columns_new_line,
    string_agg(
        concat(p.table_alias || '.', c.column_name), 
        ', '
        ORDER BY ordinal_position
    ) AS columns_no_new_line,
    string_agg(
        c.column_name, 
        ', '
        ORDER BY ordinal_position
    ) AS columns_no_alias,
    c.table_schema::text,
    c.table_name::text AS tbl_name,
    p.table_alias::text
FROM information_schema.columns AS c
JOIN table_prefix AS p ON c.table_name = p.table_name
WHERE c.table_schema = quote_ident(sch_name)
GROUP BY 
    c.table_schema, 
    c.table_name,
    p.table_alias
ORDER BY c.table_name;
$$
LANGUAGE SQL;
