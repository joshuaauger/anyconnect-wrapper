#!/usr/bin/env bash
USER=$(whoami)
DISABLE="$HOME/.vpn.disable"
PLAIN=0

## Some prompt stuff, helps wrap prompts.
function prompt() {
	osascript <<EOT
	tell app "System Events"
		text returned of (display dialog "$1" default answer "$2" buttons {"OK"} default button 1 with title "$(basename "$0")")
	end tell
EOT
}

function notifications() {
	if [ $PLAIN -ne 0 ]; then
		echo "$2 $1"
	else 
		which terminal-notifier > /dev/null 2>&1
		if [ $? -ne 0 ];
		then
			osascript -e "display notification \"$1\" with title \"Cisco Anyconnect $2\""
		else
			# terminal-notifier -remove 1 > /dev/null 2>&1
			terminal-notifier -group 1 -sender 'com.cisco.anyconnect.gui'  -title "Cisco Anyconnect $2" -message "$1" > /dev/null 2>&1
		fi
	fi
}

function get_url(){
	security find-generic-password -a "$USER" -s vpn_url -w 2> /dev/null
}

function set_url() {
	security add-generic-password -a "$USER" -s vpn_url -w $1 > /dev/null 2>&1
}

function remove_url() {
	security delete-generic-password -a "$USER" -s vpn_url > /dev/null 2>&1
}

function get_password() {
	security find-generic-password -a "$USER" -s vpn -w 2> /dev/null
}

function set_password() {
	security add-generic-password -a "$USER" -s vpn -w $1 > /dev/null 2>&1
}

function remove_password() {
	security delete-generic-password -a "$USER" -s vpn > /dev/null 2>&1
}

function url_wrapper() {
	URL=$(get_url)
	
	if [ -z "$URL" ]
	then
		URL=$(prompt 'Enter the test/keepalive URL:' 'https://www.google.com')
		set_url "$URL"
	fi

	echo "$URL"
}

function password_wrapper() {
	PASS=$(get_password)
	
	if [ -z "$PASS" ]
	then
		PASS=$(prompt 'Enter VPN Password:' 'password')
		set_password "$PASS"
	fi
	echo "$PASS"
}

function remove() {
	remove_password
	remove_url
}

function config() {
	remove
	password_wrapper
	url_wrapper
}

function read_vars() {
	USERNAME=$USER
	PASS=$(password_wrapper) #This is a wrapper to add a GUI shell for Launchd
	VPN=1 #This should be the mac group, change as needed.
	MFA=$(prompt 'Enter your MFA Token:' '')

	if [[ -z $VPN || -z $USERNAME || -z $MFA || -z $PASS ]]; then
		notifications 'One or more variables came back undefined, please make sure all variables are set!' 'Warning:'
		exit 1
	fi

	printf "%s\n%s\n%s\n%s\n" "$VPN" "$USERNAME" "$MFA" "$PASS"
}

function connect() {
	(read_vars | /opt/cisco/anyconnect/bin/vpn connect VPN -s > /tmp/anyconnect-wrapper.log 2>&1) > /dev/null 2>&1
	status
}

function disconnect() {
	/opt/cisco/anyconnect/bin/vpn disconnect > /dev/null 2>&1
	status
}

function status() {
	if [[ "{$(/opt/cisco/anyconnect/bin/vpn status)[0]}" == *"Disconnected"* ]]; then
		notifications "Disconnected." "Status:"
		return 1
	elif [[ "{$(/opt/cisco/anyconnect/bin/vpn status)[0]}" == *"Connected"* ]]; then
		notifications "Connected." "Status:"
		return 0
	else
		notifications "Unkown." "Status:"
		return 2
	fi
}

function monitor() {
	if [[ ! -f $DISABLE ]]; then
		#Let's keep this baby alive 💻
		#I really hope this doesn't break something, it shouldn't right? 👹
		URL=$(url_wrapper)
		curl -s -o /dev/null "$URL"
		if [[ "{$(/opt/cisco/anyconnect/bin/vpn status)[0]}" == *"Disconnected"* ]]; then
			connect
		fi
	fi
}

function agent_disable() {
	touch "$DISABLE"
	notifications "Disabled." "Agent:"
}

function agent_enable() {
	rm -f "$DISABLE"
	notifications "Enabled." "Agent:"
}

function agent_status() {
	if [[ ! -f $DISABLE ]]; then
		notifications "Enabled." "Agent:"
	else
		notifications "Disabled." "Agent:"
	fi
}

function print_help() {
	echo "Cisco Anyconnect Wrapper - 2023 Joshua Auger"
	echo
	echo "Syntax: vpn [--connect | --disconnnect | --agent {enable,disable,status} | --status | --configure | --monitor | --help]"
	echo "options:"
	echo "--connect     | -c                            Connect to the VPN using the built-in connection and supplied password and key."
	echo "--disconnnect | -d                            Disconnect from the vpn."
	echo "--configure   | -conf                         Configure the VPN connection parameters."
	echo "--agent       | -a {enabled,disabled,status}  Use this to enable or disable the launch agent. Enabled by default."
	echo "--monitor     | -m                            This can be used as a way to wrap this script in a Launch Agent or other process wrapper."
	echo "--status      | -s                            Get the current status of the VPN."
	echo "--help        | -h                            Print this help text."
	echo
}

POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
	case $1 in
	-c|-con|--connect)
		CONN=true
		shift
		;;
	-d|-dis|--disconnect)
		CONN=false
		shift
		;;
	-conf|--configure|--configuration)
		CONF=true
		shift
		;;
	-r|--remove)
		remove
		exit 0
		;;
	-a|--agent)
		AGENT=$(echo "$2" | tr '[:upper:]' '[:lower:]')
		shift #Shift past the $2, then onto next shift...
		shift
		;;
	-m|--mon|--monitor)
		monitor
		exit 0
		;;
	-s|--stat|--status)
		STAT=true
		shift
		;;
	-h|--help)
		print_help
		exit 0
		;;
	-p|--plaintext)
		PLAIN=1
		shift
		;;
	-*)
		notifications "Unknown option $1" "Argument:"
		exit 1
		;;
	*)
		POSITIONAL_ARGS+=("$1") # save positional arg
		shift # past argument
		;;
	esac
done

set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters

## The order of the next section helps with notification stacking...

if [[ $CONF == "true" ]]; then
	config
fi

if [[ "$AGENT" == 'enable' || "$AGENT" == 'enabled' || "$AGENT" == 'true' || $AGENT == '1' ]]; then
	agent_enable
elif [[ "$AGENT" == 'status' ]]; then
	agent_status
elif [[ -n "$AGENT" ]]; then
	agent_disable
fi

if [[ $CONN == "false" ]]; then
	disconnect
elif [[ $CONN == "true" ]]; then
	connect
fi

if [[ $STAT == "true" ]]; then
	status
fi