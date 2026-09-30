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

DO $$
BEGIN
IF current_database() = 'bigdata' THEN
    ALTER FUNCTION public.to_month(date) OWNER TO dbadmin;
ELSIF current_database() = 'ptc' THEN
    ALTER FUNCTION public.to_month(date) OWNER TO postgres;
END IF;
END
$$;
