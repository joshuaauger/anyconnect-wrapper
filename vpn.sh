#!/usr/bin/env bash

DISABLE="$HOME/.vpn.disable"

## Some prompt stuff, helps wrap prompts.
function prompt() {
  osascript <<EOT
    tell app "System Events"
      text returned of (display dialog "$1" default answer "$2" buttons {"OK"} default button 1 with title "$(basename "$0")")
    end tell
EOT
}

function password_wrapper() {
    PASS=$(security find-generic-password -a "$(whoami)" -s vpn -w)

    if [ -z "$PASS" ]
    then
        PASS=$(prompt 'Enter VPN Password:' 'password')
        security add-generic-password -a "$(whoami)" -s vpn -w "$PASS" > /dev/null 2>&1
    fi
    echo "$PASS"
}

function read_vars() {
    USERNAME=$(whoami)
    PASS=$(password_wrapper) #This is a wrapper to add a GUI shell for Launchd
    VPN=1 #This should be the mac group, change as needed.
    MFA=$(prompt 'Enter your MFA Token:' '')

    echo "$VPN" > /tmp/vpn.tmp
    echo "$USERNAME" >> /tmp/vpn.tmp
    echo "$MFA" >> /tmp/vpn.tmp
    echo "$PASS" >> /tmp/vpn.tmp
}

function connect() {
    read_vars
    /opt/cisco/anyconnect/bin/vpn -s connect VPN < /tmp/vpn.tmp
    rm /tmp/vpn.tmp
}

function disconnect() {
    /opt/cisco/anyconnect/bin/vpn disconnect
}

function status() {
    if [[ "{$(/opt/cisco/anyconnect/bin/vpn status)[0]}" == *"Disconnected"* ]]; then
        echo "VPN Status: Disconnected."
    elif [[ "{$(/opt/cisco/anyconnect/bin/vpn status)[0]}" == *"Connected"* ]]; then
        echo "VPN Status: Connected."
    else
        echo "VPN Status: Unkown."
    fi
}

function monitor() {
    if [[ ! -f $DISABLE ]]; then  
        if [[ "{$(/opt/cisco/anyconnect/bin/vpn status)[0]}" == *"Disconnected"* ]]; then
            connect
        fi
    fi
}

function agent_disable() {
    touch "$DISABLE"
}

function agent_enable() {
    rm "$DISABLE"
}

function print_help() {
    # Display Help
    echo "VPN Wrapper - 2023 Joshua Auger"
    echo
    echo "Syntax: vpn [connect|disconnnect|enable|disable|monitor|help]"
    echo "options:"
    echo "connect         Connect to the VPN using the built-in connection and supplied password and key."
    echo "disconnnect     Disconnect from the vpn."
    echo "enable          Enables the monitor function. This is enabled by default"
    echo "disable         Disables the monitor function"
    echo "monitor         This can be used as a way to wrap this script in a Launch Agent or other process wrapper."
    echo "status          Get the current status of the VPN."
    echo "help            Print this help text."
    echo
}

while :; do
    case $1 in
        connect) connect; break ;;
        disconnect) disconnect; break ;;
        enable) agent_enable; break ;;
        disable) agent_disable; break;;
        monitor) monitor; break;;
        status) status; break;;
        help) print_help ;;
        *) break;;
    esac

    shift
done


