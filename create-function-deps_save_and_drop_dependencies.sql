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

COMMENT ON FUNCTION public.deps_save_and_drop_dependencies(VARCHAR, VARCHAR) IS 
    '''This version is only to be used by admins. It drops all dependencies of the inputed object. 
    Use this function when you need to drop+edit+recreate a table or (mat) view with dependencies.
    This function will recursively iterate through an objects dependencies and save:
    - definition of view/mat view
    - object owner
    - index/unique index (only applies to mat views)
    - object comments
    - column comments
    - any permissions
    - DOES NOT HANDLE TRIGGERS ON DEPENDENT VIEWS 
    - DROP the dependency
    Then, after dropping, editing, and restoring the original object, use the function 
    public.deps_restore_dependencies(VARCHAR, VARCHAR) to recreate the dependencies. 
    You can also use `dryrun = True` to not drop the dependencies, if you want to check
    the entries in `public.deps_saved_ddl` first. In that case you will have to delete the records.
    
    Example:
    SELECT public.deps_save_and_drop_dependencies(''miovision_api''::text COLLATE pg_catalog."C", ''volumes_15min''::text COLLATE pg_catalog."C");
    --now DROP and make changes to miovision_api.volumes_15min, recreate. 
    SELECT public.deps_restore_dependencies(''miovision_api''::text COLLATE pg_catalog."C", ''volumes_15min''::text COLLATE pg_catalog."C");
    '''
