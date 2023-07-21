declare
  v_curr record;
begin
for v_curr in
(
select deps_ddl_to_run 
from public.deps_saved_ddl
where deps_view_schema = p_view_schema and deps_view_name = p_view_name
order by deps_id desc
) loop
  execute v_curr.deps_ddl_to_run;
end loop;
delete from public.deps_saved_ddl
where deps_view_schema = p_view_schema and deps_view_name = p_view_name;
end;