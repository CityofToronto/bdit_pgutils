-- FUNCTION: public.datetime_bin_ceil(timestamp without time zone, integer)
-- DROP FUNCTION IF EXISTS public.datetime_bin_ceil(timestamp without time zone, integer);

CREATE OR REPLACE FUNCTION public.datetime_bin_ceil(
    _timestamp_val timestamp without time zone,
    _minutes integer)
RETURNS timestamp without time zone
LANGUAGE 'sql'
COST 100
IMMUTABLE PARALLEL UNSAFE
AS $BODY$

    SELECT TIMESTAMP WITHOUT TIME ZONE 'epoch' + INTERVAL '1 second' * (ceil((extract('epoch' from _timestamp_val)) / (_minutes*60)) * (_minutes*60));

$BODY$;

ALTER FUNCTION public.datetime_bin_ceil(timestamp without time zone, integer) OWNER TO dbadmin;
