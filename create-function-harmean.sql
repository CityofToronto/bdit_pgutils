CREATE OR REPLACE FUNCTION harmean_accum(numeric[], numeric)
RETURNS numeric[]
LANGUAGE sql
AS $h$
SELECT array[$1[1]+1.0/$2, $1[2]+1.0]; 
$h$;

CREATE OR REPLACE FUNCTION harmean_finalize(numeric[])
RETURNS numeric
LANGUAGE sql
AS $h$
SELECT $1[2] /  $1[1];
$h$;

CREATE AGGREGATE public.harmean(numeric) (
    sfunc = harmean_accum,
    stype = numeric[],
    finalfunc = harmean_finalize,
    INITCOND = '{0.0, 0.0}'
);
