#!/usr/bin/env bash
DIR=$(pwd)
LAUNCH_AGENT="$HOME/Library/LaunchAgents/com.wrapper.utilities.vpn.plist"
BIN="/usr/local/bin/vpn"

## The common functions need to be at the top so they load before everything else
function set_bin_permissions(){
    # chown "$(whoami)":"$(id -gn)" "$BIN"
    chmod 550 "$BIN"
}

function set_agent_permissions() {
    # chown "$(whoami)":"$(id -gn)" "$LAUNCH_AGENT"
    chmod 644 "$LAUNCH_AGENT"
}

function load_launchagent() {
    launchctl load -w "$LAUNCH_AGENT" > /dev/null 2>&1
}

function unload_launchagent() {
    launchctl unload -w "$LAUNCH_AGENT" > /dev/null 2>&1
}



## Update functions are at the top because we're not really using a true update vs install
function update_binaries() {
    cp -f "$DIR"/vpn.sh $BIN
    set_bin_permissions
}

function update_launchagent() {
    unload_launchagent
    cp -f "$DIR"/com.wrapper.utilities.vpn.plist "$LAUNCH_AGENT"
    set_agent_permissions
    load_launchagent
}

function update_git(){
    #This is just to make sure we're latest, instead of current git code.
    if git status -sb | grep behind ; then
        git pull
        ./setup.sh update_nogit
        exit;
    fi
}

function update_nogit() {
    update_binaries
    update_launchagent
}

## Install functions are basically wrappers for the update functions...
function install_launchagent() {
    update_launchagent
}

function install_binaries() {
    update_binaries
}

function install() {
    install_binaries
    install_launchagent
    $BIN enable
    echo "Insatlled and loaded the vpn wrapper."
}

function uninstall() {
    $BIN disconnect > /dev/null 2>&1
    unload_launchagent
    rm -f "$LAUNCH_AGENT" > /dev/null 2>&1
    rm -f "$BIN" > /dev/null 2>&1
    security delete-generic-password -a "$(whoami)" -s vpn > /dev/null 2>&1
    security delete-generic-password -a "$(whoami)" -s vpn_url > /dev/null 2>&1
    echo "Disabled and removed the vpn wrapper."
}

function print_help() {
    # Display Help
    echo "Anyconnect Wrapper - 2023 Joshua Auger"
    echo
    echo "Syntax: ./setup.sh [install|uninstall|update|help]"
    echo "options:"
    echo "install         Installs and loads the VPN wrapper."
    echo "reinstall       Used to reset VARS and re-install."
    echo "uninstall       Uninstalls the VPN wrapper."
    echo "update          Updates the code and reinstalls."
    echo "help            Print this help text."
    echo
}

function main(){
    ARG=$1
    case $ARG in
        install) install;;
        uninstall) uninstall;;
        reinstall) uninstall; install;;
        update) update_git;;
        update_nogit) update_nogit;;
        help) print_help;;
        *) return;;
    esac
}

main "$1"