CREATE OR REPLACE FUNCTION public.array_diff(
    array1 anyarray,
    array2 anyarray
)
RETURNS anyarray
LANGUAGE sql
PARALLEL SAFE
IMMUTABLE AS $$
    SELECT COALESCE(ARRAY_AGG(elem), '{}')
    FROM UNNEST(array1) AS elem
    WHERE elem <> ALL(array2)
$$;

ALTER FUNCTION public.array_diff OWNER TO postgres;

GRANT EXECUTE ON FUNCTION public.array_diff TO public;

COMMENT ON FUNCTION public.array_diff IS 'Remove elements in Array2 from Array1.
Source: https://stackoverflow.com/questions/55304197/array-difference-in-postgresql
Example: SELECT array_diff(''{2,3,4}''::int[],	''{4,2}''::int[])';