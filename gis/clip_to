-- FUNCTION: gis.clip_totext, text

-- DROP FUNCTION gis.clip_totext, text;
/*Author: Raphael Dumas
Clips the specified layer in the specified schema to the Toronto boundary*/
CREATE OR REPLACE FUNCTION gis.clip_to(
	schemaname text,
	tablename text)
    RETURNS integer
    LANGUAGE 'plpgsql'
    COST 100.0
    VOLATILE STRICT 
AS $function$

BEGIN
DROP TABLE IF EXISTS bounded_table;
EXECUTE FORMAT('CREATE TEMP TABLE bounded_table AS SELECT a.*  FROM %I.%I AS a, gis."to" AS b WHERE ST_Intersects(a.geom, b.geom)', schemaname, tablename);
EXECUTE FORMAT('TRUNCATE %I.%I', schemaname, tablename);
EXECUTE FORMAT('INSERT INTO %I.%I SELECT * FROM bounded_table',  schemaname, tablename);
RETURN 1;
END;

$function$;

ALTER FUNCTION gis.clip_to(text, text)
    OWNER TO dbadmin;

GRANT EXECUTE ON FUNCTION gis.clip_to(text, text) TO bdit_humans;

GRANT EXECUTE ON FUNCTION gis.clip_to(text, text) TO dbadmin;

