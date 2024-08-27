#!/bin/bash

set -eu

VERSION="0.7.1"
SCRIPT_NAME=$(basename "$0")
SCRIPT_DIR=$(pwd)

echo -n "b_script: (i) install, (Any) uninstall: "
read OPTION

if [ $OPTION == "i" ]
then
    echo "Installing..."
    cp "PEC/pec_caller" "$HOME/.local/bin/pec"
    chmod a+x "$HOME/.local/bin/pec"
    echo "Done"
    echo "Run the command: 'pec setup' to complete your installation"
else
    echo "Uninstalling..."
    rm "$HOME/.local/bin/pec"
    echo "Done"
fi
