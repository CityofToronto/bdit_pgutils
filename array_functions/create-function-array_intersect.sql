CREATE OR REPLACE FUNCTION public.array_intersect(state int[], elem int[])
RETURNS int[] AS
$BODY$
BEGIN
    -- first row: seed the accumulator
    IF state IS NULL THEN
        RETURN elem;
    END IF;

    -- short-circuit: once we hit empty, stays empty
    IF state = '{}' THEN
        RETURN state;
    END IF;

    RETURN ARRAY(SELECT unnest(state) INTERSECT SELECT unnest(elem));
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE AGGREGATE public.array_intersect_agg(int[]) (
    SFUNC = array_intersect,
    STYPE = int[]
);

--example of function
SELECT public.array_intersect('{1,2}'::int[], '{2,3}'::int[])

--example of aggregate function
WITH test(vals) AS ((VALUES('{1,2}'::int[]), ('{2,3}'::int[]), ('{2,4}'::int[])))
SELECT public.array_intersect_agg(vals) FROM test

COMMENT ON FUNCTION public.array_intersect IS
'Function to find the intersections of two arrays. See array_intersect_agg for aggregate function.';
