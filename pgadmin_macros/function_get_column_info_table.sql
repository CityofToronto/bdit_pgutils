--for testing: 
--rescu.volumes_15min

DROP FUNCTION public.get_column_info_table(text);
CREATE OR REPLACE FUNCTION public.get_column_info_table(IN sch_table_name text) --$SELECTION$ = schema_name.table_name

RETURNS TABLE (
    columns_new_line TEXT,
    columns_no_new_line TEXT,
    columns_no_alias TEXT,
    table_schema TEXT,
    tbl_name TEXT,
    table_alias TEXT
) AS
$$

--$SELECTION$ = schema_name.table_name
WITH table_prefix AS (
    SELECT 
        p.table_name, 
        string_agg(
            LEFT(p.prefix, 1), --first letter of each word in table name
            ''
        ) AS table_alias
    FROM (
        SELECT 
            table_name,
            UNNEST( --array to lines
                        regexp_split_to_array(
                            table_name, --extract table name from schema.table_name
                            '_'
                        )
            ) prefix
        FROM information_schema.tables t
        WHERE t.table_schema = split_part(sch_table_name, '.', 1)
            AND t.table_name = split_part(sch_table_name, '.', 2)
    ) AS p
    GROUP BY p.table_name
)

SELECT 
    'SELECT' || chr(10) || string_agg(
        concat(p.table_alias || '.', c.column_name), 
        ',' || chr(10)
        ORDER BY ordinal_position
    ) || chr(10) || 'FROM ' || c.table_name || ' AS ' || p.table_alias  AS columns_new_line,
    'SELECT ' || string_agg(
        concat(p.table_alias || '.', c.column_name), 
        ','
        ORDER BY ordinal_position
    ) || chr(10) || 'FROM ' || c.table_name || ' AS ' || p.table_alias  AS columns_no_new_line,
    string_agg(
        concat(p.table_alias || '.', c.column_name), 
        ', '
        ORDER BY ordinal_position
    ) AS columns_no_alias,
    c.table_schema::text,
    c.table_name::text AS tbl_name,
    p.table_alias
FROM information_schema.columns AS c
JOIN table_prefix AS p ON c.table_name = p.table_name
WHERE c.table_schema = split_part(sch_table_name, '.', 1)
    AND c.table_name = split_part(sch_table_name, '.', 2)
GROUP BY 
    c.table_schema, 
    c.table_name,
    p.table_alias
ORDER BY c.table_name;
$$
LANGUAGE SQL;
