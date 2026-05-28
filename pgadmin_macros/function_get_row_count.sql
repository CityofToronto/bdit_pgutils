/*
Query to return approximate row count of a table as a formatted text field.

Usage:
Set PGadmin Macro to the below select query.
Highlighted text (schema_name.table_name) will be populated into $SELECTION$
*/

SELECT
    '$SELECTION$' AS schema_table,
    (xpath('/row/c/text()', query_to_xml(
        'SELECT TO_CHAR(COUNT(1) * 100, ''999,999,999,999,999'') AS c from $SELECTION$ TABLESAMPLE SYSTEM (1)',
        FALSE, TRUE, '')))[1]::text AS approx_row_count;