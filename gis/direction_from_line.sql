CREATE OR REPLACE FUNCTION gis.direction_from_line(line GEOMETRY)
RETURNS varchar(10)
AS $$
DECLARE	dir varchar(10);
BEGIN 

	IF GeometryType(line) NOT IN ('MULTILINESTRING','LINESTRING') THEN
		RAISE EXCEPTION 'Invalid Geometry'
			USING HINT = 'Input geometry must be a Line';
	END IF;
	
	SELECT direction INTO dir
	FROM (VALUES ('Northbound', int4range(0,45)), ('Northbound', int4range(315,361)), ('Eastbound', int4range(45,135)), ('Southbound', int4range(135,225)), ('Westbound', int4range(225,315))) AS t(direction, angle_range)
	WHERE degrees(ST_Azimuth(ST_StartPoint(ST_LineMerge(line)), ST_EndPoint(ST_LineMerge(line))))::INT <@ angle_range
	LIMIT 1; 
	RETURN dir;
END;
$$ LANGUAGE 'plpgsql' IMMUTABLE STRICT 
;
