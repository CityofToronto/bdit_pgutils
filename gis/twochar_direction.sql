CREATE OR REPLACE FUNCTION gis.twochar_direction(direction text)
  RETURNS TEXT AS
$BODY$
BEGIN
    RETURN CASE direction WHEN 'Northbound' THEN 'NB'
			  WHEN 'Southbound' THEN 'SB'
			  WHEN 'Eastbound' THEN 'EB'
			  WHEN 'Westbound' THEN 'WB'
	END;
END;
$BODY$
  LANGUAGE plpgsql;
ALTER FUNCTION gis.twochar_direction(text)
  OWNER TO rdumas;
GRANT EXECUTE ON FUNCTION gis.twochar_direction(text) TO public;