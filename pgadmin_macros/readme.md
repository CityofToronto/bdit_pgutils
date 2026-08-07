> Query Tool Macros enable you to execute pre-defined SQL queries with a single key press. Pre-defined queries can contain the placeholder $SELECTION$. Upon macro execution, the placeholder will be replaced with the currently selected text in the Query Editor pane of the Query Tool.
- https://www.pgadmin.org/docs/pgadmin4/9.17/query_tool.html#macros

This folder contains some SQL queries which can be helpful when used as pgAdmin macros for quick access during development.

[function_get_row_count.sql](./function_get_row_count.sql)

Macro to get an approximation of row count using `TABLESAMPLE SYSTEM` method.
Works well for very large tables as it only samples 1% of pages.

[get_columns.sql](./get_columns.sql)

Macro to return strucutre of a single table/view. Includes:
- column name
- data type
- comments
- data sample (first row)

[get_object_info.sql](./get_object_info.sql)

Macro to return column names (and more) for one or more tables/views/functions in a variety of formats.

Can be used on:
schema name: `miovision_api`
schema.table: `miovision_api.intersections`
schema.partial_table: `miovision_api.int` (finds anything starting with `int`)

[standup_order.sql](./standup_order.sql)
Use to randomly generate a standup order which can be pasted into Slack/Teams.