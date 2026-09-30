-- FUNCTION: gis.clip_to(text, text)

-- DROP FUNCTION gis.clip_to(text, text);
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
EXECUTE FORMAT('CREATE TEMP TABLE bounded_table AS SELECT a.*  FROM %I.%I AS a, gis.toronto_boundary AS b WHERE ST_Intersects(a.geom, b.geom)', schemaname, tablename);
EXECUTE FORMAT('TRUNCATE %I.%I', schemaname, tablename);
EXECUTE FORMAT('INSERT INTO %I.%I SELECT * FROM bounded_table',  schemaname, tablename);
RETURN 1;
END;

$function$;

DO $$
BEGIN
IF current_database() = 'bigdata' THEN
    ALTER FUNCTION gis.clip_to(text, text) OWNER TO dbadmin;
    GRANT EXECUTE ON FUNCTION gis.clip_to(text, text) TO dbadmin;
    GRANT EXECUTE ON FUNCTION gis.clip_to(text, text) TO bdit_humans;
ELSIF current_database() = 'ptc' THEN
    ALTER FUNCTION gis.clip_to(text, text) OWNER TO postgres;
    GRANT EXECUTE ON FUNCTION gis.clip_to(text, text) TO postgres;
    GRANT EXECUTE ON FUNCTION gis.clip_to(text, text) TO ptc_humans;
END IF;
END
$$;
