#!/bin/bash

set -eu

SCRIPT_NAME=$(basename "$0")
PEC_DIR=""
BUILD_CMD=""
FRONT_CMD=""

touch configs/.config

while IFS= read -r line; do

    OPTION=${line%% *}

    case $OPTION in

        PEC_DIR)
            PEC_DIR=$(cut -d " " -f2- <<< ${line})
            ;;
        BUILD_CMD)
            BUILD_CMD=$(cut -d " " -f2- <<< ${line})
            ;;
        FRONT_CMD)
            FRONT_CMD=$(cut -d " " -f2- <<< ${line})
            ;;
        *)
            # Mais opções serão adicionadas no futuro
            ;;
    esac
done < configs/.config

function setup() {
    echo -n "PEC repository path: "
    read PEC_DIR

    echo -n "Default build command: "
    read BUILD_CMD

    echo -n "Default frontend command: "
    read FRONT_CMD

    touch configs/.config
    > configs/.config

    printf "PEC_DIR $PEC_DIR\nBUILD_CMD $BUILD_CMD\nFRONT_CMD $FRONT_CMD" > configs/.config
}

function build() {
    cd $PEC_DIR

    echo "Compiling..."
    echo $BUILD_CMD
    $BUILD_CMD
    echo "Done"
}

function reset-base() {
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
    reset-base
}

function run() {
    cd "$PEC_DIR/app-bundle"
    mvn spring-boot:run -Dspring.profiles.active=dev,dev-postgres -Dbridge.flags.experimental=true
}

function front() {
    cd "$PEC_DIR/frontend"
    $FRONT_CMD
}

function switch-branch() {
    cd $PEC_DIR
    git switch $1
    update-branch
}

function update-branch() {
    git fetch
    git pull
}

function update-all-branches() {
    switch-branch "main"
    switch-branch "stable"
    switch-branch "next"
}

function git-status() {
    cd $PEC_DIR
    git status
}

case $1 in

    help | h)
        cat help.txt
        ;;
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
    build | b)
        build
        ;;
    resetbase | rba)
        reset-base
        ;;
    switch | sw)
        switch-branch $2
        ;;
    updatebranch | ub)
        update-branch
        ;;
    updatebranches | ubs)
        update-all-branches
        ;;
    gitstatus | gs)
        git-status
        ;;
    *)
        echo "Command not found"
        ;;
esac
