--DROP FUNCTION public.array_diff;
CREATE OR REPLACE FUNCTION public.array_diff(
    array1 anyarray,
    array2 anyarray
)
RETURNS anyarray
LANGUAGE plpgsql
PARALLEL SAFE
IMMUTABLE AS $$
DECLARE r array1%TYPE;

BEGIN
    IF array1 IS NULL THEN
        RETURN array2;
    ELSIF array2 IS NULL THEN
        RETURN array1;
    ELSE
        SELECT COALESCE(ARRAY_AGG(elem), '{}') INTO r
        FROM UNNEST(array1) AS elem
        WHERE elem <> ALL(array2);
        RETURN r;
    END IF;
END;
$$;

ALTER FUNCTION public.array_diff OWNER TO dbadmin;

GRANT EXECUTE ON FUNCTION public.array_diff TO public;

COMMENT ON FUNCTION public.array_diff IS 'Remove elements in Array2 from Array1.
Source: https://stackoverflow.com/questions/55304197/array-difference-in-postgresql
Example: SELECT array_diff(''{2,3,4}''::int[],	''{4,2}''::int[])';
