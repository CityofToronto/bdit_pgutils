/*Create a datetime bin for a timestamp and a set number of minutes*/
CREATE OR REPLACE FUNCTION public.datetime_bin(
    _timestamp_val timestamp without time zone, _minutes integer
)
RETURNS timestamp without time zone
LANGUAGE 'sql'
COST 100
IMMUTABLE 
AS $BODY$

    SELECT TIMESTAMP WITHOUT TIME ZONE 'epoch' + INTERVAL '1 second' * (floor((extract('epoch' from _timestamp_val)) / (_minutes*60)) * (_minutes*60));

$BODY$;

DO $$
BEGIN
IF current_database() = 'bigdata' THEN
    ALTER FUNCTION public.datetime_bin(timestamp without time zone, integer) OWNER TO dbadmin;
ELSIF current_database() = 'ptc' THEN
    ALTER FUNCTION public.datetime_bin(timestamp without time zone, integer) OWNER TO postgres;
END IF;
END
$$;
