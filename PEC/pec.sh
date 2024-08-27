#!/bin/bash

set -eu

SCRIPT_NAME=$(basename "$0")
CURRENT_PRESET=""
PRESET_FILE=""
PEC_DIR=""
BUILD_CMD=""
FRONT_CMD=""

function read-config() {
    touch configs/.config

    while IFS= read -r line; do

        OPTION=${line%% *}

        case $OPTION in

            CURRENT_PRESET)
                set-preset-internal $(cut -d " " -f2- <<< ${line})
                ;;
            *)
                # Mais opções serão adicionadas no futuro
                ;;
        esac
    done < configs/.config

    if [ "$CURRENT_PRESET" = "" ]
    then
        set-preset "default"
    fi

    touch "configs/presets/${PRESET_FILE}"
}

function read-preset() {
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
    done < "configs/presets/${PRESET_FILE}"
}

function new-preset() {
    local is_default=$1

    if [ "$is_default" = "true" ]
    then
        set-preset-internal $2

        if [ -f "configs/presets/${PRESET_FILE}" ]
        then
            echo -n "The file $PRESET_FILE already exists. Do you want to override this preset? [Y/n]: "
            local answer
            read answer

            if [ "$answer" = "n" ]
            then
                return
            fi
        fi
    else
        set-preset-internal "default"
    fi

    echo -n "PEC repository path: "
    read PEC_DIR

    echo -n "Build command: "
    read BUILD_CMD

    echo -n "Frontend command: "
    read FRONT_CMD

    touch "configs/presets/${PRESET_FILE}"
    > "configs/presets/${PRESET_FILE}"
    printf "PEC_DIR $PEC_DIR\nBUILD_CMD $BUILD_CMD\nFRONT_CMD $FRONT_CMD\n" > "configs/presets/${PRESET_FILE}"
}

function remove-preset() {
    local previous_preset=$CURRENT_PRESET
    set-preset-internal $1

    if [ -f "configs/presets/${PRESET_FILE}" ]
    then
        rm "configs/presets/${PRESET_FILE}"
        echo "Preset $CURRENT_PRESET removed"

        if [ "$1" = "$previous_preset" ]
        then
            set-preset "default"
        fi
    else
        echo "The preset $CURRENT_PRESET doesn't exist"
    fi
}

function set-preset-internal() {
    CURRENT_PRESET=$1
    PRESET_FILE="${CURRENT_PRESET}.txt"   
}

function set-preset() {
    set-preset-internal $1

    if [ -f "configs/presets/${PRESET_FILE}" ]
    then
        echo "Setting $CURRENT_PRESET as the current preset"
        read-preset

        > "configs/.config"
        printf "CURRENT_PRESET $CURRENT_PRESET\n" > "configs/.config"
    else
        echo "The preset $CURRENT_PRESET doesn't exist"
    fi
}

function get-current-preset() {
    echo $CURRENT_PRESET
}

function list-presets() {
    echo "Presets:"

    for file in "configs/presets"/*
    do
        echo "$(basename $file .txt)"
    done
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
    docker compose up -d postgres
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

function debug() {
    echo $SCRIPT_NAME
    echo $CURRENT_PRESET
    echo $PRESET_FILE
    echo $PEC_DIR
    echo $BUILD_CMD
    echo $FRONT_CMD
}

# Inicialização
read-config
read-preset

case $1 in

    help | h)
        cat help.txt
        ;;
    setup | st)
        new-preset "false" $2
        ;;
    newpreset | np)
        new-preset "true" $2
        ;;
    removepreset | rp)
        remove-preset $2
        ;;
    listpresets | lp)
        list-presets
        ;;
    currentpreset | cp)
        get-current-preset
        ;;
    setpreset | sp)
        set-preset $2
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
    debug | dbg)
        debug
        ;;
    *)
        echo "Command not found"
        ;;
esac
