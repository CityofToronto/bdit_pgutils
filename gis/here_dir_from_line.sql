CREATE OR REPLACE FUNCTION gis.here_dir_from_line(line GEOMETRY)
RETURNS char(1)
AS $$
/* Returns the link direction of the provided line based on its drawn direction and the logic provided by here 
F and T represent "From" and "To" relative to each link's reference node, which is always the node with the lowest latitude. 
In the case of two nodes with equal latitude, the node with the lowest longitude is the reference node. 
*/


DECLARE	_azimuth numeric;
		
BEGIN 

	IF GeometryType(line) NOT IN ('MULTILINESTRING','LINESTRING') THEN
		RAISE EXCEPTION 'Invalid Geometry'
			USING HINT = 'Input geometry must be a Line';
	END IF;
	
	_azimuth := degrees(ST_Azimuth(ST_StartPoint(ST_LineMerge(line)), ST_EndPoint(ST_LineMerge(line)))) >= 90;
	
	RETURN CASE WHEN _azimuth < 90 THEN 'F'
				WHEN _azimuth >= 90 AND _azimuth < 270 THEN 'T'
				ELSE 'F'
																						 
	END;
END;
$$ LANGUAGE 'plpgsql' IMMUTABLE STRICT 
;

GRANT EXECUTE ON FUNCTION gis.here_dir_from_line(GEOMETRY) TO bdit_humans;