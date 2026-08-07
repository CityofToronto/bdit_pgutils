- [Overview](#overview)
  - [view-all\_objects.sql](#view-all_objectssql)
  - [view-functions.sql](#view-functionssql)
  - [view-tables\_and\_views.sql](#view-tables_and_viewssql)
  - [view-schemas.sql](#view-schemassql)
  - [create-function-priviliges\_from\_acl.sql](#create-function-priviliges_from_aclsql)

# Overview
These basic views are meant to be the building blocks of other dbadmin queries, and to make it easy to conduct purges.

## [view-all_objects.sql](view-all_objects.sql)
A view of all database objects, not limited to:
- From `pg_class`: Tables, Partitioned Tables, Index, Sequences, Views, Types, Materialized Views
- From `pg_proc`: Window Functions, Functions, Aggregate Functions, Procedures

## [view-functions.sql](view-functions.sql)
A filtered view of `dbadmin.all_objects` which only includes functions (`pg_proc`): Window Functions, Functions, Aggregate Functions, Procedures

## [view-tables_and_views.sql](view-tables_and_views.sql)
A filtered view of `dbadmin.all_objects` which only includes non-functions (`pg_class`): Tables, Partitioned Tables, Index, Sequences, Views, Types, Materialized Views

## [view-schemas.sql](view-schemas.sql)
A view of schemas, useful to identify chonkers for purge.

## [create-function-priviliges_from_acl.sql](create-function-priviliges_from_acl.sql)
Misc helper function used in [deps_save_and_drop_dependencies_dryrun](../dependency_mgmt/create-function-deps_save_and_drop_dependencies_dryrun.sql).
