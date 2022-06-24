#!/bin/bash

import_schema () {
    schema_folder=$1
    schema=$(basename "$schema_folder")
    shopt -s nullglob
    for filename in ${schema_folder}/*; do
        if [[ -f $filename && "$filename" == *.sql ]]; then
            # creating the schema
            psql -w -h 10.160.23.4 -d $database -t -f $filename
            #echo $filename
        elif [[ -d $filename ]]; then
            # creating different objects
            counter=0
            for sql_file in ${filename}/*.sql; do
                psql -w -h 10.160.23.4 -d $database -t -f $sql_file
                ((counter++))
            done
            echo Created $counter $(basename "$filename")
        fi
    done
    shopt -u nullglob
}

if [ $# -ge 3 ]; then
    database=$1
    schema=$2
    output_dir="$3/${database}"
    schema_folder=${output_dir}/${schema}
    import_schema $schema_folder
    echo All done
elif [ $# -ge 2 ]; then
    database=$1
    schema=$2
    output_dir="./${database}"
    schema_folder=${output_dir}/${schema}
    import_schema $schema_folder
    echo All done
elif [ $# -ge 1 ]; then
    database=$1
    output_dir="./${database}"
    for schema_folder in ${output_dir}/*; do
        schema=$(basename "$schema_folder")
        echo Creating schema $schema
        import_schema $schema_folder
    done
    echo All done
else
    # Expecting at least the database name
    echo Usage import_schema database [schema [output-directory]]
    echo Example: ./import_database.sh ptc raw .
fi
