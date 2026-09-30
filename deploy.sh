cd bdit_pgutils/

#find sql files, excluding pgadmin macros
sql_files=$(find . -name "*.sql" -not -path "./pgadmin_macros/*" | sort);

#execute each file
for file in ${sql_files}; do \
    psql -w -U postgres -d ptc -f $file;
done;
