# deps_save_and_drop_dependencies

## Dry Run
First time here? Try running with dryrun := True first and look at the results to see behind the scenes. This function saves all of an object’s dependencies so you can safely drop and recreate it. 

```sql
--run dry run = true and check results 
SELECT public.deps_save_and_drop_dependencies_dryrun(
	p_view_schema:= 'vds'::character varying COLLATE "C",
	p_view_name:= 'detector_inventory'::character varying COLLATE "C", 
	dryrun := True::boolean, 
	max_depth := 20::integer
);

--check out dry run results and save elsewhere.
SELECT deps_id, deps_view_schema, deps_view_name, deps_ddl_to_run
FROM public.deps_saved_ddl
WHERE 
    deps_view_schema = 'vds'
    AND deps_view_name = 'volumes_daily';
```

## Non-Dry Run

Now the real deal. Run the non-dryrun version to drop dependencies. I prefer to run this all in one go so if it fails to recreate any dependencies the whole thing is aborted safely. 

```sql
--when comfortable, run with dryrun = False
SELECT public.deps_save_and_drop_dependencies(
	p_view_schema:= 'vds'::character varying COLLATE "C",
	p_view_name:= 'volumes_daily'::character varying COLLATE "C", 
	max_depth := 20::integer
);

/*##########################################
############################################
                 !!!stop!!!
drop and recreate the object with dependencies
############################################
############################################*/

--now restore dependencies:
SELECT public.deps_restore_dependencies(
	p_view_schema:= 'vds'::character varying COLLATE "C",
	p_view_name:= 'volumes_daily'::character varying COLLATE "C"
);
```

## Editing dependencies
If you make edits to the base object which is referenced by dependencies, you may need to edit the `deps_ddl_to_run` (eg. remove reference to a column) before `deps_restore_dependencies` can be run. You can edit interactively in pgAdmin, since the table has a primary key:

```sql
SELECT deps_id, deps_ddl_to_run
FROM public.deps_saved_ddl
WHERE deps_view_schema = 'vds'
AND deps_view_name = 'volumes_daily'
```
