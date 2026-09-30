-- create ref and dbadmin schemas
-- with options for bigdata (dbadmin/bdit_humans) and ptc (postgres/ptc_humans)

DO $$
DECLARE
    r text;
BEGIN
    FOREACH r IN ARRAY ARRAY['dbadmin', 'postgres']
    LOOP
        IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = r) THEN
            EXECUTE format('
                CREATE SCHEMA IF NOT EXISTS ref AUTHORIZATION %1$I;
                GRANT ALL ON SCHEMA ref TO %1$I;
                CREATE SCHEMA IF NOT EXISTS dbadmin AUTHORIZATION %1$I;
                GRANT ALL ON SCHEMA dbadmin TO %1$I;',
            r);
        END IF;
    END LOOP;
END
$$;

DO $$
DECLARE
    r text;
BEGIN
    FOREACH r IN ARRAY ARRAY['bdit_humans', 'ptc_humans']
    LOOP
        IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = r) THEN
            EXECUTE format('
                GRANT USAGE ON SCHEMA ref TO %1$I;
                GRANT USAGE ON SCHEMA dbadmin TO %1$I;
                ALTER DEFAULT PRIVILEGES FOR ROLE %1$I IN SCHEMA dbadmin
                GRANT SELECT ON TABLES TO %1$I;',
            r);
        END IF;
    END LOOP;
END
$$;

COMMENT ON SCHEMA ref IS 'For reference lookup tables, eg. holidays';

COMMENT ON SCHEMA dbadmin
IS 'Helpful queries and views for database administration. 
See: https://github.com/CityofToronto/bdit_pgutils';
