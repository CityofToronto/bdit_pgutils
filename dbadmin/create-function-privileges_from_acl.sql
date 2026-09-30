CREATE OR REPLACE FUNCTION public.privileges_from_acl(TEXT)
RETURNS TEXT
LANGUAGE SQL AS $$
    SELECT string_agg(privilege, ', ')
    FROM (
        SELECT 
            CASE ch
                WHEN 'r' THEN 'SELECT'
                WHEN 'w' THEN 'UPDATE'
                WHEN 'a' THEN 'INSERT'
                WHEN 'd' THEN 'DELETE'
                WHEN 'D' THEN 'TRUNCATE'
                WHEN 'x' THEN 'REFERENCES'
                WHEN 't' THEN 'TRIGGER'
            END AS privilege
        FROM regexp_split_to_table($1, '') AS ch
    ) AS s 
$$;

DO $$
BEGIN
IF current_database() = 'bigdata' THEN
    ALTER FUNCTION public.privileges_from_acl(TEXT) OWNER TO dbadmin;
    GRANT EXECUTE ON FUNCTION public.privileges_from_acl(TEXT) TO bdit_humans;
ELSIF current_database() = 'ptc' THEN
    ALTER FUNCTION public.privileges_from_acl(TEXT) OWNER TO postgres;
    GRANT EXECUTE ON FUNCTION public.privileges_from_acl(TEXT) TO ptc_humans;
END IF;
END
$$;
