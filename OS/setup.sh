#!/bin/bash

check_dependencies() {
    REQUIRED_CMDS=("git" "make" "zip" "lsb_release" "uname" "gcc" "dwarfdump")
    MISSING_CMDS=()
    for cmd in "${REQUIRED_CMDS[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            MISSING_CMDS+=("$cmd")
        fi
    done
    if [ ${#MISSING_CMDS[@]} -ne 0 ]; then
        sudo apt-get update
        for cmd in "${MISSING_CMDS[@]}"; do
            sudo apt-get install -y "$cmd"
        done
    fi
}

clone_volatility() {
    if [ ! -d "volatility" ]; then
        git clone https://github.com/volatilityfoundation/volatility || exit 1
    fi
}

build_linux_module() {
    cd volatility/tools/linux || exit 1
    make || exit 1
    cd ../../../
}

create_profile() {
    OS_NAME=$(lsb_release -i -s)
    KERNEL_VER=$(uname -r)
    ZIP_NAME="${OS_NAME}_${KERNEL_VER}_profile.zip"
    if [ ! -f "$ZIP_NAME" ]; then
        # Check if dwarfdump is available
        if ! command -v dwarfdump &>/dev/null; then
            echo "Error: dwarfdump is not installed. Please install it and try again."
            exit 1
        fi
        zip "$ZIP_NAME" ./volatility/tools/linux/module.dwarf /boot/System.map-"$KERNEL_VER" || exit 1
    fi
}

move_profile() {
    PLUGIN_DIR="volatility/volatility/plugins/overlays/linux"
    [ ! -d "$PLUGIN_DIR" ] && mkdir -p "$PLUGIN_DIR"
    mv *.zip "$PLUGIN_DIR" || exit 1
}

main() {
    check_dependencies
    clone_volatility
    build_linux_module
    create_profile
    move_profile
}

main
