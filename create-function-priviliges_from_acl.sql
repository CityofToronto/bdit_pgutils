CREATE OR REPLACE FUNCTION public.priviliges_from_acl(TEXT)
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

ALTER FUNCTION public.priviliges_from_acl(TEXT) OWNER TO dbadmin;