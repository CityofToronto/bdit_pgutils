CREATE OR REPLACE FUNCTION public.to_month(
	date_val DATE)
    RETURNS TEXT
    LANGUAGE 'sql'

    COST 100
    IMMUTABLE 
AS $BODY$

SELECT to_char(date_trunc('month', date_val)::DATE, 
			   'YYYY-MM');
$BODY$;

ALTER FUNCTION public.to_month(DATE)
    OWNER TO rdumas;

