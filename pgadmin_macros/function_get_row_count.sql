/*
Function to quickly return row count of a table as a formatted text field.

Usage: Set PGadmin Macro SQL to:
--$SELECTION$ = schema_name.table_name (eg. rescu.volumes_15min)
SELECT public.get_row_count('$SELECTION$');
*/

DROP FUNCTION public.get_row_count(text);
CREATE OR REPLACE FUNCTION public.get_row_count(IN schema_table text)
RETURNS TEXT AS
$$
DECLARE
    row_count TEXT;
BEGIN
    EXECUTE 'SELECT TO_CHAR(COUNT(1), ''999,999,999,999,999'') AS row_count FROM ' || schema_table
    INTO row_count;
  
    RETURN row_count;
END;
$$
LANGUAGE plpgsql;