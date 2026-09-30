CREATE OR REPLACE FUNCTION gis.twochar_direction(direction text)
RETURNS TEXT AS
$BODY$
BEGIN
    RETURN CASE direction
        WHEN 'Northbound' THEN 'NB'
        WHEN 'Southbound' THEN 'SB'
        WHEN 'Eastbound' THEN 'EB'
        WHEN 'Westbound' THEN 'WB'
    END;
END;
$BODY$
LANGUAGE plpgsql;

DO $$
BEGIN
IF current_database() = 'bigdata' THEN
    ALTER FUNCTION gis.twochar_direction OWNER TO dbadmin;
    GRANT EXECUTE ON FUNCTION gis.twochar_direction TO public;
ELSIF current_database() = 'ptc' THEN
    ALTER FUNCTION gis.twochar_direction OWNER TO postgres;
    GRANT EXECUTE ON FUNCTION gis.twochar_direction TO ptc_humans;
END IF;
END
$$;
