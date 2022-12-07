#!/bin/bash

set -eu

VERSION="0.3.2"
SCRIPT_NAME=$(basename "$0")
SCRIPT_DIR=$(pwd)

echo -n "b_script: (1) install, (2) uninstall: "
read OPTION

if [ $OPTION == "1" ]
then
    echo "Installing..."

    cd "$HOME/.local/bin"
    touch pec
    > pec
    chmod a+x pec
    printf "#!/bin/bash\ncd $SCRIPT_DIR/PEC\nbash pec.sh \"\$@\"\n" > pec

    echo "Done"
    echo "Run the command: 'pec setup' to complete your installation"
else
    echo "Uninstalling..."
    rm "$HOME/.local/bin/pec"
    echo "Done"
fi
