#!/bin/bash

set -eu

SCRIPT_NAME=$(basename "$0")
PEC_DIR=""

touch configs/.config

while IFS= read -r line; do
    OPTION=${line%% *}

    case $OPTION in

        PEC_DIR)
            PEC_DIR=${line##* }
            ;;
        *)
            # Mais opções serão adicionadas no futuro
            ;;
    esac
done < configs/.config

function setup() {
    echo -n "PEC repository path: "

    read PEC_DIR

    touch configs/.config
    > configs/.config

    printf "PEC_DIR $PEC_DIR\n" > configs/.config
}

function build() {
    cd $PEC_DIR

    echo "Compiling..."
    mvn clean install -T 1C -DskipTests
    echo "Done"
}

function reset_base() {
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

function rebuild() {
    build
    reset_base
}

function run() {
    cd "$PEC_DIR/app-bundle"
    mvn spring-boot:run -Dspring.profiles.active=dev,dev-postgres -Dbridge.flags.experimental=true
}

function front() {
    cd "$PEC_DIR/frontend"
    yarn start:experimental
}

function go() {
    cd $PEC_DIR
}

case $1 in

    setup | st)
        setup
        ;;
    rebuild | rb)
        rebuild
        ;;
    run | r)
        run
        ;;
    front | fr)
        front
        ;;
    go)
        go
        ;;
    build | b)
        build
        ;;
    resetbase | rba)
        reset_base
        ;;
    *)
        echo "Command not found"
        ;;
esac
