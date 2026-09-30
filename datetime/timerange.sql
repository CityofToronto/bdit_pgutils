--create type without erroring on pre-existing
DO 'BEGIN
   CREATE TYPE public.timerange AS RANGE(
        subtype = TIME
    );
EXCEPTION WHEN duplicate_object THEN
   NULL;  -- ignore the error
END;';
