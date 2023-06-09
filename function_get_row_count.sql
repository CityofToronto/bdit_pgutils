--for testing: 
--rescu.volumes_15min

DROP FUNCTION get_row_count(text);
CREATE OR REPLACE FUNCTION get_row_count(IN schema_table text)
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