CREATE OR REPLACE FUNCTION public.deps_restore_dependencies(p_view_schema IN VARCHAR, p_view_name IN VARCHAR)
RETURNS NULL
LANGUAGE plpgsql
    VOLATILE
    PARALLEL UNSAFE
    COST 100
AS
$$
DECLARE v_curr record;
BEGIN
FOR v_curr IN (
    SELECT deps_ddl_to_run
    FROM public.deps_saved_ddl
    WHERE
        deps_view_schema = p_view_schema
        AND deps_view_name = p_view_name
    ORDER BY deps_id DESC
) loop

EXECUTE v_curr.deps_ddl_to_run;
END loop;

DELETE FROM public.deps_saved_ddl
WHERE
    deps_view_schema = p_view_schema
    AND deps_view_name = p_view_name;

END;
$$;

ALTER FUNCTION public.deps_save_and_drop_dependencies OWNER TO natalie;