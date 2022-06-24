#!/bin/bash
# Exporting all tables and views of the given schema (first argument) in "sql" folder in
# the given directory (second argument) or the current directory if nothing was given

# TO DO: pass the user name and host IP to the script (would that affect .pgpass?)
# Do we need to export any other elements, e.g., triggers?
# Should we export all objects or allow users to select some of them? 


export_schema () {

    echo Dumping schema $1
    [[ ! -d $2 ]] && mkdir $2
    [[ -f "$2/$1.sql" ]] && rm "$2/$1.sql"
    pg_dump -w -h 10.160.23.4 -d $database --schema $1 --exclude-table $1.* --schema-only | grep -v "^SET" | grep -v "^SELECT" > $2/$1.sql

    ##### TABLES
    echo Dumping tables in schema $1
    [[ ! -d "$2/tables/" ]] && mkdir "$2/tables/"
    psql -w -h 10.160.23.4 -d $database -t -c "SELECT table_name FROM information_schema.tables WHERE table_schema = '$1';" | while read -r table
    do
        if [[ "$table" == "" ]]; then
            echo Finished exporting tables
            break
        fi
        echo Dumping table $table
        [[ -f "$2/tables/${table}.sql" ]] && rm "$2/tables/${table}.sql"
        # exporting table definitions without the extra SET/SELECT statements on top
        pg_dump -w -h 10.160.23.4 -d $database --table $1.$table --schema-only | grep -v "^SET" | grep -v "^SELECT" > $2/tables/$table.sql # -f $2/tables/$table.sql
    done

    ##### VIEWS
    echo Dumping views in schema $1
    [[ ! -d "$2/views/" ]] && mkdir "$2/views/"
    psql -w -h 10.160.23.4 -d $database -t -c "SELECT table_name FROM information_schema.views WHERE table_schema = '$1';" | while read -r table
    do
        if [[ "$table" == "" ]]; then
            echo Finished exporting views
            break
        fi
        echo Dumping view $table
        [[ -f "$2/views/${table}.sql" ]] && rm "$2/views/${table}.sql"
        # exporting view definitions without the extra SET/SELECT statements on top
        pg_dump -w -h 10.160.23.4 -d $database --table $1.$table --schema-only | grep -v "^SET" | grep -v "^SELECT" > $2/views/$table.sql
    done

    ##### SEQUENCES
    echo Dumping sequences in schema $1
    [[ ! -d "$2/sequences/" ]] && mkdir "$2/sequences/"
    psql -w -h 10.160.23.4 -d $database -t -c "SELECT sequence_name FROM information_schema.sequences WHERE sequence_schema = '$1';" | while read -r seq
    do
        if [[ "$seq" == "" ]]; then
            echo Finished exporting sequences
            break
        fi
        echo Dumping sequence $seq
        [[ -f "$2/sequences/${seq}.sql" ]] && rm "$2/sequences/${seq}.sql"
        # exporting sequence definitions without the extra SET/SELECT statements on top
        pg_dump -w -h 10.160.23.4 -d $database --table $1.$seq --schema-only | grep -v "^SET" | grep -v "^SELECT" > $2/sequences/$seq.sql
    done
}


if [ $# -ge 3 ]; then
    output_dir=$3
    [[ ! -d "${output_dir}" ]] && mkdir "${output_dir}"
else
    output_dir="."
fi

if [ $# -ge 2 ]; then
    schema=$2
    database=$1
    [[ ! -d "${output_dir}/${database}/" ]] && mkdir "${output_dir}/${database}/"
    # exporting the schema and its children definitions
    export_schema $schema "${output_dir}/${database}/${schema}/"
    echo All done
elif [ $# -eq 1 ]; then
    database=$1
    [[ ! -d "${output_dir}/${database}/" ]] && mkdir "${output_dir}/${database}/"

    psql -w -h 10.160.23.4 -d $database -t -c "SELECT schema_name FROM information_schema.schemata;" | while read -r schema
    do
        if [[ "$schema" == "" ]]; then
            echo Finished exporting schemas
            break
        fi
        # exporting the schema and its children definitions
        export_schema $schema "${output_dir}/${database}/${schema}/"
    done
    echo All done
else
    # Expecting at least the database name
    echo Usage export_schema database [schema [output-directory]]
    echo Example: ./export_database.sh ptc raw .
fi
