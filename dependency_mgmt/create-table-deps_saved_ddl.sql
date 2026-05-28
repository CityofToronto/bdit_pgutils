-- Table: dbadmin.deps_saved_ddl

-- DROP TABLE IF EXISTS dbadmin.deps_saved_ddl;

CREATE TABLE IF NOT EXISTS dbadmin.deps_saved_ddl
(
    deps_id integer NOT NULL DEFAULT nextval('deps_saved_ddl_deps_id_seq'::regclass),
    deps_view_schema character varying(255) COLLATE pg_catalog."default",
    deps_view_name character varying(255) COLLATE pg_catalog."default",
    deps_ddl_to_run text COLLATE pg_catalog."default",
    CONSTRAINT deps_saved_ddl_pkey PRIMARY KEY (deps_id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS dbadmin.deps_saved_ddl
OWNER TO dbadmin;

GRANT ALL ON TABLE dbadmin.deps_saved_ddl TO bdit_humans;

GRANT ALL ON TABLE dbadmin.deps_saved_ddl TO dbadmin;
