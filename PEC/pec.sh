#!/bin/bash

set -eu

VERSION="0.1"
SCRIPT_NAME=$(basename "$0")
PEC_DIR=""

touch .config

while IFS= read -r line; do
    OPT=${line%% *}

    case $OPT in

        PEC_DIR)
            PEC_DIR=${line##* }
            ;;
        *)
            # Mais opções serão adicionadas no futuro
            ;;
    esac
done < .config

function setup() {
    echo -n "PEC repository path: "

    read PEC_DIR

    touch .config
    > .config

    printf "PEC_DIR $PEC_DIR\n" > .config
}

function rebuild() {
    echo "Rebuilding..."

    cd $PEC_DIR

    echo "Compiling..."
    mvn clean install -T 1C -DskipTests

    echo "Reseting databases..."
    docker rm -f pec_postgres_1
    cd "$PEC_DIR/database"
    docker-compose up -d postgres
    mvn spring-boot:run -Dspring.liquibase.contexts=experimental

    echo "Loading data..."
    cd "$PEC_DIR/data-loader"
    mvn spring-boot:run -Dspring.profiles.active=dev,dev-postgres
    echo "Done"
}

case $1 in

    setup | st)
        setup
        ;;

    rebuild | rb)
        rebuild
        ;;
    *)
        echo "Command not found"
        ;;

esac
