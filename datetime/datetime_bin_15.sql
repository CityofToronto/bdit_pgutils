-- FUNCTION: public.datetime_bin_15(timestamp without time zone)

-- DROP FUNCTION public.datetime_bin_15(timestamp without time zone);

CREATE OR REPLACE FUNCTION public.datetime_bin_15(
	timestamp_val timestamp without time zone)
    RETURNS timestamp without time zone
    LANGUAGE 'sql'

    COST 100
    IMMUTABLE 
AS $BODY$

	SELECT TIMESTAMP WITHOUT TIME ZONE 'epoch' + INTERVAL '1 second' * (floor((extract('epoch' from timestamp_val)) / 900) * 900);

$BODY$;

ALTER FUNCTION public.datetime_bin_15(timestamp without time zone)
    OWNER TO rdumas;
