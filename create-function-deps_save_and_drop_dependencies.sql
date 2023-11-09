CREATE OR REPLACE FUNCTION public.deps_save_and_drop_dependencies(p_view_schema IN VARCHAR, p_view_name IN VARCHAR)
RETURNS VOID
LANGUAGE SQL
    VOLATILE
    PARALLEL UNSAFE
    COST 100
AS $$ 
SELECT public.deps_save_and_drop_dependencies_dry_run(
    p_view_schema,
    p_view_name,
    False --dryrun = False
);
$$;

GRANT EXECUTE ON FUNCTION public.deps_save_and_drop_dependencies(VARCHAR, VARCHAR) TO bdit_admins;
